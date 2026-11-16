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



## 2026-11-16 – ver-04 single Graphical Browser multi-page diagnostic

- Re-read the repository's AI handover, project context, skill package, API register, technical decisions, known issues and lessons before changing direction.
- Reconfirmed from the exact ver-02 source that the user-facing Results Graphical Browser itself owns row selection and native Apply. There is no separate Apply bridge in ver-02.
- Reconfirmed from ver-03 source that UICT Display Table selection is a different selection context. The hidden Browser bridge and its programmatic :select-and-execute attempts are not a valid replacement.
- Inspected PTC Graphical Browser API: one Browser Tree can hold multiple page roots; a table displays the children of its active table root; sd-browser-add-popup-entry can add dynamic popup submenus with string client data.
- Added diagnostic src/part-filter/ver-04/diagnostics/H871_PF_V04_SINGLE_BROWSER_PAGES_DIAG.lsp.
- Candidate architecture: one visible Graphical Browser, one table, one root per Density pair, page switching via Previous/Next and a dynamic Results Pages submenu, page-local selection path save/restore, and the Browser's unmodified native Apply.
- The diagnostic reuses existing ver-03 page data and hides the ver-03 UICT Results shell while the native Browser is displayed. It does not change ver-03 production source, search logic, mappings, normalization, or ver-02.
- Static validation: 471 lines; balanced parentheses (depth 0, minimum 0); no unterminated strings; all local h871-pf-v04-* calls resolve; native :okButtonLabel "Apply" is present and no :okButtonAction override is supplied.
- Runtime status: not loaded or functionally tested in Modeling 18.1. Horizontal tab UI is not yet implemented in this candidate. Native Apply must be verified by selecting actual Parts in the viewport.


## 2026-11-16 – ver-04 first Modeling 18.1 test and lifecycle recovery

- User confirmed the diagnostic hides the old UICT shell and opens exactly one native Graphical Browser Results window.
- The active ver-03 page's rows appeared in the Browser. The trace copied two page records: CNC-SS400 (8 Parts) and CG-SS400 (2 Parts).
- The user could select rows in the new Browser, but page navigation back to the old UICT window was not available through the attempted interaction.
- A second invocation failed with Browser Tree H871-PF-V04-SINGLE-RESULTS-TREE already exists. The trace stopped after DIAG/PAGES-COPIED, so page switching, selection restoration and native Apply have not yet been tested.
- Root cause: the diagnostic had no successful-run cleanup path for its named Browser/Tree objects. Hiding the Browser and preserving the old UICT shell were not enough to make the diagnostic re-entrant.
- Patched ver-04 to destroy the old Browser before its Tree before rebuilding; Close Results now invokes the same cleanup and restores ver-03 UICT. Added H871_PF_V04_RESTORE_UICT_RESULTS as a recovery command.
- Static check passed: balanced parentheses, no negative nesting, no unterminated strings.
- **Runtime status:** lifecycle patch committed but not yet retested in Creo 18.1. Native Apply and page switching remain unverified. ver-01/ver-02/ver-03 production sources and filter logic were not changed.


## 2026-11-16 – ver-04 persistent return path from UICT Results

- User confirmed the lifecycle patch: ver-04 opens the native Results Browser; Close Results returns to the existing ver-03 UICT Results window. The named Browser/Tree can now be reset and recreated.
- The new trace confirms the Browser Tree contains two page roots and ten Part nodes; the Results Pages popup entries are added; the active root is changed to page 2; one selected row is restored; and the page is marked active. This is evidence for page-root switching during initialization, not yet proof that the user-operated Previous/Next or popup navigation works.
- The trace's separate ver-03 Apply log includes one non-NIL `SELECT-AND-EXECUTE-SUCCESS-CONTEXT` containing an `ELAN::SEL_ITEM`. It is a stronger diagnostic signal but does not prove the user's 3D viewport selection changed.
- Implemented a persistent `Open Native Results` pushbutton in the ver-03 UICT shell. It is installed once in the existing shell grid and calls the ver-04 diagnostic entry point. After Close Results returns to UICT, the user can reopen the native Browser by clicking the button rather than typing the LISP command again.
- Added page navigation request/target trace markers to distinguish button callback execution from initial page activation.
- Static checks passed: balanced parentheses, no negative nesting and no unterminated strings. Source commit: 21ddfb945a40f2361cb09439522387f90f6fac54.
- Runtime verification pending: button creation/placement and callback, repeat close/reopen, Previous/Next and popup switching, and actual viewport Apply. No ver-03 production source, ver-02 baseline or Density filtering logic was changed.

## 2026-11-16 – ver-05 self-contained single Results Browser candidate

- Reaffirmed the user's unchanged product requirement: one Results window only, with ver-02's direct native row selection/Apply and ver-03's multiple Density-pair pages. ver-04 UICT switching and launcher are diagnostic-only and not the final workflow.
- Added `src/part-filter/ver-05/H871_PART_FILTER_VER_05.lsp`.
- Removed dependency on ver-03 UICT globals/page registry. ver-05 owns the Assembly search, Process/Material mapping, page registry, Browser Tree, Graphical Browser, page navigation and selection state.
- Preserved ver-02's recursive Assembly collector, numeric Instance/Base comparison, /1000 normalization and user mapping values. No filter predicate changes were introduced.
- One page root is created per Density pair; same-pair search refreshes that page; new pair adds a page; no-match leaves prior pages intact.
- Uses one named Graphical Browser and one named Browser Tree, with Previous/Next and a dynamic Results Pages popup. The native Apply button is left at its default action; no custom :okButtonAction and no hidden Apply bridge.
- Page-local selected paths are saved/restored when navigating. A successful new search rebuilds the named Browser/Tree from the in-memory page registry; no extra Results window or manual reopen action is intended.
- Static checks: 510 lines; balanced parentheses; no negative nesting; no unterminated strings; 40 local helper definitions; no unresolved local helper calls; no ver-03/UICT globals; exact mappings present; native Apply default retained.
- Runtime status: not loaded or functionally tested in Creo Elements/Direct Modeling 18.1. Native Apply, search lifecycle, page navigation, selection restore and no-match preservation require user test on a disposable model copy.
- Horizontal tab strip remains unimplemented; current same-window page navigation is Previous/Next + Results Pages popup.

### ver-05 refinement – horizontal page buttons in the single Browser

- Replaced the Previous/Next toolbar pair with a dynamic Graphical Browser `:modeMenu` row: one page button per stored Density pair.
- The active page's button name is supplied using `:modeMenuInitialButton`; each page button invokes the same Browser page activation function.
- Select All and Clear Selection remain in the Browser button menu. The Results Pages popup remains as an alternate same-window selector.
- The detailed PTC modeMenu reference is from a later release, so this is static-checked but not yet verified in Modeling 18.1. Do not claim a final tab strip until the user confirms button rendering and switching.



## 2026-11-16 – ver-05 critical table-root isolation fix

- Re-read the latest ver-05 source and compare against the known-good ver-02 Apply architecture and the ver-03 page-local selection requirement.
- Found a critical page-switch defect: h871-pf-v05-activate-page set a new table root but did not clear the previous root. Graphical Browser can retain multiple table roots, so the table could show rows from more than one Density page; Select All and native Apply would no longer be safely page-scoped.
- Updated src/part-filter/ver-05/H871_PART_FILTER_VER_05.lsp: buffer redraw, clear Browser selection, clear all table roots, set only the requested page root, resume redraw, and trace :number-of-table-roots.
- Source commit: c510c7c76243f9ceed5430eee86e68111d183f3a.
- Static checks passed: balanced parentheses/strings; :clear-table-roots present; native :okButtonLabel "Apply" remains default with no :okButtonAction; all Density mappings unchanged.
- PTC 20.6 reference documents the command sequence. Modeling 18.1 runtime compatibility remains unverified.
- Remaining acceptance gaps: horizontal page button strip rendering and callback, root count exactly one after each switch, page-local selection save/restore, same-pair refresh, no-match preservation, Select All/Clear Selection, and actual 3D viewport Apply.
