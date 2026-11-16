# ver-03 Stage 1 — isolated single-browser diagnostic baseline

**Branch:** `rebuild/ver-03-from-ver-02`  
**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Status:** Source replaced with a Stage 0-equivalent diagnostic baseline; runtime retest required.

## Current source

- `H871_PART_FILTER_VER_03_STAGE1.lsp`
- Command: `H871_PART_FILTER_VER_03_STAGE1`
- Stage 0 canonical baseline remains unchanged at `src/part-filter/ver-03-rebuild/`.

## Why Stage 1 was reset

The previous multi-browser implementation caused Fatal Exception `0xC00000FD` immediately after Search OK. Removing the later-version Browser Tree `:update-args` option and switching to zero-argument callbacks did not change the runtime result.

The trace file `%USERPROFILE%/H871_PART_FILTER_STAGE1_TRACE.txt` was created once but remained 0 KB and was not updated on a later search. The trace writer swallowed its own errors with `ignore-errors`; therefore the empty file is **not reliable evidence** about which search stage was reached. The trace mechanism is retired for this diagnostic cycle.

## Current diagnostic design

Stage 1 source has been replaced by a mechanical clone of the user-confirmed Stage 0 source:

- Same single native Graphical Browser and single Browser Tree.
- Same zero-argument Browser Tree updater.
- Same recursive Assembly traversal and Density Instance/Base comparison.
- Same report generation.
- Same native row selection, Select All, Clear Selection and Apply behavior.
- No multi-browser sessions, generated callback closures, `:createAsTab`, `:tabname`, or trace-file writer.
- Helper/global symbols remain isolated with the `h871-pf-mt-` prefix.
- Dialog command remains `H871_PART_FILTER_VER_03_STAGE1`.

This diagnostic deliberately removes all multi-tab functionality. Its sole purpose is to determine whether the Stage 1 failure came from the multi-browser changes or from another difference between the former Stage 1 implementation and Stage 0.

## User test — one search only

Use a disposable model copy.

1. Start a fresh Modeling 18.1 session.
2. Load the latest Stage 1 LISP file from this branch.
3. Run `H871_PART_FILTER_VER_03_STAGE1`.
4. Search one known pair, preferably CNC + SUS304 (numeric Instance=1, Base=304).
5. Report whether the Results Browser appears, and whether Apply works.

Do not test multiple pairs yet. If this single-browser diagnostic succeeds, the next step is to reintroduce exactly one multi-tab-related change at a time. If it fails with the same fatal exception, compare the dialog/run path against Stage 0 and isolate the earliest differing expression.

## Preservation and safety

- Stage 0 source, ver-01 and ver-02 remain unchanged.
- The former multi-browser Stage 1 implementation remains in Git history.
- The unstable former UICT-based ver-03 remains preserved separately.
- Do not test on or overwrite the original customer model.
- No runtime success is claimed until the user confirms it in Modeling 18.1.
