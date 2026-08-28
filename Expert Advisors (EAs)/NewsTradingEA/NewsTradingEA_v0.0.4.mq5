//+------------------------------------------------------------------+
//| NewsTradingEA_v0.0.4.mq5 — Expert Advisor
//| Copyright 2026, PutraWorks
//| MQL5 Market Submission Build + ML Engine
//+------------------------------------------------------------------+
#property copyright "PutraWorks"
#property version   "1.03"
#property link       "https://www.mql5.com"
#property description "News Trading EA — Automatically trades high-impact news events. Captures volatility spikes during economic releases."
#property description "Features: Economic calendar integration, configurable pre/post news trade windows, straddle order placement, volatility-based SL/TP, and news impact filtering."
#property description "Ideal for: News traders who want to automate event-driven volatility capture."
#property strict

#include "Include/NewsTradingEA_v0.0.4.mqh"
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








input double   InpLotSize          = 0.01;    // Lot size
input int      InpStopLoss         = 200;      // SL (points)
input int      InpTakeProfit       = 300;      // TP (points)
input int      InpStraddlePoints   = 100;      // Straddle distance (points)
input int      InpMinutesBefore    = 2;        // Minutes before news to place orders
input int      InpMinutesAfter     = 5;        // Minutes after news to cancel
input int      InpMaxSpread        = 50;       // Max spread (points)
input int      InpMagicNumber      = 100003;   // Magic number
input int      InpSlippage         = 50;       // Slippage
input string   InpNewsCountries    = "US,EU";  // Countries to watch (comma-separated)
input int      InpMinImportance    = 3;        // Min importance (1=low,2=med,3=high)
input bool     InpDeleteAfterFill  = true;     // Delete opposite order after fill
input bool     InpCloseEndOfDay    = true;     // Close all positions at end of day
input int      InpCloseHour        = 22;       // End of day close hour



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
    g_journal.Init("NewsTradingEA");
    g_learning.Init("NewsTradingEA");
    g_evolution.Init();
    g_optimizer.Init(10, false);
    g_reports.Init("NewsTradingEA");
    g_dashboard.Init("NewsTradingEA");
    g_newsManager.Init(30);
    g_newsManager.UpdateCalendar();
    g_indicators.Init(_Symbol, _Period);
    Print("[ML] NewsTradingEA engine initialized");
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
    Print("[ML] NewsTradingEA engine shutdown");
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

    EventSetTimer(10); // Check every 10 seconds
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    ML_OnDeinit();
    EventKillTimer();
}

void OnTimer()
{
    // Check for upcoming high-impact news
    if(!hasPendingNews)
    {
        datetime nextNews = GetNextNewsEvent();
        if(nextNews > 0)
        {
            newsTime = nextNews;
            hasPendingNews = true;
            PrintFormat("News event detected: %s at %s", pendingNewsName,
                        TimeToString(newsTime, TIME_DATE|TIME_MINUTES));
        }
    }

    // Place straddle orders X minutes before news
    if(hasPendingNews && !ordersPlaced)
    {
        int secondsToNews = (int)(newsTime - TimeCurrent());
        if(secondsToNews <= InpMinutesBefore * 60 && secondsToNews > 0)
        {
            PlaceStraddle();
            ordersPlaced = true;
            PrintFormat("Straddle placed %d min before news", InpMinutesBefore);
        }
    }

    // Cancel unfilled orders X minutes after news
    if(hasPendingNews && ordersPlaced)
    {
        int secondsAfterNews = (int)(TimeCurrent() - newsTime);
        if(secondsAfterNews > InpMinutesAfter * 60)
        {
            CancelPendingOrders();
            hasPendingNews = false;
            ordersPlaced = false;
        }
    }

    // End of day close
    if(InpCloseEndOfDay)
    {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        if(dt.hour >= InpCloseHour)
        {
            CloseAllPositions();
        }
    }
}

void OnTick()
{
    ML_OnTick();
    // Check if a straddle order was filled, then delete the opposite
    if(ordersPlaced && InpDeleteAfterFill)
    {
        CheckStraddleFill();
    }
}

datetime GetNextNewsEvent()
{
    // Use MT5 Calendar API
    MqlCalendarValue values[];
    datetime from = TimeCurrent();
    datetime to = from + 3600; // Next hour

    string countries[];
    int n = StringSplit(InpNewsCountries, ',', countries);

    // Get calendar events
    MqlCalendarEvent events[];
    int total = CalendarValueHistory(values, from, to, NULL, NULL);

    for(int i = 0; i < ArraySize(values); i++)
    {
        ulong eventId = values[i].event_id;
        if(!CalendarEventById(eventId, events)) continue;

        // Check importance
        if(events[0].importance < InpMinImportance) continue;

        // Check country
        bool countryMatch = false;
        for(int c = 0; c < n; c++)
        {
            string country = countries[c];
            StringTrimLeft(country);
            StringTrimRight(country);
            if(events[0].country_code == country) { countryMatch = true; break; }
        }
        if(!countryMatch) continue;

        pendingNewsName = events[0].name;
        return values[i].time;
    }

    return 0;
}

void PlaceStraddle()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = _Point;
    int digits = _Digits;

    double buyPrice  = NormalizeDouble(ask + InpStraddlePoints * point, digits);
    double sellPrice = NormalizeDouble(bid - InpStraddlePoints * point, digits);

    double buySL  = NormalizeDouble(buyPrice - InpStopLoss * point, digits);
    double buyTP  = NormalizeDouble(buyPrice + InpTakeProfit * point, digits);
    double sellSL = NormalizeDouble(sellPrice + InpStopLoss * point, digits);
    double sellTP = NormalizeDouble(sellPrice - InpTakeProfit * point, digits);

    if(trade.BuyStop(InpLotSize, buyPrice, _Symbol, buySL, buyTP, ORDER_TIME_GTC, 0, "NewsBuy"))
        PrintFormat("Straddle BuyStop @ %.5f", buyPrice);

    if(trade.SellStop(InpLotSize, sellPrice, _Symbol, sellSL, sellTP, ORDER_TIME_GTC, 0, "NewsSell"))
        PrintFormat("Straddle SellStop @ %.5f", sellPrice);
}

void CancelPendingOrders()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        ulong ticket = OrderGetTicket(i);
        if(ticket == 0) continue;
        if(OrderGetInteger(ORDER_MAGIC) != InpMagicNumber) continue;
        if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
        trade.OrderDelete(ticket);
        PrintFormat("Cancelled pending order #%I64u", ticket);
    }
}

void CheckStraddleFill()
{
    // Check if any pending orders became positions
    bool buyFilled = false, sellFilled = false;

    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;
        if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
        if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        string comment = PositionGetString(POSITION_COMMENT);
        if(StringFind(comment, "NewsBuy") >= 0) buyFilled = true;
        if(StringFind(comment, "NewsSell") >= 0) sellFilled = true;
    }

    if(buyFilled || sellFilled)
    {
        CancelPendingOrders(); // Delete the opposite side
    }
}

void CloseAllPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;
        if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
        if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        trade.PositionClose(ticket);
    }
}
