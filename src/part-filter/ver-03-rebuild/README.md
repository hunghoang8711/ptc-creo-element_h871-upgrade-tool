# ver-03 Native Browser Rebuild Reference

**Source:** `H871_PART_FILTER_VER_03_REBUILD.lsp`  
**Derived from:** preserved ver-02 native Graphical Browser baseline  
**Target:** Creo Elements/Direct Modeling 18.1  
**Status:** Reference candidate; not complete.

This source is kept separately from `../ver-03/`, which is the older UICT/internal-tab implementation. Do not merge their runtime status or Apply behavior.

## Current user-reported result (2026-11-17)

- Results Browser opens.
- Only Part Name is visible.
- Density Instance, Density Base and Assembly Path are not visible, although four custom column definitions exist in source.
- A change that moved active-table selection and `:set-table-mode` after Browser show/root assignment did not improve the result.

## Next diagnostic

Do not make another speculative Browser lifecycle-order change. First inspect in Modeling 18.1:
- whether the Browser is actually in Table Mode;
- which custom table is active;
- how many table roots are assigned;
- return values from table definition and activation;
- the full Results window and horizontal scroll position.

Keep Density collection, mappings, row client data, selection and native Apply unchanged while diagnosing the column visibility issue. Re-test direct row selection, Select All, Clear Selection and actual viewport Apply after any eventual fix.

This source is preserved as an engineering reference, not as a user-confirmed complete version.
