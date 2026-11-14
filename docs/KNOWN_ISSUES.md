

## 2026-11-14 – Current verification boundary after browser refinement

- **Confirmed resolved:** user reports the `Odd number of arguments for keywords.` message no longer appears.
- **Confirmed working:** result table opens and individual Part rows can be selected.
- **Still pending:** user has not yet confirmed that the revised Select All / Clear Selection menu entries are visible or functional.
- **Still pending:** user has not yet confirmed the revised column widths display Part Name, Density Instance, and Density Base together without horizontal scrolling.
- **Implementation detail:** latest source declares Select All / Clear Selection in both `:buttonMenu` and `:topMenu`, with `:buttonMenuOffObjectOnly nil`. If neither surface appears in Creo 18.1, do not repeat the same menu approach; inspect the supported browser API for a permanently visible toolbar/control.
- **Column sizing lesson:** `:initial-width` uses character counts. Current values are 28 / 13 / 12 / 42 for Part Name / Density Instance / Density Base / Assembly Path; adjust only after a screenshot or measured runtime observation.
- **Verification rule:** GitHub source presence and static checks are not proof of Creo runtime behavior. Preserve the user's confirmed status separately from pending UI behavior.


## 2026-11-14 – Select All control still not visible; persistent mode-menu attempt

- **User-confirmed:** result columns are compact; manual multi-row highlighting and Apply work.
- **Unresolved:** no visible Select All control in the result browser.
- **Likely UI-surface issue:** previous implementation put actions in `:buttonMenu` / `:topMenu`, which did not expose a clear always-visible action in the user's Creo 18.1 UI.
- **Latest source attempt:** add `:modeMenu` with persistent Select All and Clear Selection actions, and use native `:browser-push-cmd` for popup fallback actions.
- **Pending:** verify button visibility and actual selection behavior in Creo 18.1. If `:modeMenu` is also unavailable in 18.1, use a separate supported UI control (e.g. a dedicated dialog/button surface) rather than more menu declaration variations.


## 2026-11-14 – Latest screenshot: Select All absent and columns still too wide

- **User-confirmed:** the latest screenshot still has no visible Select All control; the Density column starts near the far right edge and is partly clipped.
- **Correction to earlier sizing note:** the statement that the current Graphical Browser column widths were character counts was not adequately supported and is withdrawn. PTC's 20.4 release notes identify `:max-width` as the legacy option and say it was changed to `:initial-width` in 20.4. Modeling 18.1 source should therefore use `:max-width` unless the 18.1 local reference proves otherwise.
- **Latest source:** uses `:max-width` values 22 / 8 / 8 / 30 and adds a separate UICT dialog with Select All / Clear Selection pushbuttons.
- **Still unverified:** UICT control creation and column sizing must be tested in Creo 18.1. If the UICT window fails to appear, capture the exact LISP error before changing APIs again.


## 2026-11-14 – Unified results-window implementation pending runtime test

- **User requirement:** one window with bottom buttons in this order: Apply, Select All, Clear Selection, Close. Select All must select all rows and immediately execute the Apply hand-off.
- **Latest source:** removed the separate Selection Tools shell; embeds the Graphical Browser in a resizable host shell using `sd-set-graphical-browser-parent`; adds the four UICT pushbuttons in the host footer.
- **Select All action:** `:select-all` followed by `:select-and-execute`; this should hand all matched Parts to Modeling without a second Apply click.
- **Compatibility risk:** the available PTC reference for browser-parent hosting is from a later Integration Kit release than Modeling 18.1. The source checks function availability and reports an error rather than silently opening a second window if the API is unavailable.
- **Pending runtime checks:** all controls in one window; native table renders inside host; Apply / Select All / Clear Selection / Close; existing row multi-selection and Apply remain intact.


## 2026-11-14 – Graphical Browser embedding returns NIL

- **User-confirmed runtime error:** `H871: Could not embed the results browser in its host window.`
- The failure occurs at `sd-set-graphical-browser-parent`.
- Correction: do not assume this API is unavailable in 18.1. PTC's release-history page places the resizable UICT and browser-parent functions in older CoCreate Modeling history, before the 18.1 lineage.
- Latest source adds a diagnostic message reporting browser existence/docked state, dialog-shell existence, and both grid-area handles before cleanup.
- **Pending:** collect the diagnostic values from the user's Creo 18.1 run. Do not alter the parent API call speculatively until the actual UI object hierarchy is known.


## 2026-11-14 – Root cause found for browser embedding failure

- **Confirmed source defect:** the root resizable grid area `H871-PF-RESULTS-RG` was used as a parent before it had been created.
- PTC UICT naming convention: a dialog shell with basename `H871-PF-RESULTS` creates client area `H871-PF-RESULTS-AA`.
- Latest source now creates the root grid under that automatic client area, then creates the browser grid under the root grid.
- Browser parenting still requires runtime verification after this hierarchy correction.


## 2026-11-14 – Unified results-window creation failure now reports exact stage

- **User-confirmed:** searches with no matching Parts still show the expected no-match message.
- **User-confirmed:** searches with matching Parts fail with `H871: Could not create the unified results window.`
- This narrows the failure to the result UI creation branch after matches are found; it does not establish which UICT operation fails.
- Latest source now reports a numbered stage: API availability, dialog shell, root grid, browser child grid, or one of the four footer buttons.
- **Next required evidence:** exact stage text from the next Creo 18.1 run. Do not change the Density filter or browser-parent call until this is known.
- Static parenthesis balance is 0; runtime remains unverified.

 
## 2026-11-14 – Roll back unified results-window regression

### User report
After merging Apply / Select All / Clear Selection / Close into one window, searches that find Parts no longer open the results UI. The no-match path still works.

### History comparison
- Last known-good standalone browser source: commit `3e9f3c1`, blob `2d65e613708e8ef8721c5cd58c50d950b89488b3`.
- The standalone implementation creates the Graphical Browser, defines the BOM table, calls `sd-browser-set-active-table`, switches to table mode, then calls `sd-show-graphical-browser`.
- The unified-window implementation introduced a host dialog/grid hierarchy and the additional `sd-set-graphical-browser-parent` call. This path was not present in the known-good source and is the regression boundary.
- The Density collector and result-tree construction are retained from the known-good source.

### Rollback
Restored the complete LISP source to the exact known-good standalone-browser implementation from `3e9f3c1`. This intentionally prioritizes restoring the working results browser and manual row selection / Apply flow over the unverified single-window footer.

### Runtime verification
- Static source restored from the historical Git blob.
- User must reload this version and confirm the results browser opens again for a matching Assembly.
- Select All / Clear Selection visibility remains a separate unresolved enhancement; do not reintroduce browser-parent hosting until a Modeling 18.1-compatible method is proven.

 
## 2026-11-14 – Select All button reintroduced without changing Results Browser architecture

- **User-confirmed baseline:** the standalone Results Browser works normally again after rollback.
- **Current implementation:** a compact separate UICT window contains one Select All button; Clear Selection has been omitted.
- The button calls the existing Graphical Browser `:select-all` command. The Results Browser remains standalone; browser-parent embedding is not used.
- **Static checks passed:** balanced parentheses, closed strings, no browser-parent API, and one Select All pushbutton.
- **Pending runtime test:** verify the tool window appears, Select All highlights every row, and Apply transfers the complete selection. Do not treat static validation as Creo runtime verification.

 
## 2026-11-14 – Select All moved into Filter Results window

- Separate Selection Tools window has been removed in response to the user's correction.
- Current source uses the Graphical Browser's native `:abortButtonLabel "Select All"` and `:abortButtonAction` to expose the action in the same Results window, while preserving the native OK/Apply action.
- This avoids browser-parent embedding and keeps the standalone browser architecture.
- **Pending Creo 18.1 runtime verification:** confirm button placement, selection behavior, browser remains open after Select All, Apply, and normal close behavior. PTC reference consulted is for a later release, so do not assume compatibility before testing.


## 2026-11-14 – Part Filter unified footer runtime verification pending
- Latest source creates independent UICT Apply and Select All buttons in one host dialog footer; it no longer uses the Graphical Browser Abort slot.
- Browser embedding still depends on `sd-set-graphical-browser-parent` succeeding in Creo Elements/Direct Modeling 18.1.
- Browser is shown before parent assignment. If embedding fails, a numbered diagnostic is displayed and the standalone browser is restored.
- Do not mark the unified window as working until the user confirms one-window display, adjacent buttons, Select All behavior, Apply hand-off, and normal close behavior.


## 2026-11-14 – Part Filter native footer runtime check pending

- The oversized host-shell implementation has been removed from the current source.
- Current source is based on the standalone Results Browser that previously displayed the result rows correctly.
- Apply and Select All now use the Graphical Browser's native footer slots; Apply explicitly re-shows the browser after selection hand-off.
- Pending Creo 18.1 checks: footer button order/placement, Select All without closing, Apply hand-off followed by browser restoration, and normal close.
- The previous host-shell / browser-reparenting limitation is no longer part of the current implementation.


## 2026-11-14 – Part Filter row selection / Apply regression

**User-reported:** the Part list and Select All button are visible, but clicking a Part row does not select it and Apply has no effect.

**Mitigation committed:** removed the custom Apply callback and restored the Graphical Browser's native default OK action. This addresses the known unnecessary re-open behavior in the custom callback.

**Still unresolved pending Creo 18.1 retest:** individual row selection. If single-click still fails, inspect browser node selectability and click handling independently. Do not claim the full selection workflow is fixed based on static source validation.
