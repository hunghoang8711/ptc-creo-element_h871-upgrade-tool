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

No sanitized automated fixture or repeatable model package is currently committed. The current baseline test evidence is the user's manual runtime confirmation dated 2026-11-14.

Never use customer-confidential CAD data as a public test fixture.
