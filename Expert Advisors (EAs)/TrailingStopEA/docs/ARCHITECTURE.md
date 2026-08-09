# TrailingStopEA — Architecture

## Overview

ATR/fixed/step trailing stop with breakeven. Part of the PutraWorks MetaTrader-AI collection.

## Tool-Specific Parameters

- `trailMethod` — configured in Config_v0.0.4.mqh
- `trailPoints` — configured in Config_v0.0.4.mqh
- `breakevenTrigger` — configured in Config_v0.0.4.mqh
- `atrPeriod` — configured in Config_v0.0.4.mqh

## ML Pattern Categories

- `TrendContinuation` — tracked and scored by PatternRecognition_v0.0.4.mqh
- `ReversalSignal` — tracked and scored by PatternRecognition_v0.0.4.mqh
- `BreakevenHold` — tracked and scored by PatternRecognition_v0.0.4.mqh
- `ProfitLock` — tracked and scored by PatternRecognition_v0.0.4.mqh

## Module Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    TrailingStopEA_v0.0.4.mq5                      │
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
| Config | Config_v0.0.4.mqh | TrailingStopEA-specific parameter profiles with trailMethod, trailPoints, breakevenTrigger, atrPeriod |
| IndicatorEngine | IndicatorEngine_v0.0.4.mqh | ATR/ADX regime detection |
| RiskManager | RiskManager_v0.0.4.mqh | Position sizing, daily loss limits, drawdown protection |
| TradingJournal | TradingJournal_v0.0.4.mqh | CSV trade journal with MFE/MAE tracking |
| LearningEngine | LearningEngine_v0.0.4.mqh | Post-trade lesson extraction for TrendContinuation, ReversalSignal, BreakevenHold, ProfitLock |
| PatternRecognition | PatternRecognition_v0.0.4.mqh | Scores TrendContinuation, ReversalSignal, BreakevenHold, ProfitLock patterns by win rate |
| StrategyEvolution | StrategyEvolution_v0.0.4.mqh | Multi-profile management with promotion/retirement |
| OptimizationEngine | OptimizationEngine_v0.0.4.mqh | Adaptive tuning of trailMethod, trailPoints, breakevenTrigger, atrPeriod |
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
TrailingStopEA/
├── TrailingStopEA_v0.0.4.mq5              # Main file — compile this
├── Include/
│   ├── TrailingStopEA_v0.0.4.mqh           # Core EA logic
│   ├── Config_v0.0.4.mqh           # TrailingStopEA parameters
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
├── Tests/TrailingStopEA_TestSuite_v0.0.4.mq5
├── docs/
│   ├── ARCHITECTURE.md            # This file
│   ├── USER_GUIDE.md              # Usage guide
│   └── CHANGELOG.md               # Version history
├── Publish/README.md
└── Archive/                       # Previous versions (read-only)
    ├── TrailingStopEA_v0.0.1.mq5
    ├── TrailingStopEA_v0.0.2.mq5
    └── TrailingStopEA_v0.0.3.mq5
```
