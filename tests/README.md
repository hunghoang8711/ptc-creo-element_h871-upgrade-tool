# Tests and Sample Data

Store sanitized test assets and repeatable test procedures here. Do not commit customer-confidential CAD data.

## Test record fields
- Test ID/date and Creo Elements/Direct Modeling version.
- Exact source path and Git commit.
- Sanitized model/setup and input values.
- Expected result, actual result, pass/fail and regression observations.
- Who observed the runtime result (user confirmation).

## ver-01 / ver-02 regression checklist
1. Load the intended version in Modeling 18.1.
2. Select an Assembly containing known matching Parts.
3. Search exact Density Instance + Density Base pair.
4. Confirm the Results Browser opens and lists expected Parts.
5. Select one row and confirm the corresponding Part is selected.
6. Select multiple rows and confirm selection is retained.
7. Use Select All and confirm all result rows are selected.
8. Press native Apply and confirm only selected Parts transfer to Modeling selection.
9. Search an Assembly with no matches and confirm the normal no-match message.
10. For ver-02, verify CNC/KH/CG/COVER and Material mapping values, display-only code fields and default CNC + SUS304 (1/304).

## ver-03 internal-tab prototype validation plan

Source: `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp`

1. Load the file in Creo Elements/Direct Modeling 18.1 and confirm no LOAD-time errors.
2. Run `H871_PART_FILTER_VER_03` and search CNC + SUS304.
   - Expected: one Results window with internal tab `SUS304-CNC`.
3. Search KH + A6061.
   - Expected: tab `A6061-KH` appears inside the same Results window.
4. Search CNC + SUS304 again.
   - Expected: existing `SUS304-CNC` page refreshes; no duplicate tab.
5. Switch pages; verify each page's result list is isolated.
6. Select individual/multiple rows; verify selected count is page-specific.
7. Use Select All and Clear Selection on each page.
8. Run a no-match search; verify existing valid pages/results remain unchanged.
9. Record exact runtime errors and the action that caused them.

**Not yet in this prototype:** Apply to Modeling selection. Do not mark that acceptance item as passed or use ver-03 for production selection until a Modeling 18.1 hand-off is implemented and tested.

## ver-03 production acceptance (future gate)
1. Confirm a verified Modeling 18.1 method to transfer the selected real Part objects from the active UICT page to Modeling selection.
2. Add Apply only after that method is demonstrated.
3. Confirm Apply transfers only the active page's selected Parts.
4. Repeat the ver-01/ver-02 row selection and native Apply regression tests.

No automated Creo runtime harness or sanitized CAD fixture is currently committed. Never describe source/static review as a runtime test.
