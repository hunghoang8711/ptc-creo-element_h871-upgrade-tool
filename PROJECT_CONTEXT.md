

## 2026-11-14 – Confirmed native Density inquiry behavior (supersedes earlier pending-test notes)

### Native model scope
The user clarified that the working model is native Creo Elements/Direct Modeling data (`.pkg` or `.bdl`), not STEP. All Part/Assembly inquiry and traversal work must target the native model structure. Do not assume a STEP-import-specific attribute path.

### Confirmed Density calls on Part 010-plate_2.1.1.2.1
The user ran the direct LISP tests in Modeling 18.1 on the native Part:

| Inquiry | Runtime result | Part Properties display |
|---|---:|---:|
| `(sd-inq-part-density part :instance)` | `1000.0` | Instance = `1` |
| `(sd-inq-part-density part :contents)` | `304000.0` | Base = `304` |

Also confirmed: `(sd-inq-part-p part)` returns `T`; the selected object is `ELAN::SEL_ITEM` and is accepted directly by the inquiry calls.

Both API values are 1000 times the UI display values for this sample. This is an observed scale relationship, not yet a proven unit definition. Verify against another known Part before encoding a conversion factor in the production filter.

### Updated implementation status
- The optional `:instance` and `:contents` forms are confirmed supported in this user's Modeling 18.1 installation.
- The isolated API read is confirmed; the production Assembly traversal, exact-pair matching, BOM-like result list, double-click locate, and Add to Drawlist workflow remain unverified.
- Keep property acquisition, normalization, and exact-pair matching as separate functions so the scale rule can be changed safely after verification.
