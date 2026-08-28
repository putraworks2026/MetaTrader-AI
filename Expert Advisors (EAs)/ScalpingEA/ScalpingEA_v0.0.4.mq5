//+------------------------------------------------------------------+
//| ScalpingEA_v0.0.4.mq5 — Expert Advisor
//| Copyright 2026, PutraWorks
//| MQL5 Market Submission Build + ML Engine
//+------------------------------------------------------------------+
#property copyright "PutraWorks"
#property version   "1.03"
#property link       "https://www.mql5.com"
#property description "Scalping EA — Fast in-and-out trades with tight spreads. Highest search volume of any EA type on MQL5 Market."
#property description "Features: RSI-based scalping signals, micro TP targets, spread filter, max positions control, and rapid trade execution."
#property description "Ideal for: Scalpers who want automated fast-trade execution with risk controls."
#property strict

#include "Include\\ScalpingEA_v0.0.4.mqh"
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
    g_journal.Init("ScalpingEA");
    g_learning.Init("ScalpingEA");
    g_evolution.Init();
    g_optimizer.Init(10, false);
    g_reports.Init("ScalpingEA");
    g_dashboard.Init("ScalpingEA");
    g_newsManager.Init(30);
    g_newsManager.UpdateCalendar();
    g_indicators.Init(_Symbol, _Period);
    Print("[ML] ScalpingEA engine initialized");
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
    Print("[ML] ScalpingEA engine shutdown");
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
    ML_OnDeinit();
    IndicatorRelease(handleFastMA);
    IndicatorRelease(handleSlowMA);
    IndicatorRelease(handleRSI);
}

void OnTick()
{
    ML_OnTick();
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
