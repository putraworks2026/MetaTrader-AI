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

int OnInit()
{
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpSlippage);

    EventSetTimer(10); // Check every 10 seconds
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
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
