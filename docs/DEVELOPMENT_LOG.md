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


## 2026-11-16 – ver-03 Search stack-overflow mitigation

- User reported that Modeling remained operational after closing the Filter tab, but the Search action had previously triggered Windows fatal exception `0xC00000FD` before Results UI creation.
- Source inspection found recursive Assembly traversal in `h871-pf-v03-collect`: the function recursively called itself for every child and did not track visited object references.
- Replaced recursion with iterative depth-first traversal using a local `EQ` hash table to process each object reference once. Children are pushed in reverse order to preserve the former depth-first sibling ordering.
- Kept Density Instance/Base numeric comparison, `/1000.0` normalization, CNC=1 / SUS304=304 mapping, Results UI, tabs, logical tables and Apply implementation unchanged from the rollback revision.
- Static source check passed: balanced parentheses, no negative nesting, no unterminated strings, and no self-recursive call remains in the collector.
- This is a strong candidate mitigation for stack exhaustion, not a runtime-confirmed root-cause fix. Modeling 18.1 testing must use a separate disposable model copy; never test against or overwrite the original customer model.
- Apply remains unresolved. ver-01 and ver-02 remain unchanged.


## 2026-11-16 – Iterative traversal did not resolve Search fatal exception

- User retested the iterative collector intended to mitigate possible stack exhaustion. The same fatal exception `0xC00000FD` occurred.
- This disproves the claim that the collector's explicit self-recursion alone explains the crash; root cause remains unknown.
- Rolled active ver-03 source back to the last revision associated with user-confirmed Results UI appearance (`8c0a1cd56f25f125958080b3ab6316e55827b141`). The iterative traversal candidate is retained in Git history, not active.
- Updated Known Issues with a strict evidence requirement: obtain the trace file and use its last marker to localize the failing stage before making another code change.
- No runtime success is claimed. ver-01 and ver-02 remain untouched.


## 2026-11-16 – Start ver-03 rebuild from the user-confirmed ver-02 baseline

- User approved rebuilding ver-03 from the last known-good ver-02 workflow instead of continuing speculative fixes in the unstable UICT-based implementation.
- Created isolated branch `rebuild/ver-03-from-ver-02`, based on the current `main`; no changes were made to `main`.
- Added `src/part-filter/ver-03-rebuild/H871_PART_FILTER_VER_03_REBUILD.lsp` as a mechanical clone of `src/part-filter/ver-02/H871_PART_FILTER_VER_02.lsp`.
- Isolated helper/global symbol names with the `h871-pf-rb-` prefix and assigned the new dialog command `H871_PART_FILTER_VER_03_REBUILD`, so loading the rebuild does not redefine ver-02's symbols/dialog.
- Stage 0 intentionally retains ver-02's Filter dialog, numeric Density Instance/Base mapping, search traversal, native Graphical Browser, row selection, Select All, Clear Selection and native Apply behavior.
- No UICT Display Table, logical table, internal tabs, or hidden Apply bridge has been carried into the rebuild.
- ver-01, ver-02 and the unstable original ver-03 source are untouched.
- Static source inspection only; no Modeling 18.1 runtime test has been performed by the assistant. Stage 0 must be tested by the user on a disposable model copy before any feature is added.


## 2026-11-16 – Stage 0 runtime confirmed; Stage 1 native multi-filter tabs implemented

- User confirmed Stage 0 rebuild works in Creo Modeling 18.1: Results appear; Select All and Apply work; double-click selects an individual Part.
- Preserved the Stage 0 source unchanged as the known-good rebuild baseline.
- Added a separate Stage 1 source: `src/part-filter/ver-03-stage1/H871_PART_FILTER_VER_03_STAGE1.lsp`.
- Stage 1 retains the same numeric Density Instance/Base search and native Graphical Browser selection/Apply workflow.
- New design: one independent Browser Tree + Graphical Browser per unique numeric Density pair. Each browser is requested as a docked Browser Bar tab via `:createAsTab t`; each tree is unique because PTC documentation states a tree cannot be shared by multiple browsers.
- Pair caption convention remains Process-Material, e.g. CNC-SUS304; actual search values remain numeric Instance=1 and Base=304.
- Repeating a pair replaces only that pair's result tab; a different pair creates another tab; a no-match search preserves existing tabs.
- Select All/Clear Selection actions are bound to the corresponding browser name. Apply remains the Graphical Browser's native default :select-and-execute; double-click remains native.
- No UICT Display Table, logical table, custom Apply bridge, or BrowserNode handoff was introduced.
- Static source validation passed: balanced parentheses, no unterminated strings, unique stage command and symbol prefix, separate tree update arguments, no UICT calls.
- Compatibility caveat: `:createAsTab` and Browser Tree `:update-args` were verified in later-version PTC Integration Kit documentation, not yet in a Modeling 18.1 runtime test. Stage 1 remains unverified until user tests it.
- Test only on a disposable model copy. Do not proceed to Stage 2 until Stage 1 passes.


## 2026-11-16 – Stage 1 Search exception: Browser Tree callback compatibility correction

- User tested Stage 1 and reported Fatal Exception `0xC00000FD` immediately after pressing Search OK. Closing the message left Modeling usable, matching the earlier incident; Results Browser did not appear.
- Compared Stage 1's search path with the user-confirmed Stage 0 source. Density matching and recursive Assembly collection are structurally equivalent; Stage 1's Browser Tree creation introduced a new later-version API usage: `:update-args` with a two-argument updater, unlike Stage 0's zero-argument callback.
- Targeted correction: removed `:update-args`. Stage 1 now registers a unique zero-argument callback symbol for each Density-pair tree. The callback closes over that tree name and pair key, so separate result trees retain independent data without relying on the later-version callback-argument feature.
- Added append-only trace milestones in `H871_PART_FILTER_STAGE1_TRACE.txt` under the Modeling user's home directory: Search entry, before/after collection, after report, before/after Browser Tree creation, after Browser creation, and after showing the Browser.
- Static validation after correction: 494 lines; parentheses balanced (depth 0, minimum 0); no unterminated strings; no `:update-args` call remains; zero-argument updater and trace writer present.
- Remaining unverified API: `:createAsTab` still relies on later-version PTC documentation and requires Modeling 18.1 runtime validation.
- Runtime status: **fix not yet confirmed**. User must test only on a disposable model copy and report either successful Results display or the last trace line if the exception persists.
- Stage 0, ver-01 and ver-02 source files were not modified.


## 2026-11-16 – Stage 1 trace inconclusive; reset to Stage 0-equivalent diagnostic

- User confirmed `H871_PART_FILTER_STAGE1_TRACE.txt` was created once, remained 0 KB, and was not recreated/updated after another Search attempt.
- Reviewed the trace function: it wraps file open/write/flush in `ignore-errors`, which can silently suppress a path, stream, or write failure. Therefore the empty file is not evidence that the Search function was never entered.
- The previous Stage 1 correction (unique zero-argument Browser Tree callbacks instead of `:update-args`) did not change the fatal exception. That hypothesis is not confirmed and must not be treated as a fix.
- Replaced the active Stage 1 source with a mechanical clone of the user-confirmed Stage 0 source. Only helper/global symbol prefix and dialog command/title are changed; single Browser/Tree, collector, report, native selection, Select All, Clear Selection and Apply follow Stage 0.
- Removed multi-browser sessions, generated callback closures, `:createAsTab`, `:tabname`, and the unreliable trace writer from the active diagnostic source.
- Static validation: 420 lines; opening/closing parenthesis counts match; no multi-tab options or trace writer remain; Stage 1 command and isolated helper prefix remain.
- Next user test: one CNC-SUS304 search in a fresh Modeling 18.1 session using a disposable model. Do not test multiple pairs until this baseline is confirmed.
- Stage 0, ver-01 and ver-02 sources remain unchanged. No runtime success is claimed.


## 2026-11-16 – Stage 1 diagnostic baseline runtime-confirmed

- User tested the current Stage 1 source after it had been reset to a mechanical clone of Stage 0.
- User confirmed Stage 1 now runs successfully in Creo Modeling 18.1 and provides the same functionality as Stage 0.
- This confirms the isolated Stage 1 command and helper/global prefix are compatible with the user's environment when the Stage 0 single-browser workflow is retained.
- No new feature has been added to Stage 1 yet; the user correctly noted that the current source is functionally equivalent to Stage 0.
- Diagnostic conclusion: the former `0xC00000FD` is associated with one or more changes removed from the multi-browser experiment, but the precise failing API/expression remains unknown.
- Next implementation rule: introduce one tab-related API difference per revision, test it in Modeling 18.1, and revert immediately if the fatal exception returns. Do not combine tab creation, multiple Browser Trees, callback changes, and selection changes in one patch.
- Stage 0, ver-01 and ver-02 remain unchanged. Current Stage 1 single-browser source is a user-confirmed runtime baseline.


## 2026-11-16 – Stage 1 isolated tab-presentation experiment

- After the user confirmed that the Stage 0-equivalent Stage 1 source runs successfully, prepared the first feature/API experiment.
- Added only `:createAsTab t` to the existing single `sd-create-graphical-browser` call in Stage 1.
- Kept one Browser Tree, one Graphical Browser, Density search/collection, report generation, table columns, native row selection, Select All, Clear Selection, double-click behavior and Apply logic unchanged.
- Did not add a second browser, per-pair browser registry, `:tabname`, callback closures, or any multi-tab lifecycle logic.
- Purpose: isolate whether Modeling 18.1 accepts the tab-presentation option before attempting multiple result sessions.
- Static check: balanced parentheses and exactly one `:createAsTab t` occurrence; runtime test pending.
- User test: run one CNC-SUS304 search in a disposable model, report whether Results opens, whether it appears as a tab, and whether selection/Apply remain functional. If it fails, remove this one option and restore the confirmed baseline.


## 2026-11-16 – Stage 1 createAsTab basic runtime test passed

- User tested Stage 1 with the single added `:createAsTab t` option.
- User reports that Stage 1 runs successfully and retains the same functionality as Stage 0. No fatal exception was reported.
- This establishes basic runtime compatibility of `:createAsTab t` with the existing single Graphical Browser workflow in the user's Modeling 18.1 environment.
- The user has not yet explicitly confirmed a visible tab presentation; same functionality as Stage 0 may mean the Browser still appears as a normal separate window. Keep this distinction unresolved rather than assuming the tab UI was created.
- No multi-browser sessions, second Browser Tree, `:tabname`, callback changes, search changes, or selection/Apply changes have been added.
- Next step: ask whether the Results Browser is visibly displayed as a tab or as a separate window. Only after confirming the presentation should the next isolated API experiment be selected.

## 2026-11-16 – Stage 1 explicit Browser docking experiment

- User clarified that the revision containing only `:createAsTab t` still opens a separate floating Results window; searching a different Density pair refreshes/replaces the displayed window.
- Reviewed PTC's Graphical Browser API reference. It states that `:createAsTab t` controls initial docking but can be overridden by a PDS preference saved from the previous Modeling session.
- PTC also documents `sd-dock-graphical-browser`, which explicitly docks a floating Graphical Browser into the Browser Bar and can activate its tab using `:show t`.
- Fetched the current Stage 1 source from the active branch and verified the existing browser lifecycle. The browser is shown with `sd-show-graphical-browser`.
- Added one isolated call immediately after that show operation: `(sd-dock-graphical-browser *h871-pf-mt-browser-name* :show t)`.
- Wrapped only the new call in `ignore-errors` to preserve the known-good floating Results behavior if the docking API is unavailable or rejected by this Modeling 18.1 build.
- No other browser/tree, filter, report, row-selection, Select All, Clear Selection, double-click, or Apply logic was changed.
- Source commit: `5294cdd9468963503c5c0d976588892882f2445e`.
- **Runtime status:** Pending user test in Creo Elements/Direct Modeling 18.1. Do not claim docking or tab presentation works until confirmed.


## 2026-11-16 – User reasserted ver-03 standalone internal-tab requirement

- User corrected the direction after an incorrect docking experiment.
- Exact required architecture: one independent standalone Results window, with multiple clearly named internal pages/tabs inside it. Not Structure Browser tabs, not Browser Bar tabs, and not one Graphical Browser per filter pair.
- The existing UICT ver-03 prototype is the correct architectural direction because it already created the standalone shell and internal pages. The reported remaining issue is Apply: #:NODE241 is not of type BROWSERNODE.
- Stage 0 is only the known-good single Graphical Browser/table/selection/Apply baseline; it is not a multi-page implementation and must not be described as a feature-complete ver-03 base.
- :createAsTab t and sd-dock-graphical-browser were an incorrect interpretation of tabs. Removed both from the active Stage 1 diagnostic source in commit 3518446f579ed6bd496f14fa533f9986cd98e980; Stage 1 is again a standalone single-browser baseline.
- Reviewed existing main-branch knowledge: docs/LESSONS_LEARNED.md LL-007 and docs/ENGINEERING_KNOWLEDGE_BASE.md Section 6 already state the correct internal-tab requirement and prohibit docking/multiple Graphical Browsers. The failure was not preserving/following this recorded requirement before the last change.
- Next step: inspect the original UICT ver-03 Apply bridge and API return/object types; isolate the NODE... versus BROWSERNODE mismatch. Do not alter the standalone UICT shell, page tabs, labels, per-page tables, or filter logic during this investigation.
- Runtime state remains as last reported by user: earlier UICT ver-03 showed standalone window/internal named pages but Apply failed; no claim that the Apply issue is fixed.


## 2026-11-17 – Active VER-03 rebuild: Density table initialization order

- Reorganized the active work around the existing `rebuild/ver-03-stable-restart` branch. No new branch, numbered version, source directory, or command was created.
- Active source remains `src/part-filter/ver-03-rebuild/H871_PART_FILTER_VER_03_REBUILD.lsp`; command remains `H871_PART_FILTER_VER_03_REBUILD`.
- User-confirmed current behavior: standalone Results Browser opens and Part rows can be selected. User reports Density columns are not visible.
- Source inspection confirmed the four table columns and Density display callbacks were already defined. The table root had been assigned after `sd-show-graphical-browser`.
- Focused change: assign the active table and table root, then activate table mode, then show the Browser. Added explicit error messages if the root cannot be resolved/assigned or table mode cannot be activated.
- No changes to Density collector, normalization, filter mapping, BrowserNode row data, row selection, Select All/Clear Selection, or native Apply.
- Static checks completed; edited source still requires runtime confirmation in Modeling 18.1. The user should test on a disposable Assembly copy and confirm column headers and cell values separately.
- Experimental VER-04/05/06/07 branches are not active development bases. Do not create another numbered version for the next iteration.
