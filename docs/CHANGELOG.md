

## 2026-11-14 – Confirm separate Density Instance and Contents inquiries

- User ran both direct tests on the known Part in the native Creo Elements/Direct model.
- `:instance` returned `1000.0`; `:contents` returned `304000.0`.
- Part Properties displays the corresponding values as Instance = `1` and Base = `304`.
- Confirmed the two optional kind arguments work in this Modeling 18.1 environment and return distinct fields.
- Recorded the observed 1000:1 scale relationship; its unit semantics still need confirmation before implementing normalization.
- Clarified native model scope: test and develop against `.pkg` / `.bdl`, not STEP-imported geometry.



## 2026-11-14 – Normalize Density API values in Part Filter

- Second native Part verified: Part Properties Instance/Base = 2/400; API `:instance` / `:contents` = 2000/400000.
- Together with the first Part, confirmed a 1000:1 API-to-display scale on two different Density pairs.
- Updated `H871_PART_FILTER.lsp` to normalize API values by dividing by 1000.0 before exact matching.
- Result table and matched-Part report now use Part Properties scale; raw API values remain available in diagnostics.
- Runtime verification of the complete filter in Creo 18.1 is still pending.


## 2026-11-14
- Fixed invalid Common Lisp character literals in the numeric-string parser of `H871_PART_FILTER.lsp`, addressing the reported `Octal digit expected` load error.
- Static syntax-balance check passed; Creo 18.1 runtime test pending.


## 2026-11-14
- Simplified numeric conversion to avoid `READ-FROM-STRING` and Lisp character literals after the user reported the reader error persisted.
- Creo 18.1 runtime verification remains pending.


## 2026-11-14 – Part Filter usability and keyword-error correction
- Corrected both `sd-browser-set-status-text` calls to pass the text with the documented `:value` keyword; this is the likely cause of the reported `Odd number of arguments for keywords` error.
- Added visible `Select All` and `Clear Selection` toolbar buttons to the result browser.
- Kept the Assembly / Density Instance / Density Base input dialog active after each search so another density pair can be entered immediately.
- Result browser remains separately closable after Part selection.
- Creo 18.1 runtime verification is pending.


## 2026-11-14 – Part Filter results UI refinement
- User confirmed the keyword-argument error is resolved.
- Reworked the Select All / Clear Selection button-menu callbacks and set `:buttonMenuOffObjectOnly nil`.
- Reduced browser maximum width to 900.
- Reduced result column widths to 28 / 13 / 12 / 42 characters. PTC documentation confirms `:initial-width` uses character counts, not pixels.
- Runtime visibility and selection behavior still require confirmation in Creo 18.1.
