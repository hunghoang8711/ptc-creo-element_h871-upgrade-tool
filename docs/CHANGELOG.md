# Changelog

Concise record of meaningful project milestones. See Git history for individual commits and intermediate experiments.

## 2026-11-14 – Stabilize H871 Part Filter baseline

- Confirmed the dedicated Graphical Browser displays matching Part rows in Creo Elements/Direct Modeling 18.1.
- Confirmed Select All is available in the Results window.
- Confirmed individual row selection and native Apply transfer selected Parts to Modeling selection.
- Restored and retained the standalone Graphical Browser architecture.
- Removed the custom Apply callback that interfered with native selection hand-off.
- Corrected status-text keyword arguments using `:value`.
- Consolidated technical decisions, known issues, lessons, and development history to remove contradictory intermediate UI states.

## 2026-11-13 – Establish Part Filter foundation

- Added the initial Part property/Density investigation and diagnostic source.
- Implemented an exact Density Instance + Density Base search path.
- Added a BOM-like Graphical Browser result table with Part name, Density values, and Assembly path.
