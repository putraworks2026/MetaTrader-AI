//+------------------------------------------------------------------+
//| SignalPatterns_v0.0.4.mqh — SessionsKillzones Signal Pattern Scoring
//| Copyright 2026, PutraWorks
//| Scores which conditions produce good Session Break signals
//+------------------------------------------------------------------+
#ifndef SESSIONSKILLZONES_SIGNAL_PATTERNS_MQH
#define SESSIONSKILLZONES_SIGNAL_PATTERNS_MQH

#include "SignalConfig_v0.0.4.mqh"

struct SignalPatternStat { string condition; int occurrences; int successes; int failures; double successRate; double avgFavorable; double score; };

class CSignalPatterns
{
private:
   SignalPatternStat m_patterns[]; int m_count;
public:
   void Init() { m_count=0; }
   void RecordPattern(string condition, bool success, double favorable)
   {
      for(int i=0;i<m_count;i++)
         if(m_patterns[i].condition==condition)
         { m_patterns[i].occurrences++; if(success) m_patterns[i].successes++; else m_patterns[i].failures++; m_patterns[i].successRate=(double)m_patterns[i].successes/m_patterns[i].occurrences; m_patterns[i].avgFavorable=(m_patterns[i].avgFavorable*(m_patterns[i].occurrences-1)+favorable)/m_patterns[i].occurrences; m_patterns[i].score=m_patterns[i].successRate*80.0+MathMin(20.0,m_patterns[i].occurrences*2.0); return; }
      SignalPatternStat ps; ps.condition=condition; ps.occurrences=1; ps.successes=success?1:0; ps.failures=success?0:1; ps.successRate=success?1.0:0.0; ps.avgFavorable=favorable; ps.score=success?80.0:20.0;
      ArrayResize(m_patterns, m_count+1); m_patterns[m_count]=ps; m_count++;
   }
   double GetScore(string condition) { for(int i=0;i<m_count;i++) if(m_patterns[i].condition==condition) return m_patterns[i].score; return 50.0; }
   string GetBestCondition() { if(m_count==0) return "No data for Session Break"; int b=0; for(int i=1;i<m_count;i++) if(m_patterns[i].score>m_patterns[b].score) b=i; return m_patterns[b].condition+" | SR: "+DoubleToString(m_patterns[b].successRate*100,1)+"%"; }
   int GetPatternCount() { return m_count; }
};

#endif // SESSIONSKILLZONES_SIGNAL_PATTERNS_MQH
