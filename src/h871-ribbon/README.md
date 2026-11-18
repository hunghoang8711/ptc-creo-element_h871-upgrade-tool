# H871 Ribbon Integration – Phase 1

**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Status:** User-confirmed working in Modeling 18.1 (2026-11-18).

This package exposes the existing H871 Part Filter Lisp dialog as a native user-defined command that can be placed on a custom Ribbon tab/group. It does **not** rewrite or patch the Part Filter Lisp core.

## Confirmed setup

- Existing Part Filter Lisp source loads and works normally.
- User-defined command is saved in Modeling's Customize / Commands interface.
- Command appears in the custom command group `H871-TOOL`.
- A custom Ribbon group/tool has been created.
- The H871 Ribbon button is visible and clicking it launches the Part Filter successfully.

## Command definition

- Application: `SolidDesigner`
- Group: `H871-TOOL` (user's confirmed Customize group)
- Command: `H871 Part Filter - All Pages`
- Display title: `H871 Part Filter`
- Action: `H871_PART_FILTER_VER_03`
- Icon resource: `H871/part_filter` (32×32 BMP)

## Files

- `H871_AVAILABLE_COMMANDS_SNIPPET.cmd` – Available Command syntax reference. This is **not** a Lisp file; do not use Lisp `(load ...)` on it.
- `tools/Generate-H871Icon.ps1` – creates the 32×32 BMP icon in the personal Modeling customization directory.
- `INSTALL_AND_TEST.md` – detailed step-by-step installation, Customize command registration, Ribbon placement and runtime verification guide.

## Important runtime boundary

The confirmed button dispatches the existing dialog command. The Lisp core must already be loaded in the current Modeling session. Automatic startup loading and multi-workstation deployment are future phases, not part of this confirmed implementation.

Keep factory customization files and existing user customization files safe. Never replace `sd_avail_cmds.cmd`, an existing `user_avail_cmds.cmd`, or unrelated Ribbon customization files just to install this tool.


## Portable installation helper (release 0.1)

A safe copy-based installer is available under portable/:

- portable/Install-H871.ps1 – copies the canonical Lisp source and command reference, generates the icon in a user-selected customization directory, and writes the exact LOAD expression.
- portable/README_INSTALL.txt – workstation transfer and installation instructions.
- portable/INSTALLER_SCOPE.md – scope, safety behavior and acceptance checklist.

The installer stops if target files already exist. Use -Force only when replacement is intended; existing targets are backed up first. It does not write to user_avail_cmds.cmd, sd_avail_cmds.cmd or Ribbon customization files. Command registration and Ribbon placement remain manual through Modeling 18.1 Customize UI. Manual LOAD remains required in each session.
