//+------------------------------------------------------------------+
//| NewsTradingEA.mqh — Include file for NewsTradingEA
//| MetaTrader AI — Function Library
//| Version: v0.0.3
//+------------------------------------------------------------------+
#ifndef __NEWSTRADINGEA_MQH__
#define __NEWSTRADINGEA_MQH__

//+------------------------------------------------------------------+
//|                                            NewsTradingEA.mq5  |
//|                              MetaTrader AI - EAs                |
//|          #3 — Auto-trades high-impact news events                |
//+------------------------------------------------------------------+

#include <Trade/Trade.mqh>

//--- Inputs

//--- Globals
CTrade   trade;
bool     ordersPlaced = false;
datetime newsTime = 0;
string   pendingNewsName = "";
bool     hasPendingNews = false;
int      straddleBuyTicket = 0;
int      straddleSellTicket = 0;


datetime GetNextNewsEvent()
{
    // Use MT5 Calendar API
    MqlCalendarValue values[];
    datetime from = TimeCurrent();
    datetime to = from + 3600; // Next hour

    string countries[];
    int n = StringSplit(InpNewsCountries, ',', countries);

    // Get calendar events
    MqlCalendarEvent event;
    int total = CalendarValueHistory(values, from, to, NULL, NULL);

    for(int i = 0; i < ArraySize(values); i++)
    {
        ulong eventId = values[i].event_id;
        if(!CalendarEventById(eventId, event)) continue;

        // Check importance
        if(event.importance < InpMinImportance) continue;

        // Check country
        bool countryMatch = false;
        for(int c = 0; c < n; c++)
        {
            string country = countries[c];
            StringTrimLeft(country);
            StringTrimRight(country);
            if(event.country_id == country) { countryMatch = true; break; }
        }
        if(!countryMatch) continue;

        pendingNewsName = event.name;
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

#endif // __NEWSTRADINGEA_MQH__
