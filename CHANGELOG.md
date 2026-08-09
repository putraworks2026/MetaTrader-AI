# Changelog — PutraWorks MetaTrader-AI

All notable changes across the project are documented here.
Per-tool changelogs are in each tool's `docs/CHANGELOG.md`.

## v0.0.4 — 2026-08-09

### Changed
- Replaced generic AIEA copies with tool-specific ML files
- EAs: 11 tool-specific modules (Config with EA params, LearningEngine with EA lessons, PatternRecognition with EA patterns)
- Indicators: 5 signal-focused modules (SignalConfig, SignalJournal, SignalLearning, SignalPatterns, SignalDashboard)
- Scripts: 2 execution-focused modules (ExecConfig, ExecJournal)
- All filenames now include `_v0.0.4` revision
- All `#include` paths updated to reference versioned filenames
- Per-tool ARCHITECTURE.md and USER_GUIDE.md rewritten to be tool-specific
- Publish/README.md updated to reference v0.0.4

### Added
- Root README.md (comprehensive project overview)
- Root CHANGELOG.md
- .gitignore (MT5 build artifacts)
- LICENSE (PutraWorks proprietary)
- Per-tool docs/CHANGELOG.md
- AIEA_Trader/Publish/README.md

### Removed
- Old generic AIEA-style include files (220 files deleted)
- Old unversioned filenames

## v0.0.3 — 2026-07-21

### Added
- Initial ML engine based on AIEA_Trader architecture
- 11 include files per tool (generic copies of AIEA with name swap)
- Tests/ folder with test suite per tool
- docs/ folder with ARCHITECTURE.md and USER_GUIDE.md per tool
- Publish/ folder with README per tool

## v0.0.2 — 2026-07-20

### Changed
- Bug fixes and code improvements across all tools

## v0.0.1 — 2026-07-20

### Added
- Initial release of all 20 tools (5 EAs, 10 Indicators, 5 Scripts)
- Libraries (5 utility modules)
- AIEA_Trader reference architecture
