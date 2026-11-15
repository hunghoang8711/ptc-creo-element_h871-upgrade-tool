# Part Filter ver-02

**Status:** Implemented; user reported the result was very good. Preserve as a separate version.

- Source: `H871_PART_FILTER_VER_02.lsp`
- Command: `H871_PART_FILTER_VER_02`
- UI: Machining Process + Material convention selectors.
- Mapping: Process CNC/KH/CG/COVER → Density Instance 1/2/3/4; Material A6061/SUS201/SUS304/SS400/POM/Bakelit/MC/MIKA/PU → Density Base 6061/201/304/400/10/20/30/40/50.
- Search engine and Results Browser behavior are retained from ver-01.

Important: the Material selector maps a user convention to Density Base; it does not read the actual Material property. The root-level legacy path `src/part-filter/H871_PART_FILTER_VER_02.lsp` is retained for older LOAD instructions.
