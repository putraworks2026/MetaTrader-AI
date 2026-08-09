//+------------------------------------------------------------------+
//| OptimizationEngine_v0.0.4.mqh — ScalpingEA Adaptive Optimization
//| Copyright 2026, PutraWorks
//| Optimizable: scalpTP, scalpSL, maxSpread, rsiPeriod
//+------------------------------------------------------------------+
#ifndef SCALPINGEA_OPTIMIZATION_ENGINE_MQH
#define SCALPINGEA_OPTIMIZATION_ENGINE_MQH

#include "Config_v0.0.4.mqh"
#include "StrategyEvolution_v0.0.4.mqh"
#include "LearningEngine_v0.0.4.mqh"
#include "PatternRecognition_v0.0.4.mqh"
#include "TradingJournal_v0.0.4.mqh"

#define MAX_CHANGES 50

struct ProposedChange { int changeId; int profileId; string parameter; double oldValue; double newValue; string rationale; double expectedImprovement; int evidenceTrades; int approval; datetime proposed; };

class COptimizationEngine
{
private: ProposedChange m_c[MAX_CHANGES]; int m_count; int m_nextId; int m_minEvidence; bool m_auto;
public:
   void Init(int minEv=10, bool auto_=false) { m_count=0; m_nextId=1; m_minEvidence=minEv; m_auto=auto_; }
   void ProposeChange(int pid, string param, double oldV, double newV, string reason, double exp, int ev)
   { if(ev<m_minEvidence||m_count>=MAX_CHANGES) return; ProposedChange pc; pc.changeId=m_nextId++; pc.profileId=pid; pc.parameter=param; pc.oldValue=oldV; pc.newValue=newV; pc.rationale=reason; pc.expectedImprovement=exp; pc.evidenceTrades=ev; pc.approval=m_auto?2:1; pc.proposed=TimeCurrent(); m_c[m_count]=pc; m_count++; }
   void Approve(int id) { for(int i=0;i<m_count;i++) if(m_c[i].changeId==id) m_c[i].approval=2; }
   void Reject(int id) { for(int i=0;i<m_count;i++) if(m_c[i].changeId==id) m_c[i].approval=3; }
   int GetPendingCount() { int c=0; for(int i=0;i<m_count;i++) if(m_c[i].approval==1) c++; return c; }
   string GetPendingSummary() { string s=""; for(int i=0;i<m_count;i++) if(m_c[i].approval==1) s+=StringFormat("#%d: %s %.2f->%.2f (%s)\n",m_c[i].changeId,m_c[i].parameter,m_c[i].oldValue,m_c[i].newValue,m_c[i].rationale); if(s=="") s="No pending"; return s; }
   int GetChangeCount() { return m_count; }
};

#endif // SCALPINGEA_OPTIMIZATION_ENGINE_MQH
