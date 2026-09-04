#!/bin/sh
# Verify the deterministic 0.7.1 coordination contract without network or Git.

set -eu

LC_ALL=C
LANG=C
export LC_ALL LANG

pass() { printf '%s\n' "PASS: $*"; }
fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || fail "python3 is required for coordination verification"

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd) || exit 1
plugin_dir=$(CDPATH= cd "$script_dir/.." && pwd) || exit 1
skill_dir=$plugin_dir/skills/orchestration
fixture=$skill_dir/evals/coordination_cases.json
evaluator=$skill_dir/scripts/evaluate_coordination.py
history=$skill_dir/evals/history/0.7.0-coordination.json
manifest=$skill_dir/manifest.json
skill=$skill_dir/SKILL.md
contracts=$skill_dir/references/role-contracts.md
native=$skill_dir/references/native-v2-lane.md
readme=$(CDPATH= cd "$plugin_dir/../.." && pwd)/README.md
interface=$skill_dir/agents/interface.yaml
openai=$skill_dir/agents/openai.yaml
scorecard_md=$skill_dir/reports/output_quality_scorecard.md
scorecard_json=$skill_dir/reports/output_quality_scorecard.json
trust_md=$skill_dir/reports/security_trust_report.md
trust_json=$skill_dir/reports/security_trust_report.json
risk_md=$skill_dir/reports/output-risk-profile.md
risk_json=$skill_dir/reports/output-risk-profile.json
shell_trust_md=$skill_dir/reports/plugin_shell_trust.md
shell_trust_json=$skill_dir/reports/plugin_shell_trust.json

for required in "$fixture" "$evaluator" "$history" "$manifest" "$skill" "$contracts" "$native" \
  "$interface" "$openai" "$scorecard_md" "$scorecard_json" "$trust_md" "$trust_json" \
  "$risk_md" "$risk_json" "$shell_trust_md" "$shell_trust_json"; do
  [ -f "$required" ] || fail "required coordination file missing: $required"
done

# README is a repository convenience surface, not part of an installed plugin snapshot.
readme_arg=$readme
if [ ! -f "$readme" ]; then
  readme_arg=''
fi

sh -n "$script_dir/verify-coordination.sh"
python3 -B "$evaluator" "$fixture" --self-test

python3 - "$fixture" "$evaluator" "$history" "$manifest" "$skill" "$contracts" "$native" "$readme_arg" \
  "$interface" "$openai" "$scorecard_json" "$trust_json" "$risk_json" "$shell_trust_json" "$plugin_dir" <<'PY'
from __future__ import annotations

from hashlib import sha256
from pathlib import Path
import json
import re
import subprocess
import sys


(
    fixture_arg,
    evaluator_arg,
    history_arg,
    manifest_arg,
    skill_arg,
    contracts_arg,
    native_arg,
    readme_arg,
    interface_arg,
    openai_arg,
    scorecard_arg,
    trust_arg,
    risk_arg,
    shell_trust_arg,
    plugin_dir_arg,
) = sys.argv[1:]
fixture_path = Path(fixture_arg)
evaluator_path = Path(evaluator_arg)
history_path = Path(history_arg)
manifest_path = Path(manifest_arg)
skill_path = Path(skill_arg)
contracts_path = Path(contracts_arg)
native_path = Path(native_arg)
interface_path = Path(interface_arg)
openai_path = Path(openai_arg)
scorecard_path = Path(scorecard_arg)
trust_path = Path(trust_arg)
risk_path = Path(risk_arg)
shell_trust_path = Path(shell_trust_arg)
plugin_dir = Path(plugin_dir_arg)

BASE_COMMIT = "d4c2e588ea9ba9eabb6f5fc028b33a43da0a7fc3"
ROLES = {"deep_explorer", "explorer", "worker", "tester", "reviewer"}
STATUSES = {"active", "not_started", "succeeded", "failed", "blocked", "interrupted"}
DECISIONS = {"allow", "deny", "wait", "update", "reuse", "invalidate"}
REQUIRED_CASES = {
    "allowed_orthogonal_primary_prep",
    "forbidden_same_scope_explorer_duplication",
    "forbidden_primary_edit_tests_while_worker_active",
    "forbidden_primary_browser_qa_while_tester_active",
    "dependent_reviewer_waits_for_worker_terminal",
    "acceptance_waits_for_all_relevant_children",
    "failed_child_requires_terminal_disposition",
    "blocked_child_requires_terminal_disposition",
    "silence_is_not_abandonment",
    "wait_silence_no_chatter",
    "wait_new_child_return_update",
    "wait_state_transition_update",
    "wait_blocker_update",
    "wait_user_decision_update",
    "cross_role_scope_overlap_denied",
    "cross_role_scope_nonoverlap_allowed",
    "two_writer_disjoint_scopes_denied",
    "terminal_ready_dependent_review_allow",
    "handoff_artifact_missing_wait",
    "terminal_ready_accept_allow",
    "interrupted_child_requires_terminal_disposition",
    "authorized_interrupt_allowed",
    "unauthorized_interrupt_denied",
    "fresh_evidence_reuse",
    "drifted_evidence_invalidated",
    "unknown_path_evidence_invalidated",
    "failed_child_with_disposition_still_blocks",
    "successful_evidence_incomplete_wait",
    "all_evidence_complete_allows_accept",
    "explicit_nonrelevant_rescope_inspectable",
    "orthogonal_extra_scope_denied",
    "evidence_extra_scope_invalidated",
    "evidence_missing_provenance_invalidated",
    "same_child_continuation_allow",
    "other_child_overlap_denied",
    "read_only_tester_nonwriter",
    "tester_repair_writer_collision",
    "actor_scope_escape_denied",
    "nonprimary_accept_denied",
    "nonprimary_interrupt_denied",
    "primary_unlisted_disjoint_write_denied",
    "assigned_reviewer_write_denied",
    "assigned_explorer_write_denied",
    "nonprimary_reuse_denied",
    "acceptance_ignores_unrelated_failed_child",
    "tester_repair_authorization_required",
    "valid_sol_ledger_tester_repair_allow",
    "tester_generic_write_denied",
    "tester_generic_edit_denied",
    "tester_generic_write_config_denied",
    "tester_generic_edit_and_test_denied",
    "tester_repair_missing_failed_check_denied",
    "tester_repair_scope_mismatch_denied",
    "tester_repair_round_mismatch_denied",
    "tester_repair_active_worker_collision",
    "resolved_handoff_evidence_reuse",
    "unknown_handoff_invalidated",
    "wrong_handoff_child_invalidated",
    "uninspected_handoff_invalidated",
    "failed_handoff_invalidated",
    "handoff_digest_mismatch_invalidated",
    "handoff_snapshot_mismatch_invalidated",
    "handoff_scope_escape_invalidated",
    "worker_handoff_role_not_admitted",
    "tester_handoff_role_not_admitted",
    "reviewer_handoff_role_not_admitted",
    "child_handoff_scope_mismatch_invalidated",
    "malformed_current_evidence_invalidated",
    "malformed_snapshot_evidence_invalidated",
    "malformed_handoff_evidence_invalidated",
    "worker_incomplete_packet_denied",
    "worker_complete_packet_allowed",
    "tester_before_final_candidate_denied",
    "tester_first_batched_final_allowed",
    "tester_identical_repeat_denied",
    "tester_same_child_drift_correction_allowed",
    "tester_same_child_evidence_gap_allowed",
    "reviewer_before_final_candidate_denied",
    "tester_final_candidate_active_worker_waits",
    "reviewer_final_candidate_active_worker_waits",
    "worker_complete_packet_active_writer_denied",
    "worker_complete_packet_active_predecessor_waits",
    "second_logical_reviewer_denied",
    "same_reviewer_targeted_correction_allowed",
}
EVIDENCE_KEYS = (
    "scope", "branch", "base", "dirty_ownership", "config_runtime",
    "contracts", "contradiction", "path_known",
)
SHELL_INVENTORY = {
    "scripts/install-agents.sh": "installer mutation is limited to the explicit compatibility-agent target directory and its allowlisted agent files; it does not mutate global config or external services",
    "scripts/verify.sh": "read-only package checks plus disposable temporary files cleaned inside the guarded temp boundary",
    "scripts/verify-coordination.sh": "read-only package checks plus disposable temporary files only if future checks declare a guarded boundary",
    "scripts/verify-external-specialist.sh": "read-only package checks; no product or external-service writes",
    "scripts/verify-model-routing.sh": "read-only package checks; no product or external-service writes",
    "scripts/inspect-agent-runtime.sh": "read-only allowlisted rollout inspection plus one guarded temporary match list",
}


def load_json(path: Path, label: str):
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise SystemExit(f"{label} is not valid UTF-8 JSON: {exc}")
    if not isinstance(value, dict):
        raise SystemExit(f"{label} must contain a JSON object")
    return value


def nonempty_string(value, label):
    if not isinstance(value, str) or not value.strip():
        raise SystemExit(f"{label} must be a non-empty string")


def _scope_items(value):
    if isinstance(value, str):
        return [value.strip()] if value.strip() else []
    if isinstance(value, list):
        return [item.strip() for item in value if isinstance(item, str) and item.strip()]
    return []


def read_optional(path_arg: str, label: str) -> str:
    if not path_arg:
        return ""
    path = Path(path_arg)
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise SystemExit(f"{label} cannot be read: {exc}")


fixture = load_json(fixture_path, "coordination fixture")
if fixture.get("schema_version") != "0.7.1-coordination-v1":
    raise SystemExit("coordination fixture has the wrong schema_version")
if fixture.get("fixture_type") != "file-backed fixture" or fixture.get("sanitized") is not True:
    raise SystemExit("coordination fixture must be a sanitized file-backed fixture")
if fixture.get("suite") != "Sol Advisor 0.7.1 coordination state transitions":
    raise SystemExit("coordination fixture has the wrong suite")
route = fixture.get("native_route")
if not isinstance(route, dict):
    raise SystemExit("coordination fixture native_route must be an object")
if route.get("roles") != ["deep_explorer", "explorer", "worker", "tester", "reviewer"]:
    raise SystemExit("coordination fixture must preserve the five native roles in order")
for key, expected in (
    ("fork_turns", "none"),
    ("routes_fixture", "model_routing_cases.json"),
    ("fast_service_tier_missing_semantics", "unobservable"),
):
    if route.get(key) != expected:
        raise SystemExit(f"coordination fixture native_route {key} changed")

holdout = fixture.get("semantic_holdouts", {}).get("strict_micro_edit_predicate")
if holdout != {
    "one_repository": True,
    "one_already_inspected_owned_file": True,
    "genuinely_atomic_settled_change": True,
    "no_active_writer_overlap_or_unclear_dirty_ownership": True,
    "at_most_one_narrow_local_non_browser_check": True,
    "packet_review_overhead_exceeds_saved_context": True,
}:
    raise SystemExit("coordination fixture lost the strict micro-edit predicate holdout")
latency = fixture.get("semantic_holdouts", {}).get("latency_guardrails")
if latency != {
    "whole_phase_worker_packet": True,
    "tester_after_final_candidate": True,
    "tester_rerun_requires_drift_or_evidence_gap": True,
    "reviewer_high_risk_or_explicit_only": True,
    "one_logical_reviewer_per_candidate": True,
    "external_reference_loads_only_when_admitted": True,
    "ab_latency_token_service_tier_evidence": "missing evidence",
}:
    raise SystemExit("coordination fixture lost latency guardrails")

cases = fixture.get("cases")
if not isinstance(cases, list) or len(cases) < len(REQUIRED_CASES):
    raise SystemExit(f"coordination fixture must contain at least {len(REQUIRED_CASES)} cases")
seen_ids = set()
for index, case in enumerate(cases):
    if not isinstance(case, dict):
        raise SystemExit(f"coordination case {index} must be an object")
    for field in ("id", "scenario", "state", "action", "expected", "expected_outcome"):
        if field not in case:
            raise SystemExit(f"coordination case {index} is missing {field}")
    case_id = case["id"]
    nonempty_string(case_id, f"coordination case {index} id")
    if not re.fullmatch(r"[a-z][a-z0-9_]*", case_id):
        raise SystemExit(f"coordination case id is not a stable lowercase identifier: {case_id!r}")
    if case_id in seen_ids:
        raise SystemExit(f"coordination cases duplicate id {case_id!r}")
    seen_ids.add(case_id)
    nonempty_string(case["scenario"], f"coordination case {case_id} scenario")
    nonempty_string(case["expected_outcome"], f"coordination case {case_id} expected_outcome")
    state = case["state"]
    if not isinstance(state, dict) or not isinstance(state.get("children"), list) or not state["children"]:
        raise SystemExit(f"coordination case {case_id} state.children must be a non-empty list")
    child_ids = set()
    for child_index, child in enumerate(state["children"]):
        if not isinstance(child, dict):
            raise SystemExit(f"coordination case {case_id} child {child_index} must be an object")
        for field in ("id", "role", "status", "acceptance_relevant", "scope"):
            if field not in child:
                raise SystemExit(f"coordination case {case_id} child {child_index} is missing {field}")
        nonempty_string(child["id"], f"coordination case {case_id} child id")
        if child["id"] in child_ids:
            raise SystemExit(f"coordination case {case_id} duplicates child id {child['id']!r}")
        child_ids.add(child["id"])
        if child["role"] not in ROLES:
            raise SystemExit(f"coordination case {case_id} has unknown child role {child['role']!r}")
        if child["status"] not in STATUSES:
            raise SystemExit(f"coordination case {case_id} has unknown child status {child['status']!r}")
        if not isinstance(child["acceptance_relevant"], bool):
            raise SystemExit(f"coordination case {case_id} child acceptance_relevant must be boolean")
        if not isinstance(child["scope"], list) or not child["scope"] or not all(isinstance(item, str) and item.strip() for item in child["scope"]):
            raise SystemExit(f"coordination case {case_id} child scope must be a non-empty string list")
        if child["role"] in {"worker", "tester"}:
            if not isinstance(child.get("writer"), bool):
                raise SystemExit(f"coordination case {case_id} {child['role']} must declare boolean writer ownership")
        if "repair_authorization" in child:
            authorization = child["repair_authorization"]
            if child["role"] != "tester" or not isinstance(authorization, dict):
                raise SystemExit(f"coordination case {case_id} repair_authorization must be a tester object")
            for field in ("issued_by", "scope", "failed_check_id", "round", "action"):
                if field not in authorization:
                    raise SystemExit(f"coordination case {case_id} repair_authorization is missing {field}")
            if authorization.get("issued_by") != "sol" or authorization.get("action") != "repair_product":
                raise SystemExit(f"coordination case {case_id} repair_authorization must be issued by Sol for repair_product")
            if not isinstance(authorization.get("scope"), list) or not authorization["scope"] or not all(isinstance(item, str) and item.strip() for item in authorization["scope"]):
                raise SystemExit(f"coordination case {case_id} repair_authorization scope must be a non-empty string list")
            if not isinstance(authorization.get("failed_check_id"), str) or not authorization["failed_check_id"].strip():
                # Keep this as a valid negative fixture so the pure evaluator can
                # prove that a missing failed check denies the attempted repair.
                if case_id != "tester_repair_missing_failed_check_denied":
                    raise SystemExit(f"coordination case {case_id} repair_authorization needs failed_check_id")
            if not isinstance(authorization.get("round"), int) or isinstance(authorization.get("round"), bool) or authorization["round"] < 0:
                raise SystemExit(f"coordination case {case_id} repair_authorization round must be a non-negative integer")
        if "rescope" in child and not isinstance(child["rescope"], bool):
            raise SystemExit(f"coordination case {case_id} child rescope must be boolean")
        if "evidence_complete" in child and not isinstance(child["evidence_complete"], bool):
            raise SystemExit(f"coordination case {case_id} child evidence_complete must be boolean")
        for evidence_field in ("required_evidence", "evidence_present"):
            if evidence_field in child and (
                not isinstance(child[evidence_field], list)
                or not all(isinstance(item, str) and item.strip() for item in child[evidence_field])
            ):
                raise SystemExit(f"coordination case {case_id} child {evidence_field} must be a string list")
        if "disposition" in child and child["disposition"] is not None and not isinstance(child["disposition"], dict):
            raise SystemExit(f"coordination case {case_id} disposition must be a structured object or null")
        if child["status"] in {"failed", "blocked", "interrupted"} and isinstance(child.get("disposition"), dict):
            disposition = child["disposition"]
            if (
                not isinstance(disposition.get("recorded_by"), str)
                or disposition["recorded_by"].strip().lower() != "sol"
                or not isinstance(disposition.get("decision"), str)
                or not disposition["decision"].strip()
            ):
                raise SystemExit(f"coordination case {case_id} child disposition must be a structured Sol decision")
    action = case["action"]
    if not isinstance(action, dict):
        raise SystemExit(f"coordination case {case_id} action must be an object")
    for field in ("actor", "kind", "scope"):
        if field not in action:
            raise SystemExit(f"coordination case {case_id} action is missing {field}")
    if action["actor"] != "primary" and action["actor"] not in ROLES:
        raise SystemExit(f"coordination case {case_id} action actor is not a native role")
    if action["actor"] != "primary":
        if not isinstance(action.get("actor_child_id"), str) or not action["actor_child_id"].strip():
            raise SystemExit(f"coordination case {case_id} role action needs explicit actor_child_id")
        matching_actor = [child for child in state["children"] if child.get("id") == action["actor_child_id"]]
        if len(matching_actor) != 1 or matching_actor[0].get("role") != action["actor"]:
            raise SystemExit(f"coordination case {case_id} actor_child_id does not identify its native role child")
    nonempty_string(action["kind"], f"coordination case {case_id} action kind")
    if not isinstance(action["scope"], list) or not action["scope"] or not all(isinstance(item, str) and item.strip() for item in action["scope"]):
        raise SystemExit(f"coordination case {case_id} action scope must be a non-empty string list")
    if "round" in action and (not isinstance(action["round"], int) or isinstance(action["round"], bool) or action["round"] < 0):
        raise SystemExit(f"coordination case {case_id} action round must be a non-negative integer")
    if "repair_authorized" in action and not isinstance(action["repair_authorized"], bool):
        raise SystemExit(f"coordination case {case_id} action repair_authorized must be boolean")
    expected = case["expected"]
    if not isinstance(expected, dict):
        raise SystemExit(f"coordination case {case_id} expected must be an object")
    for field in ("decision", "reason_code", "terminal_barrier"):
        if field not in expected:
            raise SystemExit(f"coordination case {case_id} expected is missing {field}")
    if expected["decision"] not in DECISIONS:
        raise SystemExit(f"coordination case {case_id} has unknown expected decision {expected['decision']!r}")
    nonempty_string(expected["reason_code"], f"coordination case {case_id} expected reason_code")
    if not isinstance(expected["terminal_barrier"], bool):
        raise SystemExit(f"coordination case {case_id} expected terminal_barrier must be boolean")
    handoffs = state.get("handoffs", [])
    if not isinstance(handoffs, list):
        raise SystemExit(f"coordination case {case_id} state.handoffs must be a list")
    handoff_ids = set()
    for handoff_index, handoff in enumerate(handoffs):
        if not isinstance(handoff, dict):
            raise SystemExit(f"coordination case {case_id} handoff {handoff_index} must be an object")
        for field in ("id", "child_id", "role", "status", "inspected", "artifact_digest", *EVIDENCE_KEYS):
            if field not in handoff:
                raise SystemExit(f"coordination case {case_id} handoff {handoff_index} is missing {field}")
        nonempty_string(handoff["id"], f"coordination case {case_id} handoff id")
        if handoff["id"] in handoff_ids:
            raise SystemExit(f"coordination case {case_id} duplicates handoff id {handoff['id']!r}")
        handoff_ids.add(handoff["id"])
        nonempty_string(handoff["child_id"], f"coordination case {case_id} handoff child_id")
        if not isinstance(handoff["role"], str) or not isinstance(handoff["status"], str) or handoff["child_id"] not in child_ids or handoff["role"] not in ROLES or handoff["status"] not in STATUSES:
            raise SystemExit(f"coordination case {case_id} handoff identity/status is invalid")
        if not isinstance(handoff["inspected"], bool):
            raise SystemExit(f"coordination case {case_id} handoff inspected must be boolean")
        nonempty_string(handoff["artifact_digest"], f"coordination case {case_id} handoff artifact_digest")
        if not isinstance(handoff["scope"], (str, list)) or not _scope_items(handoff["scope"]):
            raise SystemExit(f"coordination case {case_id} handoff scope must be non-empty")
if not REQUIRED_CASES.issubset(seen_ids):
    raise SystemExit(f"coordination fixture is missing required case ids: {', '.join(sorted(REQUIRED_CASES - seen_ids))}")

mutations = fixture.get("adversarial_mutations")
if not isinstance(mutations, list) or len(mutations) < 10:
    raise SystemExit("coordination fixture needs at least ten adversarial mutations")
mutation_ids = set()
for mutation in mutations:
    if not isinstance(mutation, dict):
        raise SystemExit("adversarial mutation must be an object")
    nonempty_string(mutation.get("id"), "adversarial mutation id")
    if mutation["id"] in mutation_ids:
        raise SystemExit(f"adversarial mutations duplicate id {mutation['id']!r}")
    mutation_ids.add(mutation["id"])
    if mutation.get("base_case") not in seen_ids:
        raise SystemExit(f"adversarial mutation references unknown case {mutation.get('base_case')!r}")

computed_run = subprocess.run(
    [sys.executable, "-B", str(evaluator_path), str(fixture_path), "--json"],
    check=False,
    capture_output=True,
    text=True,
)
if computed_run.returncode != 0:
    raise SystemExit(f"coordination evaluator failed: {computed_run.stderr.strip()}")
try:
    computed = json.loads(computed_run.stdout)
except json.JSONDecodeError as exc:
    raise SystemExit(f"coordination evaluator did not emit JSON: {exc}")
if not isinstance(computed, dict) or set(computed) != seen_ids:
    raise SystemExit("coordination evaluator output does not cover exactly the fixture case IDs")
for case in cases:
    actual = computed[case["id"]]
    expected = case["expected"]
    if actual != expected:
        raise SystemExit(
            f"computed transition disagrees with fixture oracle for {case['id']}: "
            f"computed={actual!r} expected={expected!r}"
        )
evaluator_source = evaluator_path.read_text(encoding="utf-8")
for token in (
    "def _covers",
    "def _overlap",
    "PRODUCT_WRITE_KINDS",
    "repair_product",
    "repair_authorization",
    "failed_check_id",
    "evidence_snapshot",
    "evidence_handoff",
    "handoffs",
    "artifact_digest",
    "actor_child_id",
    "writer",
    "WAIT_KINDS",
    "PRIMARY_CONTROL_KINDS",
    "ROLE_ACTION_KINDS",
    "primary_only_action",
    "orthogonal_scope_not_authorized",
    "role_action_not_authorized",
    "tester_repair_authorization_required",
    "terminal_disposition_required",
    "required_evidence_unresolved",
    "evidence_handoff_unresolved",
    "evidence_handoff_digest_mismatch",
    "evidence_handoff_snapshot_mismatch",
    "EVIDENCE_ROLES",
    "_evidence_roles",
    "_known_evidence_value",
    "_known_evidence_context",
    "evidence_handoff_scope_not_child_covered",
    "evidence_context_malformed",
    "evidence_handoff_snapshot_malformed",
    "not a runtime scheduler",
    "worker_packet_incomplete",
    "tester_requires_final_candidate",
    "identical_tester_repeat_denied",
    "same_tester_correction_authorized",
    "reviewer_requires_final_candidate",
    "second_logical_reviewer_denied",
    "same_reviewer_targeted_correction",
    "def _writer_collision_result",
    "Global safety invariants precede latency admission",
):
    if token not in evaluator_source:
        raise SystemExit(f"coordination evaluator is missing semantic implementation {token!r}")
if "EXPECTED" in evaluator_source:
    raise SystemExit("coordination evaluator must not use a hardcoded EXPECTED decision map")
if "allowed_evidence_roles" in evaluator_source or "state.get(\"allowed_evidence_roles\")" in evaluator_source:
    raise SystemExit("evidence roles must not be state-expandable")

history = load_json(history_path, "coordination history")
if history.get("schema_version") != "0.7.0-coordination-history-v1" or history.get("release") != "0.7.0":
    raise SystemExit("coordination history has the wrong release/schema")
base = history.get("base")
if not isinstance(base, dict) or base.get("release") != "0.6.8" or base.get("commit") != BASE_COMMIT:
    raise SystemExit("coordination history must identify the 0.6.8 base commit")
history_fixture = history.get("fixture")
if not isinstance(history_fixture, dict) or history_fixture.get("type") != "file-backed fixture" or history_fixture.get("path") != "evals/coordination_cases.json" or history_fixture.get("sanitized") is not True:
    raise SystemExit("coordination history must identify the shared sanitized file-backed fixture")
computed_evidence = history.get("computed_state_transition_evidence")
if not isinstance(computed_evidence, dict) or computed_evidence.get("fixture_cases") != 73 or computed_evidence.get("computed_fixture_violations") != 0 or computed_evidence.get("expected_oracle_matches") is not True or computed_evidence.get("mutation_checks") != 50:
    raise SystemExit("coordination history does not report computed evaluator evidence")
if "observed_deterministic_evidence" in history:
    raise SystemExit("coordination history must use computed evidence names, not observed runtime claims")
missing = history.get("missing_evidence")
if not isinstance(missing, list) or not missing or not all(isinstance(item, str) and item.strip() for item in missing):
    raise SystemExit("coordination history needs a separate non-empty missing_evidence list")
if history.get("user_direction") != "主代理等待的时候不要说无关的东西，如果能看到子代理的返回，可以说，如果看不到只是等待，就不要碎碎念":
    raise SystemExit("coordination history must preserve the waiting-silence user direction")

manifest = load_json(manifest_path, "skill manifest")
if manifest.get("version") != "0.7.1" or manifest.get("updated_at") != "2026-09-04":
    raise SystemExit("skill manifest version/date are not 0.7.1/2026-09-04")
if manifest.get("maturity_tier") != "governed" or manifest.get("lifecycle_stage") != "governed" or manifest.get("review_cadence") != "monthly":
    raise SystemExit("skill manifest does not declare governed monthly lifecycle")
if manifest.get("context_budget_tier") != "production":
    raise SystemExit("skill manifest must retain context_budget_tier=production")
components = manifest.get("factory_components")
if not isinstance(components, list) or not {"references", "evals", "reports", "scripts"}.issubset(components):
    raise SystemExit("factory_components must truthfully cover references, evals, reports, and scripts")
for label, key in (
    ("input_contract", "file-backed fixture"),
    ("input_contract", "input_files"),
    ("output_contract", "output contract"),
    ("output_contract", "trust report"),
    ("output_contract", "reports/output_quality_scorecard.md"),
    ("output_contract", "missing evidence"),
    ("rollback_boundary", "rollback boundary"),
):
    if key not in manifest.get(label, ""):
        raise SystemExit(f"skill manifest {label} is missing Yao boundary label {key!r}")

skill = skill_path.read_text(encoding="utf-8")
contracts = contracts_path.read_text(encoding="utf-8")
native = native_path.read_text(encoding="utf-8")
readme = read_optional(readme_arg, "optional README")
interface = interface_path.read_text(encoding="utf-8")
openai = openai_path.read_text(encoding="utf-8")
docs = {"SKILL.md": skill, "role-contracts.md": contracts, "native-v2-lane.md": native, "README.md": readme, "interface.yaml": interface, "openai.yaml": openai}
combined = "\n".join(docs.values())
def frontmatter_top_level_keys(text):
    match = re.match(r"^---\n(.*?)\n---(?:\n|$)", text, re.DOTALL)
    if not match:
        raise ValueError("frontmatter is missing or malformed")
    keys = set()
    for line in match.group(1).splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip(" "))
        if indent:
            continue
        if ":" not in line:
            raise ValueError("top-level frontmatter entry has no key separator")
        key = line.split(":", 1)[0].strip()
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_-]*", key):
            raise ValueError(f"invalid top-level frontmatter key {key!r}")
        keys.add(key)
    return keys

try:
    frontmatter_keys = frontmatter_top_level_keys(skill)
except ValueError as exc:
    raise SystemExit(f"SKILL.md frontmatter is invalid: {exc}")
if frontmatter_keys - {"name", "description", "license", "allowed-tools", "metadata"}:
    raise SystemExit("SKILL.md has unsupported frontmatter keys")
try:
    legal_nested = frontmatter_top_level_keys(
        "---\nname: orchestration\ndescription: test\nmetadata:\n  version: 0.7.0\n---\n"
    )
    illegal_top_level = frontmatter_top_level_keys(
        "---\nname: orchestration\ndescription: test\nversion: 0.7.0\n---\n"
    )
except ValueError as exc:
    raise SystemExit(f"frontmatter guard self-test failed: {exc}")
if "version" in legal_nested or "version" not in illegal_top_level:
    raise SystemExit("frontmatter guard nested-metadata self-test failed")
strict_predicate = (
    "one repository",
    "one already-inspected owned file",
    "genuinely atomic settled change",
    "no active writer/overlap/unclear dirty ownership",
    "at most one narrow local non-browser check",
    "packet and review overhead exceeds saved context",
)
if not all(token in skill for token in strict_predicate):
    raise SystemExit("SKILL.md is missing the complete strict micro-edit predicate")
required_tokens = (
    "active-child", "ownership ledger", "nonterminal", "explicitly allowed orthogonal primary work",
    "do not duplicate", "terminal coordination barrier", "acceptance-relevant predecessor", "failed", "blocked",
    "records their disposition", "missing evidence", "long `wait_agent`", "list_agents", "one factual `send_message`",
    "Silence", "not abandonment", "no user-facing status/chatter", "evidence freshness", "Invalidate",
    "worker owns tracked", "tester owns", "narrowest local non-browser", "at most one logical reviewer", "after the final candidate",
)
for token in required_tokens:
    if token.lower() not in combined.lower():
        raise SystemExit(f"normative documents are missing coordination token {token!r}")
if 'mode: "manual"' not in interface or "adapter invocation metadata" not in interface or "global AGENTS default supplies always-on routing" not in interface:
    raise SystemExit("interface activation metadata does not clarify manual adapter invocation")
if "0.7.1" not in skill or "0.7.1" not in openai or (readme and "0.7.1" not in readme):
    raise SystemExit("human-facing coordination surfaces are missing 0.7.1")
for role in ROLES:
    for label, document in (("SKILL.md", skill), ("role-contracts.md", contracts), ("native-v2-lane.md", native)):
        if role not in document:
            raise SystemExit(f"native role {role} is missing from {label}")
for field in ("agent_type=default", "agent_type=tester", "logical_role", "route_class", "fork_turns=none"):
    for label, document in (("SKILL.md", skill), ("role-contracts.md", contracts), ("native-v2-lane.md", native)):
        if field not in document:
            raise SystemExit(f"{label} is missing explicit native route field {field}")

scorecard = load_json(scorecard_path, "output quality scorecard")
if scorecard.get("release") != "0.7.1" or scorecard.get("fixture", {}).get("path") != "evals/coordination_cases.json":
    raise SystemExit("output quality scorecard does not identify the 0.7.1 shared fixture")
if scorecard.get("baseline", {}).get("release") != "0.6.8" or scorecard.get("baseline", {}).get("commit") != BASE_COMMIT:
    raise SystemExit("output quality scorecard does not identify the 0.6.8 base")
if scorecard.get("computed_state_transition_evidence", {}).get("computed_fixture_violations") != 0:
    raise SystemExit("scorecard computed fixture evidence is not a zero-violation pass")
gates = scorecard.get("required_gates")
if not isinstance(gates, dict):
    raise SystemExit("output quality scorecard required_gates must be an object")
for gate in ("zero_same_scope_active_child_overlap", "zero_preterminal_dependent_phase_or_acceptance"):
    entry = gates.get(gate)
    if not isinstance(entry, dict) or entry.get("computed_fixture_violations") != 0 or entry.get("status") != "pass":
        raise SystemExit(f"output quality scorecard gate {gate} is not a computed deterministic pass")
suite_gate = gates.get("existing_route_robustness_safety_suites_non_regressed")
if not isinstance(suite_gate, dict) or suite_gate.get("status") != "pass":
    raise SystemExit("output quality scorecard route/robustness/safety gate is not a pass")
if any("observed" in entry for entry in gates.values() if isinstance(entry, dict)):
    raise SystemExit("scorecard must not label runtime gates as observed")
latency = scorecard.get("runtime_latency_target")
if not isinstance(latency, dict) or latency.get("p50_improvement_target_percent") != 20 or latency.get("p90_target") != "no worse" or latency.get("status") != "missing evidence":
    raise SystemExit("output quality scorecard must disclose missing runtime A/B evidence")
if not isinstance(scorecard.get("missing_evidence"), list) or not scorecard["missing_evidence"]:
    raise SystemExit("output quality scorecard needs missing_evidence")

for path, label in ((trust_path, "security trust report"), (risk_path, "output risk profile")):
    load_json(path, label)
trust = load_json(trust_path, "security trust report")
if trust.get("scope") != "skills/orchestration" or "not package-wide shell trust" not in trust.get("scope_note", ""):
    raise SystemExit("Yao trust report must explicitly state its skills/orchestration-only scope")
TRUST_SCAN_DIRS = ("agents", "assets", "docs", "evals", "references", "runtime", "scripts", "security", "skill-ir", "templates")
TRUST_ROOT_FILES = ("SKILL.md", "README.md", "manifest.json", "requirements-ci.txt", "Makefile")
TRUST_TEXT_SUFFIXES = {".css", ".js", ".md", ".json", ".jsonl", ".yaml", ".yml", ".py", ".sh", ".txt", ".toml"}


def trust_source_files(root: Path):
    files = [root / name for name in TRUST_ROOT_FILES if (root / name).is_file()]
    for directory in TRUST_SCAN_DIRS:
        folder = root / directory
        if not folder.is_dir():
            continue
        for path in sorted(folder.rglob("*")):
            if path.is_file() and not path.is_symlink() and path.suffix in TRUST_TEXT_SUFFIXES and path.stat().st_size <= 1_000_000:
                files.append(path)
    return sorted(set(files))


def trust_package_digest(files, root: Path, mutate_first=False):
    digest = sha256()
    for index, path in enumerate(files):
        relative = str(path.relative_to(root))
        content = path.read_bytes()
        if mutate_first and index == 0:
            content += b"\ncoordination-digest-mutation\n"
        digest.update(relative.encode("utf-8"))
        digest.update(b"\0")
        digest.update(sha256(content).hexdigest().encode("ascii"))
        digest.update(b"\0")
    return digest.hexdigest()


trust_summary = trust.get("summary")
if not isinstance(trust_summary, dict) or trust_summary.get("package_hash_scope") != "source-contract-without-generated-reports":
    raise SystemExit("Yao trust report has an unexpected package hash scope")
skill_root = skill_path.parent
trust_files = trust_source_files(skill_root)
computed_digest = trust_package_digest(trust_files, skill_root)
if trust_summary.get("package_hash_file_count") != len(trust_files) or trust_summary.get("scanned_files") != len(trust_files) or trust_summary.get("package_sha256") != computed_digest:
    raise SystemExit(f"Yao trust report package digest/file count is stale: root={skill_path} report={trust_summary.get('package_sha256')}/{trust_summary.get('package_hash_file_count')} computed={computed_digest}/{len(trust_files)}")
if trust_package_digest(trust_files, skill_root, mutate_first=True) == computed_digest:
    raise SystemExit("Yao trust digest mutation self-test did not change the digest")
trust_markdown = trust_path.with_suffix(".md").read_text(encoding="utf-8")
if f"Package hash files: `{len(trust_files)}`" not in trust_markdown or f"Package SHA256: `{computed_digest}`" not in trust_markdown:
    raise SystemExit("Yao trust Markdown digest/file count is stale")

shell_report = load_json(shell_trust_path, "plugin shell trust report")
if shell_report.get("schema_version") != "0.7.1-plugin-shell-trust-v1" or shell_report.get("scope") != "plugins/sol-advisor/scripts/*.sh":
    raise SystemExit("plugin shell trust report has the wrong schema or scope")
entries = shell_report.get("scripts")
if not isinstance(entries, list) or {entry.get("path") for entry in entries if isinstance(entry, dict)} != set(SHELL_INVENTORY):
    raise SystemExit("plugin shell trust report inventory does not match every shipped shell script")
if shell_report.get("checks", {}).get("exact_inventory") is not True or shell_report.get("checks", {}).get("network_capability_scan") != "pass" or shell_report.get("checks", {}).get("hashes") != "pass":
    raise SystemExit("plugin shell trust report does not record all required checks")
network_words = ["cu" + "rl", "w" + "get", "s" + "sh", "s" + "cp", "n" + "c", "tel" + "net"]
network_re = re.compile((r"(?:\b(?:%s)\b|\bopen" + "ssl\\s+s_client\\b|https?" + r"://)") % "|".join(network_words), re.IGNORECASE)
for entry in entries:
    relative = entry["path"]
    script = plugin_dir / relative
    if not script.is_file():
        raise SystemExit(f"plugin shell trust inventory points to missing script {relative}")
    content = script.read_text(encoding="utf-8")
    digest = sha256(content.encode("utf-8")).hexdigest()
    if entry.get("sha256") != digest or entry.get("syntax") != "pass":
        raise SystemExit(f"plugin shell trust hash/syntax evidence is stale for {relative}")
    if network_re.search(content) or entry.get("network_capabilities") != []:
        raise SystemExit(f"plugin shell trust network scan is not clean for {relative}")
    if entry.get("file_write_classification") != SHELL_INVENTORY[relative] or not isinstance(entry.get("side_effect_classification"), str) or not entry["side_effect_classification"].strip():
        raise SystemExit(f"plugin shell trust side-effect classification is incomplete for {relative}")
    subprocess.run(["sh", "-n", str(script)], check=True)
installer = next(entry for entry in entries if entry["path"] == "scripts/install-agents.sh")
if "explicit compatibility-agent target" not in installer.get("installer_mutation_boundary", "") or "global config" not in installer.get("installer_mutation_boundary", ""):
    raise SystemExit("installer trust evidence does not state its explicit mutation boundary")

print(f"computed coordination evaluator, {len(cases)} unique transitions, {len(mutations)} mutations, reports, shell hashes, and normative docs validated")
PY

pass "0.7.1 computed active-child lock, terminal barrier, latency policy, evidence reuse/invalidation, and report contracts"
