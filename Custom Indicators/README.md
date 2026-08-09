# Custom Indicators

Visual tools that calculate and draw mathematical formulas, trendlines, or patterns onto price charts.

## Tools

| Tool | Description | ML Modules | Version |
|------|-------------|------------|---------|
| AutoSupportResistance | Auto S/R from swing points | 5 (signal-focused) | v0.0.4 |
| FairValueGap | 3-candle imbalance detection (ICT) | 5 (signal-focused) | v0.0.4 |
| FibonacciAutoDraw | Auto fib levels with confluence | 5 (signal-focused) | v0.0.4 |
| LiquidityZones | Equal highs/lows liquidity pools | 5 (signal-focused) | v0.0.4 |
| OrderBlocks | ICT order block detection | 5 (signal-focused) | v0.0.4 |
| SessionsKillzones | Session boxes with killzones | 5 (signal-focused) | v0.0.4 |
| SmartMoneyConcepts | BOS, CHoCH, OB, FVG combined | 5 (signal-focused) | v0.0.4 |
| SupplyDemandZones | Institutional S/D zones | 5 (signal-focused) | v0.0.4 |
| TrendStrengthMeter | Multi-TF ADX trend dashboard | 5 (signal-focused) | v0.0.4 |
| VolumeProfile | Volume at price with POC | 5 (signal-focused) | v0.0.4 |

## ML Architecture

Each indicator has 5 signal-focused ML modules (no trading modules):
- SignalConfig, SignalJournal, SignalLearning, SignalPatterns, SignalDashboard
- Tracks signal accuracy, learns which conditions produce reliable signals

See `RANKING.md` for market demand ranking.
