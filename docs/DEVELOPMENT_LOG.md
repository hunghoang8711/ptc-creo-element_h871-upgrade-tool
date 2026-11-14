

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
