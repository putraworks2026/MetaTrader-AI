//+------------------------------------------------------------------+
//| AutoSupportResistance.mqh — Include file for AutoSupportResistance
//| MetaTrader AI — Function Library
//| Version: v0.0.2
//+------------------------------------------------------------------+
#ifndef __AUTOSUPPORTRESISTANCE_MQH__
#define __AUTOSUPPORTRESISTANCE_MQH__

//+------------------------------------------------------------------+
//|                                AutoSupportResistance.mq5       |
//|                              MetaTrader AI - Custom Indicators   |
//|          Ranks #6 — Auto-draws S/R from swing points            |
//+------------------------------------------------------------------+


struct SRLevel
{
    double   price;
    int      touches;
    bool     is_resistance;
    datetime lastTouch;
    string   name;
};

SRLevel  g_levels[];
int      g_count = 0;
datetime g_lastBar = 0;


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

#endif // __AUTOSUPPORTRESISTANCE_MQH__
