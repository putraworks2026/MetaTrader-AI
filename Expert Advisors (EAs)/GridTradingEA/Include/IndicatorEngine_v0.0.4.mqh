//+------------------------------------------------------------------+
//| IndicatorEngine_v0.0.4.mqh — GridTradingEA Indicator Management
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef GRIDTRADINGEA_INDICATOR_ENGINE_MQH
#define GRIDTRADINGEA_INDICATOR_ENGINE_MQH

#include "Config_v0.0.4.mqh"

struct IndicatorSnapshot { double atr; double trend; double spread; ENUM_MARKET_REGIME regime; datetime timestamp; };

class CIndicatorEngine
{
private:
   string m_symbol; ENUM_TIMEFRAMES m_tf;
public:
   void Init(string s, ENUM_TIMEFRAMES t) { m_symbol=s; m_tf=t; }
   IndicatorSnapshot GetSnapshot() { IndicatorSnapshot snap; snap.atr=GetATR(14); snap.spread=(double)SymbolInfoInteger(m_symbol,SYMBOL_SPREAD); snap.regime=DetectRegime(); snap.timestamp=TimeCurrent(); return snap; }
   ENUM_MARKET_REGIME DetectRegime() { int h=iADX(m_symbol,m_tf,14); if(h==INVALID_HANDLE) return REGIME_UNKNOWN; double b[]; double a=0; if(CopyBuffer(h,0,0,1,b)>0) a=b[0]; IndicatorRelease(h); if(a>25) return REGIME_TRENDING; if(a<20) return REGIME_RANGING; return REGIME_VOLATILE; }
   double GetATR(int p=14) { int h=iATR(m_symbol,m_tf,p); if(h==INVALID_HANDLE) return 0; double b[]; double v=0; if(CopyBuffer(h,0,0,1,b)>0) v=b[0]; IndicatorRelease(h); return v; }
};

#endif // GRIDTRADINGEA_INDICATOR_ENGINE_MQH
