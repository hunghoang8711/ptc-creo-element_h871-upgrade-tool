> **ARCHITECTURE WARNING – NOT THE ACCEPTED FINAL UI:** This branch currently implements one Graphical Browser per machining-process/material pair. That is why each filter result opens a separate Part List window. This is a deliberate multi-Browser experiment, but it does **not** satisfy the user's required design of one shared Results window containing internal tabs. Do not describe the current multi-Browser layout as the completed VER-05 target. See the 2026-11-16 architecture correction in the Development Log.

# H871 Part Filter VER-05 – VER-03 Filter + Native Multi-Browser Manager

Target: PTC Creo Elements/Direct Modeling 18.1

## Source and branch

- Branch: `rebuild/ver05-ver03-filter-native-multi-browser`
- Source: `H871_PART_FILTER_VER_05_MULTI_BROWSER.lsp`
- Base: `debug/ver03-visible-apply-bridge` (the VER-03 source revision where the visible native Apply Bridge's built-in Apply button was user-confirmed to select Parts in the 3D viewport).
- VER-01, VER-02, VER-03, VER-04 and `main` are not modified.

## Architecture

1. The complete VER-03 search dialog is preserved: Assembly, Machining Process, Material and numeric display-code fields.
2. Filtering still matches BOTH Density Instance and Density Base using the numeric codes and the existing `/1000.0` normalization.
3. One Browser Manager window lists each successful Density pair in a compact two-column layout. Each pair has a dedicated Open button; the Manager supports up to 36 pair entries in one Modeling session.
4. Each Density pair has its own Graphical Browser and Browser Tree. Browser and Tree names include the pair and a generation number.
5. Each Browser Tree update callback is a distinct function closure over that Browser's tree name, pair label and result snapshot. No shared active-pair/global-parts variable is used.
6. Each Graphical Browser uses native `:okButtonLabel "Apply"`, plus native Browser table columns, Select All and Clear Selection commands.
7. Re-filtering the same pair creates and opens a replacement Browser first, updates that pair's Manager row, then destroys only the previous Browser/Tree for that same pair.
8. A no-match search does not replace any existing Browser or Manager row.

## Explicitly removed

- No `sd-create-display-table-control`.
- No `sd-create-logical-table` or logical-table refresh.
- No `sd-get-display-table-selection` or UICT Display Table selection handling.
- No temporary Apply Bridge. The visible Graphical Browser itself owns the result rows and its native Apply button.

## Density mapping

- Density Instance: CNC=1, KH=2, CG=3, COVER=4.
- Density Base: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
- `1-304` means CNC-SUS304. Matching checks both numeric properties; labels are presentation only.

## Load and run

Copy the source to a local test folder and load it in a fresh Modeling session using the actual local path:

```lisp
(load "D:/H871-TEST/H871_PART_FILTER_VER_05_MULTI_BROWSER.lsp")
```

Run command:

```text
H871_PART_FILTER_VER_05
```

## Mandatory safe test sequence

- [ ] Use a disposable copy of the Assembly, never the only/original customer model.
- [ ] Filter CNC-SUS304 (1-304): verify Manager row and Browser columns/Part list.
- [ ] In this Browser, select one Part and press its native Apply; verify the actual 3D viewport selection.
- [ ] Filter KH-A6061 (2-6061): verify a second independent Browser appears.
- [ ] Keep both Browsers open and verify their rows remain independent.
- [ ] Press Apply in each Browser and verify the intended Parts in the viewport.
- [ ] Re-filter CNC-SUS304 from a different Assembly: only the previous 1-304 Browser should be replaced; KH-A6061 must remain unchanged.
- [ ] Use the Manager's Open Browser buttons for both pairs.
- [ ] Test a no-match pair: existing Browsers and Manager rows must remain unchanged.
- [ ] Close/reopen the Manager and verify its rows can reopen the corresponding Browsers.
- [ ] Repeat the search in a fresh Modeling session and check for any fatal exception.

## Trace and report

- `H871_PART_FILTER_VER_05_TRACE.txt` in the user's home directory.
- `H871_PART_FILTER_VER_05_RESULT.txt` in the user's home directory.

## Validation status

Static source audit passed: balanced parentheses, closed strings, no duplicate local DEFUN names, all referenced `h871-pf-v05-*` functions defined, no UICT Display Table/logical-table APIs, native Browser Apply present, and per-Browser callback closures present.

The user has runtime-confirmed in Modeling 18.1 that separate result Graphical Browsers are independent; individual selection, double-click selection, and Select All followed by native Apply correctly select Parts in the 3D viewport for the tested workflow. The Manager's original small/clipped layout was corrected by changing only its grid-area dimensions from 112 × 82 to 1120 × 820 pixels while retaining the 10 × 10 pixel cell size and all child-control coordinates. The user subsequently confirmed in Modeling 18.1 that the H871 Graphic window became larger. Exact full-layout readability and all Manager row/button positions still need a complete visual check. Remaining multi-window lifecycle cases and the earlier fatal `0xc00000fd` root cause are still open.

## Known risk

The Assembly collector is deliberately preserved from VER-03 to avoid changing the search engine while replacing the results UI. It remains recursive. Earlier iterative traversal did not resolve the user's reported `0xc00000fd` exception, so the exception's root cause is unresolved. Test only on a disposable model copy and capture the trace/crash evidence.

## Runtime milestone – first user confirmation (2026-11-16)

The user tested VER-05 in Creo Elements/Direct Modeling 18.1 and confirmed:

- Filtering creates a separate Graphical Browser window for each result type/pair.
- Result windows are independent.
- Selecting an individual Part works; double-click selection and Select All followed by native Apply work as well as the known-good VER-02 workflow.
- The native Browser Apply correctly hands the selected Parts to the 3D viewport.
- The separate H871 Graphic/Manager window appears in a screen corner, but is currently too small to read all of its information. This is a Manager readability/layout issue, not an Apply failure.

Trace supplied for the tested run:

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

The trace confirms collection reached its completion marker after progress markers through 500 and reports the final tuple (0 530). Do not assign undocumented meanings to the tuple fields. No fatal exception or Apply error was reported in this test. This single trace does not prove that the earlier 0xc00000fd issue is universally resolved.

**New confirmed baseline:** preserve the independent native Graphical Browser windows, individual/double-click selection and Select All + Apply behavior. The next UI task is limited to improving the H871 Graphic/Manager window size/readability; do not modify the filter predicate, Browser selection callbacks or native Apply path while doing so.

Updated test status:
- [x] Independent result Browser windows appear for separate filter pairs.
- [x] Individual Part selection works.
- [x] Double-click selection works.
- [x] Select All + native Apply selects Parts in the 3D viewport.
- [x] H871 Graphic/Manager window became larger after the grid-area sizing correction (user-confirmed); verify all rows/buttons and full readability as a separate visual acceptance check.
- [ ] Full regression sequence (same-pair replacement, no-match preservation, Manager reopen buttons and fresh-session repeat) confirmed.
- [ ] Root cause/status of the earlier fatal exception conclusively established.


## 2026-11-16 – H871 Graphic/Manager grid sizing correction

Static layout review found a pixel/grid-unit mismatch in the Manager's grid area. The grid was declared as 112 × 82 pixels while its child controls use a 10 × 10 pixel cell size and coordinates extending to approximately 112 × 75 grid units. The available grid was therefore only about 11 × 8 units, clipping most of the intended two-column layout.

Changed only the Manager grid-area pixel dimensions to 1120 × 820, preserving the 10 × 10 cell size, all child-control coordinates, two-column arrangement, pair callbacks and native Browser implementation.

**Runtime status:** source change committed; not yet tested in Modeling 18.1. Confirm that all Manager rows/buttons are visible and legible at the new size. Do not treat the sizing correction as runtime-verified until the user tests it.


## Architecture correction – 2026-11-16

The user retested the current branch and confirmed that every machining-process/material pair still opens its own Part List window. A full source inspection confirms this is expected from the current implementation, not a rendering glitch:

- `h871-pf-v05-run` calls `h871-pf-v05-create-browser` for every successful filter pair.
- `h871-pf-v05-create-browser` allocates a new Graphical Browser and Browser Tree for that pair.
- The Manager's Open button calls `sd-show-graphical-browser` for that pair's stored Browser.
- The source has no shared Results tab control and no internal page/tab registry.

This conflicts with the user's accepted UI requirement: one `H871 - PART FILTER RESULTS` window with internal tabs. Each unique pair creates one tab; repeating a pair refreshes its existing tab; different pairs do not create extra top-level windows.

The current multi-Browser implementation is therefore a proven native Apply experiment, not the accepted final UI architecture. Preserve its native Browser Apply findings as reference material, but do not extend the Manager/Open-per-pair approach as the final solution.

A replacement design must first establish a single top-level Results window and internal pair tabs, then validate a visible Apply workflow without reintroducing a hidden Browser bridge. The old VER-03 source contains the intended single-shell/tab-control structure, but its Display Table/Apply behavior must not be assumed compatible or stable in Modeling 18.1 merely because the tab layout exists. Port only after reviewing the exact known-good native selection behavior and validating each API in the target release.
