# Technical Decisions

Record decisions that constrain future implementation. Amend entries only when a decision is deliberately revisited; preserve the rationale and date.

## TD-001 – Target CAD platform

- **Date:** 2026-11-13
- **Decision:** Target PTC Creo Elements/Direct Modeling 18.1.
- **Rationale:** This is the user's stated production environment.
- **Implication:** Do not assume Creo Parametric APIs or newer Elements/Direct APIs are compatible. Verify functions and object/property access in version 18.1.

## TD-002 – Part property filter uses exact Instance/Base matching

- **Date:** 2026-11-13
- **Decision:** The Material filter is based on an exact pair of property values: Instance and Base.
- **Example:** Instance = `1`, Base = `304`.
- **Rationale:** The user explicitly clarified that the Material page needs filtering by Instance and Base values, not comparison operators.
- **Implication:** A match requires both fields to match the entered values. Do not add greater-than/less-than comparisons or treat the two fields as OR alternatives.
- **Open detail:** Confirm the exact property retrieval mechanism and the meaning of the previously selected implementation approach B from the original source/discussion before implementing.

## TD-003 – Test claims must distinguish static checks from in-application tests

- **Date:** 2026-11-13
- **Decision:** Code review, syntax checks, successful file loading, functional tests, and regression tests are separate verification levels.
- **Rationale:** A LISP file can pass a basic static check but still fail in the Creo reader or behave incorrectly against real model objects.
- **Implication:** Development logs must state precisely which verification levels were completed.

## TD-004 – Documentation is part of each feature change

- **Date:** 2026-11-13
- **Decision:** Meaningful source changes must be accompanied by updates to the development log and, where relevant, technical decisions, lessons learned, known issues, and changelog.
- **Rationale:** New development sessions must be able to resume from repository evidence rather than relying on chat history.


## TD-005 – Density filter is an exact Instance/Base pair

- **Date:** 2026-11-13
- **Decision:** The Material tab's Density filter uses exactly two numeric values: Density Instance and Density Base.
- **Retrieval:** `sd-inq-part-density` with `:instance` retrieves the Instance value; `:contents` retrieves the Base value.
- **Match rule:** A Part matches only if both returned values are non-NIL and numerically equal to the two requested values.
- **UI:** No comparison operators, enable toggles, or AND/OR selector for this pair.
- **Rationale:** Matches the supplied Part Properties screenshot (Instance 1, Base 304) and PTC Integration Kit inquiry semantics.
- **Verification caveat:** The function documentation is available in current PTC Integration Kit references and the function was already present in the imported source, but the new implementation still requires load and functional verification in the user's Creo 18.1 installation.


## TD-006 – Return matches through Creo native selection

- **Date:** 2026-11-13
- **Decision:** Matching Parts should be selected using Creo's native `GET_SELECTION` interrupt action, not merely written to a text report or highlighted as a dialog variable.
- **Implementation:** Use `*sd-part-seltype*`, `:check_function` for exact Density pair validation, and `:select :in_assembly` for the selected Assembly.
- **Rationale:** PTC Integration Kit documentation describes GET_SELECTION as invoking the standard SELECT subaction and returning selected SEL_ITEMs. Its check function can return `:ok` to retain or `:filter` to exclude each selected item.
- **Expected workflow:** Matching Parts should be available in the native selection list for commands such as Add to Drawlist.
- **Verification caveat:** Documentation reviewed is for Elements/Direct 20.x; GET_SELECTION is an established Integration Kit interrupt action, but the exact behavior must be confirmed on the user's Creo 18.1 build.


## TD-007 – Select matching nodes in the native Structure Browser

- **Date:** 2026-11-13
- **Decision:** To meet the user's workflow, select matching objects in the existing Structure Browser's own selection state rather than treating a GET_SELECTION return value as persistent UI selection.
- **Browser:** Standard Structure Browser name is `parcel-gbrowser`.
- **API:** `sd-browser-exec-cmd` with `:set-object-selection` accepts a BrowserNode struct and a Boolean; `:clear-select-list` clears prior browser selections; `:expand-tree` can expose descendants.
- **Node lookup:** Traverse browser nodes using `sd-query-browser :get-children`, compare `BrowserNode-objPath` with `sd-inq-obj-pathname` of the matching model object.
- **Rationale:** PTC Graphical Browsers reference documents these commands and the Structure Browser-specific name. This corresponds to the user's desired browser row selection behavior.
- **Verification caveat:** Reference is for a later release; compatibility and behavior must be tested on Creo 18.1. Browser nodes must be visible/selectable.


## TD-008 – Replace direct-selection approach with a dedicated H871 results browser

- **Date:** 2026-11-13
- **Decision:** The Part Filter will present search results in a dedicated BOM-like Creo Graphical Browser, rather than attempting to force selection into the existing Structure Browser immediately after a scan.
- **Rationale:** The user needs a persistent, inspectable list where individual results and all results can be selected, double-click can locate a model object, and subsequent operations can be applied to the selected result set. PTC's Graphical Browser framework supports data trees, BrowserNode client data, tables with custom columns, mouse click handlers, selection queries, and browser commands.
- **Interaction:** Single click selects a row; Ctrl-click adds/removes; double-click locates/operates on the corresponding object; explicit Select All/Clear Selection actions; Clear Results separate from selection clearing.
- **Extensibility:** Separate property predicate from result browser so Density is the first filter and additional Part properties can be added later.
- **Compatibility:** PTC documents reviewed are for 20.4/20.8; must verify the relevant APIs in the user's Creo 18.1 Integration Kit before implementing. Do not reuse unverified function signatures from newer releases.
- **Supersedes:** TD-006 and TD-007 as the primary user interaction strategy. Their selection experiments are historical and not accepted as successful implementations.
