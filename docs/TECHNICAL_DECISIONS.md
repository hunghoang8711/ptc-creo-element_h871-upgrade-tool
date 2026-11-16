# Technical Decisions

Active decisions that constrain implementation. Superseded experiments are recorded in `DEVELOPMENT_LOG.md` and `LESSONS_LEARNED.md`.

## TD-001 – Target platform
- **Date:** 2026-11-13
- **Decision:** Target PTC Creo Elements/Direct Modeling 18.1.
- **Rule:** Do not assume Creo Parametric APIs or later Elements/Direct APIs are compatible. Verify function existence, signatures, object types and UI behavior in 18.1.

## TD-002 – Density filter is an exact pair
- **Date:** 2026-11-13; clarified 2026-11-14
- **Decision:** Match Density Instance and Density Base exactly; both conditions must be true (AND).
- **Retrieval:** `sd-inq-part-density :instance` and `sd-inq-part-density :contents`.
- **Normalization:** Current source divides returned API values by 1000.
- **Evidence:** Tested UI 1/304 ↔ API 1000/304000; UI 2/400 ↔ API 2000/400000.
- **Rule:** Do not generalize this conversion to other properties.

## TD-003 – Preserve native Graphical Browser selection and Apply
- **Date:** 2026-11-14
- **Decision:** Preserve standalone Graphical Browser, native row selection, Select All and native Apply hand-off.
- **User-confirmed:** Rows display, individual rows can be selected, Select All works and Apply transfers selected Parts to Modeling selection.
- **Rule:** Do not replace native Apply with a custom callback that reopens the browser. Do not revive the failed host-shell/browser-reparenting architecture.

## TD-004 – Separate filter engine from presentation
- **Date:** 2026-11-13
- **Decision:** Keep property acquisition/predicate evaluation separate from result presentation so future UI work does not rewrite the verified filter logic.

## TD-005 – Explicit verification evidence
- **Date:** 2026-11-13
- **Decision:** Static review, API documentation review, loading, functional test and regression test are separate evidence levels.
- **Rule:** Later-release documentation is not proof of Modeling 18.1 compatibility.

## TD-006 – Documentation accompanies meaningful changes
- **Date:** 2026-11-13
- **Decision:** Update project context and relevant knowledge/decision/issue/lesson/log records when meaningful discoveries or implementation changes are made.

## TD-007 – ver-02 user convention mappings
- **Date:** 2026-11-14
- **Decision:** ver-02 maps fixed Machining Process and Material labels to the existing Density Instance/Base inputs; it does not retrieve actual Material metadata.
- **Machining Process → Density Instance:** CNC=1, KH=2, CG=3, COVER=4.
- **Material → Density Base:** A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
- **UI:** Numeric `:range` values with human-readable `:label`; display-only code fields synchronized by `:after-input`.
- **Default:** CNC + SUS304 (1/304).
- **Rule:** Treat mappings as the user's convention, not actual Material-property retrieval.

## TD-008 – ver-03 is one Results window with internal tabs
- **Date:** 2026-11-14; corrected and confirmed 2026-11-15
- **Decision:** One separate Results Browser window contains multiple horizontal pages/tabs. Tabs are internal to that window, not separate Graphical Browsers and not Creo Browser Bar tabs.
- **Identity:** One unique Density Instance + Density Base pair maps to one tab; caption uses mapped Material-Process labels.
- **Refresh:** Repeating a pair refreshes its existing page; a different pair adds a page.
- **Isolation:** Each page retains its own results and selection state where feasible; Apply operates only on the active page.
- **No-match:** A no-match search does not silently erase existing valid tabs.
- **Rule:** Do not implement as multiple Graphical Browser instances. The prior multi-browser ver-03 experiment is superseded.

## TD-009 – Single shared main branch and version folders
- **Date:** 2026-11-15
- **Decision:** Use `main` as the shared development and knowledge branch. Do not create branches for each LISP version.
- **Versioning:** Keep ver-01, ver-02, ver-03 etc. in separate source folders. Preserve user-confirmed versions; create a new version for architectural changes.
- **Knowledge:** Consolidate requirements, technical findings, lessons, troubleshooting and reusable skills into shared docs on main so new chats/tools can bootstrap from one source.

## TD-010 – ver-03 UICT prototype and Apply boundary
- **Date:** 2026-11-16
- **Decision:** Prototype the internal-tab UI using one UICT Dialog Shell, one horizontal Tab Control and per-page List Controls; do not create one Graphical Browser per search or dock separate windows in Creo Browser Bar.
- **Implemented behavior:** One page per exact Density pair, same-pair refresh, new-pair page creation, page-local row selection, Select All/Clear Selection and no-match preservation.
- **Compatibility rule:** UICT references currently reviewed are PTC 20.7/20.8 documentation. Modeling 18.1 compatibility is unverified until the user loads and tests the source in 18.1.
- **Apply rule:** Do not wire Apply until a Modeling 18.1 method is demonstrated to transfer only the selected real Part objects from the active page into Modeling selection. Preserve ver-01/ver-02 native Apply as the production baseline.



## TD-011 – Keep multi-page results and native Apply in one Graphical Browser (diagnostic stage)

- Date: 2026-11-16
- Decision: Do not copy UICT Display Table selection into a hidden Graphical Browser. Keep the visible Results rows, selected BrowserNodes and native Apply button in one Graphical Browser instance, as proven in ver-02.
- Candidate: Represent each Density pair as a page root in one Browser Tree. Use the selected page root to populate the one Browser table. Save/restore selection paths per page when switching roots.
- Navigation prototype: Previous/Next toolbar buttons and a dynamic Results Pages popup submenu. This is not yet the required horizontal tab strip; it is intended to validate the single-Browser Apply architecture first.
- Apply: Keep :okButtonLabel "Apply" and do not override :okButtonAction; use the native Graphical Browser default.
- Scope: Diagnostic only. Do not change the ver-03 production source, collector, Density mappings, normalization, or ver-02 baseline until runtime tests prove the candidate.


## TD-012 – Persistent two-way navigation between UICT and native Results Browser (diagnostic stage)

- Date: 2026-11-16
- Decision: Keep one visible Results window at a time. Close Results returns to the existing ver-03 UICT shell; a persistent `Open Native Results` button in that shell reopens the native Browser using the latest UICT page state.
- Implementation: ver-04 installs the uniquely named button in the existing ver-03 grid and routes it to the diagnostic rebuild function. The Browser is rebuilt rather than merely shown, so searches made in UICT after returning are captured.
- Scope: diagnostic only; this does not yet implement horizontal tabs inside the native Browser. Verify UICT control placement, callback and repeat open/close in Modeling 18.1 before adopting this as final UI.
