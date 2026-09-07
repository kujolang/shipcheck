# ShipCheck Operations Guide

This guide focuses on using ShipCheck as a release-readiness gate in developer workflows and CI.

## Standard Local Workflow

Run this sequence from the target repository root:

```bash
kujo run /path/to/shipcheck/shipcheck.kujo scan --dir .
kujo run /path/to/shipcheck/shipcheck.kujo checklist --dir .
kujo run /path/to/shipcheck/shipcheck.kujo gate --dir .
```

Recommended policy:

- Treat `scan` as informational output: it can report findings without failing.
- Treat `gate` as the pass/fail enforcement step.
- Treat gate failures as must-fix before tagging/releases.
- Treat warnings as explicit review items in release pull requests.

## JSON Output For Automation

For machine processing:

```bash
kujo run /path/to/shipcheck/shipcheck.kujo scan --dir . --format json > shipcheck-report.json
kujo run /path/to/shipcheck/shipcheck.kujo gate --dir . --format json
```

`scan --format json` is useful as an archived artifact. `gate --format json` is suitable for policy scripts because the output is valid JSON and the process exit code still carries the pass/fail result.

## CI Gate Pattern

Minimal CI release gate step:

```bash
kujo run /path/to/shipcheck/shipcheck.kujo gate --dir . --format json
```

Expected behavior:

- Exit `0`: no error-level release blockers.
- Exit `1`: one or more error-level blockers.

ShipCheck does not implement standalone `--help` or `--version` aliases in this wrapper; use `help` and `version`.

The repository includes `.github/workflows/ci.yml`, which builds a pinned Kujo runtime, runs the CLI output contract, and executes ShipCheck's own scan and gate.

## Example and Artifact Hygiene

- Treat `README.md`, `docs/`, and `examples/` as the canonical copyable surfaces.
- Keep examples short enough to paste into a terminal without editing.
- Do not commit generated scan artifacts such as `shipcheck-report.json`.
- Exclude `.dogfood/` and `eval_results/` from broad cleanup sweeps unless the task targets those paths.

## Security Posture

- Paths passed to Git subprocesses are shell-quoted before execution.
- CI uses a pinned Kujo runtime ref so the gate runs against a reproducible language/runtime build.
- Unsupported output formats fail with exit `2` instead of silently falling back to Markdown.
- ShipCheck reads local repository files and runs local Git commands; it does not call network services while scanning.
- The complete threat model, output-handling limits, and reporting guidance are
  in [security.md](security.md).

## JSON Compatibility

Validate automation output against
[`schemas/shipcheck-report.schema.json`](../schemas/shipcheck-report.schema.json)
and follow [compatibility.md](compatibility.md) when upgrading or consuming a
new report field.

## Suggested Release Policy

1. Run `scan` and review warnings.
2. Run `checklist` and complete all release actions.
3. Run `gate` as final pass/fail enforcement.
4. Generate `release-note` draft and finalize human-edited notes.

## Troubleshooting

Common failure patterns:

- `Not a git repository`: run inside a git checkout.
- `No README file found`: add and commit repository README.
- `No changelog found`: add `CHANGELOG.md` with at least current release notes.
- `No version metadata found`: add version in `kennel.toml`, `VERSION`, or another supported manifest.

## Scope and Limits

ShipCheck is a local scanner. It does not currently:

- execute your tests,
- execute your linter,
- validate release artifacts,
- publish releases.

It detects release readiness signals so your team can enforce consistent standards before shipping, but it does not certify a release or replace human review.

## Repository verification

From the ShipCheck checkout, with the runtime on `PATH`:

```bash
for source in shipcheck.kujo src/*.kujo; do
  kujo check "$source"
  kujo lint "$source"
done
tests/cli-output-contract.sh
python3 tests/hardening-contract.py
```

Both test suites accept `KUJO_BIN=/absolute/path/to/kujo`. The Python suite uses
only the standard library, temporary fixtures and offline subprocesses. CI runs
both suites plus source checks and the self gate. The Eval definition in
`tests/shipcheck_eval.json` expects the repository root as its working directory.

For a repeatable comparison against the pre-hardening implementation:

```bash
mkdir -p .dogfood/hardening
python3 tests/benchmark.py 4c958ab18d8a48c46e5904261af43d3e031343d1 .dogfood/hardening/benchmark.json
```

The benchmark alternates baseline/current execution order, discards warmups,
records seven samples per command, and requires byte-identical fixture output.
Timing is diagnostic evidence rather than a noisy CI threshold. Review the
fixture and baseline reference when intentionally changing supported output.

`release-note` reads version metadata and at most 20 Git log entries; it does not
run readiness checks. Version priority is kennel.toml, a non-empty VERSION,
package.json, then Cargo.toml. Run `gate` separately for readiness enforcement.
