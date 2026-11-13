# Project Context

Last updated: 2026-11-13

## Purpose

Develop and maintain practical LISP-based productivity tools for PTC Creo Elements/Direct Modeling, with a reliable handover process across development sessions.

## Target environment

| Item | Current information |
|---|---|
| CAD platform | PTC Creo Elements/Direct Modeling |
| Version | 18.1 |
| CAD paradigm | Direct Modeling (not Creo Parametric) |
| Main customization language | Creo/ME10-style LISP environment; confirm exact supported dialect/API per feature |
| User technical background | Automation machine design engineer; basic LISP familiarity |
| Related CAD tools | AutoCAD 2023, Autodesk Inventor 2021 |

Do not assume that APIs, commands, object models, or LISP functions from Creo Parametric or another Creo release are available in Elements/Direct Modeling 18.1. Verify against the target application's actual environment and documentation.

## Development conventions

- Prefer small, testable LISP modules over one large monolithic file.
- Give commands and user-facing labels clear, consistent names.
- Handle missing properties, empty selections, unsupported objects, and malformed input explicitly.
- Avoid modifying model data unless the feature explicitly requires it.
- Provide diagnostic output that helps identify the failing object/property without overwhelming normal users.
- Keep UI behavior predictable and avoid filters or comparisons that were not requested.
- Preserve working behavior unless a requirement explicitly changes it.

## Initial feature: Part property filter

### User requirement

Each Part can expose properties such as **Material** and **Density**, with separate **Instance** and **Base** values visible in Part Properties.

The requested filter targets **Density**, displayed under the **Material** tab in Part Properties. It is an exact-value lookup, not a comparison/query-language interface.

Example confirmed by the user's Part Properties screenshot:
- Density Instance value: `1`
- Density Base value: `304`

The UI should expose only the two numeric fields (Density Instance and Density Base). Both values are mandatory for matching; no comparison operators, per-field enable toggles, or AND/OR selector are required.

The tool should find Parts whose corresponding property values match the entered Instance **and** Base values. Both values form one exact pair; do not interpret them as comparison operators or as alternatives.

The user selected implementation approach **B** in the earlier design discussion. The detailed technical meaning of option B must be recovered from the original source/discussion before changing architecture; do not invent missing implementation details.

### Initial implementation (2026-11-13)

- Added `src/part-filter/H871_PART_FILTER.lsp`.
- The implementation uses `sd-inq-part-density` with `:instance` for Instance and `:contents` for Base.
- It scans Parts recursively under the selected Assembly and writes exact-pair matches to `H871_PART_FILTER_RESULT.txt` in the user's home directory.
- Initial dialog values are 1.0 and 304.0, matching the supplied screenshot.
- This is a first implementation, not yet loaded or functionally tested in Creo 18.1.

### Known historical development information

- A filter UI with input/filter options was displayed, but the returned filter values did not match the intended behavior.
- The user clarified that the Material page only needs filtering by Instance and Base values.
- An earlier diagnostic LISP file, `H871_PART_FILTER_DIAG.lsp`, produced:
  `Unexpected end of #<input stream "...H871_PART_FILTER_DIAG.lsp">`
- The exact source file and failing line are not currently in this repository. The error is recorded as historical evidence, not a confirmed current defect.

### Acceptance criteria for the Part filter

1. User can enter an exact Instance value and an exact Base value for the target property.
2. A Part is a match only when both requested values match the corresponding property fields.
3. No comparison operators are required or shown for this workflow.
4. Matching is evaluated against actual Part property data, not text guessed from display labels.
5. Empty, missing, or unavailable property values are handled explicitly.
6. Results are verified against representative Parts in Creo Elements/Direct Modeling 18.1.
7. The test record states the exact property, input pair, expected Parts, and actual results.

## Source and test status

Source `src/part-filter/H871_PART_FILTER_DIAG.lsp` has been imported and preserved unchanged as the diagnostic baseline. The first working implementation is `src/part-filter/H871_PART_FILTER.lsp`. No Creo test model or functional test evidence has been committed yet.

## Session handover checklist

- [ ] Read README and this file.
- [ ] Read technical decisions, known issues, lessons learned, and development log.
- [ ] Inspect the current source and latest commit.
- [ ] Confirm the target Creo version and actual LISP runtime.
- [ ] Identify what has been functionally tested in Creo.
- [ ] Update docs with every meaningful implementation or test result.


### Native selection-list output (2026-11-13)

- Updated the filter to call Creo's `GET_SELECTION` interrupt action with Part focus, `:in_assembly`, and a check function that accepts only the exact Density Instance/Base pair.
- Intended result: matching Parts become native Creo selection items for follow-on commands such as Add to Drawlist.
- This behavior is implemented in source but still requires verification in Creo 18.1; static code review cannot confirm the selector's runtime behavior in this installation.


### Structure Browser selection implementation (2026-11-13)

- Corrected the earlier approach: `GET_SELECTION` returns `SEL_ITEM` values and is a selector/inquiry API; it is not itself a command to set the Structure Browser's selected nodes.
- New implementation targets the standard Structure Browser named `parcel-gbrowser` and uses `sd-browser-exec-cmd` with `:set-object-selection` for each matching BrowserNode.
- It expands the current Structure Browser tree, locates nodes by object path, clears the previous browser selection, then selects matching nodes.
- The code now distinguishes model matches from nodes successfully selected in the browser and does not claim selection success when the count is zero.
- Still pending actual verification in Creo 18.1.
