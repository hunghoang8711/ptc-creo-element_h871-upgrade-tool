# Direct Part Selection Research

Target runtime: PTC Creo Elements/Direct Modeling 18.1.

## Baseline protection

- Official baseline: `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp`
- Official baseline blob SHA: `45b39cbad1271fd083622380f5764c3c92a1548c`
- This research branch was created from `main`.
- VER-03 source is unchanged in this branch.
- Do not replace or disable the VER-03 Apply Bridge until direct selection is proven in the user's Modeling 18.1 runtime.

## Stage 1: SEL_ITEM handle probe

Probe file:

`H871_PF_V03_SELITEM_PROBE.lsp`

Load it after VER-03. Select one or more rows in the active Results tab, then run:

`H871_PF_V03_SELITEM_PROBE`

The probe reads the selected rows' hidden `:part-object` values and writes:

`H871_PF_V03_SELITEM_PROBE.txt`

in the user's home directory.

It records:
- Lisp `TYPE-OF` of each stored Part reference.
- Whether `SD-INQ-PART-P` accepts the reference.
- The reference pathname.
- The result of `SD-PATHNAME-TO-OBJ` for that pathname.
- Whether the round-trip reference is recognized as a Part and resolves to the same pathname.

The probe is non-mutating: it does not create BrowserNodes, open a Graphical Browser, alter model geometry, or modify Modeling's active selection. It does not call `SEL_ITEM-P`, which was reported undefined in an earlier Modeling 18.1 diagnostic attempt.

## Findings from PTC Integration Kit documentation

1. `SD-INQ-OBJ-CHILDREN` returns child objects as `SEL_ITEM` values.
2. `SD-PATHNAME-TO-OBJ` converts a pathname string into a `SEL_ITEM`.
3. `SEL_ITEM` values are temporary handles and must not be treated as permanent identifiers across model modifications.
4. PTC documents `GET_SELECTION` as a selector/inquiry action that returns `SEL_ITEM` values; it is not documented as a generic API for assigning an arbitrary list to Modeling's current selection.
5. The Graphical Browser's `:SET-OBJECT-SELECTION` operates on visible BrowserNode structures. The `:SELECT-AND-EXECUTE` command performs the hand-off from browser selection into Modeling's selection/action context.

Relevant PTC references (later Integration Kit documentation; verify runtime behavior on 18.1):
- SEL_ITEM, pathname conversion, object children: https://support.ptc.com/help/creo_elements_direct/r20.5.0.0/advanced_documentation/integration_kit/reference/inq_obj.html
- GET_SELECTION: https://support.ptc.com/help/creo_elements_direct/r20.6.0.0/advanced_documentation/integration_kit/reference/get_selection.html
- Graphical Browser commands: https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/reference/gbrowser.html
- User command/action context and SEL_ITEM action parameters: https://support.ptc.com/help/creo_elements_direct/r20.6.0.0/advanced_documentation/integration_kit/concepts/user_cmd.html

## Stage 1 acceptance criteria

- Probe runs without a LISP error in Modeling 18.1.
- Selected row count matches the selected Results rows.
- Each raw `:part-object` reference is accepted by `SD-INQ-PART-P`.
- Each pathname round-trip returns a valid Part reference.
- Reported path matches the original path.

This only validates Part/SEL_ITEM handles. It does **not** prove that Modeling's active selection can be assigned directly without a Graphical Browser.

## Next stages

- Stage 2: investigate a documented, non-Graphical-Browser way to submit a list of Part SEL_ITEMs into Modeling's selection/action context.
- Stage 3: runtime-test one Part, then multiple Parts.
- Stage 4: only after successful runtime validation, implement an alternative Apply path behind a separate experimental command. Keep VER-03 Apply Bridge available until the alternative is proven.


## 2026-11-17 — Stage 1 probe correction

- First Modeling 18.1 runtime attempt stopped before reading any selected rows:
  `The variable *H871-PF-V03-CURRENT-PAGE* is unbound.`
- This is a probe-side assumption failure, not evidence of a VER-03 Results or Apply Bridge regression. The original probe assumed the current-page variable would be bound in the callback runtime.
- Updated `H871_PF_V03_SELITEM_PROBE.lsp` to avoid directly requiring the current-page variable. It now scans the registered VER-03 page registry and inspects selected rows on each registered table.
- The revised report records whether the current-page variable and page registry are bound, the registered page count, and each page with selected Part rows.
- Static validation after the correction: balanced parentheses, no unterminated strings. This is not a Modeling 18.1 runtime pass.
- Next test: reload the revised probe file in the same Modeling session where VER-03 is already loaded, select one or more rows in Results, and run `H871_PF_V03_SELITEM_PROBE`. Send `H871_PF_V03_SELITEM_PROBE.txt` from the user home folder.


## 2026-11-17 — V2 isolated command after repeated unbound-variable error

- User confirmed the error occurs when running the probe command (not while loading the file).
- The previous revision still contained a conditional read of the current-page variable and reused the original dialog command name. To eliminate both possible sources, the probe has been isolated under new function/dialog symbols.
- New command: `H871_PF_V03_SELITEM_PROBE_V2`.
- New report: `H871_PF_V03_SELITEM_PROBE_V2.txt`.
- V2 contains no reference to the VER-03 current-page variable and does not reuse the V1 dialog/function symbols. It scans only the registered page list and reads selected rows.
- Static validation is required before runtime; the V2 test is not yet confirmed in Modeling 18.1.
- User test: load the updated probe file, run the new command name exactly (do not run V1), then send the V2 report or exact error.


## 2026-11-17 — V2 runtime result: VER-03 registry symbol unbound

- User ran `H871_PF_V03_SELITEM_PROBE_V2`; command completed without a LISP error.
- Report: `Page registry bound: NIL`, `Registered page count: 0`.
- The official VER-03 source declares `(defvar *h871-pf-v03-pages* nil)` in package `:oli`. If that exact source has been loaded in the same Modeling session/package, the symbol should be bound even when its value is NIL.
- Therefore this result does not establish that no rows are selected and does not yet test the runtime type of the stored Part handles. It indicates the probe's `:oli` environment cannot see the registry symbol expected from the official VER-03 source.
- Next diagnostic is to establish whether the official VER-03 file was loaded in this same Modeling session before V2. Do not modify the official VER-03 file or Apply Bridge based on this result.


## 2026-11-17 — V1 runtime confirms selected cells contain ELAN::SEL_ITEM

- User ran the original V1 probe while the VER-03 Results window was open and four rows were selected.
- All four hidden `:part-object` values had `TYPE-OF = ELAN::SEL_ITEM`.
- For all four, `sd-inq-part-p`, `sd-inq-obj-pathname`, and the pathname roundtrip returned NIL.
- This proves the Results table is returning SEL_ITEM-typed structures, but it does not yet prove the handles resolve to live Part objects. Do not treat NIL from these inquiries as proof of invalid handles until the correct SEL_ITEM accessor/package is checked.
- PTC Integration Kit references describe `sel_item-p` and `sel_item-type` as SEL_ITEM structure accessors. A V3 non-mutating probe was added to resolve and call these accessors in both :ELAN and :OLI, then also record basename/pathname/sysid inquiries.
- V3 command: `H871_PF_V03_SELITEM_PROBE_V3`; report: `H871_PF_V03_SELITEM_PROBE_V3.txt`.
- No changes to official VER-03 or its Apply Bridge. V3 still requires user runtime validation in Modeling 18.1.



## 2026-11-17 — V3 caused fatal Modeling 18.1 exception

- User ran `H871_PF_V03_SELITEM_PROBE_V3` and Modeling terminated with fatal exception `0xc00000fd` (Windows status commonly associated with stack overflow).
- The crash occurred during the V3 command. The exact failing call is unknown because V3 invoked several candidate functions dynamically (`SEL_ITEM-P`, `SEL_ITEM-TYPE` in :ELAN/:OLI) and then several object inquiry functions for each selected handle.
- `ignore-errors` cannot protect against a native process-level crash; the V3 probe must be considered unsafe for this Modeling 18.1 runtime.
- Stop running V3. Do not repeat it, and do not test the candidate accessors by direct invocation in Modeling 18.1.
- The user was testing a disposable sample model, so no original production model was at risk. Nevertheless, after any fatal exception, restart Modeling cleanly and do not save/overwrite important model data from the crashed session.
- Existing V1 evidence remains valid: four selected result cells yielded values whose `TYPE-OF` was `ELAN::SEL_ITEM`; V1's `SD-INQ-PART-P` and pathname inquiries returned NIL. This does not establish that the handles are invalid.
- Next research must avoid executing unverified SEL_ITEM accessors. First inspect the exact 18.1 Integration Kit documentation/signatures or use a strictly passive symbol-availability/type-only diagnostic. If no safe, documented route exists, retain the Apply Bridge rather than risking another native crash.
- No change to official VER-03, Results UI, or Apply Bridge.
