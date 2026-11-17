# H871 Part Filter VER-06 — Standalone Structure Browser shell

**Branch:** `rebuild/ver06-structure-browser-shell`  
**Base:** known-good VER-02 native Graphical Browser workflow  
**Target:** PTC Creo Elements/Direct Modeling 18.1

## Why this branch exists

VER-04 through VER-06 experiments are not accepted as working deliverables. Their implementation attempts and failure observations are retained as lessons, but the new development path is reset to the known-good VER-02 baseline. The user explicitly authorized replacing the non-working VER-04–VER-06 implementation files.

The goal is now one independent H871 Results window that uses the native PTC Graphical Browser as its shell, styled and populated for the H871 Part Filter. This avoids recreating the native selection/Apply behavior in a custom UICT table.

## Stage 1 implemented: standalone Browser shell

Source: `H871_PART_FILTER_VER_06_STRUCTURE_BROWSER.lsp`

- Preserves the VER-02 Density Instance + Density Base matching engine and native Browser selection/Apply pattern.
- Creates one Graphical Browser for the current result set.
- Requests a floating window with `:createAsTab nil`, with larger maximum dimensions.
- Keeps native Apply, Select All and Clear Selection.
- Uses the existing BOM-like columns: Part Name, Density Instance, Density Base and Assembly Path.

### Important PTC behavior

PTC's Graphical Browser API documentation states that `:createAsTab` requests docked vs floating placement, but a preference stored in PDS from the previous Modeling session can override the argument. Therefore the floating-window result must be checked in the user's actual Modeling 18.1 session. If it appears docked, inspect/reset the Browser Bar/PDS placement preference rather than changing the result-tree code.

## Not implemented yet

- Editable notes panel / per-Part note persistence.
- Internal result tabs or multiple filter-pair workspaces inside one Browser.
- Interactive drag-resizing verification in Modeling 18.1.
- Any custom replacement for native Apply.

These are intentionally deferred until Stage 1 confirms that the single floating native Browser shell is created reliably in 18.1. A read-only table column must not be misrepresented as an editable note interface.

## Safe runtime test

Use a disposable Assembly copy.

1. Load the source in a fresh Modeling 18.1 session.
2. Run `H871_PART_FILTER_VER_06`.
3. Filter a known pair such as CNC-SUS304 (1-304).
4. Confirm exactly one H871 Results Browser appears as a separate floating window.
5. Confirm the four result columns and Part rows.
6. Select one Part and use native Apply; confirm the intended Part is selected in the 3D viewport.
7. Repeat with Select All and Clear Selection.
8. Record whether PDS forced the Browser into a docked tab despite `:createAsTab nil`.
9. Close and reopen the command once on the disposable copy; stop if any model-data warning or fatal exception appears.

## Validation status

- Source was derived from the VER-02 source that the user previously confirmed for native Browser selection and Apply.
- Static transformation performed: VER-02 symbols were namespaced to VER-06 and the Browser creation requests floating mode.
- **Not runtime-tested** in Modeling 18.1. Do not call this a working release until the user confirms the test sequence.
- Notes editor remains a separate design task. The next investigation is whether Modeling 18.1 exposes a supported in-Browser custom editable detail/control area; later-release Browser View APIs are not assumed available in 18.1.
