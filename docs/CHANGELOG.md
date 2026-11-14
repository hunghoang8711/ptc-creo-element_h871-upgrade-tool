# Changelog

Concise record of meaningful project milestones. See Git history for individual commits and intermediate experiments.

## 2026-11-14 – Add H871 Part Filter ver-02 dialog candidate

- Added fixed Machining Process choices mapped to Density Instance: CNC=1, KH=2, CG=3, COVER=4.
- Added fixed Material choices mapped to Density Base: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
- Added adjacent read-only numeric code fields.
- Preserved Assembly selection, exact Density pair engine, report, Results Browser and native Apply path.
- Kept ver-01 source unchanged.
- Runtime verification in Modeling 18.1 is still pending.

## 2026-11-14 – Record multi-search tab direction

- Captured the future requirement for independent search sessions and browser-like result tabs; implementation deferred until ver-02 validation.

## 2026-11-14 – Stabilize H871 Part Filter ver-01 baseline

- Confirmed Results Browser result rows, Select All, individual row selection and native Apply in Creo Elements/Direct Modeling 18.1.
- Preserved standalone Graphical Browser and native selection hand-off.
