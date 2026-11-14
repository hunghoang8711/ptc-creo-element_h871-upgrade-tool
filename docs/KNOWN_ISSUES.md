# Known Issues and Verification Gaps

Only unresolved or unverified items belong here. Remove an item when it is resolved; preserve reusable root-cause knowledge in `LESSONS_LEARNED.md`.

## KI-001 – Material property inquiry

- **Status:** Not implemented / not verified.
- **Details:** ver-02 maps user-defined Material labels to numeric Density Base values. It does not read the model's actual Material property. A reliable Material-name/code retrieval mechanism has not yet been confirmed for Modeling 18.1.

## KI-002 – Additional Part properties

- **Status:** Future scope.
- **Details:** Mass, Volume, dimensions, bounding-box values, structure metadata, and custom attributes have not yet been validated as filterable properties.

## KI-003 – Broader filter-condition workflow

- **Status:** Not implemented.
- **Details:** A dynamic condition builder, arbitrary add/remove rows, comparison operators, text matching, and grouped AND/OR logic are not part of the current exact Density-pair implementation.

## KI-004 – Additional Results Browser behaviors

- **Status:** Not confirmed as part of the current baseline.
- **Details:** Clear Selection visibility/functionality, repeat-search lifecycle, and other convenience behaviors have not been independently confirmed in the latest user test.

## KI-005 – ver-02 dialog compatibility in Modeling 18.1

- **Status:** Awaiting runtime test.
- **Details:** ver-02 uses numeric `:range` choices with `:label`, `:after-input` synchronization, and `:display-only` code fields. The implementation follows the Dialog Generator pattern documented by PTC, but the available references are for later releases. The code fields currently occupy separate rows after the selectors; same-row right-side placement is not yet implemented.
- **Next step:** Load `H871_PART_FILTER_VER_02.lsp` in Modeling 18.1. Confirm dialog creation, default CNC/SUS304 values, code-field updates, non-editability, and numeric values passed to the search function. Then assess a compatible same-row layout for the selector and its code field.

## KI-006 – Independent search sessions / browser tabs

- **Status:** Deferred; not implemented.
- **Details:** Current source uses shared result globals and fixed Browser/Tree names, and the current search path destroys the prior Browser/Tree. Multi-session support requires per-session result data and unique Browser/Tree identities before any tab UI is added.
- **Next step:** After ver-02 dialog validation, prototype independent Browser/Tree instances and test native selection/Apply before tab docking.

## Resolved baseline behavior

The following are user-confirmed in Creo Elements/Direct Modeling 18.1: Results Browser opens and displays result rows; Select All is present; clicking a row selects it; native Apply transfers selected Parts to Modeling selection.
