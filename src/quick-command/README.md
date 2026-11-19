# H871 Quick Command

**Target:** Creo Elements/Direct Modeling 18.1  
**Initial shortcut/UI decision:** `Ctrl + Space`, popup positioned near the mouse cursor.  
**Development status:** Core V0.1 committed; UI integration not yet verified.

## Goal

Build an AutoCAD-style command launcher for Modeling 18.1:

1. Press `Ctrl + Space` to open the command entry near the pointer.
2. Type the first characters of a command.
3. Show matching command suggestions while typing.
4. Navigate suggestions with Up/Down and execute with Enter.
5. Close with Esc.
6. Support native Modeling commands and H871 Lisp tools through a controlled registry.

## Source

- `H871_QUICK_COMMAND_CORE_V01.lsp` – command registry, case-insensitive prefix search, exact lookup and safe callback dispatch.

## Current implementation boundary

The core does not install keyboard hooks, capture mouse events, or change selection behavior. It also does not yet claim to provide the final floating autocomplete interface.

The following Modeling 18.1 integration points must be verified in the actual application before implementation:

- Reliable `Ctrl + Space` shortcut registration without conflicting with existing commands.
- A text-entry control that retains keyboard focus and reports text changes live.
- A popup/dialog position derived from the current pointer coordinates.
- Up/Down, Enter and Esc handling while the command input has focus.
- A safe dispatch route for registered native Modeling commands and H871 Lisp functions.

## Core smoke test

Load the Lisp source manually in Modeling 18.1, then run:

```lisp
(h871-qc-list "H")
(h871-qc-run "HQC")
```

Expected: the search lists `H871-QC-SELFTEST` and the exact alias dispatch prints a confirmation. This is a source-level smoke test only; it is not a substitute for runtime verification in Modeling.

## Safety rules

- Do not install global keyboard or mouse hooks until shortcut ownership and focus behavior are proven.
- Do not evaluate arbitrary text entered by the user as Lisp.
- Execute only exact commands registered in the command registry.
- Keep the command engine separate from the popup UI and Customize/Ribbon integration.
- Do not modify factory customization files or existing H871 tools as part of this feature.
- Mark each API and runtime behavior as verified only after testing in Creo Elements/Direct Modeling 18.1.

## Planned stages

1. **Core V0.1:** registry and prefix search.
2. **UI probe:** verify supported dialog/text-entry APIs and live input behavior.
3. **Popup V0.2:** pointer-positioned suggestion window.
4. **Shortcut V0.3:** register `Ctrl + Space` through a supported Modeling customization mechanism.
5. **Integration:** add existing H871 commands and verified native command dispatch.
6. **Regression:** confirm no interference with selection, mouse tools, command line or existing Ribbon commands.
