# CloseAllTrades — User Guide

## Description

Closes all open positions with slippage control.

## Installation

1. Copy the entire `CloseAllTrades/` folder to your MT5 `MQL5/Scripts/` directory
2. Open MetaEditor (F4 in MT5 terminal)
3. Navigate to the `CloseAllTrades/` folder
4. Compile `CloseAllTrades_v0.0.4.mq5` (F7)
5. Drag the script from MT5 Navigator onto any chart

## Usage

1. Drag CloseAllTrades onto a chart
2. The script executes immediately: **Close Positions**
3. Results are logged to the Experts tab
4. ML execution data is saved automatically

## ML Execution Tracking

Each execution is logged with:
- Timestamp and duration (milliseconds)
- Result (success, partial, failed, cancelled)
- Items processed (number of trades/orders affected)
- Day of week and hour (for timing analysis)

The ExecStats struct tracks:
- Total runs
- Success rate
- Average execution time
- Last run timestamp

## File Storage

ML data is stored in `MQL5/Files/CloseAllTrades/`:
- `exec_log.csv` — Execution journal

## Testing

Run the test suite:
1. Compile `Tests/CloseAllTrades_TestSuite_v0.0.4.mq5` in MetaEditor
2. Attach to any chart
3. Check the Experts tab for test results

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Script doesn't run | Check AutoTrading is enabled |
| Partial execution | Check for open positions/orders that can't be modified |
| No ML data | Run the script — data accumulates with each execution |
