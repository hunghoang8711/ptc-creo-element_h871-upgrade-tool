

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
