# VER-06 implementation log — Standalone Structure Browser shell

## 2026-11-17 — Reset from known-good VER-02

### Decision
- Preserve VER-04/05/06 failures as project lessons; do not use their implementation as the new base.
- Start from `feature/part-filter-ver-02`, whose native Graphical Browser selection and Apply workflow was previously user-confirmed.
- New branch: `rebuild/ver06-structure-browser-shell`.

### Implemented
- Added `src/part-filter/ver-06/H871_PART_FILTER_VER_06_STRUCTURE_BROWSER.lsp`.
- Namespaced the VER-02 implementation under `h871-pf-v06-*` to avoid collisions with earlier loaded versions.
- Preserved exact Density Instance + Density Base filtering, result tree callbacks, BOM columns, native Apply, Select All and Clear Selection.
- Changed Browser sizing request to `:maxWidth 1200`, `:maxHeight 900`.
- Added `:createAsTab nil` to request a floating Browser window. `:tabname "H871 Results"` is retained as the Browser's tab label if PDS/session preferences cause docked placement.

### Static checks
- Parenthesis balance: 0.
- No negative parenthesis depth.
- No unterminated string.
- No un-namespaced `h871-pf` function/global references detected.
- Native `:okButtonLabel "Apply"` retained.
- Static checks do not establish Modeling 18.1 runtime compatibility.

### PTC API evidence / caveat
PTC Graphical Browser reference for Modeling 20.6 documents `:createAsTab` as a Boolean that requests initially docked vs floating placement. The same reference explicitly says the value can be overwritten by a preference stored in PDS from the previous Modeling session. Thus the user's runtime observation is required; do not assume `:createAsTab nil` guarantees floating placement.

Reference: https://support.ptc.com/help/creo_elements_direct/r20.6.0.0/advanced_documentation/integration_kit/reference/gbrowser.html

### Not yet implemented
- Editable notes panel and persistent note storage.
- Multiple filter-pair tabs inside this single Browser.
- Interactive resizing verification.
- Custom Apply or secondary Browser.

### Next runtime gate
Use a disposable Assembly copy. Verify one floating Results Browser, all four table columns, individual selection, native Apply, Select All, Clear Selection, and one close/reopen cycle. If a model-data warning or fatal exception occurs, stop and capture the trace. Only after this gate passes should we implement the notes interface and multi-result navigation.
