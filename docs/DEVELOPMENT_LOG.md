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



## 2026-11-16 – ver-03 Apply diagnostic: expose the native Browser bridge

- User confirmed that the UICT Results window and its result tables now appear, and Select All/Apply callbacks execute, but Apply does not select Parts in the 3D viewport.
- Latest trace proves UICT row selection is read as actual `ELAN::SEL_ITEM` objects and the Modeling User Action is queued. The bridge BrowserNodes are resolved to `G-BROWSER::BROWSERNODE`, but `:is-object-displayed` returned NIL for each node. Browser selection count increased and `:select-and-execute` reported `:SUCCESS`, but this is not proof of viewport selection.
- Created isolated branch `debug/ver03-visible-apply-bridge` from `feature/ver03-uict-apply`.
- Diagnostic-only source change: call `sd-show-graphical-browser` on the temporary Apply bridge immediately after setting its table root and before checking displayed-state / selecting nodes / executing native hand-off. Added trace marker `APPLY/SHOW-BRIDGE-RETURN`.
- The bridge is intentionally left visible during this diagnostic so the user can observe whether it contains the expected Part rows and whether Modeling accepts the selection. This is a temporary second window for diagnosis, not the intended final UX.
- No changes to UICT Results tables, page tabs, selection extraction, Density matching, or ver-01/ver-02.
- Commit: `db0c48de331e565b955728d33a9d2b7ec4608bbc`.
- Runtime status: NOT TESTED yet in Modeling 18.1. Do not mark Apply fixed until the actual matching Parts are visibly selected in the 3D viewport. Test only on a disposable Assembly copy.



## 2026-11-16 – ver-03 Apply confirmed; hide bridge after hand-off

- User runtime-tested the visible-bridge diagnostic in Creo Elements/Direct Modeling 18.1.
- Confirmed result: the temporary Apply bridge appears; pressing its Apply action selects the intended Part in the 3D viewport. This is the first user-confirmed proof that the native `:select-and-execute` hand-off works when the bridge Browser is displayed.
- Root-cause direction is now confirmed: the bridge cannot remain hidden during native selection hand-off. The earlier trace's `:SUCCESS` alone was insufficient; the viewport result is the acceptance evidence.
- Follow-up refinement committed on the same isolated branch: keep the bridge visible through `:select-and-execute`, then call `sd-hide-graphical-browser` only after the hand-off returns without the explicit `:error` status. Added trace marker `APPLY/HIDE-BRIDGE-AFTER-HANDOFF`.
- Intended result: temporary bridge is shown only while Apply runs and disappears immediately after a successful hand-off, leaving the 3D Part selection intact. This refinement is NOT YET runtime-tested; verify viewport selection remains after the bridge hides and that repeated Apply still works.
- Source commit: `0076b6cbca7e6b18d823db4f8dc7f84082795f27`.
- Do not merge to main until the post-handoff hide behavior and repeat-Apply behavior are confirmed in Modeling 18.1.


## 2026-11-16 – Apply bridge hide call did not close the window; try explicit destroy

- User tested source commit `0076b6cbca7e6b18d823db4f8dc7f84082795f27`: the Apply bridge appears and its Apply action correctly selects the intended Part in the 3D viewport, but the bridge window remains visible afterward.
- This proves the selection hand-off remains successful, but the prior post-handoff `sd-hide-graphical-browser` call did not achieve the intended UI cleanup in the user's Modeling 18.1 runtime.
- Narrow follow-up on the isolated debug branch: after the successful `:select-and-execute` hand-off, explicitly call `sd-destroy-graphical-browser` for the temporary bridge and then `sd-destroy-browser-tree` for its temporary tree. Both cleanup calls are guarded with `ignore-errors` so a cleanup failure cannot undo or interrupt the already-completed Part selection.
- Added trace markers `APPLY/DESTROY-BRIDGE-AFTER-HANDOFF` and `APPLY/DESTROY-BRIDGE-TREE-AFTER-HANDOFF`.
- No change to UICT Results tables/tabs, selection extraction, Density matching, or the native hand-off sequence before it completes.
- Source commit: `c1f6f79ba6e53147d93bfd4c32d8ce119994c1c6`.
- Runtime status: NOT TESTED. User must verify (1) Part remains selected in 3D, (2) bridge window closes, and (3) a second Apply works. Do not merge to main until confirmed.


## 2026-11-16 – Prevent Results row double-click from auto-running Apply

- User's latest trace shows repeated `APPLY/DOUBLE-CLICK-CALLBACK` immediately after Results interaction, followed by queuing and running the native Apply action. This means the Display Table's double-click callback is wired to Apply; a double-click/rapid row interaction can unexpectedly launch the bridge, trigger repeated heavy work, and make the cursor appear busy.
- The trace confirms the selection callback itself is separate and correctly receives selected `ELAN::SEL_ITEM` values. The dedicated Apply pushbutton is already wired to `h871-pf-v03-apply`.
- Narrow fix: remove `:doubleClickAction 'h871-pf-v03-double-click` from both Display Table creation paths (initial page creation and table recreation). Selecting a row now only changes table selection/status; Apply must be explicitly invoked using the Apply button. No automatic Apply on double-click.
- Native bridge/handoff and destroy sequence are deliberately unchanged in this patch. The trace's `:SUCCESS` and destroy return `T` do not prove viewport selection; runtime viewport verification remains mandatory.
- Source commit: `e357cc7f3ecbd1fc04d0e6870f480450e8a1f35b`.
- Runtime status: NOT TESTED. Verify single-click and multi-select only update selection/status without opening a bridge or spinning; then press Apply once and verify the intended Parts are selected in the 3D viewport and the temporary bridge closes.


## 2026-11-16 – Remove custom callback from Display Table row selection

- User retested the revision that removed automatic Apply on double-click. The Results interaction still produces a brief busy cursor with no visible result; the previous patch therefore did not resolve the reported symptom.
- Source review found a second custom callback on every row-selection event: `:selectionAction 'h871-pf-v03-table-selection-changed`. It queries the current Display Table selection and updates a UICT text control while the native table is processing the selection.
- Narrow isolation change: removed this callback from both the initial Display Table creation path and the recovery/recreation path. Row selection is now left entirely to the native Display Table; the Apply button still reads the selected rows when explicitly pressed. Select All/Clear Selection still update the status text through their own button actions.
- Also confirmed that no `:doubleClickAction` binding remains and the explicit Apply button binding remains present.
- Source commit: `dd266a318eaa6d9f4699ad3435859e4bb5b037f0`.
- Static checks: exactly two selection callback bindings removed; no selectionAction or doubleClickAction bindings remain; Apply binding and selected-row reader remain. No Creo LISP runtime test has been performed.
- Next acceptance test: single-click a row and Ctrl+click another row. The table should visibly mark the selected rows without a busy pause or launching the Apply bridge. Then press Apply once and verify actual 3D viewport selection separately.


## 2026-11-16 – Restore the proven native Graphical Browser Apply action

- User supplied a fresh trace after testing in a completely new Modeling window. Results collection and logical-table refresh completed; UICT returned 1, 2 and 8 selected `ELAN::SEL_ITEM` values on separate Apply runs.
- For each run, the bridge was shown, BrowserNodes were resolved, browser selection counts matched the requested number, and programmatic `:select-and-execute` returned `:SUCCESS`. The bridge and tree were then destroyed. The trace still does not prove that the intended Parts entered the 3D viewport.
- Critical comparison with the user-confirmed ver-02 baseline: ver-02 configures `:okButtonLabel "Apply"` and lets the Graphical Browser's native OK action perform `:select-and-execute`. The user had separately confirmed that manually pressing Apply in the visible bridge selected the intended Part in the viewport.
- The current ver-03 path instead invoked `:select-and-execute` programmatically from a custom User Action and immediately destroyed the bridge. Although the command returned `:SUCCESS`, this is not equivalent evidence to the successful native-button interaction.
- Narrow correction: keep the bridge visible with its selected rows and stop invoking `:select-and-execute` programmatically. The user must press the bridge's built-in **Apply** button, allowing Creo's native Graphical Browser OK action to perform the hand-off exactly as in ver-02. The bridge is no longer destroyed before that native action.
- Added trace marker `APPLY/READY-FOR-NATIVE-OK` and an on-screen instruction identifying the bridge's Apply button.
- Source commit: `875c89febb0a3409c2a7744e07aa690e1278d5f8`.
- Static checks: native browser creation still has `:okButtonLabel "Apply"`; programmatic `:select-and-execute` call removed; immediate bridge/tree destroy removed; selected BrowserNode setup retained. No Modeling 18.1 runtime test yet.
- Runtime acceptance: click the Results window's Apply once; confirm the Native Apply Bridge appears with the expected highlighted rows; then click **Apply inside that bridge**. Verify the matching Parts become selected in the 3D viewport. Only after that is confirmed should bridge cleanup be addressed.


## 2026-11-16 – VER-05 rebuild from VER-03 filter with native multi-Browser manager

- User explicitly requested a clean restart from the VER-03 source revision on `debug/ver03-visible-apply-bridge`, where the visible Graphical Browser's native Apply button was user-confirmed to select Parts in the 3D viewport.
- Created isolated branch `rebuild/ver05-ver03-filter-native-multi-browser`. No changes to `main`, VER-01, VER-02, VER-03 or VER-04.
- Preserved the complete VER-03 Search dialog layout and choice mappings (Assembly, Machining Process, Material, Process Code and Material Code), numeric Density comparison, report generation and Assembly traversal.
- Replaced the Results UICT Display Table / logical-table architecture entirely. VER-05 contains no `sd-create-display-table-control`, `sd-create-logical-table`, `sd-get-display-table-selection`, or logical-table update calls.
- New Manager is one dialog shell containing per-pair text controls and Open Browser pushbuttons. It is not a Display Table.
- Each Density Instance + Density Base pair owns a separate Graphical Browser and Browser Tree. Names include pair codes and a generation number. Each Browser Tree update callback is a separately interned function symbol whose function is a closure over that Browser's tree name, pair label and copied Part result list; there is no shared active-pair/global-parts variable.
- Browser columns are Part Name, Density Instance, Density Base and Assembly Path. Select All / Clear Selection use the native Graphical Browser commands. The Browser's own native `:okButtonLabel "Apply"` is the direct Apply mechanism; the temporary Apply Bridge has been removed from this architecture.
- Same-pair refresh creates and displays the replacement Browser before updating the Manager entry and destroying only the previous Browser/Tree for that same pair. A no-match search does not replace existing pair data.
- Added `src/part-filter/ver-05/README.md` with load instructions, architecture, mapping, safety guidance and runtime acceptance checklist.
- Commits: `d47719ed1adafad1dc452400405caee705173e23` (initial source), `64f1c60136f7e62c279489194f565e526a816bd8` (restore missing VER-03 filter engine and complete architecture), `d5fc20b140d62fc287311c103bbe643bea46ebb0` (manager row layout), `d7ec93de2ca814e54ee026fee1b551d6b50b0736` (README).
- Static audit: balanced parentheses, no unterminated strings, no duplicate local DEFUN names, all referenced `h871-pf-v05-*` functions defined, no UICT Display Table/logical-table APIs, native Graphical Browser Apply configured, and per-Browser callback closures present.
- Runtime status: NOT TESTED in Modeling 18.1. The development environment cannot execute Creo, so it cannot truthfully supply the requested live runtime result. Multiple simultaneous Browsers, callback timing, UICT manager controls, native Apply and the reported fatal `0xc00000fd` behavior remain runtime acceptance items.
- Important known risk: the VER-03 recursive Assembly collector was deliberately retained to preserve the exact filter engine. An earlier iterative traversal experiment did not resolve the reported `0xc00000fd`; root cause remains unknown. Do not describe the crash as fixed. Test only on a disposable Assembly copy.

### VER-05 follow-up – compact Manager layout and final static audit

- Changed the Manager from one pair per row to a two-column layout, supporting up to 36 Density-pair entries in one Modeling session while keeping the Manager grid bounded.
- Fixed the example load path to the actual `H871_PART_FILTER_VER_05_MULTI_BROWSER.lsp` filename.
- Final source audit after these changes: 564 lines; balanced parentheses; no unterminated strings; no duplicate local DEFUN names; no missing local `h871-pf-v05-*` definitions; no UICT Display Table/logical-table APIs or Apply Bridge; both Density fields are compared; native Graphical Browser Apply and per-Browser callback closures are present.
- Latest source content SHA: `97b754f71f2ade1bbbbf6dbf7f06220061c75f47`.
- Runtime remains pending. Static source checks do not validate Creo 18.1 API behavior or prove the `0xc00000fd` issue is fixed.

### VER-05 Manager control validation and callback lifecycle follow-up

- Manager text controls and pushbuttons are now checked by their UICT control handles after creation, rather than assuming the creation/set-text API return value is truthy.
- Added cleanup of obsolete per-Browser callback function bindings after the associated old Browser and Tree are destroyed, including Browser creation failure paths.
- Final source content SHA after these follow-ups: `f0c0f3dc89bbc6e620b19c685b44a6a91eccec41` (590 lines).
- Static checks re-run: balanced parentheses, closed strings, no duplicate local DEFUN names, no missing local helper definitions, and no Display Table/logical-table/Apply-Bridge code.
- Runtime status unchanged: NOT TESTED in Modeling 18.1.

## 2026-11-16 – VER-05 first successful native multi-Browser runtime test

User tested VER-05 in Creo Elements/Direct Modeling 18.1 and confirmed that filtering creates separate, independent Graphical Browser windows for each result type/pair. Selecting an individual Part works; double-click selection and Select All followed by native Apply both work as well as the VER-02 workflow, and Apply correctly selects the Parts in the 3D viewport.

The separate H871 Graphic/Manager window appears in a screen corner but is too small to read all displayed information. Treat this as the next focused UI/layout issue. Preserve the working Browser windows, row-selection behavior, Select All and native Apply implementation. Do not refactor the filter engine or Browser callbacks while adjusting Manager dimensions/layout.

User-provided trace:

~~~text
H871 VER-05 TRACE START
RUN/BEGIN | (ELAN::SEL_ITEM 1 6061)
COLLECT/BEGIN | "/05.cum-ve-sinh_do"
COLLECT/PROGRESS | 100
COLLECT/PROGRESS | 200
COLLECT/PROGRESS | 300
COLLECT/PROGRESS | 400
COLLECT/PROGRESS | 500
COLLECT/COMPLETE | (0 530)
~~~

Collection reached its completion marker after visiting progress milestones through 500; final reported tuple is (0 530). Its fields are not interpreted because their exact meaning is not established. No fatal exception was reported in this test. This is positive runtime evidence for this tested case, not proof that the previously reported 0xc00000fd is universally resolved.

**Status:** native multi-Browser selection/Apply is now user-confirmed in Modeling 18.1 for the tested workflow. Manager readability and the remaining multi-window lifecycle regression cases are still open.


## 2026-11-16 – VER-05 H871 Graphic/Manager sizing correction

After the user confirmed native multi-Browser selection and Apply, the next reported issue was that the separate H871 Graphic/Manager window appeared too small to read. Source inspection found a unit mismatch: `sd-append-grid-area` was configured as 112 × 82 pixels, but child control positions/sizes were authored in grid units with `:cellSize 10,10`. The two-column layout uses coordinates up to roughly 112 × 75 grid units, so the original pixel area exposed only about 11 × 8 grid units.

Changed only the Manager grid area's pixel dimensions to 1120 × 820. Kept the cell size, control coordinates, row arrangement, filter logic, per-Browser callbacks, independent Graphical Browser windows and native Apply path unchanged.

The sizing change is committed but awaits user runtime confirmation in Modeling 18.1. Acceptance: Manager displays all populated rows and Open buttons without clipping and the text is readable; verify Browser selection and native Apply still behave exactly as before.


## 2026-11-16 – VER-05 audit and Open-action fatal exception follow-up

A fresh source/documentation audit was performed on branch `rebuild/ver05-ver03-filter-native-multi-browser`.

- Audited source: `src/part-filter/ver-05/H871_PART_FILTER_VER_05_MULTI_BROWSER.lsp`, 590 lines, blob SHA `5f69073e223a69267c7fec8fa350c4b4604c3189`.
- Static checks: balanced parentheses (final depth 0; no negative depth), no unterminated strings, 35 local DEFUN definitions with no duplicate names, native `:okButtonLabel "Apply"` retained, exact matching still checks both Density Instance and Density Base, existing `/1000.0` normalization retained, per-Browser callback closure retained, and no UICT Display Table/logical-table or Apply-Bridge calls found.
- The collector remains recursive. This was deliberately retained from the VER-03 search engine; the earlier `0xc00000fd` fatal exception is not considered fixed.
- Runtime-confirmed baseline remains: independent result Browsers, individual/double-click row selection, Select All and native Apply to the 3D viewport.
- Manager grid-area correction is now runtime-confirmed at the specific level the user reported: the H871 Graphic window became larger. Full readability/all rows and buttons still need a complete visual check.
- User reported a fatal `0xc00000fd` exception after clicking an Open action intended to show another Browser. The exact UI control/action path has not yet been isolated. Current source's Manager Open handler calls `sd-show-graphical-browser` on the stored Browser name; this is a candidate path to inspect, not a proven cause. Do not claim the exception is fixed or attribute it conclusively to recursion/callbacks.
- Safe handling: do not repeat the failing Open action on the only/original customer model. If reproducing, use a disposable Assembly copy and preserve the trace/crash details.

No production LISP code was changed in this audit. This entry records status and evidence only.
