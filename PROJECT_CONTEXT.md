

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


## 2026-11-14 — Part Filter reader-error correction
- Latest source fix: `h871-pf-as-number` now uses valid `#\Space`, `#\Tab`, and `#\Newline` character literals (single backslash).
- The previous doubled-backslash form caused the Lisp reader's octal-digit error and likely the subsequent parenthesis error.
- Static check passed; do not mark the filter runtime-tested until the user reloads it successfully in Creo Elements/Direct Modeling 18.1.


## 2026-11-14 — Second reader-error mitigation
- Removed `READ-FROM-STRING`, `STRING-TRIM`, and `#\\Space` / `#\\Tab` / `#\\Newline` from the numeric helper.
- The helper now accepts numeric values only, which matches the current API and dialog contract.
- If the same message persists, verify the local file version/path and capture the exact source line or load-stage prompt before further edits.


## 2026-11-14 – Part Filter result browser follow-up

### User-confirmed current behavior
- The BOM-like Part Name result table is now visible.
- Individual Part rows can be selected.
- A remaining runtime message appears when the filter command is run: `Odd number of arguments for keywords.`

### Source correction and requested workflow
- Corrected both `sd-browser-set-status-text` calls: the status message is now supplied using `:value`, matching the PTC Integration Kit function signature. This is the likely cause of the keyword-argument error.
- Added visible `Select All` and `Clear Selection` buttons to the result browser.
- The filter dialog now defers termination after the search, keeping Assembly, Density Instance, and Density Base inputs available for the next search.
- The result browser is a separate window and can be closed after the user has selected the required Parts.

### Pending runtime confirmation
- Confirm no keyword-argument error appears in Creo 18.1.
- Confirm Select All selects every displayed result row.
- Confirm the filter input dialog remains open and accepts a changed Density pair for a subsequent search.
- Do not describe these new behaviors as runtime-verified until the user confirms them.


## 2026-11-14 – Part Filter results UI refinement

### User feedback
- The previous `Odd number of arguments for keywords` message is now gone in Creo 18.1.
- Select All is still not visible in the result browser.
- Density Instance and Density Base columns are too far to the right due to oversized columns.

### Latest source changes
- Selection menu callbacks now invoke the named `h871-pf-select-all` and `h871-pf-clear-selection` functions.
- Set `:buttonMenuOffObjectOnly nil` to avoid restricting the button menu to blank-space context clicks.
- Browser max width reduced from 1150 to 900.
- PTC Graphical Browser reference confirms `:initial-width` is in character counts, not pixels. Widths are now Part Name 28, Density Instance 13, Density Base 12, Assembly Path 42.

### Pending Creo 18.1 test
- Verify Select All and Clear Selection controls are visibly available.
- Verify Select All selects every displayed row.
- Verify Part Name, Density Instance, and Density Base are visible together without horizontal scrolling.
- If Select All remains hidden, switch to a separate always-visible control mechanism instead of relying on the browser menu compatibility mapping.
