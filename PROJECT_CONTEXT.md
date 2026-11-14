# H871 Part Filter – Project Context

**Last consolidated:** 2026-11-14  
**Target application:** PTC Creo Elements/Direct Modeling 18.1  
**Current phase:** Existing Part Filter baseline stabilized; awaiting the user's next feature idea.

## 1. Product goal

Develop an advanced Part-filtering tool for Creo Elements/Direct Modeling. The long-term direction is to search Parts by model properties and return real selectable model objects, not merely generate a text report.

Keep the property-reading/filter engine separate from the Results Browser so additional properties and conditions can be introduced without replacing the working selection interface.

## 2. Current user-confirmed baseline

The user has confirmed the following in Modeling 18.1:

- The Filter Results Graphical Browser opens and displays matching Part rows.
- Select All is available in the Results window.
- Clicking an individual Part row selects that result.
- Apply transfers the selected Part(s) to Creo Modeling selection.

**Regression boundary:** preserve the standalone Graphical Browser architecture, native row-selection behavior, Select All action, and native default Apply hand-off. Do not replace the native Apply action with a custom callback that immediately reopens the browser. Do not reintroduce the failed unified host-shell/browser-reparenting architecture.

Clear Selection, repeat-search behavior, and other convenience features must not be described as verified unless the user separately confirms them.

## 3. Current filter behavior

The current production candidate searches by an exact pair:

- Density Instance, read with `sd-inq-part-density :instance`.
- Density Base, read with `sd-inq-part-density :contents`.

Both values must match (AND). There are no comparison operators or OR logic in this current exact-pair dialog.

The API returns values on a different scale from the Part Properties display. The current source normalizes the API values by dividing by 1000. User-provided examples:

| Part Properties display | API raw values |
|---|---|
| Instance 1, Base 304 | Instance 1000, Base 304000 |
| Instance 2, Base 400 | Instance 2000, Base 400000 |

These examples are confirmed for the tested Parts; do not assume every property or model uses the same conversion without diagnosis.

## 4. Source of truth

- Main implementation: `src/part-filter/H871_PART_FILTER.lsp`
- Preserved diagnostic baseline: `src/part-filter/H871_PART_FILTER_DIAG.lsp`
- Current main source blob at consolidation: `e94a89547460e038b2669995f2136fc1dd835816`

Inspect the current file before editing. Documentation records intent and evidence; source plus user runtime confirmation determine actual behavior.

## 5. Not implemented / not yet verified

- Material property retrieval/filtering has not been verified for Modeling 18.1.
- Other physical, geometric, structural, and custom Part properties are future scope, not existing features.
- A generalized dynamic condition builder (add/remove rows, operators, AND/OR groups) has not been implemented.
- Clear Selection visibility/functionality and repeat-search lifecycle are not part of the confirmed baseline unless re-tested.
- Later-release PTC browser/UICT references are investigation material only; validate exact APIs in 18.1.

## 6. Required development approach

1. Ask the user for the intended next feature before expanding scope.
2. Inspect the exact current source and identify the smallest extension point.
3. Preserve the confirmed Results Browser and selection hand-off.
4. Verify every new property API with a small diagnostic on a known Part before integrating it into the filter engine.
5. Test in Modeling 18.1 and record the exact result.
6. Update this file and the relevant decision, issue, lesson, log, and changelog entries.
