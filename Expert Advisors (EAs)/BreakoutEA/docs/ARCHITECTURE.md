# BreakoutEA — Architecture

## Overview

Trades range breakouts with volume confirmation. Part of the PutraWorks MetaTrader-AI collection.

## Tool-Specific Parameters

- `rangePeriod` — configured in Config_v0.0.4.mqh
- `volumePeriod` — configured in Config_v0.0.4.mqh
- `volumeMultiplier` — configured in Config_v0.0.4.mqh
- `breakoutThreshold` — configured in Config_v0.0.4.mqh

## ML Pattern Categories

- `RangeBreakout` — tracked and scored by PatternRecognition_v0.0.4.mqh
- `VolumeBreakout` — tracked and scored by PatternRecognition_v0.0.4.mqh
- `FalseBreakout` — tracked and scored by PatternRecognition_v0.0.4.mqh
- `SessionBreakout` — tracked and scored by PatternRecognition_v0.0.4.mqh

## Module Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    BreakoutEA_v0.0.4.mq5                      │
│                   (Main EA Entry Point)                   │
├──────────┬──────────┬──────────┬──────────┬─────────────┤
│ Config   │ Indicator │  Risk    │ Trading  │  Learning   │
│ _v0.0.4  │ Engine    │ Manager  │ Journal  │  Engine     │
│ .mqh     │ _v0.0.4  │ _v0.0.4  │ _v0.0.4  │  _v0.0.4   │
├──────────┼──────────┴──────────┴──────────┼─────────────┤
│ Pattern  │    Strategy Evolution           │ Optimization│
│ Recogn.  │    _v0.0.4.mqh                  │ Engine      │
│ _v0.0.4  │                                 │ _v0.0.4     │
├──────────┴────────────────────────────────┴─────────────┤
│ Report Generator │ Dashboard │ News Manager            │
│ _v0.0.4.mqh     │ _v0.0.4  │ _v0.0.4                 │
└─────────────────┴──────────┴───────────────────────────┘
```

## ML Modules (11 files)

| Module | File | Purpose |
|--------|------|---------|
| Config | Config_v0.0.4.mqh | BreakoutEA-specific parameter profiles with rangePeriod, volumePeriod, volumeMultiplier, breakoutThreshold |
| IndicatorEngine | IndicatorEngine_v0.0.4.mqh | ATR/ADX regime detection |
| RiskManager | RiskManager_v0.0.4.mqh | Position sizing, daily loss limits, drawdown protection |
| TradingJournal | TradingJournal_v0.0.4.mqh | CSV trade journal with MFE/MAE tracking |
| LearningEngine | LearningEngine_v0.0.4.mqh | Post-trade lesson extraction for RangeBreakout, VolumeBreakout, FalseBreakout, SessionBreakout |
| PatternRecognition | PatternRecognition_v0.0.4.mqh | Scores RangeBreakout, VolumeBreakout, FalseBreakout, SessionBreakout patterns by win rate |
| StrategyEvolution | StrategyEvolution_v0.0.4.mqh | Multi-profile management with promotion/retirement |
| OptimizationEngine | OptimizationEngine_v0.0.4.mqh | Adaptive tuning of rangePeriod, volumePeriod, volumeMultiplier, breakoutThreshold |
| ReportGenerator | ReportGenerator_v0.0.4.mqh | Daily performance reports |
| Dashboard | Dashboard_v0.0.4.mqh | On-chart ML display |
| NewsManager | NewsManager_v0.0.4.mqh | MT5 calendar API news filter |

## Include Chain

```
Config (base — no dependencies)
  ├── IndicatorEngine → Config
  ├── RiskManager → Config
  ├── TradingJournal → Config
  ├── LearningEngine → Config + TradingJournal + IndicatorEngine
  ├── PatternRecognition → Config + TradingJournal
  ├── StrategyEvolution → Config + LearningEngine + TradingJournal
  ├── OptimizationEngine → Config + StrategyEvolution + LearningEngine + PatternRecognition + TradingJournal
  ├── ReportGenerator → Config + TradingJournal + LearningEngine + StrategyEvolution + PatternRecognition
  ├── Dashboard → Config + TradingJournal + LearningEngine + StrategyEvolution
  └── NewsManager (standalone)
```

## File Structure

```
BreakoutEA/
├── BreakoutEA_v0.0.4.mq5              # Main file — compile this
├── Include/
│   ├── BreakoutEA_v0.0.4.mqh           # Core EA logic
│   ├── Config_v0.0.4.mqh           # BreakoutEA parameters
│   ├── IndicatorEngine_v0.0.4.mqh  # Indicator management
│   ├── RiskManager_v0.0.4.mqh      # Risk controls
│   ├── TradingJournal_v0.0.4.mqh   # Trade journal
│   ├── LearningEngine_v0.0.4.mqh   # Post-trade learning
│   ├── PatternRecognition_v0.0.4.mqh # Pattern scoring
│   ├── StrategyEvolution_v0.0.4.mqh # Profile management
│   ├── OptimizationEngine_v0.0.4.mqh # Parameter optimization
│   ├── ReportGenerator_v0.0.4.mqh  # Performance reports
│   ├── Dashboard_v0.0.4.mqh        # On-chart display
│   └── NewsManager_v0.0.4.mqh      # News filter
├── Tests/BreakoutEA_TestSuite_v0.0.4.mq5
├── docs/
│   ├── ARCHITECTURE.md            # This file
│   ├── USER_GUIDE.md              # Usage guide
│   └── CHANGELOG.md               # Version history
├── Publish/README.md
└── Archive/                       # Previous versions (read-only)
    ├── BreakoutEA_v0.0.1.mq5
    ├── BreakoutEA_v0.0.2.mq5
    └── BreakoutEA_v0.0.3.mq5
```
