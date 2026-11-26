# ShipCheck Threat Model and Security Boundaries

## Intended use

ShipCheck is a local, read-only release-readiness scanner for repositories the
operator is authorized to inspect. It is not a security scanner, release
certifier, sandbox, or policy-enforcement system.

## Assets and trust boundaries

- Repository paths and filenames are untrusted input. ShipCheck passes
  paths as literal Git arguments without a shell, and contract tests cover shell
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
using JSON escaping. Markdown path labels and check values encode syntax characters from the input. Review reports and commit subjects before publication.

The scanner requires a directory target. Files and directories that resolve
beneath that target can supply readiness signals. Reads of regular files use
rooted descriptors and reject replacement links below the root. In-tree
aliases resolve to their in-tree destination. Choose a stable target and parent
directory when inspecting a changing repo.

Readme, Makefile, and manifest reads are capped at 1 MiB each, and VERSION
reads at 256 bytes. Root filename heuristics examine the first 8,192 sorted
entries. The source-based entry check considers at most 256 root scripts with
a 256 KiB read limit per script. Directory listings use bounded pages. The
runtime still enumerates names to select each page.

Git calls use a five-second deadline and one MiB per output stream. They
disable paging, optional locks, filesystem monitors, and object replacements.
Repository-selection environment variables are excluded. Release notes read at
most 20 commit subjects without signature display. Failed or incomplete Git
output cannot establish readiness.
