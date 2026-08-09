//+------------------------------------------------------------------+
//| DeleteAllPending_v0.0.3.mq5 — Publish Entry Point
//| MetaTrader AI — Scripts
//| Version: v0.0.3
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.02"
#property script_show_inputs

#include "Include/DeleteAllPending.mqh"
//--- ML Engine Includes
#include "Include/ML_Config.mqh"
#include "Include/ML_Journal.mqh"

//--- ML Global Objects
CMLJournal         mlJournal;


input bool   InpDeleteBuy      = true;   // Delete buy orders
input bool   InpDeleteSell     = true;   // Delete sell orders
input bool   InpDeleteLimits   = true;   // Delete limit orders
input bool   InpDeleteStops    = true;   // Delete stop orders
input bool   InpConfirmDialog   = true;   // Show confirmation
input int    InpSlippage        = 30;     // Slippage

void OnStart()
{
    int total = OrdersTotal();

    if(total == 0)
    {
        Print("No pending orders to delete.");
        return;
    }

    if(InpConfirmDialog)
    {
        string msg = StringFormat("Delete all %d pending orders?", total);
        if(MessageBox(msg, "Delete All Pending", MB_YESNO | MB_ICONQUESTION) != IDYES)
        {
            Print("Cancelled by user.");
            return;
        }
    }

    CTrade trade;
    trade.SetDeviationInPoints(InpSlippage);

    int deleted = 0;
    int failed  = 0;

    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        ulong ticket = OrderGetTicket(i);
        if(ticket == 0) continue;

        ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
        string symbol = OrderGetString(ORDER_SYMBOL);

        // Filter by type
        bool shouldDelete = false;
        if(type == ORDER_TYPE_BUY_LIMIT  && InpDeleteBuy && InpDeleteLimits) shouldDelete = true;
        if(type == ORDER_TYPE_SELL_LIMIT && InpDeleteSell && InpDeleteLimits) shouldDelete = true;
        if(type == ORDER_TYPE_BUY_STOP   && InpDeleteBuy && InpDeleteStops)  shouldDelete = true;
        if(type == ORDER_TYPE_SELL_STOP  && InpDeleteSell && InpDeleteStops) shouldDelete = true;

        if(!shouldDelete) continue;

        if(trade.OrderDelete(ticket))
        {
            deleted++;
            PrintFormat("Deleted #%I64u %s %s", ticket, symbol, EnumToString(type));
        }
        else
        {
            failed++;
            PrintFormat("Failed to delete #%I64u: %s", ticket, trade.ResultRetcodeDescription());
        }
    }

    PrintFormat("Delete All Pending complete: %d deleted, %d failed", deleted, failed);
}
