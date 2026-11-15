# Source Code

Target: PTC Creo Elements/Direct Modeling 18.1.

## Part Filter version layout

- `part-filter/ver-01/H871_PART_FILTER_VER_01.lsp` – preserved user-confirmed numeric Density pair baseline.
- `part-filter/ver-02/H871_PART_FILTER_VER_02.lsp` – mapped Machining Process + Material convention dialog; user reported very good results.
- `part-filter/ver-03/README.md` – corrected single-window internal-tabs specification and test plan. No new ver-03 LISP implementation exists yet.
- `part-filter/H871_PART_FILTER.lsp` – legacy ver-01 path retained for older LOAD instructions.
- `part-filter/H871_PART_FILTER_VER_02.lsp` – legacy ver-02 path retained for older LOAD instructions.
- `part-filter/H871_PART_FILTER_DIAG.lsp` – diagnostic/early filter exploration; not the production source.

## Rules

1. Never overwrite a user-confirmed version. Create a new `ver-XX` folder for a new iteration.
2. Work directly on `main`; no branch per version.
3. Keep diagnostic utilities separate from production commands.
4. Include purpose, command entry point, target version and compatibility notes in each source header.
5. Do not commit customer-sensitive models, proprietary drawings, credentials or personal data.
6. Inspect source and shared knowledge docs before editing.
7. Update the AI handover and engineering knowledge base after meaningful discoveries.
8. Clearly distinguish specified, implemented, static-checked, loaded, functionally tested and user-confirmed states.
