//+------------------------------------------------------------------+
//| ML_Optimize.mqh — Adaptive Parameter Optimization
//| Part of: GridTradingEA v0.0.3
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef __ML_OPTIMIZE_GRIDTRADINGEA_MQH__
#define __ML_OPTIMIZE_GRIDTRADINGEA_MQH__

#include "ML_Config.mqh"

//==================================================================
//  PROPOSED CHANGE STRUCT
//==================================================================
struct ML_ProposedChange
{
   int      changeId;
   int      profileId;
   string   parameter;
   double   oldValue;
   double   newValue;
   string   rationale;
   double   expectedImprovement;
   int      evidenceTrades;
   ENUM_ML_APPROVAL approval;
   datetime proposed;
};

void ML_InitProposedChange(ML_ProposedChange &pc)
{
   pc.changeId=0; pc.profileId=0; pc.parameter=""; pc.oldValue=0;
   pc.newValue=0; pc.rationale=""; pc.expectedImprovement=0;
   pc.evidenceTrades=0; pc.approval=ML_APPROVAL_NONE; pc.proposed=TimeCurrent();
}

class CMLoptimizer
{
private:
   ML_ProposedChange m_changes[];
   int              m_changeCount;
   int              m_nextChangeId;
   int              m_minEvidenceTrades;
   bool             m_autoApprove;
public:
   void Init(int minEvidence = 10, bool autoApprove = false)
   {
      m_changeCount = 0;
      m_nextChangeId = 1;
      m_minEvidenceTrades = minEvidence;
      m_autoApprove = autoApprove;
   }

   void SetMinEvidence(int trades) { m_minEvidenceTrades = trades; }
   void SetAutoApprove(bool val) { m_autoApprove = val; }

   void ProposeChange(int profileId, string param, double oldVal, double newVal,
                      string rationale, double expected, int evidence)
   {
      if(evidence < m_minEvidenceTrades) return;
      ML_ProposedChange pc; ML_InitProposedChange(pc);
      pc.changeId = m_nextChangeId++;
      pc.profileId = profileId;
      pc.parameter = param;
      pc.oldValue = oldVal;
      pc.newValue = newVal;
      pc.rationale = rationale;
      pc.expectedImprovement = expected;
      pc.evidenceTrades = evidence;
      pc.approval = m_autoApprove ? ML_APPROVAL_APPROVED : ML_APPROVAL_PENDING;
      ArrayResize(m_changes, m_changeCount + 1);
      m_changes[m_changeCount] = pc;
      m_changeCount++;
   }

   void ApproveChange(int changeId)
   {
      for(int i = 0; i < m_changeCount; i++)
         if(m_changes[i].changeId == changeId)
            m_changes[i].approval = ML_APPROVAL_APPROVED;
   }

   void RejectChange(int changeId)
   {
      for(int i = 0; i < m_changeCount; i++)
         if(m_changes[i].changeId == changeId)
            m_changes[i].approval = ML_APPROVAL_REJECTED;
   }

   int GetPendingCount()
   {
      int count = 0;
      for(int i = 0; i < m_changeCount; i++)
         if(m_changes[i].approval == ML_APPROVAL_PENDING) count++;
      return count;
   }

   int GetApprovedCount()
   {
      int count = 0;
      for(int i = 0; i < m_changeCount; i++)
         if(m_changes[i].approval == ML_APPROVAL_APPROVED) count++;
      return count;
   }

   string GetPendingChangesSummary()
   {
      string summary = "";
      for(int i = 0; i < m_changeCount; i++)
      {
         if(m_changes[i].approval == ML_APPROVAL_PENDING)
         {
            summary += StringFormat("Change #%d: %s %.2f->%.2f (%s)\n",
               m_changes[i].changeId, m_changes[i].parameter,
               m_changes[i].oldValue, m_changes[i].newValue, m_changes[i].rationale);
         }
      }
      if(summary == "") summary = "No pending changes";
      return summary;
   }

   int GetChangeCount() { return m_changeCount; }
};

#endif // __ML_OPTIMIZE_GRIDTRADINGEA_MQH__
