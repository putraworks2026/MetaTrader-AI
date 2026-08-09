//+------------------------------------------------------------------+
//| BreakoutEA_v0.0.4.mq5 — Expert Advisor
//| Copyright 2026, PutraWorks
//| MQL5 Market Submission Build + ML Engine
//+------------------------------------------------------------------+
#property copyright "PutraWorks"
#property version   "1.03"
#property link       "https://www.mql5.com"
#property description "Breakout EA — Trades range breakouts with a volume filter for confirmation. Designed for trending market conditions."
#property description "Features: Automatic range detection, volume-based breakout confirmation, ATR-based SL/TP, trailing stop, session filtering, and max spread protection."
#property description "Ideal for: Breakout traders who want automated execution with volume confirmation."
#property strict

#include "Include/BreakoutEA.mqh"
//--- ML Engine Includes (AIEA Architecture)
#include "Include\\Config.mqh"
#include "Include\\IndicatorEngine.mqh"
#include "Include\\RiskManager.mqh"
#include "Include\\TradingJournal.mqh"
#include "Include\\LearningEngine.mqh"
#include "Include\\PatternRecognition.mqh"
#include "Include\\StrategyEvolution.mqh"
#include "Include\\OptimizationEngine.mqh"
#include "Include\\ReportGenerator.mqh"
#include "Include\\Dashboard.mqh"
#include "Include\\NewsManager.mqh"

//--- ML Global Objects
CRiskManager         g_riskManager;
CTradingJournal      g_journal;
CLearningEngine      g_learning;
CPatternRecognition  g_patterns;
CStrategyEvolution   g_evolution;
COptimizationEngine  g_optimizer;
CReportGenerator     g_reports;
CDashboard           g_dashboard;
CNewsManager         g_newsManager;
CIndicatorEngine     g_indicators;





input int      InpRangePeriod      = 20;        // Bars to detect range
input int      InpVolumePeriod      = 10;        // Volume MA period
input double   InpVolumeMultiplier  = 1.5;       // Min volume vs average for breakout
input double   InpLotSize          = 0.01;       // Lot size
input int      InpTakeProfit       = 100;        // TP (points)
input int      InpStopLoss         = 50;         // SL (points)
input int      InpMaxSpread        = 20;         // Max spread (points)
input int      InpMaxPositions     = 2;          // Max simultaneous positions
input int      InpMagicNumber      = 100005;      // Magic number
input int      InpSlippage        = 30;          // Slippage
input bool     InpUseTrailing     = true;        // Use trailing stop
input int      InpTrailingStart    = 30;          // Trailing start (points)
input int      InpTrailingDistance = 15;          // Trailing distance (points)
input bool     InpTradeSessions    = true;        // Trade only during active sessions
input int      InpStartHour       = 7;            // Session start
input int      InpEndHour         = 20;           // Session end
input int      InpRangeMinPoints   = 50;          // Min range size (points)

int OnInit()
{
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpSlippage);

    handleVolume = iVolumes(_Symbol, PERIOD_CURRENT, VOLUME_TICK);
    if(handleVolume == INVALID_HANDLE)
    {
        Print("Failed to create volume indicator");
        return INIT_FAILED;
    }

    return INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    IndicatorRelease(handleVolume);
}

void OnTick()
{
    datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(currentBar == lastBarTime) return;

    // Session filter
    if(InpTradeSessions && !IsInSession()) { lastBarTime = currentBar; return; }

    // Spread filter
    if((int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > InpMaxSpread) return;

    // Position limit
    if(CountPositions() >= InpMaxPositions) { lastBarTime = currentBar; return; }

    // Detect range (lookback high/low over N bars)
    double high[], low[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);

    if(CopyHigh(_Symbol, PERIOD_CURRENT, 1, InpRangePeriod, high) < InpRangePeriod) return;
    if(CopyLow(_Symbol, PERIOD_CURRENT, 1, InpRangePeriod, low) < InpRangePeriod) return;

    rangeHigh = high[0];
    rangeLow  = low[0];
    for(int i = 1; i < InpRangePeriod; i++)
    {
        if(high[i] > rangeHigh) rangeHigh = high[i];
        if(low[i]  < rangeLow)  rangeLow  = low[i];
    }

    double rangePoints = (rangeHigh - rangeLow) / _Point;
    if(rangePoints < InpRangeMinPoints) { lastBarTime = currentBar; return; }

    rangeSet = true;

    // Get current bar close (previous bar)
    double close[];
    ArraySetAsSeries(close, true);
    if(CopyClose(_Symbol, PERIOD_CURRENT, 1, 2, close) < 2) return;

    // Volume filter
    double vol[];
    ArraySetAsSeries(vol, true);
    if(CopyBuffer(handleVolume, 0, 1, InpVolumePeriod + 1, vol) < InpVolumePeriod + 1) return;

    double avgVolume = 0;
    for(int i = 1; i <= InpVolumePeriod; i++) avgVolume += vol[i];
    avgVolume /= InpVolumePeriod;

    bool volumeConfirmed = (vol[0] > avgVolume * InpVolumeMultiplier);

    // Breakout signals
    bool breakUp   = (close[0] > rangeHigh && volumeConfirmed);
    bool breakDown = (close[0] < rangeLow  && volumeConfirmed);

    double point = _Point;
    int digits = _Digits;

    if(breakUp)
    {
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double sl = NormalizeDouble(ask - InpStopLoss * point, digits);
        double tp = NormalizeDouble(ask + InpTakeProfit * point, digits);
        if(trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "Breakout"))
            PrintFormat("BREAKOUT BUY @ %.5f | Range: %.5f-%.5f (%.0f pts) | Vol: %.0f > %.0f",
                        ask, rangeLow, rangeHigh, rangePoints, vol[0], avgVolume);
    }
    else if(breakDown)
    {
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double sl = NormalizeDouble(bid + InpStopLoss * point, digits);
        double tp = NormalizeDouble(bid - InpTakeProfit * point, digits);
        if(trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "Breakout"))
            PrintFormat("BREAKOUT SELL @ %.5f | Range: %.5f-%.5f (%.0f pts) | Vol: %.0f > %.0f",
                        bid, rangeLow, rangeHigh, rangePoints, vol[0], avgVolume);
    }

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
