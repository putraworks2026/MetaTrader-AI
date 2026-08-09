# Expert Advisors (EAs)

Trading robots that automatically analyze price charts, open, modify, and close trades 24/5 based on coded rules and risk parameters.

## Tools

| Tool | Description | ML Modules | Version |
|------|-------------|------------|---------|
| AIEA_Trader | Reference self-improving EA architecture | 11 (original) | 1.000 |
| BreakoutEA | Range breakout with volume confirmation | 11 (tool-specific) | v0.0.4 |
| GridTradingEA | Grid trading with configurable levels | 11 (tool-specific) | v0.0.4 |
| NewsTradingEA | Straddle orders around news events | 11 (tool-specific) | v0.0.4 |
| ScalpingEA | Fast scalping with spread filter | 11 (tool-specific) | v0.0.4 |
| TrailingStopEA | ATR/fixed/step trailing stop | 11 (tool-specific) | v0.0.4 |

## ML Architecture

Each EA has 11 tool-specific ML modules:
- Config with EA-specific parameters
- LearningEngine with EA-specific lessons and patterns
- PatternRecognition with EA-specific pattern categories
- Full trading stack: RiskManager, TradingJournal, StrategyEvolution, OptimizationEngine

See `RANKING.md` for market demand ranking.
