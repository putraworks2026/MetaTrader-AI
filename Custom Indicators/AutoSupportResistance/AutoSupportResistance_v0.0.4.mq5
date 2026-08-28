//+------------------------------------------------------------------+
//| AutoSupportResistance_v0.0.4.mq5 — Publish Entry Point
//| MetaTrader AI — Custom Indicators
//| Version: v0.0.4
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.03"
#property indicator_chart_window
#property indicator_plots 0

#include "Include\\AutoSupportResistance_v0.0.4.mqh"
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
input int      InpSwingPeriod    = 5;        // Fractal period (bars each side)
input int      InpMaxLevels      = 20;       // Max S/R levels
input int      InpMinTouches     = 2;        // Min touches to confirm level
input double   InpTolerancePips  = 10;       // Tolerance for level touches (pips)
input color    InpResistColor     = clrCrimson;  // Resistance color
input color    InpSupportColor    = clrSeaGreen; // Support color
input int      InpLineWidth       = 1;        // Line width
input ENUM_LINE_STYLE InpLineStyle = STYLE_SOLID; // Line style
input bool     InpShowLabels      = true;     // Show price labels
input bool     InpAlertOnTouch    = true;     // Alert when price touches S/R
input bool     InpExtendLines     = true;     // Extend to right



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
    g_signalJournal.Init("AutoSupportResistance");
    g_signalLearning.Init("AutoSupportResistance");
    g_signalDashboard.Init("AutoSupportResistance");
    Print("[ML] AutoSupportResistance signal engine initialized");
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
    g_signalDashboard.Update("S/R Level Touch", g_signalJournal.GetCount(), 0, 0, 0.0,
        g_signalLearning.GetTopInsight(), 0);
}

void ML_OnDeinit()
{
    g_signalLearning.SaveLessons();
    g_signalDashboard.Cleanup();
    Print("[ML] AutoSupportResistance signal engine shutdown");
}

int OnInit()
{
    ML_Init();
    ArrayResize(g_levels, InpMaxLevels);
    g_count = 0;
    ObjectsDeleteAll(0, "SR_");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    ML_OnDeinit(); ObjectsDeleteAll(0, "SR_"); }

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
    if(rates_total < InpSwingPeriod * 2 + 5) return(0);
    if(time[rates_total-1] == g_lastBar && prev_calculated > 0)     ML_SignalDashboardUpdate();
    return(rates_total);
    g_lastBar = time[rates_total-1];

    int start = (prev_calculated == 0) ? MathMax(rates_total - InpLookback, InpSwingPeriod + 1) : prev_calculated - 1;
    if(start < InpSwingPeriod + 1) start = InpSwingPeriod + 1;

    double tolerance = InpTolerancePips * _Point * 10;

    // Detect swing highs and lows
    for(int i = start; i < rates_total - InpSwingPeriod; i++)
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
            AddOrUpdateLevel(high[i], time[i], true, tolerance, rates_total, time, high, low);

        if(isSwingLow)
            AddOrUpdateLevel(low[i], time[i], false, tolerance, rates_total, time, high, low);
    }

    // Filter: only keep levels with enough touches
    // Draw
    DrawLevels(time[rates_total - 1]);

    // Alerts
    if(InpAlertOnTouch)
    {
        static datetime lastAlert = 0;
        datetime now = time[rates_total - 1];
        if(now != lastAlert)
        {
            double price = close[rates_total - 1];
            for(int l = 0; l < g_count; l++)
            {
                if(g_levels[l].touches < InpMinTouches) continue;
                if(MathAbs(price - g_levels[l].price) <= tolerance)
                {
                    string type = g_levels[l].is_resistance ? "RESISTANCE" : "SUPPORT";
                    Alert(StringFormat("Price at %s level: %.5f (%d touches)", type, g_levels[l].price, g_levels[l].touches));
                    lastAlert = now;
                    break;
                }
            }
        }
    }

    return(rates_total);
}

void AddOrUpdateLevel(double price, datetime t, bool isRes, double tolerance,
                      int rates_total, const datetime &time[], const double &high[], const double &low[])
{
    // Check if this price matches an existing level
    for(int l = 0; l < g_count; l++)
    {
        if(MathAbs(price - g_levels[l].price) <= tolerance)
        {
            g_levels[l].touches++;
            g_levels[l].lastTouch = t;
            return;
        }
    }

    // New level
    if(g_count >= InpMaxLevels)
    {
        // Remove level with fewest touches
        int minIdx = 0;
        for(int l = 1; l < g_count; l++)
            if(g_levels[l].touches < g_levels[minIdx].touches) minIdx = l;
        g_levels[minIdx] = g_levels[g_count - 1];
        g_count--;
    }

    g_levels[g_count].price         = price;
    g_levels[g_count].touches       = 1;
    g_levels[g_count].is_resistance = isRes;
    g_levels[g_count].lastTouch     = t;
    g_levels[g_count].name          = StringFormat("SR_%d", g_count);
    g_count++;
}

void DrawLevels(datetime endTime)
{
    ObjectsDeleteAll(0, "SR_");

    for(int l = 0; l < g_count; l++)
    {
        if(g_levels[l].touches < InpMinTouches) continue;

        string name = "SR_Line_" + IntegerToString(l);
        ObjectCreate(0, name, OBJ_TREND, 0,
                     g_levels[l].lastTouch, g_levels[l].price,
                     endTime, g_levels[l].price);

        color clr = g_levels[l].is_resistance ? InpResistColor : InpSupportColor;
        ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, InpLineWidth);
        ObjectSetInteger(0, name, OBJPROP_STYLE, InpLineStyle);
        ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, InpExtendLines);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

        if(InpShowLabels)
        {
            string label = StringFormat("%s %.5f x%d",
                g_levels[l].is_resistance ? "R" : "S",
                g_levels[l].price,
                g_levels[l].touches);
            string lblName = "SR_Label_" + IntegerToString(l);
            ObjectCreate(0, lblName, OBJ_TEXT, 0, g_levels[l].lastTouch, g_levels[l].price);
            ObjectSetString(0, lblName, OBJPROP_TEXT, label);
            ObjectSetInteger(0, lblName, OBJPROP_COLOR, clr);
            ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
            ObjectSetInteger(0, lblName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, lblName, OBJPROP_HIDDEN, true);
        }
    }
}
