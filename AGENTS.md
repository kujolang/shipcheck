# Agent Notes

ShipCheck is a small Kujo CLI. Keep changes easy to review and preserve the command surface unless a task explicitly asks for behavior changes.

## Canonical Surfaces

- `README.md` is the primary onboarding path.
- `examples/README.md` and `examples/scan-local-and-external.sh` are copyable examples. Prefer concise commands and idioms that agents should imitate.
- `shipcheck.kujo`, `src/scan.kujo`, `src/checks.kujo`, and `src/report.kujo` are hand-written source files.
- `docs/check-catalog.md` is the public check reference and should stay aligned with `src/checks.kujo`.
- `docs/operations.md` is the operational/CI guide.

## Non-Canonical Or Bulk Surfaces

- `.dogfood/shipcheck/` contains historical implementation notes. Read it for context, but do not treat it as the current API contract.
- `eval_results/` contains generated or bulk evaluation output. Exclude it from broad readability sweeps unless the task explicitly targets eval artifacts.

## Search Hygiene

Use targeted searches that skip generated and historical bulk paths by default:

```bash
rg "pattern" -g '!eval_results/**' -g '!.dogfood/**'
```

When sweeping examples, start with:

```bash
rg -n "print\\(|format json|checklist|gate|release-note" README.md docs examples src shipcheck.kujo
```

Prioritize copyable examples over tests: examples should model the most token-efficient idioms we want agents to imitate.

## Output Style

For repeated static CLI output, prefer a small local `print_lines([...])` helper over runs of adjacent `print(...)` calls. Keep first-run examples direct, and only add helpers when they make the command or report easier to scan.

## Validation

If `kujo` is not on `PATH`, set `KUJO_BIN` to the local runtime path before running tests:

```bash
KUJO_BIN=/path/to/kujo tests/cli-output-contract.sh
```

Run focused checks for touched Kujo files, then run the CLI contract test and ShipCheck's own scan/gate smoke checks.
