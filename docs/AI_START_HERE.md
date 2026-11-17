# AI Start Here – H871 Creo Tools

This file is the mandatory entry point for any new ChatGPT conversation or developer continuing this repository.

## Mandatory reading order

1. Confirm repository `hunghoang8711/ptc-creo-element_h871-upgrade-tool` and work on `main`.
2. Read `PROJECT_CONTEXT.md`.
3. Read `docs/PART_FILTER_EXPERIMENT_HISTORY.md` before touching Part Filter.
4. Read `docs/ENGINEERING_KNOWLEDGE_BASE.md`, `docs/API_VERIFICATION_REGISTER.md`, `docs/TECHNICAL_DECISIONS.md`, `docs/KNOWN_ISSUES.md` and `docs/LESSONS_LEARNED.md`.
5. Fetch and inspect the exact current source on `main`; never rely on an old chat's paths or assumptions.

## Source preservation

- Preserve `src/part-filter/ver-02/H871_PART_FILTER_VER_02.lsp` unchanged.
- Preserve `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp` unchanged.
- Preserve `src/part-filter/ver-03-rebuild/H871_PART_FILTER_VER_03_REBUILD.lsp` as a separate native Browser reference; do not confuse it with the UICT ver-03 source.
- Keep all executable LISP test/diagnostic code under `src/`. Keep written test plans under `tests/`.
- Rejected ver-04/ver-05/ver-06/ver-07 implementations are not canonical code. Their lessons belong in the experiment history, not in new permanent version folders.
- Work on `main`; do not create branches for routine experiments.

## Critical engineering rules

- Target PTC Creo Elements/Direct Modeling 18.1, not Creo Parametric.
- Preserve the exact Density Instance AND Density Base predicate, numeric mappings and tested /1000 normalization.
- Do not assume later-release PTC APIs work in 18.1.
- Preserve native Graphical Browser selection and Apply. Never use a hidden Browser bridge or custom Apply callback as a shortcut.
- A BrowserNode creation token is not a BrowserNode structure; resolve it, then verify actual viewport selection.
- A successful trace, status code or non-NIL return is not proof of Modeling selection.
- Use disposable model copies for risky runtime tests.
- Separate static checks from loaded, functionally tested and user-confirmed results.
- Before editing, identify the exact failing stage and change one isolated layer only. Do not repeat a previously failed experiment without new evidence.

## Current Part Filter state (2026-11-17)

The native Browser rebuild opens Results, but the user reports that only Part Name is visible even though four column definitions exist in source. The latest table activation-order change did not fix it. The rebuild is not complete. The next step is targeted runtime diagnostics of Browser mode, active table, table roots and table activation results—not another speculative order change.

See `docs/PART_FILTER_EXPERIMENT_HISTORY.md` for the full error catalogue and ver-04 through ver-07 lessons.
