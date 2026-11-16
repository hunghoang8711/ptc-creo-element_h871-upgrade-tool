# Part Filter ver-03 – Single Results Window with Internal Tabs

**Status: UICT prototype implemented; static-checked; Creo 18.1 runtime validation pending. Native Apply hand-off not implemented yet.**

## Authoritative requirement

Build exactly one separate Results window. Inside that window, provide horizontal tabs/pages similar to a desktop browser. Do not create multiple Graphical Browser windows and do not use Creo Browser Bar tabs.

## Page identity and lifecycle

- Key: exact pair `Density Instance + Density Base`.
- Caption: mapped Material + Machining Process, e.g. `SUS304-CNC`.
- First search for a pair creates its page.
- Repeating the same pair refreshes/replaces the existing page; no duplicate tab.
- A different pair creates a new page in the same window.
- Each page owns its result list and selection state.
- Each page has its own multi-select list, Select All and Clear Selection controls.
- A no-match search does not silently erase a previously valid page.
- **Apply to Modeling selection is still pending**; do not use ver-03 as a production selection tool until that hand-off is implemented and tested.

## Source baseline

Start from ver-02 behavior. Preserve:
- Assembly selection and recursive scan.
- Density Instance + Base exact pair matcher and normalization.
- Material/Process mapping.
- Result row data and display fields.
- Known-good native Graphical Browser selection/Apply semantics as a regression boundary.

Do not modify ver-01 or ver-02.

## Implemented prototype

Canonical source:
`H871_PART_FILTER_VER_03.lsp`

The source now integrates the ver-02 search engine with one UICT Dialog Shell, one internal horizontal Tab Control and per-page List Controls. It maintains page state by Density pair, refreshes existing pages, creates pages for new pairs and keeps previous pages when a search has no matches.

The prototype stores the actual Part object against each displayed row internally. The current list selection API returns display labels/positions, however, and a safe Modeling 18.1 operation to transfer the selected Part objects into Modeling selection has not yet been verified. Therefore the Apply action is deliberately not wired.

## Technical compatibility boundary

UICT Tab Control / Dialog Shell / List Control patterns were found in PTC Integration Kit documentation for releases 20.7/20.8. Exact Modeling 18.1 availability and signatures are not established. The first runtime load/test in Modeling 18.1 is required before treating these calls as compatible.

See [VER03_IMPLEMENTATION_NOTES](../../../docs/VER03_IMPLEMENTATION_NOTES.md) for API references, static-check results and test instructions.

## First runtime test

1. Load `H871_PART_FILTER_VER_03.lsp` in Modeling 18.1.
2. Run `H871_PART_FILTER_VER_03`.
3. Search CNC + SUS304; expect one Results window with tab `SUS304-CNC`.
4. Search KH + A6061; expect a second tab `A6061-KH` in the same window.
5. Search CNC + SUS304 again; expect the existing tab to refresh, not duplicate.
6. Switch tabs; confirm result lists and selection are isolated.
7. Test row multi-selection, Select All and Clear Selection.
8. Search a no-match pair; verify existing tabs/results remain unchanged.

Do not test Apply yet; it is not connected in this prototype.

## Acceptance tests before production

1. All runtime tests above pass in Creo Elements/Direct Modeling 18.1.
2. Selection state remains page-specific across tab switches and refresh.
3. A verified Modeling 18.1 mechanism transfers only selected real Parts from the active page into Modeling selection.
4. Apply behavior is regression-tested without replacing the proven ver-01/ver-02 native Apply path prematurely.
5. ver-01/ver-02 regression checklist passes.
