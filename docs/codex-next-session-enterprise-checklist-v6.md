# kujo-eval Next Session Enterprise Checklist (v6)

Date created: 2026-06-19
Context: Post-v5 review and hardening pass for named path policy profiles, root-layout presentation, docs alignment, and release-gate validation.

Purpose:
- Capture the next highest-value work items to move Eval from production-ready local/CI evaluation tooling toward a flagship, broadly adoptable enterprise control primitive.
- Keep items implementation-ready with measurable validation expectations.
- Avoid overclaiming universal enterprise readiness where Eval still depends on host execution boundaries.

## Priority Legend

- P0: Critical trust/safety/correctness risk
- P1: High-value enterprise hardening and adoption
- P2: Scale/performance/operability improvements
- P3: Product presentation and ecosystem growth polish

## Completed In This Session (Reference)

- Added `path_policy_profile` presets for top-level configs and `policy_stage_overlays`: `open`, `ci-restricted`, and `release-deny-default`.
- Added validation and lint diagnostics for invalid path policy profiles, including stage-overlay locations.
- Surfaced `path_policy_profile` in `policy-explain` effective policy output.
- Updated `schema/eval-suite.schema.json`, `README.md`, `docs/eval-suite-reference.md`, `docs/SECURITY.md`, `docs/API_REFERENCE.md`, and `docs/QUICKREF.md`.
- Added README root-layout rationale explaining why `main.kujo` remains at root while implementation lives in `src/`.
- Added regression coverage for profile expansion, policy explain output, lint diagnostics, and release-stage path denial behavior.
- Added CHANGELOG coverage for behavior, security, and docs changes.

## Production Readiness Position

Eval is production-ready for deterministic local and CI evaluation workflows where command/file access is intentionally granted and runner boundaries are controlled.

Eval is not yet a universal enterprise sandbox. Command execution still runs through the host runtime, and hard isolation must come from containers, CI runners, workload policy, or external supervisors. Future enterprise work should continue improving fail-closed defaults and making those limitations impossible to miss.

## Phase A: Contract And Policy Integrity

### [ ] A1 - Add frozen fixtures for path policy profile outputs (P1)
Why:
- Machine consumers need stable examples for `policy-explain` output that include `path_policy_profile`.
Work:
- Add fixture payloads for `ci-restricted` and `release-deny-default` profile explanations.
- Extend artifact/contract verification to compare profile-related fields.
Files likely affected:
- `examples/fixtures/contracts/`
- `scripts/verify_artifact_contract.sh`
- `tests/cli_integration_tests.kujo`
- `docs/API_REFERENCE.md`
Verification:
- Contract verification fails if profile fields disappear or change shape unexpectedly.

### [ ] A2 - Validate stage-overlay policy profiles in schema parity checks (P1)
Why:
- JSON Schema now exposes profile values; docs and schema should remain parity-checked.
Work:
- Add schema smoke validation examples for top-level and stage-overlay `path_policy_profile`.
- Include one invalid-profile negative case in lint/contract coverage if schema tooling supports it.
Files likely affected:
- `schema/eval-suite.schema.json`
- `tests/coverage_tests.kujo`
- `docs/eval-suite-reference.md`
Verification:
- `kujo test`, docs parity, and artifact contract checks pass.

## Phase B: Security And Governance

### [ ] B1 - Add strict shell-operator governance for command checks (P1)
Why:
- `allowed_commands` constrains the first executable, but enterprise suites may also want to reject shell chaining/control operators unless explicitly allowed.
Work:
- Add an opt-in command policy field such as `reject_shell_operators` or `shell_operator_policy`.
- Enforce it in `run_shell_with_policy`.
- Document interaction with `allowed_command_patterns` and existing `blocked_arg_patterns`.
Files likely affected:
- `src/checks.kujo`
- `src/config.kujo`
- `schema/eval-suite.schema.json`
- `tests/security_tests.kujo`
- `docs/SECURITY.md`
Verification:
- Security tests cover `&&`, `||`, `;`, and pipe behavior under strict and non-strict modes.

### [ ] B2 - Strengthen canonical path resolution where runtime support allows (P1)
Why:
- Current path policy normalizes strings and blocks symlink segments when allowlists are active; realpath-style canonical checks would improve confidence.
Work:
- Investigate available Kujo/runtime path canonicalization helpers.
- Add canonical path comparison when supported, falling back to existing normalization with clear metadata.
Files likely affected:
- `src/checks.kujo`
- `tests/security_tests.kujo`
- `docs/SECURITY.md`
Verification:
- Tests cover nested symlink, absolute allowlist, relative allowlist, and unsupported-runtime fallback behavior.

### [ ] B3 - Add policy posture summary to run artifacts (P2)
Why:
- `policy-explain` is useful before execution; run artifacts should also say which policy profile/mode actually applied.
Work:
- Include effective policy summary in `last_run.json`, `summary.json`, and `cli-summary.json`.
- Keep output compact and avoid echoing large allowlists unnecessarily.
Files likely affected:
- `src/eval_core.kujo`
- `main.kujo`
- `scripts/verify_artifact_contract.sh`
- `docs/API_REFERENCE.md`
Verification:
- Artifact contract fixtures validate stable policy summary fields.

## Phase C: Performance And Scale

### [ ] C1 - Stream or chunk checksum generation for large artifacts (P2)
Why:
- Manifest checksum verification currently reads artifact content directly; large reports may become memory-heavy.
Work:
- Investigate whether the runtime exposes file-hash or chunked read support.
- Add a bounded-memory checksum path or document current artifact-size expectations.
Files likely affected:
- `main.kujo`
- `scripts/verify_artifact_contract.sh`
- `tests/benchmark_tests.kujo`
Verification:
- Benchmark or stress test covers large artifact manifest generation without regressions.

### [ ] C2 - Publish cache/performance metrics in human reports (P2)
Why:
- Run payloads include cache and parallel metrics, but report readers should see the performance story without opening JSON.
Work:
- Add a compact performance section to Markdown/HTML reports.
- Include cache hits/misses, bytes reused, parallel mode, worker count, and prefetch duration.
Files likely affected:
- `src/report.kujo`
- `tests/coverage_tests.kujo`
- `docs/API_REFERENCE.md`
Verification:
- Markdown and HTML report tests assert the metrics render when present and omit cleanly when absent.

## Phase D: Product Presentation And Adoption

### [ ] D1 - Archive or index historical session checklist docs (P2)
Why:
- The docs folder now contains many historical checklists; new users need a clearer path to current references.
Work:
- Create `docs/archive/` or a single `docs/session-history.md` index.
- Move or link old Codex checklists without breaking useful references.
- Keep the current v6 checklist discoverable.
Files likely affected:
- `docs/`
- `README.md`
- `scripts/supply_chain_policy_check.sh`
Verification:
- README references remain valid; supply-chain doc reference check passes.

### [ ] D2 - Add golden-path artifact examples for enterprise onboarding (P3)
Why:
- Users adopt faster when they can see expected `summary.json`, `cli-summary.json`, policy explain output, and report screenshots/snippets.
Work:
- Add concise, parity-validated snippets for a strict enterprise run.
- Avoid committing generated bulk artifacts unless they are contract fixtures.
Files likely affected:
- `README.md`
- `docs/QUICKREF.md`
- `docs/COOKBOOK.md`
- `examples/fixtures/contracts/`
Verification:
- Docs parity validates every command shown.

### [ ] D3 - Consider `--version` alias support (P3)
Why:
- Many CLI users expect `--version`; README currently explains that `version` is the supported command.
Work:
- Decide whether to add `--version` as an alias to `version` or keep explicit command-only semantics.
- If added, update help, completion, inventory, docs, and CLI integration tests.
Files likely affected:
- `main.kujo`
- `src/cli.kujo`
- `docs/COMMAND_INVENTORY.md`
- `tests/cli_integration_tests.kujo`
Verification:
- `kujo run main.kujo --version` exits 0 and docs command inventory remains fresh.

## Suggested Next Session Order

1. B1
2. A1
3. B2
4. B3
5. C1
6. C2
7. D1
8. D2
9. D3

## Next Session Definition Of Done

- Selected checklist items implemented with focused tests.
- `kujo test` passes.
- `kujo test --runtime vm` passes.
- `scripts/verify_readme_counts.sh` passes with `KUJO_BIN` set.
- `scripts/verify_artifact_contract.sh` passes with `KUJO_BIN` set.
- `scripts/verify_docs_command_parity.sh` passes with `KUJO_BIN` set.
- `scripts/supply_chain_policy_check.sh` passes.
- `scripts/release_quality_gates.sh` passes with `KUJO_BIN` set.

