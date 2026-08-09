//+------------------------------------------------------------------+
//| SmartMoneyConcepts_v0.0.3.mq5 — Publish Entry Point
//| MetaTrader AI — Custom Indicators
//| Version: v0.0.3
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.02"
#property indicator_chart_window
#property indicator_plots 0

#include "Include/SmartMoneyConcepts.mqh"
//--- ML Engine Includes
#include "Include/ML_Config.mqh"
#include "Include/ML_Patterns.mqh"
#include "Include/ML_Dashboard.mqh"

//--- ML Global Objects
CMLPatternRecognition mlPatterns;
CMLDashboard        mlDashboard;


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

int OnInit()
{
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

void OnDeinit(const int reason) { ObjectsDeleteAll(0, "SMC_"); }

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
    if(time[rates_total - 1] == g_lastBarTime && prev_calculated > 0) return(rates_total);
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
void DetectStructure(const datetime &time[], const double &close[], int rates_total)
{
    // Need at least 2 swing highs and 2 swing lows
    if(g_swingHighCount < 2 || g_swingLowCount < 2) return;

    // Compare last two swing highs
    int hi = g_swingHighCount - 1;
    int li = g_swingLowCount - 1;

    // BOS: price breaks above previous swing high (bullish BOS) or below previous swing low (bearish BOS)
    if(hi >= 1)
    {
        if(close[rates_total - 1] > g_swingHighs[hi-1].price && g_lastTrend != 1)
        {
            // Check if this is BOS (continuation) or CHoCH (reversal)
            bool isCHoCH = (g_lastTrend == -1);

            if(InpShowBOS)
            {
                string name = "SMC_BOS_" + IntegerToString(g_swingHighs[hi-1].time);
                ObjectCreate(0, name, OBJ_HLINE, 0, g_swingHighs[hi-1].time, g_swingHighs[hi-1].price);
                ObjectSetInteger(0, name, OBJPROP_COLOR, isCHoCH ? InpCHoCHColor : InpBOSColor);
                ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
                ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
                ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

                string label = isCHoCH ? "CHoCH (Bullish)" : "BOS (Bullish)";
                string labelName = "SMC_BOSLabel_" + IntegerToString(g_swingHighs[hi-1].time);
                ObjectCreate(0, labelName, OBJ_TEXT, 0, g_swingHighs[hi-1].time, g_swingHighs[hi-1].price);
                ObjectSetString(0, labelName, OBJPROP_TEXT, label);
                ObjectSetInteger(0, labelName, OBJPROP_COLOR, isCHoCH ? InpCHoCHColor : InpBOSColor);
                ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
                ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
            }

            g_lastTrend = 1;

            if(InpAlerts)
                Alert(isCHoCH ? "CHoCH: Bullish reversal detected!" : "BOS: Bullish structure confirmed!");
        }
    }

    if(li >= 1)
    {
        if(close[rates_total - 1] < g_swingLows[li-1].price && g_lastTrend != -1)
        {
            bool isCHoCH = (g_lastTrend == 1);

            if(InpShowBOS)
            {
                string name = "SMC_BOS_" + IntegerToString(g_swingLows[li-1].time);
                ObjectCreate(0, name, OBJ_HLINE, 0, g_swingLows[li-1].time, g_swingLows[li-1].price);
                ObjectSetInteger(0, name, OBJPROP_COLOR, isCHoCH ? InpCHoCHColor : InpBOSColor);
                ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
                ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
                ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

                string label = isCHoCH ? "CHoCH (Bearish)" : "BOS (Bearish)";
                string labelName = "SMC_BOSLabel_" + IntegerToString(g_swingLows[li-1].time);
                ObjectCreate(0, labelName, OBJ_TEXT, 0, g_swingLows[li-1].time, g_swingLows[li-1].price);
                ObjectSetString(0, labelName, OBJPROP_TEXT, label);
                ObjectSetInteger(0, labelName, OBJPROP_COLOR, isCHoCH ? InpCHoCHColor : InpBOSColor);
                ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
                ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
            }

            g_lastTrend = -1;

            if(InpAlerts)
                Alert(isCHoCH ? "CHoCH: Bearish reversal detected!" : "BOS: Bearish structure confirmed!");
        }
    }
}

//+------------------------------------------------------------------+
void DetectOrderBlocks(const double &open[], const double &high[], const double &low[],
                       const double &close[], const datetime &time[], int rates_total, int begin)
{
    if(!InpShowOB) return;

    for(int i = begin; i < rates_total - 2; i++)
    {
        double impulse = MathAbs(close[i+1] - open[i+1]) / _Point;
        if(impulse < 100) continue;

        bool bullish = close[i+1] > open[i+1];
        int obIdx = -1;
        for(int j = i; j >= MathMax(i - 3, 0); j--)
        {
            if(bullish && close[j] < open[j]) { obIdx = j; break; }
            if(!bullish && close[j] > open[j]) { obIdx = j; break; }
        }
        if(obIdx < 0) continue;

        bool exists = false;
        for(int b = 0; b < g_obCount; b++)
        {
            if(g_obs[b].time == time[obIdx]) { exists = true; break; }
        }
        if(exists) continue;

        if(g_obCount >= InpMaxOB)
        {
            for(int s = 0; s < g_obCount - 1; s++) g_obs[s] = g_obs[s+1];
            g_obCount--;
        }

        g_obs[g_obCount].high      = high[obIdx];
        g_obs[g_obCount].low       = low[obIdx];
        g_obs[g_obCount].time      = time[obIdx];
        g_obs[g_obCount].bullish   = bullish;
        g_obs[g_obCount].mitigated  = false;
        g_obCount++;
    }
}

//+------------------------------------------------------------------+
void DrawAll(datetime endTime)
{
    // Draw FVGs
    if(InpShowFVG)
    {
        for(int f = 0; f < g_fvgCount; f++)
        {
            if(g_fvgs[f].filled) continue;

            string name = "SMC_FVG_" + IntegerToString(f);
            ObjectCreate(0, name, OBJ_RECTANGLE, 0,
                         g_fvgs[f].time, g_fvgs[f].high,
                         endTime, g_fvgs[f].low);
            ObjectSetInteger(0, name, OBJPROP_COLOR, InpFVGColor);
            ObjectSetInteger(0, name, OBJPROP_BACK, true);
            ObjectSetInteger(0, name, OBJPROP_FILL, true);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 0);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        }
    }

    // Draw Order Blocks
    if(InpShowOB)
    {
        for(int b = 0; b < g_obCount; b++)
        {
            if(g_obs[b].mitigated) continue;

            string name = "SMC_OB_" + IntegerToString(b);
            ObjectCreate(0, name, OBJ_RECTANGLE, 0,
                         g_obs[b].time, g_obs[b].high,
                         endTime, g_obs[b].low);
            ObjectSetInteger(0, name, OBJPROP_COLOR, g_obs[b].bullish ? InpBullOBColor : InpBearOBColor);
            ObjectSetInteger(0, name, OBJPROP_BACK, true);
            ObjectSetInteger(0, name, OBJPROP_FILL, true);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 0);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        }
    }
}
