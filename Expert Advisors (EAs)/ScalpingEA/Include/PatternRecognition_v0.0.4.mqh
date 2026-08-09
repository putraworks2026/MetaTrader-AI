//+------------------------------------------------------------------+
//| PatternRecognition_v0.0.4.mqh — ScalpingEA Pattern Detection
//| Copyright 2026, PutraWorks
//| Categories: OversoldBounce, OverboughtDrop, SpreadSqueeze, MicroTrend
//+------------------------------------------------------------------+
#ifndef SCALPINGEA_PATTERN_RECOGNITION_MQH
#define SCALPINGEA_PATTERN_RECOGNITION_MQH

#include "Config_v0.0.4.mqh"
#include "TradingJournal_v0.0.4.mqh"

struct PatternStat { string category; string condition; int trades; int wins; int losses; double totalProfit; double winRate; double score; };

class CPatternRecognition
{
private: PatternStat m_p[]; int m_count;
public:
   void Init() { m_count=0; }
   void RecordTrade(string cat, string cond, bool won, double profit)
   { for(int i=0;i<m_count;i++) if(m_p[i].category==cat && m_p[i].condition==cond) { m_p[i].trades++; if(won) m_p[i].wins++; else m_p[i].losses++; m_p[i].totalProfit+=profit; m_p[i].winRate=(double)m_p[i].wins/m_p[i].trades; m_p[i].score=m_p[i].winRate*70.0+(m_p[i].totalProfit>0?15.0:0.0)+MathMin(15.0,m_p[i].trades*1.5); return; } PatternStat ps; ps.category=cat; ps.condition=cond; ps.trades=1; ps.wins=won?1:0; ps.losses=won?0:1; ps.totalProfit=profit; ps.winRate=won?1.0:0.0; ps.score=won?70.0:30.0; ArrayResize(m_p,m_count+1); m_p[m_count]=ps; m_count++; }
   double GetScore(string cat, string cond) { for(int i=0;i<m_count;i++) if(m_p[i].category==cat && m_p[i].condition==cond) return m_p[i].score; return 50.0; }
   string GetBest() { if(m_count==0) return "No patterns"; int b=0; for(int i=1;i<m_count;i++) if(m_p[i].score>m_p[b].score) b=i; return m_p[b].category+"|"+m_p[b].condition+"|"+DoubleToString(m_p[b].score,1); }
   string GetWorst() { if(m_count==0) return "No patterns"; int w=0; for(int i=1;i<m_count;i++) if(m_p[i].score<m_p[w].score) w=i; return m_p[w].category+"|"+m_p[w].condition+"|"+DoubleToString(m_p[w].score,1); }
   int GetPatternCount() { return m_count; }
};

#endif // SCALPINGEA_PATTERN_RECOGNITION_MQH
