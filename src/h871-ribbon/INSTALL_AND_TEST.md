# H871 Ribbon Integration – Install & Runtime Test

**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Runtime status:** User-confirmed working in Modeling 18.1 on 2026-11-18.

This package exposes the existing H871 Part Filter Lisp dialog as a native user-defined command and Ribbon button. It does not modify the Part Filter Lisp core.

## 1. What the completed setup looks like

The user has confirmed the following workflow on Modeling 18.1:

1. The Part Filter Lisp source loads and works normally.
2. The H871 command is saved through Modeling's Customize / Commands interface.
3. The command is visible in the custom command group named `H871-TOOL`.
4. A custom Ribbon group/tool has been created in the Modeling UI.
5. The H871 Ribbon button is visible and clicking it launches the Part Filter successfully.

This is direct user runtime confirmation, not merely a source or documentation check.

## 2. Files in this package

- `H871_AVAILABLE_COMMANDS_SNIPPET.cmd` – Integration Kit Available Command reference. It is **not** a normal Lisp file; never use Lisp `(load ...)` on it.
- `tools/Generate-H871Icon.ps1` – generates a 32×32 BMP icon.
- `INSTALL_AND_TEST.md` – this installation and verification guide.

## 3. Prepare safely

1. Keep a backup of the current Modeling customization settings before changing them.
2. For the first functional test, save the active model as a separate disposable file. Do not test new UI integrations on the only copy of a customer model.
3. Start Creo Elements/Direct Modeling 18.1.
4. Load the existing core source through the Modeling Lisp command/input line:

```lisp
(load "C:/REPLACE_WITH_YOUR_REPOSITORY_PATH/src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp")
```

Replace the example path with the actual local repository path. Confirm that the Lisp file finishes loading without an error and that the Part Filter can still be opened by its command.

**Important:** The initial integration deliberately uses manual Lisp loading. The Ribbon command dispatches the existing dialog; it does not itself load the Lisp source. Automatic startup loading is a separate future enhancement.

## 4. Generate the custom icon

Open PowerShell and run the script from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\src\h871-ribbon\tools\Generate-H871Icon.ps1 -CustomizationDirectory "C:\PATH\TO\YOUR\MODELING\PERSONAL\CUSTOMIZATION"
```

Replace the directory with the personal Modeling customization directory used by this installation.

The script creates:

```text
bitmaps\bmp\commands\H871\part_filter.bmp
```

The generated image is 32×32 pixels. Use the personal customization directory rather than writing into the factory Modeling installation directory.

## 5. Register the user-defined command

The command must be registered before it can be placed in a Ribbon group.

1. Open Modeling's **Customize** interface.
2. Open the **Commands** page/section.
3. Select or create the custom command group. In the confirmed setup, the group is named **H871-TOOL**.
4. Choose **New** (or the equivalent command-creation action in the installed UI).
5. Define the command using the following values. UI field labels can differ slightly between installations.

| Setting | Value |
|---|---|
| Application | `SolidDesigner` / Modeling |
| Group | `H871-TOOL` (the user's custom group) |
| Command name | `H871 Part Filter - All Pages` |
| Title / display text | `H871 Part Filter` |
| Action / command text | `H871_PART_FILTER_VER_03` |
| Description / tooltip | `Open the H871 Part Filter with Part Note and cross-page selection.` |
| Icon | The generated `part_filter.bmp` |

6. Browse to the generated BMP if the Customize UI provides an icon selector.
7. Save/apply the command customization.
8. Confirm that **H871 Part Filter** is listed in the custom **H871-TOOL** command group.

The important command action is the existing Modeling command name `H871_PART_FILTER_VER_03`. Do not replace it with the filename of the Lisp source.

## 6. Place the command on the Ribbon

Command registration and Ribbon placement are separate operations.

1. Open the Ribbon customization interface in Modeling.
2. Create a custom Ribbon tab, for example **H871**, or select an existing custom tab.
3. Create a Ribbon group, for example **H871-TOOL**.
4. In the available command list, locate the user-defined **H871 Part Filter** command created in the previous section.
5. Add/drag that command into the custom Ribbon group.
6. Apply/save the Ribbon customization.
7. Close the customization interface and verify that the H871 tab/group is visible in the normal Modeling workspace.

The exact location and wording of Customize controls may vary. The procedure above describes the logical sequence that was successfully completed by the user in Modeling 18.1: first save the command in Customize / Commands, then create the Ribbon group and place the saved command there.

## 7. Runtime acceptance checklist

The following items have been confirmed by the user on 2026-11-18:

- [x] Existing Lisp source loads and the Part Filter is usable.
- [x] User-defined H871 command is saved in Customize.
- [x] Command appears in the custom `H871-TOOL` command group.
- [x] Custom Ribbon group/tool is created in Modeling.
- [x] H871 Ribbon button is visible.
- [x] Clicking the Ribbon button launches the Part Filter successfully.

For a fresh workstation or after changing customization files, also verify:

- [ ] Custom icon is displayed correctly (not a missing-image placeholder).
- [ ] Tooltip/display text is correct.
- [ ] Search, selection, Apply and Edit Note still behave as expected.
- [ ] Cross-page controls are individually regression-tested; confirmation of Select All Pages does not by itself prove Clear All Pages or Apply All Pages.

## 8. Important safety and maintenance notes

- Do not overwrite factory files such as `sd_avail_cmds.cmd`.
- Do not overwrite an existing `user_avail_cmds.cmd`; use Modeling's Customize UI or back up and carefully merge entries if manual integration is ever required.
- Do not overwrite existing Ribbon customization files or unrelated user commands.
- The `.cmd` snippet uses Integration Kit Available Commands syntax. It is not ordinary Lisp source and must not be loaded with `(load ...)`.
- Keep the current Part Filter Lisp core separate from the Ribbon wrapper. Ribbon registration should call the existing dialog rather than duplicate or rewrite its logic.
- The current confirmed workflow requires the Lisp source to have been loaded in the Modeling session. Startup auto-loading and deployment to multiple workstations are not included in this phase.
