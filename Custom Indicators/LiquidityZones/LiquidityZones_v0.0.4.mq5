//+------------------------------------------------------------------+
//| LiquidityZones_v0.0.4.mq5 — Publish Entry Point
//| MetaTrader AI — Custom Indicators
//| Version: v0.0.4
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.03"
#property indicator_chart_window
#property indicator_plots 0

#include "Include\\LiquidityZones_v0.0.4.mqh"
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








input int      InpLookback       = 500;      // Bars to analyze
input double   InpTolerancePips  = 5;        // Pip tolerance for "equal" levels
input int      InpMinEqual        = 2;        // Min equal points to mark liquidity
input color    InpLiqHighColor    = clrOrange;   // Liquidity above (equal highs)
input color    InpLiqLowColor     = clrDodgerBlue; // Liquidity below (equal lows)
input bool     InpShowLabels      = true;     // Show liquidity labels
input bool     InpAlertOnSweep    = true;     // Alert when liquidity is swept
input int      InpMaxZones        = 20;       // Max liquidity zones



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
    g_signalJournal.Init("LiquidityZones");
    g_signalLearning.Init("LiquidityZones");
    g_signalDashboard.Init("LiquidityZones");
    Print("[ML] LiquidityZones signal engine initialized");
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
    g_signalDashboard.Update("Liquidity Sweep", g_signalJournal.GetCount(), 0, 0, 0.0,
        g_signalLearning.GetTopInsight(), 0);
}

void ML_OnDeinit()
{
    g_signalLearning.SaveLessons();
    g_signalDashboard.Cleanup();
    Print("[ML] LiquidityZones signal engine shutdown");
}

int OnInit()
{
    ML_Init();
    ArrayResize(g_zones, InpMaxZones);
    g_count = 0;
    ObjectsDeleteAll(0, "LIQ_");
    return(INIT_SUCCEEDED;;
}

void OnDeinit(const int reason) {
    ML_OnDeinit(); ObjectsDeleteAll(0, "LIQ_"); }

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
    if(rates_total < 20) return(0);
    if(time[rates_total-1] == g_lastBar && prev_calculated > 0)     ML_SignalDashboardUpdate();
    return(rates_total);
    g_lastBar = time[rates_total-1];

    int start = (prev_calculated == 0) ? MathMax(rates_total - InpLookback, 3) : prev_calculated - 1;
    if(start < 3) start = 3;

    double tolerance = InpTolerancePips * _Point * 10;

    // Scan for swing highs and lows
    for(int i = start; i < rates_total - 3; i++)
    {
        // Simple swing detection: 3-bar fractal
        if(i < 1 || i >= rates_total - 1) continue;

        bool isSwingHigh = (high[i] > high[i-1] && high[i] > high[i+1]);
        bool isSwingLow  = (low[i]  < low[i-1]  && low[i]  < low[i+1]);

        if(isSwingHigh)
            ProcessLiquidity(high[i], time[i], true, tolerance);
        if(isSwingLow)
            ProcessLiquidity(low[i], time[i], false, tolerance);
    }

    // Check for sweeps
    double currentPrice = close[rates_total - 1];
    for(int z = 0; z < g_count; z++)
    {
        if(!g_zones[z].swept)
        {
            if(g_zones[z].is_high && currentPrice > g_zones[z].price + tolerance)
            {
                g_zones[z].swept = true;
                if(InpAlertOnSweep)
                    Alert(StringFormat("Buy-side liquidity SWEPT at %.5f (%d equal highs)", g_zones[z].price, g_zones[z].count));
            }
            if(!g_zones[z].is_high && currentPrice < g_zones[z].price - tolerance)
            {
                g_zones[z].swept = true;
                if(InpAlertOnSweep)
                    Alert(StringFormat("Sell-side liquidity SWEPT at %.5f (%d equal lows)", g_zones[z].price, g_zones[z].count));
            }
        }
    }

    DrawZones(time[rates_total - 1]);
    return(rates_total);
}


