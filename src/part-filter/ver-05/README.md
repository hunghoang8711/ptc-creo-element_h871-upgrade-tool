# Part Filter ver-05 – Single Results Browser / Multi-page

**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Canonical source:** `H871_PART_FILTER_VER_05.lsp`  
**Status:** Implemented and static-checked; not yet loaded or functionally tested in Modeling 18.1.

## 1. Non-negotiable product requirement

The final tool must have exactly one user-facing Results Graphical Browser. That same visible Browser instance must own:

- all result rows for all Density-pair pages;
- direct row selection and Ctrl/Shift multi-selection;
- Select All and Clear Selection;
- the native Apply action that transfers selected Parts to Modeling.

There must be no UICT Results window, no hidden Browser bridge, no second Results window, no Browser Bar tabs, no Open Native Results launcher, and no Close-to-UICT/reopen workflow.

The existing ver-02 search dialog (Assembly, Machining Process, Material) is retained as the input step. After a successful search, the single Results Browser is shown automatically. Creating another Density-pair page requires no extra user action beyond performing the search.

## 2. Required page behavior

- Each exact numeric Density Instance + Density Base pair has one page.
- New pair: create a page.
- Existing pair searched again: refresh that page; clear only that page's stale selection.
- No-match: preserve all existing valid pages and their data.
- Page switching: show only the active page's Parts.
- Each page keeps its own selected Part paths when switching away and back.
- Select All and Clear Selection affect only the active page.
- Apply transfers only the currently selected Parts from the active page.

Page captions use **PROCESS-MATERIAL** order: `CNC-SUS304`, `CG-SS400`.

## 3. Architecture

### Search and mapping
- Reuses the ver-02 recursive Assembly collector and exact AND predicate.
- Reads `sd-inq-part-density :instance` and `:contents`.
- Normalizes the tested API scale by dividing by 1000.
- Preserves the user's mappings:
  - Instance: CNC=1, KH=2, CG=3, COVER=4.
  - Base: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
- Display labels are never search inputs.

### One Browser and many pages
- One Browser Tree stores a root for each page.
- Each page root owns its Part BrowserNodes.
- One Graphical Browser and one table display the active page root's direct children.
- The same visible Browser handles row selection and retains the unmodified native Apply default.
- Page buttons are generated through Graphical Browser `:modeMenu` with one button per page. PTC 20.6 documents this as a horizontal row of toggle buttons; exact Modeling 18.1 rendering and callback behavior remain unverified.
- The Browser is rebuilt under the same named Browser/Tree after a successful search so the page-button row can include newly created pages. This is automatic and does not require a second user-facing Results window or a manual reopen command.

### Critical page-root isolation
A Graphical Browser can retain multiple table roots. Every page activation must:
1. Buffer redraw.
2. Clear the current Browser selection.
3. Clear all table roots.
4. Set the requested page root.
5. Resume redraw.
6. Trace the result and fail closed if clearing or setting the root fails.

The trace optionally records `:number-of-table-roots`; when supported, it must report exactly 1 after each page switch. This command sequence is documented in the PTC 20.6 reference, not yet runtime-confirmed in 18.1.

## 4. Apply safety boundary

- Never replace native Apply with a custom Apply callback.
- Never transfer UICT Display Table selections into a hidden Browser.
- Never treat `:SUCCESS`, a non-NIL command result, a BrowserNode count, or a persistent highlight as proof of Modeling selection.
- The only acceptance evidence is that the intended Part(s) are visibly selected in the actual 3D viewport after pressing Apply.
- Use a disposable copy of an Assembly, not the original/customer model.

## 5. Runtime acceptance plan

| Test | Action | Required result |
|---|---|---|
| 1. First page | Search CNC + SUS304 | One Results Browser; page button CNC-SUS304; only matching Parts shown |
| 2. Add page | Search CG + SS400 | Same Results Browser workflow; two horizontal page buttons; active page is CG-SS400 |
| 3. Root isolation | Switch between both pages | Only active page rows shown; trace reports one table root where query is supported |
| 4. Row selection | Select one row, then Ctrl-select another | Correct rows selected in the visible Browser |
| 5. Page-local state | Select rows on page A, switch to B and select rows, return to A | A and B retain independent selection |
| 6. Select All | Press Select All on active page | All and only active-page rows selected |
| 7. Clear Selection | Press Clear Selection | Only active-page selection cleared |
| 8. Native Apply | Select one/multiple rows and press Apply | Only intended actual Parts become selected in the 3D viewport |
| 9. Same-pair refresh | Search CNC + SUS304 again | Existing CNC-SUS304 page refreshed; no duplicate page; that page's old selection cleared |
| 10. No-match | Search a pair with no matching Parts | Existing pages/data remain unchanged |
| 11. Repeat lifecycle | Perform multiple successful searches | Never more than one Results Browser is visible; no manual reopen or UICT transition |

## 6. Known limitations / evidence

- Static source checks do not establish Modeling 18.1 API availability or UI behavior.
- The modeMenu page-button row is documented in later PTC releases, not confirmed in 18.1.
- Native Apply is retained from ver-02, but Apply behavior with page-rooted multi-page BrowserNodes is not yet user-confirmed.
- The ver-02 recursive collector is intentionally preserved; do not rewrite traversal or change the Density predicate/mapping without a separate, evidence-led investigation.
- The source rebuilds the same named Browser/Tree after successful searches so the modeMenu can be regenerated. This is automatic; it must not create multiple visible Results windows.

## 7. Trace and reporting

Trace file: `H871_PF_V05_SINGLE_BROWSER_TRACE.txt` in the user's home folder.

Important markers:
- `SEARCH/PAGE-STORED`
- `TREE/BUILT`
- `PAGE/SAVE-SELECTION`
- `PAGE/CHANGE-ROOT` (includes clear-roots status, set-root status and optional root count)
- `PAGE/RESTORE-ROW`
- `PAGE/ACTIVE`
- `LIFECYCLE/RESET-BROWSER-AND-TREE`

When a runtime test fails, preserve the exact error and the final trace lines. Do not make another speculative API/UI rewrite before locating the failing stage.


## 2026-11-16 – critical page-selector UI correction

The first ver-05 implementation incorrectly used Graphical Browser :modeMenu for the page strip. PTC's Graphical Browser reference explicitly says modeMenu and buttonMenu are mapped to right-click popup entries for compatibility; the visible horizontal row is buttonMenu. This explains why the user saw a ver-02-like Results table without visible page selectors.

The source now builds the Density-pair page selectors dynamically through :buttonMenu. Each page gets a horizontal push button whose callback activates that page root. Select All and Clear Selection are appended to the same horizontal row. The incorrect modeMenu page selector configuration and duplicate right-click Results Pages popup installation have been removed.

These are horizontal page-navigation buttons, not proven native UICT-style tab controls with mutually-exclusive selected styling. The active page is identified in the Browser status line. Runtime visibility and callback behavior in Modeling 18.1 remain unverified.
