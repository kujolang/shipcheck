# ShipCheck Examples

This directory contains copy/paste command examples for common workflows.

The shell-script example expects the Kujo runtime to be available as `kujo` on `PATH`.

## Scan Current Repository

```bash
kujo run shipcheck.kujo -- scan
```

## Emit JSON Report Artifact

```bash
kujo run shipcheck.kujo -- scan --format json > shipcheck-report.json
```

## Gate Another Repository

```bash
kujo run shipcheck.kujo -- gate --dir ../kujo-spec --format json
```

## Generate a Release Checklist

```bash
kujo run shipcheck.kujo -- checklist --dir .
```

## Shell Script Example

```bash
PATH=/path/to/kujo/target/release:$PATH bash examples/scan-local-and-external.sh
```
