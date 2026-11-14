# Source Code

Maintained LISP source and related implementation assets.

## Rules

- Preserve an untouched or known-good Git baseline before risky changes.
- Keep diagnostic utilities separate from production commands.
- Include purpose, command entry point, target version, and relevant compatibility notes in each source header.
- Do not commit customer-sensitive models, proprietary drawings, credentials, or personal data without approval.

## Part Filter files

- `part-filter/H871_PART_FILTER.lsp` – confirmed ver-01 numeric Density Instance + Density Base filter and standalone Graphical Browser. User-confirmed runtime behavior: result rows display, Select All is available, individual rows can be selected, and native Apply transfers selected Parts to Modeling selection.
- `part-filter/H871_PART_FILTER_VER_02.lsp` – ver-02 candidate with fixed Machining Process/Material ranges and adjacent display-only code fields. Maps to the same Density pair; not yet tested in Modeling 18.1.
- `part-filter/H871_PART_FILTER_DIAG.lsp` – preserved diagnostic/early filter baseline. Do not treat it as the current production implementation.

The ver-02 command is `H871_PART_FILTER_VER_02`. Inspect the source before editing. Documentation does not replace runtime verification of API and dialog behavior in Modeling 18.1.
