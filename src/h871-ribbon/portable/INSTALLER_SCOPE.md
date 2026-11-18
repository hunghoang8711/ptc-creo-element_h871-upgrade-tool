# Portable Installer – Scope and Verification

## Release 0.1
- Target: Creo Elements/Direct Modeling 18.1 on Windows.
- Source: canonical Part Note / All Pages Lisp source.
- Install mode: copy-based, user-selected destinations.
- Safety: preflight existing targets; stop by default; -Force creates timestamped backups before replacement.
- Icon: generated into the selected personal customization directory.
- Command: provide the current Available Command definition as a reference file; do not mutate Modeling command registries.
- Ribbon: user completes placement through the Modeling UI.
- Startup: manual LOAD remains required for each new Modeling session.

## Deliberately excluded
- No direct write to sd_avail_cmds.cmd or user_avail_cmds.cmd.
- No speculative Ribbon XML/Lisp import/export.
- No automatic startup file modification.
- No changes to the Part Filter core.
- No assumption that a later Modeling release's customization path or import/export feature is identical in 18.1.

## Acceptance tests
### Static checks
- [ ] PowerShell parser accepts installer.
- [ ] Required source files are validated before writes.
- [ ] Existing destinations stop installation unless -Force.
- [ ] -Force backs up every existing target before replacing it.
- [ ] Icon generator receives the selected customization directory.
- [ ] Installer prints exact output paths and next steps.

### Modeling 18.1 runtime tests (must be performed by user)
- [ ] Installer completes on a second workstation.
- [ ] Lisp loads without error.
- [ ] Icon appears correctly.
- [ ] User-defined command can be registered with the supplied action.
- [ ] Ribbon button launches Part Filter.
- [ ] Search, selection, Apply, Edit Note and cross-page actions are regression-tested.

Until these tests pass, describe the installer as a portable installation helper, not a fully automated one-click Ribbon deployment.
