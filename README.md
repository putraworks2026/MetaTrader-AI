# MetaTrader-AI — PutraWorks

A collection of **26 MQL5 tools** for MetaTrader 5: Expert Advisors, Custom Indicators, Scripts, and Libraries — all with self-improving ML architecture.

## Project Structure

```
MetaTrader-AI/
├── Expert Advisors (EAs)/          # 6 trading robots
│   ├── AIEA_Trader/                 # Reference architecture (unchanged)
│   ├── BreakoutEA/                  # Range breakout with volume confirmation
│   ├── GridTradingEA/              # Grid trading with configurable levels
│   ├── NewsTradingEA/              # Straddle orders around news events
│   ├── ScalpingEA/                 # Fast scalping with spread filter
│   └── TrailingStopEA/             # ATR/fixed/step trailing stop
├── Custom Indicators/              # 10 visual chart tools
│   ├── AutoSupportResistance/      # Auto S/R from swing points
│   ├── FairValueGap/                # 3-candle imbalance detection
│   ├── FibonacciAutoDraw/          # Auto fib levels with confluence
│   ├── LiquidityZones/             # Equal highs/lows liquidity pools
│   ├── OrderBlocks/                # ICT order block detection
│   ├── SessionsKillzones/          # Session boxes with killzones
│   ├── SmartMoneyConcepts/         # BOS, CHoCH, OB, FVG combined
│   ├── SupplyDemandZones/          # Institutional S/D zones
│   ├── TrendStrengthMeter/         # Multi-TF ADX trend dashboard
│   └── VolumeProfile/             # Volume at price with POC
├── Scripts/                        # 5 utility scripts
│   ├── CloseAllTrades/             # Close all positions
│   ├── DeleteAllPending/          # Delete pending orders
│   ├── ExportTradeHistory/        # Export trades to CSV
│   ├── RiskCalculator/            # Lot size calculator
│   └── SetBreakevenAll/           # Move all to breakeven
└── Libraries/                      # 5 reusable libraries
    ├── MathStats/                  # Statistical functions
    ├── Notifications/              # Alert system
    ├── OrderManager/              # Order execution
    ├── RiskManager/               # Risk management
    └── TimeSession/               # Session detection
```

## Per-Tool Structure

Each tool follows a standardized directory layout:

```
ToolName/
├── ToolName_v0.0.4.mq5            # Compile-ready main file
├── Include/                        # ML engine + function modules
│   ├── ToolName_v0.0.4.mqh         # Core tool logic
│   └── [ML modules]_v0.0.4.mqh    # Tool-specific ML files
├── Tests/                          # Unit test suite
│   └── ToolName_TestSuite_v0.0.4.mq5
├── docs/                           # Documentation
│   ├── ARCHITECTURE.md            # Tool-specific architecture
│   ├── USER_GUIDE.md              # How to use
│   └── CHANGELOG.md               # Version history
├── Publish/                        # MQL5 Market submission assets
│   └── README.md
└── Archive/                        # Previous versions (read-only)
    ├── ToolName_v0.0.1.mq5
    ├── ToolName_v0.0.2.mq5
    └── ToolName_v0.0.3.mq5
```

## ML Architecture by Tool Type

### EAs (11 ML modules each)
Trading-focused self-improvement:
- **Config** — Tool-specific parameter profiles (e.g., BreakoutEA has `rangePeriod`, `volumeMultiplier`)
- **IndicatorEngine** — ATR/ADX regime detection
- **RiskManager** — Position sizing, daily loss limits, drawdown protection
- **TradingJournal** — CSV trade journal with MFE/MAE tracking
- **LearningEngine** — Post-trade lesson extraction (tool-specific patterns and lessons)
- **PatternRecognition** — Pattern scoring (e.g., BreakoutEA: RangeBreakout, FalseBreakout)
- **StrategyEvolution** — Multi-profile management with promotion/retirement
- **OptimizationEngine** — Adaptive parameter tuning with approval workflow
- **ReportGenerator** — Daily performance reports
- **Dashboard** — On-chart ML display
- **NewsManager** — MT5 calendar API news filter

### Indicators (5 ML modules each)
Signal-focused accuracy tracking:
- **SignalConfig** — Signal quality enums and SignalProfile struct
- **SignalJournal** — Tracks signal accuracy (price after 1/5/10 bars, max favorable/adverse)
- **SignalLearning** — Learns which signal conditions are reliable per indicator type
- **SignalPatterns** — Scores which conditions produce good signals
- **SignalDashboard** — On-chart signal accuracy display

### Scripts (2 ML modules each)
Execution-focused logging:
- **ExecConfig** — Execution result enums and ExecStats struct
- **ExecJournal** — Logs each execution with duration and result

## Version History

| Version | Description |
|---------|-------------|
| v0.0.1 | Initial release |
| v0.0.2 | Bug fixes and improvements |
| v0.0.3 | Added ML engine (AIEA architecture) |
| v0.0.4 | Tool-specific ML (replaced generic copies with per-tool logic) |

## Compilation

1. Copy the tool folder to your MT5 `MQL5/` directory
2. Open MetaEditor
3. Compile the `*_v0.0.4.mq5` file at the tool root
4. All `#include` paths use relative `Include\` paths — no additional setup needed

## License

Copyright 2026 PutraWorks. All rights reserved.
