//+------------------------------------------------------------------+
//| BreakoutEA.mqh — Include file for BreakoutEA
//| MetaTrader AI — Function Library
//| Version: v0.0.2
//+------------------------------------------------------------------+
#ifndef __BREAKOUTEA_MQH__
#define __BREAKOUTEA_MQH__

//+------------------------------------------------------------------+
//|                                            BreakoutEA.mq5     |
//|                              MetaTrader AI - EAs                |
//|          #5 — Trades range breakouts with volume filter         |
//+------------------------------------------------------------------+

#include <Trade/Trade.mqh>

//--- Inputs

//--- Globals
CTrade   trade;
int      handleVolume;
datetime lastBarTime = 0;
double   rangeHigh = 0;
double   rangeLow  = 0;
bool     rangeSet = false;


bool IsInSession()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    return (dt.hour >= InpStartHour && dt.hour < InpEndHour);
}

int CountPositions()
{
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;
        if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber &&
           PositionGetString(POSITION_SYMBOL) == _Symbol)
            count++;
    }
    return count;
}

void ApplyTrailing()
{
    double point = _Point;
    int digits = _Digits;

    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;
        if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
        if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

        long type = PositionGetInteger(POSITION_TYPE);
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentSL = PositionGetDouble(POSITION_SL);
        double currentTP = PositionGetDouble(POSITION_TP);
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        if(type == POSITION_TYPE_BUY)
        {
            if(bid - openPrice > InpTrailingStart * point)
            {
                double newSL = NormalizeDouble(bid - InpTrailingDistance * point, digits);
                if(newSL > currentSL) trade.PositionModify(ticket, newSL, currentTP);
            }
        }
        else
        {
            if(openPrice - ask > InpTrailingStart * point)
            {
                double newSL = NormalizeDouble(ask + InpTrailingDistance * point, digits);
                if(currentSL == 0 || newSL < currentSL) trade.PositionModify(ticket, newSL, currentTP);
            }
        }
    }
}

#endif // __BREAKOUTEA_MQH__
