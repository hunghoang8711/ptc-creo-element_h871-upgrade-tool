# VER-03 Stable Restart Baseline

## Decision (2026-11-16)

Restart Part Filter development from the user-verified **VER-03 REBUILD / VER-02 BASELINE**, not from the later UICT ver-03, ver-05, or ver-06 multi-page experiments.

This is the version the user tested in PTC Creo Elements/Direct Modeling 18.1 and confirmed:
- Results window opens and lists matching Parts.
- Select All followed by Apply selects actual Parts in the Modeling viewport.
- Double-clicking a result row selects the corresponding individual Part.
- The Results window is a separate intermediate selection window; keep this proven interaction model.

## Immutable source baseline

- Repository: `hunghoang8711/ptc-creo-element_h871-upgrade-tool`
- Source branch: `rebuild/ver-03-from-ver-02`
- Baseline commit: `b843b921f013941d48169821ca33ed19d34fcfbc`
- File: `src/part-filter/ver-03-rebuild/H871_PART_FILTER_VER_03_REBUILD.lsp`
- File blob at baseline: `3f5e272220fe77e4dd6b868d1974a5dc983332f7`
- Command: `H871_PART_FILTER_VER_03_REBUILD`
- Restart work branch: `rebuild/ver-03-stable-restart`

The restart branch was created from the exact baseline commit above. Do not edit the baseline source in place. Make changes incrementally on the restart branch and retain a clean copy of this known-good file.

## Preserve these proven behaviors

1. Keep the standalone native Graphical Browser Results window.
2. Keep the native Apply/OK action and the exact working Part-selection handoff.
3. Keep direct row selection and double-click selection.
4. Keep Select All and Clear Selection.
5. Keep the existing results table columns: Part Name, Density Instance, Density Base, Assembly Path.
6. Keep the existing recursive Assembly collector and exact Density Instance AND Density Base predicate until a separate diagnostic proves a required correction.
7. Keep numeric convention:
   - Process / Density Instance: CNC=1, KH=2, CG=3, COVER=4.
   - Material / Density Base: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
   - API values are normalized by dividing by 1000.
   - `1-304` means CNC-SUS304.
   - Matching must use both Instance AND Base.

## Lessons and restrictions carried forward

- Do not replace the proven Results window with UICT Dialog Shell / Display Table / Tab Control.
- Do not add Browser Bar docking, hidden Browser bridges, host-shell reparenting, or multiple result Browser windows.
- Do not replace native Apply with a custom callback that loses the actual BrowserNode/Part selection handoff.
- Do not infer successful viewport selection from a trace status, a selected Browser row, or a returned success symbol. Verify actual highlighted Parts in the 3D viewport.
- Do not use the obsolete UICT ver-03 source or the later ver-06 candidate as the new base.
- Do not run risky recursive collector experiments on the customer's original Assembly. Use a disposable Assembly copy.
- Do not change multiple subsystems in one iteration. First establish a known-good baseline, then change one item, run static checks, and test in Modeling 18.1.
- Treat APIs documented for newer Creo versions as unverified until tested in Modeling 18.1.

## Open issues to diagnose on top of this baseline

### A. Process selector and displayed Process Code desynchronization
A recent run showed the selector as CG while the separate Process Code display remained 1. The report for that run recorded Requested Density Instance=3, so the filter input was CG=3 even though the display field was stale. The `:after-input` synchronization for the display-only field is not reliable enough to be treated as authoritative.

Next implementation should remove this duplicated state where possible: use the selected Process value itself as the only filter input and make the displayed code derive from that same value through a verified Modeling 18.1 dialog mechanism. Do not change the Density matching engine to compensate for a UI display issue.

### B. Density Instance returns NIL in one Assembly
A report from Assembly `/B_NAV2610-02/05.cum-ve-sinh_do` showed:
- Requested Density Instance=3; Requested Density Base=304.
- Sampled Parts returned NIL for `(sd-inq-part-density part :instance)`.
- Density Base values were readable, including raw 304000.0.
- Consequently, exact-pair matching rejected these sampled Parts because the Instance value was NIL.

This does not prove that the Assembly contains no CG-SUS304 Parts. It proves that the current Instance inquiry did not return a value for the sampled Parts in that Assembly. Do not weaken the exact AND predicate or silently substitute a different property source. Diagnose a known Part whose Creo Properties explicitly show the expected Instance and Base.

Existing read-only diagnostic files:
- `src/part-filter/H871_DENSITY_DIAG.lsp`
- `src/part-filter/H871_DENSITY_API_TEST.lsp`
- `src/part-filter/H871_DENSITY_KIND_TEST.lsp`

The diagnostic should compare default Density inquiry, `:instance`, `:contents`, and Instance/Contents attributes, recording return values and errors distinctly. Only after identifying a verified source for Density Instance should the collector be changed.

## Test protocol

1. Work only on a disposable copy of the Assembly.
2. Load the unchanged baseline and confirm the Results window, Select All + Apply, and double-click selection still work.
3. Record the selected Process label, numeric value passed to the filter, selected Material label/value, and report header.
4. Test the Density API on one known Part whose Properties visibly show the expected Density Instance and Density Base.
5. Change only the smallest proven defect; retain the baseline Apply and Browser code.
6. Re-test actual Part selection in the 3D viewport.
7. Update this file and the development log with exact tested / not-tested status and commit references.

## Status

- Baseline Results window and native Apply: **USER-VERIFIED in Modeling 18.1**.
- Baseline double-click selection: **USER-VERIFIED in Modeling 18.1**.
- Process Code display synchronization: **OPEN ISSUE**.
- Density Instance inquiry for the reported Assembly: **OPEN ISSUE**.
- Any new changes on this restart branch: **NOT YET RUNTIME-TESTED**.
