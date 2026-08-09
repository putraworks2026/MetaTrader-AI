//+------------------------------------------------------------------+
//| SessionsKillzones_v0.0.2.mq5 — Custom Indicator
//| Copyright 2026, PutraWorks
//| MQL5 Market Submission Build
//+------------------------------------------------------------------+
#property copyright "PutraWorks"
#property version   "1.01"
#property link       "https://www.mql5.com"
#property description "Sessions & Killzones — Displays London, New York, and Asian session boxes with ICT killzone highlighting."
#property description "Features: Automatic session time detection, ICT killzone overlays (London Open, NY Open, Asian session), customizable colors, and session start alerts."
#property description "Ideal for: ICT traders who need visual session timing and killzone awareness."
#property indicator_plots 0

#include "SessionsKillzones.mqh"

input bool     InpShowAsia      = true;       // Show Asian session
input int      InpAsiaStart     = 0;          // Asia start hour (broker time)
input int      InpAsiaEnd       = 7;          // Asia end hour (broker time)
input color    InpAsiaColor     = clrDarkSlateGray;
input bool     InpShowLondon    = true;       // Show London session
input int      InpLondonStart   = 7;          // London start hour
input int      InpLondonEnd     = 16;         // London end hour
input color    InpLondonColor   = clrDodgerBlue;
input bool     InpShowNY        = true;       // Show New York session
input int      InpNYStart       = 12;         // NY start hour
input int      InpNYEnd         = 20;         // NY end hour
input color    InpNYColor       = clrCrimson;
input bool     InpShowLondonKill = true;      // Show London Killzone
input int      InpLondonKillStart = 7;        // London Killzone start
input int      InpLondonKillEnd   = 10;       // London Killzone end
input color    InpLondonKillColor = clrMediumSlateBlue;
input bool     InpShowNYKill     = true;      // Show NY Killzone
input int      InpNYKillStart     = 12;        // NY Killzone start
input int      InpNYKillEnd       = 15;        // NY Killzone end
input color    InpNYKillColor    = clrOrangeRed;
input int      InpLookbackDays   = 5;         // Days to show
input bool     InpFillBoxes      = true;      // Fill session boxes
input int      InpTransparency   = 10;        // Box fill transparency
input bool     InpShowLabels     = true;      // Show session labels
input bool     InpAlertOnOpen   = true;       // Alert when session opens

int OnInit()
{
    ObjectsDeleteAll(0, "SES_");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { ObjectsDeleteAll(0, "SES_"); }

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
    if(rates_total < 50) return(0);

    // Only redraw on new bar
    static datetime lastBar = 0;
    if(time[rates_total-1] == lastBar && prev_calculated > 0) return(rates_total);
    lastBar = time[rates_total-1];

    ObjectsDeleteAll(0, "SES_");

    // Process each day in lookback range
    int daysProcessed = 0;
    int i = rates_total - 1;

    while(i >= 0 && daysProcessed < InpLookbackDays)
    {
        // Find the start and end of this day
        datetime dayStart = time[i];
        MqlDateTime dt;
        TimeToStruct(dayStart, dt);
        dt.hour = 0; dt.min = 0; dt.sec = 0;
        datetime dayBegin = StructToTime(dt);
        datetime dayEnd   = dayBegin + 86400;

        // Find the bar indexes for day boundaries
        int dayStartIdx = i;
        int dayEndIdx   = i;

        // Walk backward to find first bar of this day
        while(dayStartIdx > 0 && time[dayStartIdx-1] >= dayBegin) dayStartIdx--;

        // Find high and low for the day
        double dayHigh = 0;
        double dayLow  = DBL_MAX;
        for(int j = dayStartIdx; j <= dayEndIdx; j++)
        {
            if(high[j] > dayHigh) dayHigh = high[j];
            if(low[j]  < dayLow)  dayLow  = low[j];
        }

        if(dayHigh > 0 && dayLow < DBL_MAX)
        {
            string dayStr = TimeToString(dayBegin, TIME_DATE);

            // Draw session boxes
            if(InpShowAsia)     DrawSession("Asia",    dayStr, dayBegin, dayEnd, dayHigh, dayLow, InpAsiaStart,    InpAsiaEnd,    InpAsiaColor);
            if(InpShowLondon)   DrawSession("London",  dayStr, dayBegin, dayEnd, dayHigh, dayLow, InpLondonStart,  InpLondonEnd,  InpLondonColor);
            if(InpShowNY)      DrawSession("NY",      dayStr, dayBegin, dayEnd, dayHigh, dayLow, InpNYStart,      InpNYEnd,      InpNYColor);

            // Draw killzones
            if(InpShowLondonKill) DrawSession("LonKill", dayStr, dayBegin, dayEnd, dayHigh, dayLow, InpLondonKillStart, InpLondonKillEnd, InpLondonKillColor);
            if(InpShowNYKill)     DrawSession("NYKill",  dayStr, dayBegin, dayEnd, dayHigh, dayLow, InpNYKillStart,     InpNYKillEnd,     InpNYKillColor);
        }

        daysProcessed++;
        i = dayStartIdx - 1;
    }

    // Alert on session open
    if(InpAlertOnOpen)
    {
        MqlDateTime now;
        TimeToStruct(TimeCurrent(), now);
        static int lastAlertHour = -1;
        if(now.hour != lastAlertHour)
        {
            if(InpShowLondon && now.hour == InpLondonStart)
                Alert("London session OPEN");
            if(InpShowNY && now.hour == InpNYStart)
                Alert("New York session OPEN");
            if(InpShowAsia && now.hour == InpAsiaStart)
                Alert("Asian session OPEN");
            lastAlertHour = now.hour;
        }
    }

    return(rates_total);
}

void DrawSession(string prefix, string dayStr, datetime dayBegin, datetime dayEnd,
                 double dayHigh, double dayLow, int startHour, int endHour, color clr)
{
    datetime boxStart = dayBegin + startHour * 3600;
    datetime boxEnd   = dayBegin + endHour * 3600;
    if(boxEnd > dayEnd) boxEnd = dayEnd;

    string name = "SES_" + prefix + "_" + dayStr;

    ObjectCreate(0, name, OBJ_RECTANGLE, 0, boxStart, dayHigh, boxEnd, dayLow);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_BACK, InpFillBoxes);
    ObjectSetInteger(0, name, OBJPROP_FILL, InpFillBoxes);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

    if(InpShowLabels)
    {
        string lblName = "SES_LBL_" + prefix + "_" + dayStr;
        ObjectCreate(0, lblName, OBJ_TEXT, 0, boxStart, dayHigh);
        ObjectSetString(0, lblName, OBJPROP_TEXT, prefix);
        ObjectSetInteger(0, lblName, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 7);
        ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LEFT);
        ObjectSetInteger(0, lblName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, lblName, OBJPROP_HIDDEN, true);
    }
}
