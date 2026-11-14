# Development Log

Concise milestone history. Detailed abandoned UI iterations are consolidated in `LESSONS_LEARNED.md`; Git commits retain the full source history.

## 2026-11-14 – ver-02 mapped filter dialog

- User tested ver-02 and reported a very good result; promoted the mapped-choice dialog to the accepted working baseline.

## 2026-11-14 – ver-02 mapped filter dialog candidate

- Created `src/part-filter/H871_PART_FILTER_VER_02.lsp` on branch `feature/part-filter-ver-02`; preserved ver-01 source unchanged.
- Kept Assembly selection unchanged.
- Replaced numeric Instance input with Machining Process choices: CNC=1, KH=2, CG=3, COVER=4.
- Replaced numeric Base input with Material choices: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
- Added read-only code fields after each selector; selected numeric range values are passed directly to the existing `h871-pf-run`. The standard dialog places these variables on separate rows, so same-row right-side placement remains deferred pending 18.1 UI verification.
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

## 2026-11-14 – ver-03 independent multi-search Browser candidate

- Created branch `feature/part-filter-multi-browser-sessions` from the ver-02 feature branch; ver-01 and ver-02 sources remain unchanged.
- Added `src/part-filter/H871_PART_FILTER_VER_03.lsp` with a session registry and monotonically unique Browser/Tree names.
- Each successful search stores its own result list, Assembly, filter values, label and diagnostic samples. The previous search's Browser and Tree are not destroyed.
- Tab label derives from Material + Machining Process (e.g. SUS304-CNC); duplicate searches receive a suffix.
- Select All, Clear Selection and selection summary callbacks are parameterized by Browser name. Native Apply remains unmodified.
- Requested docked tabs with `:createAsTab t` and `:tabname`; routed the tree update callback using `:update-args`.
- Static Lisp delimiter check passed after correcting one missing closing parenthesis. This is not a Lisp compile or Creo runtime test.
- The tab/update-args APIs are documented in later PTC Integration Kit references; Modeling 18.1 compatibility and all multi-session behaviors remain untested.

## Current source roles

- Confirmed ver-01 baseline: `src/part-filter/H871_PART_FILTER.lsp`
- ver-02 candidate: `src/part-filter/H871_PART_FILTER_VER_02.lsp`
- Diagnostic baseline: `src/part-filter/H871_PART_FILTER_DIAG.lsp`
