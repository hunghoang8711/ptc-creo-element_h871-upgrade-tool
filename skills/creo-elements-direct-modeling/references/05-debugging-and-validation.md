# 05 – Debugging and Validation Playbook

## Error-first debugging
When the user reports an error:
1. Preserve the exact error text, including capitalization and punctuation.
2. Record the exact command/file/version and the action that triggers it.
3. Determine whether the error is load-time, command dispatch, API call, UI construction, selection, or post-action lifecycle.
4. Reproduce the smallest failing operation; avoid rewriting multiple layers at once.
5. Check whether the symbol exists in the target Modeling 18.1 environment.
6. Verify argument count, keyword/value pairs, object type and current edit context.
7. Make one minimal correction, static-check, then return exact user test steps.
8. Update this playbook only when the cause/fix is supported by evidence.

## Known failures and fixes

### Undefined HANDLER-CASE
- Seen when loading/running an early Lisp diagnostic.
- Conclusion: do not assume ANSI Common Lisp condition-handling constructs are available in this Modeling 18.1 environment.
- Action: use only error-handling constructs documented/verified for this Lisp runtime.

### Undefined SEL_ITEM-P
- Seen in multiple diagnostic tests.
- Conclusion: this predicate is not available under that name in the user's environment.
- Action: do not use it; inspect supported object predicates and use verified `sd-inq-part-p` where appropriate.

### Density API one-argument test
- On 2026-11-14, the user tested a selected part `010-plate_2.1.1.2.1`.
- `sd-inq-part-p` and `sd-inq-part-density` were defined.
- `(sd-inq-part-density part)` returned `1000.0` as `LONG-FLOAT`.
- This is a narrow test result, not proof of every optional mode keyword or all Part types.

### Odd number of arguments for keywords
- Cause in working Part Filter: status text setter omitted the `:value` keyword.
- Confirmed pattern:
```lisp
(sd-browser-set-status-text browser-name :value "Status message")
```

### Results Browser selection stopped working
- Cause: custom Apply callback replaced native default Apply; callback also reopened the browser after selection hand-off.
- Fix: remove custom callback and retain native Apply. User confirmed individual row selection and Apply worked again.

### Browser host-shell embedding failures
- Errors: “Could not embed the results browser in its host window” and “Could not create the unified results window.”
- Fix: return to standalone Graphical Browser.
- Do not retry browser reparenting without a new, documented 18.1-supported mechanism.

### UICT tab control uncertainty
- Later PTC docs mention `sd-create-dialog-shell`, `sd-create-tab-control`, `sd-insert-tab-control-page`, and `sd-create-display-table-control`.
- This is a research direction only. Confirm function presence and signatures in 18.1. Prove actual Part row selection and Apply-to-Modeling before integrating.

## Static checks
Static checks may include:
- balanced parentheses/brackets;
- strings and comments not accidentally terminating forms;
- matching defun/dialog names;
- defined helper references within the source;
- exact command names and file paths;
- no duplicate command registrations;
- no unintentional modifications to baseline versions.

Static checks cannot establish:
- that a function exists in Modeling 18.1;
- that a UI control is supported;
- that selection/Apply works;
- that an API returns expected units or object types;
- that the macro is safe on a real customer assembly/drawing.

## Runtime regression checklist
For Part Filter:
- load exact file;
- select assembly;
- test matching and no-match pairs;
- verify row list;
- select one row;
- select multiple rows;
- Select All;
- native Apply;
- confirm only intended Parts selected;
- test a repeated search and verify browser lifecycle.

For Annotation sheet/frame tools:
- create a sheet using built-in frame;
- load a custom MI frame;
- create multiple sheets with different frame variants;
- replace a frame and verify centering/content preservation;
- save/reopen and check persistence;
- verify built-in frame list remains intact.

For drawing arrangement:
- test with 1, 2, and many sheets/views;
- check current edit part restored;
- check no overlap and expected spacing;
- test non-default model units;
- test error cleanup of temporary LTABs.

For BOM layouts:
- load one head, component and flag layout;
- verify scale preservation;
- edit/accept/discard;
- confirm stored layout persists and temporary parts/sheets are cleaned up.
