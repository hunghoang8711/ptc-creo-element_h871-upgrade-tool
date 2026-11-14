# Source Code

Maintained LISP source and related implementation assets.

## Rules

- Preserve an untouched or known-good Git baseline before risky changes.
- Keep diagnostic utilities separate from production commands.
- Include purpose, command entry point, target version, and relevant compatibility notes in each source header.
- Do not commit customer-sensitive models, proprietary drawings, credentials, or personal data without approval.

## Part Filter files

- `part-filter/H871_PART_FILTER.lsp` – current Density Instance + Density Base filter and standalone Graphical Browser results UI. User-confirmed runtime behavior: result rows display, Select All is available, individual rows can be selected, and native Apply transfers selected Parts to Modeling selection.
- `part-filter/H871_PART_FILTER_DIAG.lsp` – preserved diagnostic/early filter baseline. Do not treat it as the current production implementation.

Always inspect the source before editing. Documentation does not replace checking the actual function signatures and code paths in the current file.
