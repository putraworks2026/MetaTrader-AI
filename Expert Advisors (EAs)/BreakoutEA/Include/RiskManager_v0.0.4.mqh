//+------------------------------------------------------------------+
//| RiskManager_v0.0.4.mqh — BreakoutEA Risk Management
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef BREAKOUTEA_RISK_MANAGER_MQH
#define BREAKOUTEA_RISK_MANAGER_MQH

#include "Config_v0.0.4.mqh"

class CRiskManager
{
private:
   double m_dailyLoss, m_dailyProfit; int m_posToday; datetime m_lastReset;
public:
   void Init() { m_dailyLoss=0; m_dailyProfit=0; m_posToday=0; m_lastReset=TimeCurrent(); }
   double CalculateLotSize(double riskPct, double slPoints, string sym)
   {
      double bal=AccountInfoDouble(ACCOUNT_BALANCE); double risk=bal*riskPct/100.0;
      double tv=SymbolInfoDouble(sym,SYMBOL_TRADE_TICK_VALUE); double ts=SymbolInfoDouble(sym,SYMBOL_TRADE_TICK_SIZE);
      double pt=SymbolInfoDouble(sym,SYMBOL_POINT); if(ts==0||tv==0) return 0.01;
      double lot=risk/(slPoints*(tv/ts*pt));
      double mn=SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN); double mx=SymbolInfoDouble(sym,SYMBOL_VOLUME_MAX);
      double st=SymbolInfoDouble(sym,SYMBOL_VOLUME_STEP);
      lot=MathMax(mn,MathMin(mx,lot)); lot=MathFloor(lot/st)*st; return lot;
   }
   bool CanOpenPosition(const ParameterSet &p)
   {
      ResetDaily(); if(m_posToday>=p.maxPositions) return false;
      double bal=AccountInfoDouble(ACCOUNT_BALANCE); double eq=AccountInfoDouble(ACCOUNT_EQUITY);
      double dd=(bal-eq)/bal*100.0; if(dd>=p.maxDrawdownPercent) return false;
      if(m_dailyLoss<=-bal*p.maxDailyLossPercent/100.0) return false; return true;
   }
   void OnTradeClosed(double p) { if(p>0) m_dailyProfit+=p; else m_dailyLoss+=p; }
   void OnPositionOpened() { m_posToday++; }
   void ResetDaily() { MqlDateTime n,l; TimeToStruct(TimeCurrent(),n); TimeToStruct(m_lastReset,l); if(n.day!=l.day) { m_dailyLoss=0; m_dailyProfit=0; m_posToday=0; m_lastReset=TimeCurrent(); } }
   double GetDailyPnL() { return m_dailyProfit+m_dailyLoss; }
};

#endif // BREAKOUTEA_RISK_MANAGER_MQH
