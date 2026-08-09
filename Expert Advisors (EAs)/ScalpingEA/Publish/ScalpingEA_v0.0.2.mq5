//+------------------------------------------------------------------+
//| ScalpingEA_v0.0.2.mq5 — Publish Entry Point
//| MetaTrader AI — Expert Advisors (EAs)
//| Version: v0.0.2
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.01"
#property strict

#include "ScalpingEA.mqh"

input int      InpFastMA          = 5;         // Fast EMA period
input int      InpSlowMA          = 15;        // Slow EMA period
input int      InpRSIPeriod       = 7;         // RSI period
input double   InpRSIOb           = 70.0;      // RSI overbought
input double   InpRSIOs           = 30.0;      // RSI oversold
input double   InpLotSize         = 0.01;      // Lot size
input int      InpTakeProfit       = 50;        // TP (points)
input int      InpStopLoss         = 30;        // SL (points)
input int      InpMaxSpread        = 20;        // Max spread (points)
input int      InpMaxPositions    = 3;         // Max simultaneous positions
input int      InpMagicNumber      = 100002;    // Magic number
input int      InpSlippage        = 10;        // Slippage (points)
input bool     InpUseTrailing     = true;      // Use trailing stop
input int      InpTrailingStart    = 15;        // Trailing start (points)
input int      InpTrailingDistance = 10;        // Trailing distance (points)
input bool     InpTradeOnlyLondon  = true;      // Trade only during London session
input int      InpStartHour       = 7;         // Session start hour
input int      InpEndHour         = 16;        // Session end hour

int OnInit()
{
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpSlippage);

    handleFastMA = iMA(_Symbol, PERIOD_CURRENT, InpFastMA, 0, MODE_EMA, PRICE_CLOSE);
    handleSlowMA = iMA(_Symbol, PERIOD_CURRENT, InpSlowMA, 0, MODE_EMA, PRICE_CLOSE);
    handleRSI   = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);

    if(handleFastMA == INVALID_HANDLE || handleSlowMA == INVALID_HANDLE || handleRSI == INVALID_HANDLE)
    {
        Print("Error creating indicators");
        return(INIT_FAILED);
    }

    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    IndicatorRelease(handleFastMA);
    IndicatorRelease(handleSlowMA);
    IndicatorRelease(handleRSI);
}

void OnTick()
{
    // Only trade on new bar
    datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(currentBar == lastBarTime) return;

    // Check session
    if(InpTradeOnlyLondon && !IsInSession())
    {
        lastBarTime = currentBar;
        return;
    }

    // Check spread
    int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    if(spread > InpMaxSpread) return;

    // Check max positions
    if(CountPositions() >= InpMaxPositions)
    {
        lastBarTime = currentBar;
        return;
    }

    // Get indicator values
    double fastMA[], slowMA[], rsi[];
    ArraySetAsSeries(fastMA, true);
    ArraySetAsSeries(slowMA, true);
    ArraySetAsSeries(rsi, true);

    if(CopyBuffer(handleFastMA, 0, 0, 3, fastMA) < 3) return;
    if(CopyBuffer(handleSlowMA, 0, 0, 3, slowMA) < 3) return;
    if(CopyBuffer(handleRSI, 0, 0, 3, rsi) < 3) return;

    // Signals: EMA crossover + RSI filter
    bool buySignal  = (fastMA[1] > slowMA[1] && fastMA[2] <= slowMA[2] && rsi[1] < InpRSIOb);
    bool sellSignal = (fastMA[1] < slowMA[1] && fastMA[2] >= slowMA[2] && rsi[1] > InpRSIOs);

    double point = _Point;
    int digits = _Digits;

    if(buySignal)
    {
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double sl = NormalizeDouble(ask - InpStopLoss * point, digits);
        double tp = NormalizeDouble(ask + InpTakeProfit * point, digits);
        if(trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "Scalp"))
            PrintFormat("Scalp BUY @ %.5f | SL: %.5f | TP: %.5f", ask, sl, tp);
    }
    else if(sellSignal)
    {
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double sl = NormalizeDouble(bid + InpStopLoss * point, digits);
        double tp = NormalizeDouble(bid - InpTakeProfit * point, digits);
        if(trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "Scalp"))
            PrintFormat("Scalp SELL @ %.5f | SL: %.5f | TP: %.5f", bid, sl, tp);
    }

    // Trailing stop
    if(InpUseTrailing) ApplyTrailing();

    lastBarTime = currentBar;
}

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
                if(newSL > currentSL)
                    trade.PositionModify(ticket, newSL, currentTP);
            }
        }
        else if(type == POSITION_TYPE_SELL)
        {
            if(openPrice - ask > InpTrailingStart * point)
            {
                double newSL = NormalizeDouble(ask + InpTrailingDistance * point, digits);
                if(currentSL == 0 || newSL < currentSL)
                    trade.PositionModify(ticket, newSL, currentTP);
            }
        }
    }
}
