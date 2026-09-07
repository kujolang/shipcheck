# ShipCheck Check Catalog

ShipCheck currently runs 16 checks grouped into 4 categories.

## Severity Model

- Error: blocks release gate and causes non-zero gate exit.
- Warning: does not block gate by itself but highlights release risk.
- Info: passing check state.

## Repository Health

| Check ID | Purpose | Fails As |
| --- | --- | --- |
| `git-repo` | Confirms target is a git repository | Error |
| `readme` | Confirms a README file exists | Error |
| `license` | Detects license file presence | Warning |
| `ignore-files` | Detects `.gitignore` or `.dockerignore` | Warning |

## Code Quality

| Check ID | Purpose | Fails As |
| --- | --- | --- |
| `tests-exist` | Detects test directories or test files | Error |
| `lint-command` | Detects lint capability from manifest/config/scripts | Warning |
| `format-command` | Detects format capability from manifest/config/scripts | Warning |
| `ci-config` | Detects CI workflow configuration files | Warning |

## Documentation

| Check ID | Purpose | Fails As |
| --- | --- | --- |
| `readme-install` | Verifies README mentions install or quickstart guidance | Warning |
| `readme-usage` | Verifies README includes usage/examples guidance | Warning |
| `examples` | Detects `examples/` or `demo/` content | Warning |
| `docs` | Detects non-empty `docs/` directory | Warning |

## Release Metadata

| Check ID | Purpose | Fails As |
| --- | --- | --- |
| `version-metadata` | Detects version metadata in known manifests/files | Error |
| `changelog` | Detects changelog/history documentation | Error |
| `kennel-manifest` | Validates presence and core fields in `kennel.toml` | Warning |
| `entry-point` | Detects executable Kujo entrypoint metadata/script | Warning |

## Notes

- Check implementations live in `src/checks.kujo`.
- Report formatting and gate calculations live in `src/report.kujo`.
- Gate behavior is intentionally conservative: only error-level failures block release.
- The report contract is defined by
  [`schemas/shipcheck-report.schema.json`](../schemas/shipcheck-report.schema.json).
- A passing gate is evidence that these local metadata checks passed, not human
  release certification or a security assessment.
- The CLI contract suite exercises non-repository failure handling, hostile path
  quoting, and representative Node and Kujo fixture repositories. The generic
  checks deliberately report signals rather than infer that a project is safe,
  production-ready, or publishable.

## Detection details

Named file signals require regular files (symlinks to regular files remain
supported). Directories and FIFOs named like manifests or README files do not
count. Non-empty test/CI/docs/example directories remain presence signals;
ShipCheck does not establish that their contents are runnable or correct.

JSON and TOML metadata use the Kujo runtime parsers. A malformed document or a
missing, blank, or non-string metadata field cannot establish that signal.
Kennel metadata comes from `[package]`; entry metadata comes from `[kujo].entry`.
The entry check remains a declaration signal, not a validation of the declared
path. Without entry metadata, visible root `.kujo` files containing `args()` or
`func main` are inspected in sorted filename order.

Lint/format signals recognize non-empty string scripts named `lint`, `check`,
`style` or `format`, `fmt`, `beautify`, respectively, including colon suffixes
such as `lint:ci`. Comments, descriptions, and dependency names do not count.
Makefiles recognize literal target headers, including multiple targets; variable
expansion, includes and conditional evaluation require human review. A regular
`kujo.toml` continues to indicate availability of Kujo lint/format tooling.
