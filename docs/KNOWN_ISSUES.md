

## 2026-11-14 – Current verification boundary after browser refinement

- **Confirmed resolved:** user reports the `Odd number of arguments for keywords.` message no longer appears.
- **Confirmed working:** result table opens and individual Part rows can be selected.
- **Still pending:** user has not yet confirmed that the revised Select All / Clear Selection menu entries are visible or functional.
- **Still pending:** user has not yet confirmed the revised column widths display Part Name, Density Instance, and Density Base together without horizontal scrolling.
- **Implementation detail:** latest source declares Select All / Clear Selection in both `:buttonMenu` and `:topMenu`, with `:buttonMenuOffObjectOnly nil`. If neither surface appears in Creo 18.1, do not repeat the same menu approach; inspect the supported browser API for a permanently visible toolbar/control.
- **Column sizing lesson:** `:initial-width` uses character counts. Current values are 28 / 13 / 12 / 42 for Part Name / Density Instance / Density Base / Assembly Path; adjust only after a screenshot or measured runtime observation.
- **Verification rule:** GitHub source presence and static checks are not proof of Creo runtime behavior. Preserve the user's confirmed status separately from pending UI behavior.
