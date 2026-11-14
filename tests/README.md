# Tests and Sample Data

Store sanitized test assets and repeatable test procedures here.

## Test record

For each meaningful test, record:
- Test ID and date.
- Creo Elements/Direct Modeling version.
- Source commit or file revision.
- Sanitized model/setup and input values.
- Expected and actual results.
- Pass/fail status and any regression observations.

## Part Filter ver-02 dialog tests

Run these in Creo Elements/Direct Modeling 18.1 after loading `H871_PART_FILTER_VER_02.lsp`:

1. Confirm command `H871_PART_FILTER_VER_02` opens the dialog without LISP errors.
2. Confirm Assembly selection is unchanged.
3. Confirm default selections are CNC and SUS304.
4. Confirm displayed code fields initially show 1 and 304 (the standard dialog may place each code field on the row below its selector; same-row placement is not yet implemented).
5. Change Machining Process through CNC, KH, CG, COVER; verify code field shows 1, 2, 3, 4 respectively.
6. Change Material through all nine choices; verify code field shows 6061, 201, 304, 400, 10, 20, 30, 40, 50 respectively.
7. Attempt to edit each code field; confirm it is display-only.
8. Search CNC + SUS304 and compare result count/Parts against ver-01 numeric 1/304 on the same Assembly.
9. Test at least one other process/material combination and verify the expected numeric pair reaches the filter.
10. Confirm the input dialog remains available for a subsequent search.

## Part Filter regression checklist

After changing the filter engine or Results Browser, retest in Modeling 18.1:

1. Search an Assembly with known matching Parts.
2. Confirm the Results Browser opens and lists the expected Parts.
3. Select one row and confirm the corresponding Part is selected.
4. Select multiple rows and confirm the selection is retained.
5. Use Select All and confirm all result rows are selected.
6. Press native Apply and confirm the selected Parts transfer to Modeling selection.
7. Search an Assembly with no matches and confirm the normal no-match message.
8. If repeat-search behavior is changed, verify the input dialog and result-window lifecycle separately.

No sanitized automated fixture or repeatable model package is currently committed. The ver-01 baseline test evidence is the user's manual runtime confirmation dated 2026-11-14. ver-02 still requires runtime testing.

Never use customer-confidential CAD data as a public test fixture.
