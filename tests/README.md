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

## ver-03 internal-tab validation plan
1. Confirm exactly one separate Results Browser window is created.
2. Create first page for Density pair 1/304, caption `SUS304-CNC`.
3. Search pair 2/6061; confirm a second page appears in the same window, caption `A6061-KH`.
4. Search 1/304 again; confirm the existing page refreshes and no duplicate appears.
5. Switch pages; verify each page's result list remains isolated.
6. Verify row selection and Select All are page-specific.
7. Apply from one page; confirm only selected Parts from the active page transfer to Modeling selection.
8. Run a no-match search; verify existing valid pages remain intact.
9. Repeat baseline tests after every UI change.

No automated Creo runtime harness or sanitized CAD fixture is currently committed. Never describe source/static review as a runtime test.
