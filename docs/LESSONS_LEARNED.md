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


## LL-009 – Do not confuse Modeling Lisp with Annotation/ME10 macros
- **Lesson:** User-provided Annotation sources use command-language syntax such as `DEFINE`, `PARAMETER`, `LET`, `INQ`, `END_DEFINE`; this is not Lisp syntax.
- **Prevention:** Identify the language and module before proposing a LOAD command or porting a macro. Port behavior deliberately instead of pasting code across interpreters.

## LL-010 – A frame lifecycle macro is not a frame catalogue registration mechanism
- **Lesson:** The reviewed Annotation source shows how to load/create/replace a frame on a sheet, but does not prove how frame choices are registered in the UI.
- **Prevention:** Trace the actual frame picker/list population mechanism in the installed 18.1 customization files. Do not rely on unverified `docu-register-frame` or unavailable `am_customize`.

## LL-011 – Preserve current edit context and clean temporary structures
- **Lesson:** Legacy sheet/BOM arrangement macros repeatedly save the current part, switch to TOP/root/target sheet, create temporary LTABs or parts, then restore the prior context and delete temporary structures.
- **Prevention:** Treat current-part restoration and temporary-object cleanup as explicit success and error-path acceptance criteria in new tools.

## LL-012 – Units must be derived from the current environment
- **Lesson:** The legacy Arrange_sheets2 macro reads a unit factor from `INQ_ENV 6` / `INQ 2` and converts a 25 mm spacing before arranging sheets.
- **Prevention:** Never hard-code drawing/model distances without verifying active units and conversion direction.


## LL-013 – Keep multi-Browser result contexts independent
- **Lesson:** A single shared `active-parts` / `active-instance` variable is unsafe when several Graphical Browser trees can refresh or reopen independently. A callback may run after another pair has become active and rebuild the wrong Browser's rows.
- **Prevention:** Give every Browser/Tree unique handles and a distinct update callback closure that captures that Browser's own tree name, pair label and immutable result snapshot. Do not depend on whichever pair was most recently filtered.

## LL-014 – Do not add UICT Display Table when a native Graphical Browser already owns selection and Apply
- **Lesson:** VER-03's Display Table required an additional conversion/Apply bridge, while VER-02 already demonstrated native Graphical Browser row selection and Apply. A second UICT table layer adds API compatibility and object-type boundaries without being necessary for native Browser selection.
- **Prevention:** For workflows whose result rows must be selected and applied to the 3D viewport, prefer the native Graphical Browser as the result surface. Use a lightweight manager window only for opening/organizing pair-specific Browsers. Verify native Apply in the actual viewport.

## LL-015 – Treat fatal `0xc00000fd` as unresolved until runtime evidence identifies its source
- **Lesson:** Recursive Assembly traversal is a plausible stack-overflow source, but an iterative traversal experiment did not resolve the reported fatal exception. Therefore recursion alone is not a confirmed root cause.
- **Prevention:** Do not label the crash fixed based on static checks or a rewritten collector. Capture the last trace marker and reproduce only on a disposable model copy. Avoid overwriting original customer model data.