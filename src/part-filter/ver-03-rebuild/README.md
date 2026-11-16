# ver-03 Rebuild — Stage 0 baseline

**Branch:** `rebuild/ver-03-from-ver-02`  
**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Status:** Source baseline created; runtime test required before any feature work.

## Purpose

This rebuild deliberately starts from the user-confirmed ver-02 implementation rather than the unstable UICT-based ver-03 implementation.

## Baseline source

- `H871_PART_FILTER_VER_03_REBUILD.lsp`
- Derived from `src/part-filter/ver-02/H871_PART_FILTER_VER_02.lsp`
- Original ver-02 source is not modified.
- Internal helper/global symbols use the isolated `h871-pf-rb-` prefix to avoid collisions if ver-02 and the rebuild are loaded in the same Creo session.
- Dialog command: `H871_PART_FILTER_VER_03_REBUILD`

## What this stage contains

This is a mechanical baseline clone of ver-02 behavior:
- Same Filter dialog structure and numeric mappings.
- Same recursive Density Instance + Density Base search semantics.
- Same native Graphical Browser Results UI.
- Same native row selection, Select All, Clear Selection, and Apply behavior.
- No UICT Display Table, no logical table, no internal tabs, and no hidden Apply bridge.
- No new Search callback, collection, or selection algorithm.

## Required Stage 0 runtime test

Use a disposable model copy, never the original customer model.

1. Load this file.
2. Run `H871_PART_FILTER_VER_03_REBUILD`.
3. Search a known pair such as CNC + SUS304 (numeric Density Instance=1, Density Base=304).
4. Confirm matching rows appear in the Graphical Browser.
5. Select one row and Apply; confirm the corresponding Part becomes selected in Modeling.
6. Test Select All, Clear Selection, and multiple-row selection.
7. Confirm the Filter dialog can be closed normally.

**Do not start Stage 1 until the user confirms Stage 0 works in Modeling 18.1.**

## Safety and versioning

- ver-01 and ver-02 remain immutable regression baselines.
- Existing `src/part-filter/ver-03/` remains preserved for forensic reference; it is not the active rebuild base.
- Every later feature must be added as one small isolated change and runtime-tested before proceeding.
