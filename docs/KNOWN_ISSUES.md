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

- **Status:** First Graphical Browser implementation candidate committed; pending Creo 18.1 load and functional verification.
- **Observed:** Previous approaches only produced Output messages and did not create an actionable result list.
- **Implemented candidate:** Dedicated Graphical Browser data tree with BrowserNode client data retaining the corresponding model Part; BOM-like columns for Part Name, Density Instance, Density Base, and Assembly Path; browser row selection; Select All and Clear Selection actions; exact Density pair filtering remains separate from result presentation.
- **Not yet verified:** Browser creation/update lifecycle, table display, row selection, and menu actions in Creo 18.1. Double-click navigation to the corresponding model object and transfer of selected result Parts to downstream commands such as Add to Drawlist remain required acceptance tests.
- **Risk:** Public PTC Integration Kit references available during development are for 20.x. The Graphical Browser framework predates these releases, but exact 18.1 signatures and behavior must be confirmed in the installed environment.


## KI-006 – Density Instance/Base inquiry may not be supported as used on Modeling 18.1

- **Status:** Investigating; awaiting isolated API test in Creo 18.1.
- **Observed behavior:** User confirms the Assembly contains Parts whose Part Properties show Density Instance = 1 and Density Base = 304, but the filter returns zero.
- **Numeric clarification:** In Common Lisp, numeric `=` treats `1` and `1.0` as equal. Numeric formatting alone is not a sufficient explanation.
- **API documentation finding:** PTC's current Integration Kit reference documents `sd-inq-part-density` with `:contents`, `:instance`, and `:realized` kinds. PTC's What's New material describes the instance/contents property-attribute extension in a later 20.x release; the 18.1 What's New section does not list that extension. The optional `:kind` form is therefore a compatibility suspect, but the one-argument legacy call also needs direct runtime testing.
- **Previous diagnostic limitation:** The selected object was reported as `ELAN::SEL_ITEM`, and its basename/path inquiries succeeded. Do not infer that this is an invalid object handle or attempt to unwrap it. The earlier helper's `IGNORE-ERRORS` / `FUNCALL` wrapper reported `ESCAPE` for all inquiries and did not isolate the failing API.
- **Invalid test instruction corrected (2026-11-14):** `SEL_ITEM-P` is undefined in the user's Modeling 18.1 environment. The User Input Line is also not a direct Lisp expression console; do not ask the user to paste Lisp expressions there.
- **New diagnostic:** `src/part-filter/H871_DENSITY_API_TEST.lsp` defines two separate selection dialogs. `H871_DENSITY_TEST_PART_P` directly tests `sd-inq-part-p`; `H871_DENSITY_TEST_ONE_ARG` directly tests the legacy one-argument `sd-inq-part-density`. Each writes a report to `H871_DENSITY_API_TEST.txt`. The direct calls intentionally avoid the previous generic error wrapper.
- **Verification:** GitHub source and development-log commits succeeded. Static syntax and Creo 18.1 load/run are pending. No runtime success is claimed.
- **Next action:** Load the new test file using the established H871 LISP loading method; launch each dialog through the Modeling command/menu mechanism (not the User Input Line); send the TXT report and any exact error message.
- **Do not close:** Until a known Part is read correctly and the Assembly search returns the expected Part set in Creo 18.1.
