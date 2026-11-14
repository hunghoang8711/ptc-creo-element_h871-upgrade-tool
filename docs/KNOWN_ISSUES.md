# Known Issues and Verification Gaps

Only unresolved or unverified items belong here. Remove an item when it is resolved; preserve reusable root-cause knowledge in `LESSONS_LEARNED.md`.

## KI-001 – Material property inquiry

- **Status:** Not implemented / not verified.
- **Details:** A reliable Material-name/code retrieval mechanism has not yet been confirmed for Creo Elements/Direct Modeling 18.1.
- **Next step:** Diagnose the exact property source on a known Part in 18.1 before adding Material to the filter UI.

## KI-002 – Additional Part properties

- **Status:** Future scope.
- **Details:** Mass, Volume, dimensions, bounding-box values, structure metadata, and custom attributes have not yet been validated as filterable properties in the current tool.
- **Next step:** Do not add UI fields until each property's retrieval API, returned type, units, and instance/base semantics are understood.

## KI-003 – Broader filter-condition workflow

- **Status:** Not implemented.
- **Details:** A dynamic condition builder, arbitrary add/remove rows, comparison operators, text matching, and grouped AND/OR logic are not part of the current exact Density-pair implementation.
- **Next step:** Wait for the user's feature definition; do not assume the previously brainstormed design is approved.

## KI-004 – Additional Results Browser behaviors

- **Status:** Not confirmed as part of the current baseline.
- **Details:** Clear Selection visibility/functionality, repeat-search lifecycle, and other convenience behaviors have not been independently confirmed in the latest user test.
- **Next step:** Retest only if the next feature depends on them.

## Resolved baseline behavior

The following are not open issues: the Results Browser opens and displays result rows; Select All is present; clicking a row selects it; native Apply transfers selected Parts to Modeling selection. The user confirmed these behaviors in Creo Elements/Direct Modeling 18.1 on 2026-11-14.
