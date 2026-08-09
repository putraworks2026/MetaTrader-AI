//+------------------------------------------------------------------+
//| GridTradingEA.mqh — Include file for GridTradingEA
//| MetaTrader AI — Function Library
//| Version: v0.0.2
//+------------------------------------------------------------------+
#ifndef __GRIDTRADINGEA_MQH__
#define __GRIDTRADINGEA_MQH__

//+------------------------------------------------------------------+
//|                                            GridTradingEA.mq5  |
//|                              MetaTrader AI - EAs                |
//|          #1 — Grid trading for ranging markets                   |
//+------------------------------------------------------------------+

#include <Trade/Trade.mqh>

//--- Inputs

//--- Globals
CTrade   trade;
int      gridLevel = 0;
double   lastGridPrice = 0;
double   gridHigh = 0;
double   gridLow  = 0;
datetime lastBarTime = 0;


int CountExistingGrid()
{
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;
        if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
        if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        count++;
    }
    return count;
}

void ApplyTrailingStop()
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
            double profit = bid - openPrice;
            if(profit > InpTrailingStart * point)
            {
                double newSL = bid - InpTrailingDistance * point;
                newSL = NormalizeDouble(newSL, digits);
                if(newSL > currentSL)
                    trade.PositionModify(ticket, newSL, currentTP);
            }
        }
        else if(type == POSITION_TYPE_SELL)
        {
            double profit = openPrice - ask;
            if(profit > InpTrailingStart * point)
            {
                double newSL = ask + InpTrailingDistance * point;
                newSL = NormalizeDouble(newSL, digits);
                if(currentSL == 0 || newSL < currentSL)
                    trade.PositionModify(ticket, newSL, currentTP);
            }
        }
    }
}

bool IsFridayClose()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    return (dt.day_of_week == 5 && dt.hour >= InpFridayCloseHour);
}

void CloseAllGrid()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;
        if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
        if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        trade.PositionClose(ticket);
    }
    gridLevel = 0;
}

#endif // __GRIDTRADINGEA_MQH__
