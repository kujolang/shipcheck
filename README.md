# ShipCheck

ShipCheck checks whether a local repo is ready enough to ship by running explicit release-readiness checks and reporting blockers.

It audits a local repository and produces:

- a human-readable Markdown report,
- a machine-friendly JSON report,
- a release checklist,
- and a deterministic gate result for CI.

ShipCheck surfaces blockers and follow-up work; it does not certify a release or replace human review.

## Release-Readiness Capabilities

- Scans repository health, code quality, documentation, and release metadata.
- Distinguishes informational scanning from the blocking `gate` command.
- Uses error vs warning severity so teams can gate on what matters.
- Works fully offline on local repositories.
- Produces structured JSON for automation and reporting systems.

## Requirements

- Kujo runtime available as `kujo`
- Git available on `PATH`

## Quick Start

Run from this repository:

```bash
kujo run shipcheck.kujo -- help
kujo run shipcheck.kujo -- scan
kujo run shipcheck.kujo -- scan --format json
kujo run shipcheck.kujo -- gate
```

Use `help` and `version`; standalone `--help` and `--version` aliases are not implemented in this wrapper.

Scan another repository:

```bash
kujo run shipcheck.kujo -- scan --dir ../kujo-spec
kujo run shipcheck.kujo -- gate --dir ../kujo-spec --format json
```

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
kujo run shipcheck.kujo -- gate --dir . --format json
```

If your policy needs a saved artifact:

```bash
kujo run shipcheck.kujo -- scan --dir . --format json > shipcheck-report.json
```

Additional operational guidance is in [docs/operations.md](docs/operations.md).

## Project Status

Current release: `v0.1.0`

ShipCheck is in early-stage maturity, but the command surface and gate behavior are verified enough for local developer workflows and CI experimentation.

## Repository Layout

- `shipcheck.kujo` CLI entry point
- `src/checks.kujo` individual release checks
- `src/scan.kujo` scan orchestration
- `src/report.kujo` markdown/json/checklist/release-note output
- `docs/` operational and check reference documentation

The example shell script under `examples/` expects the Kujo runtime to be available as `kujo` on `PATH`.

## Changelog

Release notes and history are tracked in [CHANGELOG.md](CHANGELOG.md).

## Dogfood Artifacts

Historical implementation and ecosystem notes are preserved under [.dogfood/shipcheck](.dogfood/shipcheck).
