

## 2026-11-14 – Density :instance and :contents confirmed on native model

### User runtime evidence
Tested on the native Creo Elements/Direct model Part `010-plate_2.1.1.2.1` (not a STEP-imported object):
- `(sd-inq-part-p part)` returned `T`.
- `(sd-inq-part-density part :instance)` returned `1000.0` (`LONG-FLOAT`).
- `(sd-inq-part-density part :contents)` returned `304000.0` (`LONG-FLOAT`).
- The same Part Properties fields are displayed to the user as Instance = `1` and Base = `304`.
- Both API values are exactly 1000 times the corresponding displayed values for this test Part.

### Conclusions
- Modeling 18.1 accepts both optional kind arguments in the user's environment.
- The direct API path correctly distinguishes the Instance and Contents/Base values; the earlier assumption that these optional arguments might be unsupported is disproven for this installation.
- The selected object remains a valid `ELAN::SEL_ITEM` input; no unwrapping is needed for these calls.
- The observed factor of 1000 is recorded as a measured relationship only. Its unit/conversion semantics are not yet independently established; do not hard-code a conversion without a further check against additional Parts or authoritative 18.1 unit documentation.

### Native model scope
The user clarified that the source model is native Creo Elements/Direct Modeling data (`.pkg` or `.bdl`), not STEP. All subsequent tests and implementation assumptions must target Parts and Assemblies in this native model structure. Do not build a STEP-import-specific attribute path.

### Next steps
1. Verify the 1000 factor against at least one more Part with known Instance and Base values, ideally including a zero/decimal or different density pair.
2. Inspect the current production filter and change only the value normalization/matching path once the scale convention is established.
3. Then run a full Assembly scan and compare the match list against the known Part path.
4. Continue toward the BOM-like result browser only after the core scan returns correct exact-pair matches.

### Verification status
- User-confirmed runtime success for Part predicate, `:instance`, and `:contents` calls on the native model.
- No claim yet that the production Assembly scan, result browser, double-click locate, or Add to Drawlist workflow has passed runtime testing.



## 2026-11-14 – Second native Part confirms Density scale; filter normalized

### Additional user runtime evidence
A second native Part was tested: `010-plate_2.1.1.2.1.1`.
- Part Properties: Density Instance = `2`, Density Base = `400`.
- `(sd-inq-part-density part :instance)` returned `2000.0`.
- `(sd-inq-part-density part :contents)` returned `400000.0`.
- Both calls returned `LONG-FLOAT`; `sd-inq-part-p` returned `T`.

Together with the first known Part (UI 1/304; API 1000/304000), this confirms the same exact 1000:1 ratio on two independent native Parts with different values.

### Source update
Updated `src/part-filter/H871_PART_FILTER.lsp`:
- Added `h871-pf-density-display-value`, which divides numeric API Density values by 1000.0.
- Exact-pair matching now compares normalized values against the dialog inputs.
- Result-table Density columns now display normalized values matching Part Properties.
- The result report includes both normalized display-scale values and raw API values for diagnosis.
- Diagnostic samples continue to preserve raw API values and their Lisp types.

### Verification status
- Source change committed to GitHub; this is not yet a Creo runtime test.
- Static source inspection is still required after this edit.
- The complete Assembly traversal, result count, Graphical Browser creation, and row-selection interactions remain unverified in Creo 18.1.
- Treat 1000 as an empirically confirmed conversion for the two tested Parts; if later testing reveals mixed units or exceptional values, isolate any adjustment in the normalization helper.


## 2026-11-14 — Fix Lisp reader error in numeric string parser
- Fixed invalid doubled backslashes in Common Lisp character literals in `h871-pf-as-number`: `#\\Space`, `#\\Tab`, and `#\\Newline` are now the valid `#\Space`, `#\Tab`, and `#\Newline` forms.
- Root cause of Creo's `Octal digit expected` reader error; the subsequent misplaced-right-parenthesis message was likely a cascading parse error.
- Static source check after the fix: balanced parentheses (0), no negative nesting, no unterminated string, and all three character literals verified.
- Creo Elements/Direct Modeling 18.1 runtime reload and filter execution still require user confirmation.


## 2026-11-14 — Remove reader-dependent numeric parsing
- After the user reported the same load error persisted, removed `READ-FROM-STRING`, `STRING-TRIM`, and all `#\\...` character literals from `h871-pf-as-number`.
- The workflow uses numeric dialog fields and numeric Density API results, so numeric-string parsing is unnecessary.
- Static check: balanced parentheses, no negative nesting, no unterminated string, and no remaining `READ-FROM-STRING` or character literals in the source. Creo runtime reload is pending.


## 2026-11-14 – Part Filter browser error, Select All, and repeat-search workflow

### User-reported state
- The BOM-like result table now appears and individual Part rows can be selected in Creo Elements/Direct Modeling 18.1.
- A LISP error still appears when the filter command is run: `Odd number of arguments for keywords.`

### Source diagnosis and correction
- Reviewed the current result-browser call sequence against the PTC Integration Kit Graphical Browser API reference.
- Found both calls to `sd-browser-set-status-text` passed the status message as a positional argument. The documented function takes the message through the keyword `:value`; this mismatch is the likely source of the keyword-argument error.
- Updated both status-text calls to use `:value`.
- Added visible browser toolbar buttons for `Select All` and `Clear Selection`, using the documented `:select-all` and `:clear-select-list` browser commands.
- Updated the filter dialog OK action to call `sd-return-from-ok-action` after each search, so the Assembly and Density Instance/Base inputs remain available for repeated searches without reopening the command.
- The result browser remains a separate window that the user can close after selecting the desired Parts.

### Verification status
- GitHub source update committed; this is a code change, not proof of runtime success.
- Need user confirmation in Creo 18.1 that the keyword error is gone, the Select All button selects all visible result rows, and the filter dialog remains open after each search.
- If Creo 18.1 rejects the new button-menu or deferred-dialog behavior, isolate those UI changes separately without disturbing the working result table.


## 2026-11-14 – Make result selection controls visible and compact table columns

### User feedback
- The keyword-argument error is confirmed resolved in Creo 18.1.
- The result browser still does not visibly expose Select All.
- The Part Name / Density columns are too wide; Instance and Base are pushed far to the right.

### Implementation
- Kept the existing Graphical Browser and result data model.
- Reworked the button-menu actions to call the named Select All and Clear Selection functions.
- Set `:buttonMenuOffObjectOnly nil` so the selection controls are not restricted to blank-space context clicks.
- Reduced browser maximum width from 1150 to 900.
- Corrected column widths after checking the PTC API: `:initial-width` is measured in characters, not pixels. New widths are Part Name 28, Density Instance 13, Density Base 12, Assembly Path 42.
- The three key columns should now fit together in a compact view; the path column remains available at a bounded width.

### Verification
- Source and documentation committed.
- Need user runtime confirmation that the Select All / Clear Selection controls are now visible and that all result rows are selected when pressed.
- Need visual confirmation that the density columns are visible without horizontal scrolling in Creo 18.1. These UI changes are not yet marked runtime-tested.
