# DeleteAllPending — Architecture

## Overview

Deletes all pending orders by type. Part of the PutraWorks MetaTrader-AI collection.

## Action Type

This script performs: **Delete Pending Orders**

## ML Module Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  DeleteAllPending_v0.0.4.mq5                       │
│               (Main Script Entry Point)                  │
├──────────────────────────────────────────┬──────────────┤
│ ExecConfig                               │ ExecJournal  │
│ _v0.0.4.mqh                             │ _v0.0.4.mqh  │
└──────────────────────────────────────────┴──────────────┘
```

## ML Modules (2 files — execution-focused)

| Module | File | Purpose |
|--------|------|---------|
| ExecConfig | ExecConfig_v0.0.4.mqh | Execution result enums, ExecStats struct (success/fail/partial tracking) |
| ExecJournal | ExecJournal_v0.0.4.mqh | Logs each Delete Pending Orders execution with duration, items processed, result |

## Why No Learning/Optimization Modules?

Scripts are one-shot utilities — they run once, perform an action, and stop. They don't need:
- Pattern recognition (no recurring patterns to track)
- Learning engine (no continuous trading to learn from)
- Strategy evolution (no profiles to manage)
- Optimization engine (no parameters to adapt)

The ML simply tracks execution success rates and logs each run.

## Include Chain

```
ExecConfig (base — no dependencies)
  └── ExecJournal → ExecConfig
```

## File Structure

```
DeleteAllPending/
├── DeleteAllPending_v0.0.4.mq5              # Main file — compile this
├── Include/
│   ├── DeleteAllPending_v0.0.4.mqh           # Core script logic
│   ├── ExecConfig_v0.0.4.mqh      # Execution config
│   └── ExecJournal_v0.0.4.mqh     # Execution journal
├── Tests/DeleteAllPending_TestSuite_v0.0.4.mq5
├── docs/
│   ├── ARCHITECTURE.md
│   ├── USER_GUIDE.md
│   └── CHANGELOG.md
├── Publish/README.md
└── Archive/                       # Previous versions (read-only)
    ├── DeleteAllPending_v0.0.1.mq5
    ├── DeleteAllPending_v0.0.2.mq5
    └── DeleteAllPending_v0.0.3.mq5
```
