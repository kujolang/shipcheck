# Changelog

## Unreleased

- Reconciled the public version badge with the `0.1.0` manifests and CLI.
- Added a versioned JSON report schema, schema-validation contract coverage,
  compatibility policy, and security/threat-model documentation.
- Added CI that builds a pinned Kujo runtime, runs the CLI output contract, and self-scans ShipCheck.
- Fixed `gate --format json` so automation receives valid JSON without appended human status text.
- Quoted target directories before Git subprocess calls and added regression coverage for shell metacharacters in paths.
- Added unsupported-format validation with exit `2`.
- Updated README, operations, and examples to reflect the current CI, security, and automation posture.
- Added agent/contributor guidance for canonical examples, generated artifact exclusions, and search hygiene.
- Reduced repetitive CLI/report output printing with local helpers while preserving command output.
- Added a CLI output contract test for stable help/version output and JSON/gate smoke coverage.
- Fixed README and kennel manifest checks that stored boolean expressions and then compared them as integer flags.
