

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



## 2026-11-14 – Density scale verified on two Parts; normalization added

A second native Part `010-plate_2.1.1.2.1.1` was tested. Its Part Properties values are Instance = `2`, Base = `400`; API inquiries returned `2000.0` for `:instance` and `400000.0` for `:contents`. Combined with the first Part (UI 1/304; API 1000/304000), both fields show a consistent API-to-display factor of 1000 across two different native Parts.

The production filter source now has a dedicated normalization helper that divides numeric API Density values by 1000.0 before exact-pair comparison. The result table displays normalized values and diagnostics retain raw values. This source update is committed but has not yet been run in Creo 18.1. Full Assembly scan and Graphical Browser interactions remain unverified.
