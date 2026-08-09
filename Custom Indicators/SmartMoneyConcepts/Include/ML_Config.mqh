//+------------------------------------------------------------------+
//| ML_Config.mqh — Machine Learning Configuration
//| Part of: SmartMoneyConcepts v0.0.3
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef __ML_CONFIG_SMARTMONEYCONCEPTS_MQH__
#define __ML_CONFIG_SMARTMONEYCONCEPTS_MQH__

//==================================================================
//  ML ENUMERATIONS
//==================================================================
enum ENUM_ML_REGIME
{
   ML_REGIME_UNKNOWN  = 0,
   ML_REGIME_TRENDING = 1,
   ML_REGIME_RANGING  = 2,
   ML_REGIME_VOLATILE = 3
};

enum ENUM_ML_OUTCOME
{
   ML_OUTCOME_PENDING   = 0,
   ML_OUTCOME_WIN       = 1,
   ML_OUTCOME_LOSS      = 2,
   ML_OUTCOME_BREAKEVEN = 3
};

enum ENUM_ML_PROFILE_STATUS
{
   ML_PROFILE_ACTIVE   = 0,
   ML_PROFILE_PROMOTED = 1,
   ML_PROFILE_RETIRED  = 2,
   ML_PROFILE_BACKUP   = 3
};

enum ENUM_ML_ENTRY_QUALITY
{
   ML_ENTRY_UNKNOWN  = 0,
   ML_ENTRY_OPTIMAL  = 1,
   ML_ENTRY_AVERAGE  = 2,
   ML_ENTRY_POOR     = 3
};

enum ENUM_ML_APPROVAL
{
   ML_APPROVAL_NONE    = 0,
   ML_APPROVAL_PENDING = 1,
   ML_APPROVAL_APPROVED= 2,
   ML_APPROVAL_REJECTED= 3
};

//==================================================================
//  ML PARAMETER SET — adaptive strategy profile
//==================================================================
struct ML_ParameterSet
{
   int      id;
   string   name;
   double   param1;        // Primary parameter (tool-specific)
   double   param2;        // Secondary parameter
   double   param3;        // Tertiary parameter
   double   riskPercent;
   double   minConfidence;
   double   maxSpreadPoints;
   int      maxPositions;
   double   maxDailyLossPercent;
   double   maxDrawdownPercent;
   // Performance tracking
   int      totalTrades;
   int      wins;
   int      losses;
   double   totalProfit;
   double   profitFactor;
   double   avgRiskReward;
   double   score;
   ENUM_ML_PROFILE_STATUS status;
   datetime created;
   datetime lastUpdated;
};

void ML_CreateDefaultProfile(ML_ParameterSet &ps, int id = 1)
{
   ps.id                  = id;
   ps.name                = "Default";
   ps.param1              = 0.0;
   ps.param2              = 0.0;
   ps.param3              = 0.0;
   ps.riskPercent         = 1.0;
   ps.minConfidence       = 50.0;
   ps.maxSpreadPoints     = 30.0;
   ps.maxPositions        = 3;
   ps.maxDailyLossPercent = 5.0;
   ps.maxDrawdownPercent  = 20.0;
   ps.totalTrades         = 0;
   ps.wins                = 0;
   ps.losses              = 0;
   ps.totalProfit         = 0.0;
   ps.profitFactor        = 0.0;
   ps.avgRiskReward       = 0.0;
   ps.score               = 50.0;
   ps.status              = ML_PROFILE_ACTIVE;
   ps.created             = TimeCurrent();
   ps.lastUpdated         = TimeCurrent();
}

void ML_CloneProfile(const ML_ParameterSet &src, ML_ParameterSet &dst, int newId, string newName)
{
   dst = src;
   dst.id          = newId;
   dst.name        = newName;
   dst.totalTrades = 0;
   dst.wins        = 0;
   dst.losses      = 0;
   dst.totalProfit = 0.0;
   dst.profitFactor = 0.0;
   dst.avgRiskReward = 0.0;
   dst.score       = 50.0;
   dst.status      = ML_PROFILE_ACTIVE;
   dst.created     = TimeCurrent();
   dst.lastUpdated = TimeCurrent();
}

void ML_UpdateProfileScore(ML_ParameterSet &ps)
{
   if(ps.totalTrades < 3) return;
   double winRate = (double)ps.wins / ps.totalTrades;
   double lossProfit = 0;
   if(ps.losses > 0) lossProfit = ps.totalProfit / (ps.losses + ps.wins);
   ps.profitFactor = (ps.losses > 0) ? (double)ps.wins / ps.losses : (ps.wins > 0 ? 99.0 : 0.0);
   ps.score = (winRate * 60.0) + (ps.profitFactor > 1.0 ? 20.0 : 0.0) + (ps.avgRiskReward * 10.0);
   ps.score = MathMin(100.0, MathMax(0.0, ps.score));
   ps.lastUpdated = TimeCurrent();
}

#endif // __ML_CONFIG_SMARTMONEYCONCEPTS_MQH__
