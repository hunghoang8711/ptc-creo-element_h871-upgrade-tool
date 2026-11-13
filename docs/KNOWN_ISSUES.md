# Known Issues

Track confirmed defects and unresolved investigations. Close an issue only after the fix is verified at the appropriate level.

## KI-001 – Part filter returns values that do not match the intended exact pair

- **Status:** First implementation added; pending in-Creo functional verification.
- **Area:** Part property filter / Material tab – Density.
- **Reported behavior:** The filter UI and options appeared, but the values returned by filtering were not as intended.
- **Expected behavior:** Match Parts using the exact Instance and Base values entered by the user. Both fields must match.
- **Implementation:** `src/part-filter/H871_PART_FILTER.lsp` now compares Density Instance and Density Base as an exact pair.
- **Next action:** Load in Creo 18.1 and compare results against known Parts, including the screenshot pair (1, 304).
- **Closure criteria:** Verified expected and actual matching Part sets in Creo Elements/Direct Modeling 18.1.

## KI-002 – Diagnostic LISP file reports unexpected end of input

- **Status:** Historical error; imported revision passes static parenthesis/string balance check, but the historical error is not confirmed resolved in Creo.
- **Area:** `H871_PART_FILTER_DIAG.lsp`.
- **Reported message:** `Unexpected end of #<input stream "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER_DIAG.lsp">`.
- **Current blocker:** Exact failing file revision is not present in the repository.
- **Next action:** Import the exact file, inspect reader syntax and balanced forms, and reproduce in the target Creo version.
- **Closure criteria:** Corrected file loads successfully and its intended diagnostic behavior is verified.

## Issue entry template

### KI-XXX – Short title

- **Status:** Open / Investigating / Fixed – pending verification / Closed.
- **Area:**
- **Observed behavior:**
- **Expected behavior:**
- **Reproduction steps:**
- **Evidence / affected commit:**
- **Root cause:**
- **Fix:**
- **Verification:**
- **Closure criteria:**


## KI-003 – Native selection-list integration pending Creo 18.1 test

- **Status:** Implemented; pending functional verification.
- **Area:** Part filter / Creo native selector.
- **Expected behavior:** Exact Density Instance/Base matches become native selected Parts, usable by Add to Drawlist and other standard commands.
- **Implementation:** `GET_SELECTION` with Part focus, an exact-pair check function, and `:in_assembly`.
- **Risk:** PTC references reviewed are for later 20.x releases; actual 18.1 runtime behavior and selection-list persistence must be confirmed.
- **Next action:** Run the updated LISP in Creo 18.1 and report selected count, selection-list behavior, and Add to Drawlist result.


## KI-004 – Earlier GET_SELECTION implementation did not set Structure Browser selection

- **Status:** Superseded by Structure Browser node-selection implementation; pending Creo 18.1 verification.
- **Observed behavior:** User saw only Output messages and no rows selected in the Structure Browser.
- **Root cause:** The implementation relied on GET_SELECTION return values and incorrectly claimed those values were persisted as Structure Browser selections. PTC documents GET_SELECTION as a selector that returns SEL_ITEMs.
- **Fix:** Use `sd-browser-exec-cmd "parcel-gbrowser" :set-object-selection` on matching BrowserNode structs.
- **Next action:** Test updated source in Creo 18.1 and report matched/selected counts.


## KI-005 – Part Filter requires a dedicated result browser

- **Status:** Architecture agreed; implementation pending.
- **Observed:** User reports previous approaches still only produce Output messages and do not create an actionable result list.
- **Required fix:** Dedicated Graphical Browser with a BOM-like table, row selection, Select All/Clear Selection, double-click locate, and extensible property filters.
- **Research evidence:** PTC Graphical Browser documentation describes custom data trees, BrowserNode client data, tables, mouse click handlers, selection state, and browser commands. Standard Search results can navigate/highlight matching objects.
- **Risk:** Available online documentation is for later releases (20.4/20.8); exact APIs must be checked against installed Creo 18.1 Integration Kit. Do not commit speculative code.
