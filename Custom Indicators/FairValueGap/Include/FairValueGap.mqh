//+------------------------------------------------------------------+
//| FairValueGap.mqh — Include file for FairValueGap
//| MetaTrader AI — Function Library
//| Version: v0.0.2
//+------------------------------------------------------------------+
#ifndef __FAIRVALUEGAP_MQH__
#define __FAIRVALUEGAP_MQH__

//+------------------------------------------------------------------+
//|                                       FairValueGap.mq5          |
//|                              MetaTrader AI - Custom Indicators   |
//|          Ranks #4 — Detects 3-candle imbalance (FVG)             |
//+------------------------------------------------------------------+


struct FVGZone
{
    double   high;
    double   low;
    datetime time;
    bool     bullish;
    bool     filled;
};

FVGZone  g_fvgs[];
int      g_count = 0;
datetime g_lastBar = 0;


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

#endif // __FAIRVALUEGAP_MQH__
