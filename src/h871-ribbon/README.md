# H871 Ribbon Integration – Phase 1

Target: PTC Creo Elements/Direct Modeling 18.1.

This package adds a native Modeling user-defined command that can be placed on a custom Ribbon tab/group or toolbar. It does **not** rewrite or patch the Part Filter Lisp core.

## Phase 1 scope

- Register one command: **H871 Part Filter – All Pages**.
- Command action: `H871_PART_FILTER_VER_03`.
- Optional custom BMP icon: `H871/part_filter`.
- User places the command on a custom H871 Ribbon group through Modeling's Customize UI.
- The existing Part Filter source remains the executable core.

## Files

- `H871_AVAILABLE_COMMANDS_SNIPPET.cmd` – available-command definition for manual integration/reference. This is **not** a Lisp file; do not use Lisp `(load ...)` on it.
- `tools/Generate-H871Icon.ps1` – creates a 32×32 BMP at the Modeling customization icon path.
- `INSTALL_AND_TEST.md` – exact first-install and acceptance procedure.

## First test – safest workflow

1. Make a disposable copy of the current model and open it in Modeling 18.1.
2. LOAD the exact current source:
   `src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp`.
3. Generate the icon in the personal Modeling customization directory (instructions below).
4. Use Modeling's Customize interface to create a user-defined command. Do not overwrite the factory `sd_avail_cmds.cmd` or any existing customization file.
5. Set the command action to `h871_part_filter_ver_03`, choose the generated icon, and add the command to a user-defined H871 Ribbon group.
6. Click the icon and confirm that the existing Part Filter dialog opens.

The core Lisp is manually loaded for this first proof. Automatic startup loading is intentionally a later phase, after the command dispatch and icon are confirmed on the target 18.1 installation.

## Compatibility boundary

PTC documentation for later Modeling releases describes Available Commands, Ribbon customization files, icon lookup and user customization storage. Fluent UI itself was introduced before 18.1, but exact command registration and icon behavior must still be confirmed in the user's Modeling 18.1 installation. Do not treat this repository package as runtime-verified until the user completes the test.
