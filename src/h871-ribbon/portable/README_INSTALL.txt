H871 PART FILTER - PORTABLE INSTALLER
Target: PTC Creo Elements/Direct Modeling 18.1

PACKAGE CONTENTS
- Install-H871.ps1: copies the existing Part Filter Lisp and command reference.
- Canonical source: src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp
- Icon generator: src/h871-ribbon/tools/Generate-H871Icon.ps1
- No Part Filter source logic is changed by installation.

BEFORE INSTALLING
1. Download the complete repository ZIP from:
   https://github.com/hunghoang8711/ptc-creo-element_h871-upgrade-tool
2. Extract the ZIP. Do not copy only the portable folder; the installer needs other source files in the repository.
3. Close Creo Elements/Direct Modeling 18.1 before changing its customization icon folder.
4. Back up the target workstation's Modeling customization directory.
5. Identify the personal Modeling customization directory used by this installation. Do not guess a factory installation path.

RUN
Open PowerShell in the extracted repository root and run:

powershell -ExecutionPolicy Bypass -File .\src\h871-ribbon\portable\Install-H871.ps1 -CustomizationDirectory "C:\YOUR\MODELING\CUSTOMIZATION"

Optional custom install directory:

powershell -ExecutionPolicy Bypass -File .\src\h871-ribbon\portable\Install-H871.ps1 -CustomizationDirectory "C:\YOUR\MODELING\CUSTOMIZATION" -InstallDirectory "D:\H871\PartFilter"

If targets already exist, the installer stops. To replace them, explicitly add -Force. Existing target files are copied to a timestamped backup folder before replacement.

WHAT THE INSTALLER DOES
1. Copies the canonical Part Filter Lisp into the selected H871 install directory.
2. Copies the Available Command reference file into that directory.
3. Generates the 32x32 icon under:
   <CustomizationDirectory>\bitmaps\bmp\commands\H871\part_filter.bmp
4. Writes LOAD_H871_PART_FILTER.txt with the exact Lisp LOAD expression.

WHAT IT DOES NOT DO
- It does not modify user_avail_cmds.cmd or sd_avail_cmds.cmd.
- It does not automatically register a command inside Modeling.
- It does not import/export or rewrite Ribbon customization.
- It does not configure automatic startup loading.
- It does not modify the original Part Filter source in the extracted repository.
- It does not prove all Part Filter functions on a new workstation.

FINAL SETUP IN MODELING 18.1
1. Start Modeling and load the installed Lisp using the expression in LOAD_H871_PART_FILTER.txt.
2. Open Customize / Commands.
3. Create/save the user command using the values in H871_AVAILABLE_COMMANDS_SNIPPET.cmd:
   Application: SolidDesigner
   Group: H871-TOOL
   Command: H871 Part Filter - All Pages
   Title: H871 Part Filter
   Action: H871_PART_FILTER_VER_03
   Icon: H871/part_filter
4. Open Ribbon customization.
5. Add the saved command to the desired custom Ribbon tab/group.
6. Apply/save, close customization and click the Ribbon button.
7. Test Search, row selection, Apply, Edit Note and cross-page actions on a disposable model copy.

PORTABILITY BOUNDARY
The existing command/Ribbon workflow has been confirmed by the user on one Modeling 18.1 workstation. The exact mechanism for exporting/importing Ribbon customization across 18.1 workstations has not yet been verified. This installer deliberately leaves Ribbon placement as a short manual step instead of risking overwriting the target user's customization.

TROUBLESHOOTING
- Missing icon: verify that the selected customization directory is the active personal directory for this Modeling profile; restart Modeling if its icon cache has already loaded.
- Unknown command / button does nothing: confirm the installed Lisp was loaded in the current session and that the action is exactly H871_PART_FILTER_VER_03.
- Installer reports an existing file: inspect it first. Rerun with -Force only if replacement is intended; the previous file will be backed up.
- Do not test new builds on the only copy of a customer model.
