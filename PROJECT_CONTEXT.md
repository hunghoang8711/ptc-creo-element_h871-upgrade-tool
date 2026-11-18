# H871 Upgrade Tools – Project Context

**Last consolidated:** 2026-11-18  
**Target application:** PTC Creo Elements/Direct Modeling 18.1  
**Canonical branch:** `main`  
**Repository:** `hunghoang8711/ptc-creo-element_h871-upgrade-tool`

## 1. Project purpose

Build reliable, reusable LISP tools for Creo Elements/Direct Modeling 18.1. This repository is both source control and the durable engineering knowledge base. New chats must use the documented API evidence and prior failure history instead of repeating experiments.

## 2. Canonical Part Filter source

| Source | Role | Preservation rule |
|---|---|---|
| `src/part-filter/ver-02/H871_PART_FILTER_VER_02.lsp` | Mapped Process/Material filter; native Graphical Browser selection and Apply baseline | Keep unchanged |
| `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp` | UICT/internal-tab implementation reference | Keep unchanged; do not assume hidden Apply bridge works |
| `src/part-filter/ver-03-rebuild/H871_PART_FILTER_VER_03_REBUILD.lsp` | Stage 0 native Graphical Browser rebuild derived from ver-02 | Keep as a reference candidate; latest user test reports only Part Name visible |
| `src/part-filter/ver-01/` | Earlier numeric filter baseline | Preserve |

The ver-03 UICT source and the ver-03 native Browser rebuild are different implementation paths. Do not conflate their runtime results or Apply behavior.

## 3. Current runtime status (2026-11-18)

- User reports that the current native Browser rebuild opens the Results window.
- The Results window displays only the Part Name column. Density Instance, Density Base and Assembly Path are not visible.
- The source contains four custom column definitions, but source presence is not proof that the custom table is active or rendered.
- The most recent change to table activation order did not improve the runtime result.
- The native Browser rebuild remains **not complete**. Do not make further speculative lifecycle-order changes. First add targeted runtime diagnostics for actual Browser mode, active table, table roots and table-definition/activation return values, and inspect the entire Results window including horizontal scroll state.\n- Separately, the ver-03 Part Note UICT extension includes cross-page Select All / Clear All / Apply All. The user confirmed Select All Pages works in Modeling 18.1 on source revision 415481d0a62a744d3b09cb7b0cc697b623b14716. Clear All Pages and Apply All Pages remain pending separate runtime verification.
- Row selection, Select All, Clear Selection and native Apply must be regression-tested after any change. Do not assume they still work merely because Results opens.

## 4. Filter mapping and invariant

The filter uses an exact Density Instance AND Density Base pair.

Machining Process → Density Instance:
- CNC=1, KH=2, CG=3, COVER=4.

Material convention → Density Base:
- A6061=6061, SUS201=201, SUS304=304, SS400=400,
- POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.

Tested API values are normalized by dividing by 1000:
- UI 1/304 ↔ API 1000/304000.
- UI 2/400 ↔ API 2000/400000.

These labels are user-defined mappings; the Material selector does not read the Part's actual Material property. Never replace numeric filter inputs with labels such as CNC-SUS304. Never weaken the AND predicate or invent a missing Density Instance value.

## 5. Product requirement

The intended product is one separate Results window with internal pages/tabs for unique Density pairs. Each page must show only its matching Parts, preserve page-local selection where feasible, and support direct row selection, Select All, Clear Selection and Apply. Native Apply must transfer only selected Parts to the actual Modeling selection.

Do not create one Browser per query, dock result windows in the Creo Browser Bar, use a hidden Browser bridge, or reparent the Browser into a custom host shell without a separately proven 18.1 API path.

## 6. Lessons and experiment history

Read [Part Filter Experiment History](docs/PART_FILTER_EXPERIMENT_HISTORY.md) for consolidated ver-04 through ver-07 findings, exact reported errors, failed architectures, lifecycle lessons and the mandatory next workflow.

Read [Engineering Knowledge Base](docs/ENGINEERING_KNOWLEDGE_BASE.md), [API Verification Register](docs/API_VERIFICATION_REGISTER.md), [Known Issues](docs/KNOWN_ISSUES.md), [Lessons Learned](docs/LESSONS_LEARNED.md) and [Technical Decisions](docs/TECHNICAL_DECISIONS.md) before changing source.

## 7. API evidence discipline

- User-confirmed Modeling 18.1 behavior, source-observed behavior, later-release documentation and unverified proposals are separate evidence classes.
- PTC 20.6/20.7/20.8 documentation is not proof of 18.1 compatibility.
- Preserve exact tested API call patterns from ver-02.
- Do not assume `HANDLER-CASE` or `SEL_ITEM-P` exists; both were reported undefined.
- `sd-browser-set-status-text` requires `:value`.
- A BrowserNode creation symbol such as `#:NODE241` is not a BrowserNode structure. Resolve it before calling a BrowserNode-typed API, then verify actual viewport selection.
- A trace status or non-NIL return is not proof of Apply.

## 8. Repository workflow

- Work directly on `main`.
- Preserve ver-02 and ver-03 LISP source byte-for-byte unless explicitly authorized.
- Keep all executable LISP and test/diagnostic code under `src/`; keep written test plans under `tests/`.
- Do not keep rejected experimental versions as permanent code folders. Consolidate their reusable lessons in the experiment history.
- Before editing, inspect current `main` source and related docs.
- Make one isolated change at a time and record exact evidence.
- Static-check source before asking for runtime tests.
- Use a disposable model copy for risky tests; never use the original/customer model.
- Never claim a feature is complete until the user confirms it in Modeling 18.1.

## 9. Other Creo knowledge

The reusable skill package at `skills/creo-elements-direct-modeling/` preserves recovered knowledge beyond Part Filter, including Annotation sheet/frame macros, BOM layout customization, drawing arrangement, platform/language boundaries and debugging workflow. Do not copy confidential user-provided source dumps into this public repository; preserve technical summaries and provenance only.
