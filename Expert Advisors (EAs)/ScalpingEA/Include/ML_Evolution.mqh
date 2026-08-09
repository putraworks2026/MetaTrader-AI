//+------------------------------------------------------------------+
//| ML_Evolution.mqh — Strategy Evolution & Profile Management
//| Part of: ScalpingEA v0.0.3
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef __ML_EVOLUTION_SCALPINGEA_MQH__
#define __ML_EVOLUTION_SCALPINGEA_MQH__

#include "ML_Config.mqh"

#define ML_MAX_PROFILES 10

class CMLStrategyEvolution
{
private:
   ML_ParameterSet m_profiles[ML_MAX_PROFILES];
   int            m_activeProfileId;
   int            m_profileCount;
public:
   void Init()
   {
      m_profileCount = 0;
      m_activeProfileId = -1;
      // Create default profile
      ML_CreateDefaultProfile(m_profiles[0], 1);
      m_profileCount = 1;
      m_activeProfileId = 1;
   }

   int CreateProfile(string name)
   {
      if(m_profileCount >= ML_MAX_PROFILES) return -1;
      int newId = m_profileCount + 1;
      ML_CloneProfile(m_profiles[GetActiveIndex()], m_profiles[m_profileCount], newId, name);
      m_profileCount++;
      return newId;
   }

   void PromoteBestProfile()
   {
      int bestIdx = 0;
      double bestScore = m_profiles[0].score;
      for(int i = 1; i < m_profileCount; i++)
      {
         if(m_profiles[i].status == ML_PROFILE_ACTIVE && m_profiles[i].score > bestScore)
         {
            bestScore = m_profiles[i].score;
            bestIdx = i;
         }
      }
      // Retire current active
      for(int i = 0; i < m_profileCount; i++)
         if(m_profiles[i].id == m_activeProfileId)
            m_profiles[i].status = ML_PROFILE_BACKUP;
      m_profiles[bestIdx].status = ML_PROFILE_PROMOTED;
      m_activeProfileId = m_profiles[bestIdx].id;
   }

   void RetirePoorProfiles(double minScore = 30.0)
   {
      for(int i = 0; i < m_profileCount; i++)
      {
         if(m_profiles[i].totalTrades >= 10 && m_profiles[i].score < minScore)
            m_profiles[i].status = ML_PROFILE_RETIRED;
      }
   }

   void UpdateProfileStats(int profileId, bool won, double profit, double riskReward)
   {
      int idx = -1;
      for(int i = 0; i < m_profileCount; i++)
         if(m_profiles[i].id == profileId) { idx = i; break; }
      if(idx < 0) return;
      m_profiles[idx].totalTrades++;
      if(won) m_profiles[idx].wins++; else m_profiles[idx].losses++;
      m_profiles[idx].totalProfit += profit;
      m_profiles[idx].avgRiskReward = (m_profiles[idx].avgRiskReward * (m_profiles[idx].totalTrades - 1) + riskReward) / m_profiles[idx].totalTrades;
      ML_UpdateProfileScore(m_profiles[idx]);
   }

   int GetActiveIndex()
   {
      for(int i = 0; i < m_profileCount; i++)
         if(m_profiles[i].id == m_activeProfileId) return i;
      return 0;
   }

   ML_ParameterSet GetActiveProfile()
   {
      return m_profiles[GetActiveIndex()];
   }

   int GetProfileCount() { return m_profileCount; }
   int GetActiveProfileId() { return m_activeProfileId; }

   string GetProfileSummary()
   {
      int idx = GetActiveIndex();
      return StringFormat("Profile #%d '%s' | Trades: %d | WR: %.1f%% | PF: %.2f | Score: %.1f",
         m_profiles[idx].id, m_profiles[idx].name,
         m_profiles[idx].totalTrades,
         (m_profiles[idx].totalTrades > 0 ? (double)m_profiles[idx].wins / m_profiles[idx].totalTrades * 100 : 0),
         m_profiles[idx].profitFactor,
         m_profiles[idx].score);
   }
};

#endif // __ML_EVOLUTION_SCALPINGEA_MQH__
