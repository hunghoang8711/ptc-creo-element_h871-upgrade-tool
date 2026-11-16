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
