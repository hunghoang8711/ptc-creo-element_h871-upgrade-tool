

## 2026-11-14 – Confirm Part predicate and isolate Density kind arguments

### User runtime evidence
- User ran `H871_DENSITY_TEST_PART_P` against the known Part `010-plate_2.1.1.2.1`.
- `sd-inq-part-p` returned `T` (type `SYMBOL`).
- Selected object type was `ELAN::SEL_ITEM`; its basename and full model path were returned correctly.
- User also previously ran `H871_DENSITY_TEST_ONE_ARG`: `(sd-inq-part-density part)` returned `1000.0` (type `LONG-FLOAT`).

### Conclusion
- `ELAN::SEL_ITEM` is accepted directly by both tested inquiry calls; it is not the cause of the zero-match issue.
- The known selected object is confirmed as a Part.
- The one-argument density value is the default/realized value and does not establish the separate Instance/Base values shown in Part Properties.
- The optional `:instance` and `:contents` calls remain unverified on Modeling 18.1.

### Files changed
- Added `src/part-filter/H871_DENSITY_KIND_TEST.lsp`.

### Implementation
- Added two separate dialog commands: `H871_DENSITY_TEST_INSTANCE` and `H871_DENSITY_TEST_CONTENTS`.
- Each dialog directly calls exactly one optional-kind form and writes to its own report (`H871_DENSITY_INSTANCE_TEST.txt` or `H871_DENSITY_CONTENTS_TEST.txt`).
- The report is flushed before the direct API call, so if the call signals an error the attempted expression and Part identity should still be recorded.
- No `FUNCALL`, `LAMBDA`, `IGNORE-ERRORS`, or generic safe-call wrapper is used around the tested inquiry.

### Verification
- GitHub file creation succeeded.
- Static source scan: parentheses balanced (0), no negative nesting, no unterminated strings.
- `sd-inq-part-p` runtime test: user-confirmed success.
- One-argument density runtime test: user-confirmed success.
- Optional `:instance` / `:contents` runtime tests: pending user execution.

### Next steps
1. Load `H871_DENSITY_KIND_TEST.lsp` using the established LISP loading method.
2. Run `H871_DENSITY_TEST_INSTANCE` on the same known Part and send `H871_DENSITY_INSTANCE_TEST.txt`.
3. Run `H871_DENSITY_TEST_CONTENTS` and send `H871_DENSITY_CONTENTS_TEST.txt`.
4. Only after these results, select the correct 18.1 data-access strategy and revise the production filter.
