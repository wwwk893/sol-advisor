# Output quality scorecard — Sol Advisor 0.7.0

This is a deterministic package-quality comparison for the same sanitized `file-backed fixture`,
`evals/coordination_cases.json`, against the 0.6.8 base commit
`d4c2e588ea9ba9eabb6f5fc028b33a43da0a7fc3`. It is not a runtime benchmark.

| Gate | 0.6.8 baseline | 0.7.0 candidate | Evidence |
| --- | --- | --- | --- |
| Same-scope active-child overlap | Not modeled | 0 computed_fixture_violations; pass | Pure evaluator overlap holdouts |
| Pre-terminal dependent phase/acceptance | Not modeled | 0 computed_fixture_violations; pass | Pure evaluator barrier holdouts |
| Existing route/robustness/safety suites | Baseline fixtures | Preserved; pass | Existing verifier checks remain wired |

The 73 fixture transitions and 50 adversarial mutations are `computed_state_transition_evidence`;
the evaluator derives decisions from state and action, including the primary ledger gate, role-action
ownership, Sol-ledger tester repair authorization, fixed explorer-only evidence-role admission,
child-covered handoff scope, typed/non-empty evidence contexts, resolved handoff provenance, and relevant/rescope-only terminal filtering, then
compares them with fixture oracles. This is instruction-contract evidence, not runtime scheduler enforcement. Shell syntax, network-capability,
side-effect, and hash evidence for every shipped package shell entrypoint is in
[`plugin_shell_trust.md/.json`](plugin_shell_trust.md).

## Latency target

The target is p50 improvement of at least 20% with p90 no worse. Actual isolated A/B latency,
token counts, and service-tier response metadata are **missing evidence**; no latency improvement
or target achievement is claimed.

## Scope note

The scorecard evaluates deterministic state-transition and package-contract evidence. It does not
claim external approval, production telemetry, or runtime enforcement of instruction-only locks.
