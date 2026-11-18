# 01 – Platform, Language and Environment

## Target environment
- Product: **PTC Creo Elements/Direct Modeling 18.1**.
- Not Creo Parametric.
- User has basic Lisp experience and benefits from exact LOAD instructions, command names, test steps and expected outcomes.
- Initial tool interests (conversation 2026-10-09): drawing, dimension/geometry measurement, data export, command/menu/Ribbon access and manual loading.

## Language distinction
Two source families have appeared in user-provided material:

### Creo/Modeling Lisp and Integration Kit
Common Lisp-like syntax such as `(defun ...)`, `(load ...)`, package use, `sd-inq-...`, `sd-create-...`, `sd-defdialog`. This runs in the Modeling Lisp environment and exposes Integration Kit functions.

### Legacy Annotation / ME10 command language
Syntax such as:
```
DEFINE Docu_create_sheet
  PARAMETER Sheet_name
  LET ...
  EDIT_PART ...
END_DEFINE
```
This is a separate command/macro language used by the Annotation module. Uploaded sources identify themselves as Annotation or ME10 macros. Do not assume these are Lisp files or load them using Lisp `(load ...)`.

## Compatibility discipline
- Verify function existence and signatures in Modeling 18.1.
- Later-release PTC documentation (e.g. 20.x UICT references) is useful for finding candidate APIs but not proof of 18.1 compatibility.
- Distinguish native Modeling commands, Integration Kit Lisp functions, Annotation-specific macros, and optional modules.
- For every inquiry, record units and whether the result is a Part, Assembly, occurrence, selection item, unique ID, name or path.
- Never generalize units/scaling between unrelated properties.

## Startup and command exposure
- The user previously asked about Ribbon/menu and command integration.
- A proposed `*_avail_cmds.cmd` file and `am_customize` startup path were discussed, but actual 18.1 startup/menu registration was not confirmed.
- User explicitly reported that `am_customize` was not available in their environment during the Annotation frame investigation.
- Treat `docu-register-frame`, `am_customize` and any assumed startup registration as unverified unless a target-version test proves them.

## Measurement/export
- A preliminary `measure_export.lsp` and `measure_export_avail_cmds.cmd` concept was discussed on 2026-10-09.
- Real geometry measurement APIs, units, edge/face/axis selection and 18.1 syntax were not verified.
- Do not resurrect the draft as production code without first identifying a documented and tested inquiry path and a small test model.


## Native Ribbon / Available Commands
- Modeling's Fluent UI was introduced in Creo Elements/Direct Modeling 18.0; the target 18.1 generation therefore has a Ribbon-based UI.
- PTC later-release Integration Kit documentation describes Available Commands as the basis for Ribbon/toolbars/context menus. Command identity is Application + Group + Command; an action string is sent through the Modeling input buffer; a custom icon is a BMP resolved under `bitmaps/bmp/commands/` in the customization directory.
- Available Command customization files are not normal Lisp files. Do not load a `.cmd` definition using Lisp `(load ...)`.
- For H871's first integration test, preserve the Part Filter core and create one user-defined command whose action is `h871_part_filter_ver_03`. Keep automatic startup loading deferred until the command and icon have been confirmed in the exact 18.1 installation.
- Current package and test procedure: `src/h871-ribbon/README.md` and `src/h871-ribbon/INSTALL_AND_TEST.md`.
- Evidence note: detailed file syntax and icon search behavior are from later-release documentation; exact 18.1 behavior still requires user runtime confirmation.
