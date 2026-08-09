//+------------------------------------------------------------------+
//| TradingJournal_v0.0.4.mqh — NewsTradingEA Trade Journal
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef NEWSTRADINGEA_TRADING_JOURNAL_MQH
#define NEWSTRADINGEA_TRADING_JOURNAL_MQH

#include "Config_v0.0.4.mqh"

struct JournalEntry
{
   int ticket; string symbol; datetime openTime,closeTime; int type;
   double openPrice,closePrice,stopLoss,takeProfit,volume,profit,mfe,mae;
   int profileId; ENUM_MARKET_REGIME regime; double atrAtEntry,spreadAtEntry;
   int weekday,hour; string session; ENUM_TRADE_OUTCOME outcome;
};

void InitJE(JournalEntry &je) { je.ticket=0; je.symbol=""; je.openTime=0; je.closeTime=0; je.type=-1; je.openPrice=0; je.closePrice=0; je.stopLoss=0; je.takeProfit=0; je.volume=0; je.profit=0; je.mfe=0; je.mae=0; je.profileId=0; je.regime=REGIME_UNKNOWN; je.atrAtEntry=0; je.spreadAtEntry=0; je.weekday=0; je.hour=0; je.session=""; je.outcome=OUTCOME_PENDING; }

class CTradingJournal
{
private: string m_fn;
public:
   void Init(string toolName) { string f="MQL5/Files/"+toolName; FolderCreate(f); m_fn=f+"/journal.csv"; }
   bool WriteEntry(const JournalEntry &je)
   {
      int h=FileOpen(m_fn,FILE_WRITE|FILE_READ|FILE_CSV|FILE_ANSI,','); if(h==INVALID_HANDLE) return false;
      FileSeek(h,0,SEEK_END);
      FileWrite(h,je.ticket,je.symbol,je.openTime,je.closeTime,je.type,DoubleToString(je.openPrice,5),DoubleToString(je.closePrice,5),DoubleToString(je.stopLoss,5),DoubleToString(je.takeProfit,5),DoubleToString(je.volume,2),DoubleToString(je.profit,2),DoubleToString(je.mfe,1),DoubleToString(je.mae,1),je.profileId,(int)je.regime,DoubleToString(je.atrAtEntry,2),DoubleToString(je.spreadAtEntry,1),je.weekday,je.hour,je.session,(int)je.outcome);
      FileClose(h); return true;
   }
   int GetEntryCount() { int h=FileOpen(m_fn,FILE_READ|FILE_CSV|FILE_ANSI,','); if(h==INVALID_HANDLE) return 0; int c=0; while(!FileIsEnding(h)) { FileReadString(h); c++; } FileClose(h); return c; }
};

#endif // NEWSTRADINGEA_TRADING_JOURNAL_MQH
