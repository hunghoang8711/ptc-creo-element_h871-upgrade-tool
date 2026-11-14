

## 2026-11-14 – Consolidate Part Filter implementation lessons
- Recorded user-confirmed resolution of the keyword-argument error and working individual row selection.
- Recorded latest Select All / Clear Selection menu declarations as an implementation awaiting Creo 18.1 confirmation, not as a verified feature.
- Recorded compact column widths (28 / 13 / 12 / 42 characters) and the important API detail that Graphical Browser `:initial-width` is measured in characters.
- Recorded repeat-search design: keep Assembly/Density inputs available after each run; create a separate closable results browser for each search.
- Added verification discipline: distinguish static checks, API-reference assumptions, and user-confirmed runtime tests.


## 2026-11-14 – Select All visibility follow-up
- Added a dedicated `:modeMenu` action row containing visible-intent Select All and Clear Selection controls.
- Bound actions directly to Graphical Browser `:select-all` and `:clear-select-list` commands.
- Updated popup fallbacks to use `:browser-push-cmd` as shown in PTC Graphical Browser examples.
- Preserved compact columns and the working manual multi-selection / Apply path.
- Creo 18.1 runtime visibility and selection test pending.


## 2026-11-14 – 18.1 compatibility correction and dedicated selection controls
- Replaced the prior `:modeMenu` attempt with a separate UI Construction Toolkit selection-tools dialog containing Select All and Clear Selection pushbuttons.
- Switched table column sizing from `:initial-width` to legacy `:max-width` for the Modeling 18.1 target; set max widths to 22 / 8 / 8 / 30.
- Preserved the native browser row selection and Apply workflow.
- Runtime validation in Creo 18.1 is pending.


## 2026-11-14 – Single-window Part Filter controls
- Removed the separate Selection Tools dialog.
- Added a resizable host shell with the Graphical Browser embedded in its browser area.
- Added a unified footer ordered Apply, Select All, Clear Selection, Close.
- Select All now runs `:select-all` then `:select-and-execute` so the complete result set is handed to Modeling immediately.
- Clear Selection only clears browser row selection.
- Modeling 18.1 compatibility and runtime behavior remain pending user verification.


## 2026-11-14 – Browser embedding diagnostics
- Added runtime diagnostics for `sd-set-graphical-browser-parent` failure.
- Reports whether the browser, dialog shell, host grid, and nested browser-parent grid exist, plus browser docked state.
- Diagnostic runs before cleanup; no functional fix is claimed yet.


## 2026-11-14 – Corrected unified results dialog hierarchy
- Create root resizable grid area under the dialog shell's automatic `-AA` client area.
- Create the browser grid as a child of the root grid.
- Footer buttons remain in the root grid beside the browser area.
- Fix addresses the confirmed missing-parent defect; runtime test pending.
