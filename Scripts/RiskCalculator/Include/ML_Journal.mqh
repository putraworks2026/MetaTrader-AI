//+------------------------------------------------------------------+
//| ML_Journal.mqh — Machine Learning Trade Journal
//| Part of: RiskCalculator v0.0.3
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef __ML_JOURNAL_RISKCALCULATOR_MQH__
#define __ML_JOURNAL_RISKCALCULATOR_MQH__

#include "ML_Config.mqh"

//==================================================================
//  JOURNAL ENTRY STRUCT
//==================================================================
struct ML_JournalEntry
{
   int          ticket;
   string       symbol;
   datetime     openTime;
   datetime     closeTime;
   int          type;
   double       openPrice;
   double       closePrice;
   double       stopLoss;
   double       takeProfit;
   double       volume;
   double       profit;
   double       mfe;
   double       mae;
   double       confidence;
   string       rationale;
   ENUM_ML_OUTCOME outcome;
   ENUM_ML_ENTRY_QUALITY entryQuality;
   ENUM_ML_REGIME regime;
   int          profileId;
   double       rsiAtEntry;
   double       atrAtEntry;
   double       volatilityPercent;
   int          weekday;
   int          hour;
   string       session;
   string       lessonLearned;
   double       riskRewardRatio;
};

void ML_InitJournalEntry(ML_JournalEntry &je)
{
   je.ticket=0; je.symbol=""; je.openTime=0; je.closeTime=0; je.type=-1;
   je.openPrice=0; je.closePrice=0; je.stopLoss=0; je.takeProfit=0;
   je.volume=0; je.profit=0; je.mfe=0; je.mae=0; je.confidence=0;
   je.rationale=""; je.outcome=ML_OUTCOME_PENDING; je.entryQuality=ML_ENTRY_UNKNOWN;
   je.regime=ML_REGIME_UNKNOWN; je.profileId=0; je.rsiAtEntry=0;
   je.atrAtEntry=0; je.volatilityPercent=0; je.weekday=0; je.hour=0;
   je.session=""; je.lessonLearned=""; je.riskRewardRatio=0;
}

class CMLJournal
{
private:
   string m_folder;
   string m_filename;
public:
   void Init(string toolName)
   {
      m_folder = "MQL5/Files/" + toolName;
      m_filename = m_folder + "/journal.csv";
      FolderCreate(m_folder);
   }

   void WriteEntry(const ML_JournalEntry &je)
   {
      int handle = FileOpen(m_filename, FILE_WRITE | FILE_READ | FILE_CSV | FILE_ANSI, ',');
      if(handle == INVALID_HANDLE) return;
      FileSeek(handle, 0, SEEK_END);
      FileWrite(handle,
         je.ticket, je.symbol, je.openTime, je.closeTime, je.type,
         je.openPrice, je.closePrice, je.stopLoss, je.takeProfit, je.volume,
         DoubleToString(je.profit, 2), DoubleToString(je.mfe, 1), DoubleToString(je.mae, 1),
         DoubleToString(je.confidence, 1), je.rationale, (int)je.outcome,
         (int)je.entryQuality, (int)je.regime, je.profileId,
         DoubleToString(je.rsiAtEntry, 2), DoubleToString(je.atrAtEntry, 2),
         DoubleToString(je.volatilityPercent, 2), je.weekday, je.hour,
         je.session, je.lessonLearned, DoubleToString(je.riskRewardRatio, 2));
      FileClose(handle);
   }

   int ReadEntries(ML_JournalEntry &entries[], int maxCount = 100)
   {
      int handle = FileOpen(m_filename, FILE_READ | FILE_CSV | FILE_ANSI, ',');
      if(handle == INVALID_HANDLE) return 0;
      int count = 0;
      ArrayResize(entries, maxCount);
      while(!FileIsEnding(handle) && count < maxCount)
      {
         ML_JournalEntry je; ML_InitJournalEntry(je);
         je.ticket = (int)FileReadNumber(handle);
         je.symbol = FileReadString(handle);
         je.openTime = (datetime)FileReadNumber(handle);
         je.closeTime = (datetime)FileReadNumber(handle);
         je.type = (int)FileReadNumber(handle);
         je.openPrice = FileReadNumber(handle);
         je.closePrice = FileReadNumber(handle);
         je.stopLoss = FileReadNumber(handle);
         je.takeProfit = FileReadNumber(handle);
         je.volume = FileReadNumber(handle);
         je.profit = FileReadNumber(handle);
         je.mfe = FileReadNumber(handle);
         je.mae = FileReadNumber(handle);
         je.confidence = FileReadNumber(handle);
         je.rationale = FileReadString(handle);
         je.outcome = (ENUM_ML_OUTCOME)(int)FileReadNumber(handle);
         je.entryQuality = (ENUM_ML_ENTRY_QUALITY)(int)FileReadNumber(handle);
         je.regime = (ENUM_ML_REGIME)(int)FileReadNumber(handle);
         je.profileId = (int)FileReadNumber(handle);
         je.rsiAtEntry = FileReadNumber(handle);
         je.atrAtEntry = FileReadNumber(handle);
         je.volatilityPercent = FileReadNumber(handle);
         je.weekday = (int)FileReadNumber(handle);
         je.hour = (int)FileReadNumber(handle);
         je.session = FileReadString(handle);
         je.lessonLearned = FileReadString(handle);
         je.riskRewardRatio = FileReadNumber(handle);
         entries[count] = je;
         count++;
      }
      FileClose(handle);
      ArrayResize(entries, count);
      return count;
   }

   int CountEntries()
   {
      int handle = FileOpen(m_filename, FILE_READ | FILE_CSV | FILE_ANSI, ',');
      if(handle == INVALID_HANDLE) return 0;
      int count = 0;
      while(!FileIsEnding(handle))
      {
         FileReadString(handle);
         count++;
      }
      FileClose(handle);
      return count;
   }
};

#endif // __ML_JOURNAL_RISKCALCULATOR_MQH__
