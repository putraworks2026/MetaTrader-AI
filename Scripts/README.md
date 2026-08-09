# Scripts

One-shot utility scripts that perform a specific action when dragged onto a chart.

## Tools

| Tool | Description | ML Modules | Version |
|------|-------------|------------|---------|
| CloseAllTrades | Close all open positions | 2 (execution) | v0.0.4 |
| DeleteAllPending | Delete all pending orders | 2 (execution) | v0.0.4 |
| ExportTradeHistory | Export trades to CSV | 2 (execution) | v0.0.4 |
| RiskCalculator | Calculate lot size from risk % | 2 (execution) | v0.0.4 |
| SetBreakevenAll | Move all positions to breakeven | 2 (execution) | v0.0.4 |

## ML Architecture

Each script has 2 execution-focused ML modules:
- ExecConfig (execution result tracking, stats)
- ExecJournal (logs each execution with duration and result)

See `RANKING.md` for market demand ranking.
