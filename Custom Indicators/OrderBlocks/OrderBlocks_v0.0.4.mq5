//+------------------------------------------------------------------+
//| OrderBlocks_v0.0.4.mq5 — Publish Entry Point
//| MetaTrader AI — Custom Indicators
//| Version: v0.0.4
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.03"
#property indicator_chart_window
#property indicator_plots 0

#include "Include\\OrderBlocks_v0.0.4.mqh"
//--- ML Engine Includes (Tool-Specific)
#include "Include\\SignalConfig_v0.0.4.mqh"
#include "Include\\SignalJournal_v0.0.4.mqh"
#include "Include\\SignalLearning_v0.0.4.mqh"
#include "Include\\SignalPatterns_v0.0.4.mqh"
#include "Include\\SignalDashboard_v0.0.4.mqh"

//--- ML Global Objects (Indicator)
CSignalJournal       g_signalJournal;
CSignalLearning      g_signalLearning;
CSignalPatterns      g_signalPatterns;
CSignalDashboard     g_signalDashboard;








input int      InpLookback        = 500;        // Bars to analyze
input int      InpMinImpulse      = 150;        // Min impulse size (points)
input color    InpBullOBColor     = clrDodgerBlue; // Bullish OB color
input color    InpBearOBColor     = clrCrimson;    // Bearish OB color
input bool     InpFill            = true;       // Fill OB rectangles
input bool     InpShowLabels      = true;       // Show OB labels
input bool     InpAlertOnTouch    = true;       // Alert when price touches OB
input int      InpMaxBlocks       = 15;         // Max blocks to display
input bool     InpRemoveMitted    = true;       // Remove mitigated (tested) blocks



datetime g_lastSignalDash = 0;

void ML_SignalDashboardUpdate()
{
    if(TimeCurrent() - g_lastSignalDash >= 30)
    {
        ML_UpdateDashboard();
        g_lastSignalDash = TimeCurrent();
    }
}

//==================================================================
//  ML SIGNAL ENGINE INTEGRATION
//==================================================================

void ML_Init()
{
    g_signalJournal.Init("OrderBlocks");
    g_signalLearning.Init("OrderBlocks");
    g_signalDashboard.Init("OrderBlocks");
    Print("[ML] OrderBlocks signal engine initialized");
}

void ML_OnSignal(string signalType, double price, ENUM_SIGNAL_QUALITY quality, double confidence)
{
    SignalEntry se; InitSignalEntry(se);
    se.id = g_signalJournal.GetNextId();
    se.signalTime = TimeCurrent();
    se.signalPrice = price;
    se.signalType = signalType;
    se.quality = quality;
    se.confidence = confidence;
    MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
    se.weekday = dt.day_of_week;
    se.hour = dt.hour;
    se.session = (dt.hour >= 7 && dt.hour <= 12) ? "London" : (dt.hour >= 13 && dt.hour <= 17) ? "NewYork" : "Asia";
    g_signalJournal.WriteEntry(se);
}

void ML_UpdateDashboard()
{
    g_signalDashboard.Update("OB Mitigation", g_signalJournal.GetCount(), 0, 0, 0.0,
        g_signalLearning.GetTopInsight(), 0);
}

void ML_OnDeinit()
{
    g_signalLearning.SaveLessons();
    g_signalDashboard.Cleanup();
    Print("[ML] OrderBlocks signal engine shutdown");
}

int OnInit()
{
    ML_Init();
    ArrayResize(g_blocks, InpMaxBlocks);
    g_blockCount = 0;
    ObjectsDeleteAll(0, "OB_");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    ML_OnDeinit(); ObjectsDeleteAll(0, "OB_"); }

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    if(rates_total < InpLookback + 5) return(0);
    if(time[rates_total - 1] == g_lastBarTime && prev_calculated > 0)     ML_SignalDashboardUpdate();
    return(rates_total);
    g_lastBarTime = time[rates_total - 1];

    int start = (prev_calculated == 0) ? rates_total - InpLookback : prev_calculated - 1;
    if(start < 3) start = 3;

    for(int i = start; i < rates_total - 2; i++)
    {
        // Detect impulse: strong move in one direction
        double impulseHigh = MathMax(high[i], high[i+1]);
        double impulseLow  = MathMin(low[i],  low[i+1]);
        double impulseSize = (impulseHigh - impulseLow) / _Point;

        if(impulseSize < InpMinImpulse) continue;

        bool bullishImpulse = close[i+1] > open[i+1] && close[i] > open[i];

        // Find the Order Block: last opposite-color candle before the impulse
        int obIndex = -1;
        for(int j = i; j >= MathMax(i - 5, 0); j--)
        {
            if(bullishImpulse && close[j] < open[j])  // Last bearish candle before bullish impulse
            {
                obIndex = j;
                break;
            }
            if(!bullishImpulse && close[j] > open[j])  // Last bullish candle before bearish impulse
            {
                obIndex = j;
                break;
            }
        }

        if(obIndex < 0) continue;

        // Check if this OB already exists
        bool exists = false;
        for(int b = 0; b < g_blockCount; b++)
        {
            if(g_blocks[b].time == time[obIndex]) { exists = true; break; }
        }
        if(exists) continue;

        // Create Order Block
        if(g_blockCount >= InpMaxBlocks)
        {
            // Shift array (remove oldest)
            for(int s = 0; s < g_blockCount - 1; s++) g_blocks[s] = g_blocks[s+1];
            g_blockCount--;
        }

        g_blocks[g_blockCount].high       = high[obIndex];
        g_blocks[g_blockCount].low        = low[obIndex];
        g_blocks[g_blockCount].time       = time[obIndex];
        g_blocks[g_blockCount].is_bullish = bullishImpulse;
        g_blocks[g_blockCount].mitigated   = false;
        g_blocks[g_blockCount].name       = StringFormat("OB_%d_%s", obIndex, bullishImpulse ? "BUL" : "BER");
        g_blockCount++;
    }

    // Check mitigation
    if(InpRemoveMitted)
    {
        double currentPrice = close[rates_total - 1];
        for(int b = 0; b < g_blockCount; b++)
        {
            if(!g_blocks[b].mitigated)
            {
                if(g_blocks[b].is_bullish && currentPrice < g_blocks[b].low)
                    g_blocks[b].mitigated = true;
                if(!g_blocks[b].is_bullish && currentPrice > g_blocks[b].high)
                    g_blocks[b].mitigated = true;
            }
        }
    }

    DrawBlocks(time[rates_total - 1]);

    // Alerts
    if(InpAlertOnTouch)
    {
        static datetime lastAlert = 0;
        datetime now = time[rates_total - 1];
        if(now != lastAlert)
        {
            double price = close[rates_total - 1];
            for(int b = 0; b < g_blockCount; b++)
            {
                if(g_blocks[b].mitigated) continue;
                if(price >= g_blocks[b].low && price <= g_blocks[b].high)
                {
                    string dir = g_blocks[b].is_bullish ? "BULLISH" : "BEARISH";
                    Alert(StringFormat("Price at %s Order Block (%.5f - %.5f)", dir, g_blocks[b].low, g_blocks[b].high));
                    lastAlert = now;
                    break;
                }
            }
        }
    }

    return(rates_total);
}

//+------------------------------------------------------------------+
