# Source Code

All executable Creo Lisp, test scripts and diagnostic utilities belong under `src/`.

## Part Filter

- `part-filter/ver-01/` – earlier numeric filter source.
- `part-filter/ver-02/` – preserved mapped Process/Material baseline.
- `part-filter/ver-03/` – preserved UICT/internal-tab source reference.
- `part-filter/ver-03-rebuild/` – preserved native Graphical Browser rebuild reference.
- `part-filter/H871_DENSITY_API_TEST.lsp`, `H871_DENSITY_DIAG.lsp`, `H871_DENSITY_KIND_TEST.lsp`, `H871_PART_FILTER_DIAG.lsp` – focused API and runtime diagnostics.

Do not place executable LISP test files in the repository-level `tests/` folder. That folder is reserved for written procedures and sanitized test fixtures.

Experimental ver-04 through ver-07 implementations have been removed from the current source tree. Their findings are consolidated in `docs/PART_FILTER_EXPERIMENT_HISTORY.md`.
