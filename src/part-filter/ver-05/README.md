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

No Creo Elements/Direct Modeling 18.1 runtime is available in the development environment. Therefore multiple simultaneous Browser windows, Browser Tree callback timing, manager control layout, native Apply and the fatal `0xc00000fd` behavior are NOT runtime-confirmed. Do not call VER-05 fixed until the mandatory runtime sequence is completed.

## Known risk

The Assembly collector is deliberately preserved from VER-03 to avoid changing the search engine while replacing the results UI. It remains recursive. Earlier iterative traversal did not resolve the user's reported `0xc00000fd` exception, so the exception's root cause is unresolved. Test only on a disposable model copy and capture the trace/crash evidence.