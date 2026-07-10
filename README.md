# ShipCheck

[![Version](https://img.shields.io/badge/version-0.1.0-black)](https://github.com/kujolang/shipcheck)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)
[![built with Kujo](https://img.shields.io/badge/built%20with-Kujo-white.svg)](https://github.com/kujolang/kujo)

ShipCheck checks whether a local repo is ready enough to ship by running explicit release-readiness checks and reporting blockers.

It audits a local repository and produces:

- a human-readable Markdown report,
- a machine-friendly JSON report,
- a release checklist,
- and a deterministic gate result for CI.

ShipCheck surfaces blockers and follow-up work; it does not certify a release or replace human review.

## Positioning

ShipCheck is a production-forward alpha: the CLI surface, JSON shape, and gate semantics are stable enough for local workflows and CI experimentation, and the project now passes its own release gate. It is not an enterprise certification engine yet. Treat it as a clear, deterministic readiness scanner that helps teams see missing release signals before humans make the final ship decision.

## Install / Quick Start

Requirements:

- Kujo runtime available as `kujo`
- Git available on `PATH`

Run from this repository:

```bash
kujo run shipcheck.kujo help
kujo run shipcheck.kujo scan
kujo run shipcheck.kujo gate
```

Expected gate behavior:

- `scan` prints findings without failing the command.
- `gate` exits `1` when error-level checks fail.
- `gate` exits `0` when only warnings or passing checks remain.
- `gate --format json` emits valid JSON and still uses the exit code for pass/fail automation.

## Usage Examples

Emit JSON for automation:

```bash
kujo run shipcheck.kujo scan --format json
```

Scan another repository:

```bash
kujo run shipcheck.kujo scan --dir ../kujo-spec
kujo run shipcheck.kujo gate --dir ../kujo-spec --format json
```

Use `help` and `version`; standalone `--help` and `--version` aliases are not implemented in this wrapper.

Unsupported output formats fail with exit `2`:

```bash
kujo run shipcheck.kujo scan --format yaml
```

## Release-Readiness Capabilities

- Scans repository health, code quality, documentation, and release metadata.
- Distinguishes informational scanning from the blocking `gate` command.
- Uses error vs warning severity so teams can gate on what matters.
- Works fully offline on local repositories.
- Produces structured JSON for automation and reporting systems.
- Shell-quotes target directories before invoking Git subprocesses.

## Command Reference

| Command | Description |
| --- | --- |
| `scan` | Run all checks and print a full release-readiness report |
| `checklist` | Print an actionable release checklist plus current check state |
| `gate` | Run checks and fail fast if any error-level checks fail |
| `release-note` | Draft release notes using recent git commits |
| `version` | Print tool version and summary |
| `help` | Print usage and examples |

Supported flags:

- `--dir <path>` target directory (default: current directory)
- `--format markdown|json` output format for `scan` and `gate` (default: `markdown`)

Scan is informational: it can report findings without failing the command. Gate is the blocking verification command.

## Gate Semantics

- Error-level failures cause `gate` to exit with status `1`.
- Warning-only results still pass the gate.
- Successful gate runs exit with status `0`.

This makes ShipCheck useful in CI merge/release workflows, with human review still needed for warnings and release decisions.

## JSON Contract and Compatibility

`scan --format json` and `gate --format json` conform to the versioned
[JSON schema](schemas/shipcheck-report.schema.json). The schema is part of the
public CLI contract for the current `0.1.x` line.

ShipCheck makes additive changes to the JSON report only in backward-compatible
releases. Renaming, removing, or changing the meaning/type of an existing field
requires a documented breaking release and a schema-version update. Consumers
should ignore unrecognized fields and rely on the command exit status plus
`summary.gate_passed` for gate decisions.

See [the compatibility policy](docs/compatibility.md) for the complete policy,
including the experimental-maturity boundary.

## Security and Limitations

ShipCheck reads repository metadata and invokes local Git commands; it does not
run project tests, inspect release artifacts, call network services, publish
releases, or certify a project. Read the [threat model and security
boundaries](docs/security.md) before using it against untrusted workspaces.

## Check Coverage

ShipCheck runs 16 checks across 4 categories:

- Repository health
- Code quality
- Documentation
- Release metadata

Full catalog and severity definitions are documented in [docs/check-catalog.md](docs/check-catalog.md).

## CI Integration

Example release gate step:

```bash
kujo run shipcheck.kujo gate --dir . --format json
```

If your policy needs a saved artifact:

```bash
kujo run shipcheck.kujo scan --dir . --format json > shipcheck-report.json
```

Additional operational guidance is in [docs/operations.md](docs/operations.md).

This repository includes a GitHub Actions workflow at `.github/workflows/ci.yml`. It builds a pinned Kujo runtime, runs the CLI contract test, and then runs ShipCheck's own scan and gate.

## Project Status

Current release: `v0.1.0` (the current commit is intentionally untagged).

ShipCheck is in early-stage maturity, but its core command surface and gate behavior are covered by contract tests. Current self-scan status is 16/16 checks passing with zero warnings.

## Repository Layout

- `shipcheck.kujo` CLI entry point
- `src/checks.kujo` individual release checks
- `src/scan.kujo` scan orchestration
- `src/report.kujo` markdown/json/checklist/release-note output
- `.github/workflows/ci.yml` CI contract and self-gate workflow
- `docs/` operational and check reference documentation
- `AGENTS.md` contributor and agent guidance for canonical examples and search hygiene

The example shell script under `examples/` uses `KUJO_BIN` when set and otherwise expects the Kujo runtime to be available as `kujo` on `PATH`.

## Changelog

Release notes and history are tracked in [CHANGELOG.md](CHANGELOG.md).

## Dogfood Artifacts

Historical implementation and ecosystem notes are preserved under [.dogfood/shipcheck](.dogfood/shipcheck). Treat them as background context, not canonical examples.

Generated or bulk evaluation output lives under `eval_results/`; exclude it from broad readability sweeps unless the task explicitly targets eval artifacts.
