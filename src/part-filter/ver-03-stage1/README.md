# ver-03 Stage 1 — isolated single-browser diagnostic baseline

**Branch:** `rebuild/ver-03-from-ver-02`  
**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Status:** `:createAsTab t` passes basic runtime/functionality test; visible tab presentation awaits confirmation.

## Current source

- `H871_PART_FILTER_VER_03_STAGE1.lsp`
- Command: `H871_PART_FILTER_VER_03_STAGE1`
- Stage 0 canonical baseline remains unchanged at `src/part-filter/ver-03-rebuild/`.

## Why Stage 1 was reset

The previous multi-browser implementation caused Fatal Exception `0xC00000FD` immediately after Search OK. Removing the later-version Browser Tree `:update-args` option and switching to zero-argument callbacks did not change the runtime result.

The trace file `%USERPROFILE%/H871_PART_FILTER_STAGE1_TRACE.txt` was created once but remained 0 KB and was not updated on a later search. The trace writer swallowed its own errors with `ignore-errors`; therefore the empty file is **not reliable evidence** about which search stage was reached. The trace mechanism is retired for this diagnostic cycle.

## Confirmed diagnostic baseline

Before the current experiment, the user confirmed that the Stage 0-equivalent Stage 1 source ran successfully in Modeling 18.1. It provided exactly the same functionality as Stage 0.

## Current experiment — one API difference

The current source adds only `:createAsTab t` to the existing `sd-create-graphical-browser` call. It still creates exactly one Browser Tree and one Graphical Browser. No multiple-browser sessions, callback closures, `:tabname`, search changes, report changes, or selection/Apply changes are included. User reports that this revision runs successfully and retains the same functionality as Stage 0. This confirms basic compatibility, but does not yet prove that the Browser is visibly presented as a tab.

## Previous diagnostic design

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

## Test this isolated experiment

Use a disposable model copy and a fresh Modeling 18.1 session. Load the current Stage 1 file and run `H871_PART_FILTER_VER_03_STAGE1` for one known pair (CNC-SUS304, numeric 1/304). Confirm whether the Results Browser opens and whether row selection, Select All, double-click and Apply still work. Also note whether the browser is presented as a tab or as a normal window.

If the fatal exception returns or the Browser fails to open, revert only `:createAsTab t` to return to the confirmed baseline. Do not add a second browser or any other tab-related argument until this experiment passes.

## Preservation and safety

- Stage 0 source, ver-01 and ver-02 remain unchanged.
- The former multi-browser Stage 1 implementation remains in Git history.
- The unstable former UICT-based ver-03 remains preserved separately.
- Do not test on or overwrite the original customer model.
- No runtime success is claimed until the user confirms it in Modeling 18.1.
