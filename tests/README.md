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

## ver-03.1 multi-column Display Table and Apply validation

Source: `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp`

1. Load the file in Creo Elements/Direct Modeling 18.1 and confirm no LOAD-time errors.
2. Run `H871_PART_FILTER_VER_03` and search CNC + SUS304.
   - Expected: one Results window with internal tab `SUS304-CNC`.
   - Expected: four visible columns: Part Name, Density Instance, Density Base, Assembly Path.
3. Search KH + A6061.
   - Expected: tab `A6061-KH` appears inside the same Results window.
4. Search CNC + SUS304 again.
   - Expected: existing `SUS304-CNC` page refreshes; no duplicate tab.
5. Click one row; status should show 1 selected.
6. Ctrl-click/Shift-click more rows; verify multi-row selection.
7. Use Select All; all rows in the active tab should be selected.
8. Use Clear Selection; only the active tab should clear.
9. Select a subset and press Apply; verify only those actual Parts transfer to Modeling selection.
10. Switch tabs; verify selection is independent per page.
11. Refresh a pair; its result data should update and stale selection should clear.
12. Run a no-match search; existing valid tabs/results should remain unchanged.
13. Record exact runtime errors, action and whether the temporary Apply bridge appeared.

## ver-03 compatibility boundary

- PTC Display Table and logical-table APIs are documented in the 20.7 Integration Kit; exact Modeling 18.1 availability/signatures remain unverified.
- The ver-02 Graphical Browser selection-and-execute pattern is user-confirmed. The new hidden bridge from Display Table-selected Part objects to temporary BrowserNodes has not been runtime-tested in 18.1.
- Do not mark ver-03.1 production-ready until the table, multi-row selection and Apply tests above pass.
- ver-01/ver-02 remain the known-good fallback and must not be overwritten.

No automated Creo runtime harness or sanitized CAD fixture is currently committed. Never describe source/static review as a runtime test.


## ver-03.2 logical-table recovery regression

1. Load the updated ver-03 source over an existing Modeling session that may contain old ver-03 page state.
2. Run the mapped Process/Material dialog and press OK.
3. Expected: no empty logical-table name error; refresh succeeds or reports the concrete non-empty table identifier.
4. Repeat the same Density pair to exercise in-place refresh.
5. Start a fresh Modeling session and repeat the search to verify first-page creation remains valid.
6. If it fails, capture the full new error text; it should now identify the specific table name or control restoration stage.
