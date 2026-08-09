//+------------------------------------------------------------------+
//| SupplyDemandZones.mqh — Include file for SupplyDemandZones
//| MetaTrader AI — Function Library
//| Version: v0.0.3
//+------------------------------------------------------------------+
#ifndef __SUPPLYDEMANDZONES_MQH__
#define __SUPPLYDEMANDZONES_MQH__

//+------------------------------------------------------------------+
//|                                          SupplyDemandZones.mq5   |
//|                              MetaTrader AI - Custom Indicators   |
//|         Ranks #1 — Auto-draws institutional supply/demand zones   |
//+------------------------------------------------------------------+

//--- Input parameters

//--- Globals
struct SDZone
{
    double   high;
    double   low;
    datetime time_start;
    datetime time_end;
    bool     is_supply;  // true = supply (resistance), false = demand (support)
    bool     active;
    string   name;
};

SDZone   g_zones[];
int      g_zoneCount = 0;
datetime g_lastBarTime = 0;

//+------------------------------------------------------------------+

void CleanupObjects()
{
    ObjectsDeleteAll(0, "SDZ_");
}

void AddZone(SDZone &newZone)
{
    // Check for overlap with existing zones — merge if overlapping
    for(int z = 0; z < g_zoneCount; z++)
    {
        if(g_zones[z].is_supply == newZone.is_supply)
        {
            // Check overlap
            if(!(newZone.high < g_zones[z].low || newZone.low > g_zones[z].high))
            {
                // Merge
                g_zones[z].high = MathMax(g_zones[z].high, newZone.high);
                g_zones[z].low  = MathMin(g_zones[z].low,  newZone.low);
                g_zones[z].time_start = MathMin(g_zones[z].time_start, newZone.time_start);
                return;
            }
        }
    }

    // Add new zone if space available
    if(g_zoneCount < InpMaxZones)
    {
        g_zones[g_zoneCount] = newZone;
        g_zoneCount++;
    }
    else
    {
        // Replace oldest zone
        g_zones[0] = newZone;
    }
}

void DrawZones()
{
    for(int z = 0; z < g_zoneCount; z++)
    {
        string rectName = "SDZ_Rect_" + IntegerToString(z);
        string labelName = "SDZ_Label_" + IntegerToString(z);

        // Draw rectangle
        ObjectCreate(0, rectName, OBJ_RECTANGLE, 0,
                     g_zones[z].time_start, g_zones[z].high,
                     g_zones[z].time_end,   g_zones[z].low);

        color clr = g_zones[z].is_supply ? InpSupplyColor : InpDemandColor;

        ObjectSetInteger(0, rectName, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, rectName, OBJPROP_BACK, InpFillZones);
        ObjectSetInteger(0, rectName, OBJPROP_FILL, InpFillZones);
        ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, rectName, OBJPROP_HIDDEN, true);

        // Label
        if(InpShowLabels)
        {
            string label = g_zones[z].is_supply ? "SUPPLY" : "DEMAND";
            ObjectCreate(0, labelName, OBJ_TEXT, 0, g_zones[z].time_start, g_zones[z].high);
            ObjectSetString(0,  labelName, OBJPROP_TEXT, label);
            ObjectSetInteger(0, labelName, OBJPROP_COLOR, clr);
            ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
            ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, g_zones[z].is_supply ? ANCHOR_LOWER : ANCHOR_UPPER);
            ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
        }
    }
}

void CheckAlerts(double currentPrice, datetime currentTime)
{
    static datetime lastAlertTime = 0;
    if(currentTime == lastAlertTime) return;

    for(int z = 0; z < g_zoneCount; z++)
    {
        if(currentPrice >= g_zones[z].low && currentPrice <= g_zones[z].high)
        {
            string dir = g_zones[z].is_supply ? "SUPPLY" : "DEMAND";
            Alert(StringFormat("Price entered %s zone (%.5f - %.5f)", dir, g_zones[z].low, g_zones[z].high));
            lastAlertTime = currentTime;
            break;
        }
    }
}

#endif // __SUPPLYDEMANDZONES_MQH__
