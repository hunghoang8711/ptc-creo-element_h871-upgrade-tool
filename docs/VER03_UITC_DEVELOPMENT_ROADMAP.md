# ver-03 UICT Development Roadmap

**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Development branch:** `feature/ver03-uict-apply`  
**Base:** `main` at `bdf0ba8ddda82ae0e0e3a6e8232b81147e53e532`  
**Canonical UICT source:** `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp`  
**Last UICT source revision associated with user-confirmed Results UI:** `8c0a1cd56f25f125958080b3ab6316e55827b141`

## 1. Product requirement — do not reinterpret

The required result interface is:

- One independent, standalone Results window.
- Multiple clearly named internal tabs/pages inside that same window.
- One page per numeric Density Instance + Density Base pair.
- Page caption uses the Process-Material convention, e.g. `CNC-SUS304`.
- Searching a new pair creates a new page in the same Results window.
- Searching an existing pair refreshes only that page.
- A no-match search must not erase or modify existing valid pages.
- Each page owns its own result data and selection state.
- Select All, Clear Selection and Apply operate only on the intended page.
- Do not dock into Structure Browser/Browser Bar.
- Do not create one Graphical Browser per query.
- Do not reparent a Graphical Browser into a host shell.

## 2. Version boundaries

| Source | Proven role | Do not assume |
|---|---|---|
| ver-02 | User-confirmed native Graphical Browser, row selection and native Apply baseline | Does not provide multiple internal result pages |
| Stage 0 | Isolated clone of ver-02; user confirmed Results, Select All, individual selection and Apply | Not a multi-page implementation |
| Stage 1 diagnostic | Same single-browser behavior as Stage 0 under isolated symbols | Not a tab implementation |
| ver-03 UICT | User confirmed standalone Results window, named internal tabs, result table and Apply button appear | Apply hand-off is not confirmed; later Search fatal exception is unresolved |

The canonical development base is the UICT ver-03 source on this branch. Stage 0/1 may be consulted only as a reference for known-good native Graphical Browser behavior and API call patterns. Do not replace the UICT architecture with Stage 0/1.

## 3. Verified filter convention — preserve exactly

Search uses numeric Density properties, not UI labels:

- Machining Process -> Density Instance: CNC=1, KH=2, CG=3, COVER=4.
- Material -> Density Base: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
- `1-304` means CNC-SUS304.
- API Density values are normalized by dividing by 1000.
- Match requires both Instance AND Base to match.

Do not change mappings, normalization or the search predicate while investigating UICT Apply.

## 4. Current evidence and unresolved failures

### Results UI

User confirmed the UICT ver-03 Results window appears in Modeling 18.1, contains internal tabs with clear names, displays Part Name/Density columns and includes an Apply button.

### Apply

User reported:

`LISP error: #:NODE241 is not of type "BROWSERNODE".`

Source diagnosis:
- `sd-create-browsernode` returns a symbolic node ID.
- The active UICT bridge stored that ID as if it were a BrowserNode structure.
- `:set-object-selection` requires a BrowserNode structure.
- PTC 20.7 documentation describes `sd-get-browsernode-struct` as the resolver, but exact Modeling 18.1 compatibility of the complete bridge remains unverified.

A BrowserNode-resolution candidate was previously committed and then rolled back. It was not user-confirmed. Do not treat it as a working fix or blindly repeat it.

### Search fatal exception

User reported Modeling fatal exception `0xC00000FD` after pressing Search OK, before Results UI appeared. An iterative Assembly traversal candidate did not fix it and was rolled back. The recursive collector is therefore not a confirmed root cause.

The UICT source at commit `8c0a1cd56f25f125958080b3ab6316e55827b141` includes stage trace markers writing to:

`H871_PART_FILTER_VER_03_TRACE.txt`

The trace file (especially the last marker) is required to localize the Search failure before changing the Search pipeline again. Do not infer a root cause from the exception code alone.

## 5. Development sequence

### Phase A — protect and establish the UICT baseline

- Keep ver-01 and ver-02 unchanged.
- Keep the Stage 0/1 branch and files unchanged.
- Work only on `feature/ver03-uict-apply`.
- Preserve the one-window/internal-tabs UICT architecture.
- Do not edit Search traversal, Density mapping, page naming, logical-table refresh and Apply in the same change.

### Phase B — isolate Search stability

- Inspect the trace file from the exact failing Modeling 18.1 session.
- Identify the last completed/entered stage.
- Reproduce only on a disposable model copy, never the original customer model.
- Change only the failing stage.
- Confirm Search can create the UICT window and both a new-pair page and same-pair refresh work before touching Apply.

### Phase C — isolate Apply hand-off

- Preserve the UICT table, tabs, row selection and hidden Part-object column.
- Inspect the return type from `sd-create-browsernode` and the result of `sd-get-browsernode-struct` in the actual 18.1 runtime.
- Verify each node resolves to a BrowserNode structure before `:set-object-selection`.
- Do not pass a Symbol such as `#:NODE...` to a BrowserNode-typed command.
- If the bridge still fails, investigate a native 18.1 selection hand-off; do not invent alternate API calls.
- Test one selected row, multiple selected rows, Select All, Clear Selection, and selection isolation after switching tabs.

### Phase D — improve UI/data lifecycle

Only after Phases B and C pass:
- Improve table column widths, status line and page layout without replacing the UICT architecture.
- Ensure page records survive LISP reload safely or rebuild stale runtime handles deterministically.
- Define explicit page identity from numeric Instance+Base, not from display caption alone.
- Same pair: update existing page data and clear stale object selections.
- New pair: add a page; do not overwrite another pair.
- No match: preserve all existing pages.
- Add cleanup/close/reload behavior only after control and logical-table lifetimes are verified in 18.1.

## 6. Mandatory regression checklist

Every candidate source must be checked for:
1. Static LISP parentheses/string balance.
2. Exact changed-function diff; no unrelated edits.
3. Search CNC-SUS304 (numeric Instance=1, Base=304).
4. Search a second known pair and verify a second internal tab appears in the same independent window.
5. Repeat the first pair and verify only its page refreshes.
6. No-match search preserves existing tabs/data.
7. Select one row and Apply: only that Part becomes selected in Modeling.
8. Select multiple rows and Apply: only those Parts become selected.
9. Select All / Clear Selection affect only the active page.
10. Switch tabs and verify page-specific results and selection.
11. Verify no Browser Bar docking, no Structure Browser page creation and no extra Results windows.

Runtime status must always be recorded as **user-tested**, **not yet tested**, or **failed**. Static inspection is not runtime verification.

## 7. Explicit no-repeat rules

- Never replace the UICT Results window with a single Graphical Browser as the feature implementation.
- Never interpret “tabs” as Browser Bar tabs or tabs inside Structure Browser.
- Never create one Graphical Browser per filter pair.
- Never use the failed host-shell/reparenting architecture.
- Never override the native ver-02 Apply flow without a proven need and runtime test.
- Never claim the Apply bridge is fixed based only on a later-release PTC manual.
- Never claim the Search fatal exception is fixed by the iterative traversal experiment; user testing disproved that candidate.
- Never edit ver-01/ver-02 or the known-good Stage 0/1 baselines during this work.

## 8. Immediate next evidence needed

Before another Search-pipeline edit, obtain the `H871_PART_FILTER_VER_03_TRACE.txt` produced by the exact Modeling 18.1 session where Search failed. If the trace was not produced or is empty, instrument a minimal isolated test with a method proven to write a file in the user's 18.1 environment; do not swallow all trace errors silently.

The first code experiment after Search is stable must be limited to the BrowserNode ID-to-structure conversion in the Apply bridge. Record the exact source diff and test outcome separately from Search stability.


## 9. Diagnostic trace writer is not validated — 2026-11-16

User reports that every generated `H871_PART_FILTER_VER_03_TRACE.txt` is 0 KB.

Consequences:
- The existing trace writer is **not a usable diagnostic source** in the user's Modeling 18.1 environment.
- The trace helper wraps all file operations in `ignore-errors` and returns true even if opening/writing fails. Its success return is therefore meaningless.
- Do not ask the user to resend the same empty trace file.
- Do not infer the Search failure stage from an empty trace.
- Do not continue changing the Search collector or UICT creation sequence based on guesses.

Next diagnostic experiment must first validate the output mechanism independently:
1. Use a minimal standalone LISP command that writes a short fixed line to a new uniquely named file in a known writable directory.
2. Explicitly call `force-output` and close the stream; do not swallow file errors.
3. Report the exact target pathname and surface any open/write/close error to the user.
4. Confirm the file contains the test line before integrating diagnostics into ver-03.
5. If file output cannot be validated, use an alternative visible diagnostic channel with a small number of explicit stage checkpoints. Avoid high-volume messages and avoid changing filtering or UICT behavior.

This is a diagnostic-infrastructure failure, not evidence that the filter or Apply logic has changed. Search root cause remains unknown.


## 10. Standalone trace-writer test prepared — 2026-11-16

Added `src/diagnostics/H871_TRACE_WRITE_TEST.lsp` on this branch.

- Command: `H871_PF_V03_TRACE_WRITE_TEST`
- Expected output: `H871_TRACE_WRITE_TEST.txt` in `(user-homedir-pathname)`.
- Expected content: `H871 TRACE WRITE TEST OK - Modeling 18.1`
- Uses `with-open-file`, `format`, and `force-output`; the stream is closed before success is displayed.
- No `ignore-errors`: failures should surface as actual LISP errors.
- Does not load or modify the Part Filter source.
- Static inspection only; user runtime validation is pending.

After this test passes, integrate the same proven writer into ver-03 and add a few stage checkpoints. Then use those checkpoints to isolate Search. Only after Search is stable should Apply be changed.


## 11. Trace writer validated and integrated — 2026-11-16

The user ran `H871_PF_V03_TRACE_WRITE_TEST` in Creo Modeling 18.1 and confirmed the visible success text: `H871 TRACE WRITE TEST OK - Modeling 18.1`.

Consequences:
- The home-directory file output mechanism using `with-open-file`, `format`, and `force-output` is now user-validated in the target runtime.
- The ver-03 trace helper now uses that same mechanism, appends each checkpoint, flushes after each line, and no longer suppresses errors with `ignore-errors`.
- Each Search run resets the trace file before writing its first checkpoint.
- Added a traversal counter and a progress checkpoint every 100 visited assembly objects. This is diagnostic-only; recursive traversal, matching predicate, numeric normalization, and UI architecture remain unchanged.
- Runtime status: trace writer test = **user-tested success**; integrated ver-03 trace and traversal checkpoints = **not yet tested** in Modeling 18.1.

Next test: load this updated ver-03 source, run one known-positive search (CNC / SUS304), and if it fails or terminates, send the generated `H871_PART_FILTER_VER_03_TRACE.txt`. The last checkpoint will show whether failure occurs before collection, during traversal (including last 100-object progress count), report writing, or UICT creation. Do not change the Apply bridge until Search behavior is isolated.


## 12. Search trace isolates logical-table content update — 2026-11-16

The user tested the integrated trace in Creo Elements/Direct Modeling 18.1 and supplied this final sequence:

- Assembly traversal completed: 500 visited objects.
- Two matching Parts were found (RUN/COLLECT-DONE | 2).
- The result report was written successfully.
- The standalone Results shell was created successfully.
- A new internal page was inserted; logical table, status control, display table and all three buttons were created.
- The page was made current.
- The refresh passed logical-table and display-table existence checks.
- The final trace marker was REFRESH/CHANGE-CONTENTS/BEGIN | ("H871-PF-V03-PAGE-2-LOGICAL-TABLE" 2).

Evidence-based conclusion:
- The current failure is localized to the sd-change-logical-table-contents call or the automatic Display Table update it triggers. The trace does not yet distinguish those possibilities.
- Assembly recursion, matching, report writing, shell creation and page/control creation are not the failing stages in this run.
- PTC Integration Kit documentation for later releases describes sd-change-logical-table-contents as taking a list of rows, one list per row, with one value per logical-table column. It also documents nil column type as untyped and able to hold arbitrary Lisp objects. This supports the intended six-column row design, including the hidden Part-object value, but does not prove Modeling 18.1 compatibility.
- Do not remove the hidden Part-object column or change the Apply bridge based on this trace alone.
- Do not change the numeric filter, recursive collector, page architecture or Apply bridge during this diagnostic step.

Diagnostic-only source update:
- Added REFRESH/CONTENTS-SHAPE before the update call. It records row count, each row's element count, and the Lisp type of each cell without dumping object values.
- Added REFRESH/CHANGE-CONTENTS/RETURN immediately after the API call to record its return value if control returns normally.
- No table schema, row data, search logic, selection behavior or UI architecture was changed.
- Source commit: b40f77b6d5e1b5573591ef7c33df3e4b40dc3cd0.

Next runtime test:
1. Load the updated canonical ver-03 source from feature/ver03-uict-apply.
2. Run the same known-positive CNC / SUS304 search on a disposable/test assembly.
3. Send the new trace and the exact Modeling error text, if an error appears.
4. Interpret the next trace:
   - No CONTENTS-SHAPE: failure occurred before the new shape logger.
   - CONTENTS-SHAPE but no CHANGE-CONTENTS/RETURN: failure is inside the API call or its synchronous display-table refresh.
   - CHANGE-CONTENTS/RETURN | NIL: API returned failure normally; inspect table definition/row schema.
   - CHANGE-CONTENTS/RETURN | T: proceed to inspect selection reset and post-refresh UI.
Runtime status: source change is committed; not yet tested in Modeling 18.1.


## 13. Results UI confirmed stable; BrowserNode Apply fix candidate — 2026-11-16

The user has now confirmed the following in Creo Elements/Direct Modeling 18.1:
- The standalone Results window displays the Part Results table correctly.
- Searching a new machining-process/material pair creates a new internal page.
- All pages retain their corresponding result data.
- Select All highlights all rows on the active page.
- The remaining interaction failures are double-click-to-select and Apply-to-select-in-3D.
- Apply reports: `LISP error: #:NODE289 is not of type "BROWSERNODE".`

Evidence-based diagnosis:
- In the current source, `sd-create-browsernode` return values were stored in `*h871-pf-v03-apply-nodes*` and passed directly to `:set-object-selection`.
- PTC Integration Kit Graphical Browser documentation explicitly states that `sd-create-browsernode` returns a symbolic node name, while `sd-get-browsernode-struct(tree-name, node-name)` returns the BrowserNode structure. The PTC 20.7 documentation gives a direct example of this conversion. This explains the exact Symbol-vs-BrowserNode error; Modeling 18.1 runtime compatibility still requires user testing.
- The Results UI, collector, numeric Density matching, table schema and internal-page architecture are now user-confirmed working and must remain unchanged.

Candidate source change on `feature/ver03-uict-apply`:
- Commit: `f92834af7c28fa172768f552431bb06315b72ee6`
- Blob: `c55f008127db50658191b447b43d6e8325429caa`
- In `h871-pf-v03-native-apply`, each symbolic child node ID is now resolved with `sd-get-browsernode-struct` before being passed to `:set-object-selection`. A missing structure produces a clear H871 error instead of passing an invalid value.
- Added `h871-pf-v03-double-click`, which receives the Display Table name, finds its owning page and invokes that page's Apply handler.
- Wired `:doubleClickAction 'h871-pf-v03-double-click` into both Display Table creation paths (new page and restored table).
- No changes to search, Density mappings/normalization, results rows, hidden Part-object column, tab behavior, Select All, or the standalone Results UI.
- Static source update committed; **not yet tested** in Modeling 18.1.

Next runtime test, in order:
1. Load the exact candidate source linked from this branch.
2. Search a known-positive pair and confirm the Results window, multiple pages and Select All still work.
3. Select exactly one result row and press Apply. Confirm exactly that Part is selected in the 3D model.
4. Repeat by double-clicking one row. Confirm it selects that Part in 3D.
5. Select multiple rows and press Apply; confirm only those Parts are selected.
6. Switch to another page and verify Apply/double-click never selects Parts from the previous page.
7. If an error remains, provide the exact LISP error and a trace/log if available. Do not change the UICT architecture or search pipeline while investigating.


## 14. Apply reaches native hand-off but no objects are accepted — 2026-11-16

User runtime result after candidate commit `f92834af7c28fa172768f552431bb06315b72ee6`:
- Double-click still does not select the Part.
- Selecting a row and pressing Apply no longer reports the Symbol-vs-BrowserNode type error.
- Instead, Apply reports: `H871 Apply: No objects were handed to Modeling. Check the active command.`

Interpretation:
- The BrowserNode type mismatch has been passed far enough for the code to reach the native browser hand-off.
- The message is emitted when `sd-browser-exec-cmd ... :select-and-execute` returns NIL.
- PTC Graphical Browser documentation states that `:select-and-execute` returns NIL if no objects are selected in that browser. It also states that `:set-object-selection` only selects items that are visible in the browser. This makes it important to distinguish: (a) node ID resolution, (b) node displayed state, (c) set-object-selection return, (d) browser selected-object count, and (e) hand-off return.
- The current temporary Graphical Browser is intentionally not shown. This may be relevant because its table rows may not be considered displayed/selectable, but this is a hypothesis, not yet proven.
- The phrase "Check the active command" in the custom message should not be treated as proof that the active-command state is the root cause. First establish whether the temporary browser actually contains selected BrowserNodes before hand-off.

Diagnostic-only source update:
- Commit: `eade2709d7ebc5a1839690ec4137a33bb75c76c7`
- Blob: `7aed33cea9c6e5a8bb44895eeab08eee01858d46`
- Added trace checkpoints for UICT selection payload, double-click callback entry/page resolution, number and types of generated bridge nodes, table-mode/root setup return values, per-node BrowserNode type/displayed state/selection return, browser selected count/list types, and select-and-execute return.
- No behavior changes to the bridge, Results UI, table contents, search, or mappings; instrumentation only.
- Static check: 797 lines; parentheses balanced (depth 0, minimum 0); no unterminated strings.
- Not yet tested in Modeling 18.1.

Next test:
1. Load this exact source.
2. Search one known-positive pair and select one result row.
3. Press Apply once.
4. Send the appended trace section beginning at `APPLY/UICT-SELECTION`.
5. Double-click one row and send whether `APPLY/DOUBLE-CLICK-CALLBACK` appears in the trace.
Do not change the Results UICT architecture or replace it with the Stage 0/1 browser.


## 15. Double-click reproduces the same native hand-off failure — 2026-11-16

The user has now tested both interaction paths:
- Select a result row and press Apply.
- Double-click a result row.

Both paths fail with the same message:
`H871 Apply: No objects were handed to Modeling. Check the active command.`

Updated interpretation:
- The double-click action is now reaching the shared Apply path far enough to produce the same native hand-off message, but the trace must confirm callback entry and page resolution.
- This is not evidence of two independent UI event bugs. Both paths converge on `h871-pf-v03-apply` -> `h871-pf-v03-native-apply` -> `:select-and-execute`.
- The current candidate already contains instrumentation to distinguish row payload, BrowserNode resolution, visibility, per-node selection result, selected count, and hand-off return. Use those exact trace values before changing implementation.
- A likely area to inspect is the temporary Graphical Browser bridge: it is created hidden, and its nodes may not be registered as displayed/selectable. This remains a hypothesis until the trace confirms the intermediate states.
- Do not make the hidden bridge visible as a speculative fix: that could introduce an extra Results window and violate the one-standalone-UICT-window requirement.
- Do not change the UICT Results window, page architecture, table schema, filter mappings, collector, or known-good ver-02 / Stage 0/1 baselines.

Next evidence:
1. Confirm the loaded file is the latest `feature/ver03-uict-apply` source containing the `APPLY/NODE-STATE` and `APPLY/SELECT-AND-EXECUTE-RETURN` checkpoints.
2. Run Apply once after selecting exactly one row.
3. Send the trace block beginning at `APPLY/UICT-SELECTION` through `APPLY/SELECT-AND-EXECUTE-RETURN`.
4. Double-click once and confirm whether `APPLY/DOUBLE-CLICK-CALLBACK` and `APPLY/DOUBLE-CLICK-PAGE` are present.
5. Runtime status: Apply and double-click hand-off = **failed** in Modeling 18.1; root cause = **not yet isolated**.


## 16. Apply trace isolates hidden-browser visibility / native hand-off — 2026-11-16

The user supplied the full trace from the latest diagnostic source. The trace proves:

- Search completed: 500 assembly objects visited; 8 Parts matched.
- UICT page refresh completed: `sd-change-logical-table-contents` returned T.
- Double-click callback entered and resolved the correct page.
- UICT selection payload contained 1 selected `ELAN::SEL_ITEM` for double-click and 8 selected `ELAN::SEL_ITEM` values for Select All / Apply.
- Native bridge created the same number of BrowserNode IDs.
- Each ID resolved to `G-BROWSER::BROWSERNODE`.
- `:set-table-mode` and `:change-table-root` both returned T.
- For every bridge node, `:is-object-displayed` returned NIL while `:set-object-selection` returned T.
- Browser query reported selected count 1 or 8 and returned the expected number of BrowserNode structures.
- `:select-and-execute` returned NIL in every attempt, including double-click, one selected row and eight selected rows.

Evidence-based conclusion:
- UICT row selection and callback routing are working.
- BrowserNode construction/resolution and browser selection bookkeeping are working.
- The failure is specifically after the hidden bridge has registered a selection and at the native `:select-and-execute` hand-off.
- The strongest current discrepancy is that every bridge node is reported as not displayed (`NIL`) even though it is selected. The bridge browser is created but never passed to `sd-show-graphical-browser`.
- PTC Integration Kit documentation for later releases says `:set-object-selection` only selects visible items, and describes `:select-and-execute` as transferring the browser selection into the Modeling select list / active command. The actual Modeling 18.1 behavior remains authoritative; later-version documentation is supporting context only.
- The `SEL_ITEM` values in the UICT payload are expected Modeling selection handles, not malformed Part values. Do not convert them to names or discard them.
- The trace does not prove whether the NIL hand-off is caused by invisible BrowserNodes, missing active-command context, or a Modeling 18.1-specific restriction. Do not claim a definitive root cause yet.

Known-good comparison:
- User-confirmed Stage 1 uses a normal visible Graphical Browser and its native Apply/OK action; user confirmed that this path selects Parts in 3D.
- The current UICT bridge differs materially: it constructs a second Graphical Browser invisibly and calls `:select-and-execute` programmatically.
- Therefore the next controlled experiment should isolate visibility/native browser lifecycle only, not change UICT data, search, mapping, or tab architecture.

Next experiment proposal:
1. Prepare a diagnostic-only candidate on the UICT feature branch that calls `sd-show-graphical-browser` for the temporary bridge immediately before applying the selected BrowserNodes, then performs the same selection and native hand-off.
2. Do not change the UICT Results shell, page tabs, row data, collector, Density matching or selection payload.
3. This may briefly show the temporary native bridge window during Apply. It is a diagnostic test only, not the intended final UI. If the user does not want even a temporary second window, stop before testing and design a different hand-off route.
4. Test exactly one selected row first. Record `:is-object-displayed`, selected count and `:select-and-execute` return.
5. If the visible bridge succeeds, investigate whether its native Apply can be invoked/closed without exposing a second window, or whether a different native selection bridge is required. If it still fails, investigate active-command context in Modeling 18.1.
6. Runtime status: latest hidden-bridge Apply and double-click = **failed**; diagnostic trace = **user-supplied and conclusive for the intermediate states**; root cause = **narrowed to native hand-off, final cause not yet proven**.


## 17. Visible native Apply bridge diagnostic candidate — 2026-11-16

Implemented on `feature/ver03-uict-apply`:

- Source commit: `5629a274a080c6b6db3608656eabf64fb79653ae`
- Source blob: `25a0470c2a69dc3bb54c39bdea28ad234e163bca`
- File: `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp`
- Change: after creating the bridge Browser, building its BrowserNodes, setting table mode and changing the table root, call `sd-show-graphical-browser` immediately before the existing per-node displayed/selected checks and `:select-and-execute`.
- New trace checkpoint: `APPLY/SHOW-BRIDGE-RETURN`.

Scope guard:
- No changes to UICT Results shell, internal page/tab lifecycle, collector, Density mapping/normalization, logical/display table schema, selection payload, or callback routing.
- No changes to the native hand-off command itself.
- This is explicitly a diagnostic candidate. It may briefly display the temporary native bridge window during Apply; it is not the intended final UI.

Static validation:
- Parentheses balanced.
- No unterminated strings.
- Source re-fetched from GitHub after commit and insertion verified.

Runtime validation:
- **Not yet tested by user in Creo Modeling 18.1.**
- Do not mark Apply or double-click fixed until the user tests this exact commit.
- Expected diagnostic distinction: compare `APPLY/NODE-STATE` displayed values before/after showing the bridge, then check `APPLY/SELECT-AND-EXECUTE-RETURN`.
- First test one selected row via double-click or selecting one row and pressing Apply. If the temporary bridge appears, allow it to complete and note whether the Part becomes selected in the 3D model.

## 18. Native bridge Apply confirmed by user in Modeling 18.1 — 2026-11-16

The user tested the visible native bridge candidate and confirmed:
- The temporary native Apply bridge window appears.
- Clicking the bridge's native **Apply** button successfully selects the intended Part(s) in the 3D viewport, as desired.
- This confirms the selected Part payload can be represented by BrowserNodes and handed to Modeling through the native Graphical Browser's built-in Apply action.

Trace evidence:
- `APPLY/SHOW-BRIDGE-RETURN` reports `:VISIBLE T`.
- Bridge BrowserNode structures are created and selected; selected count is 1 for single-row tests and 8 for Select All.
- `:select-and-execute` still returns `NIL` when called programmatically from LISP.
- Despite that NIL return, the user confirms clicking **Apply** in the visible native bridge performs the correct 3D selection.

Updated technical conclusion:
- The native Graphical Browser's built-in Apply action is the currently verified successful hand-off path in Creo Elements/Direct Modeling 18.1.
- The direct LISP invocation of `:select-and-execute` is not equivalent in this context and must not be treated as a successful substitute.
- This narrows the remaining problem to invoking or reusing the native Apply action from the UICT workflow, or deciding whether the native bridge can remain as an explicit second-stage confirmation window.
- Do not claim that UICT Apply or double-click is fully integrated yet: the user still has to click Apply in the bridge window.
- Preserve the confirmed working UICT Results window, internal tabs, per-page results, and selected Part payload. Do not change collector, numeric Density mappings/normalization, matching predicate, or table schema.

Known-good implementation reference:
- ver-02 creates its native Graphical Browser with `:okButtonLabel "Apply"`; the source comments explicitly rely on Creo's native OK action to perform `:select-and-execute`.
- In ver-03, the bridge also has `:okButtonLabel "Apply"`, and the user confirms that native button works.

Next investigation:
1. Inspect the Graphical Browser API and existing ver-02 behavior for any supported way to invoke the native OK/Apply action or configure its action callback. Do not invent an undocumented command or simulate a mouse click.
2. If no supported programmatic invocation exists, retain the bridge as an explicit native confirmation step temporarily, and ask the user whether that two-window interaction is acceptable before making it the production behavior.
3. Do not remove the bridge's native Apply button or close the bridge before the user has applied it.
4. Runtime status: native bridge Apply = **user-confirmed working**; programmatic `:select-and-execute` = **returns NIL**; end-to-end one-window UICT Apply = **not yet solved**.

## 19. Graphical Browser API research: native OK action — 2026-11-16

Official PTC Integration Kit documentation for Creo Elements/Direct Modeling 20.6 was checked:
- `sd-create-graphical-browser` supports `:okButtonAction`, a LISP form executed when the native OK button is pressed.
- The documented default is `(sd-browser-exec-cmd name :select-and-execute)`.
- The documentation says this default sends selected browser items to Modeling and closes the browser if it is not pinned; it is also used for the browser's default double-click action.
- Reference: https://support.ptc.com/help/creo_elements_direct/r20.6.0.0/advanced_documentation/integration_kit/reference/gbrowser.html (section `SD-CREATE-GRAPHICAL-BROWSER`, `:okButtonAction`).

Implications and limitations:
- This explains why the native Apply button is the known-good path.
- The documented `:okButtonAction` is a configuration hook for what happens when the user presses the native button. It is not documented as an API for programmatically synthesizing that button press.
- The documented default action is the same browser command that returned NIL when called directly from the ver-03 LISP routine. Therefore merely spelling out `:okButtonAction` in the browser constructor is not yet a proven fix for programmatic Apply.
- The documentation checked is for Modeling 20.6, not the user's installed 18.1. Treat it as supporting API guidance only; do not assume every option or behavior is identical in 18.1.

Engineering decision:
- Do not attempt Windows mouse simulation, guessed widget names, undocumented button invocation, or direct calls to private UI internals.
- Keep the current visible bridge candidate as a diagnostic/fallback only. The target remains one standalone UICT Results window with internal tabs; a permanent second Graphical Browser window is not accepted as the final architecture unless the user explicitly changes that requirement.
- Continue looking for a documented 18.1-compatible way to route selected Part objects into Modeling's selection context without a second user-facing browser. If no supported route exists, report the limitation and present the native bridge as the reliable two-step fallback.

## 20. One-window Apply candidate: execute native hand-off in Modeling command context — 2026-11-16

User requirement reaffirmed:
- Do not require the user to interact with a second native Apply bridge window.
- Keep one standalone UICT Results window with internal pages/tabs.
- Apply and double-click must hand selected Parts directly to the 3D Modeling selection context.

Implementation candidate on `feature/ver03-uict-apply`:
- Source commit: `e2040033bc7c41895ae866e231569e522af3817f`
- Source blob: `e0598143bafcb2b15f828f0fc3b6c68fe8e5feb8`
- Source file: `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp`
- Removed the diagnostic `sd-show-graphical-browser` call, so Apply no longer intentionally opens the temporary native bridge window.
- Kept the existing bridge data construction and selected BrowserNode payload unchanged.
- Changed the hand-off call to execute `sd-browser-exec-cmd ... :select-and-execute` inside `sd-call-cmds`, based on PTC Integration Kit guidance that Modeling action routines invoked from UI callbacks should be wrapped in `sd-call-cmds` to manage command execution and UI state.
- Existing trace checkpoint `APPLY/SELECT-AND-EXECUTE-RETURN` remains and now records the wrapped call's result.
- Error text now reports that Modeling did not confirm the hand-off rather than asserting that no objects were handed over.

Technical rationale:
- The user confirmed that clicking the native bridge's Apply button works, while direct LISP invocation of `:select-and-execute` returns NIL.
- This candidate tests whether the missing piece is Modeling command context when the call originates from the UICT callback.
- This is a controlled hypothesis, not a proven fix. PTC documentation describes `sd-call-cmds` as the wrapper for action routines; it does not explicitly guarantee that wrapping this Graphical Browser command will reproduce the native button event.
- Reference: PTC Integration Kit, User Defined Commands: https://support.ptc.com/help/creo_elements_direct/r20.6.0.0/advanced_documentation/integration_kit/concepts/user_cmd.html
- Reference: PTC Integration Kit, Graphical Browser `:select-and-execute`: https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/reference/gbrowser.html

Scope guard:
- No changes to UICT Results shell, internal page/tab lifecycle, row payload, collector, numeric Density mappings/normalization, match predicate, table schema, or Select All behavior.
- The temporary native bridge is no longer shown by this Apply path.
- No mouse simulation, guessed UI widget command, or private UI internals used.

Static validation:
- Parentheses balanced; no negative nesting; no unterminated strings.
- Source committed and re-fetched from GitHub to verify the candidate.

Runtime validation:
- **Not yet tested in Creo Elements/Direct Modeling 18.1.**
- Do not report Apply/double-click fixed until the user verifies direct 3D selection with no second window.
- First test one selected row with Apply, then one row by double-click, then Select All + Apply.
- Capture `APPLY/SELECT-AND-EXECUTE-RETURN` and confirm whether the temporary native bridge remains absent.

## 21. Modeling 18.1 runtime result: `sd-call-cmds` is illegal from UICT Apply callback — 2026-11-16

User tested source commit `e2040033bc7c41895ae866e231569e522af3817f` in Creo Elements/Direct Modeling 18.1:
- Both double-click on a Results row and pressing the UICT **Apply** button produce `Illegal call to action routine.`
- The subsequent H871 message is `Modeling did not confirm the native selection hand-off`.
- Therefore the one-window candidate in section 20 is **runtime-failed**. Do not describe it as a working fix.

Technical interpretation:
- The failure occurs at the attempted `sd-call-cmds` wrapper, before a successful native browser hand-off can be confirmed.
- PTC Integration Kit documentation describes `sd-call-cmds` as legal only inside an existing Modeling User Action; invoking it outside that context produces an illegal-action-call error. A UICT `:pushAction` callback must not be assumed to be a Modeling User Action.
- Reference (PTC 20.4 documentation; use as API guidance, not proof of 18.1 behavior): https://support.ptc.com/help/creo_elements_direct/r20.4.0.0/advanced_documentation/integration_kit/reference/sd-call-cmds.html
- The browser's native OK button remains the only runtime-confirmed selection hand-off path: user confirmed it selects the intended Part(s) when pressed in the visible Graphical Browser.

Next investigation:
1. Do not wrap `sd-browser-exec-cmd :select-and-execute` in `sd-call-cmds` from UICT callbacks again.
2. Find a documented Modeling 18.1-compatible way to enter a genuine Modeling User Action / command context from the UICT callback, or another supported selection-transfer API.
3. Distinguish browser commands from Modeling Action Routines. Do not infer that calling a browser command programmatically reproduces the browser's native OK-button event.
4. Do not use guessed internal widget callbacks, Windows mouse simulation, or undocumented private UI calls.
5. Keep the single-window requirement. Do not promote the visible bridge to the final design without explicit user approval.

Scope preserved:
- No source-code changes made in this diagnostic update.
- UICT Results shell, internal tabs, per-page results, collector, numeric Density mappings/normalization, match predicate, and table schema remain untouched.

Runtime status:
- Search/results/tabs/selection list: previously user-confirmed working.
- Visible native Graphical Browser Apply: user-confirmed working.
- Direct programmatic `:select-and-execute`: returns NIL in the earlier test.
- `sd-call-cmds` wrapper from UICT callback: **user-tested and failed** with `Illegal call to action routine`.
- One-window Apply/double-click: **not solved**.

## 22. Apply candidate: queue a zero-input Modeling User Action from UICT — 2026-11-16

### Why this candidate exists

The user tested section 20's direct `sd-call-cmds` call from UICT and received:
- `Illegal call to action routine.`
- `H871 Apply: Modeling did not confirm the native selection hand-off.`

PTC documentation explicitly states that `sd-call-cmds` may only be used inside a User Action. Calling it without a surrounding User Action produces `SD-CALL-ACTION-ILLEGAL-CALL`.
Reference: https://support.ptc.com/help/creo_elements_direct/r20.4.0.0/advanced_documentation/integration_kit/reference/sd-call-cmds.html

### New implementation candidate

Source commits on `feature/ver03-uict-apply`:
- Initial trampoline: `f93dc1d0aaada84758fdcab588628c616e230e52`
- Explicit action success/failure diagnostics: `d0a0efecac3b0f463bc9860a37ac735cb9bd6fc8`
- Source blob after latest commit: `7a195dfdc6970a1fed53e37000925f254bd7f996`

Source file:
`src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp`

Implementation:
1. The UICT Apply/double-click callback only reads the active table selection, stores the real Part objects and page name in globals, then calls `sd-put-buffer "H871_PF_V03_APPLY_ACTION"`.
2. A new zero-input sequential Dialog Generator command, `h871_pf_v03_apply_action`, is defined with `:variables '()`.
3. PTC Dialog Generator documentation says a sequential dialog executes its `:ok-action` immediately when no dialog variables remain. Thus this action is intended to execute without opening a second user-facing dialog.
4. The new command's `:ok-action` calls the existing native bridge builder/selection routine. That routine now calls `sd-call-cmds` from inside the actual Dialog Generator User Action context.
5. The `sd-call-cmds` call has explicit `:success` and `:failure` branches. A NIL return from the browser command is not incorrectly treated as an execution error; actual action failure is recorded using `sd-inq-error-obj :all`.

PTC references:
- `sd-put-buffer` feeds the Modeling command-line buffer and is the documented way for UI controls to send input to Modeling: https://support.ptc.com/help/creo_elements_direct/r20.8.0.0/advanced_documentation/integration_kit/reference/ui_util.html
- A dialog can be activated by entering its command name into the input buffer; a sequential dialog with no remaining variables immediately executes its `:ok-action`: https://support.ptc.com/help/creo_elements_direct/r20.8.0.0/advanced_documentation/integration_kit/reference/dg_manual.html
- `sd-call-cmds` success/failure forms and the User Action context restriction: https://support.ptc.com/help/creo_elements_direct/r20.4.0.0/advanced_documentation/integration_kit/reference/sd-call-cmds.html

Compatibility caveat:
- These online references are for Modeling 20.4–20.8, not the user's 18.1 installation. This implementation is a documented-API hypothesis and must be runtime-tested in 18.1.
- No source-level test can establish that the command buffer is processed immediately after a UICT callback or that the hidden Graphical Browser's programmatic `:select-and-execute` produces the same viewport result as clicking its native Apply button.

### Scope guard

- No changes to the UICT Results window, tabs, table schema, collector, numeric Density mappings/normalization, matching predicate, or per-page selection extraction.
- The UICT callback no longer calls `sd-call-cmds` directly.
- No visible Graphical Browser bridge is opened by the candidate.
- No mouse simulation, guessed widget IDs, or undocumented private UI calls.

### Static validation

- Source was re-fetched from GitHub after the latest commit.
- Parentheses balanced; no negative nesting; no unterminated strings.
- Confirmed the Apply callback queues `H871_PF_V03_APPLY_ACTION`.
- Confirmed the dedicated `sd-defdialog` exists and has zero variables.
- Confirmed the native browser hand-off is called from the dedicated command's `:ok-action`, not directly from the UICT callback.
- Confirmed explicit `:success` / `:failure` diagnostics are present.

### Runtime validation

**Not yet tested in Creo Elements/Direct Modeling 18.1.**

User test sequence:
1. Reload the new ver-03 source.
2. Search one known matching pair, e.g. CNC + SUS304.
3. Select one row and click UICT Apply.
4. Repeat by double-clicking one row.
5. Test Select All + Apply.
6. Confirm whether any additional dialog/window appears and whether the intended Part(s) become selected in the 3D viewport.

If the test fails, capture the trace stages:
- `APPLY/QUEUE-USER-ACTION`
- `APPLY/QUEUE-USER-ACTION-RETURN`
- `APPLY/USER-ACTION-ENTER`
- `APPLY/SELECT-AND-EXECUTE-SUCCESS-CONTEXT` or `APPLY/SELECT-AND-EXECUTE-ACTION-ERROR`
- `APPLY/SELECT-AND-EXECUTE-STATUS`

Do not mark one-window Apply as fixed until the user confirms the 3D selection in Modeling 18.1.
