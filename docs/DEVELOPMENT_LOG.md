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
- User clarified that there must be one separate Results window with browser-like internal tabs.
- Same Density pair refreshes its existing page; a different pair creates a new page.
- Each page owns results and selection; Apply affects only the active page.
- No-match must not silently erase existing valid pages.
- The old multi-browser architecture was explicitly rejected.
- UICT Tab Control was identified as a research direction; 18.1 compatibility and real Part Apply hand-off were unverified.

## 2026-11-15 – Main-branch knowledge consolidation
- User requested `main` as the shared development/knowledge branch, with no branch per LISP version.
- Version-specific source folders and centralized AI handover/engineering knowledge docs are being established.
- Runtime claims remain limited to user-confirmed Creo tests.

## 2026-11-15 – Cross-chat Creo skill package
- Recovered earlier project context for the 2026-10-09 measurement/export request and 2026-10-16 Annotation frame investigation.
- Retrieved prior user-provided Library materials: Annotation sheet/frame macros (467 lines), BOM layout customization macros (580 lines), drawing sheet/view arrangement macros (311 lines), and Part Filter diagnostic prototype (3,389 bytes).
- Reviewed and distilled their technical patterns into `skills/creo-elements-direct-modeling/references/`.
- Added API Verification Register, User Reference Inventory and reusable skill instructions.
- Kept full CoCreate confidential legacy macro source out of public GitHub; only summaries and provenance metadata are committed.
- Did not find an accessible standalone official Creo Elements/Direct Modeling 18.1 Integration Kit PDF/manual in the Library inventory.
- Explicitly recorded that measurement/export APIs and Annotation frame catalogue registration remain unverified.

## 2026-11-16 – ver-03 internal-tab prototype implemented
- Added canonical source `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp` on `main`.
- Integrated the ver-02 recursive Assembly scan, exact Density pair matching, ×1000 normalization and mapped Machining Process/Material dialog.
- Implemented one UICT Dialog Shell with one horizontal internal Tab Control and per-page List Controls.
- Implemented page identity by exact Density Instance + Density Base pair, same-pair refresh, new-pair tab creation and no-match preservation.
- Added per-page multi-selection, Select All, Clear Selection and selection count.
- Static checks: balanced parentheses and strings; no Creo runtime test was possible.
- PTC UICT signatures were researched in official 20.7/20.8 references. Exact Modeling 18.1 availability/signatures remain unverified.
- Native Apply hand-off is deliberately not connected because a safe 18.1 method to transfer UICT-selected real Part objects has not yet been proven.
- Updated project context, ver-03 README, API register, known issues, tests and implementation notes.
- ver-01 and ver-02 were not modified.

## Current status
- ver-01: user-confirmed baseline.
- ver-02: mapped-choice source preserved; user reported very good results.
- ver-03: UICT prototype implemented and static-checked; first runtime test in Modeling 18.1 pending; Apply hand-off pending.


## 2026-11-16 – ver-03.1 multi-column table and explicit Apply implementation
- User runtime-confirmed that the single Results window and internal tabs work, but identified concatenated text rows, nonfunctional row selection/Select All, and missing explicit Apply.
- Replaced per-page List Controls with Display Table Controls backed by independent logical tables.
- Added visible columns: Part Name, Density Instance, Density Base, Assembly Path; hidden untyped :part-object column retains the actual Part object.
- Enabled :multiple-rows selection; added page-scoped Select All, Clear Selection, Apply and selection count.
- Same-pair refresh updates the logical table in place and clears stale selection; other tabs remain untouched.
- Apply reads selected Part objects and routes them through a temporary Graphical Browser using the native :set-object-selection and :select-and-execute commands used by ver-02.
- PTC 20.7 references confirm Display Table/logical-table/multi-row selection APIs, but exact Modeling 18.1 compatibility is unverified.
- The ver-02 native Apply pattern is user-confirmed; the new hidden Display Table-to-BrowserNode bridge is not runtime-tested yet.
- ver-01 and ver-02 remain unchanged as regression baselines.


## 2026-11-16 – ver-03.2 logical-table refresh recovery
- User reported runtime error after choosing Process/Material and pressing OK: `A logical table with name "" does not exist`, followed by the generic result-table refresh error.
- Source review identified a stale in-memory page-record compatibility case: page registry globals survive LISP reloads, while older page entries may lack the `:logical-table` key.
- Refresh now derives the table name from the stable page ID, validates it, recreates missing logical tables, checks the Display Table binding, and restores the control if stale.
- Error message now includes the concrete logical-table name for further diagnosis.
- Committed to main; Modeling 18.1 retest pending. ver-01/ver-02 untouched.


## 2026-11-16 – ver-03.2 follow-up: empty-string truthiness
- User retested the previous recovery patch and reported the same empty logical-table error.
- Found the precise bug in the fallback: Common Lisp treats the empty string as truthy, so an OR expression does not replace an explicitly empty :logical-table value.
- Corrected the refresh path to accept the stored logical-table name only if it is a non-empty string; otherwise it derives the deterministic name from the page ID.
- Committed to main; runtime retest pending.


### 2026-11-16 – ver-03 numeric filter / caption correction
- Rechecked numeric search path against ver-02. `1` (Density Instance) + `304` (Density Base) is the actual CNC-SUS304 search pair; labels are presentation only.
- Corrected tab caption order and added numeric argument validation. Runtime diagnosis of the separate NIL/STRING error remains open.


### 2026-11-16 – ver-03 early tab callback NIL guard
- Reviewed full ver-03 initialization against known-good ver-02.
- Guarded tab-change/status callback against firing before the page registry and UI handles exist; prevent NIL from reaching Display Table selection APIs.
- Matched ver-02's null-safe Density Instance/Base check in the recursive filter. Runtime retest pending.


### 2026-11-16 – ver-03 partial UICT initialization recovery
- User confirmed the NIL-is-not-of-type-STRING error remained after the early tab-callback guard.
- Found a separate partial-initialization bug: shell, grid area and tab control were created under a single shell-existence check. If a previous failed run left only the shell alive, later runs skipped creation of missing child controls and tried to insert pages into an incomplete UI.
- Updated shell initialization to recover each layer independently with sd-control-p; changed tab callback binding to a function object as shown in PTC's official UICT examples.
- Density search logic and ver-01/ver-02 remain unchanged. Modeling 18.1 retest pending.


## 2026-11-16 – instrument ver-03 NIL/STRING failure (no speculative fix)

- User retested the previous callback guard and partial-UI recovery revision; the same `NIL is not of type STRING` error remains.
- The earlier callback and partial-shell explanations are therefore **not confirmed root causes** and must not be treated as resolved.
- Added a diagnostic trace writer to the canonical ver-03 source. It appends stage markers and relevant handle values to `H871_PART_FILTER_VER_03_TRACE.txt` in the Modeling user's home directory.
- Trace markers cover the run entry, collection/report completion, shell/grid/tab checks and creation, tab insertion, logical-table creation/check, text/display-table/button creation, current-tab activation, and logical-table refresh.
- The last `BEGIN` marker in the trace identifies the exact call being entered when the uncaught NIL/STRING error occurs. This allows the next fix to target the failing API argument rather than guessing.
- No filtering predicate or Density mapping was changed. CNC-SUS304 remains numeric Density Instance=1 and Density Base=304, with API values normalized by /1000. ver-01/ver-02 remain untouched.
- Commit: `8c0a1cd56f25f125958080b3ab6316e55827b141`.
- Runtime diagnosis is pending the user's next test and trace file.


## 2026-11-16 – ver-03 Results UI confirmed; Apply BrowserNode type mismatch

- User confirmed that after closing/reopening Modeling and loading the latest ver-03 source, the Results window appears, per-filter tabs are created, the table displays Part Name/Density columns, and the Apply button is present.
- Pressing Apply produces the exact runtime error: `#:NODE241 is not of type "BROWSERNODE"`.
- Compared the Apply source path: `h871-pf-v03-build-apply-tree` stores the direct return value from `sd-create-browsernode`; `h871-pf-v03-native-apply` passes that stored value to `:set-object-selection`.
- Runtime value `#:NODE241` is an uninterned symbol, not a BrowserNode structure. This localizes the failure to the Apply bridge's assumption that the creation return token is already a BrowserNode object.
- ver-02 obtains actual selected BrowserNodes via `sd-query-browser ... :get-selected-objects`; it does not use the direct creation return token as a BrowserNode.
- Next step: verify the exact Modeling 18.1 API for resolving a created node identifier to a BrowserNode structure, then pass only that structure to `:set-object-selection`. Do not invent a lookup API.
- Preserve the now-working Results UI, numeric Density Instance/Base matching, and ver-02 source. Apply remains unresolved until the exact 18.1 API is verified and user retests.

## 2026-11-16 – ver-03 Apply BrowserNode identifier resolution

- Exact user error: `#:NODE241 is not of type "BROWSERNODE"`.
- PTC official Graphical Browser documentation confirms `sd-create-browsernode` returns a symbolic node ID; `sd-get-browsernode-struct` resolves that ID to the BrowserNode structure required by BrowserNode-consuming commands.
- The ver-02 source already uses `sd-get-browsernode-struct` to resolve the root node.
- Updated only the ver-03 Apply tree builder: capture each creation ID, resolve it, and store the resulting BrowserNode structure before `:set-object-selection`.
- No changes to Density filter, Results UI, logical tables, tabs, or ver-01/ver-02.
- Modeling 18.1 runtime retest remains required; Apply is not marked resolved until user confirmation.

## 2026-11-16 – Emergency rollback after fatal exception

- User reported Modeling fatal exception `Oxc00000fd` immediately after pressing OK to Search; message warned that model data may have been damaged.
- Reviewed the two latest source diffs. They only changed `h871-pf-v03-build-apply-tree` and the early validation guard in `h871-pf-v03-native-apply`; they did not edit the Search dialog or `h871-pf-v03-run`. Cause of the Search-time fatal exception remains unknown.
- Emergency action: restored the active ver-03 source on `main` to the last source revision associated with user-confirmed Results UI appearance: `8c0a1cd56f25f125958080b3ab6316e55827b141`.
- This removes the unverified Apply fix. Do not represent Apply as fixed. The restored revision is a source rollback only; user must reload it in a disposable test session and verify Search before further use.
- Safety: do not test on or overwrite the original model. Preserve the exact crash report/log and diagnostic trace for investigation.
