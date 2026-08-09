//+------------------------------------------------------------------+
//| TrendStrengthMeter.mqh — Include file for TrendStrengthMeter
//| MetaTrader AI — Function Library
//| Version: v0.0.2
//+------------------------------------------------------------------+
#ifndef __TRENDSTRENGTHMETER_MQH__
#define __TRENDSTRENGTHMETER_MQH__

//+------------------------------------------------------------------+
//|                                  TrendStrengthMeter.mq5        |
//|                              MetaTrader AI - Custom Indicators   |
//|          Ranks #10 — Multi-timeframe ADX trend dashboard        |
//+------------------------------------------------------------------+


string   g_tfNames[];
ENUM_TIMEFRAMES g_tfs[];
int      g_tfCount = 0;
int      g_adxHandles[];
int      g_prevTrend[];  // -1=bear, 0=none, 1=bull
datetime g_lastBar = 0;


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

#endif // __TRENDSTRENGTHMETER_MQH__
