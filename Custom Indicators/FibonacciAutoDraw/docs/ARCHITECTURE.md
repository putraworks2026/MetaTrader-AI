# FibonacciAutoDraw — Architecture

## Overview

Auto-identifies swings and draws fib levels. Part of the PutraWorks MetaTrader-AI collection.

## Signal Type

This indicator generates **Fib Retracement Touch** signals.

## ML Module Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  FibonacciAutoDraw_v0.0.4.mq5                       │
│                (Main Indicator Entry Point)              │
├──────────┬──────────┬──────────┬──────────┬────────────┤
│ Signal   │ Signal   │ Signal   │ Signal   │  Signal    │
│ Config   │ Journal  │ Learning │ Patterns │  Dashboard │
│ _v0.0.4  │ _v0.0.4  │ _v0.0.4  │ _v0.0.4  │  _v0.0.4   │
└──────────┴──────────┴──────────┴──────────┴────────────┘
```

## ML Modules (5 files — signal-focused)

| Module | File | Purpose |
|--------|------|---------|
| SignalConfig | SignalConfig_v0.0.4.mqh | Signal quality enums, SignalProfile struct |
| SignalJournal | SignalJournal_v0.0.4.mqh | Tracks Fib Retracement Touch signal accuracy (price after 1/5/10 bars) |
| SignalLearning | SignalLearning_v0.0.4.mqh | Learns which Fib Retracement Touch conditions are reliable |
| SignalPatterns | SignalPatterns_v0.0.4.mqh | Scores Fib Retracement Touch conditions by success rate |
| SignalDashboard | SignalDashboard_v0.0.4.mqh | On-chart signal accuracy display |

## Why No Trading Modules?

Indicators do not execute trades. They generate signals. The ML tracks:
- Signal accuracy (did the signal predict the right direction?)
- Signal quality (how confident was the signal?)
- Signal conditions (which market conditions produce good signals?)
- Signal timing (which sessions/hours produce reliable signals?)

## Include Chain

```
SignalConfig (base)
  ├── SignalJournal → SignalConfig
  ├── SignalLearning → SignalConfig + SignalJournal
  └── SignalPatterns → SignalConfig
SignalDashboard (standalone)
```

## File Structure

```
FibonacciAutoDraw/
├── FibonacciAutoDraw_v0.0.4.mq5              # Main file — compile this
├── Include/
│   ├── FibonacciAutoDraw_v0.0.4.mqh           # Core indicator logic
│   ├── SignalConfig_v0.0.4.mqh     # Signal configuration
│   ├── SignalJournal_v0.0.4.mqh   # Signal accuracy journal
│   ├── SignalLearning_v0.0.4.mqh  # Signal reliability learning
│   ├── SignalPatterns_v0.0.4.mqh  # Signal pattern scoring
│   └── SignalDashboard_v0.0.4.mqh # On-chart display
├── Tests/FibonacciAutoDraw_TestSuite_v0.0.4.mq5
├── docs/
│   ├── ARCHITECTURE.md
│   ├── USER_GUIDE.md
│   └── CHANGELOG.md
├── Publish/README.md
└── Archive/                       # Previous versions (read-only)
    ├── FibonacciAutoDraw_v0.0.1.mq5
    ├── FibonacciAutoDraw_v0.0.2.mq5
    └── FibonacciAutoDraw_v0.0.3.mq5
```
