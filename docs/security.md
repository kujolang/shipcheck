# ShipCheck Threat Model and Security Boundaries

## Intended use

ShipCheck is a local, read-only release-readiness scanner for repositories the
operator is authorized to inspect. It is not a security scanner, release
certifier, sandbox, or policy-enforcement system.

## Assets and trust boundaries

- Repository paths and filenames are untrusted input. ShipCheck shell-quotes
  paths supplied to Git subprocesses, and contract tests cover shell
  metacharacters in target directories.
- Repository contents are read as text to detect common readiness signals.
  ShipCheck does not upload those contents or make network requests.
- Git metadata is treated as local evidence only. A passing result does not
  prove provenance, signature validity, branch protection, or artifact safety.
- JSON and Markdown output may include the operator-supplied target path and
  repository-derived messages. Do not publish reports from sensitive paths
  without reviewing them.

## Non-goals and limitations

ShipCheck does not execute project tests, linters, builds, package installs, or
release artifacts. It cannot detect malicious repository hooks, validate hosted
CI state, assess dependencies, or establish that a project is safe to publish.
Run it in an environment appropriate for the repository and pair it with
independent security review and release approval.

## Reporting a vulnerability

Do not include secrets or exploit payloads in public issues. Report suspected
path-handling, output-leakage, or command-execution vulnerabilities privately to
the repository maintainers with a minimal reproduction and expected impact.

## Output and filesystem handling

Human-readable report fields and CLI diagnostics escape C0/C1 terminal control
characters as visible `\uXXXX` sequences. Git release-note output disables color
and escapes controls in each commit line. JSON preserves the original strings
using JSON escaping. Reports and commit subjects remain untrusted Markdown;
render them with a viewer that disables raw HTML and review before publication.

The scanner requires a directory target and probes regular files before reading
file signals, avoiding accidental reads from directories or FIFOs. Symlinks to
regular files remain supported: this is not a filesystem confinement boundary.
Filesystem probes and reads are not an atomic snapshot; concurrent repository
changes can affect observations or cause a runtime I/O error. Retry only after
stabilizing the target if a reproducible report is required.

Metadata and source files are buffered by the runtime, with no ShipCheck-specific
size quota. Root scans are shallow and release history is limited to 20 entries,
but file size and directory breadth still determine resource use. Use external
resource limits for adversarial repositories. No new cache, retry loop, mutable
persistent state, or repository execution capability is introduced by scanning.
