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
