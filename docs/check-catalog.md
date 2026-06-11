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
