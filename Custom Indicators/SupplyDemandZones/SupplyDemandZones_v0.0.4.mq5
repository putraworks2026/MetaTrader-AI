//+------------------------------------------------------------------+
//| SupplyDemandZones_v0.0.4.mq5 — Publish Entry Point
//| MetaTrader AI — Custom Indicators
//| Version: v0.0.4
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.03"
#property indicator_chart_window
#property indicator_plots 0

#include "Include/SupplyDemandZones_v0.0.4.mqh"
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








input int      InpLookback        = 500;        // Bars to analyze
input int      InpMinImpulse      = 200;        // Min impulse size (points)
input int      InpMaxZoneBars     = 30;         // Max bars in a zone base
input color    InpSupplyColor     = clrCrimson;  // Supply zone color
input color    InpDemandColor     = clrSeaGreen; // Demand zone color
input bool     InpFillZones       = true;       // Fill zones with color
input int      InpTransparency    = 15;         // Fill transparency (0-100)
input bool     InpShowLabels      = true;      // Show zone labels
input bool     InpAlertOnTouch    = true;       // Alert on price touching zone
input int      InpMaxZones        = 10;         // Max zones to display


//==================================================================
//  ML SIGNAL ENGINE INTEGRATION
//==================================================================

void ML_Init()
{
    g_signalJournal.Init("SupplyDemandZones");
    g_signalLearning.Init("SupplyDemandZones");
    g_signalDashboard.Init("SupplyDemandZones");
    Print("[ML] SupplyDemandZones signal engine initialized");
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
    g_signalDashboard.Update("Zone Touch", g_signalJournal.GetCount(), 0, 0, 0.0,
        g_signalLearning.GetTopInsight(), 0);
}

void ML_OnDeinit()
{
    g_signalLearning.SaveLessons();
    g_signalDashboard.Cleanup();
    Print("[ML] SupplyDemandZones signal engine shutdown");
}

int OnInit()
{
    ML_Init();
    ArrayResize(g_zones, InpMaxZones);
    g_zoneCount = 0;
    CleanupObjects();
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    ML_OnDeinit();
    CleanupObjects();
}

void CleanupObjects()
{
    ObjectsDeleteAll(0, "SDZ_");
}

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

    int start = MathMax(prev_calculated == 0 ? rates_total - InpLookback : prev_calculated - 1, 10);
    if(start < 5) start = 5;

    // Scan for impulse moves and identify the base (consolidation) before them
    for(int i = start; i < rates_total - 3; i++)
    {
        // Look for a strong impulse candle
        double impulseSize = (high[i] - low[i]) / _Point;
        if(impulseSize < InpMinImpulse) continue;

        // Check if this is a breakout from a consolidation
        bool isBullishImpulse = close[i] > open[i];
        double baseHigh = 0, baseLow = 0;
        datetime baseStart = 0, baseEnd = 0;
        int baseBars = 0;

        // Walk backward to find the consolidation base
        for(int j = i - 1; j >= MathMax(i - InpMaxZoneBars, 0); j--)
        {
            double range = high[j] - low[j];
            double bodySize = MathAbs(open[j] - close[j]);

            // Consolidation candle: small body relative to range
            if(bodySize > range * 0.6) break; // Big body = not consolidation

            if(baseBars == 0)
            {
                baseHigh = high[j];
                baseLow  = low[j];
                baseStart = time[j];
            }
            else
            {
                baseHigh = MathMax(baseHigh, high[j]);
                baseLow  = MathMin(baseLow,  low[j]);
                baseStart = time[j];
            }
            baseBars++;
        }

        if(baseBars < 2) continue; // Need at least 2 consolidation candles

        // Create zone from the base
        SDZone zone;
        zone.high      = baseHigh;
        zone.low       = baseLow;
        zone.time_start = baseStart;
        zone.time_end  = time[rates_total - 1]; // Extend to current
        zone.is_supply = !isBullishImpulse;     // Bullish impulse → demand below, bearish → supply above
        zone.active    = true;
        zone.name      = StringFormat("SDZ_%d_%s", i, isBullishImpulse ? "DEM" : "SUP");

        AddZone(zone);
    }

    // Draw zones
    DrawZones();

    // Check for zone touches
    if(InpAlertOnTouch)
        CheckAlerts(close[rates_total - 1], time[rates_total - 1]);

    return(rates_total);
}

//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
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
