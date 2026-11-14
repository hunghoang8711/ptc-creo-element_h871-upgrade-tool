# Technical Decisions

Active decisions that constrain implementation. Historical experiments superseded by these decisions are summarized in `DEVELOPMENT_LOG.md` and `LESSONS_LEARNED.md`.

## TD-001 – Target platform

- **Date:** 2026-11-13
- **Decision:** Target PTC Creo Elements/Direct Modeling 18.1.
- **Rule:** Do not assume Creo Parametric APIs or later Elements/Direct APIs are compatible. Verify functions, signatures, object types, and UI behavior in 18.1.

## TD-002 – Density filter remains an exact numeric pair

- **Date:** 2026-11-13 (clarified 2026-11-14)
- **Decision:** The filter matches Density Instance and Density Base exactly. Both conditions must be true.
- **Retrieval:** `sd-inq-part-density` with `:instance` for Instance and `:contents` for Base.
- **Normalization:** Current source divides returned API values by 1000 before matching/displaying them.
- **Evidence:** User-tested examples: UI 1/304 corresponds to raw API 1000/304000; UI 2/400 corresponds to raw API 2000/400000.

## TD-003 – Preserve the working Results Browser selection architecture

- **Date:** 2026-11-14
- **Decision:** Keep the standalone Graphical Browser and its native row-selection and Apply behavior.
- **User-confirmed:** Results rows display; Select All is available; individual rows can be selected; native Apply transfers selected Parts to Modeling selection.
- **Rule:** Do not override native Apply with a callback that immediately reopens the browser. Do not reintroduce the failed unified host-shell/browser-parent embedding design.

## TD-004 – Separate filter logic from result presentation

- **Date:** 2026-11-13
- **Decision:** Keep property acquisition and predicate evaluation independent from Graphical Browser tree/table construction.

## TD-005 – Verification evidence must be explicit

- **Date:** 2026-11-13
- **Decision:** Static checks, API-reference review, successful loading, functional testing, and regression testing are different evidence levels.
- **Rule:** Later-release documentation is not proof of 18.1 compatibility.

## TD-006 – Documentation is part of each change

- **Date:** 2026-11-13
- **Decision:** Meaningful source changes must update project context and relevant development/decision/issue/lesson/changelog records.

## TD-007 – User convention codes map to the existing Density pair

- **Date:** 2026-11-14
- **Decision:** ver-02 presents fixed Machining Process and Material choices while retaining Density Instance/Base as the underlying search properties.
- **Machining Process → Density Instance:** CNC=1, KH=2, CG=3, COVER=4.
- **Material → Density Base:** A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
- **UI:** Use numeric `:range` values with human-readable `:label` text. Adjacent code fields are `:display-only` and synchronized by `:after-input`.
- **Default:** CNC + SUS304 (1/304), matching the previous dialog's default numeric pair.
- **Rule:** Changing the mapping is a user-owned convention update in the ver-02 `:range` lists. Do not describe this as actual Material-property retrieval.
- **Compatibility note:** Dialog Generator range labels and display-only behavior are supported by later PTC Integration Kit documentation; runtime compatibility must still be checked in Modeling 18.1.

## TD-008 – Multi-search result tabs are deferred

- **Date:** 2026-11-14
- **Decision:** Preserve the user's direction to keep each search result as an independent session and later present sessions in browser-like tabs.
- **Rule:** Do not combine this feature with ver-02. Each session must own its result list, Browser identity, and Browser Tree. Validate tab docking separately in Modeling 18.1.
