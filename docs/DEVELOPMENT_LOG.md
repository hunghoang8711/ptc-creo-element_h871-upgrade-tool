

## 2026-11-14 – Consolidated lessons and current Part Filter status

### Confirmed by the user
- The Part Filter Results browser opens and displays Part names.
- Individual result rows can be selected.
- The runtime message `Odd number of arguments for keywords.` is gone after correcting both `sd-browser-set-status-text` calls to pass the message with `:value`.

### Current source implementation (not yet user-verified)
- The latest source adds Select All and Clear Selection entries to both the browser button menu and top menu, routed to `h871-pf-select-all` and `h871-pf-clear-selection`.
- The latest source sets `:buttonMenuOffObjectOnly nil` in an attempt to make the button menu available beyond blank-space context clicks.
- The result browser maximum width is 900; column widths are Part Name 28, Density Instance 13, Density Base 12, Assembly Path 42. PTC Graphical Browser `:initial-width` values are character counts, not pixels.
- The filter input dialog calls `sd-return-from-ok-action` after a search so Assembly and both Density inputs can be reused for another exact-pair search. Each search recreates the results browser/tree; the results window is intended to remain separately closable.

### Lessons learned
1. A function accepting keyword arguments must be called with the documented keyword/value pairs; a positional message string can trigger `Odd number of arguments for keywords.`
2. A successful LISP load and a visible result table do not prove every browser menu/control is exposed. Treat menu declarations as implementation attempts until the user confirms the control is actually visible and works in Modeling 18.1.
3. Check the unit used by UI sizing parameters before choosing values. Here, `:initial-width` is in characters; treating it like pixels created excessively wide columns.
4. Keep the data-search dialog separate from the results browser. This supports repeated searches without losing the input values, while allowing each result set to be closed independently.
5. Record three separate verification levels: static source checks, API documentation/compatibility assumptions, and user-confirmed Creo runtime behavior.

### Next runtime checks
- Confirm Select All is visibly accessible and selects every displayed row; confirm Clear Selection reverses it.
- Confirm Part Name, Density Instance, and Density Base are visible together without excessive horizontal scrolling.
- Confirm the input dialog remains available after a search and can run a second Density pair; confirm the result browser can be closed independently.
- Do not mark these UI refinements as runtime-passed until the user reports the result.


## 2026-11-14 – Make Select All a persistent browser action row

### Reason for follow-up
The user confirmed the result columns are now compact and multi-row selection followed by Apply works, but no Select All control is visible. The previous source placed Select All in `:buttonMenu` and `:topMenu`; this did not produce a clearly visible always-available control in the user's Creo 18.1 UI.

### Source change
- Added a dedicated `:modeMenu` row labelled "Selection" with persistent "Select All" and "Clear Selection" action buttons.
- The buttons call the documented browser commands directly: `:select-all` and `:clear-select-list`.
- Kept the top-menu popup as a right-click fallback, using the documented `:browser-push-cmd` form for native browser commands.
- Preserved the existing result table, compact column widths, multi-row selection, and Apply workflow.

### API evidence and compatibility boundary
PTC Graphical Browser reference describes `:modeMenu` as a row of buttons displayed above the `:buttonMenu`, and its examples use browser commands for Select All. The reference is for a later Integration Kit release than the user's 18.1 installation; this is a targeted compatibility attempt, not proof until tested in Creo 18.1.

### Runtime verification required
Reload the updated LISP and confirm a visible "Selection" row with "Select All" and "Clear Selection". Verify Select All highlights every result row and that Apply then operates on the complete selection. Also verify manual multi-row selection still works.


## 2026-11-14 – Correct 18.1 browser sizing and move selection controls to UICT

### Evidence from the user's latest screenshot
- The Select All control is still absent from the Graphical Browser.
- The first column still occupies most of the window; Density columns are pushed beyond the visible area.

### Important compatibility correction
- The earlier note that Graphical Browser `:initial-width` is measured in characters was incorrect for the later Browser Views API and is not the right setting to assume for Modeling 18.1.
- PTC's 20.4 release notes explicitly state that `:sd-browser-define-table` changed the legacy column option `:max-width` to `:initial-width` in that later release. For the user's 18.1 target, use the legacy `:max-width` form instead.
- The source now sets Part Name / Density Instance / Density Base / Assembly Path max widths to 22 / 8 / 8 / 30. These are target values to validate visually in 18.1, not a confirmed final layout.

### Select All redesign
- Removed reliance on the unverified `:modeMenu` action row.
- Added a separate compact UI Construction Toolkit dialog with real Pushbutton controls for Select All and Clear Selection. The button callbacks call the same native Graphical Browser commands already used by the working manual selection / Apply workflow.
- Retained the browser popup menu as a fallback.
- UICT Pushbutton and dialog-shell API signatures are documented by PTC in later Integration Kit references; availability and exact compatibility in the user's 18.1 installation still require runtime testing.

### Next runtime test
Reload the latest source and verify:
1. A small separate "H871 - SELECTION TOOLS" window appears beside the results browser.
2. Select All highlights every result row; Apply then acts on all selected Parts.
3. Clear Selection removes all row highlights.
4. Part Name, Density Instance, and Density Base columns are visible without excessive horizontal scrolling.
5. Manual multi-row selection remains functional.

Do not mark the new controls or widths as runtime-passed until the user confirms them.


## 2026-11-14 – Unify Part Filter result browser and action footer

### User requirement
The user confirmed the Select All / Clear Selection controls appeared in a second window. They requested one results window with a single bottom row ordered: Apply, Select All, Clear Selection, Close. Select All must immediately perform the same selection hand-off as Apply, without requiring a second Apply click.

### Source implementation
- Removed the separate Selection Tools dialog.
- Added a resizable host dialog shell and resizable browser area.
- Embedded the Graphical Browser in the host using `sd-set-graphical-browser-parent`.
- Added four UICT Pushbuttons to the host shell footer in the requested order.
- Set the Graphical Browser's own OK/Abort labels to empty so the host shell supplies the visible Apply and Close controls.
- Apply calls native `:select-and-execute`.
- Select All calls native `:select-all` followed immediately by `:select-and-execute`, then hides the host shell.
- Clear Selection calls native `:clear-select-list` without applying.
- Close hides the embedded browser and host shell.

### API compatibility boundary
PTC's later Integration Kit documentation describes `sd-set-graphical-browser-parent` as hosting a Graphical Browser inside a resizable grid area that is a descendant of a resizable dialog shell. It also documents UICT Pushbuttons as controls inside a grid area. These references establish the intended architecture, but are later than the user's Modeling 18.1 installation. The source checks for the required functions and displays a clear error if the host API is unavailable. Creo 18.1 runtime validation is still required.

### Static validation
- Parenthesis balance: 0
- Minimum parenthesis depth: 0
- Unterminated strings: none
- Old separate Selection Tools dialog removed.
- Footer button declarations and Select All -> Select-and-Execute sequence present.

### Runtime test required
Confirm the results table and all four buttons appear in one window; verify Apply, Select All immediate hand-off, Clear Selection, Close, and the existing manual multi-row selection behavior. Do not mark runtime passed until user confirmation.


## 2026-11-14 – Diagnose Graphical Browser parent failure

### User runtime result
The user tested the unified host-window implementation and received:
`H871: Could not embed the results browser in its host window.`

### Investigation
- The failure is the NIL return from `sd-set-graphical-browser-parent`; the earlier UI creation steps did not report failure.
- PTC's What's New documentation places `sd-create-resizable-dialog-shell`, `sd-create-resizable-grid-area`, `sd-set-control-binding`, and `sd-set-graphical-browser-parent` in historical CoCreate Modeling 2008 additions, so it is incorrect to claim these functions were first introduced in 20.7/20.8. They are plausible APIs for the 18.1 lineage.
- PTC documents that the browser parent must be a resizable grid area descending from the specified resizable dialog shell; dialog is the shell basename without `-DS`.
- The source currently follows that intended structure, but actual object existence, browser docked state, and hierarchy are not yet known from the user's generic error.

### Diagnostic update
- Added `h871-pf-parent-diagnostic`, called automatically after embedding fails.
- The diagnostic reports browser existence, docked state, dialog shell existence, root host grid existence, and nested browser-parent grid existence.
- Diagnostic state is captured before destroying the host shell.
- This is an information-gathering patch only; it does not claim to fix embedding.

### Next test
Load the latest source and run the same search once. Send the complete `H871 EMBED DIAGNOSTIC` message. Use those exact flags to identify whether the failure is due to a missing UI object or browser docking/parent state before changing the parenting call.


## 2026-11-14 – Fix missing root grid area in unified results dialog

### Root cause confirmed by source inspection
The previous implementation created the dialog shell, whose client area is automatically named `H871-PF-RESULTS-AA`, but attempted to create `H871-PF-BROWSER-RG` with `H871-PF-RESULTS-RG` as its parent before creating that parent. Therefore the required UI hierarchy was incomplete, explaining the browser-parent failure.

### Corrected hierarchy
- Dialog shell: `H871-PF-RESULTS-DS`
- Automatic client area: `H871-PF-RESULTS-AA`
- Root resizable grid area: `H871-PF-RESULTS-RG`, parent = `H871-PF-RESULTS-AA`
- Browser resizable grid area: `H871-PF-BROWSER-RG`, parent = `H871-PF-RESULTS-RG`
- Footer Pushbuttons remain children of the root resizable grid area.
- Graphical Browser parent remains `H871-PF-BROWSER-RG`, dialog basename remains `H871-PF-RESULTS`.

### Verification
- Source structure statically checked after patch.
- This corrects a definite parent/child construction error. Runtime embedding still needs confirmation in Modeling 18.1.


## 2026-11-14 – Isolate unified results-window creation failure

### Latest user runtime result
The user reports that searches with no matching Parts still display the normal "not found" message, but searches with matching Parts now stop with:
`H871: Could not create the unified results window.`

This places the failure after the filter has found matches and entered the results UI creation path. It does not prove the density filter is failing.

### Diagnostic source change
- Replaced the single generic host-window failure with stage-specific errors.
- The next Creo run will identify one of these stages:
  1. API availability check
  2. Create dialog shell
  3. Create root grid under the automatic `-AA` client area
  4. Create browser child grid
  5. Create Apply button
  6. Create Select All button
  7. Create Clear Selection button
  8. Create Close button
- Removed the duplicate generic error so the user sees the exact failing stage.
- No speculative change was made to the Density matching algorithm or browser-parent API.

### Static validation and runtime boundary
- Parenthesis balance: 0.
- This patch improves fault localization only; it does not claim the host window is fixed.
- Runtime verification is pending the exact stage message from Creo 18.1.

 
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

 
## 2026-11-14 – Restore standalone Select All tool without browser embedding

### User-confirmed baseline
The user confirms the Part Filter LISP and standalone Results Browser are working normally again after rollback. Preserve the standalone Graphical Browser architecture and its manual row selection / Apply workflow.

### Source change
- Added a compact separate UICT dialog titled **H871 - SELECTION TOOLS** with one **Select All** pushbutton.
- Reused the previously tested UICT pattern from source revision `c06f5b8` (`sd-create-dialog-shell`, `sd-append-grid-area`, and `sd-create-pushbutton-control`).
- The button calls the existing `h871-pf-select-all` callback, which issues the native Graphical Browser `:select-all` command.
- Removed Clear Selection controls and callback as requested.
- The standalone Graphical Browser is still created and shown by its existing `sd-show-graphical-browser` path. No `sd-set-graphical-browser-parent`, host shell, or browser embedding was reintroduced.

### Static validation
- LISP parenthesis balance: 0; no negative depth; strings closed.
- Confirmed only the Select All pushbutton remains in the UICT selection-tools window.
- Confirmed browser-parent embedding API is absent.
- Commit: `e8c818a38592134a47550b879e66a18349e48ccb`.

### Runtime verification required
Reload the latest source in Creo Elements/Direct Modeling 18.1 and verify:
1. The Results Browser still opens for an Assembly with matches.
2. The small Selection Tools window appears with one Select All button.
3. Select All highlights every result row.
4. The existing Apply hand-off works with all rows selected.
5. Manual row selection and Ctrl-click multi-selection remain unchanged.

The source is statically checked but the new Select All button has not yet been re-tested by the user in Creo 18.1.
