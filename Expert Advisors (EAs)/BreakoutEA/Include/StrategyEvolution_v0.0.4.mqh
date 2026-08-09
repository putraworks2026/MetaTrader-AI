//+------------------------------------------------------------------+
//| StrategyEvolution_v0.0.4.mqh — BreakoutEA Profile Management
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef BREAKOUTEA_STRATEGY_EVOLUTION_MQH
#define BREAKOUTEA_STRATEGY_EVOLUTION_MQH

#include "Config_v0.0.4.mqh"
#include "LearningEngine_v0.0.4.mqh"
#include "TradingJournal_v0.0.4.mqh"

#define MAX_PROFILES 10

class CStrategyEvolution
{
private: ParameterSet m_p[MAX_PROFILES]; int m_activeId; int m_count;
public:
   void Init() { m_count=0; m_activeId=-1; CreateDefaultProfile(m_p[0],1); m_count=1; m_activeId=1; }
   int CreateProfile(string name) { if(m_count>=MAX_PROFILES) return -1; int id=m_count+1; CloneProfile(m_p[GetActiveIdx()],m_p[m_count],id,name); m_count++; return id; }
   void PromoteBest() { int b=0; for(int i=1;i<m_count;i++) if(m_p[i].status==PROFILE_ACTIVE&&m_p[i].score>m_p[b].score) b=i; for(int i=0;i<m_count;i++) if(m_p[i].id==m_activeId) m_p[i].status=PROFILE_BACKUP; m_p[b].status=PROFILE_PROMOTED; m_activeId=m_p[b].id; }
   void UpdateStats(int id, bool won, double profit) { int idx=-1; for(int i=0;i<m_count;i++) if(m_p[i].id==id) { idx=i; break; } if(idx<0) return; m_p[idx].totalTrades++; if(won) m_p[idx].wins++; else m_p[idx].losses++; m_p[idx].totalProfit+=profit; UpdateProfileScore(m_p[idx]); }
   int GetActiveIdx() { for(int i=0;i<m_count;i++) if(m_p[i].id==m_activeId) return i; return 0; }
   ParameterSet GetActiveProfile() { return m_p[GetActiveIdx()]; }
   int GetProfileCount() { return m_count; }
   string GetSummary() { int i=GetActiveIdx(); return StringFormat("#%d '%s' T:%d WR:%.1f%% S:%.1f",m_p[i].id,m_p[i].name,m_p[i].totalTrades,(m_p[i].totalTrades>0?(double)m_p[i].wins/m_p[i].totalTrades*100:0),m_p[i].score); }
};

#endif // BREAKOUTEA_STRATEGY_EVOLUTION_MQH
