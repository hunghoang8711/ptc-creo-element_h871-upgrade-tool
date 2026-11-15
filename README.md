# PTC Creo Elements/Direct Modeling – H871 Upgrade Tools

Version-controlled engineering workspace for custom tools targeting **PTC Creo Elements/Direct Modeling 18.1**.

## Current focus

**H871 Part Filter – ver-02 baseline preserved; ver-03 single-window multi-tab design specified, implementation pending.**

The confirmed filter behavior is based on an exact Density Instance + Density Base pair. The mapped UI uses Machining Process and Material convention labels, which map to those existing Density values; it does not read the model's actual Material property.

## Start here (AI / new development session)

1. Read [AI_START_HERE](docs/AI_START_HERE.md) for the mandatory handover workflow.
2. Read [PROJECT_CONTEXT](PROJECT_CONTEXT.md) for the current state and active feature.
3. Read [ENGINEERING_KNOWLEDGE_BASE](docs/ENGINEERING_KNOWLEDGE_BASE.md) for consolidated APIs, mappings, failure causes, compatibility limits and engineering rules.
4. Read [TECHNICAL_DECISIONS](docs/TECHNICAL_DECISIONS.md), [KNOWN_ISSUES](docs/KNOWN_ISSUES.md), and [LESSONS_LEARNED](docs/LESSONS_LEARNED.md).
5. Inspect the exact versioned LISP source before editing.

## Repository map

- `docs/AI_START_HERE.md` – compact instructions for new chats and new tool development.
- `PROJECT_CONTEXT.md` – live project state and handover.
- `docs/ENGINEERING_KNOWLEDGE_BASE.md` – consolidated technical memory and reusable engineering skills.
- `src/part-filter/ver-01/` – preserved ver-01 source.
- `src/part-filter/ver-02/` – mapped-choice ver-02 source.
- `src/part-filter/ver-03/` – target specification and future implementation; not yet implemented.
- `src/part-filter/` root – legacy source paths retained for compatibility.
- `docs/TECHNICAL_DECISIONS.md` – active decisions.
- `docs/KNOWN_ISSUES.md` – unresolved or unverified items only.
- `docs/LESSONS_LEARNED.md` – confirmed root causes and prevention rules.
- `docs/DEVELOPMENT_LOG.md` – milestone history and verification evidence.
- `tests/` – repeatable manual regression procedures.

## Main-branch and version policy

- `main` is the single shared development and knowledge branch.
- Do not create a branch for each LISP version or routine feature iteration.
- Keep each released/experimental LISP version in its own `ver-XX` folder.
- Never overwrite a previously user-confirmed version; create the next version instead.
- Update the shared context, knowledge base, decisions, issues, lessons and log whenever a meaningful discovery is made.
- Experimental or superseded code must be clearly labelled and must never be presented as the active version.

## Development rules

1. Inspect repository state, current source and relevant docs before changing code.
2. Preserve confirmed Results Browser row selection, Select All and native Apply behavior.
3. Target Modeling 18.1; never assume Creo Parametric or later Elements/Direct APIs are compatible.
4. Make small, isolated changes and distinguish static checks from actual Creo runtime tests.
5. Record exact user-observed results; never claim runtime success without evidence.
6. Keep customer models, proprietary drawings, credentials and personal data out of this public repository.

## Verification terminology

- **Specified** – requirement/design recorded; no implementation claim.
- **Implemented** – source has been changed.
- **Static-checked** – source structure/syntax inspected; not proof of Creo compatibility.
- **Loaded in Creo** – file loaded in the target application.
- **Functionally tested** – behavior exercised in Creo.
- **User-confirmed** – user reported the behavior working in their target environment.
- **Regression-tested** – existing confirmed behavior retested after a change.


## Reusable Creo skill package

The complete cross-chat skill package is in [`skills/creo-elements-direct-modeling/`](skills/creo-elements-direct-modeling/SKILL.md). It includes platform/language boundaries, recovered user-provided Annotation references, BOM and drawing macro analysis, Part Filter history, API evidence, debugging procedures and a reusable development workflow.

Also see [API Verification Register](docs/API_VERIFICATION_REGISTER.md) and [User Reference Inventory](docs/USER_REFERENCE_INVENTORY.md). The package is designed to let a new chat continue after the original project conversation is unavailable.
