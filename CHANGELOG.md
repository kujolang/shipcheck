# Changelog

## Unreleased

- Parse TOML metadata with the runtime parser and require real script/entry fields.
- Reject non-file readiness signals, blank CLI values and non-directory targets.
- Restore root Kujo entrypoint detection and stabilize filename selection.
- Escape terminal controls in human output while preserving JSON data.
- Draft release notes without a full scan; recognize Node and Rust versions.
- Add offline hardening regressions, source CI checks and portable Eval commands.


## Unreleased

### Fixed

- Reject unknown and command-incompatible CLI options, and report unknown commands before validating their arguments.
- Stop treating empty test, demo, and CI directories as implemented release signals.
- Require real version metadata in `package.json`, non-empty `VERSION` files, and the TOML `[package]` section.
- Validate required `kennel.toml` fields in `[package]` instead of matching unrelated text.
- Align the public JSON schema identifier and version pattern with ShipCheck 1.x output.

## [1.0.0] - 2026-08-08

- Added launch-readiness Spec and Eval metadata for the Kujo prelaunch review.
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
