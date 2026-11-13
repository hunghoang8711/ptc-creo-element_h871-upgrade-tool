# Lessons Learned

Reusable engineering knowledge. Add an entry when a root cause is understood or a mistake can be prevented in future work. Do not record speculation as a confirmed root cause.

## Confirmed lessons

No root cause has been confirmed yet. The entries below are investigation rules derived from the initial project requirements.

## Investigation note – LISP unexpected end of input

**Observed symptom**
- Creo reported: `Unexpected end of #<input stream "...H871_PART_FILTER_DIAG.lsp">`.

**Root cause**
- Not yet established. The original file is not present in this repository.

**Investigation approach**
1. Obtain the exact failing file and preserve an untouched copy.
2. Check balanced parentheses and quoted strings, especially near the end of the file.
3. Check incomplete forms, comments, reader syntax, and conditional branches.
4. Reduce the file to the smallest reproducing expression if necessary.
5. Load the corrected file in Creo Elements/Direct Modeling 18.1.

**Prevention**
- Keep source changes small.
- Run a syntax/parenthesis-balance check before loading.
- Do not treat a static balance check as proof that the Creo LISP reader accepts the file.
- Record the exact file revision and test environment when the error is reproduced or resolved.

## Lesson entry template

### [Short title]

**Problem**
- Observable symptom and conditions.

**Root cause**
- Confirmed technical cause, or explicitly state “not yet established”.

**Solution**
- The change that resolved the issue.

**Prevention**
- Rule, test, or design practice that prevents recurrence.

**Evidence**
- File/commit, Creo version, test case, and result.
