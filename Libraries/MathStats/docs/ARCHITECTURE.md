# MathStats — Architecture

## Overview

Statistical math functions (mean, std, skew, kurtosis). Part of the PutraWorks MetaTrader-AI collection.

## Purpose

This is a reusable library — it provides utility functions used by EAs, indicators, and scripts. It does not have ML modules and does not trade independently.

## Usage

```mql5
#include "MathStats.mqh"
```

Include from any EA, indicator, or script that needs this functionality.

## File Structure

```
MathStats/
├── Include/
│   └── MathStats.mqh          # Main library header
├── docs/
│   └── ARCHITECTURE.md    # This file
├── Publish/
│   └── README.md         # Market submission notes
└── Archive/
    └── MathStats_v0.0.1.mqh   # Previous version (read-only)
```

## Dependencies

Libraries are standalone — they do not depend on other libraries or ML modules. They are consumed by tools that need their functionality.
