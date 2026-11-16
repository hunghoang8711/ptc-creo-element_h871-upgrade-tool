# H871 Part Filter ver-03 – Implementation Record

**Implementation milestone:** 2026-11-16  
**Branch:** `main`  
**Source:** `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp`  
**Status:** Prototype implemented and statically checked; Modeling 18.1 runtime validation pending.

## What is implemented

- The source is based on the ver-02 recursive Assembly scan and exact Density Instance + Density Base matching.
- The existing ver-02 mapping is retained:
  - Machining Process: CNC=1, KH=2, CG=3, COVER=4.
  - Material convention: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
- A single UICT Dialog Shell is created as the Results window.
- One horizontal UICT Tab Control lives inside that shell.
- Each unique Density pair is assigned one tab caption, such as `SUS304-CNC`.
- A repeated pair refreshes the existing page rather than adding another page.
- A different pair creates another page in the same shell.
- Each page has its own multi-select list and selection count.
- Select All and Clear Selection are scoped to the page that owns the buttons.
- A no-match search returns a message and leaves existing result pages unchanged.
- The page refresh attempts to preserve selected rows whose display keys still exist.

## Explicitly not complete

**Apply to Modeling selection is not wired in this prototype.** UICT list selection returns display items/positions, but the reviewed references do not establish a safe Modeling 18.1 operation to transfer those selected Part objects into the native Modeling selection set. We must not invent a command or use a later-release assumption.

The known-good native Graphical Browser row selection and native Apply behavior remain preserved in ver-01/ver-02. Do not replace those files.

## API evidence

The following UICT patterns were found in official PTC Integration Kit references for releases 20.7/20.8:

- `sd-create-dialog-shell`, `sd-append-grid-area`
- `sd-create-tab-control`, `sd-insert-tab-control-page`
- `sd-create-list-control`, `sd-create-text-control`
- `sd-set-list-control-items`, `sd-set-list-control-selected-items`
- `sd-get-list-control-selected-items`
- `sd-set-current-tab-control-page`, `sd-get-current-tab-control-page`
- `sd-dialog-shell-p`, `sd-dialog-shell-visible-p`

The PTC examples explicitly describe a tab control and per-page child controls. These sources prove the API patterns for the documented newer releases only; they do not prove availability or identical signatures in Modeling 18.1.

Research references:
- https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/reference/uict_create.html
- https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/reference/uict_specutil.html
- https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/examples/vertical_tabs_lsp.html

## Static checks performed

- Parenthesis balance: passed.
- String delimiter scan: passed.
- The source uses the current ver-02 Density query and normalization pattern.
- No change was made to ver-01 or ver-02.
- No Creo 18.1 runtime test was possible in this development environment.

## First user runtime test

1. Load the exact ver-03 file in Creo Elements/Direct Modeling 18.1:
   `(load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER_VER_03.lsp")`
2. Run command: `H871_PART_FILTER_VER_03`.
3. Choose an Assembly and search CNC + SUS304.
   - Expected: one Results window, one internal tab named `SUS304-CNC`, matching Parts listed.
4. Search KH + A6061.
   - Expected: second tab `A6061-KH` appears in the same window, not a second window.
5. Search CNC + SUS304 again.
   - Expected: the existing `SUS304-CNC` tab refreshes; no duplicate tab.
6. Switch tabs and check each list remains isolated.
7. Test selecting multiple rows, Select All and Clear Selection on each page.
8. Search a pair with no matching Parts.
   - Expected: a no-match message; all previous tabs and results remain intact.

If loading or opening the shell fails, send the exact error text and identify whether it occurs during LOAD, dialog launch, first search, or second search.

## Next engineering gate

After the user confirms the tab shell and list behavior in 18.1:
1. Verify the native Modeling selection hand-off for actual Part objects.
2. Add an Apply action only after the exact 18.1 API/command behavior is demonstrated.
3. Regression-test page-specific selection and native selection hand-off.
4. Only then consider ver-03 suitable for production use.
