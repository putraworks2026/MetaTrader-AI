//+------------------------------------------------------------------+
//|                                          TrailingStopEA.mq5   |
//|                              MetaTrader AI - EAs                |
//|          #4 — Smart trailing stop for all positions             |
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>

//--- Trailing modes
enum ENUM_TRAIL_MODE
{
    TRAIL_FIXED,      // Fixed distance trailing
    TRAIL_ATR,        // ATR-based trailing
    TRAIL_STEP,       // Step trailing (moves in increments)
    TRAIL_BREAKEVEN,   // Breakeven + profit lock
    TRAIL_PSAR         // Parabolic SAR trailing
};

//--- Inputs
input ENUM_TRAIL_MODE InpMode        = TRAIL_FIXED;  // Trailing mode
input double   InpFixedDistance      = 20;            // Fixed distance (points)
input int      InpATRPeriod           = 14;            // ATR period
input double   InpATRMultiplier       = 1.5;           // ATR multiplier
input int      InpStepSize            = 10;            // Step size (points)
input double   InpBETrigger           = 20;            // Breakeven trigger (points)
input double   InpBELockProfit        = 5;             // Lock profit at BE (points)
input int      InpPSARStep            = 20;            // PSAR step (x1000)
input int      InpPSARMax             = 20;            // PSAR max (x1000)
input int      InpMagicNumber         = 0;             // 0 = manage all orders
input int      InpSlippage            = 30;            // Slippage
input bool     InpManageOnlySymbol    = false;          // Only current symbol
input int      InpUpdateFrequency     = 1;             // Update every N seconds

//--- Globals
CTrade   trade;
int      atrHandle = INVALID_HANDLE;
int      psarHandle = INVALID_HANDLE;
datetime lastUpdate = 0;

int OnInit()
{
    trade.SetDeviationInPoints(InpSlippage);

    if(InpMode == TRAIL_ATR)
    {
        atrHandle = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
        if(atrHandle == INVALID_HANDLE) { Print("Failed ATR handle"); return INIT_FAILED; }
    }
    if(InpMode == TRAIL_PSAR)
    {
        psarHandle = iSAR(_Symbol, PERIOD_CURRENT, InpPSARStep / 1000.0, InpPSARMax / 1000.0);
        if(psarHandle == INVALID_HANDLE) { Print("Failed PSAR handle"); return INIT_FAILED; }
    }

    Print("Trailing Stop EA initialized — Mode: ", EnumToString(InpMode));
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
    if(psarHandle != INVALID_HANDLE) IndicatorRelease(psarHandle);
}

void OnTick()
{
    // Throttle updates
    if(TimeCurrent() - lastUpdate < InpUpdateFrequency) return;
    lastUpdate = TimeCurrent();

    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;

        // Magic filter
        if(InpMagicNumber > 0 && PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

        // Symbol filter
        string symbol = PositionGetString(POSITION_SYMBOL);
        if(InpManageOnlySymbol && symbol != _Symbol) continue;

        switch(InpMode)
        {
            case TRAIL_FIXED:     TrailFixed(ticket, symbol); break;
            case TRAIL_ATR:       TrailATR(ticket, symbol); break;
            case TRAIL_STEP:      TrailStep(ticket, symbol); break;
            case TRAIL_BREAKEVEN: TrailBreakeven(ticket, symbol); break;
            case TRAIL_PSAR:      TrailPSAR(ticket, symbol); break;
        }
    }
}

void TrailFixed(ulong ticket, string symbol)
{
    long type = PositionGetInteger(POSITION_TYPE);
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    int stopsLevel = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);

    if(type == POSITION_TYPE_BUY)
    {
        double newSL = NormalizeDouble(bid - InpFixedDistance * point, digits);
        if(newSL > currentSL && newSL <= bid - stopsLevel * point)
            trade.PositionModify(ticket, newSL, currentTP);
    }
    else
    {
        double newSL = NormalizeDouble(ask + InpFixedDistance * point, digits);
        if((currentSL == 0 || newSL < currentSL) && newSL >= ask + stopsLevel * point)
            trade.PositionModify(ticket, newSL, currentTP);
    }
}

void TrailATR(ulong ticket, string symbol)
{
    if(atrHandle == INVALID_HANDLE) return;

    double atr[];
    ArraySetAsSeries(atr, true);
    if(CopyBuffer(atrHandle, 0, 0, 1, atr) < 1) return;

    long type = PositionGetInteger(POSITION_TYPE);
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double trailDist = atr[0] * InpATRMultiplier;

    if(type == POSITION_TYPE_BUY)
    {
        double newSL = NormalizeDouble(bid - trailDist, digits);
        if(newSL > currentSL)
            trade.PositionModify(ticket, newSL, currentTP);
    }
    else
    {
        double newSL = NormalizeDouble(ask + trailDist, digits);
        if(currentSL == 0 || newSL < currentSL)
            trade.PositionModify(ticket, newSL, currentTP);
    }
}

void TrailStep(ulong ticket, string symbol)
{
    long type = PositionGetInteger(POSITION_TYPE);
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

    if(type == POSITION_TYPE_BUY)
    {
        double profit = bid - openPrice;
        int steps = (int)(profit / (InpStepSize * point));
        if(steps > 0)
        {
            double newSL = NormalizeDouble(openPrice + steps * InpStepSize * point, digits);
            if(newSL > currentSL)
                trade.PositionModify(ticket, newSL, currentTP);
        }
    }
    else
    {
        double profit = openPrice - ask;
        int steps = (int)(profit / (InpStepSize * point));
        if(steps > 0)
        {
            double newSL = NormalizeDouble(openPrice - steps * InpStepSize * point, digits);
            if(currentSL == 0 || newSL < currentSL)
                trade.PositionModify(ticket, newSL, currentTP);
        }
    }
}

void TrailBreakeven(ulong ticket, string symbol)
{
    long type = PositionGetInteger(POSITION_TYPE);
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

    if(type == POSITION_TYPE_BUY)
    {
        double profit = bid - openPrice;
        if(profit >= InpBETrigger * point)
        {
            double bePrice = NormalizeDouble(openPrice + InpBELockProfit * point, digits);
            if(bePrice > currentSL)
                trade.PositionModify(ticket, bePrice, currentTP);
        }
    }
    else
    {
        double profit = openPrice - ask;
        if(profit >= InpBETrigger * point)
        {
            double bePrice = NormalizeDouble(openPrice - InpBELockProfit * point, digits);
            if(currentSL == 0 || bePrice < currentSL)
                trade.PositionModify(ticket, bePrice, currentTP);
        }
    }
}

void TrailPSAR(ulong ticket, string symbol)
{
    if(psarHandle == INVALID_HANDLE) return;

    double psar[];
    ArraySetAsSeries(psar, true);
    if(CopyBuffer(psarHandle, 0, 0, 2, psar) < 2) return;

    long type = PositionGetInteger(POSITION_TYPE);
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

    if(type == POSITION_TYPE_BUY)
    {
        double newSL = NormalizeDouble(psar[0], digits);
        if(newSL > currentSL && newSL < SymbolInfoDouble(symbol, SYMBOL_BID))
            trade.PositionModify(ticket, newSL, currentTP);
    }
    else
    {
        double newSL = NormalizeDouble(psar[0], digits);
        if((currentSL == 0 || newSL < currentSL) && newSL > SymbolInfoDouble(symbol, SYMBOL_ASK))
            trade.PositionModify(ticket, newSL, currentTP);
    }
}
