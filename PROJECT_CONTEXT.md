# H871 Part Filter – Project Context

**Last updated:** 2026-11-14  
**Target application:** PTC Creo Elements/Direct Modeling 18.1  
**Current phase:** ver-03 independent multi-search Results Browser candidate; awaiting Modeling 18.1 runtime test.

## 1. Product goal

Develop an advanced Part-filtering tool that searches Parts by model properties and returns real selectable model objects. Keep property-reading/filter logic independent from Results Browser presentation.

## 2. Confirmed baseline

User-confirmed in Modeling 18.1:
- Results Browser displays matching Part rows.
- Individual rows can be selected.
- Select All works.
- Native Apply transfers selected Parts to Modeling selection.
- ver-02 mapped-choice dialog produced a very good result in the user's test.

Preserve the standalone Graphical Browser and native Apply behavior. Do not reintroduce the failed unified host-shell/browser-reparenting approach or override native Apply with a callback.

## 3. Filter conventions

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

The selected numeric codes are passed to the existing exact Density Instance + Density Base matcher. This is a user-defined mapping, not actual Material-property retrieval. Default is CNC + SUS304 (1/304).

## 4. ver-03 independent search sessions

Source: `src/part-filter/H871_PART_FILTER_VER_03.lsp`  
Command: `H871_PART_FILTER_VER_03`

Intended behavior:
- Every successful search creates a new session; previous sessions are not destroyed or overwritten.
- Each session has a unique Browser name and Browser Tree name.
- Each session stores its own matched Part list, Assembly, filter values and diagnostic samples.
- The tab label is derived from Material + Machining Process, e.g. `SUS304-CNC`. Repeated identical searches receive a unique suffix.
- Select All, Clear Selection and selection summary actions target the Browser that owns the action.
- Native Apply is intentionally left as the Graphical Browser default action; each Browser should hand off only its own selected rows.
- Closing/hiding a Browser should not destroy other sessions.

Implementation notes:
- Tree update callback routing currently uses `:update-args` to pass the Browser name.
- Docked-tab creation uses `:createAsTab t` and `:tabname`.
- These signatures are documented in later PTC Integration Kit references, not yet confirmed in Modeling 18.1. Treat ver-03 as a compatibility candidate.

## 5. Source roles

- `src/part-filter/H871_PART_FILTER.lsp` – confirmed ver-01 numeric baseline.
- `src/part-filter/H871_PART_FILTER_VER_02.lsp` – user-confirmed mapped-choice dialog.
- `src/part-filter/H871_PART_FILTER_VER_03.lsp` – multi-session/tab candidate.
- `src/part-filter/H871_PART_FILTER_DIAG.lsp` – diagnostic baseline.

## 6. ver-03 test plan

1. Load ver-03 and run `H871_PART_FILTER_VER_03`.
2. Search SUS304-CNC; confirm one tab appears with the expected Parts.
3. Change choices and search a different combination; confirm a second tab appears and the first result list remains unchanged.
4. Switch between tabs; verify each tab shows only its own Part list.
5. In the first tab, select one row and Apply; verify only that Part is transferred.
6. In the second tab, use Select All and Apply; verify only that session's Parts are transferred.
7. Repeat the same search; verify a unique tab label is generated and neither earlier session is overwritten.
8. Hide/close one tab and verify the others remain available.
9. Search with no matches; verify no empty Results Browser tab is created.
10. Retest the ver-02 mapping dialog defaults and selection updates.

## 7. Verification terminology

Static delimiter checks are not a Lisp compile or Creo runtime test. API references from later releases do not prove Modeling 18.1 compatibility. Record source/static checks separately from load, functional and regression tests.
