# Lessons Learned

Confirmed engineering knowledge and prevention rules for Creo Elements/Direct Modeling 18.1. Keep speculative ideas out of this file.

## LL-001 – Preserve the native Graphical Browser Apply action

**Symptom:** After a custom Apply callback was added, clicking result rows no longer behaved correctly and Apply did not hand off the selection as expected.

**Cause:** The custom callback replaced the Graphical Browser's native default OK/Apply action and immediately reopened the browser after `:select-and-execute`.

**Resolution:** Remove the custom callback and retain the native default Apply action. The user then confirmed that row selection and Apply worked again in Modeling 18.1.

**Prevention:** Do not override native browser selection/Apply behavior unless there is a proven requirement and a regression test. Do not immediately reopen the browser after the native selection hand-off.

## LL-002 – Do not reparent the working Results Browser into a new host shell

**Symptom:** Searches with matches failed to show results after the Results Browser was embedded in a custom unified host window.

**Cause:** The host-shell/browser-parent approach introduced a failure path; an incomplete grid parent hierarchy was also found during investigation. Even after diagnosing the hierarchy, the unified architecture was rolled back in favor of the known-good standalone browser.

**Resolution:** Restore the standalone Graphical Browser creation path.

**Prevention:** Keep the current standalone browser. Do not reintroduce `sd-set-graphical-browser-parent` or a new host shell just to rearrange footer controls without first proving a minimal 18.1 test.

## LL-003 – Supply keyword arguments in the documented form

**Symptom:** Creo displayed `Odd number of arguments for keywords.`

**Cause:** Calls to `sd-browser-set-status-text` supplied the status message without the required `:value` keyword/value pair.

**Resolution:** Pass the status text using `:value` in both calls. The user confirmed the message disappeared.

**Prevention:** Verify the exact function signature and pass every required keyword explicitly.

## LL-004 – Density API values use a different scale from the UI examples

**Observation:** For the two user-tested Parts, `sd-inq-part-density` returned Instance/Base values 1000/304000 and 2000/400000 while Part Properties displayed 1/304 and 2/400.

**Resolution in current source:** Normalize returned numeric values by dividing by 1000 before matching/displaying.

**Prevention:** Diagnose raw values and units on known Parts before applying conversion to other properties or models. Do not generalize this scale factor to unrelated APIs.

## LL-005 – Separate verified behavior from API assumptions

**Lesson:** Documentation for a later PTC release can guide investigation but does not prove compatibility with Modeling 18.1.

**Prevention:** Validate function existence, signatures, object types, and actual UI behavior in the target installation. Record static checks and runtime evidence separately.

## Development checklist

- Preserve a known-good source revision before a risky change.
- Make one focused change at a time.
- Test the exact failing and success paths in Modeling 18.1.
- Retest result display, single-row selection, Select All, and native Apply after any Results Browser change.
- Record the user's observed result and source revision.
