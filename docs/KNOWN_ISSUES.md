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

- **Status:** User-confirmed working.
- **Details:** The user tested ver-02 and reported a very good result. The mapped-choice dialog is the accepted baseline for the next development stage.
- **Remaining UI limitation:** Code fields appear in separate rows after selectors; same-row right-side placement remains a separate enhancement.

## KI-006 – Independent search sessions / browser tabs

- **Status:** Implemented in ver-03 candidate; awaiting runtime test.
- **Details:** ver-03 stores each search in a session registry and assigns unique Browser and Browser Tree names. Browser callbacks route selection actions by Browser name. Each successful search requests a docked tab with a Material-Process label.
- **Compatibility risks:** `:update-args`, `:createAsTab` and `:tabname` were found in later PTC Integration Kit references; availability/behavior in Modeling 18.1 is not confirmed.
- **Next step:** Test two different searches, switching tabs, per-tab row selection, Select All, native Apply, duplicate search labels and hiding one tab without affecting the others.

## Resolved baseline behavior

The following are user-confirmed in Creo Elements/Direct Modeling 18.1: Results Browser opens and displays result rows; Select All is present; clicking a row selects it; native Apply transfers selected Parts to Modeling selection; ver-02 mapped-choice dialog produced a very good result.
