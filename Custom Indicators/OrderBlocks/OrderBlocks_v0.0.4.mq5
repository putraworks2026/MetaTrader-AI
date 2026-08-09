//+------------------------------------------------------------------+
//| OrderBlocks_v0.0.4.mq5 — Publish Entry Point
//| MetaTrader AI — Custom Indicators
//| Version: v0.0.4
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.03"
#property indicator_chart_window
#property indicator_plots 0

#include "Include/OrderBlocks_v0.0.4.mqh"
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





input int      InpLookback        = 500;        // Bars to analyze
input int      InpMinImpulse      = 150;        // Min impulse size (points)
input color    InpBullOBColor     = clrDodgerBlue; // Bullish OB color
input color    InpBearOBColor     = clrCrimson;    // Bearish OB color
input bool     InpFill            = true;       // Fill OB rectangles
input bool     InpShowLabels      = true;       // Show OB labels
input bool     InpAlertOnTouch    = true;       // Alert when price touches OB
input int      InpMaxBlocks       = 15;         // Max blocks to display
input bool     InpRemoveMitted    = true;       // Remove mitigated (tested) blocks

int OnInit()
{
    ArrayResize(g_blocks, InpMaxBlocks);
    g_blockCount = 0;
    ObjectsDeleteAll(0, "OB_");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { ObjectsDeleteAll(0, "OB_"); }

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
    if(rates_total < InpLookback + 5) return(0);
    if(time[rates_total - 1] == g_lastBarTime && prev_calculated > 0) return(rates_total);
    g_lastBarTime = time[rates_total - 1];

    int start = (prev_calculated == 0) ? rates_total - InpLookback : prev_calculated - 1;
    if(start < 3) start = 3;

    for(int i = start; i < rates_total - 2; i++)
    {
        // Detect impulse: strong move in one direction
        double impulseHigh = MathMax(high[i], high[i+1]);
        double impulseLow  = MathMin(low[i],  low[i+1]);
        double impulseSize = (impulseHigh - impulseLow) / _Point;

        if(impulseSize < InpMinImpulse) continue;

        bool bullishImpulse = close[i+1] > open[i+1] && close[i] > open[i];

        // Find the Order Block: last opposite-color candle before the impulse
        int obIndex = -1;
        for(int j = i; j >= MathMax(i - 5, 0); j--)
        {
            if(bullishImpulse && close[j] < open[j])  // Last bearish candle before bullish impulse
            {
                obIndex = j;
                break;
            }
            if(!bullishImpulse && close[j] > open[j])  // Last bullish candle before bearish impulse
            {
                obIndex = j;
                break;
            }
        }

        if(obIndex < 0) continue;

        // Check if this OB already exists
        bool exists = false;
        for(int b = 0; b < g_blockCount; b++)
        {
            if(g_blocks[b].time == time[obIndex]) { exists = true; break; }
        }
        if(exists) continue;

        // Create Order Block
        if(g_blockCount >= InpMaxBlocks)
        {
            // Shift array (remove oldest)
            for(int s = 0; s < g_blockCount - 1; s++) g_blocks[s] = g_blocks[s+1];
            g_blockCount--;
        }

        g_blocks[g_blockCount].high       = high[obIndex];
        g_blocks[g_blockCount].low        = low[obIndex];
        g_blocks[g_blockCount].time       = time[obIndex];
        g_blocks[g_blockCount].is_bullish = bullishImpulse;
        g_blocks[g_blockCount].mitigated   = false;
        g_blocks[g_blockCount].name       = StringFormat("OB_%d_%s", obIndex, bullishImpulse ? "BUL" : "BER");
        g_blockCount++;
    }

    // Check mitigation
    if(InpRemoveMitted)
    {
        double currentPrice = close[rates_total - 1];
        for(int b = 0; b < g_blockCount; b++)
        {
            if(!g_blocks[b].mitigated)
            {
                if(g_blocks[b].is_bullish && currentPrice < g_blocks[b].low)
                    g_blocks[b].mitigated = true;
                if(!g_blocks[b].is_bullish && currentPrice > g_blocks[b].high)
                    g_blocks[b].mitigated = true;
            }
        }
    }

    DrawBlocks(time[rates_total - 1]);

    // Alerts
    if(InpAlertOnTouch)
    {
        static datetime lastAlert = 0;
        datetime now = time[rates_total - 1];
        if(now != lastAlert)
        {
            double price = close[rates_total - 1];
            for(int b = 0; b < g_blockCount; b++)
            {
                if(g_blocks[b].mitigated) continue;
                if(price >= g_blocks[b].low && price <= g_blocks[b].high)
                {
                    string dir = g_blocks[b].is_bullish ? "BULLISH" : "BEARISH";
                    Alert(StringFormat("Price at %s Order Block (%.5f - %.5f)", dir, g_blocks[b].low, g_blocks[b].high));
                    lastAlert = now;
                    break;
                }
            }
        }
    }

    return(rates_total);
}

//+------------------------------------------------------------------+
void DrawBlocks(datetime endTime)
{
    ObjectsDeleteAll(0, "OB_");

    for(int b = 0; b < g_blockCount; b++)
    {
        if(g_blocks[b].mitigated && InpRemoveMitted) continue;

        string rectName = "OB_Rect_" + IntegerToString(b);
        string labelName = "OB_Label_" + IntegerToString(b);

        ObjectCreate(0, rectName, OBJ_RECTANGLE, 0,
                     g_blocks[b].time, g_blocks[b].high,
                     endTime, g_blocks[b].low);

        color clr = g_blocks[b].is_bullish ? InpBullOBColor : InpBearOBColor;
        ObjectSetInteger(0, rectName, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, rectName, OBJPROP_BACK, InpFill);
        ObjectSetInteger(0, rectName, OBJPROP_FILL, InpFill);
        ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, rectName, OBJPROP_HIDDEN, true);

        if(InpShowLabels)
        {
            string label = g_blocks[b].is_bullish ? "Bull OB" : "Bear OB";
            ObjectCreate(0, labelName, OBJ_TEXT, 0, g_blocks[b].time, g_blocks[b].high);
            ObjectSetString(0, labelName, OBJPROP_TEXT, label);
            ObjectSetInteger(0, labelName, OBJPROP_COLOR, clr);
            ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 7);
            ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
        }
    }
}
