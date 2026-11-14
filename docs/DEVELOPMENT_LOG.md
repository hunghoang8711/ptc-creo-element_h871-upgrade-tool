# Development Log

Concise milestone history. Detailed abandoned UI iterations are consolidated in `LESSONS_LEARNED.md`; Git commits retain the full source history.

## 2026-11-14 – ver-02 mapped filter dialog candidate

- Created `src/part-filter/H871_PART_FILTER_VER_02.lsp` on branch `feature/part-filter-ver-02`; preserved ver-01 source unchanged.
- Kept Assembly selection unchanged.
- Replaced numeric Instance input with Machining Process choices: CNC=1, KH=2, CG=3, COVER=4.
- Replaced numeric Base input with Material choices: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
- Added adjacent read-only code fields; selected numeric range values are passed directly to the existing `h871-pf-run`.
- Default remains CNC + SUS304 (1/304).
- Existing density normalization, exact pair matching, report, Results Browser, Select All and native Apply implementation retained.
- Static source review only. Not yet loaded or functionally tested in Modeling 18.1.

## 2026-11-14 – Record deferred multi-search tabs

- Captured the next-stage requirement: each search must retain an independent result set, later presented as browser-like tabs with user-defined material/process tab names.
- Deferred implementation until the ver-02 dialog is validated. Each search session will need independent data and unique Browser/Tree names.

## 2026-11-14 – Results Browser baseline stabilized

User-confirmed in Modeling 18.1:
- Results Browser opens and displays matching Part rows.
- Select All is available.
- Clicking individual rows selects the corresponding Part.
- Native Apply transfers selected Part(s) to Modeling selection.

Resolved defects:
- Corrected `sd-browser-set-status-text` keyword usage by passing the message with `:value`.
- Removed a custom Apply callback that replaced native behavior.
- Restored standalone Graphical Browser after the unified host-shell/browser-parent experiment failed.

## Current source roles

- Confirmed ver-01 baseline: `src/part-filter/H871_PART_FILTER.lsp`
- ver-02 candidate: `src/part-filter/H871_PART_FILTER_VER_02.lsp`
- Diagnostic baseline: `src/part-filter/H871_PART_FILTER_DIAG.lsp`
