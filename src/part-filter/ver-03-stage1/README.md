# ver-03 Stage 1 — isolated single-browser diagnostic baseline

**Branch:** `rebuild/ver-03-from-ver-02`  
**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Status:** Explicit `sd-dock-graphical-browser` experiment committed; runtime test pending.

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

The current source retains `:createAsTab t` and, immediately after `sd-show-graphical-browser`, makes one additional isolated call to `sd-dock-graphical-browser` with `:show t`. The docking call is protected by `ignore-errors` so it cannot prevent the known-good floating Results window from appearing if the API is unavailable or rejected. User confirmed that the `:createAsTab t`-only revision still opened a separate floating window. PTC documentation notes that the saved PDS preference may override `:createAsTab`, and documents the explicit docking function. The explicit docking experiment is committed but still requires runtime testing in Modeling 18.1.

## Previous diagnostic design

Stage 1 source has been replaced by a mechanical clone of the user-confirmed Stage 0 source:

- Same single native Graphical Browser and single Browser Tree.
- Same zero-argument Browser Tree updater.
- Same recursive Assembly traversal and Density Instance/Base comparison.
- Same report generation.
- Same native row selection, Select All, Clear Selection and Apply behavior.
- No multi-browser sessions, generated callback closures, `:tabname`, or trace-file writer. The current experiment adds `:createAsTab t` plus one protected explicit docking call.
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


## KI-015 – Stage 1 Browser remains floating despite createAsTab

- **User runtime result (2026-11-16):** Results Browser still appears as a separate floating window. Searching a different Density pair refreshes/replaces the displayed Results window. Core filter/selection/Apply behavior remains successful.
- **PTC API finding:** PTC Graphical Browser reference documents that `:createAsTab t` requests an initially docked Browser, but the setting can be overwritten by the docking preference saved in PDS from the previous Modeling session. The same reference documents `sd-dock-graphical-browser` as the explicit API to dock a floating Browser into the Browser Bar.
- **Next isolated experiment:** After the existing `sd-show-graphical-browser` call, Stage 1 now calls `(sd-dock-graphical-browser *h871-pf-mt-browser-name* :show t)`. This is wrapped in `ignore-errors` so an unavailable/rejected docking API cannot prevent the already-working floating Results window from opening.
- **Scope:** One Browser and one Browser Tree only. No second result session, unique tab per pair, `:tabname`, callback changes, filter changes, or selection/Apply changes.
- **Static status:** Source patch committed; parenthesis/API availability not yet runtime-verified in the user's Modeling 18.1 installation.
- **User test required:** Run one known matching pair. Confirm whether Results is now docked in the Browser Bar and whether row selection, Select All, double-click and Apply still work. If it remains floating, report whether any error appears; because the docking call is protected, the window should still be available if the API is unsupported.
- **References:** PTC Creo Elements/Direct Modeling Integration Kit, Graphical Browsers reference (20.6/20.7 documentation; exact 18.1 runtime compatibility still requires user test).
