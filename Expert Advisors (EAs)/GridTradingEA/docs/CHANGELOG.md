# GridTradingEA — Changelog

## v0.0.4 — 2026-08-09

### Changed
- Replaced generic AIEA copies with tool-specific ML modules
- Config now has GridTradingEA-specific parameters: gridSpacing, maxGridLevels, gridDirection, gridLotMultiplier
- LearningEngine now has GridTradingEA-specific lessons for RangeBound, TrendingUp, TrendingDown, GridRecovery
- PatternRecognition now tracks GridTradingEA-specific patterns: RangeBound, TrendingUp, TrendingDown, GridRecovery
- All filenames include `_v0.0.4` revision
- All `#include` paths updated to versioned filenames
- ARCHITECTURE.md and USER_GUIDE.md rewritten to be tool-specific

### Removed
- Generic AIEA-style include files (name-swapped copies)

## v0.0.3 — 2026-07-21

### Added
- Initial ML engine (generic AIEA architecture copy)
- 11 include files, Tests/ folder, docs/ folder, Publish/ folder

## v0.0.2 — 2026-07-20

### Changed
- Bug fixes and code improvements

## v0.0.1 — 2026-07-20

### Added
- Initial release
