# Development Log

This file records chronological development work. Major features receive their own headings; small corrections are dated entries. Keep entries factual and distinguish implementation from testing.

## 2026-11-13 – Repository documentation baseline

### Work completed
- Verified the public GitHub repository was empty before initialization.
- Created the initial repository README and project context.
- Established documentation files for decisions, lessons, issues, and changes.
- Recorded the initial Part property filter requirements from prior project discussions.

### Verification
- GitHub repository access and file creation: successful.
- Creo LISP execution: not performed.
- Part filter functional behavior: not verified; source has not yet been imported.

### Next steps
1. Import the current LISP source files and any relevant historical versions.
2. Inspect the actual implementation of approach B.
3. Reproduce and isolate the historical filter mismatch.
4. Inspect the historical unexpected-end-of-input diagnostic error.
5. Establish a repeatable test set in Creo Elements/Direct Modeling 18.1.

## Entry template

### YYYY-MM-DD – Feature or change title

**Objective**
- What user-visible behavior is required?

**Files changed**
- List source and documentation paths.

**Implementation**
- Summarize the technical change and relevant design choices.

**Verification**
- Environment and Creo version:
- Static checks:
- Loaded in Creo:
- Functional tests:
- Regression tests:

**Result**
- Implemented / Static-checked / Loaded in Creo / Functionally tested / Regression-tested.

**Remaining work / risks**
- List unverified cases and follow-up actions.


## 2026-11-13 – First exact Density Instance/Base filter implementation

### Objective
- Replace the unused Material text input and comparison-oriented Density controls with an exact Density Instance/Base pair lookup.

### Files changed
- Added `src/part-filter/H871_PART_FILTER.lsp`.
- Preserved `src/part-filter/H871_PART_FILTER_DIAG.lsp` unchanged.
- Updated `PROJECT_CONTEXT.md`, technical decisions, known issues, changelog, and source guidance.

### Implementation
- The dialog asks for an Assembly, Density Instance, and Density Base only.
- Defaults are Instance = 1.0 and Base = 304.0, matching the user's screenshot.
- Recursive scan uses `sd-inq-part-density` with `:instance` and `:contents`; both values must exist and match numerically.
- Matching Part names, paths, and actual values are written to `H871_PART_FILTER_RESULT.txt` in the user's home directory.
- Created backup branch `backup-before-density-filter-20261113` before implementation.

### Verification
- GitHub source creation: successful.
- Static parentheses/string scan of the new source: balanced; no negative nesting or unterminated string.
- PTC reference confirms `:instance` means Instance density and `:contents` means Base density. Reference is for a later Elements/Direct release; compatibility must still be confirmed in Creo 18.1.
- Loaded in Creo 18.1: not performed.
- Functional / regression tests: not performed.

### Result
- Implemented and static-checked; not yet verified in Creo.

### Remaining work / risks
1. User loads the new file in Creo 18.1 and confirms the dialog opens.
2. Run against an Assembly containing known Parts with (Instance 1, Base 304), plus near-matches such as (1, other) and (other, 304).
3. Confirm the report contains only Parts matching both values.
4. If the result file is not sufficient and the user expects matching Parts selected/highlighted in the viewport, implement selection feedback after verifying the supported 18.1 selection API.


## 2026-11-13 – Native selection-list output

### Objective
- After exact Density Instance/Base matching, place matching Parts into Creo's native selection list so the user can apply standard commands such as Add to Drawlist.

### Files changed
- Updated `src/part-filter/H871_PART_FILTER.lsp`.
- Updated project context, technical decisions, known issues, and changelog.

### Implementation
- Added a GET_SELECTION check function that accepts only Parts whose Density Instance and Density Base both exactly match the requested values.
- Calls `get_selection` with `*sd-part-seltype*`, `:check_function`, and `:select :in_assembly`.
- Writes the returned selection items and their properties to the result report.

### Verification
- PTC Integration Kit reference describes GET_SELECTION, :in_assembly, and :check_function behavior.
- Source updated on GitHub successfully.
- Static balance/load checks: pending re-run after this update.
- Creo 18.1 selection-list behavior: not yet tested.

### Result
- Implemented; pending in-application verification.

### Next test
1. Load the updated `H871_PART_FILTER.lsp` only (avoid loading the old diagnostic file as a command source for this test).
2. Run `H871_PART_FILTER` and select the target Assembly.
3. Enter Instance 1 and Base 304.
4. Confirm matching Parts appear in the active selection list / Structure Browser selection state.
5. Invoke Add to Drawlist and confirm it acts on those Parts.
6. Report the selected count and any error text.


## 2026-11-13 – Correct native Structure Browser selection

### Objective
- Make matched Parts visibly selected in the existing Structure Browser, like selecting rows in the browser, so the user can continue with Add to Drawlist.

### Root cause of previous attempt
- The previous implementation treated `GET_SELECTION` return values as if they set persistent Structure Browser selection. PTC documents GET_SELECTION as invoking the standard SELECT subaction and returning SEL_ITEMs; it does not provide the Structure Browser node-selection operation.
- The previous success message was unconditional even when the result count was zero. This was incorrect and has been removed.

### Implementation
- Scan the selected Assembly's model object tree and collect exact Density Instance/Base matches.
- Use the standard Structure Browser `parcel-gbrowser`.
- Expand the browser tree, locate each matching BrowserNode by its object path, clear the previous selection list, and call `:set-object-selection node t` for each match.
- Report matching count, selected count, and nodes not found separately.

### Verification
- PTC Graphical Browser reference documents `:SET-OBJECT-SELECTION`, `:CLEAR-SELECT-LIST`, `:EXPAND-TREE`, `:GET-CHILDREN`, and `:GET-GRAPHICS-ROOT`.
- Source updated on GitHub; static balance check pending.
- Creo 18.1 runtime behavior: not yet tested.

### Remaining risks
1. Structure Browser may be closed, not fully built, or in a mode where some nodes are not selectable.
2. Browser object paths must match `sd-inq-obj-pathname` paths.
3. Density exact-match retrieval still requires separate verification against known Part Properties values.
