# 07 – Reusable Tool Development Workflow

## Repository structure
Use `main` as the shared development and knowledge branch. Do not create a new branch for each version.

Recommended structure:
```
src/
  <tool-name>/
    README.md
    ver-01/
    ver-02/
    ver-03/
skills/
  creo-elements-direct-modeling/
    SKILL.md
    references/
docs/
  AI_START_HERE.md
  ENGINEERING_KNOWLEDGE_BASE.md
  API_VERIFICATION_REGISTER.md
  USER_REFERENCE_INVENTORY.md
  TECHNICAL_DECISIONS.md
  KNOWN_ISSUES.md
  LESSONS_LEARNED.md
  DEVELOPMENT_LOG.md
tests/
  README.md
```

## Before creating a new tool
1. Define the real user problem and exact expected workflow.
2. Identify whether the task is native Modeling command, Lisp/Integration Kit, ME10 macro, Annotation customization or external integration.
3. Search existing code and this skill package for a working pattern.
4. Create a tool-specific README/specification and acceptance test list.
5. Build a diagnostic/minimal proof before a large UI implementation.
6. Use separate version folders for architectural iterations.

## API verification record
For every unfamiliar API, record:
- symbol/function name;
- source/manual and release;
- exact signature and keywords;
- input object type;
- return type and units;
- module/license dependency;
- static/documentation/runtime evidence;
- minimal reproducible test;
- failure messages and compatibility limits.

## Code quality patterns
- Preserve and restore current edit part/view context.
- Keep temporary LTABs, browser trees and UI objects lifecycle-safe.
- Use unique names only when the API requires them; do not create duplicate UI sessions when the user expects reuse.
- Avoid assumptions about object predicates; use verified inquiries.
- Normalize units only after a controlled comparison with UI values.
- Keep UI callbacks thin; delegate to tested functions.
- Preserve native selection/apply behavior when possible.
- Keep no-match/error behavior non-destructive.

## Documentation update checklist
After a meaningful change, update only relevant files but always keep:
- current project state;
- API register;
- decisions and known issues;
- lessons learned;
- development log/changelog;
- exact test evidence.

## User handoff format
Always provide:
- exact GitHub path and commit;
- exact LOAD statement and command name;
- test setup and actions in order;
- expected output/behavior;
- known limitations;
- clear statement whether only static-checked or actually tested in Creo 18.1.
