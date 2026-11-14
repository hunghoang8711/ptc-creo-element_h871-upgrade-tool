

## 2026-11-14 – Consolidated Part Filter progress and engineering lessons

### User-confirmed runtime status
- Part Filter Results browser opens and displays Part names.
- Individual Part rows can be selected.
- The `Odd number of arguments for keywords.` message is resolved after both `sd-browser-set-status-text` calls were changed to use `:value`.

### Latest source state (pending user verification)
- Select All / Clear Selection are declared in both `:buttonMenu` and `:topMenu`; callbacks call `h871-pf-select-all` and `h871-pf-clear-selection`.
- `:buttonMenuOffObjectOnly nil` is set to broaden button-menu availability.
- Browser max width = 900; column widths = 28 / 13 / 12 / 42 characters for Part Name / Density Instance / Density Base / Assembly Path.
- The filter dialog calls `sd-return-from-ok-action` after each search to preserve Assembly and Density inputs for repeat searches. Each run recreates a separate results browser/tree intended to be closed independently.

### Engineering lessons to retain
- Keyword-based APIs must receive explicit keyword/value pairs; positional arguments can produce the odd-keyword-count error.
- Do not assume a declared Graphical Browser menu item is visible in Creo 18.1. User runtime confirmation is required; if still hidden, change to a different always-visible UI mechanism rather than iterating blindly on the same menu mapping.
- Graphical Browser `:initial-width` is character-based, not pixel-based. Use compact character counts and verify visually.
- Keep filter input state and result presentation separate to support multiple searches and independently closable result windows.
- Track static validation, API compatibility assumptions, and actual Creo 18.1 runtime results as distinct evidence categories.

### Next test required
Confirm Select All and Clear Selection visibility/functionality, compact column layout, repeat search without reopening the filter dialog, and independent closing of the result browser. Until then, only error resolution and individual row selection are runtime-confirmed.
