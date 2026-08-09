# Scripts — Trader Demand Ranking

Ranked by market demand and utility value.

| Rank | Script | Why Traders Use It | ML Features | Price Range |
|------|--------|-------------------|-------------|------------|
| 1 | **Risk Calculator** | Lot size from risk % — every trader needs this | Execution stats, success tracking | $10–$30 |
| 2 | **Close All Trades** | Emergency close — essential risk management | Execution logging, duration tracking | $10–$25 |
| 3 | **Set Breakeven All** | Move all to BE — protect profits across positions | Execution journal, result tracking | $10–$25 |
| 4 | **Export Trade History** | Export to CSV — analysis and tax reporting | Execution logging, batch tracking | $5–$15 |
| 5 | **Delete All Pending** | Clean up pending orders — account management | Execution stats, type filtering | $5–$15 |

---

## ML Execution Tracking

All scripts have 2 execution-focused ML modules:
- ExecConfig: tracks success/failure rates, execution duration
- ExecJournal: logs each execution with timestamp, duration, items processed

## Buying Signals

- **Tier 1 (Rank 1–3):** Risk Calculator, Close All, Set Breakeven — essential risk tools
- **Tier 2 (Rank 4–5):** Export History, Delete Pending — utility scripts
- Scripts are often given free as bonuses with EA purchases
