//+------------------------------------------------------------------+
//| TrailingStopEA_v0.0.4.mq5 — Expert Advisor
//| Copyright 2026, PutraWorks
//| MQL5 Market Submission Build + ML Engine
//+------------------------------------------------------------------+
#property copyright "PutraWorks"
#property version   "1.03"
#property link       "https://www.mql5.com"
#property description "Trailing Stop EA — Locks in profit with smart trailing stop algorithms. Universal utility for any trading style."
#property description "Features: ATR-based trailing, fixed-point trailing, step trailing, breakeven activation, and per-position trailing management."
#property description "Ideal for: Any trader who wants automated profit protection across open positions."
#property strict

#include "Include/TrailingStopEA_v0.0.4.mqh"
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
    g_journal.Init("TrailingStopEA");
    g_learning.Init("TrailingStopEA");
    g_evolution.Init();
    g_optimizer.Init(10, false);
    g_reports.Init("TrailingStopEA");
    g_dashboard.Init("TrailingStopEA");
    g_newsManager.Init(30);
    g_newsManager.UpdateCalendar();
    g_indicators.Init(_Symbol, _Period);
    Print("[ML] TrailingStopEA engine initialized");
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
    Print("[ML] TrailingStopEA engine shutdown");
}

void ML_UpdateDashboard()
{
    g_dashboard.Update(g_evolution.GetSummary(), g_learning.GetLessonCount(),
        g_patterns.GetPatternCount(), g_optimizer.GetPendingCount(), g_riskManager.GetDailyPnL());
}

int OnInit()
{
    ML_Init();
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
    ML_OnDeinit();
    if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
    if(psarHandle != INVALID_HANDLE) IndicatorRelease(psarHandle);
}

void OnTick()
{
    ML_OnTick();
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
