# ShipCheck Compatibility Policy

## Scope

This policy covers the CLI commands and JSON report emitted by ShipCheck
`1.x`. ShipCheck remains a local-first tool; this policy does
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

Review the changelog and schema diff before upgrading. Pin a tested `1.x`
release in automation.

## Hardening corrections (2026-09-07)

Commands, options, JSON schema, check IDs, severities and numeric gate semantics
are unchanged. Invalid metadata, non-file signals, and descriptive text mistaken
for commands no longer pass checks. Legal TOML syntax is accepted through the
runtime parser. Root entrypoint detection now uses the runtime's boolean string
predicate contract. These corrections can change findings for previously
misclassified repositories; they do not redefine the check catalog.

A regular-file target returns exit 1 with `Not a directory`; blank option values
return exit 2. Equals-containing paths remain accepted. Human output displays
terminal controls visibly; machine JSON retains the original strings. Node and
Rust release-note drafts now use the same version sources recognized by scans.
