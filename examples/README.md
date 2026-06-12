# ShipCheck Examples

This directory contains canonical copy/paste command examples for common workflows.

The shell-script example expects the Kujo runtime to be available as `kujo` on `PATH`.

Generated report artifacts such as `shipcheck-report.json` are intentionally not committed.

## Scan Current Repository

```bash
kujo run shipcheck.kujo scan
```

## Emit JSON Report Artifact

```bash
kujo run shipcheck.kujo scan --format json > shipcheck-report.json
```

## Gate Another Repository

```bash
kujo run shipcheck.kujo gate --dir ../kujo-spec --format json
```

## Generate a Release Checklist

```bash
kujo run shipcheck.kujo checklist --dir .
```

## Shell Script Example

```bash
PATH=/path/to/kujo/target/release:$PATH bash examples/scan-local-and-external.sh
```

Pass a repository path to override the default `../kujo-spec` external scan target:

```bash
PATH=/path/to/kujo/target/release:$PATH bash examples/scan-local-and-external.sh ../my-project
```
