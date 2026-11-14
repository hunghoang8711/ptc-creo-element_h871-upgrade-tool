# H871 Part Filter – Project Context

**Last updated:** 2026-11-14  
**Target application:** PTC Creo Elements/Direct Modeling 18.1  
**Current phase:** Part Filter ver-02 mapped-choice dialog candidate; awaiting user runtime test.

## 1. Product goal

Develop an advanced Part-filtering tool for Creo Elements/Direct Modeling. The long-term direction is to search Parts by model properties and return real selectable model objects, not merely generate a text report.

Keep property-reading/filter logic separate from the Results Browser so additional properties and conditions can be introduced without replacing the working selection interface.

## 2. Confirmed ver-01 baseline

The user has confirmed the following in Modeling 18.1:

- The Filter Results Graphical Browser opens and displays matching Part rows.
- Select All is available in the Results window.
- Clicking an individual Part row selects that result.
- Native Apply transfers the selected Part(s) to Creo Modeling selection.

**Regression boundary:** preserve the standalone Graphical Browser architecture, native row-selection behavior, Select All action, and native default Apply hand-off. Do not replace native Apply with a custom callback that immediately reopens the browser. Do not reintroduce the failed unified host-shell/browser-reparenting architecture.

Confirmed ver-01 source: `src/part-filter/H871_PART_FILTER.lsp` (unchanged).

## 3. ver-02 intended dialog and mapping

ver-02 replaces the numeric Density Instance/Base input fields with fixed user-facing choices. It does not add Material-property retrieval. It maps the selected convention codes onto the same Density properties used by ver-01.

### Machining Process → Density Instance

| Display label | Numeric code |
|---|---:|
| CNC | 1 |
| KH | 2 |
| CG | 3 |
| COVER | 4 |

### Material → Density Base

| Display label | Numeric code |
|---|---:|
| A6061 | 6061 |
| SUS201 | 201 |
| SUS304 | 304 |
| SS400 | 400 |
| POM | 10 |
| Bakelit | 20 |
| MC | 30 |
| MIKA | 40 |
| PU | 50 |

- The corresponding code fields use Dialog Generator `:display-only`; users cannot edit them. In the standard parallel-dialog layout they appear as separate rows after their selectors, not on the same row to the right. A custom same-row layout is deferred until a compatible Modeling 18.1 method is verified.
- The selected range values are numeric and are passed directly to `h871-pf-run`.
- Default selection is CNC + SUS304, preserving the previous 1/304 default.
- To revise conventions, edit the `:range` mappings in the ver-02 source.
- The existing Density normalization (/1000), exact-pair matching, report, Results Browser, and native Apply code are retained.

**ver-02 source:** `src/part-filter/H871_PART_FILTER_VER_02.lsp`  
**Command:** `H871_PART_FILTER_VER_02`  
**Status:** source implemented and statically inspected; not yet loaded or tested in Modeling 18.1.

## 4. Results Browser baseline and deferred multi-tab idea

The current ver-02 candidate still uses the existing single Results Browser behavior. A later feature should create independent search sessions and present them as browser-like tabs (e.g. SUS304-CNC). Each session must own its results data, Browser name, and Browser Tree. This idea is recorded for later; do not mix it into the ver-02 dialog change.

## 5. Source of truth

- Confirmed ver-01: `src/part-filter/H871_PART_FILTER.lsp`
- ver-02 candidate: `src/part-filter/H871_PART_FILTER_VER_02.lsp`
- Diagnostic baseline: `src/part-filter/H871_PART_FILTER_DIAG.lsp`

Inspect the exact source before editing. Documentation records intent and evidence; source plus user runtime confirmation determine actual behavior.

## 6. Verification gaps

- ver-02 `:range` labels, numeric values, `:after-input` synchronization and `:display-only` fields must be tested in Modeling 18.1.
- Search tests must verify that CNC/SUS304 finds the same Parts as the previous numeric 1/304 search, and each other mapping passes the expected numeric pair.
- The mapping is a user convention, not proof that the model's actual Material property has been read.
- Material-property retrieval remains unverified.
- Multi-session/multi-tab Results Browser behavior is deferred and not implemented.

## 7. Required development approach

1. Load ver-02 in Modeling 18.1 and verify the dialog opens.
2. Change each selection and verify its corresponding code field updates and cannot be edited.
3. Run CNC + SUS304 and compare results with ver-01 numeric 1/304.
4. Test at least one other process and material combination.
5. Regression-test result rows, Select All, individual selection, and native Apply.
6. Record exact user-observed results and update documentation.
