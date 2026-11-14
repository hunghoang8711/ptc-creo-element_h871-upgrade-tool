

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
