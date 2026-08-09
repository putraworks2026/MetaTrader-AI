//+------------------------------------------------------------------+
//| FibonacciAutoDraw_v0.0.2.mq5 — Publish Entry Point
//| MetaTrader AI — Custom Indicators
//| Version: v0.0.2
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.01"
#property indicator_chart_window
#property indicator_plots 0

#include "Include/FibonacciAutoDraw.mqh"

input int      InpLookback       = 200;      // Bars to find swing
input int      InpSwingPeriod    = 5;        // Swing detection period
input color    InpFibColor       = clrGold;    // Fibonacci line color
input int      InpLineWidth       = 1;        // Line width
input bool     InpShowLevels      = true;     // Show all fib levels
input bool     InpShowExtensions  = true;     // Show extension levels
input bool     InpAlertOnLevel    = true;     // Alert when price hits fib level
input bool     InpExtendLines     = true;     // Extend lines to right
input string   InpCustomLevels    = "0,0.236,0.382,0.5,0.618,0.786,1.0"; // Fib levels
input string   InpExtLevels       = "1.272,1.414,1.618,2.0";            // Extension levels

int OnInit()
{
    ObjectsDeleteAll(0, "FIB_");

    // Parse custom levels
    string parts[];
    int n = StringSplit(InpCustomLevels, ',', parts);
    for(int i = 0; i < n; i++)
    {
        string s = parts[i];
        StringTrimLeft(s);
        StringTrimRight(s);
        ArrayResize(g_fibLevels, g_fibCount + 1);
        g_fibLevels[g_fibCount] = StringToDouble(s);
        g_fibCount++;
    }

    n = StringSplit(InpExtLevels, ',', parts);
    for(int i = 0; i < n; i++)
    {
        string s = parts[i];
        StringTrimLeft(s);
        StringTrimRight(s);
        ArrayResize(g_extLevels, g_extCount + 1);
        g_extLevels[g_extCount] = StringToDouble(s);
        g_extCount++;
    }

    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { ObjectsDeleteAll(0, "FIB_"); }

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
    if(time[rates_total-1] == g_lastBar && prev_calculated > 0) return(rates_total);
    g_lastBar = time[rates_total-1];

    // Find the most recent significant swing high and low
    int lookback = MathMin(InpLookback, rates_total);
    int startIdx = rates_total - lookback;

    g_swingHigh = 0;
    g_swingLow  = DBL_MAX;

    for(int i = startIdx + InpSwingPeriod; i < rates_total - InpSwingPeriod; i++)
    {
        bool isSwingHigh = true;
        bool isSwingLow  = true;

        for(int j = 1; j <= InpSwingPeriod; j++)
        {
            if(high[i] <= high[i-j] || high[i] <= high[i+j]) isSwingHigh = false;
            if(low[i]  >= low[i-j]  || low[i]  >= low[i+j])  isSwingLow  = false;
        }

        if(isSwingHigh && high[i] > g_swingHigh)
        {
            g_swingHigh     = high[i];
            g_swingHighTime = time[i];
        }
        if(isSwingLow && low[i] < g_swingLow)
        {
            g_swingLow      = low[i];
            g_swingLowTime = time[i];
        }
    }

    if(g_swingHigh == 0 || g_swingLow == DBL_MAX) return(rates_total);

    // Determine direction: if swing low is more recent → bullish, if swing high is more recent → bearish
    g_isBullish = (g_swingLowTime > g_swingHighTime);

    double range = g_swingHigh - g_swingLow;
    if(range <= 0) return(rates_total);

    DrawFib(time[rates_total - 1]);

    // Alerts
    if(InpAlertOnLevel)
    {
        static datetime lastAlert = 0;
        datetime now = time[rates_total - 1];
        if(now != lastAlert)
        {
            double price = close[rates_total - 1];
            // Check all levels
            for(int i = 0; i < g_fibCount; i++)
            {
                double levelPrice = g_isBullish ? g_swingLow + range * g_fibLevels[i]
                                                : g_swingHigh - range * g_fibLevels[i];
                if(MathAbs(price - levelPrice) < _Point * 20)
                {
                    Alert(StringFormat("Price at Fib %.1f%% (%.5f)", g_fibLevels[i] * 100, levelPrice));
                    lastAlert = now;
                    break;
                }
            }
        }
    }

    return(rates_total);
}

void DrawFib(datetime endTime)
{
    ObjectsDeleteAll(0, "FIB_");

    double range = g_swingHigh - g_swingLow;
    datetime startTime = MathMin(g_swingHighTime, g_swingLowTime);

    // Main fib levels
    for(int i = 0; i < g_fibCount; i++)
    {
        double levelPrice = g_isBullish ? g_swingLow + range * g_fibLevels[i]
                                        : g_swingHigh - range * g_fibLevels[i];

        string name = "FIB_" + DoubleToString(g_fibLevels[i], 3);
        ObjectCreate(0, name, OBJ_TREND, 0, startTime, levelPrice, endTime, levelPrice);
        ObjectSetInteger(0, name, OBJPROP_COLOR, InpFibColor);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, InpLineWidth);
        ObjectSetInteger(0, name, OBJPROP_STYLE, (g_fibLevels[i] == 0.5) ? STYLE_DOT : STYLE_SOLID);
        ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, InpExtendLines);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

        if(InpShowLevels)
        {
            string label = StringFormat("%.1f%%  %.5f", g_fibLevels[i] * 100, levelPrice);
            string lblName = "FIB_LBL_" + DoubleToString(g_fibLevels[i], 3);
            ObjectCreate(0, lblName, OBJ_TEXT, 0, startTime, levelPrice);
            ObjectSetString(0, lblName, OBJPROP_TEXT, label);
            ObjectSetInteger(0, lblName, OBJPROP_COLOR, InpFibColor);
            ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
            ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LEFT);
            ObjectSetInteger(0, lblName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, lblName, OBJPROP_HIDDEN, true);
        }
    }

    // Extension levels
    if(InpShowExtensions)
    {
        for(int i = 0; i < g_extCount; i++)
        {
            double levelPrice = g_isBullish ? g_swingLow + range * g_extLevels[i]
                                            : g_swingHigh - range * g_extLevels[i];

            string name = "FIB_EXT_" + DoubleToString(g_extLevels[i], 3);
            ObjectCreate(0, name, OBJ_TREND, 0, startTime, levelPrice, endTime, levelPrice);
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrMediumPurple);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, InpLineWidth);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, InpExtendLines);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

            string label = StringFormat("%.1f%%  %.5f", g_extLevels[i] * 100, levelPrice);
            string lblName = "FIB_EXT_LBL_" + DoubleToString(g_extLevels[i], 3);
            ObjectCreate(0, lblName, OBJ_TEXT, 0, startTime, levelPrice);
            ObjectSetString(0, lblName, OBJPROP_TEXT, label);
            ObjectSetInteger(0, lblName, OBJPROP_COLOR, clrMediumPurple);
            ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
            ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LEFT);
            ObjectSetInteger(0, lblName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, lblName, OBJPROP_HIDDEN, true);
        }
    }
}
