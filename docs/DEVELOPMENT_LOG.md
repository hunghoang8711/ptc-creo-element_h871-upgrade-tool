

## 2026-11-14 – Density :instance and :contents confirmed on native model

### User runtime evidence
Tested on the native Creo Elements/Direct model Part `010-plate_2.1.1.2.1` (not a STEP-imported object):
- `(sd-inq-part-p part)` returned `T`.
- `(sd-inq-part-density part :instance)` returned `1000.0` (`LONG-FLOAT`).
- `(sd-inq-part-density part :contents)` returned `304000.0` (`LONG-FLOAT`).
- The same Part Properties fields are displayed to the user as Instance = `1` and Base = `304`.
- Both API values are exactly 1000 times the corresponding displayed values for this test Part.

### Conclusions
- Modeling 18.1 accepts both optional kind arguments in the user's environment.
- The direct API path correctly distinguishes the Instance and Contents/Base values; the earlier assumption that these optional arguments might be unsupported is disproven for this installation.
- The selected object remains a valid `ELAN::SEL_ITEM` input; no unwrapping is needed for these calls.
- The observed factor of 1000 is recorded as a measured relationship only. Its unit/conversion semantics are not yet independently established; do not hard-code a conversion without a further check against additional Parts or authoritative 18.1 unit documentation.

### Native model scope
The user clarified that the source model is native Creo Elements/Direct Modeling data (`.pkg` or `.bdl`), not STEP. All subsequent tests and implementation assumptions must target Parts and Assemblies in this native model structure. Do not build a STEP-import-specific attribute path.

### Next steps
1. Verify the 1000 factor against at least one more Part with known Instance and Base values, ideally including a zero/decimal or different density pair.
2. Inspect the current production filter and change only the value normalization/matching path once the scale convention is established.
3. Then run a full Assembly scan and compare the match list against the known Part path.
4. Continue toward the BOM-like result browser only after the core scan returns correct exact-pair matches.

### Verification status
- User-confirmed runtime success for Part predicate, `:instance`, and `:contents` calls on the native model.
- No claim yet that the production Assembly scan, result browser, double-click locate, or Add to Drawlist workflow has passed runtime testing.



## 2026-11-14 – Second native Part confirms Density scale; filter normalized

### Additional user runtime evidence
A second native Part was tested: `010-plate_2.1.1.2.1.1`.
- Part Properties: Density Instance = `2`, Density Base = `400`.
- `(sd-inq-part-density part :instance)` returned `2000.0`.
- `(sd-inq-part-density part :contents)` returned `400000.0`.
- Both calls returned `LONG-FLOAT`; `sd-inq-part-p` returned `T`.

Together with the first known Part (UI 1/304; API 1000/304000), this confirms the same exact 1000:1 ratio on two independent native Parts with different values.

### Source update
Updated `src/part-filter/H871_PART_FILTER.lsp`:
- Added `h871-pf-density-display-value`, which divides numeric API Density values by 1000.0.
- Exact-pair matching now compares normalized values against the dialog inputs.
- Result-table Density columns now display normalized values matching Part Properties.
- The result report includes both normalized display-scale values and raw API values for diagnosis.
- Diagnostic samples continue to preserve raw API values and their Lisp types.

### Verification status
- Source change committed to GitHub; this is not yet a Creo runtime test.
- Static source inspection is still required after this edit.
- The complete Assembly traversal, result count, Graphical Browser creation, and row-selection interactions remain unverified in Creo 18.1.
- Treat 1000 as an empirically confirmed conversion for the two tested Parts; if later testing reveals mixed units or exceptional values, isolate any adjustment in the normalization helper.
