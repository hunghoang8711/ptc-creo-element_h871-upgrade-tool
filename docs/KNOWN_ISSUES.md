

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
