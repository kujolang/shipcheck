# ShipCheck Showcase Readiness Review

## Current Answer

ShipCheck is stronger after this pass, but it should not be described as universally enterprise-ready yet. It is a production-forward alpha with a stable local CLI surface, deterministic JSON/Markdown output, contract tests, CI, and a clean self-gate. The next level is broader check coverage, fixture-based regression depth, and integration with the rest of the Kujo ecosystem.

## Completed In This Pass

- Added CI that builds a pinned Kujo runtime, runs the CLI contract, and executes ShipCheck's self scan/gate.
- Fixed `gate --format json` so automation receives valid JSON and the exit code carries pass/fail state.
- Added output-format validation so unsupported formats exit `2`.
- Quoted target directories before Git subprocesses and added regression coverage for shell metacharacters in paths.
- Updated README, examples, operations docs, and changelog to reflect the current security, CI, and maturity posture.
- Confirmed the root layout is clean: `shipcheck.kujo` remains the CLI entry point, while implementation code lives in `src/`.

## Next Session Work Items

### Task 1: Fixture-Based Release Gate Matrix (P0)

**Goal:** Expand tests from smoke coverage to deterministic behavior coverage across common repository states.

**Scope:**
- Add fixtures for empty repo, docs-only repo, Kujo repo, Node repo, Python repo, and warning-only repo.
- Assert exact error/warning counts and gate exit codes.
- Keep fixtures small and local.

**Acceptance Criteria:**
- Contract tests prove `gate` exits `1` only for error-level failures.
- `scan --format json` and `gate --format json` stay parseable for every fixture.
- Fixture names and expected outcomes are documented.

### Task 2: Structured Manifest Parsing (P0)

**Goal:** Replace substring checks for `kennel.toml`, `package.json`, and related metadata with structured parsing where Kujo runtime support is stable.

**Scope:**
- Parse TOML/JSON manifests instead of checking for raw words like `version`, `license`, or `entry`.
- Avoid false positives from comments, README snippets, or unrelated fields.
- Preserve current check IDs and severity.

**Acceptance Criteria:**
- `version-metadata`, `kennel-manifest`, and `entry-point` findings are based on real fields.
- Tests cover missing field, commented field, and valid field cases.
- Docs/check catalog still matches source behavior.

### Task 3: Path and Subprocess Hardening Audit (P1)

**Goal:** Make command execution and filesystem traversal robust for unusual local paths.

**Scope:**
- Centralize shell quoting instead of keeping local helpers in multiple modules.
- Add regression tests for apostrophes, spaces, semicolons, and leading-dash path segments.
- Review all future subprocess call sites for quoting before merge.

**Acceptance Criteria:**
- A shared helper handles shell quoting consistently.
- Contract test covers hostile-looking paths without creating marker files.
- Security posture section in docs stays aligned with implementation.

### Task 4: Check Coverage Expansion (P1)

**Goal:** Make ShipCheck more universally useful across serious release workflows without pretending to run full CI itself.

**Candidate Checks:**
- Dependency lockfile presence.
- Security policy or vulnerability reporting file.
- Code of conduct and contribution guide.
- Release artifact or build script presence.
- Version consistency between manifest, `VERSION`, and changelog.
- Generated artifact hygiene for common output directories.

**Acceptance Criteria:**
- New checks have clear IDs, severity, and docs.
- Existing projects do not receive noisy errors for ecosystem-specific checks.
- `summary.total_checks` and tests are updated together.

### Task 5: Performance Sweep For Large Repositories (P2)

**Goal:** Keep scans fast and predictable on larger monorepos.

**Scope:**
- Measure scan time on large local repos.
- Avoid unnecessary full-file reads for large README/manifest files.
- Short-circuit repeated directory listings where possible.
- Add a lightweight timing note to local validation docs.

**Acceptance Criteria:**
- Baseline and post-change timings are recorded.
- No check reads more data than it needs for the signal it reports.
- Performance work does not change output semantics.

### Task 6: Kujo Ecosystem Integration (P2)

**Goal:** Make ShipCheck a better funnel into Kujo by showing how small Kujo tools compose.

**Scope:**
- Add an optional Eval suite for ShipCheck fixtures.
- Explore Scout input for richer repository intelligence.
- Explore Kennel manifest validation instead of duplicating all package checks.
- Consider a Dispatch workflow wrapper for release gates.

**Acceptance Criteria:**
- Integrations remain optional and do not make the core scanner network-dependent.
- README shows one copyable ecosystem composition example.
- Each integration has a clear fallback for users who only want ShipCheck.

### Task 7: Release Packaging And Trust Story (P3)

**Goal:** Move from local showcase to credible distributable tool.

**Scope:**
- Define release artifact shape.
- Add checksum/signature guidance.
- Clarify version bump and tag process.
- Add a release validation checklist specific to ShipCheck itself.

**Acceptance Criteria:**
- A maintainer can cut a release from docs without guessing.
- Release artifacts can be verified by users.
- CHANGELOG, kennel manifest, and README version references stay consistent.
