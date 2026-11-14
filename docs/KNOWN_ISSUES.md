

## KI-006 – Density API values differ from Part Properties display scale

- **Status:** API calls confirmed; value normalization semantics still under investigation.
- **Native test object:** Part `010-plate_2.1.1.2.1` in the user's native Creo Elements/Direct model (`.pkg` / `.bdl`), not STEP-imported geometry.
- **Part predicate:** `(sd-inq-part-p part)` returns `T`.
- **Instance inquiry:** `(sd-inq-part-density part :instance)` returns `1000.0` (`LONG-FLOAT`).
- **Contents/Base inquiry:** `(sd-inq-part-density part :contents)` returns `304000.0` (`LONG-FLOAT`).
- **Part Properties display:** Instance = `1`, Base = `304`.
- **Observed relationship:** both returned API values are 1000 times the corresponding UI values on this Part.
- **Interpretation:** optional kind arguments are supported in this Modeling 18.1 installation, and the two calls expose the intended separate fields. The unit/conversion reason for the factor is not yet proven.
- **Risk:** comparing raw API values directly against user-entered UI values (1 and 304) will not match. Do not apply an unverified global conversion factor until another known Part or authoritative 18.1 documentation confirms it.
- **Native data constraint:** all development and tests must use native Creo Elements/Direct `.pkg` / `.bdl` model content. Do not assume a STEP import data path.
- **Next action:** verify the scale on another known Part, then normalize values in a dedicated reusable function before exact-pair comparison.
- **Production filter status:** a successful isolated inquiry is not proof that the complete Assembly scan or result UI works. Keep full runtime status separate.



## KI-006 update – 1000:1 Density scale confirmed on a second native Part

- **Second test Part:** `010-plate_2.1.1.2.1.1`.
- **Part Properties:** Instance = `2`, Base = `400`.
- **API results:** `:instance` = `2000.0`; `:contents` = `400000.0`.
- **Combined evidence:** first Part UI 1/304 maps to API 1000/304000; second Part UI 2/400 maps to API 2000/400000. Both independently establish a 1000:1 scale relationship for both fields.
- **Status:** empirically confirmed on two native Parts. The source now normalizes API values by dividing by 1000.0 before exact matching and displays normalized values in the result table/report while retaining raw values in diagnostics.
- **Remaining risk:** complete Assembly scan and Graphical Browser runtime behavior have not yet been tested. This code update must not be described as a successful end-to-end filter test.


## 2026-11-14 — LISP load failure: invalid character literals
- Symptom: `Octal digit expected`, followed by `misplaced right parenthesis`.
- Cause found in `h871-pf-as-number`: character literals had two actual backslashes before `Space`, `Tab`, and `Newline`.
- Fixed to standard Common Lisp character syntax. Runtime verification in Creo 18.1 is pending.


## 2026-11-14 — Reader error remains under investigation
- The previous character-literal correction did not resolve the user's reported load error.
- Removed the entire reader-dependent string-to-number parser. `h871-pf-as-number` now accepts numeric values only, matching the dialog and Density API types used by this tool.
- Next diagnostic is to confirm the exact local file path/version being loaded and isolate whether the error occurs during file load or command execution.


## 2026-11-14 – Part Filter keyword argument error

- **User symptom:** result table is displayed and individual rows can be selected, but running the filter still displays `Odd number of arguments for keywords.`
- **Likely cause found:** the current source called `sd-browser-set-status-text` with the browser name and status string as positional arguments. The PTC Graphical Browser reference specifies the status text using `:value`.
- **Source correction:** both status-bar updates now pass `:value <string>`.
- **Related UI changes:** added toolbar buttons for Select All and Clear Selection; kept the Assembly and Density input dialog active after a search using `sd-return-from-ok-action`.
- **Runtime status:** pending user test in Modeling 18.1. The API reference consulted is for a later Integration Kit release; compatibility of the added toolbar/deferred-dialog behavior must be confirmed in the user's 18.1 installation.


## 2026-11-14 – Result browser Select All visibility and oversized columns

- **User-confirmed:** the earlier keyword-argument error is gone.
- **Remaining symptom:** no visible Select All action in the Part Filter Results browser; Instance and Base columns are positioned too far to the right.
- **Cause of oversized columns:** PTC Graphical Browser `:initial-width` is measured in character counts, not pixels. The previous widths (190 / 110 / 100 / 360) were therefore excessive.
- **Source update:** reduced widths to 28 / 13 / 12 / 42 characters for Part Name / Density Instance / Density Base / Assembly Path, and reduced browser max width to 900.
- **Selection controls:** changed the button-menu callbacks to named functions and set `:buttonMenuOffObjectOnly nil` to avoid limiting menu visibility to blank-space clicks.
- **Pending:** verify the actual toolbar/button visibility and Select All behavior in Creo 18.1. If the button row is still not visible, implement a separate always-visible control in a supported browser UI surface rather than relying on the compatibility menu mapping.
