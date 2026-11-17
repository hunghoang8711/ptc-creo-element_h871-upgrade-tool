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

## LL-016 – Preserve the native multi-Browser selection and Apply path once confirmed
- **Observation:** In VER-05, separate Graphical Browser windows for different filter pairs work independently. Individual Part selection, double-click selection and Select All followed by native Apply all work in the 3D viewport, matching VER-02 behavior.
- **Next issue:** The separate H871 Graphic/Manager window appears in a screen corner but is too small to display all its information legibly.
- **Prevention:** Treat Browser selection and native Apply as a confirmed baseline. When improving Manager layout, change only the Manager window sizing/layout and test that all Browser windows and Apply behavior remain unchanged. Do not reintroduce UICT Display Table or a custom Apply bridge.
- **Evidence limit:** The supplied trace reached COLLECT/COMPLETE | (0 530) after progress markers through 500. Do not infer the tuple's field meanings. One successful run does not prove every earlier fatal-exception scenario is resolved.


## LL-017 – Keep UICT pixel dimensions separate from grid-unit coordinates
- **Symptom:** A UICT Manager window appeared too small and clipped most of its child controls.
- **Cause:** The parent grid area's `:width` and `:height` are pixel dimensions, while child control `:x`, `:y`, `:width` and `:height` are grid units. With `:cellSize 10,10`, a 112 × 82 pixel area provides only about 11 × 8 grid units.
- **Correction:** Size the parent grid in pixels to match the child layout's grid-unit extent. VER-05 was changed from 112 × 82 pixels to 1120 × 820 pixels for a layout extending to about 112 × 75 grid units.
- **Prevention:** Before changing UICT layouts, calculate the parent pixel dimensions from the required grid-unit extent and cell size. Preserve child coordinates and test the result in the target Modeling release; later-release documentation alone is not runtime proof.


## LL-018 – Treat Browser reopen crashes as a separate lifecycle defect

- **Observation:** VER-05's independent result Browser display, row selection and native Apply were user-confirmed, but a later Open action intended to show another Browser was reported to trigger fatal exception `0xc00000fd`.
- **Evidence limit:** The exact UI control/action path and root cause are not yet isolated. The Manager Open handler currently calls `sd-show-graphical-browser` on the stored Browser name; this is a candidate for investigation, not a confirmed cause.
- **Prevention:** Do not mark Browser reopen/lifecycle as verified merely because initial Browser creation and Apply work. Test reopen separately on a disposable Assembly copy, capture the last trace marker, and never overwrite the original customer model after a fatal exception.


## LL-019 – Distinguish a proven component from the accepted overall UI architecture

- **Observation:** VER-05 successfully demonstrated independent Graphical Browsers and native Apply, but each process/material pair opens a separate top-level Part List window.
- **Requirement:** The accepted final design is one Results window with internal tabs, one tab per unique process/material pair. Re-filtering the same pair refreshes that tab; another pair adds a tab.
- **Failure mode:** Treating a successful multi-Browser Apply test as completion of VER-05 overlooked the explicit single-window requirement.
- **Prevention:** Verify both functional behavior and the agreed top-level UI architecture before declaring a version complete. A technically working alternative architecture is still a regression when it violates an explicit user constraint.


## LL-020 – Treat model-data warnings after UI lifecycle changes as a stop condition

- Observation: After using the VER-05 Manager Open action, the user reported that the Filter page closes while result Browsers remain independent. Closing the command and starting it again then produces a “Model data may have been damaged” warning before a Graphical Browser appears.
- Evidence limit: The exact trigger and responsible API/lifecycle operation are unknown. The current source's sd-show-graphical-browser Open callback and sd-return-from-ok-action Search-dialog exit are investigation points, not confirmed causes.
- Prevention: Stop repeated testing on the original model as soon as this warning appears. Reproduce only on a disposable copy, capture the trace and exact action sequence, and inspect Browser/Tree creation, destruction, callback lifetime and dialog close ordering before modifying code. Never claim the model itself was damaged by a specific call without evidence.

## LL-021 – Resizability is an explicit Results-window acceptance criterion

- Requirement: The Graphical Browser/Results window must allow the user to drag-resize both width and height; the result table and controls must remain usable after resizing.
- Evidence limit: Setting :minHeight, :maxWidth and :maxHeight in sd-create-graphical-browser does not by itself prove that interactive resizing is enabled. No verified Modeling 18.1 resize flag/signature has yet been recorded.
- Prevention: Verify the exact 18.1 API/options before adding a guessed keyword. Test horizontal and vertical resizing and content adaptation in the target runtime.


## LL-022 – Do not promise embedded Browser tabs on Modeling 18.1 without API evidence

- PTC release notes list resizable dialog shells, resizable grid areas, control resize bindings, and Graphical Browser parenting as new in Modeling 20.6.
- These APIs form the documented mechanism to embed the native Graphical Browser in a custom tabbed Results shell. Do not call them in an 18.1 LISP build.
- UICT Display Tables support row selection, but the documented contract does not provide a direct native viewport selection transfer. A separate Graphical Browser bridge was used by VER-03 and is explicitly disallowed by the user.
- For strict one-window 18.1 compatibility, evaluate a single native Graphical Browser with process/material pair nodes as table roots and its own native Apply. Be transparent that this is navigation rather than literal tabs. Verify Browser resizing in 18.1 before claiming it.
- Never substitute this UI trade-off silently. Preserve the multi-Browser and VER-02 baselines.
