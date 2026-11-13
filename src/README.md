# Source Code

Place maintained LISP source files and related implementation assets in this directory.

## Rules

- Preserve the original source filename when importing an existing utility.
- Before editing, keep a known baseline in Git so changes can be reviewed and reverted.
- Use descriptive filenames; include a version suffix only when parallel versions genuinely need to coexist.
- Keep diagnostic utilities separate from production commands unless there is a clear reason to combine them.
- Add a short header to each source file describing purpose, command entry point, target Creo version, dependencies, and revision date.
- Do not commit credentials, customer-sensitive models, or proprietary data without approval.

No production source files have been imported yet.

## Part filter source files

- `part-filter/H871_PART_FILTER_DIAG.lsp`: uploaded diagnostic baseline; preserved unchanged.
- `part-filter/H871_PART_FILTER.lsp`: first exact Density Instance/Base filter implementation. Load and test this file in Creo Elements/Direct Modeling 18.1. The dialog defaults to Instance 1.0 and Base 304.0 and writes matches to `H871_PART_FILTER_RESULT.txt` in the user's home directory.
- Do not treat static checks as proof of successful loading or functional behavior in Creo.
