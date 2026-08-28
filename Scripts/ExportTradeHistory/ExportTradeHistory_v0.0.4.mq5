//+------------------------------------------------------------------+
//| ExportTradeHistory_v0.0.4.mq5 — Publish Entry Point
//| MetaTrader AI — Scripts
//| Version: v0.0.4
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.03"
#property script_show_inputs

#include "Include\\ExportTradeHistory_v0.0.4.mqh"
//--- ML Engine Includes (Tool-Specific)
#include "Include\\ExecConfig_v0.0.4.mqh"
#include "Include\\ExecJournal_v0.0.4.mqh"

//--- ML Global Objects (Script)
CExecJournal         g_execJournal;








input int      InpDays            = 30;      // Export last N days (0 = all)
input string   InpFileName        = "TradeHistory.csv"; // Output filename
input bool     InpIncludeOpen     = false;    // Include open positions
input bool     InpShowInFolder    = true;    // Open folder after export


//==================================================================
//  ML EXECUTION TRACKING
//==================================================================

void ML_Init()
{
    g_execJournal.Init("ExportTradeHistory");
    Print("[ML] ExportTradeHistory execution tracking initialized");
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
    Print("[ML] ExportTradeHistory execution tracking shutdown");
}

void OnStart()
{
    ML_Init();
    string filePath = "Files/" + InpFileName;
    int handle = FileOpen(filePath, FILE_WRITE | FILE_CSV | FILE_ANSI, ',');

    if(handle == INVALID_HANDLE)
    {
        Print("Error: Cannot create file ", filePath, " — error ", GetLastError());
        return;
    }

    // Write header
    FileWrite(handle,
        "Ticket", "Symbol", "Type", "Volume", "OpenTime", "CloseTime",
        "OpenPrice", "ClosePrice", "SL", "TP",
        "Profit", "Swap", "Commission", "NetProfit",
        "Duration(hours)", "Comment"
    );

    datetime fromDate = 0;
    if(InpDays > 0)
        fromDate = TimeCurrent() - InpDays * 86400;

    // Select history
    if(!HistorySelect(fromDate, TimeCurrent() + 86400))
    {
        Print("Error: Cannot select deal history");
        FileClose(handle);
        return;
    }

    int dealsTotal = HistoryDealsTotal();
    int exported = 0;

    // Group deals by position
    for(int i = 0; i < dealsTotal; i++)
    {
        ulong dealTicket = HistoryDealGetTicket(i);
        if(dealTicket == 0) continue;

        // We want closed positions: look for DEAL_ENTRY_OUT (closing deals)
        ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
        if(entry != DEAL_ENTRY_OUT) continue;

        ulong  posTicket  = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
        string symbol     = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
        double volume     = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
        double closePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
        datetime closeTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
        double profit     = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        double swap        = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
        double commission  = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
        string comment     = HistoryDealGetString(dealTicket, DEAL_COMMENT);
        long   dealType    = HistoryDealGetInteger(dealTicket, DEAL_TYPE);

        // Find opening deal
        double openPrice = 0;
        datetime openTime = 0;
        double openVolume = 0;
        long   openType = -1;
        double sl = 0, tp = 0;

        for(int j = 0; j < dealsTotal; j++)
        {
            ulong dTicket = HistoryDealGetTicket(j);
            if(HistoryDealGetInteger(dTicket, DEAL_POSITION_ID) != (long)posTicket) continue;
            if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(dTicket, DEAL_ENTRY) == DEAL_ENTRY_IN)
            {
                openPrice  = HistoryDealGetDouble(dTicket, DEAL_PRICE);
                openTime   = (datetime)HistoryDealGetInteger(dTicket, DEAL_TIME);
                openVolume = HistoryDealGetDouble(dTicket, DEAL_VOLUME);
                openType   = HistoryDealGetInteger(dTicket, DEAL_TYPE);
                break;
            }
        }

        if(openPrice == 0) continue;

        double netProfit = profit + swap + commission;
        double durationHours = (closeTime - openTime) / 3600.0;
        string typeStr = (openType == DEAL_TYPE_BUY) ? "BUY" : (openType == DEAL_TYPE_SELL) ? "SELL" : "UNKNOWN";

        FileWrite(handle,
            posTicket, symbol, typeStr, DoubleToString(volume, 2),
            TimeToString(openTime, TIME_DATE|TIME_SECONDS),
            TimeToString(closeTime, TIME_DATE|TIME_SECONDS),
            DoubleToString(openPrice, _Digits),
            DoubleToString(closePrice, _Digits),
            DoubleToString(sl, _Digits),
            DoubleToString(tp, _Digits),
            DoubleToString(profit, 2),
            DoubleToString(swap, 2),
            DoubleToString(commission, 2),
            DoubleToString(netProfit, 2),
            DoubleToString(durationHours, 2),
            comment
        );
        exported++;
    }

    FileClose(handle);
    PrintFormat("Export complete: %d trades exported to %s", exported, filePath);

    if(InpShowInFolder)
    {
        ShellExecute("open", TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\", "", "", SW_SHOW);
    }
}
    ML_LogExecution(EXEC_SUCCESS, 0, "Export to CSV completed");
    ML_OnDeinit();
}
