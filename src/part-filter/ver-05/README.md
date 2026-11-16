# H871 Part Filter VER-05 – VER-03 UI, Stack-Safe Traversal

Target: PTC Creo Elements/Direct Modeling 18.1

## Purpose

VER-05 rebuilds the user-facing Results UI from VER-03 and replaces recursive Assembly traversal with bounded iterative traversal. It is isolated from all earlier versions.

## Safety

- Do not test on the only/original customer model.
- Open a disposable copy of the Assembly in a fresh Modeling session.
- If Creo reports a fatal exception or possible model damage, save to a new filename only if the session is still responsive, do not overwrite the original, then exit Modeling.
- Runtime compatibility is not established by static source checks.

## Load

Copy H871_PART_FILTER_VER_05_STACK_SAFE.lsp to a local test folder and load it using the actual path, for example:

```lisp
(load "D:/H871-TEST/H871_PART_FILTER_VER_05_STACK_SAFE.lsp")
```

Then run:

```text
H871_PART_FILTER_VER_05
```

## Expected UI and workflow

1. Select an Assembly.
2. Select Machining Process and Material using the numeric mapping.
3. Press OK/Filter.
4. One standalone Results window opens. Each Density Instance + Density Base pair owns an internal tab.
5. Each tab contains Part Name, Density Instance, Density Base, and Assembly Path, plus Select All, Clear Selection, and Apply.
6. Apply opens the visible Native Apply Bridge. Press the bridge's native Apply button to transfer the highlighted Parts into the 3D viewport.

The native bridge is intentionally retained because this native Apply interaction was user-confirmed in Modeling 18.1. Automatic one-click Apply is not claimed.

## Filter mapping

- Density Instance: CNC=1, KH=2, CG=3, COVER=4.
- Density Base: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
- Matching always checks both fields. Example: 1-304 means CNC-SUS304.
- API Density values are normalized by dividing by 1000.

## Stack-safety changes

- Traversal uses an explicit pending list instead of recursive calls.
- An EQ hash table tracks visited Modeling object handles.
- A 250,000-object ceiling stops a runaway scan before it can exhaust the Lisp call stack.
- If the scan is incomplete, VER-05 does not refresh or replace any Results page.
- Trace file: H871_PART_FILTER_VER_05_TRACE.txt in the user's home directory.
- Result report: H871_PART_FILTER_VER_05_RESULT.txt in the user's home directory.

## Runtime acceptance checklist

- [ ] Load in a fresh Modeling 18.1 session.
- [ ] Filter CNC-SUS304 (1-304) and verify all matching Parts.
- [ ] Filter KH-A6061 (2-6061) and verify a second tab appears in the same Results window.
- [ ] Re-filter CNC-SUS304 and verify only that tab is refreshed.
- [ ] Select one row and multiple rows.
- [ ] Select All and Clear Selection affect only the active tab.
- [ ] Press Results Apply, then native Apply in the bridge; verify actual 3D viewport selection.
- [ ] Try a no-match pair; existing Results tabs remain unchanged.
- [ ] Repeat on a second disposable Assembly.
- [ ] Confirm no fatal exception, freeze, or stack overflow.

## Current validation status

Static source checks passed. No Modeling 18.1 runtime test has yet been performed for VER-05. The 0xc00000fd cause is still a hypothesis until runtime evidence is collected.
