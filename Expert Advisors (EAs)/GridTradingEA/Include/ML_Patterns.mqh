//+------------------------------------------------------------------+
//| ML_Patterns.mqh — Pattern Recognition & Ranking
//| Part of: GridTradingEA v0.0.3
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef __ML_PATTERNS_GRIDTRADINGEA_MQH__
#define __ML_PATTERNS_GRIDTRADINGEA_MQH__

#include "ML_Config.mqh"

//==================================================================
//  PATTERN STAT STRUCT
//==================================================================
struct ML_PatternStat
{
   string   category;
   string   condition;
   int      trades;
   int      wins;
   int      losses;
   double   totalProfit;
   double   winRate;
   double   avgProfit;
   double   score;
};

void ML_InitPatternStat(ML_PatternStat &ps)
{
   ps.category=""; ps.condition=""; ps.trades=0; ps.wins=0; ps.losses=0;
   ps.totalProfit=0; ps.winRate=0; ps.avgProfit=0; ps.score=50.0;
}

class CMLPatternRecognition
{
private:
   ML_PatternStat m_patterns[];
   int            m_patternCount;
public:
   void Init() { m_patternCount = 0; }

   void RecordPattern(string category, string condition, bool won, double profit)
   {
      // Find existing pattern
      for(int i = 0; i < m_patternCount; i++)
      {
         if(m_patterns[i].category == category && m_patterns[i].condition == condition)
         {
            m_patterns[i].trades++;
            if(won) m_patterns[i].wins++; else m_patterns[i].losses++;
            m_patterns[i].totalProfit += profit;
            m_patterns[i].winRate = (double)m_patterns[i].wins / m_patterns[i].trades;
            m_patterns[i].avgProfit = m_patterns[i].totalProfit / m_patterns[i].trades;
            m_patterns[i].score = (m_patterns[i].winRate * 70.0) +
               (m_patterns[i].avgProfit > 0 ? 15.0 : 0.0) +
               (m_patterns[i].trades >= 10 ? 15.0 : m_patterns[i].trades * 1.5);
            m_patterns[i].score = MathMin(100.0, MathMax(0.0, m_patterns[i].score));
            return;
         }
      }
      // New pattern
      ML_PatternStat ps; ML_InitPatternStat(ps);
      ps.category = category;
      ps.condition = condition;
      ps.trades = 1;
      if(won) ps.wins = 1; else ps.losses = 1;
      ps.totalProfit = profit;
      ps.winRate = won ? 1.0 : 0.0;
      ps.avgProfit = profit;
      ps.score = won ? 70.0 : 30.0;
      ArrayResize(m_patterns, m_patternCount + 1);
      m_patterns[m_patternCount] = ps;
      m_patternCount++;
   }

   double GetPatternScore(string category, string condition)
   {
      for(int i = 0; i < m_patternCount; i++)
      {
         if(m_patterns[i].category == category && m_patterns[i].condition == condition)
            return m_patterns[i].score;
      }
      return 50.0; // Neutral score for unseen patterns
   }

   string GetBestPattern()
   {
      if(m_patternCount == 0) return "No patterns recorded";
      int best = 0;
      for(int i = 1; i < m_patternCount; i++)
         if(m_patterns[i].score > m_patterns[best].score) best = i;
      return m_patterns[best].category + " | " + m_patterns[best].condition +
         " | Score: " + DoubleToString(m_patterns[best].score, 1) +
         " | WR: " + DoubleToString(m_patterns[best].winRate * 100, 1) + "%";
   }

   string GetWorstPattern()
   {
      if(m_patternCount == 0) return "No patterns recorded";
      int worst = 0;
      for(int i = 1; i < m_patternCount; i++)
         if(m_patterns[i].score < m_patterns[worst].score) worst = i;
      return m_patterns[worst].category + " | " + m_patterns[worst].condition +
         " | Score: " + DoubleToString(m_patterns[worst].score, 1) +
         " | WR: " + DoubleToString(m_patterns[worst].winRate * 100, 1) + "%";
   }

   int GetPatternCount() { return m_patternCount; }
};

#endif // __ML_PATTERNS_GRIDTRADINGEA_MQH__
