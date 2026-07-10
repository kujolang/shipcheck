# ShipCheck Compatibility Policy

## Scope

This policy covers the CLI commands and JSON report emitted by ShipCheck
`0.1.x`. ShipCheck remains an experimental, local-first tool; this policy does
not represent a release certification or a promise of hosted-service support.

## JSON reports

The normative report shape is
[`schemas/shipcheck-report.schema.json`](../schemas/shipcheck-report.schema.json).
The `tool`, `version`, `summary`, and per-check fields are contract fields.

- Patch releases preserve all existing fields, types, check identifiers, and
  gate exit semantics.
- Backward-compatible additions may add optional fields or checks. Consumers
  must ignore fields they do not recognize.
- A field removal, rename, type change, semantic reinterpretation, or change to
  which error-level checks block `gate` requires a documented breaking release,
  an updated schema identifier, migration notes, and fixture coverage.
- `summary.gate_passed` is numeric (`1` or `0`) for compatibility with the
  Kujo runtime. The command exit status remains the authoritative CI signal.

## CLI commands

The supported commands are `scan`, `checklist`, `gate`, `release-note`,
`version`, and `help`. `scan` remains informational; `gate` returns `1` for an
error-level failure and `0` when only warnings remain. Unsupported formats and
unknown commands return `2`.

## Upgrade practice

Review the changelog and schema diff before upgrading. Pin a tested `0.1.x`
revision in automation until ShipCheck has a tagged stable release.
