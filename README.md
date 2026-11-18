# PTC Creo Elements/Direct Modeling – H871 Upgrade Tools

Engineering workspace for custom tools targeting **PTC Creo Elements/Direct Modeling 18.1**.

## Current repository state

- **Canonical branch:** `main`.
- **Preserved Part Filter references:** ver-02, ver-03 UICT reference and ver-03 native Browser rebuild.
- **Experimental ver-04/ver-05/ver-06/ver-07 source:** removed from the current working tree; their reusable findings are consolidated in [Part Filter Experiment History](docs/PART_FILTER_EXPERIMENT_HISTORY.md).
- **All executable LISP and diagnostic/test code:** stored under `src/`.
- **Written test procedures:** stored under `tests/`.

The latest native Browser rebuild opens Results, but the user reports that only Part Name is visible. It is not a completed or runtime-accepted replacement.

## Start here

1. [AI Start Here](docs/AI_START_HERE.md)
2. [Project Context](PROJECT_CONTEXT.md)
3. [Part Filter Experiment History](docs/PART_FILTER_EXPERIMENT_HISTORY.md)
4. [Engineering Knowledge Base](docs/ENGINEERING_KNOWLEDGE_BASE.md)
5. [API Verification Register](docs/API_VERIFICATION_REGISTER.md)
6. [Technical Decisions](docs/TECHNICAL_DECISIONS.md), [Known Issues](docs/KNOWN_ISSUES.md), [Lessons Learned](docs/LESSONS_LEARNED.md)

## Repository map

- `src/part-filter/ver-02/` – preserved mapped-choice baseline.
- `src/part-filter/ver-03/` – preserved UICT/internal-tab reference source.
- `src/part-filter/ver-03-rebuild/` – preserved native Graphical Browser rebuild reference.
- `src/part-filter/` – shared commands and diagnostic/test LISP files.
- `src/h871-ribbon/` – native Modeling Available Command / Ribbon integration starter for H871 tools.
- `docs/` – engineering knowledge, API evidence, decisions and history.
- `tests/` – written regression procedures and sanitized test assets.
- `skills/creo-elements-direct-modeling/` – reusable cross-chat Creo skill package.

## Main-branch policy

- Work directly on `main`; do not create a branch for every experiment.
- Preserve ver-02 and ver-03 source files unchanged unless the user explicitly authorizes a baseline revision.
- Experimental code is temporary. Once an experiment is rejected, keep its lessons, not another permanent version folder.
- Never claim runtime success from static inspection or a trace marker.
- Keep customer models, proprietary drawings, credentials and personal data out of this public repository.
