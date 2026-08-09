//+------------------------------------------------------------------+
//| SignalConfig_v0.0.4.mqh — AutoSupportResistance Signal Configuration
//| Copyright 2026, PutraWorks
//| Signal Type: S/R Level Touch
//+------------------------------------------------------------------+
#ifndef AUTOSUPPORTRESISTANCE_SIGNAL_CONFIG_MQH
#define AUTOSUPPORTRESISTANCE_SIGNAL_CONFIG_MQH

enum ENUM_SIGNAL_QUALITY { SIGNAL_QUALITY_NONE=0, SIGNAL_QUALITY_LOW=1, SIGNAL_QUALITY_MED=2, SIGNAL_QUALITY_HIGH=3 };
enum ENUM_SIGNAL_OUTCOME { SIGNAL_PENDING=0, SIGNAL_SUCCESS=1, SIGNAL_FAILED=2, SIGNAL_NEUTRAL=3 };
enum ENUM_MARKET_REGIME { REGIME_UNKNOWN=0, REGIME_TRENDING=1, REGIME_RANGING=2, REGIME_VOLATILE=3 };

//--- AutoSupportResistance Signal Profile
struct SignalProfile
{
   int id; string name;
   double minConfidence; double sensitivity; double minScore;
   int totalSignals; int successes; int failures;
   double successRate; double score; datetime created;
};

void CreateDefaultSignalProfile(SignalProfile &sp, int id=1)
{
   sp.id=id; sp.name="Default"; sp.minConfidence=50.0; sp.sensitivity=1.0; sp.minScore=40.0;
   sp.totalSignals=0; sp.successes=0; sp.failures=0; sp.successRate=0.0; sp.score=50.0; sp.created=TimeCurrent();
}

void UpdateSignalProfileScore(SignalProfile &sp)
{
   if(sp.totalSignals<3) return;
   sp.successRate=(double)sp.successes/sp.totalSignals;
   sp.score=MathMin(100.0, MathMax(0.0, sp.successRate*100.0));
}

#endif // AUTOSUPPORTRESISTANCE_SIGNAL_CONFIG_MQH
