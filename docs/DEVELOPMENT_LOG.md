# Development Log

Concise milestone history. Detailed abandoned UI iterations have been consolidated into `LESSONS_LEARNED.md`; Git commits retain the full source history.

## 2026-11-13 – Initial Part Filter investigation

- Targeted Creo Elements/Direct Modeling 18.1.
- Established the need to find Parts in an Assembly by property values and return selectable model objects.
- Explored Density Instance/Base retrieval and Graphical Browser result presentation.
- Early experiments with `GET_SELECTION` and direct Structure Browser selection were not accepted as the final user workflow.

## 2026-11-13 – Exact Density pair and Results Browser direction

- Clarified that the current Material/physical-property direction should distinguish Instance and Base values; the implemented Density search became an exact Instance + Base pair.
- Chose a dedicated BOM-like Graphical Browser so results can be inspected and selected before applying them to Modeling.
- Kept property matching separate from result-table presentation.
- Material retrieval remained unverified and was not included in the working Density implementation.

## 2026-11-14 – Results Browser stabilized

### User-confirmed in Creo Elements/Direct Modeling 18.1
- Results Browser opens and displays matching Part rows.
- Select All is available in the Results window.
- Clicking individual rows selects the corresponding Part.
- Native Apply transfers selected Part(s) to Creo Modeling selection.

### Resolved defects
- Corrected `sd-browser-set-status-text` keyword usage by passing the message with `:value`.
- Removed a custom Apply callback that replaced native browser behavior and caused selection/Apply regression.
- Restored the standalone Graphical Browser after the unified host-shell/browser-parent experiment caused matching searches to fail.

### Current baseline constraints
- Preserve the standalone Results Browser.
- Preserve native row selection and native default Apply behavior.
- Preserve the working Select All action.
- Do not reintroduce the failed host-shell/browser-parent embedding approach.
- Density matching uses the exact normalized Instance + Base pair.

## Current source at consolidation

- Main source: `src/part-filter/H871_PART_FILTER.lsp`
- Diagnostic baseline: `src/part-filter/H871_PART_FILTER_DIAG.lsp`
- Main source blob: `e94a89547460e038b2669995f2136fc1dd835816`
- Runtime evidence: user confirmation dated 2026-11-14, as listed above.

## Next step

No implementation task is pre-approved yet. Wait for the user's next feature idea, then update the project context and relevant technical decisions before changing source.
