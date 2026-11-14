

## KI-006 – Density Instance/Base inquiry may not be supported as used on Modeling 18.1

- **Status:** Investigating; direct optional-kind tests prepared, awaiting user execution.
- **Confirmed user runtime evidence:** On the known Part `010-plate_2.1.1.2.1`, `(sd-inq-part-p part)` returned `T` (type `SYMBOL`). The object type was `ELAN::SEL_ITEM`. The legacy one-argument `(sd-inq-part-density part)` returned `1000.0` (type `LONG-FLOAT`).
- **Conclusion:** The selected object is a valid Part handle for these calls. Do not unwrap `SEL_ITEM` or treat it as the root cause. The one-argument value is the default/realized density, not proof of Instance=1 or Base=304.
- **Still unknown:** Whether Modeling 18.1 accepts `(sd-inq-part-density part :instance)` and `(sd-inq-part-density part :contents)`, and whether they return the two Part Properties values.
- **New test file:** `src/part-filter/H871_DENSITY_KIND_TEST.lsp` defines separate commands `H871_DENSITY_TEST_INSTANCE` and `H871_DENSITY_TEST_CONTENTS`. Each command makes a direct call and writes to its own TXT report. No generic error-catching wrapper is used.
- **Static verification:** Balanced parentheses, no negative nesting, no unterminated strings.
- **Next action:** User loads the new file and runs both dialogs on the same known Part, then shares both report files or exact Creo error messages.
- **Do not change production matching logic yet:** Wait until the two direct tests establish the 18.1 API behavior and the actual values.
