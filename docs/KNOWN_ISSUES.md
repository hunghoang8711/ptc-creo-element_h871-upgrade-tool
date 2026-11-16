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

## KI-006 – ver-03 UICT compatibility and Apply runtime validation
- **Status:** Results UI runtime-confirmed by user; Apply source fix committed; Modeling 18.1 Apply retest pending.
- **Details:** One UICT Results window, internal tabs, multi-column table, and Apply button are user-confirmed working. Apply now resolves each symbolic node ID returned by `sd-create-browsernode` through `sd-get-browsernode-struct` before passing the resulting BrowserNode structure to `:set-object-selection`.
- **Compatibility gap:** UICT Display Table/logical-table APIs are documented in PTC 20.7/20.8 references; exact Modeling 18.1 availability/signatures are not all proven.
- **Next step:** In Modeling 18.1, select one result row and Apply, then select multiple rows and Apply. Verify only those actual Parts become selected. Capture the exact error if any.
- **Production boundary:** ver-01/ver-02 remain unchanged as known-good selection/apply baselines. Do not mark ver-03 Apply resolved until user confirms runtime behavior.

## Resolved baseline behavior

User-confirmed in Modeling 18.1: Results Browser opens and displays rows; Select All is present; clicking a row selects that Part; native Apply transfers selected Parts to Modeling selection.

## KI-007 – Annotation frame catalogue registration
- **Status:** Unresolved / not verified.
- **Details:** The recovered `am_sheet.m`-style source loads, creates and replaces frames but does not show how the Annotation UI frame list is populated. `docu-register-frame` was only a hypothesis; user reported `am_customize` unavailable.
- **Next step:** Trace the installed 18.1 frame selection dialog and built-in frame discovery mechanism before adding multiple A4 options.

## KI-008 – Geometry measurement and export APIs
- **Status:** Unverified.
- **Details:** Initial measurement/export and command access concepts were discussed on 2026-10-09, but no real Modeling 18.1 geometry measurement API/signature/units were confirmed.
- **Next step:** Build a minimal diagnostic on a known test part and verify one geometry inquiry at a time before implementing export.

## KI-009 – Official 18.1 Integration Kit manual availability
- **Status:** Not found in currently accessible Library inventory.
- **Details:** Recovered user files are legacy Annotation macro sources and a Part Filter diagnostic; no standalone official 18.1 Integration Kit PDF was surfaced.
- **Next step:** If an official manual exists in older chat storage or local files, retrieve it and record its exact release/source before using it as authority.
