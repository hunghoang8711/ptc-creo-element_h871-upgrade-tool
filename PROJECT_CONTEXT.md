

## 2026-11-14 – Consolidated Part Filter progress and engineering lessons

### User-confirmed runtime status
- Part Filter Results browser opens and displays Part names.
- Individual Part rows can be selected.
- The `Odd number of arguments for keywords.` message is resolved after both `sd-browser-set-status-text` calls were changed to use `:value`.

### Latest source state (pending user verification)
- Select All / Clear Selection are declared in both `:buttonMenu` and `:topMenu`; callbacks call `h871-pf-select-all` and `h871-pf-clear-selection`.
- `:buttonMenuOffObjectOnly nil` is set to broaden button-menu availability.
- Browser max width = 900; column widths = 28 / 13 / 12 / 42 characters for Part Name / Density Instance / Density Base / Assembly Path.
- The filter dialog calls `sd-return-from-ok-action` after each search to preserve Assembly and Density inputs for repeat searches. Each run recreates a separate results browser/tree intended to be closed independently.

### Engineering lessons to retain
- Keyword-based APIs must receive explicit keyword/value pairs; positional arguments can produce the odd-keyword-count error.
- Do not assume a declared Graphical Browser menu item is visible in Creo 18.1. User runtime confirmation is required; if still hidden, change to a different always-visible UI mechanism rather than iterating blindly on the same menu mapping.
- Graphical Browser `:initial-width` is character-based, not pixel-based. Use compact character counts and verify visually.
- Keep filter input state and result presentation separate to support multiple searches and independently closable result windows.
- Track static validation, API compatibility assumptions, and actual Creo 18.1 runtime results as distinct evidence categories.

### Next test required
Confirm Select All and Clear Selection visibility/functionality, compact column layout, repeat search without reopening the filter dialog, and independent closing of the result browser. Until then, only error resolution and individual row selection are runtime-confirmed.


## 2026-11-14 – Select All visibility implementation update

The user confirms compact result columns and working manual multi-row selection followed by Apply. Select All remains absent from the visible result browser. The latest source therefore adds a dedicated `:modeMenu` row labelled "Selection" with Select All and Clear Selection buttons, calling native browser commands directly. The popup fallback uses PTC's documented `:browser-push-cmd` syntax. Preserve the working table and Apply behavior. This change is not runtime-confirmed: test button visibility, Select All, Clear Selection, and Apply in Creo Elements/Direct Modeling 18.1 before marking complete.


## 2026-11-14 – Part Filter screenshot follow-up and compatibility correction

The user's latest screenshot confirms Select All is still not visible and the first table column still pushes Density beyond the visible area.

### Latest source update
- Removed the `:modeMenu` dependency.
- Added a separate UICT dialog, "H871 - SELECTION TOOLS", with Select All and Clear Selection pushbuttons calling native Graphical Browser selection commands.
- Changed column sizing to the legacy `:max-width` option for the Modeling 18.1 target; current values are Part Name 22, Density Instance 8, Density Base 8, Assembly Path 30.

### Corrected documentation lesson
Do not describe the old `:max-width` sizing option as character-based. PTC's 20.4 release notes say `:max-width` was changed to `:initial-width` in that later release. For the 18.1 target, the legacy keyword is the appropriate compatibility candidate.

### Verification status
The user's manual multi-row selection and Apply workflow remains confirmed. The new UICT dialog and reduced column widths are implementation changes only; test them in Creo 18.1 before marking complete.


## 2026-11-14 – Part Filter single-window footer update

The user confirmed that the previous Select All / Clear Selection controls appeared in a separate window and requested them inside the Part Filter Results window, between Apply and Close. Select All must immediately perform the same hand-off as Apply.

### Latest implementation
- Removed the separate Selection Tools dialog.
- Created a resizable host dialog shell and embedded the Graphical Browser using `sd-set-graphical-browser-parent`.
- Added a single footer row ordered Apply / Select All / Clear Selection / Close.
- Apply uses native `:select-and-execute`.
- Select All uses `:select-all` followed by `:select-and-execute`, then hides the host window.
- Clear Selection uses `:clear-select-list`.
- Close hides the browser and host shell.
- The Graphical Browser's native OK/Abort labels are blanked so the host footer supplies the visible controls.

### Compatibility and test status
PTC's later Integration Kit docs describe browser-parent hosting inside a resizable grid area and UICT Pushbuttons inside a grid area. This is the architecture used by the latest source. Since the reference is later than Modeling 18.1, function availability and actual layout still require runtime confirmation. Static LISP checks pass; do not describe the feature as runtime verified until the user tests it.


## 2026-11-14 – Part Filter browser-parent runtime error

The user tested the unified results-window implementation and received `H871: Could not embed the results browser in its host window.`

PTC's release-history page places the resizable UICT functions and `sd-set-graphical-browser-parent` in older CoCreate Modeling history. Do not incorrectly label these APIs as introduced only in 20.7/20.8; they are plausible in the 18.1 lineage.

The latest source adds `h871-pf-parent-diagnostic`, which reports:
- Whether the named Graphical Browser exists and whether it is docked
- Whether the host dialog shell exists
- Whether the root host grid exists
- Whether the nested browser-parent grid exists

The diagnostic is displayed before the host shell is destroyed. Next action is to ask the user to load the latest source, run one search, and provide the complete `H871 EMBED DIAGNOSTIC` message. No runtime fix has yet been confirmed.


## 2026-11-14 – Confirmed missing-parent defect in Part Filter UI

The repeated `Could not embed the results browser` error was traced to an incomplete UICT hierarchy in source: the code tried to create the browser grid using `H871-PF-RESULTS-RG` as parent before creating that root grid.

The latest source creates:
1. Dialog shell basename `H871-PF-RESULTS`, whose client area is `H871-PF-RESULTS-AA`.
2. Root resizable grid `H871-PF-RESULTS-RG` under the automatic client area.
3. Browser resizable grid `H871-PF-BROWSER-RG` under the root grid.
4. Footer Pushbuttons under the root grid.
5. Graphical Browser parent set to the browser grid, with dialog basename `H871-PF-RESULTS`.

Static validation is required; runtime embedding remains unconfirmed until user tests the new source.


## 2026-11-14 – Part Filter host-window failure isolation

The user reports that the no-match path still works, but a search that finds matching Parts displays `H871: Could not create the unified results window.` This confirms the search reaches the result-window branch, but the specific UICT creation failure is not yet known.

The latest source replaces the generic host creation error with exact numbered stages:
1. API availability
2. Dialog shell creation
3. Root grid creation under the automatic `-AA` client area
4. Browser child grid creation
5. Apply button creation
6. Select All button creation
7. Clear Selection button creation
8. Close button creation

The next runtime test must capture the exact stage message. Do not alter the Density filter or browser-parent API speculatively. Static parenthesis balance is 0; no runtime fix is claimed.

 
## 2026-11-14 – Roll back unified results-window regression

### User report
After merging Apply / Select All / Clear Selection / Close into one window, searches that find Parts no longer open the results UI. The no-match path still works.

### History comparison
- Last known-good standalone browser source: commit `3e9f3c1`, blob `2d65e613708e8ef8721c5cd58c50d950b89488b3`.
- The standalone implementation creates the Graphical Browser, defines the BOM table, calls `sd-browser-set-active-table`, switches to table mode, then calls `sd-show-graphical-browser`.
- The unified-window implementation introduced a host dialog/grid hierarchy and the additional `sd-set-graphical-browser-parent` call. This path was not present in the known-good source and is the regression boundary.
- The Density collector and result-tree construction are retained from the known-good source.

### Rollback
Restored the complete LISP source to the exact known-good standalone-browser implementation from `3e9f3c1`. This intentionally prioritizes restoring the working results browser and manual row selection / Apply flow over the unverified single-window footer.

### Runtime verification
- Static source restored from the historical Git blob.
- User must reload this version and confirm the results browser opens again for a matching Assembly.
- Select All / Clear Selection visibility remains a separate unresolved enhancement; do not reintroduce browser-parent hosting until a Modeling 18.1-compatible method is proven.
