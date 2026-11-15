# Known Issues and Verification Gaps

Only unresolved or unverified items belong here. Move resolved root causes into `LESSONS_LEARNED.md`.

## KI-001 – Actual Material property inquiry
- **Status:** Not implemented / not verified.
- **Details:** ver-02 maps user-defined Material labels to Density Base values; it does not read a Part's actual Material property.
- **Next step:** Diagnose a known Part in Modeling 18.1 before implementing actual Material retrieval.

## KI-002 – Additional Part properties
- **Status:** Future scope.
- **Details:** Mass, Volume, dimensions, bounding-box values, structure metadata and custom attributes have not been validated as filterable properties.
- **Next step:** Verify API, return type, units and instance/base semantics individually.

## KI-003 – General filter-condition builder
- **Status:** Not implemented.
- **Details:** Dynamic add/remove conditions, comparison operators, text matching and grouped AND/OR logic are not part of the current exact Density-pair tool.

## KI-004 – Additional Results Browser behavior
- **Status:** Partially verified / not part of baseline.
- **Details:** Clear Selection visibility/functionality and repeat-search lifecycle have not been independently reconfirmed after all UI changes.
- **Next step:** Retest only when a new feature depends on them.

## KI-005 – ver-02 dialog details
- **Status:** Implemented; user reported very good results. Detailed regression coverage should still be recorded.
- **Details:** Mapped choice dialog uses `:range`, `:label`, `:after-input` and `:display-only`. Standard dialog positions code fields on separate rows. A same-row custom layout is not implemented.
- **Next step:** Preserve current mappings and dialog behavior. Re-test only if changing this area.

## KI-006 – One-window internal tabs (ver-03)
- **Status:** Specified; implementation pending.
- **Details:** The requested UI requires one separate Results Browser window with multiple internal pages. The previous ver-03 source creates one Graphical Browser per search and is the wrong architecture.
- **Technical blocker:** UICT Tab Control / Dialog Shell appears promising from later-release documentation, but exact 18.1 function availability/signatures and real-Part selection/Apply hand-off are unverified.
- **Next step:** Build a minimal 18.1-compatible prototype with synthetic data; validate tab shell, then real Part row selection and Modeling selection hand-off before integrating the filter engine.

## Resolved baseline behavior

User-confirmed in Modeling 18.1: Results Browser opens and displays rows; Select All is present; clicking a row selects that Part; native Apply transfers selected Parts to Modeling selection.
