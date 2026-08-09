//+------------------------------------------------------------------+
//| FairValueGap_v0.0.2.mq5 — Publish Entry Point
//| MetaTrader AI — Custom Indicators
//| Version: v0.0.2
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.01"
#property indicator_chart_window
#property indicator_plots 0

#include "Include/FairValueGap.mqh"

input int      InpLookback      = 500;        // Bars to analyze
input color    InpBullFVGColor  = clrSeaGreen;  // Bullish FVG color
input color    InpBearFVGColor  = clrCrimson;   // Bearish FVG color
input bool     InpFill          = true;       // Fill FVG rectangles
input bool     InpShowLabels    = true;       // Show FVG labels
input bool     InpAlertOnDetect  = true;       // Alert on new FVG
input bool     InpAlertOnFill    = true;       // Alert when FVG is filled
input int      InpMaxFVGs       = 30;         // Max FVGs to display
input bool     InpHideFilled     = false;      // Hide filled FVGs

int OnInit()
{
    ArrayResize(g_fvgs, InpMaxFVGs);
    g_count = 0;
    ObjectsDeleteAll(0, "FVG_");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { ObjectsDeleteAll(0, "FVG_"); }

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
    if(rates_total < 5) return(0);
    if(time[rates_total-1] == g_lastBar && prev_calculated > 0) return(rates_total);
    g_lastBar = time[rates_total-1];

    int start = (prev_calculated == 0) ? MathMax(rates_total - InpLookback, 3) : prev_calculated - 1;
    if(start < 3) start = 3;

    for(int i = start; i < rates_total - 2; i++)
    {
        // Bullish FVG: candle[i] high < candle[i+2] low → gap up
        if(high[i] < low[i+2])
        {
            if(!FVGExists(time[i]))
            {
                if(g_count >= InpMaxFVGs) { ShiftArray(); g_count--; }

                g_fvgs[g_count].high    = low[i+2];
                g_fvgs[g_count].low     = high[i];
                g_fvgs[g_count].time    = time[i];
                g_fvgs[g_count].bullish = true;
                g_fvgs[g_count].filled  = false;
                g_count++;

                if(InpAlertOnDetect)
                    Alert(StringFormat("Bullish FVG | %s | %.5f - %.5f",
                          TimeToString(time[i], TIME_DATE|TIME_MINUTES), high[i], low[i+2]));
            }
        }

        // Bearish FVG: candle[i] low > candle[i+2] high → gap down
        if(low[i] > high[i+2])
        {
            if(!FVGExists(time[i]))
            {
                if(g_count >= InpMaxFVGs) { ShiftArray(); g_count--; }

                g_fvgs[g_count].high    = low[i];
                g_fvgs[g_count].low     = high[i+2];
                g_fvgs[g_count].time    = time[i];
                g_fvgs[g_count].bullish = false;
                g_fvgs[g_count].filled  = false;
                g_count++;

                if(InpAlertOnDetect)
                    Alert(StringFormat("Bearish FVG | %s | %.5f - %.5f",
                          TimeToString(time[i], TIME_DATE|TIME_MINUTES), high[i+2], low[i]));
            }
        }
    }

    // Check if any FVGs got filled
    double price = close[rates_total - 1];
    for(int f = 0; f < g_count; f++)
    {
        if(!g_fvgs[f].filled)
        {
            if(g_fvgs[f].bullish && price <= g_fvgs[f].low)
            {
                g_fvgs[f].filled = true;
                if(InpAlertOnFill)
                    Alert(StringFormat("Bullish FVG filled at %.5f", price));
            }
            if(!g_fvgs[f].bullish && price >= g_fvgs[f].high)
            {
                g_fvgs[f].filled = true;
                if(InpAlertOnFill)
                    Alert(StringFormat("Bearish FVG filled at %.5f", price));
            }
        }
    }

    DrawFVGs(time[rates_total - 1]);
    return(rates_total);
}

bool FVGExists(datetime t)
{
    for(int f = 0; f < g_count; f++)
        if(g_fvgs[f].time == t) return(true);
    return(false);
}

void ShiftArray()
{
    for(int i = 0; i < g_count - 1; i++) g_fvgs[i] = g_fvgs[i+1];
}

void DrawFVGs(datetime endTime)
{
    ObjectsDeleteAll(0, "FVG_");

    for(int f = 0; f < g_count; f++)
    {
        if(g_fvgs[f].filled && InpHideFilled) continue;

        string rect = "FVG_R_" + IntegerToString(f);
        ObjectCreate(0, rect, OBJ_RECTANGLE, 0,
                     g_fvgs[f].time, g_fvgs[f].high,
                     endTime, g_fvgs[f].low);

        color clr = g_fvgs[f].bullish ? InpBullFVGColor : InpBearFVGColor;
        ObjectSetInteger(0, rect, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, rect, OBJPROP_BACK, InpFill);
        ObjectSetInteger(0, rect, OBJPROP_FILL, InpFill);
        ObjectSetInteger(0, rect, OBJPROP_WIDTH, 0);
        ObjectSetInteger(0, rect, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, rect, OBJPROP_HIDDEN, true);

        if(InpShowLabels)
        {
            string label = g_fvgs[f].bullish ? "Bull FVG" : "Bear FVG";
            if(g_fvgs[f].filled) label += " (filled)";
            string txt = "FVG_T_" + IntegerToString(f);
            ObjectCreate(0, txt, OBJ_TEXT, 0, g_fvgs[f].time, g_fvgs[f].high);
            ObjectSetString(0, txt, OBJPROP_TEXT, label);
            ObjectSetInteger(0, txt, OBJPROP_COLOR, clr);
            ObjectSetInteger(0, txt, OBJPROP_FONTSIZE, 7);
            ObjectSetInteger(0, txt, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, txt, OBJPROP_HIDDEN, true);
        }
    }
}
