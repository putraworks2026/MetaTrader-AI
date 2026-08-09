//+------------------------------------------------------------------+
//| SetBreakevenAll_v0.0.4.mq5 — Publish Entry Point
//| MetaTrader AI — Scripts
//| Version: v0.0.4
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.03"
#property script_show_inputs

#include "Include/SetBreakevenAll_v0.0.4.mqh"
//--- ML Engine Includes (Tool-Specific)
#include "Include\\ExecConfig_v0.0.4.mqh"
#include "Include\\ExecJournal_v0.0.4.mqh"

//--- ML Global Objects (Script)
CExecJournal         g_execJournal;








input bool     InpOnlyProfitable  = true;    // Only modify profitable positions
input double   InpMinProfit       = 0.0;     // Minimum profit to qualify
input double   InpLockProfit      = 0.0;     // Lock this amount of profit (0 = exact BE)
input int      InpDeviation        = 30;      // Slippage in points
input bool     InpConfirmDialog    = true;    // Show confirmation


//==================================================================
//  ML EXECUTION TRACKING
//==================================================================

void ML_Init()
{
    g_execJournal.Init("SetBreakevenAll");
    Print("[ML] SetBreakevenAll execution tracking initialized");
}

void ML_LogExecution(ENUM_EXEC_RESULT result, int itemsProcessed, string details)
{
    ExecEntry ee; InitExecEntry(ee);
    ee.id = g_execJournal.GetNextId();
    ee.execTime = TimeCurrent();
    ee.result = result;
    ee.itemsProcessed = itemsProcessed;
    ee.details = details;
    MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
    ee.weekday = dt.day_of_week;
    ee.hour = dt.hour;
    g_execJournal.WriteEntry(ee);
}

void ML_OnDeinit()
{
    Print("[ML] SetBreakevenAll execution tracking shutdown");
}

void OnStart()
{
    ML_Init();
    int total = PositionsTotal();

    if(total == 0)
    {
        Print("No open positions.");
        return;
    }

    if(InpConfirmDialog)
    {
        if(MessageBox(StringFormat("Set breakeven on %d positions?", total),
                       "Set Breakeven", MB_YESNO | MB_ICONQUESTION) != IDYES)
        {
            Print("Cancelled.");
            return;
        }
    }

    CTrade trade;
    trade.SetDeviationInPoints(InpDeviation);

    int modified = 0;
    int failed   = 0;
    int skipped  = 0;

    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;

        string symbol = PositionGetString(POSITION_SYMBOL);
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentSL = PositionGetDouble(POSITION_SL);
        double currentTP = PositionGetDouble(POSITION_TP);
        double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        long   type = PositionGetInteger(POSITION_TYPE);
        double bid  = SymbolInfoDouble(symbol, SYMBOL_BID);
        double ask  = SymbolInfoDouble(symbol, SYMBOL_ASK);

        if(InpOnlyProfitable && profit < InpMinProfit)
        {
            skipped++;
            continue;
        }

        // Calculate breakeven price (including commission if available)
        double bePrice = openPrice;

        // Adjust for lock profit
        if(InpLockProfit != 0.0)
        {
            double volume = PositionGetDouble(POSITION_VOLUME);
            double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
            double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);

            if(tickValue > 0 && tickSize > 0 && volume > 0)
            {
                double priceAdjust = (InpLockProfit / volume) * (tickSize / tickValue);
                if(type == POSITION_TYPE_BUY)
                    bePrice = openPrice + priceAdjust;
                else
                    bePrice = openPrice - priceAdjust;
            }
        }

        // Normalize to symbol digits
        bePrice = NormalizeDouble(bePrice, _Digits);

        // Check if SL is already at or better than BE
        if(type == POSITION_TYPE_BUY)
        {
            if(currentSL >= bePrice)
            {
                skipped++;
                continue;
            }
        }
        else
        {
            if(currentSL > 0 && currentSL <= bePrice)
            {
                skipped++;
                continue;
            }
        }

        // Modify SL
        if(trade.PositionModify(ticket, bePrice, currentTP))
        {
            modified++;
            PrintFormat("BE set: #%I64u %s SL → %.5f (profit: %.2f)", ticket, symbol, bePrice, profit);
        }
        else
        {
            failed++;
            PrintFormat("Failed: #%I64u — %s", ticket, trade.ResultRetcodeDescription());
        }
    }

    PrintFormat("Breakeven complete: %d modified, %d skipped, %d failed", modified, skipped, failed);
}
    ML_OnDeinit();
}
