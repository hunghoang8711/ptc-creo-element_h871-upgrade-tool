# ver-03 Stage 1 — isolated single-browser diagnostic baseline

**Branch:** `rebuild/ver-03-from-ver-02`  
**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Status:** Stage 0-equivalent diagnostic baseline passed in Modeling 18.1; no Stage 1 feature has been added yet.

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

This diagnostic deliberately removes all multi-tab functionality. The user has now confirmed that it runs successfully in Modeling 18.1 and behaves exactly like Stage 0. This establishes that the renamed Stage 1 command/helper prefix is not, by itself, causing the earlier failure. The exact cause among the removed multi-browser/tab changes remains unknown.

## Runtime confirmation and next step

User confirmed on 2026-11-16 that this Stage 1 source runs successfully in Creo Modeling 18.1 and has the same functionality as Stage 0. No new feature is present in this diagnostic baseline.

The next revision will introduce only one tab-related API change, with all search, report, native selection and Apply logic kept identical. The user must test that isolated revision before any additional tab or multi-browser behavior is added. If the fatal exception returns, revert that single experiment to this confirmed baseline.

## Preservation and safety

- Stage 0 source, ver-01 and ver-02 remain unchanged.
- The former multi-browser Stage 1 implementation remains in Git history.
- The unstable former UICT-based ver-03 remains preserved separately.
- Do not test on or overwrite the original customer model.
- No runtime success is claimed until the user confirms it in Modeling 18.1.
