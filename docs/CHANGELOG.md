# Changelog

## 2026-11-15 – Consolidate main branch knowledge
- Establish `main` as the single shared development and knowledge branch.
- Define version folders for ver-01, ver-02 and ver-03.
- Consolidate AI handover, project context, technical knowledge, compatibility rules, failure causes and test workflow.
- Correct the ver-03 requirement: one Results Browser window with internal tabs; previous multi-browser prototype is superseded.
- No new ver-03 implementation is claimed.

## 2026-11-14 – Stabilize ver-01 and preserve ver-02
- Confirmed Results Browser rows, Select All, individual row selection and native Apply in Modeling 18.1.
- Corrected status-text keyword usage and removed the Apply callback that broke native selection.
- Added mapped Machining Process and Material convention choices in ver-02.
- Preserved exact Density Instance + Base matching.

## 2026-11-13 – Establish Part Filter foundation
- Added initial Part property/Density investigation and diagnostic source.
- Implemented recursive Assembly scan and exact Density pair search.
- Added a BOM-like Graphical Browser result table.


## 2026-11-15 – Cross-chat Creo knowledge and skill package
- Added reusable `skills/creo-elements-direct-modeling/` skill with platform, language, Annotation, BOM, drawing, Part Filter, API and debugging references.
- Added API Verification Register and User Reference Inventory.
- Consolidated prior chats and user-provided Annotation macro sources from October 2026.
- Recorded unverified measurement/export APIs and frame catalogue registration as unresolved, not as implemented facts.
- Preserved source provenance and avoided mirroring confidential legacy source text into public GitHub.



## 2026-11-17 – Main branch consolidation

- Consolidated Part Filter experiment history and failure lessons in `docs/PART_FILTER_EXPERIMENT_HISTORY.md`.
- Preserved ver-02, ver-03 UICT and ver-03 native Browser rebuild source references.
- Retired ver-04/ver-05 experimental source files from the current main tree; ver-06/ver-07 lessons are documented rather than retained as code versions.
- Standardized executable LISP/test/diagnostic code location under `src/`.
