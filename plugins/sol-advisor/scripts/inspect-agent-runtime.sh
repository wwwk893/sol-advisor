#!/bin/sh
# Emit only allowlisted routing metadata from one exact native subagent rollout.

set -eu

usage() {
  cat <<'EOF'
Usage: inspect-agent-runtime.sh [route expectations] [--sessions-dir DIR] THREAD_ID

Route expectations:
  --expected-carrier default|tester
  --expected-logical-role ROLE
  --expected-route-class normal|critical-risk
  --expected-model MODEL
  --expected-effort EFFORT
  --expected-fork-turns none

Read the one rollout file whose filename ends with THREAD_ID and emit a compact JSON
object containing only safe routing metadata. Without --sessions-dir, the sessions
root is "$CODEX_HOME/sessions" when CODEX_HOME is already set, otherwise
"$HOME/.codex/sessions".
EOF
}

fail() {
  printf '%s\n' "ERROR: $*" >&2
  exit 1
}

sessions_dir=''
expected_carrier=''
expected_logical_role=''
expected_route_class=''
expected_model=''
expected_effort=''
expected_fork_turns=''
while [ "$#" -gt 1 ]; do
  option=$1
  value=$2
  [ -n "$value" ] || fail "$option requires a non-empty value."
  case "$option" in
    --sessions-dir) sessions_dir=$value ;;
    --expected-carrier) expected_carrier=$value ;;
    --expected-logical-role) expected_logical_role=$value ;;
    --expected-route-class) expected_route_class=$value ;;
    --expected-model) expected_model=$value ;;
    --expected-effort) expected_effort=$value ;;
    --expected-fork-turns) expected_fork_turns=$value ;;
    *) usage >&2; exit 2 ;;
  esac
  shift 2
done
[ "$#" -eq 1 ] || { usage >&2; exit 2; }
thread_id=$1

if ! printf '%s\n' "$thread_id" | LC_ALL=C grep -Eq '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'; then
  fail "THREAD_ID must be a lowercase UUID."
fi

if [ -z "$sessions_dir" ]; then
  if [ -n "${CODEX_HOME-}" ]; then
    sessions_dir=$CODEX_HOME/sessions
  else
    [ -n "${HOME-}" ] || fail "HOME is unset and CODEX_HOME was not supplied; pass --sessions-dir explicitly."
    sessions_dir=$HOME/.codex/sessions
  fi
fi

[ -d "$sessions_dir" ] || fail "sessions directory is unavailable."

tmp_base=${TMPDIR:-/tmp}
case "$tmp_base" in
  /*) ;;
  *) tmp_base=/tmp ;;
esac
matches_file=''

cleanup() {
  if [ -n "$matches_file" ] && [ -f "$matches_file" ]; then
    case "$matches_file" in
      "$tmp_base"/sol-advisor-runtime.*)
        rm -f "$matches_file"
        ;;
      *)
        printf '%s\n' "ERROR: refusing cleanup of unexpected temporary file." >&2
        ;;
    esac
  fi
}

trap cleanup 0 HUP INT TERM

matches_file=$(mktemp "$tmp_base/sol-advisor-runtime.XXXXXX") || fail "could not create a temporary match list."

# Match only the exact rollout filename suffix; do not inspect any rollout contents
# until exactly one filename has been found.
if ! find "$sessions_dir" -type f -name "rollout-*-$thread_id.jsonl" -print > "$matches_file"; then
  fail "could not enumerate rollout filenames under the sessions directory."
fi

match_count=$(awk 'END { print NR + 0 }' "$matches_file")
case "$match_count" in
  0) fail "no rollout filename matched the requested thread id." ;;
  1) ;;
  *) fail "multiple rollout filenames matched the requested thread id." ;;
esac

IFS= read -r rollout_file < "$matches_file" || fail "could not read the matched rollout filename."
[ -f "$rollout_file" ] || fail "matched rollout is unavailable."

# The jq program reads only the matched JSONL and constructs a small allowlisted object.
# Missing routing observations are emitted as unobservable; explicit conflicts fail closed.
if ! jq -ce -s \
  --arg expected_thread_id "$thread_id" \
  --arg expected_carrier "$expected_carrier" \
  --arg expected_logical_role "$expected_logical_role" \
  --arg expected_route_class "$expected_route_class" \
  --arg expected_model "$expected_model" \
  --arg expected_effort "$expected_effort" \
  --arg expected_fork_turns "$expected_fork_turns" '
  def string_or_null:
    if type == "string" then . else null end;

  [ .[] | select(.type == "session_meta") | .payload ] as $sessions |
  [ .[] | select(.type == "turn_context") | .payload ] as $turns |
  if ($sessions | length) != 1 then
    error("missing or ambiguous session metadata")
  elif ($turns | length) == 0 then
    error("missing turn context")
  else
    $sessions[0] as $session |
    ($session.id? | string_or_null) as $session_thread_id |
    ($session.parent_thread_id? | string_or_null) as $parent_thread_id |
    ($session.agent_role? | string_or_null) as $agent_role |
    ($session.model_provider? | string_or_null) as $model_provider |
    [ $turns[] | (.model? | string_or_null) | select(. != null and . != "") ] as $models |
    [ $turns[] | (.effort? | string_or_null) | select(. != null and . != "") ] as $efforts |
    ([ $sessions[] | (.logical_role? | string_or_null) ] + [ $turns[] | (.logical_role? | string_or_null) ] | map(select(. != null and . != ""))) as $observed_logical_roles |
    ([ $sessions[] | (.route_class? | string_or_null) ] + [ $turns[] | (.route_class? | string_or_null) ] | map(select(. != null and . != ""))) as $observed_route_classes |
    [ $turns[] | ((.sandbox_policy? // {}) | .type? | string_or_null) ] as $sandbox_types |
    [ $turns[] | ((.permission_profile? // {}) | .type? | string_or_null) ] as $permission_types |
    [ $turns[] | (.cwd? | string_or_null) ] as $cwds |
    ([ $sessions[] | .fast_mode? ] + [ $turns[] | .fast_mode? ] | map(select(. != null))) as $fast_modes |
    ([ $sessions[] | .service_tier? ] + [ $turns[] | .service_tier? ] | map(select(. != null))) as $service_tiers |
    ([ $sessions[] | (.fork_turns? | string_or_null) ] + [ $turns[] | (.fork_turns? | string_or_null) ] | map(select(. != null and . != ""))) as $fork_values |
    if $session_thread_id == null or $session_thread_id != $expected_thread_id then
      error("session metadata does not identify the requested thread")
    elif $agent_role == null or $agent_role == "" then
      error("missing agent role")
    elif ($models | unique | length) > 1 then
      error("BLOCKED_ROUTE_CONFLICT: conflicting models")
    elif ($efforts | unique | length) > 1 then
      error("BLOCKED_ROUTE_CONFLICT: conflicting efforts")
    elif ($fork_values | unique | length) > 1 then
      error("BLOCKED_ROUTE_CONFLICT: conflicting fork_turns")
    elif ($observed_logical_roles | unique | length) > 1 then
      error("BLOCKED_ROUTE_CONFLICT: conflicting observed logical roles")
    elif ($observed_route_classes | unique | length) > 1 then
      error("BLOCKED_ROUTE_CONFLICT: conflicting observed route classes")
    elif any($sandbox_types[]; . == null or . == "") then
      error("missing sandbox policy type")
    elif ($sandbox_types | unique | length) != 1 then
      error("conflicting sandbox policy types")
    elif any($permission_types[]; . == null or . == "") then
      error("missing permission profile type")
    elif ($permission_types | unique | length) != 1 then
      error("conflicting permission profile types")
    elif any($cwds[]; . == null or . == "") then
      error("missing working directory")
    elif ($cwds | unique | length) != 1 then
      error("conflicting working directories")
    elif $expected_carrier != "" and $agent_role != $expected_carrier then
      error("BLOCKED_ROUTE_CONFLICT: carrier mismatch")
    elif $expected_model != "" and ($models | length) > 0 and $models[0] != $expected_model then
      error("BLOCKED_ROUTE_CONFLICT: model mismatch")
    elif $expected_effort != "" and ($efforts | length) > 0 and $efforts[0] != $expected_effort then
      error("BLOCKED_ROUTE_CONFLICT: effort mismatch")
    elif $expected_fork_turns != "" and ($fork_values | length) > 0 and $fork_values[0] != $expected_fork_turns then
      error("BLOCKED_ROUTE_CONFLICT: fork_turns mismatch")
    elif $expected_logical_role != "" and ($observed_logical_roles | length) > 0 and $observed_logical_roles[0] != $expected_logical_role then
      error("BLOCKED_ROUTE_CONFLICT: observed logical role mismatch")
    elif $expected_route_class != "" and ($observed_route_classes | length) > 0 and $observed_route_classes[0] != $expected_route_class then
      error("BLOCKED_ROUTE_CONFLICT: observed route class mismatch")
    elif any($fast_modes[]; . == true or . == "true") then
      error("BLOCKED_ROUTE_CONFLICT: fast mode conflicts with the exact route")
    elif any($service_tiers[]; . == "priority") and ((
      $agent_role == "tester" and $expected_logical_role == "tester" and
      ($expected_model == "" or $expected_model == "gpt-5.6-luna") and
      ($expected_effort == "" or $expected_effort == "max")
    ) | not) then
      error("BLOCKED_ROUTE_CONFLICT: priority service tier conflicts with the exact Sol route")
    elif ($fast_modes | unique | length) > 1 then
      error("BLOCKED_ROUTE_CONFLICT: conflicting fast mode metadata")
    elif ($service_tiers | unique | length) > 1 then
      error("BLOCKED_ROUTE_CONFLICT: conflicting service tier metadata")
    else
      {
        thread_id: $session_thread_id,
        parent_thread_id: $parent_thread_id,
        agent_role: $agent_role,
        model_provider: $model_provider,
        expected_logical_role: (if $expected_logical_role == "" then "unobservable" else $expected_logical_role end),
        observed_logical_role: (if ($observed_logical_roles | length) == 0 then "unobservable" else $observed_logical_roles[0] end),
        expected_route_class: (if $expected_route_class == "" then "unobservable" else $expected_route_class end),
        observed_route_class: (if ($observed_route_classes | length) == 0 then "unobservable" else $observed_route_classes[0] end),
        model: (if ($models | length) == 0 then "unobservable" else $models[0] end),
        effort: (if ($efforts | length) == 0 then "unobservable" else $efforts[0] end),
        fork_turns: (if ($fork_values | length) == 0 then "unobservable" else $fork_values[0] end),
        sandbox_policy_type: $sandbox_types[0],
        permission_profile_type: $permission_types[0],
        fast_mode: (if ($fast_modes | length) == 0 then "unobservable" else $fast_modes[0] end),
        service_tier: (if ($service_tiers | length) == 0 then "unobservable" else $service_tiers[0] end),
        warnings: (
          []
          + (if ($models | length) == 0 then ["model unobservable"] else [] end)
          + (if ($efforts | length) == 0 then ["effort unobservable"] else [] end)
          + (if ($fork_values | length) == 0 then ["fork_turns unobservable"] else [] end)
          + (if ($observed_logical_roles | length) == 0 then ["observed logical_role unobservable"] else [] end)
          + (if ($observed_route_classes | length) == 0 then ["observed route_class unobservable"] else [] end)
          + (if ($fast_modes | length) == 0 then ["fast_mode unobservable"] else [] end)
          + (if ($service_tiers | length) == 0 then ["service_tier unobservable"] else [] end)
          + (if any($service_tiers[]; . == "priority") then ["tester priority observed; not requested"] else [] end)
        )
      }
    end
  end
' "$rollout_file"; then
  fail "BLOCKED_ROUTE_CONFLICT or invalid rollout metadata."
fi
