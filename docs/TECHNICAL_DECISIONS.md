# Technical Decisions

Active decisions that constrain implementation. Historical experiments superseded by these decisions are summarized in `DEVELOPMENT_LOG.md` and `LESSONS_LEARNED.md`.

## TD-001 – Target platform

- **Date:** 2026-11-13
- **Decision:** Target PTC Creo Elements/Direct Modeling 18.1.
- **Rule:** Do not assume Creo Parametric APIs or later Elements/Direct APIs are compatible. Verify functions, signatures, object types, and UI behavior in 18.1.

## TD-002 – Current Density filter is an exact pair

- **Date:** 2026-11-13 (clarified 2026-11-14)
- **Decision:** The current filter matches both Density Instance and Density Base exactly. Both conditions must be true.
- **Retrieval:** `sd-inq-part-density` with `:instance` for Instance and `:contents` for Base.
- **Normalization:** Current source divides returned API values by 1000 before comparing/displaying them.
- **Evidence:** User-tested examples: UI 1/304 corresponds to raw API 1000/304000; UI 2/400 corresponds to raw API 2000/400000.
- **Rule:** Do not reintroduce comparison operators or AND/OR controls into this exact-pair baseline unless the user changes the requirement.

## TD-003 – Preserve the working Results Browser selection architecture

- **Date:** 2026-11-14
- **Decision:** Keep the standalone Graphical Browser and its native row-selection and Apply behavior.
- **User-confirmed:** Results rows display; Select All is available; individual rows can be selected; native Apply transfers selected Parts to Modeling selection.
- **Rule:** Do not override the native default Apply action with a callback that immediately reopens the browser. Do not reintroduce the unified host-shell/browser-parent embedding design that caused matching searches to fail.

## TD-004 – Separate filter logic from result presentation

- **Date:** 2026-11-13
- **Decision:** Keep property acquisition and predicate evaluation independent from Graphical Browser tree/table construction.
- **Rationale:** Future property types and filter conditions should not require replacing the working Results Browser or selection hand-off.

## TD-005 – Verification evidence must be explicit

- **Date:** 2026-11-13
- **Decision:** Static checks, API-reference review, successful loading, functional testing, and regression testing are different evidence levels.
- **Rule:** Mark runtime behavior as confirmed only after a test in Modeling 18.1 or an explicit user report. Later-release documentation is not proof of 18.1 compatibility.

## TD-006 – Documentation is part of each change

- **Date:** 2026-11-13
- **Decision:** Meaningful source changes must update the project context and relevant development/decision/issue/lesson/changelog records in the same work session.
- **Rule:** Keep current state concise; do not duplicate every intermediate experiment across multiple documents.
