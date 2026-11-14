

## 2026-11-14 – Confirm Part inquiry and add direct Density kind tests

- User confirmed `sd-inq-part-p` returns `T` for the known Part `010-plate_2.1.1.2.1`.
- User confirmed the legacy one-argument `sd-inq-part-density` call returns `1000.0` (realized/default density).
- Confirmed the `ELAN::SEL_ITEM` selection handle is accepted directly; it is not the cause of the filter mismatch.
- Added `H871_DENSITY_KIND_TEST.lsp` with separate direct tests for `:instance` and `:contents`.
- Static parentheses/string scan passed. Optional-kind runtime tests in Creo 18.1 remain pending.
