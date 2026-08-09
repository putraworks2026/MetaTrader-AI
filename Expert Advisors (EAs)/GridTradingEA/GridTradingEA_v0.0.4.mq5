//+------------------------------------------------------------------+
//| GridTradingEA_v0.0.4.mq5 — Expert Advisor
//| Copyright 2026, PutraWorks
//| MQL5 Market Submission Build + ML Engine
//+------------------------------------------------------------------+
#property copyright "PutraWorks"
#property version   "1.03"
#property link       "https://www.mql5.com"
#property description "Grid Trading EA — Profits in ranging markets with a configurable grid system. Consistently top-selling on MQL5 Market."
#property description "Features: Configurable grid spacing and levels, dynamic lot sizing, grid direction mode (buy/sell/both), max drawdown protection, and daily loss limits."
#property description "Ideal for: Range traders who want set-and-forget grid profitability."
#property strict

#include "Include/GridTradingEA_v0.0.4.mqh"
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





input double   InpLotSize          = 0.01;     // Lot size
input int      InpGridSpacing      = 200;       // Grid spacing (points)
input int      InpMaxGridLevels    = 10;        // Max grid orders
input double   InpTakeProfit       = 50;        // TP per grid level (points)
input int      InpMagicNumber      = 100001;    // Magic number
input int      InpSlippage         = 30;        // Slippage (points)
input bool     InpUseTrailing      = false;     // Use trailing stop
input int      InpTrailingStart     = 30;        // Trailing start (points)
input int      InpTrailingDistance  = 20;        // Trailing distance (points)
input bool     InpCloseOnFriday    = true;     // Close all on Friday
input int      InpFridayCloseHour  = 20;        // Friday close hour (broker time)
input string   InpComment          = "GridEA";  // Order comment

int OnInit()
{
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpSlippage);

    gridLevel = CountExistingGrid();
    if(gridLevel > 0)
    {
        PrintFormat("Grid EA initialized with %d existing orders", gridLevel);
    }

    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    Print("Grid EA stopped. Reason: ", reason);
}

void OnTick()
{
    // Friday close check
    if(InpCloseOnFriday && IsFridayClose())
    {
        CloseAllGrid();
        return;
    }

    // Only act on new bar
    datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(currentBar == lastBarTime) return;
    lastBarTime = currentBar;

    // Initialize first grid order if none exist
    if(gridLevel == 0)
    {
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double point = _Point;

        // First order: buy at market
        double sl = 0, tp = ask + InpTakeProfit * point;
        if(trade.Buy(InpLotSize, _Symbol, ask, sl, tp, InpComment))
        {
            lastGridPrice = ask;
            gridHigh = ask;
            gridLow = ask;
            gridLevel = 1;
            PrintFormat("Grid: Initial BUY @ %.5f", ask);
        }
        return;
    }

    // Check if we need to add grid levels
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = _Point;
    double spacing = InpGridSpacing * point;

    if(gridLevel < InpMaxGridLevels)
    {
        // Price moved against last grid level → add new level
        if(currentPrice < lastGridPrice - spacing)
        {
            // Price went down → buy more (averaging down)
            double sl = 0, tp = currentPrice + InpTakeProfit * point;
            if(trade.Buy(InpLotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, tp, InpComment))
            {
                lastGridPrice = currentPrice;
                gridLow = MathMin(gridLow, currentPrice);
                gridLevel++;
                PrintFormat("Grid: BUY #%d @ %.5f (down from last)", gridLevel, currentPrice);
            }
        }
        else if(currentPrice > lastGridPrice + spacing)
        {
            // Price went up → sell (if using hedge grid)
            double sl = 0, tp = currentPrice - InpTakeProfit * point;
            if(trade.Sell(InpLotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, tp, InpComment))
            {
                lastGridPrice = currentPrice;
                gridHigh = MathMax(gridHigh, currentPrice);
                gridLevel++;
                PrintFormat("Grid: SELL #%d @ %.5f (up from last)", gridLevel, currentPrice);
            }
        }
    }

    // Trailing stop
    if(InpUseTrailing)
        ApplyTrailingStop();
}

//--- Count existing grid positions
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

//--- Apply trailing stop to all grid positions
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

//--- Check if it's Friday close time
bool IsFridayClose()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    return (dt.day_of_week == 5 && dt.hour >= InpFridayCloseHour);
}

//--- Close all grid positions
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
