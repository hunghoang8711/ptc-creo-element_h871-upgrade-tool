# H871 Ribbon Integration – Install & Runtime Test

## A. Prepare a safe test

1. Save the current model as a new disposable file. Do not run the first test on the only copy of a customer model.
2. Start PTC Creo Elements/Direct Modeling 18.1.
3. Load the existing core source using the Modeling Lisp command/input line:

```lisp
(load "C:/REPLACE_WITH_YOUR_REPOSITORY_PATH/src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp")
```

Replace the path with the real local path. The source must finish loading without a Lisp error.

## B. Generate the H871 icon

Open PowerShell and run the script from the repository:

```powershell
powershell -ExecutionPolicy Bypass -File .\src\h871-ribbon\tools\Generate-H871Icon.ps1 -CustomizationDirectory "C:\PATH\TO\YOUR\MODELING\PERSONAL\CUSTOMIZATION"
```

The script creates:

`bitmaps\bmp\commands\H871\part_filter.bmp`

inside the selected customization directory. The icon is 32×32 BMP. Do not put it in the Modeling installation directory; use the personal customization directory.

## C. Create the native command

Use Modeling's Customize interface (the exact menu wording can vary slightly by installation):

1. Open **File > Options** or right-click the Ribbon and open its customization/options dialog.
2. In the command customization area, create a **New / User-defined Command**.
3. Use these values:

| Field | Value |
|---|---|
| Application | `SolidDesigner` / Modeling |
| Group | `H871` |
| Command name | `H871 Part Filter - All Pages` |
| Title / Tooltip | `H871 Part Filter` |
| Action / Command text | `H871_PART_FILTER_VER_03` |
| Description | `Open the H871 Part Filter with Part Note and cross-page selection.` |
| Icon | Browse to the generated `part_filter.bmp` |

4. Save/close the customization dialog.
5. In the Ribbon customization page, create a custom tab named **H871** and a group named **Part Tools** (or add the command to an existing custom group).
6. Add the user-defined **H871 Part Filter - All Pages** command to that group and apply the changes.

If Modeling 18.1 exposes a different Customize layout, do not edit factory files to force the command in. Capture a screenshot of the available Customize pages and we will adapt the procedure to the actual 18.1 UI.

## D. Acceptance test

- [ ] H871 tab/group appears in the Ribbon.
- [ ] H871 Part Filter button displays the custom icon (not a missing-image placeholder).
- [ ] Tooltip reads H871 Part Filter.
- [ ] Clicking the button opens the existing Part Filter dialog.
- [ ] Search with a disposable assembly works as before.
- [ ] Existing page-local Select All, Clear Selection, Apply and Edit Note are unchanged.
- [ ] Select All Pages still works.
- [ ] Do not infer Clear All Pages or Apply All Pages are fixed; they need their own tests.

## E. Important notes

- This first phase intentionally requires the core Lisp file to be loaded before clicking the icon. Automatic startup loading will be added only after this command is confirmed working in Modeling 18.1.
- `H871_AVAILABLE_COMMANDS_SNIPPET.cmd` shows the Integration Kit Available Command syntax. It is not executable via Lisp `(load ...)`.
- Do not overwrite `sd_avail_cmds.cmd`, `user_avail_cmds.cmd`, `sd_ribbon.lsp` or existing toolbar files.
- Runtime status before user testing: **not yet tested in Modeling 18.1**.
