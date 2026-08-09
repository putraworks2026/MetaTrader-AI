//+------------------------------------------------------------------+
//| LiquidityZones.mqh — Include file for LiquidityZones
//| MetaTrader AI — Function Library
//| Version: v0.0.3
//+------------------------------------------------------------------+
#ifndef __LIQUIDITYZONES_MQH__
#define __LIQUIDITYZONES_MQH__

//+------------------------------------------------------------------+
//|                                    LiquidityZones.mq5          |
//|                              MetaTrader AI - Custom Indicators   |
//|          Ranks #8 — Equal highs/lows = liquidity pools          |
//+------------------------------------------------------------------+


struct LiqZone
{
    double   price;
    int      count;      // Number of equal touches
    bool     is_high;    // true = equal highs (buy-side liquidity), false = equal lows (sell-side)
    datetime firstTouch;
    datetime lastTouch;
    bool     swept;      // Has this liquidity been taken?
};

LiqZone  g_zones[];
int      g_count = 0;
datetime g_lastBar = 0;


void ProcessLiquidity(double price, datetime t, bool isHigh, double tolerance)
{
    // Check if this matches an existing zone
    for(int z = 0; z < g_count; z++)
    {
        if(g_zones[z].is_high != isHigh) continue;
        if(MathAbs(price - g_zones[z].price) <= tolerance)
        {
            g_zones[z].count++;
            g_zones[z].lastTouch = t;
            return;
        }
    }

    // New zone
    if(g_count >= InpMaxZones)
    {
        // Replace zone with fewest touches
        int minIdx = 0;
        for(int z = 1; z < g_count; z++)
            if(g_zones[z].count < g_zones[minIdx].count) minIdx = z;
        g_zones[minIdx] = g_zones[g_count - 1];
        g_count--;
    }

    g_zones[g_count].price      = price;
    g_zones[g_count].count      = 1;
    g_zones[g_count].is_high    = isHigh;
    g_zones[g_count].firstTouch = t;
    g_zones[g_count].lastTouch  = t;
    g_zones[g_count].swept      = false;
    g_count++;
}

void DrawZones(datetime endTime)
{
    ObjectsDeleteAll(0, "LIQ_");

    for(int z = 0; z < g_count; z++)
    {
        if(g_zones[z].count < InpMinEqual) continue;

        string lineName = "LIQ_Line_" + IntegerToString(z);
        ObjectCreate(0, lineName, OBJ_TREND, 0,
                     g_zones[z].firstTouch, g_zones[z].price,
                     endTime, g_zones[z].price);

        color clr = g_zones[z].is_high ? InpLiqHighColor : InpLiqLowColor;
        if(g_zones[z].swept) clr = clrDimGray;

        ObjectSetInteger(0, lineName, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, lineName, OBJPROP_WIDTH, g_zones[z].swept ? 1 : 2);
        ObjectSetInteger(0, lineName, OBJPROP_STYLE, g_zones[z].swept ? STYLE_DOT : STYLE_SOLID);
        ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, true);
        ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, lineName, OBJPROP_HIDDEN, true);

        if(InpShowLabels)
        {
            string label = StringFormat("%s %d %s", g_zones[z].is_high ? "Buy-side" : "Sell-side",
                                       g_zones[z].count, g_zones[z].swept ? "(swept)" : "");
            string lblName = "LIQ_Lbl_" + IntegerToString(z);
            ObjectCreate(0, lblName, OBJ_TEXT, 0, g_zones[z].firstTouch, g_zones[z].price);
            ObjectSetString(0, lblName, OBJPROP_TEXT, label);
            ObjectSetInteger(0, lblName, OBJPROP_COLOR, clr);
            ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 7);
            ObjectSetInteger(0, lblName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, lblName, OBJPROP_HIDDEN, true);
        }
    }
}

#endif // __LIQUIDITYZONES_MQH__
