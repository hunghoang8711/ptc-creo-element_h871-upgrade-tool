# Part Filter – LISP Source

## Upload location

Upload the LISP files for the Part property filter currently under development into this folder:

`src/part-filter/`

Keep the original filenames. Please include, where available:
- The latest working or in-progress Part filter LISP file.
- Related diagnostic/debug LISP files.
- Earlier versions if they contain behavior or code that may be useful for comparison.

## Before uploading

- Do not rename files just to make them look cleaner; preserving their names helps trace history.
- If several files depend on each other, upload all of them.
- Do not include customer-confidential CAD models, credentials, or private data.
- If possible, include a short note identifying which file is the latest version and which one was last tested in Creo Elements/Direct Modeling 18.1.

## Review workflow

After the files are uploaded, the development workflow is:
1. Inspect every file and map dependencies and command entry points.
2. Identify the latest baseline without overwriting historical versions.
3. Review syntax and the Part property retrieval logic.
4. Compare the implementation with the exact Instance + Base matching requirement.
5. Record findings and proposed changes before modifying the source.
6. Distinguish static checks from tests actually performed in Creo 18.1.

This folder currently contains no production LISP source.