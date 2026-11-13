# Technical Decisions

Record decisions that constrain future implementation. Amend entries only when a decision is deliberately revisited; preserve the rationale and date.

## TD-001 – Target CAD platform

- **Date:** 2026-11-13
- **Decision:** Target PTC Creo Elements/Direct Modeling 18.1.
- **Rationale:** This is the user's stated production environment.
- **Implication:** Do not assume Creo Parametric APIs or newer Elements/Direct APIs are compatible. Verify functions and object/property access in version 18.1.

## TD-002 – Part property filter uses exact Instance/Base matching

- **Date:** 2026-11-13
- **Decision:** The Material filter is based on an exact pair of property values: Instance and Base.
- **Example:** Instance = `1`, Base = `304`.
- **Rationale:** The user explicitly clarified that the Material page needs filtering by Instance and Base values, not comparison operators.
- **Implication:** A match requires both fields to match the entered values. Do not add greater-than/less-than comparisons or treat the two fields as OR alternatives.
- **Open detail:** Confirm the exact property retrieval mechanism and the meaning of the previously selected implementation approach B from the original source/discussion before implementing.

## TD-003 – Test claims must distinguish static checks from in-application tests

- **Date:** 2026-11-13
- **Decision:** Code review, syntax checks, successful file loading, functional tests, and regression tests are separate verification levels.
- **Rationale:** A LISP file can pass a basic static check but still fail in the Creo reader or behave incorrectly against real model objects.
- **Implication:** Development logs must state precisely which verification levels were completed.

## TD-004 – Documentation is part of each feature change

- **Date:** 2026-11-13
- **Decision:** Meaningful source changes must be accompanied by updates to the development log and, where relevant, technical decisions, lessons learned, known issues, and changelog.
- **Rationale:** New development sessions must be able to resume from repository evidence rather than relying on chat history.
