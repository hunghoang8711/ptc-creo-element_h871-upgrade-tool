# Part Filter ver-06 – Stage 0 Native Browser + ver-04 Multi-page Integration

**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Branch:** `integration/ver-06-stage0-native-multipage`  
**Source:** `H871_PART_FILTER_VER_06.lsp`  
**Status:** Static integration candidate. Not yet runtime-tested in Modeling 18.1.

## Goal

Combine the two independently user-verified behaviors into one standalone Results Browser:

1. **Stage 0 native selection/Apply:** direct row selection, Select All, and native Apply to actual Modeling Parts.
2. **ver-04 page-root behavior:** multiple Density-pair pages in one Browser Tree, page switching, and page-local selection restoration.

The final UI is one visible standalone Results Graphical Browser. It must not create a UICT Results shell, hidden Browser bridge, intermediate Results window, Browser Bar docking, or a separate Browser for each Density pair.

## Source lineage and protected behavior

- Stage 0 baseline: `src/part-filter/ver-03-rebuild/H871_PART_FILTER_VER_03_REBUILD.lsp` on `rebuild/ver-03-from-ver-02`.
- Page-root diagnostic: `src/part-filter/ver-04/diagnostics/H871_PF_V04_SINGLE_BROWSER_PAGES_DIAG.lsp`.
- ver-06 keeps the Stage 0 recursive collector, numeric Density normalization, exact Instance AND Base predicate, report generation, Browser table columns, and native Apply button setup. The collector and density helper functions are mechanically identical after the isolated prefix rename.
- ver-04's proven `:change-table-root` and `:set-object-selection` page activation/restore pattern is reused.
- The unverified ver-05 `:clear-table-roots` sequence is deliberately not used.
- Stage 0 source remains unchanged.

## Page behavior

- A page represents one exact numeric Density Instance + Density Base pair.
- Captions use PROCESS-MATERIAL order: `CNC-SUS304`, `CG-SS400`.
- Searching a new pair creates a page.
- Searching the same pair refreshes that page and clears its old selection.
- A no-match search preserves existing pages.
- Previous Page / Next Page buttons switch pages; the Browser context menu has a Results Pages submenu for direct selection.
- Before switching, selected Part paths on the current page are saved. They are restored when returning to that page.
- Select All and Clear Selection operate on the active page.
- Apply remains the Graphical Browser's native Apply action. Do not replace it with a custom callback or hidden selection bridge.

## Density mapping – unchanged

- Instance: CNC=1, KH=2, CG=3, COVER=4.
- Base: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
- `1-304` means CNC-SUS304.
- API Density values are normalized by dividing by 1000.
- A match requires both Instance AND Base.

## Lifecycle

The same named Browser and Tree are rebuilt after each successful search so the tree includes the current page registry. The code destroys the old named Browser before creating the replacement; it does not intentionally keep multiple Results windows visible. Close Results hides the native Browser and returns control to the filter dialog. The next successful search rebuilds and shows the one Results Browser.

## Runtime acceptance – mandatory

Use a **disposable copy** of an Assembly, never the original/customer model.

1. Load `H871_PART_FILTER_VER_06.lsp` and run `H871_PART_FILTER_VER_06`.
2. Search CNC + SUS304. Confirm the Results Browser appears and contains only matching Parts.
3. Search CG + SS400. Confirm the Results Browser now offers both pages.
4. Switch pages using Previous/Next and right-click > Results Pages. Confirm each page shows only its own Parts.
5. Select one or more rows on page A, switch to B and select rows, then return to A. Confirm page-local selection is restored.
6. Test Select All and Clear Selection on each page.
7. Press native Apply. Confirm the intended Part(s) become visibly selected in the actual 3D viewport.
8. Repeat a same-pair search; confirm that page refreshes and its previous selection is cleared.
9. Search a no-match pair; confirm existing valid pages remain.
10. Confirm only one Results window is visible throughout.

**Apply acceptance rule:** a successful LISP return value, trace marker, BrowserNode resolution, or highlighted Browser row is not proof. Only visible selection of the intended Part(s) in the Modeling 3D viewport proves Apply.

## Safety and known limits

- Runtime behavior in Modeling 18.1 is not established by static checks.
- Page-root switching and selection restoration were user-confirmed in the separate ver-04 diagnostic; the ver-06 integration itself still needs runtime testing.
- Stage 0 actual viewport selection/Apply was user-confirmed independently; its behavior after introducing page roots must be reconfirmed.
- Never load or use the obsolete UICT ver-03 Apply bridge or commit `068ee4123b5aadf6cde5bce54321f1ee031ea064` as the active candidate.
- Do not change the collector, Density mapping, AND predicate, or native Apply path while testing page navigation.
- If a test fails, capture the exact error and trace before editing further.
