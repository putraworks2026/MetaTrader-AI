//+------------------------------------------------------------------+
//| CloseAllTrades_v0.0.2.mq5 — Publish Entry Point
//| MetaTrader AI — Scripts
//| Version: v0.0.2
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.01"
#property script_show_inputs

#include "Include/CloseAllTrades.mqh"

input bool   InpCloseProfitable = true;   // Close profitable trades
input bool   InpCloseLosing     = true;   // Close losing trades
input bool   InpConfirmDialog   = true;   // Show confirmation dialog
input int    InpSlippage         = 30;     // Slippage in points
input string InpComment          = "CloseAll"; // Comment for close operation

void OnStart()
{
    int total = PositionsTotal();

    if(total == 0)
    {
        Print("No open positions to close.");
        return;
    }

    if(InpConfirmDialog)
    {
        string msg = StringFormat("Close all %d positions?\nProfitable: %s\nLosing: %s",
                                   total, InpCloseProfitable ? "YES" : "NO", InpCloseLosing ? "YES" : "NO");
        if(MessageBox(msg, "Close All Trades", MB_YESNO | MB_ICONQUESTION) != IDYES)
        {
            Print("Cancelled by user.");
            return;
        }
    }

    CTrade trade;
    trade.SetDeviationInPoints(InpSlippage);

    int closed = 0;
    int failed = 0;
    double totalProfit = 0;

    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;

        double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

        bool shouldClose = false;
        if(profit >= 0 && InpCloseProfitable) shouldClose = true;
        if(profit < 0  && InpCloseLosing)     shouldClose = true;

        if(!shouldClose) continue;

        if(trade.PositionClose(ticket))
        {
            closed++;
            totalProfit += profit;
        }
        else
        {
            failed++;
            PrintFormat("Failed to close #%I64u: %s", ticket, trade.ResultRetcodeDescription());
        }
    }

    PrintFormat("Close All complete: %d closed, %d failed, P/L: %.2f", closed, failed, totalProfit);
}
