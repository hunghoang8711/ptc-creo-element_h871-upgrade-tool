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
