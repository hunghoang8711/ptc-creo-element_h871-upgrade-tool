# Tests and Sample Data

Store non-confidential test assets and repeatable test instructions here.

## Suggested structure

```text
tests/
├── README.md
├── lisp/
│   └── syntax and command-level test notes
├── fixtures/
│   └── sanitized sample models or property datasets
└── test-cases/
    └── feature-specific expected results
```

## Test record requirements

For each test, record:
- Test ID and date.
- Creo Elements/Direct Modeling version.
- Source commit or file revision.
- Model/setup used (sanitized).
- Input values and selected objects.
- Expected result.
- Actual result.
- Pass/fail and notes.

Never use customer-confidential CAD data as a public test fixture. Replace it with a minimal synthetic model that preserves only the properties needed for the test.

No test fixtures have been committed yet.
