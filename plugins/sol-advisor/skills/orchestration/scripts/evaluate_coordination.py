#!/usr/bin/env python3
"""Pure evaluator for the 0.7.0 coordination file-backed fixture.

This computes instruction-contract transitions from state and action data.  It is
evidence for the contract, not a runtime scheduler or enforcement mechanism.
"""

from __future__ import annotations

import argparse
import copy
import json
import sys
from pathlib import Path
from typing import Any


ROLES = {"deep_explorer", "explorer", "worker", "tester", "reviewer"}
TERMINAL = {"succeeded", "failed", "blocked", "interrupted"}
ACTIVE = {"active", "not_started"}
EVIDENCE_KEYS = (
    "scope",
    "branch",
    "base",
    "dirty_ownership",
    "config_runtime",
    "contracts",
    "contradiction",
    "path_known",
)
DEPENDENT_KINDS = {
    "start_dependent_review",
    "start_dependent_validation",
    "accept",
    "validate",
}
PRODUCT_WRITE_KINDS = {
    "edit",
    "edit_and_test",
    "write",
    "write_config",
}
REPAIR_WRITE_KINDS = {"repair_product"}
WRITE_KINDS = PRODUCT_WRITE_KINDS | REPAIR_WRITE_KINDS
ROLE_OWNERSHIP_KINDS = {
    "deep_explorer": {"recon"},
    "explorer": {"recon"},
    "worker": {"write_config", "tests"},
    "tester": {"runtime_qa"},
    "reviewer": {"review"},
}
ORTHOGONAL_KINDS = {"prep", "spot_check"}
INTERRUPT_REASONS = {"user_stop", "safety_boundary", "evidence_supported_abandonment"}
WAIT_KINDS = {"wait", "wait_agent"}
PRIMARY_CONTROL_KINDS = DEPENDENT_KINDS | {"interrupt", "reuse_evidence"} | WAIT_KINDS
ROLE_ACTION_KINDS = {
    "deep_explorer": {"evidence_search", "recon"},
    "explorer": {"evidence_search", "recon"},
    "worker": PRODUCT_WRITE_KINDS | {"tests", "test", "run_tests"},
    "tester": {"browser_qa", "runtime_qa", "tests", "test", "run_tests", "runtime_check", "repair_product"},
    "reviewer": {"review"},
}
EVIDENCE_ROLES = {"deep_explorer", "explorer"}


def _strings(value: Any) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, list):
        return [item for item in value if isinstance(item, str)]
    return []


def _overlap(left: Any, right: Any) -> bool:
    """Return true for equal or nested path/scope ownership."""
    left_items = {item.strip() for item in _strings(left) if item.strip()}
    right_items = {item.strip() for item in _strings(right) if item.strip()}
    for a in left_items:
        for b in right_items:
            if a == b or a.startswith(b + "/") or b.startswith(a + "/"):
                return True
    return False


def _covers(available: Any, requested: Any) -> bool:
    """Return true only when every requested item is covered by availability."""
    available_items = {item.strip() for item in _strings(available) if item.strip()}
    requested_items = {item.strip() for item in _strings(requested) if item.strip()}
    if not requested_items:
        return False
    return all(
        any(item == requested or requested.startswith(item + "/") for item in available_items)
        for requested in requested_items
    )


def _children(state: dict[str, Any]) -> list[dict[str, Any]]:
    children = state.get("children", [])
    return [child for child in children if isinstance(child, dict)]


def _active(children: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [child for child in children if child.get("status") in ACTIVE]


def _result(decision: str, reason_code: str, terminal_barrier: bool = False) -> dict[str, Any]:
    return {
        "decision": decision,
        "reason_code": reason_code,
        "terminal_barrier": terminal_barrier,
    }


def _structured_disposition(child: dict[str, Any]) -> bool:
    disposition = child.get("disposition")
    if not isinstance(disposition, dict):
        return False
    recorded_by = disposition.get("recorded_by")
    return (
        isinstance(recorded_by, str)
        and recorded_by.strip().lower() == "sol"
        and isinstance(disposition.get("decision"), str)
        and bool(disposition["decision"].strip())
    )


def _required_evidence_satisfied(child: dict[str, Any]) -> bool:
    required = child.get("required_evidence", [])
    present = child.get("evidence_present", [])
    if not isinstance(required, list) or not all(isinstance(item, str) and item.strip() for item in required):
        return False
    if not isinstance(present, list) or not all(isinstance(item, str) and item.strip() for item in present):
        return False
    return all(item in present for item in required)


def _inspectable_terminal(child: dict[str, Any]) -> bool:
    return (
        child.get("handoff_inspected") is True
        and child.get("artifacts_inspected") is True
        and child.get("evidence_complete") is True
        and _required_evidence_satisfied(child)
    )


def _valid_round(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value >= 0


def _tester_repair_error(
    child: dict[str, Any], action: dict[str, Any], action_scope: Any
) -> str | None:
    """Require a narrow repair action authorized in Sol's child ledger."""
    authorization = child.get("repair_authorization")
    if not isinstance(authorization, dict):
        return "tester_repair_authorization_required"
    if str(authorization.get("issued_by", "")).strip().lower() != "sol":
        return "tester_repair_issuer_invalid"
    if authorization.get("action") != "repair_product":
        return "tester_repair_action_invalid"
    failed_check_id = authorization.get("failed_check_id")
    if not isinstance(failed_check_id, str) or not failed_check_id.strip():
        return "tester_repair_failed_check_missing"
    if not _valid_round(authorization.get("round")) or not _valid_round(action.get("round")):
        return "tester_repair_round_mismatch"
    if authorization["round"] != action["round"]:
        return "tester_repair_round_mismatch"
    if not _covers(child.get("scope"), authorization.get("scope")):
        return "tester_repair_scope_not_authorized"
    if not _covers(authorization.get("scope"), action_scope):
        return "tester_repair_scope_not_authorized"
    return None


def _evidence_roles() -> set[str]:
    """Evidence reuse is limited to the two native evidence-producing roles."""
    return set(EVIDENCE_ROLES)


def _known_evidence_value(key: str, value: Any) -> bool:
    if key == "scope":
        if isinstance(value, str):
            return bool(value.strip())
        return (
            isinstance(value, list)
            and bool(value)
            and all(isinstance(item, str) and item.strip() for item in value)
        )
    if key == "contradiction":
        return value is False
    if key == "path_known":
        return isinstance(value, bool)
    return isinstance(value, str) and bool(value.strip())


def _known_evidence_context(value: Any) -> bool:
    return isinstance(value, dict) and all(
        key in value and _known_evidence_value(key, value[key]) for key in EVIDENCE_KEYS
    )


def _resolve_evidence_handoff(
    state: dict[str, Any], snapshot: dict[str, Any], action_scope: Any
) -> str | None:
    """Resolve provenance to one inspected, succeeded child handoff."""
    provenance = snapshot.get("provenance")
    if not isinstance(provenance, dict):
        return "evidence_provenance_missing"
    required_provenance = ("handoff_id", "child_id", "role", "artifact_digest")
    if any(
        not isinstance(provenance.get(key), str) or not provenance[key].strip()
        for key in required_provenance
    ):
        return "evidence_provenance_missing"
    handoffs = state.get("handoffs", [])
    if not isinstance(handoffs, list):
        return "evidence_handoff_unresolved"
    matches = [
        handoff
        for handoff in handoffs
        if isinstance(handoff, dict) and handoff.get("id") == provenance["handoff_id"]
    ]
    if len(matches) != 1:
        return "evidence_handoff_unresolved"
    handoff = matches[0]
    if handoff.get("inspected") is not True:
        return "evidence_handoff_unresolved"
    if (
        handoff.get("status") != "succeeded"
        or not isinstance(handoff.get("role"), str)
        or handoff.get("role") not in _evidence_roles()
    ):
        return "evidence_handoff_unresolved"
    if handoff.get("artifact_digest") != provenance["artifact_digest"]:
        return "evidence_handoff_digest_mismatch"
    if handoff.get("child_id") != provenance["child_id"] or handoff.get("role") != provenance["role"]:
        return "evidence_handoff_unresolved"
    children = _children(state)
    cited = [child for child in children if child.get("id") == provenance["child_id"]]
    if len(cited) != 1:
        return "evidence_handoff_unresolved"
    child = cited[0]
    if child.get("role") != handoff.get("role") or child.get("status") != "succeeded":
        return "evidence_handoff_unresolved"
    if not _known_evidence_context(handoff):
        return "evidence_handoff_snapshot_malformed"
    if not _covers(child.get("scope"), handoff.get("scope")):
        return "evidence_handoff_scope_not_child_covered"
    if not _covers(handoff.get("scope"), action_scope):
        return "evidence_drift"
    if any(handoff.get(key) != snapshot.get(key) for key in EVIDENCE_KEYS):
        return "evidence_handoff_snapshot_mismatch"
    return None


def _terminal_barrier_result(children: list[dict[str, Any]], kind: str) -> dict[str, Any] | None:
    relevant = [child for child in children if child.get("acceptance_relevant") is True]
    # A failed/blocked/interrupted non-relevant child is ignored unless Sol
    # explicitly marked it for rescope; that rescope still needs inspection.
    checked = list(relevant)
    checked.extend(
        child
        for child in children
        if child.get("rescope") is True and child not in checked
    )
    nonterminal = [child for child in checked if child.get("status") not in TERMINAL]
    if nonterminal:
        reason = "predecessor_nonterminal" if kind == "start_dependent_review" else "acceptance_predecessor_nonterminal"
        return _result("wait", reason, True)
    failed = [child for child in checked if child.get("status") in {"failed", "blocked", "interrupted"}]
    for child in failed:
        if not _structured_disposition(child):
            return _result("wait", "terminal_disposition_required", True)
        if child.get("acceptance_relevant") is True:
            # A disposition records what Sol decided; it never silently turns
            # an acceptance-relevant failed predecessor into complete evidence.
            return _result("deny", "required_evidence_unresolved", True)
        if not _inspectable_terminal(child):
            return _result("wait", "required_evidence_unresolved", True)
    missing_handoff = [
        child
        for child in checked
        if child.get("status") == "succeeded"
        and (child.get("handoff_inspected") is not True or child.get("artifacts_inspected") is not True)
    ]
    if missing_handoff:
        return _result("wait", "handoff_artifacts_missing", True)
    missing_evidence = [
        child
        for child in checked
        if child.get("status") == "succeeded" and not _inspectable_terminal(child)
    ]
    if missing_evidence:
        return _result("wait", "required_evidence_unresolved", True)
    return _result("allow", "predecessors_terminal", True)


def _actor_child(
    children: list[dict[str, Any]], actor: Any, action: dict[str, Any], action_scope: Any
) -> tuple[dict[str, Any] | None, dict[str, Any] | None]:
    if actor not in ROLES:
        return None, None
    actor_child_id = action.get("actor_child_id")
    if not isinstance(actor_child_id, str) or not actor_child_id.strip():
        return None, _result("deny", "actor_identity_invalid")
    matches = [child for child in children if child.get("id") == actor_child_id]
    if len(matches) != 1 or matches[0].get("role") != actor:
        return None, _result("deny", "actor_identity_invalid")
    child = matches[0]
    if child.get("status") not in ACTIVE:
        return None, _result("deny", "actor_child_not_active")
    if not _covers(child.get("scope"), action_scope):
        return None, _result("deny", "actor_scope_escape")
    return child, None


def evaluate(state: dict[str, Any], action: dict[str, Any]) -> dict[str, Any]:
    """Compute one transition without consulting case IDs or expected oracles."""
    if not isinstance(state, dict) or not isinstance(action, dict):
        return _result("deny", "invalid_transition_input")
    actor = action.get("actor")
    kind = action.get("kind")
    action_scope = action.get("scope", [])
    if actor != "primary" and actor not in ROLES:
        return _result("deny", "invalid_actor")
    if not isinstance(kind, str) or not kind.strip():
        return _result("deny", "invalid_action")
    if not isinstance(action_scope, list) or not action_scope or not all(
        isinstance(item, str) and item.strip() for item in action_scope
    ):
        return _result("deny", "invalid_action_scope")
    children = _children(state)
    active_children = _active(children)

    # Control of dependent phases, ACCEPT, waiting, evidence reuse, and child
    # interruption belongs to Sol primary, even when a child supplies
    # otherwise valid-looking data.
    if kind in PRIMARY_CONTROL_KINDS:
        if actor != "primary":
            return _result("deny", "primary_only_action")

    # While any child is active, every substantive primary action needs a
    # directional entry in the ownership ledger.  Control/monitoring actions
    # above are primary-owned and intentionally bypass this scope gate.
    if actor == "primary" and active_children and kind not in PRIMARY_CONTROL_KINDS:
        if not _covers(state.get("primary_orthogonal_scopes", []), action_scope):
            return _result("deny", "orthogonal_scope_not_authorized")

    assigned_child, actor_error = _actor_child(children, actor, action, action_scope)
    if actor_error is not None:
        return actor_error
    if assigned_child is not None:
        active_children = [child for child in active_children if child is not assigned_child]

    if actor in ROLES:
        if kind not in ROLE_ACTION_KINDS[actor]:
            return _result("deny", "role_action_not_authorized")
        if kind in WRITE_KINDS:
            if assigned_child is None or assigned_child.get("writer") is not True:
                return _result("deny", "writer_authorization_required")
            if actor == "tester":
                repair_error = _tester_repair_error(assigned_child, action, action_scope)
                if repair_error is not None:
                    return _result("deny", repair_error)

    if kind in DEPENDENT_KINDS:
        barrier = _terminal_barrier_result(children, kind)
        if barrier is not None:
            return barrier

    if kind == "reuse_evidence":
        current = state.get("evidence")
        if "evidence_snapshot" not in action:
            return _result("invalidate", "evidence_provenance_missing")
        snapshot = action.get("evidence_snapshot")
        if not _known_evidence_context(current) or not _known_evidence_context(snapshot):
            return _result("invalidate", "evidence_context_malformed")
        handoff_error = _resolve_evidence_handoff(state, snapshot, action_scope)
        if handoff_error is not None:
            return _result("invalidate", handoff_error)
        if not _covers(snapshot.get("scope"), action_scope):
            return _result("invalidate", "evidence_drift")
        fresh = (
            all(current.get(key) == snapshot.get(key) for key in EVIDENCE_KEYS)
            and current.get("contradiction") is not True
            and current.get("path_known") is True
            and snapshot.get("contradiction") is not True
            and snapshot.get("path_known") is True
        )
        return _result("reuse", "evidence_fresh") if fresh else _result("invalidate", "evidence_drift")

    if kind in WAIT_KINDS:
        event = action.get("wait_event")
        if event == "silence":
            return _result("wait", "silence_not_abandonment")
        if event == "timeout_no_new_output":
            return _result("wait", "quiet_wait_no_chatter")
        if event in {"new_return", "state_transition", "blocker", "user_decision"}:
            return _result("update", "new_wait_evidence")
        return _result("wait", "wait_for_child_state")

    if kind == "interrupt":
        return (
            _result("allow", "interrupt_authorized")
            if action.get("interrupt_reason") in INTERRUPT_REASONS
            else _result("deny", "interrupt_not_authorized")
        )

    if actor == "primary" and kind in ORTHOGONAL_KINDS:
        allowed = state.get("primary_orthogonal_scopes", [])
        if not _covers(allowed, action_scope):
            return _result("deny", "orthogonal_scope_not_authorized")
        if not any(_overlap(action_scope, child.get("scope")) for child in active_children):
            return _result("allow", "orthogonal_primary_work")

    overlapping = [child for child in active_children if _overlap(action_scope, child.get("scope"))]
    if overlapping:
        worker = next((child for child in overlapping if child.get("role") == "worker"), None)
        if actor == "primary" and kind == "edit_and_test" and worker is not None:
            return _result("deny", "active_worker_owns_write_and_test_scope")
        tester = next((child for child in overlapping if child.get("role") == "tester"), None)
        if actor == "primary" and kind == "browser_qa" and tester is not None:
            return _result("deny", "active_tester_owns_browser_qa")
        owner = next(
            (child.get("role") for child in overlapping if kind in ROLE_OWNERSHIP_KINDS.get(child.get("role"), set())),
            None,
        )
        if owner is not None:
            return _result("deny", f"active_{owner}_owns_{kind}_scope")
        return _result("deny", "active_child_scope_overlap")

    # One shared worktree has one writer.  A non-overlapping scope is still a
    # collision when another active child has writer ownership.
    active_writers = [
        child
        for child in active_children
        if child.get("writer") is True
    ]
    if kind in WRITE_KINDS and active_writers:
        return _result("deny", "shared_worktree_writer_collision")

    return _result("allow", "own_child_continuation" if assigned_child is not None else "scope_available")


def _load(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise SystemExit(f"coordination fixture cannot be loaded: {exc}")
    if not isinstance(data, dict):
        raise SystemExit("coordination fixture must be an object")
    return data


def _set_path(root: Any, path: str, value: Any) -> None:
    cursor = root
    parts = path.split(".")
    for part in parts[:-1]:
        cursor = cursor[int(part)] if isinstance(cursor, list) else cursor[part]
    last = parts[-1]
    if isinstance(cursor, list):
        cursor[int(last)] = value
    else:
        cursor[last] = value


def evaluate_cases(fixture: dict[str, Any]) -> dict[str, dict[str, Any]]:
    cases = fixture.get("cases")
    if not isinstance(cases, list):
        raise SystemExit("coordination fixture cases must be a list")
    result: dict[str, dict[str, Any]] = {}
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise SystemExit("coordination fixture has an invalid case")
        result[case["id"]] = evaluate(case.get("state", {}), case.get("action", {}))
    return result


def self_test(fixture: dict[str, Any]) -> None:
    """Run fixture-declared mutations and prove state/action affect decisions."""
    cases = {case.get("id"): case for case in fixture.get("cases", []) if isinstance(case, dict)}
    mutations = fixture.get("adversarial_mutations")
    if not isinstance(mutations, list) or not mutations:
        raise SystemExit("coordination fixture needs adversarial_mutations")
    for mutation in mutations:
        if not isinstance(mutation, dict):
            raise SystemExit("adversarial mutation must be an object")
        base = cases.get(mutation.get("base_case"))
        if base is None:
            raise SystemExit(f"mutation references unknown base case {mutation.get('base_case')!r}")
        original = evaluate(base.get("state", {}), base.get("action", {}))
        changed_state = copy.deepcopy(base.get("state", {}))
        changed_action = copy.deepcopy(base.get("action", {}))
        for path, value in mutation.get("state_patch", {}).items():
            _set_path(changed_state, path, value)
        for path, value in mutation.get("action_patch", {}).items():
            _set_path(changed_action, path, value)
        changed = evaluate(changed_state, changed_action)
        if changed == original:
            raise SystemExit(f"mutation {mutation.get('id')!r} did not change computed decision")
        expected = mutation.get("expected")
        if not isinstance(expected, dict) or changed != expected:
            raise SystemExit(f"mutation {mutation.get('id')!r} has a wrong computed oracle")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("fixture", type=Path)
    parser.add_argument("--json", action="store_true", dest="as_json")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    fixture = _load(args.fixture)
    if args.self_test:
        self_test(fixture)
        print("coordination evaluator mutation self-test passed")
        return 0
    values = evaluate_cases(fixture)
    if args.as_json:
        print(json.dumps(values, sort_keys=True, separators=(",", ":")))
    else:
        for case_id, value in values.items():
            print(f"{case_id}: {value['decision']} ({value['reason_code']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
