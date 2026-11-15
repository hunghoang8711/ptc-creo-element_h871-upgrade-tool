# Part Filter ver-03 – Single Results Window with Internal Tabs

**Status: Specified – implementation pending.**

## Authoritative requirement

Build exactly one separate Results Browser window. Inside that window, provide horizontal tabs/pages similar to a desktop browser. Do not create multiple Graphical Browser windows and do not use Creo Browser Bar tabs.

## Page identity and lifecycle

- Key: exact pair `Density Instance + Density Base`.
- Caption: mapped Material + Machining Process, e.g. `SUS304-CNC`.
- First search for a pair creates its page.
- Repeating the same pair refreshes/replaces the existing page; no duplicate tab.
- A different pair creates a new page in the same Results window.
- Each page owns its result list and selection state where feasible.
- Switching pages must not mix rows or selections.
- Apply transfers only selected Part objects from the active page.
- A no-match search does not silently erase a previously valid page.

## Source baseline

Start from ver-02 source. Preserve:
- Assembly selection and recursive scan.
- Density Instance + Base exact pair matcher and normalization.
- Material/Process mapping.
- Result row data and display fields.
- Known-good native Graphical Browser selection/Apply semantics as a regression boundary.

Do not modify ver-01 or ver-02.

## Superseded experiment

The former file `H871_PART_FILTER_VER_03.lsp` on branch `feature/part-filter-multi-browser-sessions` created one Graphical Browser per search and requested Creo Browser Bar docking. That is the wrong architecture and must not be copied into this version folder or loaded as the intended ver-03.

## Technical investigation / staged prototype

UICT Tab Control and Dialog Shell may be a candidate, but current research references are from later PTC releases. Confirm exact Modeling 18.1 function availability and signatures.

Prototype in this order:
1. Minimal single-window tab shell with synthetic data only.
2. Verify create/add/switch/refresh/remove page operations.
3. Verify table row selection and Select All are isolated per page.
4. Verify selection can represent real Part objects.
5. Verify Apply transfers only active-page selected Parts to Modeling selection.
6. Integrate the ver-02 filter engine and pair-key refresh logic.
7. Test no-match behavior and all ver-01/ver-02 regressions.

If real-Part selection/Apply cannot be grounded, stop at a diagnostic shell prototype and document the blocker. Do not claim full implementation.

## Acceptance tests

See `tests/README.md` section “ver-03 internal-tab validation plan”.
