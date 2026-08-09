# GridTradingEA — User Guide

## Description

Grid trading with configurable spacing and levels.

## Installation

1. Copy the entire `GridTradingEA/` folder to your MT5 `MQL5/Experts/` directory
2. Open MetaEditor (F4 in MT5 terminal)
3. Navigate to the `GridTradingEA/` folder
4. Compile `GridTradingEA_v0.0.4.mq5` (F7)
5. The compiled `.ex5` file appears in your MT5 Navigator

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| gridSpacing | See Config | gridSpacing |
| maxGridLevels | See Config | maxGridLevels |
| gridDirection | See Config | gridDirection |
| gridLotMultiplier | See Config | gridLotMultiplier |
| riskPercent | 1.0 | Risk per trade (% of balance) |
| maxDailyLossPercent | 5.0 | Max daily loss before trading stops |
| maxDrawdownPercent | 20.0 | Max drawdown before trading stops |
| maxPositions | 3 | Max simultaneous open positions |
| maxSpreadPoints | 30 | Max spread to allow entry |

## ML Features

### Self-Improvement
GridTradingEA learns from every trade:
- **Pattern Recognition**: Tracks RangeBound, TrendingUp, TrendingDown, GridRecovery and scores them by win rate
- **Learning Engine**: Extracts lessons from wins and losses (e.g., "RangeBound succeeds in trending markets")
- **Strategy Evolution**: Manages multiple parameter profiles, promotes the best, retires the worst
- **Optimization Engine**: Proposes parameter changes based on evidence (requires minimum 10 trades)

### Dashboard
The on-chart dashboard shows:
- Active profile name and score
- Total lessons learned
- Patterns tracked
- Pending optimization changes
- Daily P&L

### News Filter
Uses MT5 built-in calendar API (zero credits):
- Blocks trading 30 minutes before/after high-impact news
- Displays next high-impact event on dashboard

## File Storage

ML data is stored in `MQL5/Files/GridTradingEA/`:
- `journal.csv` — Trade journal
- `lessons.csv` — Learned lessons
- `report.txt` — Daily reports

## Testing

Run the test suite:
1. Compile `Tests/GridTradingEA_TestSuite_v0.0.4.mq5` in MetaEditor
2. Attach to any chart
3. Check the Experts tab for test results

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Compile errors | Ensure all Include/ files are present |
| No ML data | Run the EA — data accumulates over time |
| Dashboard not showing | Check chart has enough bars loaded |
