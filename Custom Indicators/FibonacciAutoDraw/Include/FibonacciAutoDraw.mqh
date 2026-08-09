//+------------------------------------------------------------------+
//| FibonacciAutoDraw.mqh — Include file for FibonacciAutoDraw
//| MetaTrader AI — Function Library
//| Version: v0.0.2
//+------------------------------------------------------------------+
#ifndef __FIBONACCIAUTODRAW_MQH__
#define __FIBONACCIAUTODRAW_MQH__

//+------------------------------------------------------------------+
//|                                   FibonacciAutoDraw.mq5        |
//|                              MetaTrader AI - Custom Indicators   |
//|          Ranks #9 — Auto-draws Fib from recent swing            |
//+------------------------------------------------------------------+


double   g_fibLevels[];
double   g_extLevels[];
int      g_fibCount = 0;
int      g_extCount = 0;
datetime g_lastBar  = 0;

// Current swing info
double   g_swingHigh = 0;
double   g_swingLow  = 0;
datetime g_swingHighTime = 0;
datetime g_swingLowTime  = 0;
bool     g_isBullish = true;


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

#endif // __FIBONACCIAUTODRAW_MQH__
