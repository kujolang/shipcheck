# ShipCheck repository hardening audit — 2026-09-07

## Repository and provenance

- Repository: `kujolang/shipcheck`, branch `main`, initially clean.
- Starting SHA: `4c958ab18d8a48c46e5904261af43d3e031343d1`.
- Ending implementation SHA: `f9b25c44b4da5d0d24b093e3f10437b5dd42de3b`.
- The subsequent documentation-only commit contains this report. Its exact SHA
  is available with `git log -1 --format=%H -- docs/audits/repository-hardening.md`;
  a commit cannot embed its own SHA. No source changes follow the ending SHA.
- Purpose: offline, read-only readiness signals for local repository operators,
  release reviewers and CI/agent consumers. No project commands are executed.
- Runtime used: local `../kujo/target/release/kujo`, identifying as Kujo 1.3.1.
  Binary SHA-256: `74078102b8da4a994438b361f8fb024c68f78ab3818811d18f237949cc861859`.
  Local runtime source HEAD was `9cedbf2f5ae5a0a9b126b055f4c9a6a58a2c23eb`;
  this identifies inspected source, not an independently attested binary build.
- CI still builds runtime ref `681c58f8c0c3ef5bcb0d887a7e6629849daa539e`
  with `cargo build --release --locked`. Runtime source at that ref includes
  `parse_toml`; the exact CI runtime was not rebuilt locally.
- Dependencies: Kujo builtins and local Git; zero Kennel dependencies. Bash and
  Python standard library are verification dependencies. No new package or
  runtime dependency was introduced.
- Read-only integration review: `docs.kujolang.ai/content/tools/shipcheck.md` and
  `kujo-workflows/feature-card-workflow/README.md` consume the CLI scan/gate
  surfaces. No sibling repository was modified.

## Inspection coverage

Read the CLI and all source modules, complete CLI test harness, Eval definition,
JSON schema, manifests, spec, examples, contributor/agent instructions, operations,
security/compatibility/catalog docs, both workflows and artifact guard. Historical
`.dogfood` and generated evaluation output were excluded from broad source sweeps.

The six commands, flag validation, scan ordering, 16-check catalog, JSON projection,
gate aggregation, filesystem probes, manifest parsing, Git subprocess construction,
release-note version precedence and output boundaries were traced in implementation.
There are no providers, model prompts, MCP schemas, network clients, archives,
persistence writes, locks, queues, retries or background workers to audit here.

## Baseline

Existing `tests/cli-output-contract.sh` passed before editing source. Self scan
and gate passed with 16/16 checks, zero errors and warnings. All four original
Kujo files passed `check` and `lint`. All four failed `format --check` with exit 4
(`needs formatting`); this is pre-existing style drift, preserved to avoid churn.

The first 13 new behavior tests produced 12 failing assertions/subtests against
unchanged source. Later additions cover FIFOs, controls and concurrent deterministic
selection. The completed suite contains 16 tests. No existing test was disabled
or weakened. Existing schema coverage checks required fields; new tests also
assert field types, unique check identities and summary/gate arithmetic. This is
contract validation, not a claim of running a full JSON Schema validator.

An initial eight-run self measurement recorded medians of 212.24 ms for JSON scan
and 269.69 ms for release-note. The controlled before/after comparison below uses
identical synthetic repositories and is the basis for improvement claims.

Raw local evidence is retained in ignored `.dogfood/hardening/`: baseline logs,
`baseline.json`, regression failure output, `benchmark.json`, `verification.json`
and individual verification logs. Durable conclusions and commands are here;
raw generated logs are deliberately not committed.

## Findings

| ID | Priority | Area | Finding | Evidence | Action | Status |
|---|---|---|---|---|---|---|
| SC-01 | P1 | Metadata | Handwritten TOML splitting rejected legal comments/equals and accepted duplicate keys or non-string versions | `test_toml_syntax`, `test_invalid_toml_cannot_pass`, `test_manifest_field_types` | Native TOML parser and typed field access; parse package once per manifest check | Fixed |
| SC-02 | P1 | Signals | Descriptions, dependency names and comments passed command/entry checks | `test_command_and_entry_false_positives`, `test_empty_scripts`, `test_real_commands` | Read script dictionaries, `[kujo].entry` and literal Make target headers | Fixed |
| SC-03 | P1 | Filesystem | Directory names counted as files and could provoke invalid reads; special files could block reads | `test_regular_files_required`, `test_fifo_is_not_read`, `test_target_must_be_directory` | Regular-file probes and explicit directory target validation | Fixed |
| SC-04 | P1 | Output safety | Repository strings and Git color reached terminals as control sequences | `test_terminal_controls_preserve_json`, `test_shell_quote_and_color` | Escape C0/C1 controls at human-output boundaries; disable Git color | Fixed |
| SC-05 | P1 | Correctness/determinism | Root entrypoint predicate compared booleans to integers; first-match order was implicit | `test_stable_root_selection_and_concurrent_scans` | Boolean predicates and sorted root selection | Fixed |
| SC-06 | P1 | Efficiency | Release-note discarded an entire scan and ran an unnecessary Git probe | CLI call graph and controlled benchmark | Read only version metadata and Git log | Fixed |
| SC-07 | P2 | CLI | Empty split flag values were accepted; equals-prefixed relative paths were rejected | `test_empty_split_directory`, `test_equals_directory` | Validate complete flag value with consistent blank handling | Fixed |
| SC-08 | P2 | Version | Node/Rust scans recognized versions but release notes printed unknown | `test_release_note_manifest_versions` | Add package.json/Cargo.toml fallback after existing sources | Fixed |
| SC-09 | P2 | Verification | Eval commands embedded one developer's absolute path; CI lacked new behavior/source ratchets | `tests/shipcheck_eval.json`, workflow diff | Root-relative commands; standard-library regression suite, check/lint in CI; read-only token permissions | Fixed |
| SC-10 | P3 | Formatting | Original source does not match current formatter | Baseline four exit-4 checks | Preserve existing style; avoid unrelated whole-file rewrite | Deferred |

## Changes and compatibility

- `src/checks.kujo`: replaced the ad hoc TOML parser with runtime parsing and shared
  typed field access; invalid documents cannot establish readiness. Kennel fields
  are parsed once within the manifest check. Script checks retain keyword order
  and recognize colon suffixes. Make detection does not execute Make, expand
  variables or claim complete syntax analysis. Regular-file and sorted-root
  checks preserve symlinks to regular files and existing shallow directory signals.
- `shipcheck.kujo`: rejects invalid target types and blank values, accepts the full
  equals-form value, and avoids readiness work for release notes. Established
  `scan=0`, failed `gate=1`, invalid options `=2` semantics remain intact.
- `src/display.kujo`, `src/report.kujo`: shared immutable control-escape table,
  applied only to human-visible repository strings and diagnostics. JSON retains
  original data. Commit lines remain separate and Git shell quoting is preserved.
  The release-note function's existing dictionary argument remains compatible.
- `tests/hardening-contract.py`: 16 offline behavioral cases, including actual
  hostile-path Git calls, color/control handling, invalid syntax/types, positive
  script fixtures, FIFOs, path forms and parallel-read determinism. Temporary
  resources are cleaned with `TemporaryDirectory`; subprocess deadlines fail
  tests rather than hide hangs.
- `tests/benchmark.py`: alternating baseline/current subprocess measurements and
  byte-equivalence assertions. Evidence is written to an explicit artifact path,
  with one concise stdout receipt. No flaky wall-clock CI gate was added.
- Documentation, changelog and CI describe and ratchet the corrected behavior.
  Public scan/gate consumers continue using the same flags, numeric fields and
  exit status. No schema, file format, configuration, environment-variable or
  exported function signature changed. Public findings can change for falsely
  accepted metadata and formerly missed root entrypoints; these are documented
  bug corrections, not new check meanings or severity changes.

## Performance and efficiency

Seven timed samples per command after one warmup, alternating execution order,
using the same runtime and fixture path for baseline and current implementation.
`library-0` contains basic README/VERSION/changelog/test metadata. `library-200`
adds 200 root library sources totaling 840,000 bytes without a CLI entrypoint.
No fixture executes repository code. Both commands' stdout matched byte-for-byte
on both fixtures. Results reflect this workstation, not a universal latency SLA.

| Fixture | Command | Before median | After median | stdout bytes before / after |
|---|---|---|---|---|
| library-0 | scan | 187.23 ms | 190.75 ms | 3203 / 3203 |
| library-0 | release-note | 248.56 ms | 156.98 ms | 358 / 358 |
| library-200 | scan | 230.47 ms | 297.44 ms | 3205 / 3205 |
| library-200 | release-note | 275.70 ms | 165.54 ms | 360 / 360 |

Release-note removes 16 unused checks and reduces Git subprocess invocations
from two to one (source-supported count). Scan is not faster on the source-heavy
fixture: the corrected boolean predicate now actually reads root `.kujo` files
that the old implementation skipped. This additional work restores documented
behavior. Do not optimize it away to match the broken baseline.

No memory or build-time improvement is claimed. Full-file buffering and shallow
listing remain. No cache was introduced without an invalidation model. JSON
pretty-printing and its explicit per-check projection remain compatibility and
observability boundaries; deleting them just to reduce output would be churn.
There are no model calls or model-visible schema registration paths, so no token
benchmark or model-token saving is claimed. Agent guidance remains short and
points to the operations guide rather than repeating the full audit.

## Security, errors and state

Reviewed CLI inputs, metadata, Git shell arguments, filenames, symlinks, terminal
output, filesystem probes, temporary test artifacts and CI supply-chain inputs.
Single-quote and metacharacter fixture paths remain safe; no payload was executed.
Directories/FIFOs are excluded from file reads. Invalid JSON/TOML yields missing
signals, not accidental success. I/O failures remain runtime failures, not hidden
passing checks. Git absence/non-repository state remains a failed git check; an
unavailable release history still permits the documented draft skeleton.

The scanner has no persistent mutable state or writes to the target repository.
Three simultaneous scans of a stable fixture produce identical bytes. It does
not promise an atomic snapshot of a mutating repository. Symlinks remain allowed;
Git environment/configuration and the local runtime remain trusted dependencies.
Markdown remains untrusted content for renderers; terminal escaping is not HTML
sanitization or a sandbox. CI action/runtime inputs remain pinned; Rust stable
and the hosted runner are moving toolchain inputs, so bitwise reproducibility is
not claimed. No package vulnerability database audit is claimed for Kujo's
transitive Rust dependencies, which are maintained outside this repository.

## Remaining work and cross-repository follow-ups

- P0/P1: no known unresolved defect introduced by this pass.
- P2 / needs more evidence: repeated metadata reads, full-file buffering and broad
  directory listings remain possible costs. Establish real workload limits before
  adding caches, truncation or resource quotas that change supported behavior.
- P3: pre-existing formatter drift; no unrelated reformat performed.
- Not worth changing: 16-element report loops, JSON field projection, small local
  print helpers, historical artifacts and the zero-dependency package surface.
- No required cross-repository change. External CLI consumers need no migration.
  Future mirroring of detailed catalog prose into ecosystem documentation is
  optional, not a dependency of these fixes.
- Exact pinned-runtime hosted CI execution remains a post-push check; all local
  verification used the binary identified above. No hosted result is claimed here.

One verification attempt encountered host `Resource temporarily unavailable`
while spawning processes. A subsequent unchanged sequential run passed. No sleep,
retry fallback, weakened assertion or increased timeout was added to the tests.

## Verification receipt

Run from `/Users/robertdevore/2026/Kujolang/kujo-repos/shipcheck`, with:

```bash
export KUJO_BIN="$PWD/../kujo/target/release/kujo"
export PATH="$(dirname "$KUJO_BIN"):$PATH"
```

The completed local receipt contains 23 successful command executions:

```bash
for source in shipcheck.kujo src/checks.kujo src/display.kujo src/report.kujo src/scan.kujo; do
  "$KUJO_BIN" check "$source"
  "$KUJO_BIN" lint "$source"
done
bash tests/cli-output-contract.sh
python3 tests/hardening-contract.py
"$KUJO_BIN" run shipcheck.kujo scan --dir .
"$KUJO_BIN" run shipcheck.kujo scan --dir . --format json
"$KUJO_BIN" run shipcheck.kujo gate --dir .
"$KUJO_BIN" run shipcheck.kujo gate --dir . --format json
bash examples/scan-local-and-external.sh ../kujo-spec
bash .github/scripts/check-kujo-tool-artifacts.sh
git diff --check
bash -n tests/cli-output-contract.sh examples/scan-local-and-external.sh .github/scripts/check-kujo-tool-artifacts.sh
```

The three commands in `tests/shipcheck_eval.json` were replayed with their exact
stdout/JSON/success assertions using a Python standard-library driver; all passed.
This validates the Eval definition's commands, not the external Eval engine.
The benchmark command in `docs/operations.md` passed separately. Baseline
`kujo format --check` was run on each original source file: all four exit 4 as
recorded above. No application build, web E2E, package install or publishing
phase applies to this interpreted CLI repository.

Self gate: `kujo run shipcheck.kujo gate --dir . --format json`, exit 0,
16/16 passing, highest severity `info`, zero warnings, gate passed. Existing
contract fixtures separately prove error-level exit 1 and warning-only exit 0.
