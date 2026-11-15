# Lessons Learned

Confirmed engineering knowledge and prevention rules for PTC Creo Elements/Direct Modeling 18.1. Keep speculative ideas out of this file.

## LL-001 – Preserve native Graphical Browser Apply
- **Symptom:** After a custom Apply callback was added, row selection and Apply stopped behaving correctly.
- **Cause:** The callback replaced the native default OK/Apply action and reopened the browser immediately after selection hand-off.
- **Resolution:** Remove the callback and retain native Apply. The user confirmed row selection and Apply worked again.
- **Prevention:** Do not override native selection/Apply without a proven requirement and regression test. Do not immediately reopen after native hand-off.

## LL-002 – Do not reparent the Results Browser into a host shell
- **Symptom:** Matching searches failed with “Could not embed the results browser in its host window” or “Could not create the unified results window.”
- **Cause:** The custom host-shell/browser-parent approach broke the working standalone browser path.
- **Resolution:** Restore standalone Graphical Browser.
- **Prevention:** Do not revive browser reparenting or a unified host shell merely to rearrange controls. Prove a minimal 18.1 example first.

## LL-003 – Supply status text using the keyword argument
- **Symptom:** Creo displayed “Odd number of arguments for keywords.”
- **Cause:** `sd-browser-set-status-text` was called without the required `:value` keyword/value pair.
- **Resolution:** Pass the status string with `:value`; user confirmed the error disappeared.
- **Prevention:** Check exact function signature and keyword pairing.

## LL-004 – Density API values use a different scale
- **Observation:** Tested UI values 1/304 and 2/400 corresponded to API raw values 1000/304000 and 2000/400000.
- **Resolution:** Current Density workflow normalizes by dividing API values by 1000.
- **Prevention:** Do not generalize the conversion to unrelated properties; inspect raw value/type/units first.

## LL-005 – Later-release docs are not proof of 18.1 compatibility
- **Lesson:** PTC documentation for later releases is useful for investigation but does not prove a function exists or behaves identically in Modeling 18.1.
- **Prevention:** Verify function existence, exact signature, object type and runtime behavior in the target installation.

## LL-006 – Avoid assuming Common Lisp condition handlers or helper predicates exist
- **Observed:** `HANDLER-CASE` and `SEL_ITEM-P` were reported as undefined in the user's Modeling 18.1 environment.
- **Prevention:** Do not import generic Common Lisp assumptions or undocumented helper names into the LISP tool. Confirm each symbol in the actual environment before use.

## LL-007 – Keep one Results Browser, not one browser per query
- **Symptom:** The first ver-03 experiment created multiple Graphical Browser instances and docked them as tabs in Creo's Browser Bar.
- **Cause:** The requirement was interpreted as multiple browser sessions rather than one Results Browser with internal pages.
- **Correction:** User clarified the required UI: one separate Results window with its own horizontal tabs, each keyed by the filter pair.
- **Prevention:** Read TD-008 before implementing any multi-search feature. The old multi-browser experiment is superseded.

## LL-008 – Preserve confirmed code as a versioned baseline
- **Lesson:** Risky architectural experiments must not overwrite a user-confirmed source.
- **Prevention:** Work on `main`, keep each LISP version in its own `ver-XX` directory, and preserve earlier versions unchanged.

## Development checklist
- Inspect current source and relevant docs before editing.
- Make one focused change at a time.
- Verify API names/signatures and object types in Modeling 18.1.
- Retest result display, single-row selection, Select All and native Apply after Results UI changes.
- Record exact source revision and user-observed outcome.
- Update shared knowledge docs on `main`.
