//+------------------------------------------------------------------+
//| VolumeProfile_v0.0.4.mq5 — Publish Entry Point
//| MetaTrader AI — Custom Indicators
//| Version: v0.0.4
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.03"
#property indicator_separate_window
#property indicator_plots 1
#property indicator_label1  "Volume Profile"
#property indicator_type1    DRAW_COLOR_HISTOGRAM
#property indicator_width1   2

#include "Include/VolumeProfile.mqh"
//--- ML Engine Includes (AIEA Architecture)
#include "Include\\Config.mqh"
#include "Include\\IndicatorEngine.mqh"
#include "Include\\RiskManager.mqh"
#include "Include\\TradingJournal.mqh"
#include "Include\\LearningEngine.mqh"
#include "Include\\PatternRecognition.mqh"
#include "Include\\StrategyEvolution.mqh"
#include "Include\\OptimizationEngine.mqh"
#include "Include\\ReportGenerator.mqh"
#include "Include\\Dashboard.mqh"
#include "Include\\NewsManager.mqh"

//--- ML Global Objects
CRiskManager         g_riskManager;
CTradingJournal      g_journal;
CLearningEngine      g_learning;
CPatternRecognition  g_patterns;
CStrategyEvolution   g_evolution;
COptimizationEngine  g_optimizer;
CReportGenerator     g_reports;
CDashboard           g_dashboard;
CNewsManager         g_newsManager;
CIndicatorEngine     g_indicators;





input int      InpLookback       = 500;       // Bars to analyze
input int      InpBins           = 50;        // Number of price bins (rows)
input bool     InpUseTickVolume  = true;      // Use tick volume (vs real volume)
input color    InpHighVolColor   = clrDodgerBlue; // High volume node color
input color    InpLowVolColor     = clrDimGray;    // Low volume node color
input color    InpPOCColor        = clrRed;        // Point of Control color
input bool     InpShowPOC        = true;      // Highlight Point of Control
input bool     InpShowValueArea   = true;     // Highlight Value Area (70%)
input double   InpValueAreaPct    = 70.0;     // Value Area percentage
input bool     InpShowHVN         = true;     // Show High Volume Nodes
input bool     InpShowLVN         = true;     // Show Low Volume Nodes

int OnInit()
{
    SetIndexBuffer(0, BufferVolume, INDICATOR_DATA);
    SetIndexBuffer(1, BufferColor,  INDICATOR_COLOR_INDEX);

    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0);
    PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 0);

    ArrayInitialize(BufferVolume, 0.0);
    ArrayInitialize(BufferColor, 0.0);

    return(INIT_SUCCEEDED);
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
    if(rates_total < InpBins + 10) return(0);

    int lookback = MathMin(InpLookback, rates_total);
    int startIdx = rates_total - lookback;

    // Find price range
    double highest = high[startIdx];
    double lowest  = low[startIdx];
    for(int i = startIdx; i < rates_total; i++)
    {
        if(high[i] > highest) highest = high[i];
        if(low[i]  < lowest)  lowest  = low[i];
    }

    double binSize = (highest - lowest) / InpBins;
    if(binSize <= 0) return(rates_total);

    // Calculate volume per price bin
    double volBin[];
    ArrayResize(volBin, InpBins);
    ArrayInitialize(volBin, 0.0);

    double totalVolume = 0.0;
    for(int i = startIdx; i < rates_total; i++)
    {
        double v = InpUseTickVolume ? (double)tick_volume[i] : (double)volume[i];
        double barHigh = high[i];
        double barLow  = low[i];

        // Distribute volume across bins the bar spans
        int startBin = (int)((barLow - lowest) / binSize);
        int endBin   = (int)((barHigh - lowest) / binSize);
        startBin = MathMax(0, startBin);
        endBin   = MathMin(InpBins - 1, endBin);

        int span = endBin - startBin + 1;
        if(span > 0)
        {
            double volPerBin = v / span;
            for(int b = startBin; b <= endBin; b++)
            {
                volBin[b] += volPerBin;
            }
            totalVolume += v;
        }
    }

    // Find POC (Point of Control) — bin with highest volume
    double maxVol = 0;
    int    pocBin = 0;
    for(int b = 0; b < InpBins; b++)
    {
        if(volBin[b] > maxVol) { maxVol = volBin[b]; pocBin = b; }
    }
    g_pocPrice = lowest + (pocBin + 0.5) * binSize;

    // Calculate Value Area (70% of total volume around POC)
    if(InpShowValueArea)
    {
        double vaTarget = totalVolume * (InpValueAreaPct / 100.0);
        double vaVol = volBin[pocBin];
        int vaStart = pocBin;
        int vaEnd   = pocBin;

        while(vaVol < vaTarget && (vaStart > 0 || vaEnd < InpBins - 1))
        {
            double leftVol  = (vaStart > 0) ? volBin[vaStart - 1] : 0;
            double rightVol = (vaEnd < InpBins - 1) ? volBin[vaEnd + 1] : 0;

            if(leftVol >= rightVol && vaStart > 0)
            {
                vaVol += volBin[--vaStart];
            }
            else if(vaEnd < InpBins - 1)
            {
                vaVol += volBin[++vaEnd];
            }
            else break;
        }
        g_vaHigh = lowest + (vaEnd + 1) * binSize;
        g_vaLow  = lowest + vaStart * binSize;
    }

    // Map bins to indicator buffer (each bin = one bar in separate window)
    // We render the profile horizontally: price on Y, volume on X
    ArrayInitialize(BufferVolume, 0.0);
    ArrayInitialize(BufferColor, 0.0);

    for(int b = 0; b < InpBins && b < rates_total; b++)
    {
        double normalizedVol = (totalVolume > 0) ? (volBin[b] / maxVol) * 100.0 : 0.0;
        BufferVolume[b] = normalizedVol;

        // Color based on volume relative to POC
        if(b == pocBin && InpShowPOC)
            BufferColor[b] = 2; // POC color index
        else if(InpShowValueArea && b >= (int)((g_vaLow - lowest) / binSize) && b <= (int)((g_vaHigh - lowest) / binSize))
            BufferColor[b] = 0; // Value area (high vol) color
        else
            BufferColor[b] = 1; // Low vol color
    }

    // Draw POC and VA lines on chart
    if(InpShowPOC && g_pocPrice > 0)
    {
        string pocName = "VProfile_POC";
        if(ObjectFind(0, pocName) < 0)
            ObjectCreate(0, pocName, OBJ_HLINE, 0, 0, g_pocPrice);
        ObjectSetDouble(0, pocName, OBJPROP_PRICE, g_pocPrice);
        ObjectSetInteger(0, pocName, OBJPROP_COLOR, InpPOCColor);
        ObjectSetInteger(0, pocName, OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, pocName, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, pocName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, pocName, OBJPROP_HIDDEN, true);
        ObjectSetString(0, pocName, OBJPROP_TEXT, "POC");
    }

    if(InpShowValueArea && g_vaHigh > 0)
    {
        string vaH = "VProfile_VA_High";
        string vaL = "VProfile_VA_Low";
        for(int k = 0; k < 2; k++)
        {
            string name = (k == 0) ? vaH : vaL;
            double price = (k == 0) ? g_vaHigh : g_vaLow;
            if(ObjectFind(0, name) < 0)
                ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
            ObjectSetDouble(0, name, OBJPROP_PRICE, price);
            ObjectSetInteger(0, name, OBJPROP_COLOR, InpHighVolColor);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASHDOT);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        }
    }

    return(rates_total);
}
