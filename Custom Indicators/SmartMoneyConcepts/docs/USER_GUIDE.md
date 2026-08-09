# SmartMoneyConcepts — User Guide

## Description

BOS, CHoCH, Order Blocks, FVG combined (SMC).

## Installation

1. Copy the entire `SmartMoneyConcepts/` folder to your MT5 `MQL5/Indicators/` directory
2. Open MetaEditor (F4 in MT5 terminal)
3. Navigate to the `SmartMoneyConcepts/` folder
4. Compile `SmartMoneyConcepts_v0.0.4.mq5` (F7)
5. Drag the indicator from MT5 Navigator onto any chart

## Signal Type

This indicator generates **BOS/CHoCH** signals.

## ML Signal Accuracy Features

### Signal Tracking
Every signal is recorded with:
- Entry price and time
- Price after 1, 5, and 10 bars
- Maximum favorable and adverse excursion
- Signal quality (Low/Medium/High)
- Market regime at signal time
- Session and hour

### Signal Learning
The indicator learns:
- Which confidence levels produce successful signals
- Which market regimes favor BOS/CHoCH signals
- Which sessions/hours produce reliable signals
- When high-quality signals fail (recalibration alerts)

### Signal Dashboard
The on-chart display shows:
- Signal type: BOS/CHoCH
- Accuracy rate (% of successful signals)
- Total signals vs failures
- Top insight from learning engine

## File Storage

ML data is stored in `MQL5/Files/SmartMoneyConcepts/`:
- `signals.csv` — Signal accuracy journal
- `signal_lessons.csv` — Learned signal insights

## Testing

Run the test suite:
1. Compile `Tests/SmartMoneyConcepts_TestSuite_v0.0.4.mq5` in MetaEditor
2. Attach to any chart
3. Check the Experts tab for test results

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No signals appearing | Check chart timeframe and symbol |
| No ML data | Signals accumulate over time — let it run |
| Dashboard not showing | Ensure chart has enough bars loaded |
