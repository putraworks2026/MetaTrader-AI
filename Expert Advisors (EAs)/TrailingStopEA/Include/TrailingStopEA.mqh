//+------------------------------------------------------------------+
//| TrailingStopEA.mqh — Include file for TrailingStopEA
//| MetaTrader AI — Function Library
//| Version: v0.0.2
//+------------------------------------------------------------------+
#ifndef __TRAILINGSTOPEA_MQH__
#define __TRAILINGSTOPEA_MQH__

//+------------------------------------------------------------------+
//|                                          TrailingStopEA.mq5   |
//|                              MetaTrader AI - EAs                |
//|          #4 — Smart trailing stop for all positions             |
//+------------------------------------------------------------------+

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

//--- Globals
CTrade   trade;
int      atrHandle = INVALID_HANDLE;
int      psarHandle = INVALID_HANDLE;
datetime lastUpdate = 0;


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

#endif // __TRAILINGSTOPEA_MQH__
