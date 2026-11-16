# 04 – H871 Part Filter and API Findings

## Product/version
Creo Elements/Direct Modeling 18.1. This tool is not for Creo Parametric.

## Density API evidence
- User tested Part `010-plate_2.1.1.2.1` in Modeling 18.1 on 2026-11-14.
- Object representation reported: `ELAN::SEL_ITEM`.
- User confirmed `sd-inq-part-p` and `sd-inq-part-density` are defined.
- One-argument call `(sd-inq-part-density part)` returned `1000.0`, type `LONG-FLOAT`.
- This establishes the one-argument call and its observed return for that test part. Do not assume its semantic mode unless independently verified.
- The user-confirmed production filter uses explicit `:instance` and `:contents` inquiries and successfully matches exact pair values. Keep the tested production call pattern.
- Tested display/raw pairs:
  - UI Instance 1 / Base 304 ↔ API 1000 / 304000.
  - UI Instance 2 / Base 400 ↔ API 2000 / 400000.
- The current production source normalizes the returned Density values by dividing by 1000. This conversion is specific to the tested Density workflow.

## Part Filter versions
- ver-01: numeric Density Instance + Density Base exact-pair filter; standalone Graphical Browser. User confirmed row display, individual row selection, Select All and native Apply.
- ver-02: maps Machining Process and Material convention labels onto Density values. User reported very good results.
- ver-03: specified one Results Browser window with internal horizontal tabs/pages; new implementation pending.

### ver-02 mappings
Machining Process → Density Instance:
- CNC=1, KH=2, CG=3, COVER=4.

Material convention → Density Base:
- A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.

These are convention mappings, not actual Material property retrieval. Default is CNC + SUS304 (1/304).

## Confirmed Results Browser behavior
User-confirmed in Modeling 18.1:
1. Results Graphical Browser opens and lists matching Parts.
2. Select All is available.
3. Clicking an individual row selects that Part.
4. Native Apply transfers selected Parts to Modeling selection.

Important: a custom Apply callback previously replaced native Apply and caused row selection/Apply to stop working. Removing the custom callback restored the native behavior. Do not override native Apply casually.

## ver-03 authoritative design
- One separate Results Browser window.
- Horizontal tabs/pages exist inside this window, like a desktop browser.
- Not separate Graphical Browser windows; not Creo Browser Bar tabs.
- Each unique Density Instance + Base pair maps to one page.
- Caption uses mapped Material + Process labels, e.g. `SUS304-CNC`.
- Repeating a pair refreshes its existing page; different pair adds a page.
- Switching pages preserves page results and selection state where feasible.
- Apply only transfers selected Parts from active page.
- No-match must not silently erase valid previous pages.
- Previous multi-browser prototype is superseded and archived.

## Browser/UI findings
- `sd-browser-set-status-text` requires `:value` keyword/value syntax; omission caused “Odd number of arguments for keywords.”
- Standalone Graphical Browser is the confirmed working architecture.
- Attempts to embed/reparent it into a custom host shell failed with:
  - “Could not embed the results browser in its host window.”
  - “Could not create the unified results window.”
- UICT Dialog Shell / Tab Control / Display Table are investigation candidates only. Research references were later PTC releases. Their 18.1 availability and real-Part Apply hand-off are unverified.
- Do not implement a UICT table as if its selected row automatically equals Modeling selection. Prove the hand-off separately.

## Assembly scan and diagnostic caution
- Current production source uses recursive Assembly traversal and Part checks; preserve its tested traversal behavior.
- An uploaded diagnostic prototype attempted `sd-inq-part-density` with `:contents`, `:instance`, `:realized`, and used `HANDLER-CASE`. User later reported `HANDLER-CASE` undefined in Modeling 18.1; do not reuse the prototype unchanged.
- User also reported `SEL_ITEM-P` undefined in earlier diagnostics.
- Treat the diagnostic source as a failed experiment, not a working tool.


## 2026-11-16 – Single-Browser multi-page Apply diagnostic

- Keep selection and native Apply in the same Graphical Browser instance, as in ver-02.
- A hidden temporary Browser is not an equivalent selection context for UICT Display Table rows.
- A single Browser Tree can hold multiple page roots; the table root determines which direct Part children are displayed.
- Dynamic popup menu entries can provide a page selector, with Previous/Next toolbar buttons for navigation. This is a diagnostic page-navigation UI, not a horizontal tab strip.
- Preserve the Browser's native Apply default. Do not override :okButtonAction without a proven reason and a runtime regression test.
- Do not retry the failed Browser reparenting/host-shell integration without a newly isolated root cause.


## 2026-11-16 – ver-04 persistent UICT reopen launcher

The native Results Browser can now be reopened from the restored ver-03 UICT Results shell without typing the diagnostic command again. ver-04 installs a uniquely named `Open Native Results` pushbutton in the existing ver-03 grid, guarded by `sd-control-p`, with `:pushAction '(h871-pf-v04-run-diagnostic)`. The callback snapshots current ver-03 page data and selection before rebuilding the one native Browser. Previous/Next also emit navigation request/target trace markers. This is a static-checked implementation; verify UICT button coordinates, callback execution, repeated close/reopen, page switching and actual viewport Apply in Modeling 18.1 before treating it as a proven workflow. Source: `src/part-filter/ver-04/diagnostics/H871_PF_V04_SINGLE_BROWSER_PAGES_DIAG.lsp`, commit `21ddfb945a40f2361cb09439522387f90f6fac54`.
