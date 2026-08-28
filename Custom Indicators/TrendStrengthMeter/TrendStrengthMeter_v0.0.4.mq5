//+------------------------------------------------------------------+
//| TrendStrengthMeter_v0.0.4.mq5 — Publish Entry Point
//| MetaTrader AI — Custom Indicators
//| Version: v0.0.4
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.03"
#property indicator_chart_window
#property indicator_plots 0

#include "Include\\TrendStrengthMeter_v0.0.4.mqh"
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








input int      InpADXPeriod      = 14;       // ADX period
input double   InpTrendThreshold  = 25.0;     // ADX threshold for strong trend
input double   InpWeakThreshold   = 20.0;     // ADX threshold for weak trend
input color    InpStrongBullColor = clrLimeGreen;
input color    InpStrongBearColor = clrCrimson;
input color    InpWeakBullColor   = clrPaleGreen;
input color    InpWeakBearColor   = clrRosyBrown;
input color    InpNoTrendColor    = clrGray;
input color    InpBgColor         = clrBlack;
input color    InpTextColor       = clrWhite;
input int      InpXOffset         = 10;       // Dashboard X offset (pixels)
input int      InpYOffset         = 30;       // Dashboard Y offset (pixels)
input bool     InpAlertOnFlip     = true;     // Alert when trend flips
input string   InpTimeframes      = "M5,M15,M30,H1,H4,D1,W1"; // Timeframes to show



datetime g_lastSignalDash = 0;

void ML_SignalDashboardUpdate()
{
    if(TimeCurrent() - g_lastSignalDash >= 30)
    {
        ML_UpdateDashboard();
        g_lastSignalDash = TimeCurrent();
    }
}

//==================================================================
//  ML SIGNAL ENGINE INTEGRATION
//==================================================================

void ML_Init()
{
    g_signalJournal.Init("TrendStrengthMeter");
    g_signalLearning.Init("TrendStrengthMeter");
    g_signalDashboard.Init("TrendStrengthMeter");
    Print("[ML] TrendStrengthMeter signal engine initialized");
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
    g_signalDashboard.Update("ADX Trend Strength", g_signalJournal.GetCount(), 0, 0, 0.0,
        g_signalLearning.GetTopInsight(), 0);
}

void ML_OnDeinit()
{
    g_signalLearning.SaveLessons();
    g_signalDashboard.Cleanup();
    Print("[ML] TrendStrengthMeter signal engine shutdown");
}

int OnInit()
{
    ML_Init();
    // Parse timeframes
    string parts[];
    int n = StringSplit(InpTimeframes, ',', parts);
    g_tfCount = 0;
    ArrayResize(g_tfNames, n);
    ArrayResize(g_tfs, n);
    ArrayResize(g_adxHandles, n);
    ArrayResize(g_prevTrend, n);

    for(int i = 0; i < n; i++)
    {
        string tf = parts[i];
        StringTrimLeft(tf);
        StringTrimRight(tf);
        g_tfNames[g_tfCount] = tf;
        g_tfs[g_tfCount]     = StringToTimeframe(tf);
        g_adxHandles[g_tfCount] = iADX(_Symbol, g_tfs[g_tfCount], InpADXPeriod);
        g_prevTrend[g_tfCount] = 0;
        if(g_adxHandles[g_tfCount] == INVALID_HANDLE)
        {
            Print("Failed to create ADX handle for ", tf);
            return(INIT_FAILED);
        }
        g_tfCount++;
    }

    ObjectsDeleteAll(0, "TSM_");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    ML_OnDeinit();
    for(int i = 0; i < g_tfCount; i++)
        if(g_adxHandles[i] != INVALID_HANDLE) IndicatorRelease(g_adxHandles[i]);
    ObjectsDeleteAll(0, "TSM_");
}

ENUM_TIMEFRAMES StringToTimeframe(string tf)
{
    if(tf == "M1")  return PERIOD_M1;
    if(tf == "M5")  return PERIOD_M5;
    if(tf == "M15") return PERIOD_M15;
    if(tf == "M30") return PERIOD_M30;
    if(tf == "H1")  return PERIOD_H1;
    if(tf == "H4")  return PERIOD_H4;
    if(tf == "D1")  return PERIOD_D1;
    if(tf == "W1")  return PERIOD_W1;
    if(tf == "MN1") return PERIOD_MN1;
    return PERIOD_CURRENT;
}

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

    // Update every 30 seconds to reduce load
    static datetime lastUpdate = 0;
    if(TimeCurrent() - lastUpdate < 30 && prev_calculated > 0)     ML_SignalDashboardUpdate();
    return(rates_total);
    lastUpdate = TimeCurrent();

    // Dashboard header
    int x = InpXOffset;
    int y = InpYOffset;

    // Background
    string bgName = "TSM_BG";
    ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, x - 5);
    ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, y - 5);
    ObjectSetInteger(0, bgName, OBJPROP_XSIZE, 200);
    ObjectSetInteger(0, bgName, OBJPROP_YSIZE, 24 + g_tfCount * 22);
    ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, InpBgColor);
    ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, bgName, OBJPROP_COLOR, clrDimGray);
    ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bgName, OBJPROP_HIDDEN, true);

    // Title
    string title = "Trend Strength Meter";
    ObjectCreate(0, "TSM_Title", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "TSM_Title", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, "TSM_Title", OBJPROP_YDISTANCE, y);
    ObjectSetString(0,  "TSM_Title", OBJPROP_TEXT, title);
    ObjectSetString(0,  "TSM_Title", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, "TSM_Title", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, "TSM_Title", OBJPROP_COLOR, InpTextColor);
    ObjectSetInteger(0, "TSM_Title", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, "TSM_Title", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, "TSM_Title", OBJPROP_HIDDEN, true);

    // ADX column header
    ObjectCreate(0, "TSM_ADX_Hdr", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "TSM_ADX_Hdr", OBJPROP_XDISTANCE, x + 130);
    ObjectSetInteger(0, "TSM_ADX_Hdr", OBJPROP_YDISTANCE, y);
    ObjectSetString(0,  "TSM_ADX_Hdr", OBJPROP_TEXT, "ADX");
    ObjectSetString(0,  "TSM_ADX_Hdr", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, "TSM_ADX_Hdr", OBJPROP_FONTSIZE, 8);
    ObjectSetInteger(0, "TSM_ADX_Hdr", OBJPROP_COLOR, InpTextColor);
    ObjectSetInteger(0, "TSM_ADX_Hdr", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, "TSM_ADX_Hdr", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, "TSM_ADX_Hdr", OBJPROP_HIDDEN, true);

    // Get ADX values for each timeframe
    for(int i = 0; i < g_tfCount; i++)
    {
        double adxBuffer[];
        ArraySetAsSeries(adxBuffer, true);

        if(CopyBuffer(g_adxHandles[i], 0, 0, 3, adxBuffer) < 3) continue;

        double adx = adxBuffer[0];
        // Get +DI and -DI for direction
        double plusDI[];
        double minusDI[];
        ArraySetAsSeries(plusDI, true);
        ArraySetAsSeries(minusDI, true);

        CopyBuffer(g_adxHandles[i], 1, 0, 3, plusDI);
        CopyBuffer(g_adxHandles[i], 2, 0, 3, minusDI);

        bool isBull = (plusDI[0] > minusDI[0]);
        int trend = isBull ? 1 : -1;

        // Determine color
        color clr;
        string trendText;

        if(adx >= InpTrendThreshold)
        {
            clr = isBull ? InpStrongBullColor : InpStrongBearColor;
            trendText = isBull ? "STRONG BULL" : "STRONG BEAR";
        }
        else if(adx >= InpWeakThreshold)
        {
            clr = isBull ? InpWeakBullColor : InpWeakBearColor;
            trendText = isBull ? "Bullish" : "Bearish";
        }
        else
        {
            clr = InpNoTrendColor;
            trendText = "Ranging";
            trend = 0;
        }

        // Alert on trend flip
        if(InpAlertOnFlip && g_prevTrend[i] != 0 && trend != 0 && g_prevTrend[i] != trend)
        {
            Alert(StringFormat("%s trend flip: %s → %s (ADX: %.1f)",
                  g_tfNames[i],
                  g_prevTrend[i] == 1 ? "Bullish" : "Bearish",
                  trend == 1 ? "Bullish" : "Bearish",
                  adx));
        }
        g_prevTrend[i] = trend;

        int rowY = y + 22 + i * 22;

        // TF name
        string tfLbl = "TSM_TF_" + IntegerToString(i);
        ObjectCreate(0, tfLbl, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, tfLbl, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, tfLbl, OBJPROP_YDISTANCE, rowY);
        ObjectSetString(0,  tfLbl, OBJPROP_TEXT, g_tfNames[i]);
        ObjectSetString(0,  tfLbl, OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, tfLbl, OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, tfLbl, OBJPROP_COLOR, InpTextColor);
        ObjectSetInteger(0, tfLbl, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, tfLbl, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, tfLbl, OBJPROP_HIDDEN, true);

        // Trend text
        string trLbl = "TSM_Trend_" + IntegerToString(i);
        ObjectCreate(0, trLbl, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, trLbl, OBJPROP_XDISTANCE, x + 40);
        ObjectSetInteger(0, trLbl, OBJPROP_YDISTANCE, rowY);
        ObjectSetString(0,  trLbl, OBJPROP_TEXT, trendText);
        ObjectSetString(0,  trLbl, OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, trLbl, OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, trLbl, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, trLbl, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, trLbl, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, trLbl, OBJPROP_HIDDEN, true);

        // ADX value
        string adxLbl = "TSM_ADX_" + IntegerToString(i);
        ObjectCreate(0, adxLbl, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, adxLbl, OBJPROP_XDISTANCE, x + 130);
        ObjectSetInteger(0, adxLbl, OBJPROP_YDISTANCE, rowY);
        ObjectSetString(0,  adxLbl, OBJPROP_TEXT, DoubleToString(adx, 1));
        ObjectSetString(0,  adxLbl, OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, adxLbl, OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, adxLbl, OBJPROP_COLOR, InpTextColor);
        ObjectSetInteger(0, adxLbl, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, adxLbl, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, adxLbl, OBJPROP_HIDDEN, true);
    }

    return(rates_total);
}
