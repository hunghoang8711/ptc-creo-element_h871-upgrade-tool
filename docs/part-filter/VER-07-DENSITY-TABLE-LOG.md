# VER-07 implementation log — Density result table initialization

## 2026-11-17

### User observation
The standalone Results Browser is working independently and Part selection behaves as intended, but the Density information columns are missing from the visible Results view.

### Source review
Compared VER-06 against the known-good VER-02 source. Both already defined four custom columns (Part Name, Density Instance, Density Base, Assembly Path), and both stored normalized Density Instance/Base values in each row's BrowserNode client data. The callback functions also return strings compatible with the declared `:string-column` types.

The significant initialization-order issue was that VER-06 called `sd-show-graphical-browser` before `sd-browser-exec-cmd :change-table-root`. PTC's Graphical Browser documentation says the table is populated from the children of its selected table root. The root should therefore be assigned before the Browser is first shown.

### Implemented
- Created branch `feature/part-filter-ver-07-density-table` from the user-tested VER-06 branch.
- Added `src/part-filter/ver-07/H871_PART_FILTER_VER_07_DENSITY_TABLE.lsp`.
- Namespaced all functions and globals as `h871-pf-v07-*`.
- Reordered initialization: define table → activate table → resolve root BrowserNode → assign table root → set table mode → show Browser.
- Added explicit error handling if the root cannot be resolved, the table root cannot be assigned, or table mode cannot be activated.
- Preserved the density collector, normalization, native Browser row selection, native Apply, Select All, and Clear Selection.

### Static checks
- 439 lines / 16,994 characters.
- Parenthesis balance 0; no negative depth.
- No unterminated string.
- Both Density column definitions present.
- Root assignment occurs before Browser display.
- Native Apply and selection functions retained.
- All implementation symbols use the VER-07 namespace.

### Runtime status
Not tested in Creo 18.1 by the assistant. The user must confirm that both Density columns are visible and populated while native selection and Apply continue to work. Test on a disposable Assembly copy.
