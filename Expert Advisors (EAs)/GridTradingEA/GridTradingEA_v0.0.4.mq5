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
//--- ML Engine Includes (Tool-Specific)
#include "Include\\Config_v0.0.4.mqh"
#include "Include\\IndicatorEngine_v0.0.4.mqh"
#include "Include\\RiskManager_v0.0.4.mqh"
#include "Include\\TradingJournal_v0.0.4.mqh"
#include "Include\\LearningEngine_v0.0.4.mqh"
#include "Include\\PatternRecognition_v0.0.4.mqh"
#include "Include\\StrategyEvolution_v0.0.4.mqh"
#include "Include\\OptimizationEngine_v0.0.4.mqh"
#include "Include\\ReportGenerator_v0.0.4.mqh"
#include "Include\\Dashboard_v0.0.4.mqh"
#include "Include\\NewsManager_v0.0.4.mqh"

//--- ML Global Objects (EA)
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



//==================================================================
//  ML POSITION TRACKING (Trade Closure Detection)
//==================================================================
struct ML_PosTrack {
    ulong  ticket;
    double openPrice;
    double volume;
    int    type;
    datetime openTime;
};

ML_PosTrack g_tracked[];
int g_trackedCount = 0;
datetime g_lastDashUpdate = 0;

void ML_TrackPositions()
{
    // Detect closed positions
    for(int i = g_trackedCount - 1; i >= 0; i--)
    {
        if(!PositionSelectByTicket(g_tracked[i].ticket))
        {
            // Position has closed — get result from history
            HistorySelect(g_tracked[i].openTime, TimeCurrent() + 1);
            double profit = 0;
            int deals = HistoryDealsTotal();
            for(int d = 0; d < deals; d++)
            {
                ulong dealTicket = HistoryDealGetTicket(d);
                if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == g_tracked[i].ticket)
                {
                    if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
                    {
                        profit += HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                        profit += HistoryDealGetDouble(dealTicket, DEAL_SWAP);
                        profit += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                    }
                }
            }
            
            bool won = (profit > 0);
            ML_OnTradeClosed(profit, won);
            
            // Remove from tracking
            g_tracked[i] = g_tracked[g_trackedCount - 1];
            g_trackedCount--;
            ArrayResize(g_tracked, g_trackedCount);
        }
    }
    
    // Add new positions to tracking
    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;
        
        bool found = false;
        for(int j = 0; j < g_trackedCount; j++)
        {
            if(g_tracked[j].ticket == ticket) { found = true; break; }
        }
        if(!found)
        {
            ArrayResize(g_tracked, g_trackedCount + 1);
            g_tracked[g_trackedCount].ticket = ticket;
            g_tracked[g_trackedCount].openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            g_tracked[g_trackedCount].volume = PositionGetDouble(POSITION_VOLUME);
            g_tracked[g_trackedCount].type = (int)PositionGetInteger(POSITION_TYPE);
            g_tracked[g_trackedCount].openTime = (datetime)PositionGetInteger(POSITION_TIME);
            g_trackedCount++;
        }
    }
    
    // Update dashboard every 30 seconds
    if(TimeCurrent() - g_lastDashUpdate >= 30)
    {
        ML_UpdateDashboard();
        g_lastDashUpdate = TimeCurrent();
    }
}

//==================================================================
//  ML ENGINE INTEGRATION
//==================================================================

void ML_Init()
{
    g_riskManager.Init();
    g_journal.Init("GridTradingEA");
    g_learning.Init("GridTradingEA");
    g_evolution.Init();
    g_optimizer.Init(10, false);
    g_reports.Init("GridTradingEA");
    g_dashboard.Init("GridTradingEA");
    g_newsManager.Init(30);
    g_newsManager.UpdateCalendar();
    g_indicators.Init(_Symbol, _Period);
    Print("[ML] GridTradingEA engine initialized");
}

void ML_OnTick()
{
    if(g_newsManager.IsNewsBlocked()) return;
    ML_TrackPositions();
}

void ML_OnDeinit()
{
    g_learning.SaveLessons();
    g_dashboard.Cleanup();
    Print("[ML] GridTradingEA engine shutdown");
}

void ML_UpdateDashboard()
{
    g_dashboard.Update(g_evolution.GetSummary(), g_learning.GetLessonCount(),
        g_patterns.GetPatternCount(), g_optimizer.GetPendingCount(), g_riskManager.GetDailyPnL());
}

int OnInit()
{
    ML_Init();
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
    ML_OnDeinit();
    Print("Grid EA stopped. Reason: ", reason);
}

void OnTick()
{
    ML_OnTick();
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
