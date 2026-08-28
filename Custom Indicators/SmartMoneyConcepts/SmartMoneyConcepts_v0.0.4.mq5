//+------------------------------------------------------------------+
//| SmartMoneyConcepts_v0.0.4.mq5 — Publish Entry Point
//| MetaTrader AI — Custom Indicators
//| Version: v0.0.4
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.03"
#property indicator_chart_window
#property indicator_plots 0

#include "Include\\SmartMoneyConcepts_v0.0.4.mqh"
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








input int      InpLookback        = 1000;       // Bars to analyze
input int      InpSwingPeriod     = 5;          // Swing detection period (fractal bars)
input color    InpBOSColor        = clrDodgerBlue;  // Break of Structure color
input color    InpCHoCHColor       = clrOrange;      // Change of Character color
input color    InpFVGColor         = clrMediumPurple; // Fair Value Gap color
input color    InpBullOBColor     = clrLimeGreen;    // Bullish OB color
input color    InpBearOBColor     = clrCrimson;      // Bearish OB color
input bool     InpShowBOS         = true;       // Show BOS/CHoCH lines
input bool     InpShowFVG         = true;       // Show Fair Value Gaps
input bool     InpShowOB          = true;       // Show Order Blocks
input bool     InpAlerts          = true;       // Enable all alerts
input int      InpMaxFVG          = 20;         // Max FVGs to track
input int      InpMaxOB           = 15;         // Max OBs to track



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
    g_signalJournal.Init("SmartMoneyConcepts");
    g_signalLearning.Init("SmartMoneyConcepts");
    g_signalDashboard.Init("SmartMoneyConcepts");
    Print("[ML] SmartMoneyConcepts signal engine initialized");
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
    g_signalDashboard.Update("BOS/CHoCH", g_signalJournal.GetCount(), 0, 0, 0.0,
        g_signalLearning.GetTopInsight(), 0);
}

void ML_OnDeinit()
{
    g_signalLearning.SaveLessons();
    g_signalDashboard.Cleanup();
    Print("[ML] SmartMoneyConcepts signal engine shutdown");
}

int OnInit()
{
    ML_Init();
    ArrayResize(g_swingHighs, 200);
    ArrayResize(g_swingLows, 200);
    ArrayResize(g_fvgs, InpMaxFVG);
    ArrayResize(g_obs, InpMaxOB);
    g_swingHighCount = 0;
    g_swingLowCount = 0;
    g_fvgCount = 0;
    g_obCount = 0;
    ObjectsDeleteAll(0, "SMC_");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    ML_OnDeinit(); ObjectsDeleteAll(0, "SMC_"); }

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
    if(rates_total < InpLookback + 10) return(0);
    if(time[rates_total - 1] == g_lastBarTime && prev_calculated > 0)     ML_SignalDashboardUpdate();
    return(rates_total);
    g_lastBarTime = time[rates_total - 1];

    int start = (prev_calculated == 0) ? InpSwingPeriod + 1 : prev_calculated - 1;
    int begin = MathMax(start, InpSwingPeriod + 1);
    if(begin < InpSwingPeriod + 1) begin = InpSwingPeriod + 1;

    // 1. Detect swing highs/lows (fractals)
    for(int i = begin; i < rates_total - InpSwingPeriod; i++)
    {
        bool isSwingHigh = true;
        bool isSwingLow  = true;

        for(int j = 1; j <= InpSwingPeriod; j++)
        {
            if(i - j < 0 || i + j >= rates_total) { isSwingHigh = false; isSwingLow = false; break; }
            if(high[i] <= high[i-j] || high[i] <= high[i+j]) isSwingHigh = false;
            if(low[i]  >= low[i-j]  || low[i]  >= low[i+j])  isSwingLow  = false;
        }

        if(isSwingHigh)
        {
            // Check not duplicate
            if(g_swingHighCount == 0 || g_swingHighs[g_swingHighCount-1].time != time[i])
            {
                if(g_swingHighCount < 200)
                {
                    g_swingHighs[g_swingHighCount].price = high[i];
                    g_swingHighs[g_swingHighCount].time  = time[i];
                    g_swingHighs[g_swingHighCount].is_high = true;
                    g_swingHighCount++;
                }
            }
        }

        if(isSwingLow)
        {
            if(g_swingLowCount == 0 || g_swingLows[g_swingLowCount-1].time != time[i])
            {
                if(g_swingLowCount < 200)
                {
                    g_swingLows[g_swingLowCount].price = low[i];
                    g_swingLows[g_swingLowCount].time  = time[i];
                    g_swingLows[g_swingLowCount].is_high = false;
                    g_swingLowCount++;
                }
            }
        }
    }

    // 2. Detect BOS / CHoCH
    DetectStructure(time, close, rates_total);

    // 3. Detect Fair Value Gaps
    for(int i = begin; i < rates_total - 2; i++)
    {
        // Bullish FVG: low[i+2] > high[i] (gap up)
        if(low[i+2] > high[i])
        {
            bool exists = false;
            for(int f = 0; f < g_fvgCount; f++)
            {
                if(g_fvgs[f].time == time[i]) { exists = true; break; }
            }
            if(!exists && g_fvgCount < InpMaxFVG)
            {
                g_fvgs[g_fvgCount].high    = low[i+2];
                g_fvgs[g_fvgCount].low     = high[i];
                g_fvgs[g_fvgCount].time    = time[i];
                g_fvgs[g_fvgCount].bullish = true;
                g_fvgs[g_fvgCount].filled  = false;
                g_fvgCount++;

                if(InpAlerts)
                    Alert(StringFormat("Bullish FVG detected at %s | Gap: %.5f - %.5f",
                          TimeToString(time[i], TIME_DATE|TIME_MINUTES), high[i], low[i+2]));
            }
        }
        // Bearish FVG: high[i+2] < low[i] (gap down)
        if(high[i+2] < low[i])
        {
            bool exists = false;
            for(int f = 0; f < g_fvgCount; f++)
            {
                if(g_fvgs[f].time == time[i]) { exists = true; break; }
            }
            if(!exists && g_fvgCount < InpMaxFVG)
            {
                g_fvgs[g_fvgCount].high    = low[i];
                g_fvgs[g_fvgCount].low     = high[i+2];
                g_fvgs[g_fvgCount].time    = time[i];
                g_fvgs[g_fvgCount].bullish = false;
                g_fvgs[g_fvgCount].filled  = false;
                g_fvgCount++;

                if(InpAlerts)
                    Alert(StringFormat("Bearish FVG detected at %s | Gap: %.5f - %.5f",
                          TimeToString(time[i], TIME_DATE|TIME_MINUTES), high[i+2], low[i]));
            }
        }
    }

    // Check FVG mitigation
    double currentPrice = close[rates_total - 1];
    for(int f = 0; f < g_fvgCount; f++)
    {
        if(!g_fvgs[f].filled)
        {
            if(g_fvgs[f].bullish && currentPrice < g_fvgs[f].low)
                g_fvgs[f].filled = true;
            if(!g_fvgs[f].bullish && currentPrice > g_fvgs[f].high)
                g_fvgs[f].filled = true;
        }
    }

    // 4. Detect Order Blocks
    DetectOrderBlocks(open, high, low, close, time, rates_total, begin);

    // 5. Draw everything
    DrawAll(time[rates_total - 1]);

    return(rates_total);
}

//+------------------------------------------------------------------+
