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
