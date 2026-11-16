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



## LL-013 – Keep result rows and native Apply in the same Graphical Browser

- Lesson: ver-02 works because the visible Results rows, BrowserNode selection state and native Apply button all belong to the same Graphical Browser instance. Copying selected Part objects from a UICT Display Table into a second hidden Browser does not recreate that native selection context.
- New experiment: One Graphical Browser can represent multiple result pages by keeping a page root for each Density pair and changing the table root. The native Apply button remains attached to the same Browser.
- Navigation: A dynamic Browser popup submenu can expose page names, with Previous/Next controls for quick switching. This is a page-navigation prototype, not a horizontal tab implementation.
- Prevention: Preserve the ver-02 native Apply default. Never replace :okButtonAction casually. Do not infer viewport selection from a hidden Browser, a SUCCESS trace, or a Dialog Generator highlight.


## LL-014 – Destroy named Browser objects before rerunning a diagnostic

A Graphical Browser window being hidden/closed does not prove that its named Browser Tree has been released. A second call to sd-create-browser-tree with the same name can fail with an “already exists” error even though the first diagnostic's window is no longer visible.

For diagnostic tools that create named Browser/Tree objects:
1. Capture any source UI state/data that must survive.
2. Hide and destroy the Graphical Browser first.
3. Destroy its Browser Tree second.
4. Only then create a new Tree/Browser with the same names.
5. Keep a dedicated recovery action that restores the original UI shell.

Treat sd-destroy-graphical-browser and sd-destroy-browser-tree behavior as requiring target-version runtime confirmation; a static call or a cleanup attempt is not proof that the objects were released.


## LL-015 – Provide a persistent return path when swapping Results windows

When a diagnostic temporarily replaces a working UICT Results window with a native Graphical Browser, a Close action that restores UICT is only half of the navigation. The user also needs a persistent entry point in the restored UICT shell to reopen the native Browser without typing the diagnostic command again.

For this pattern, install one uniquely named pushbutton in the existing UICT grid, guard creation with `sd-control-p`, and route its push action to the Browser rebuild entry point. Rebuild from the latest UICT page registry so new searches are reflected. Verify placement and callback in the target Modeling release; do not infer runtime success from static code checks.

## LL-016 – Keep native selection and multi-page data in the same Browser (2026-11-16)

The user's final requirement is not a sequence of windows or a two-stage hand-off. The one Results Graphical Browser must own the visible Part rows, selected BrowserNodes, active Density-pair page and native Apply action. ver-03 UICT page data cannot be treated as equivalent to native Browser selection; the hidden Browser bridge did not reproduce ver-02 behavior. ver-04's switch-to-native / return-to-UICT flow is diagnostic only.

ver-05 therefore moves search and page ownership into one standalone Browser implementation, reusing ver-02's search/mapping and native Apply pattern. The current page navigation is a same-window popup plus Previous/Next; horizontal tabs still require a separately verified 18.1-compatible UI mechanism. Never add an extra Results-window transition merely to imitate tabs.

### LL-016 follow-up – horizontal page selector inside the native Browser

PTC's Graphical Browser API documents a `:modeMenu` row of mode buttons and an initial active button. This is a promising way to render page selectors inside the same native Browser, unlike Browser Bar docking tabs. The detailed reference currently available is for a later release; therefore it is an implementation candidate, not verified Modeling 18.1 behavior. Keep the actual Part BrowserNodes and native Apply in the same Browser regardless of which page-selector UI proves compatible.



## LL-016 – Always clear Graphical Browser table roots before activating another page (2026-11-16)

A Graphical Browser can retain multiple table roots. Calling :change-table-root for the next page without first calling :clear-table-roots does not guarantee replacement of the old root. The visible table may then contain rows from more than one page, making page-local Select All and native Apply unreliable.

Use the PTC documented buffered sequence:
1. :buffer-display t
2. :clear-select-list
3. :clear-table-roots
4. :change-table-root page-node t
5. :buffer-display nil

Then query :number-of-table-roots and require exactly 1. This is now implemented in ver-05; Modeling 18.1 runtime verification remains required.


LL-016 follow-up: treat clear-roots and set-root return values as mandatory gates. Do not mark a page active unless both succeed. Optional diagnostic queries must not be allowed to break the core page transition; guard them and retain the primary command results in the trace.


## LL-017 – Distinguish Graphical Browser modeMenu from buttonMenu

PTC Graphical Browser :modeMenu is mapped to right-click popup entries for compatibility; it is not the visible horizontal row. :buttonMenu creates the visible horizontal button row. Never infer UI placement from the names. Verify the exact PTC parameter description and example before implementing a visible tab/page strip. For Density pages, create dynamic page buttons in :buttonMenu and validate the rendered UI in the target Modeling version.


### Correction to LL-017 – modeMenu is a visible horizontal row

PTC's reference says modeMenu provides a row of toggle buttons directly above buttonMenu; both are additionally mapped to right-click popup entries for compatibility. Do not state that modeMenu is popup-only. It is a valid page-selector row in principle. When it fails to appear, inspect the actual evaluated menu specification, initial button name, Browser creation result and runtime trace instead of switching parameters based on an incomplete reading.
