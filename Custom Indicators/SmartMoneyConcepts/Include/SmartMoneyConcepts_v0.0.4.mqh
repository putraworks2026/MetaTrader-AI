//+------------------------------------------------------------------+
//| SmartMoneyConcepts.mqh — Include file for SmartMoneyConcepts
//| MetaTrader AI — Function Library
//| Version: v0.0.3
//+------------------------------------------------------------------+
#ifndef __SMARTMONEYCONCEPTS_MQH__
#define __SMARTMONEYCONCEPTS_MQH__

//+------------------------------------------------------------------+
//|                                    SmartMoneyConcepts.mq5        |
//|                              MetaTrader AI - Custom Indicators   |
//|          Ranks #3 — SMC: BOS/CHoCH + Order Blocks + FVG          |
//+------------------------------------------------------------------+

//--- Input parameters

//--- Structures
struct Swing
{
    double   price;
    datetime time;
    bool     is_high;
};

struct FVG
{
    double   high;
    double   low;
    datetime time;
    bool     bullish;   // Bullish FVG = gap up (demand imbalance)
    bool     filled;
};

struct OB
{
    double   high;
    double   low;
    datetime time;
    bool     bullish;
    bool     mitigated;
};

//--- Globals
Swing   g_swingHighs[];
Swing   g_swingLows[];
int     g_swingHighCount = 0;
int     g_swingLowCount  = 0;
FVG     g_fvgs[];
int     g_fvgCount = 0;
OB      g_obs[];
int     g_obCount = 0;
int      g_lastTrend = 0;  // 1=bullish, -1=bearish, 0=undefined
datetime g_lastBarTime = 0;

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

#endif // __SMARTMONEYCONCEPTS_MQH__
