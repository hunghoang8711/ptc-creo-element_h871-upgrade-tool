# Source Code

Maintained LISP source and related implementation assets.

## Rules

- Preserve an untouched or known-good Git baseline before risky changes.
- Keep diagnostic utilities separate from production commands.
- Include purpose, command entry point, target version, and relevant compatibility notes in each source header.
- Do not commit customer-sensitive models, proprietary drawings, credentials, or personal data without approval.

## Part Filter files

- `part-filter/H871_PART_FILTER.lsp` – confirmed ver-01 numeric Density Instance + Density Base filter and standalone Graphical Browser. User-confirmed runtime behavior: result rows display, Select All is available, individual rows can be selected, and native Apply transfers selected Parts to Modeling selection.
- `part-filter/H871_PART_FILTER_VER_02.lsp` – user-confirmed mapped-choice dialog with fixed Machining Process/Material ranges and display-only code fields. Maps to the same Density pair.
- `part-filter/H871_PART_FILTER_VER_03.lsp` – independent multi-search sessions, unique Browser/Tree identities, per-Browser selection actions and docked-tab candidate. Requires Modeling 18.1 runtime testing.
- `part-filter/H871_PART_FILTER_DIAG.lsp` – preserved diagnostic/early filter baseline. Do not treat it as the current production implementation.

Commands: `H871_PART_FILTER_VER_02` and `H871_PART_FILTER_VER_03`. Inspect the relevant source before editing. ver-03 uses `:update-args`, `:createAsTab` and `:tabname` documented in later PTC references; verify compatibility in Modeling 18.1 before treating it as stable.
