# Development Log

Milestone history. Reusable technical findings are consolidated in `ENGINEERING_KNOWLEDGE_BASE.md` and `LESSONS_LEARNED.md`; Git history retains source revisions.

## 2026-11-13 – Part Filter foundation
- Targeted Creo Elements/Direct Modeling 18.1.
- Explored recursive Assembly scan and Density retrieval.
- Preserved diagnostic source separately.
- Established that actual Material-property retrieval was not verified.

## 2026-11-13 to 2026-11-14 – ver-01 baseline stabilized
User-confirmed:
- Results Graphical Browser opens and displays matching Part rows.
- Select All is available.
- Clicking an individual row selects that Part.
- Native Apply transfers selected Part(s) to Modeling selection.

Resolved:
- Fixed `sd-browser-set-status-text` keyword usage with `:value`.
- Removed custom Apply callback that broke selection hand-off.
- Restored standalone Graphical Browser after unified host-shell embedding failed.

## 2026-11-14 – ver-02 mapped-choice dialog
- Created ver-02 from the confirmed filter engine.
- Added Machining Process choices: CNC=1, KH=2, CG=3, COVER=4.
- Added Material convention choices: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
- Retained Density Instance + Density Base as the actual search properties.
- Default CNC + SUS304 (1/304).
- User reported the result was very good. Preserve ver-02 as its own version.
- Mapping is a convention only; no actual Material-property query was added.

## 2026-11-14 – Superseded ver-03 multi-browser experiment
- A prototype created a new Graphical Browser per search and used unique Browser/Tree names.
- It attempted to dock each browser as a tab in Creo's Browser Bar.
- This did not match the user's intended UI and is superseded. Do not load it as the intended ver-03.

## 2026-11-14 to 2026-11-15 – Corrected ver-03 specification
- User clarified that there must be one separate Results Browser window with browser-like internal tabs.
- Same Density pair refreshes its existing page; a different pair creates a new page.
- Each page owns results and selection; Apply affects only the active page.
- No-match must not silently erase existing valid pages.
- The old multi-browser architecture was explicitly rejected.
- UICT Tab Control is a research direction only; 18.1 compatibility and real Part Apply hand-off remain unverified.

## 2026-11-15 – Main-branch knowledge consolidation
- User requested `main` as the shared development/knowledge branch, with no branch per LISP version.
- Version-specific source folders and centralized AI handover/engineering knowledge docs are being established.
- Runtime claims remain limited to user-confirmed Creo tests.

## Current status
- ver-01: user-confirmed baseline.
- ver-02: mapped-choice source preserved; user reported very good results.
- ver-03: design specified; implementation pending.


## 2026-11-15 – Cross-chat Creo skill package
- Recovered earlier project context for the 2026-10-09 measurement/export request and 2026-10-16 Annotation frame investigation.
- Retrieved prior user-provided Library materials: Annotation sheet/frame macros (467 lines), BOM layout customization macros (580 lines), drawing sheet/view arrangement macros (311 lines), and Part Filter diagnostic prototype (3,389 bytes).
- Reviewed and distilled their technical patterns into `skills/creo-elements-direct-modeling/references/`.
- Added API Verification Register, User Reference Inventory and reusable skill instructions.
- Kept full CoCreate confidential legacy macro source out of public GitHub; only summaries and provenance metadata are committed.
- Did not find an accessible standalone official Creo Elements/Direct Modeling 18.1 Integration Kit PDF/manual in the Library inventory.
- Explicitly recorded that measurement/export APIs and Annotation frame catalogue registration remain unverified.
