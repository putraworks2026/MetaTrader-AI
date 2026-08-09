//+------------------------------------------------------------------+
//| Config_v0.0.4.mqh — ScalpingEA Configuration
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef SCALPINGEA_CONFIG_MQH
#define SCALPINGEA_CONFIG_MQH

enum ENUM_MARKET_REGIME { REGIME_UNKNOWN=0, REGIME_TRENDING=1, REGIME_RANGING=2, REGIME_VOLATILE=3 };
enum ENUM_TRADE_OUTCOME { OUTCOME_PENDING=0, OUTCOME_WIN=1, OUTCOME_LOSS=2, OUTCOME_BREAKEVEN=3 };
enum ENUM_PROFILE_STATUS { PROFILE_ACTIVE=0, PROFILE_PROMOTED=1, PROFILE_RETIRED=2, PROFILE_BACKUP=3 };

struct ParameterSet
{
   int id; string name;
   double   scalpTP;
   double   scalpSL;
   double   maxSpread;
   double   rsiPeriod;
   double riskPercent; double maxDailyLossPercent; double maxDrawdownPercent;
   int maxPositions; int maxSpreadPoints;
   int totalTrades; int wins; int losses; double totalProfit; double profitFactor; double score;
   ENUM_PROFILE_STATUS status; datetime created; datetime lastUpdated;
};

void CreateDefaultProfile(ParameterSet &ps, int id=1)
{
   ps.id=id; ps.name="Default"; ps.scalpTP = 5;
   ps.scalpSL = 10;
   ps.maxSpread = 10;
   ps.rsiPeriod = 7;
   ps.riskPercent=1.0; ps.maxDailyLossPercent=5.0; ps.maxDrawdownPercent=20.0;
   ps.maxPositions=3; ps.maxSpreadPoints=30;
   ps.totalTrades=0; ps.wins=0; ps.losses=0; ps.totalProfit=0.0;
   ps.profitFactor=0.0; ps.score=50.0; ps.status=PROFILE_ACTIVE;
   ps.created=TimeCurrent(); ps.lastUpdated=TimeCurrent();
}

void UpdateProfileScore(ParameterSet &ps)
{
   if(ps.totalTrades<3) return;
   double wr=(double)ps.wins/ps.totalTrades;
   ps.profitFactor=(ps.losses>0)?(double)ps.wins/ps.losses:99.0;
   ps.score=(wr*60.0)+(ps.profitFactor>1.0?20.0:0.0)+(ps.totalProfit>0?10.0:0.0);
   ps.score=MathMin(100.0,MathMax(0.0,ps.score)); ps.lastUpdated=TimeCurrent();
}

void CloneProfile(const ParameterSet &src, ParameterSet &dst, int newId, string newName)
{
   dst=src; dst.id=newId; dst.name=newName;
   dst.totalTrades=0; dst.wins=0; dst.losses=0; dst.totalProfit=0.0;
   dst.profitFactor=0.0; dst.score=50.0; dst.status=PROFILE_ACTIVE;
   dst.created=TimeCurrent(); dst.lastUpdated=TimeCurrent();
}

#endif // SCALPINGEA_CONFIG_MQH
