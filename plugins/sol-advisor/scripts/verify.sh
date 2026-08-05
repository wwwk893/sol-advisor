#!/bin/sh
# Repository-local verification for Sol Advisor 0.6.0.

set -eu

pass() { printf '%s\n' "PASS: $*"; }
fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd) || exit 1
plugin_dir=$(CDPATH= cd "$script_dir/.." && pwd) || exit 1
repo_dir=$(CDPATH= cd "$plugin_dir/../.." && pwd) || exit 1
installer=$script_dir/install-agents.sh
runtime_inspector=$script_dir/inspect-agent-runtime.sh
templates=$plugin_dir/agents
manifest=$plugin_dir/.codex-plugin/plugin.json
skill=$plugin_dir/skills/orchestration/SKILL.md
contracts=$plugin_dir/skills/orchestration/references/role-contracts.md
native_contract=$plugin_dir/skills/orchestration/references/native-v2-lane.md
luna_contract=$plugin_dir/skills/orchestration/references/luna-task-lane.md
readme=$repo_dir/README.md
ui=$plugin_dir/skills/orchestration/agents/openai.yaml
interface=$plugin_dir/skills/orchestration/agents/interface.yaml
skill_manifest=$plugin_dir/skills/orchestration/manifest.json
trigger_cases=$plugin_dir/skills/orchestration/evals/trigger_cases.json
semantic_config=$plugin_dir/skills/orchestration/evals/semantic_config.json

for required in "$installer" "$runtime_inspector" "$manifest" "$skill" "$contracts" \
  "$native_contract" "$luna_contract" "$readme" "$ui" "$interface" \
  "$skill_manifest" "$trigger_cases" "$semantic_config"; do
  test -f "$required" || fail "required file missing: $required"
done

tmp_base=${TMPDIR:-/tmp}
case "$tmp_base" in /*) ;; *) tmp_base=/tmp ;; esac
tmp_dir=''
cleanup() {
  if [ -n "$tmp_dir" ] && [ -d "$tmp_dir" ]; then
    case "$tmp_dir" in
      "$tmp_base"/sol-advisor-verify.*) rm -rf "$tmp_dir" ;;
      *) printf '%s\n' "REFUSING cleanup of unexpected directory: $tmp_dir" >&2 ;;
    esac
  fi
}
trap cleanup 0 HUP INT TERM
tmp_dir=$(mktemp -d "$tmp_base/sol-advisor-verify.XXXXXX") || fail "could not create disposable verification directory"

jq empty "$manifest"
jq empty "$skill_manifest"
jq empty "$trigger_cases"
jq empty "$semantic_config"
python3 - "$manifest" "$skill" "$contracts" "$native_contract" "$luna_contract" "$readme" "$ui" "$interface" "$skill_manifest" "$trigger_cases" "$semantic_config" <<'PY'
from pathlib import Path
import json
import sys

manifest_path, *paths = sys.argv[1:]
doc_paths = paths[:6]
interface_path, skill_manifest_path, trigger_cases_path, semantic_config_path = paths[6:]
manifest = json.loads(Path(manifest_path).read_text(encoding="utf-8"))
if manifest.get("version") != "0.6.0":
    raise SystemExit(f"manifest version is {manifest.get('version')!r}, expected 0.6.0")
prompts = manifest.get("interface", {}).get("defaultPrompt")
if not isinstance(prompts, list) or not prompts or not all(isinstance(p, str) and p.strip() for p in prompts):
    raise SystemExit("manifest defaultPrompt must be a non-empty list of strings")
if any(len(p) > 128 for p in prompts):
    raise SystemExit("manifest defaultPrompt contains a value longer than 128 characters")
description = manifest.get("description", "")
interface = manifest.get("interface", {})
for value, label in (
    (description, "manifest description"),
    (interface.get("longDescription", ""), "manifest longDescription"),
):
    if not all(token in value for token in ("native", "Luna")):
        raise SystemExit(f"{label} does not describe the native Luna lane")

docs = {Path(path).name: Path(path).read_text(encoding="utf-8") for path in doc_paths}
skill, contracts, native, luna, readme, ui = [docs[Path(path).name] for path in doc_paths]
interface_text = Path(interface_path).read_text(encoding="utf-8")
skill_manifest = json.loads(Path(skill_manifest_path).read_text(encoding="utf-8"))
trigger_cases = json.loads(Path(trigger_cases_path).read_text(encoding="utf-8"))
semantic_config = json.loads(Path(semantic_config_path).read_text(encoding="utf-8"))
for key, value in (
    ("canonical_format", "codex-plugin-skill"),
    ("adapter_targets", "openai"),
    ("mode", "manual"),
    ("context", "inline"),
    ("shell", "bash"),
    ("source_tier", "plugin"),
    ("remote_inline_execution", "forbid"),
    ("remote_metadata_policy", "allow-metadata-only"),
):
    if value not in interface_text:
        raise SystemExit(f"interface.yaml missing {key}={value}")
if "openai:" not in interface_text or "Native V2" not in interface_text:
    raise SystemExit("interface.yaml missing native V2 openai degradation")
for key, expected in (
    ("version", "0.6.0"),
    ("owner", "wwwk893"),
    ("updated_at", "2026-08-05"),
    ("lifecycle_stage", "production"),
    ("context_budget_tier", "production"),
    ("review_cadence", "runtime/routing changes"),
):
    if skill_manifest.get(key) != expected:
        raise SystemExit(f"skill manifest {key} does not equal {expected!r}")
if skill_manifest.get("target_platforms") != ["openai-codex"]:
    raise SystemExit("skill manifest target_platforms must be openai-codex")
if skill_manifest.get("factory_components") != ["references", "evals"]:
    raise SystemExit("skill manifest factory_components must list references and evals only")
for key in ("input_contract", "output_contract", "rollback_boundary"):
    if not isinstance(skill_manifest.get(key), str) or not skill_manifest[key].strip():
        raise SystemExit(f"skill manifest missing {key}")
for bucket in ("should_trigger", "should_not_trigger", "near_neighbor"):
    if not isinstance(trigger_cases.get(bucket), list) or not trigger_cases[bucket]:
        raise SystemExit(f"trigger cases bucket {bucket} is empty")
if not semantic_config.get("positive_concepts") or not semantic_config.get("negative_concepts"):
    raise SystemExit("semantic config needs positive and negative concepts")
ui_prompt = next(
    (
        line.split(":", 1)[1].strip().strip('"')
        for line in ui.splitlines()
        if line.strip().startswith("default_prompt:")
    ),
    "",
)
if not ui_prompt or len(ui_prompt) > 128:
    raise SystemExit("openai.yaml default_prompt must be present and at most 128 characters")
roles = {"deep_explorer", "explorer", "worker", "tester", "reviewer"}
tools = {"spawn_agent", "list_agents", "wait_agent", "followup_task", "send_message", "interrupt_agent"}
for role in roles:
    if role not in skill or role not in contracts or role not in native or role not in readme:
        raise SystemExit(f"native role {role} is not documented in every required contract")
for tool in tools:
    if tool not in skill or tool not in native:
        raise SystemExit(f"native tool {tool} is missing from the default lane")
for token in (
    "gpt-5.6-luna",
    "max",
    "priority",
    "hard prerequisites",
    "silent fallback",
    "fork_turns=none",
    "same child",
):
    if token not in skill or token not in contracts or token not in native:
        raise SystemExit(f"native routing contract is missing {token!r}")
for field in ("model=gpt-5.6-luna", "reasoning_effort=max", "fork_turns=none"):
    for document, label in ((skill, "SKILL"), (contracts, "role contracts"), (native, "native lane")):
        if field not in document:
            raise SystemExit(f"{label} lacks explicit native route field {field!r}")
for token in ("same child", "bounded repair/test-only", "otherwise return a blocker"):
    if token not in skill or token not in contracts or token not in native:
        raise SystemExit(f"tester/correction contract is missing {token!r}")
for token in ("narrowest decisive acceptance subset", "risk or impact warrants"):
    if token not in skill or token not in contracts or token not in native:
        raise SystemExit(f"acceptance subset contract is missing {token!r}")
for token in ("does not require", "app-task", "compatibility", "Terra/Sol"):
    if not all(token.lower() in document.lower() for document in (skill, native, readme)):
        raise SystemExit(f"default/compatibility separation is missing {token!r}")
if "not the default" not in luna.lower() or "explicit" not in luna.lower():
    raise SystemExit("Luna compatibility contract is not explicitly opt-in")
for tool in ("list_projects", "list_threads", "create_thread", "wait_threads", "read_thread", "send_message_to_thread"):
    if tool not in luna:
        raise SystemExit(f"Luna compatibility contract missing app tool {tool}")
for token in (
    "clientThreadId",
    "threadId",
    "hostId",
    "PR AUTHORIZED FOR",
    "OBJECTIVE",
    "FILES AND OWNERSHIP",
    "INTERFACES",
    "CONSTRAINTS",
    "STARTING STATE / BASE",
    "VERIFICATION",
    "GIT / PR BOUNDARY",
    "STRUCTURED RETURN",
):
    if token.lower() not in luna.lower():
        raise SystemExit(f"Luna compatibility contract missing {token}")
if "default" not in ui.lower() or "native luna v2" not in ui.lower():
    raise SystemExit("openai metadata does not describe the native V2 default")
if "default" not in readme.lower() or "legacy" not in readme.lower():
    raise SystemExit("README does not separate default and legacy lanes")
for requirement in ("python3", "GNU readlink", "POSIX sh", "jq", "shasum"):
    if requirement.lower() not in readme.lower():
        raise SystemExit(f"README missing installer/core requirement {requirement}")
print("native V2/default and compatibility contracts are structurally present")
PY
pass "0.6.0 metadata, role inventory, native tools, and compatibility separation"

python3 - "$templates" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
expected = {
    "sol-advisor-terra-implementer.toml": {
        "name": "sol_advisor_terra_implementer",
        "model": "gpt-5.6-terra",
        "model_reasoning_effort": "high",
    },
    "sol-advisor-sol-reviewer.toml": {
        "name": "sol_advisor_sol_reviewer",
        "model": "gpt-5.6-sol",
        "model_reasoning_effort": "high",
        "sandbox_mode": "read-only",
    },
}

def top_level_fields(path):
    fields = {}
    lines = path.read_text(encoding="utf-8").splitlines()
    index = 0
    while index < len(lines):
        line = lines[index].strip()
        index += 1
        if not line or line.startswith("#"):
            continue
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$", line)
        if not match:
            continue
        key, rhs = match.groups()
        if key in fields:
            raise SystemExit(f"{path.name}: duplicate top-level {key}")
        if rhs.startswith('"""'):
            body = rhs[3:]
            chunks = []
            if body.endswith('"""'):
                chunks.append(body[:-3])
            else:
                chunks.append(body)
                while index < len(lines):
                    body = lines[index]
                    index += 1
                    if body.endswith('"""'):
                        chunks.append(body[:-3])
                        break
                    chunks.append(body)
            fields[key] = "\n".join(chunks).strip()
            continue
        quoted = re.fullmatch(r'"([^"\\]*(?:\\.[^"\\]*)*)"(?:\s*#.*)?', rhs)
        if quoted:
            fields[key] = quoted.group(1).strip()
    return fields

actual = {path.name for path in root.glob("*.toml")}
if actual != set(expected):
    raise SystemExit(f"legacy compatibility inventory changed: {sorted(actual)}")
for filename, required in expected.items():
    fields = top_level_fields(root / filename)
    for key, value in required.items():
        if fields.get(key) != value:
            raise SystemExit(f"{filename}: {key}={fields.get(key)!r}, expected {value!r}")
    for key in ("name", "description", "model", "model_reasoning_effort", "developer_instructions"):
        if not fields.get(key):
            raise SystemExit(f"{filename}: missing or empty top-level {key}")
print("legacy Terra/Sol compatibility templates are structurally role-pinned")
PY
pass "legacy Terra/Sol files remain opt-in compatibility only"

sh -n "$installer"
sh -n "$runtime_inspector"
sh -n "$script_dir/verify.sh"
pass "shell syntax"

terra_file=sol-advisor-terra-implementer.toml
sol_file=sol-advisor-sol-reviewer.toml
luna_file=sol-advisor-luna-implementer.toml
legacy_terra_sha256=4425a8c1f21ce8c6af93f96adc253bbc33ea301f1389b3fa8ce350be08584eca
legacy_luna_sha256=fba1b42849d93737e83b094a2ab0b1611f87ac37db7438c8bbdf581f0813f8eb

snapshot_files() {
  target=$1
  if [ ! -d "$target" ]; then
    printf '%s\n' MISSING
    return
  fi
  find "$target" -mindepth 1 -maxdepth 1 -print | LC_ALL=C sort | while IFS= read -r path; do
    if [ -L "$path" ]; then
      printf 'L %s -> %s\n' "$(basename "$path")" "$(readlink "$path")"
    elif [ -f "$path" ]; then
      shasum -a 256 "$path"
    else
      printf 'O %s\n' "$(basename "$path")"
    fi
  done
}

write_legacy_roles() {
  target=$1
  mkdir -p "$target"
  cat > "$target/$terra_file" <<'LEGACY_TERRA'
name = "sol_advisor_terra_implementer"
description = "Sol Advisor's complex implementation lane for context-heavy or higher-risk work."
model = "gpt-5.6-terra"
model_reasoning_effort = "max"

developer_instructions = """
You are Sol Advisor's complex implementation worker. Resolve difficult implementation
details within the settled architecture, including context-heavy, higher-risk, or
wider-blast-radius work. Preserve every stated interface and constraint, stay within
the owned file set, and document material judgment calls.

You are not alone in the codebase: preserve concurrent edits and do not revert
unrelated work. Surface ambiguity, scope conflicts, or verification failures rather
than changing the architecture without direction. Run the requested checks and report
actual evidence. Do not silently substitute a different role, model, or reasoning
level; this installed custom-agent profile is the required complex lane.
"""
LEGACY_TERRA
  cat > "$target/$luna_file" <<'LEGACY_LUNA'
name = "sol_advisor_luna_implementer"
description = "Sol Advisor's routine implementation lane for bounded, fully specified work."
model = "gpt-5.6-luna"
model_reasoning_effort = "max"

developer_instructions = """
You are Sol Advisor's routine implementation worker. Execute the supplied five-part
implementation specification exactly when it is bounded and largely determined by
the contract. Preserve stated interfaces and constraints, make only the files you
own, and adapt to concurrent edits instead of reverting work you do not own.

Surface material ambiguity, missing acceptance criteria, scope conflicts, or failed
verification rather than redesigning the architecture. Run the requested checks and
report actual evidence. Do not silently substitute a different role, model, or
reasoning level; this installed custom-agent profile is the required routine lane.
"""
LEGACY_LUNA
  cp "$templates/$sol_file" "$target/$sol_file"
  [ "$(shasum -a 256 "$target/$terra_file" | awk '{print $1}')" = "$legacy_terra_sha256" ] || fail "legacy Terra fixture digest drifted"
  [ "$(shasum -a 256 "$target/$luna_file" | awk '{print $1}')" = "$legacy_luna_sha256" ] || fail "legacy Luna fixture digest drifted"
}

clean_target=$tmp_dir/clean
sh "$installer" --target-dir "$clean_target" >/dev/null
cmp -s "$templates/$terra_file" "$clean_target/$terra_file" || fail "clean Terra install mismatch"
cmp -s "$templates/$sol_file" "$clean_target/$sol_file" || fail "clean Sol install mismatch"
test ! -e "$clean_target/$luna_file" || fail "clean install created retired Luna role"
sh "$installer" --target-dir "$clean_target" --check >/dev/null
before=$(snapshot_files "$clean_target")
sh "$installer" --target-dir "$clean_target" >/dev/null
after=$(snapshot_files "$clean_target")
[ "$before" = "$after" ] || fail "idempotent install changed current roles"
pass "explicit compatibility install, exact check, and idempotence"

missing_target=$tmp_dir/missing
if sh "$installer" --target-dir "$missing_target" --check >/dev/null 2>&1; then fail "--check accepted missing target"; fi
test ! -e "$missing_target" || fail "--check mutated missing target"
pass "missing-target check refusal is non-mutating"

unset_target=$tmp_dir/unset-home
env -u HOME -u CODEX_HOME sh "$installer" --target-dir "$unset_target" >/dev/null
cmp -s "$templates/$terra_file" "$unset_target/$terra_file" || fail "explicit target failed when HOME/CODEX_HOME were unset"
if env -u HOME -u CODEX_HOME sh "$installer" --target-dir /tmp/.. >/dev/null 2>&1; then
  fail "root-equivalent target was accepted"
fi
pass "explicit target is parsed before HOME/CODEX_HOME and root is refused"

no_readlink_bin=$tmp_dir/no-readlink-bin
mkdir "$no_readlink_bin"
printf '%s\n' '#!/bin/sh' 'exit 127' > "$no_readlink_bin/readlink"
chmod 700 "$no_readlink_bin/readlink"
python_target=$tmp_dir/python-canonical
PATH="$no_readlink_bin:/usr/bin:/bin" env -u HOME -u CODEX_HOME sh "$installer" --target-dir "$python_target" >/dev/null
cmp -s "$templates/$terra_file" "$python_target/$terra_file" || fail "python canonicalizer did not install missing target"
if PATH="$no_readlink_bin:/usr/bin:/bin" env -u HOME -u CODEX_HOME sh "$installer" --target-dir /tmp/.. >/dev/null 2>&1; then
  fail "python canonicalizer accepted /tmp/.. root-equivalent target"
fi
if PATH="$no_readlink_bin:/usr/bin:/bin" env -u HOME -u CODEX_HOME sh "$installer" --target-dir "$tmp_dir/../../.." >/dev/null 2>&1; then
  fail "python canonicalizer accepted relative root-equivalent target"
fi
pass "python canonicalization works without readlink and rejects root-equivalent targets"

codex_home=$tmp_dir/codex-home
CODEX_HOME="$codex_home" sh "$installer" >/dev/null
cmp -s "$templates/$terra_file" "$codex_home/agents/$terra_file" || fail "CODEX_HOME Terra mismatch"
cmp -s "$templates/$sol_file" "$codex_home/agents/$sol_file" || fail "CODEX_HOME Sol mismatch"
test ! -e "$codex_home/config.toml" || fail "installer created config.toml"
pass "CODEX_HOME compatibility default remains explicit"

migration_target=$tmp_dir/migration
write_legacy_roles "$migration_target"
sh "$installer" --target-dir "$migration_target" >/dev/null
cmp -s "$templates/$terra_file" "$migration_target/$terra_file" || fail "legacy Terra was not migrated"
cmp -s "$templates/$sol_file" "$migration_target/$sol_file" || fail "Sol changed during migration"
test ! -e "$migration_target/$luna_file" || fail "exact legacy Luna was not removed"
sh "$installer" --target-dir "$migration_target" --check >/dev/null
pass "legacy installer fixture migrates only exact Terra/Luna files"

modified_terra=$tmp_dir/modified-terra
write_legacy_roles "$modified_terra"
printf '%s\n' modified >> "$modified_terra/$terra_file"
before=$(snapshot_files "$modified_terra")
if sh "$installer" --target-dir "$modified_terra" >/dev/null 2>&1; then fail "installer replaced modified Terra"; fi
after=$(snapshot_files "$modified_terra")
[ "$before" = "$after" ] || fail "modified-Terra refusal partially mutated target"
pass "modified legacy role refusal is non-mutating"

modified_luna=$tmp_dir/modified-luna
write_legacy_roles "$modified_luna"
printf '%s\n' modified >> "$modified_luna/$luna_file"
before=$(snapshot_files "$modified_luna")
if sh "$installer" --target-dir "$modified_luna" >/dev/null 2>&1; then fail "installer removed modified Luna"; fi
after=$(snapshot_files "$modified_luna")
[ "$before" = "$after" ] || fail "modified-Luna refusal partially mutated target"
pass "modified legacy Luna refusal is non-mutating"

stale_luna=$tmp_dir/stale-luna
sh "$installer" --target-dir "$stale_luna" >/dev/null
cp "$modified_luna/$luna_file" "$stale_luna/$luna_file"
before=$(snapshot_files "$stale_luna")
if sh "$installer" --target-dir "$stale_luna" --check >/dev/null 2>&1; then fail "--check accepted stale Luna"; fi
after=$(snapshot_files "$stale_luna")
[ "$before" = "$after" ] || fail "stale-Luna check partially mutated target"
pass "stale legacy Luna check refusal is non-mutating"

unsafe=$tmp_dir/unsafe
mkdir "$unsafe"
ln -s "$templates/$terra_file" "$unsafe/$terra_file"
before=$(snapshot_files "$unsafe")
if sh "$installer" --target-dir "$unsafe" >/dev/null 2>&1; then fail "installer accepted symlinked Terra"; fi
after=$(snapshot_files "$unsafe")
[ "$before" = "$after" ] || fail "symlink refusal partially mutated target"
test ! -e "$unsafe/$sol_file" || fail "symlink refusal partially installed Sol"
pass "unsafe compatibility destination refusal is non-mutating"

runtime_sessions=$tmp_dir/runtime-sessions
runtime_day=$runtime_sessions/2026/08/02
mkdir -p "$runtime_day"
runtime_id=11111111-1111-7111-8111-111111111111
runtime_rollout=$runtime_day/rollout-2026-08-02T00-00-00-$runtime_id.jsonl
printf '%s\n' \
  '{"type":"response_item","payload":{"prompt":"DO_NOT_LEAK_PROMPT secret-token-123"}}' \
  "{\"type\":\"session_meta\",\"payload\":{\"id\":\"$runtime_id\",\"parent_thread_id\":\"00000000-0000-7000-8000-000000000000\",\"agent_role\":\"worker\",\"model_provider\":\"openai\",\"agent_path\":\"/private/fixture\"}}" \
  '{"type":"turn_context","payload":{"model":"gpt-5.6-luna","effort":"max","sandbox_policy":{"type":"workspace-write"},"permission_profile":{"type":"disabled"},"cwd":"/private/fixture"}}' \
  > "$runtime_rollout"
runtime_output=$(sh "$runtime_inspector" --sessions-dir "$runtime_sessions" "$runtime_id")
printf '%s\n' "$runtime_output" | jq -e --arg id "$runtime_id" '
  .thread_id == $id and .agent_role == "worker"
  and .model == "gpt-5.6-luna" and .effort == "max"
  and .sandbox_policy_type == "workspace-write"
  and .permission_profile_type == "disabled"
  and (has("cwd") | not) and (has("agent_path") | not)
' >/dev/null || fail "runtime inspector returned wrong allowlisted routing evidence"
if printf '%s\n' "$runtime_output" | grep -Eq 'DO_NOT_LEAK|secret-token|/private/fixture'; then fail "runtime inspector leaked payload or path"; fi
if sh "$runtime_inspector" --sessions-dir "$runtime_sessions" invalid >/dev/null 2>&1; then fail "runtime inspector accepted invalid id"; fi
zero_id=33333333-3333-7333-8333-333333333333
if sh "$runtime_inspector" --sessions-dir "$runtime_sessions" "$zero_id" >/dev/null 2>&1; then fail "runtime inspector accepted zero matches"; fi
pass "runtime inspector emits compact safe routing evidence"

null_id=22222222-2222-7222-8222-222222222222
null_rollout=$runtime_day/rollout-2026-08-02T00-00-01-$null_id.jsonl
printf '%s\n' \
  "{\"type\":\"session_meta\",\"payload\":{\"id\":\"$null_id\",\"agent_role\":\"tester\"}}" \
  '{"type":"turn_context","payload":{"model":"gpt-5.6-luna","effort":"max","sandbox_policy":null,"permission_profile":null,"cwd":null}}' \
  > "$null_rollout"
if sh "$runtime_inspector" --sessions-dir "$runtime_sessions" "$null_id" >/dev/null 2>&1; then
  fail "runtime inspector accepted null sandbox/permission/cwd metadata"
fi
pass "runtime inspector rejects null sandbox, permission, and cwd metadata"

printf '%s\n' "VERIFY PASSED: Sol Advisor 0.6.0 native Luna V2 checks completed in $tmp_dir"
