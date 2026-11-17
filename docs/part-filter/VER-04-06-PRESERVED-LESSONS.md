# H871 Part Filter — Preserved lessons from VER-04 to VER-06

This note consolidates the non-working experiments and the design constraints that must not be lost when replacing their source files. These are project-history observations, not claims that every failed source had the same root cause.

## Accepted functional baseline

- VER-02 is the source baseline for the next implementation.
- The user has previously confirmed that its native Graphical Browser row selection and native Apply select the corresponding original Parts in the 3D viewport.
- Preserve the exact Density Instance + Density Base comparison and the numeric convention: `1-304` means CNC-SUS304. Do not replace it with text matching or single-property matching.
- Preserve the tested Browser table callbacks and native Apply behavior unless a focused test proves a change is required.

## Failed architecture / implementation lessons

1. **One Results window is a hard requirement.** Multiple independent Graphical Browsers, a Manager window with Open buttons, or a hidden/secondary Browser used as an Apply bridge do not satisfy it.
2. **Do not assume UICT Display Table selection can become native Modeling selection.** A Display Table row and a Graphical BrowserNode are different API objects. The earlier Apply bridge encountered a type mismatch (`#:NODE241 is not of type "BROWSERNODE"`) when an unresolved node handle was passed where a BrowserNode structure was required.
3. **Resolve BrowserNode handles before passing them to APIs requiring a BrowserNode structure.** The later documented pattern is to resolve a symbolic ID through `sd-get-browsernode-struct`; this still needs release-specific runtime validation.
4. **Do not create a Browser per filter pair.** VER-05 demonstrated that individual Browser selection and native Apply could work, but its multi-window Manager architecture violated the one-window requirement and introduced lifecycle/reopen risks.
5. **Browser lifecycle is a separate acceptance test.** Earlier reports included fatal exception `0xc00000fd` and a “Model data may have been damaged” warning after close/reopen or Manager Open workflows. The exact root cause was not isolated. Stop immediately on such a warning and test only on a disposable Assembly copy.
6. **Do not assume `:createAsTab` guarantees placement.** PTC documentation says a stored PDS preference from a previous session can override this option. Verify actual docked/floating state in Modeling 18.1.
7. **Do not claim drag-resize without a runtime test.** Later PTC releases document resizable dialog shells and Browser parenting APIs; those are not evidence that the same mechanism exists in 18.1.
8. **Do not call a read-only table column a notes editor.** The note field must support user editing and reliable persistence. Establish the exact 18.1 API before adding it to the Results UI.
9. **Do not change the collector while solving the UI.** Keep the known-good recursive Density filter unchanged until the one-window UI has passed runtime tests. The earlier stack-overflow hypothesis was not proven; an iterative traversal attempt did not establish a fix.
10. **Do not trust static checks as runtime proof.** Parenthesis balance, symbol checks and API references cannot validate Browser creation, callbacks, selection handoff, PDS placement or model lifecycle.

## Current implementation direction

Start from VER-02 and create one native Graphical Browser shell. Validate floating placement and native Apply first. Only then add the notes experience, after verifying which in-Browser editing/detail APIs are actually available in Modeling 18.1. Keep all failed VER-04/05/06 learnings here even if their implementation files are overwritten.
