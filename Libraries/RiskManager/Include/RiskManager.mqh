//+------------------------------------------------------------------+
//|                                           RiskManager.mqh      |
//|                              MetaTrader AI - Libraries           |
//|          #1 — Lot sizing, drawdown limits, daily loss caps        |
//+------------------------------------------------------------------+
#ifndef __RISKMANAGER_MQH__
#define __RISKMANAGER_MQH__

#property copyright "MetaTrader AI"
#property version   "1.01"

//--- Risk configuration structure
struct RiskConfig
{
    double   maxRiskPercent;       // Max risk per trade (% of balance)
    double   maxDailyLossPercent;  // Max daily loss (% of balance)
    double   maxDrawdownPercent;   // Max overall drawdown (% of balance)
    int      maxConcurrentTrades;  // Max simultaneous positions
    int      maxTradesPerDay;       // Max new trades per day
    bool     useRiskReward;         // Enforce minimum R/R ratio
    double   minRiskReward;         // Minimum R/R ratio
    double   fixedLotSize;          // 0 = auto-calculate, >0 = fixed lot
    double   accountBalance;        // 0 = use current balance
};

//--- Risk state tracking
struct RiskState
{
    double   dayStartBalance;
    double   dayStartEquity;
    datetime dayStartTime;
    int      tradesToday;
    double   realizedDailyLoss;
    double   peakEquity;
    bool     tradingHalted;
};

//--- Default risk configuration
RiskConfig CreateDefaultRiskConfig()
{
    RiskConfig cfg;
    cfg.maxRiskPercent      = 1.0;
    cfg.maxDailyLossPercent  = 5.0;
    cfg.maxDrawdownPercent   = 20.0;
    cfg.maxConcurrentTrades  = 5;
    cfg.maxTradesPerDay      = 10;
    cfg.useRiskReward        = true;
    cfg.minRiskReward        = 1.5;
    cfg.fixedLotSize         = 0.0;
    cfg.accountBalance       = 0.0;
    return cfg;
}

//--- Initialize risk state for a new day
RiskState InitRiskState()
{
    RiskState state;
    state.dayStartBalance   = AccountInfoDouble(ACCOUNT_BALANCE);
    state.dayStartEquity     = AccountInfoDouble(ACCOUNT_EQUITY);
    state.dayStartTime       = TimeCurrent();
    state.tradesToday        = 0;
    state.realizedDailyLoss  = 0.0;
    state.peakEquity          = AccountInfoDouble(ACCOUNT_EQUITY);
    state.tradingHalted       = false;
    return state;
}

//--- Check if a new day has started (reset daily counters)
void CheckNewDay(RiskState &state)
{
    MqlDateTime now, dayStart;
    TimeToStruct(TimeCurrent(), now);
    TimeToStruct(state.dayStartTime, dayStart);

    if(now.day != dayStart.day || now.mon != dayStart.mon)
    {
        state.dayStartBalance   = AccountInfoDouble(ACCOUNT_BALANCE);
        state.dayStartEquity     = AccountInfoDouble(ACCOUNT_EQUITY);
        state.dayStartTime       = TimeCurrent();
        state.tradesToday        = 0;
        state.realizedDailyLoss  = 0.0;
        state.tradingHalted       = false;
    }

    // Track peak equity
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    if(equity > state.peakEquity) state.peakEquity = equity;
}

//--- Calculate lot size based on risk percentage and SL distance
double CalculateLotSize(RiskConfig &cfg, string symbol, double slPips)
{
    if(cfg.fixedLotSize > 0) return cfg.fixedLotSize;

    double balance = (cfg.accountBalance > 0) ? cfg.accountBalance : AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * (cfg.maxRiskPercent / 100.0);

    double pipSize  = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double volMin    = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double volMax    = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double volStep   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

    if(tickSize == 0 || tickValue == 0 || slPips <= 0) return volMin;

    double slTicks = (slPips * pipSize) / tickSize;
    double lossPerLot = slTicks * tickValue;
    if(lossPerLot <= 0) return volMin;

    double lotSize = riskAmount / lossPerLot;

    // Normalize
    lotSize = MathRound(lotSize / volStep) * volStep;
    lotSize = MathMax(volMin, lotSize);
    lotSize = MathMin(volMax, lotSize);

    return lotSize;
}

//--- Check if trading is allowed under risk rules
bool CanTrade(RiskConfig &cfg, RiskState &state)
{
    CheckNewDay(state);

    if(state.tradingHalted) return false;

    // Check daily loss limit
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double dailyLoss = state.dayStartEquity - equity;
    double maxDailyLoss = state.dayStartBalance * (cfg.maxDailyLossPercent / 100.0);
    if(dailyLoss >= maxDailyLoss)
    {
        state.tradingHalted = true;
        Print("RISK: Daily loss limit reached — trading halted");
        return false;
    }

    // Check max drawdown
    double drawdown = state.peakEquity - equity;
    double maxDrawdown = state.peakEquity * (cfg.maxDrawdownPercent / 100.0);
    if(drawdown >= maxDrawdown)
    {
        state.tradingHalted = true;
        Print("RISK: Max drawdown reached — trading halted");
        return false;
    }

    // Check concurrent trades
    if(PositionsTotal() >= cfg.maxConcurrentTrades) return false;

    // Check trades per day
    if(state.tradesToday >= cfg.maxTradesPerDay) return false;

    return true;
}

//--- Record a new trade
void RecordTrade(RiskState &state)
{
    state.tradesToday++;
}

//--- Validate risk/reward ratio
bool ValidateRiskReward(RiskConfig &cfg, double slPips, double tpPips)
{
    if(!cfg.useRiskReward) return true;
    if(slPips <= 0) return false;
    double rr = tpPips / slPips;
    return rr >= cfg.minRiskReward;
}

//--- Get current drawdown percentage
double GetDrawdownPercent(RiskState &state)
{
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    if(state.peakEquity <= 0) return 0;
    return ((state.peakEquity - equity) / state.peakEquity) * 100.0;
}

//--- Get daily P/L
double GetDailyPnL(RiskState &state)
{
    return AccountInfoDouble(ACCOUNT_EQUITY) - state.dayStartEquity;
}

#endif // __RISKMANAGER_MQH__
