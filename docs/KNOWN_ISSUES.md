# Known Issues

Track confirmed defects and unresolved investigations. Close an issue only after the fix is verified at the appropriate level.

## KI-001 – Part filter returns values that do not match the intended exact pair

- **Status:** Historical report; current reproducibility unknown.
- **Area:** Part property filter / Material.
- **Reported behavior:** The filter UI and options appeared, but the values returned by filtering were not as intended.
- **Expected behavior:** Match Parts using the exact Instance and Base values entered by the user. Both fields must match.
- **Current blocker:** The current LISP source and test model are not yet in the repository.
- **Next action:** Import source, inspect property access and filtering logic, then reproduce with a controlled model.
- **Closure criteria:** Verified expected and actual matching Part sets in Creo Elements/Direct Modeling 18.1.

## KI-002 – Diagnostic LISP file reports unexpected end of input

- **Status:** Historical error; not yet reproduced.
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
