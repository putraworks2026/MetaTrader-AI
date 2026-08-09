//+------------------------------------------------------------------+
//| SignalJournal_v0.0.4.mqh — SessionsKillzones Signal Accuracy Journal
//| Copyright 2026, PutraWorks
//| Tracks: Session Break
//+------------------------------------------------------------------+
#ifndef SESSIONSKILLZONES_SIGNAL_JOURNAL_MQH
#define SESSIONSKILLZONES_SIGNAL_JOURNAL_MQH

#include "SignalConfig_v0.0.4.mqh"

//--- SessionsKillzones Signal Entry
struct SignalEntry
{
   int id; datetime signalTime; double signalPrice; string signalType;
   ENUM_SIGNAL_QUALITY quality; double confidence;
   double priceAfter1Bar; double priceAfter5Bars; double priceAfter10Bars;
   double maxFavorable; double maxAdverse; ENUM_SIGNAL_OUTCOME outcome;
   double atrAtSignal; ENUM_MARKET_REGIME regime; int weekday; int hour; string session;
};

void InitSignalEntry(SignalEntry &se)
{
   se.id=0; se.signalTime=0; se.signalPrice=0; se.signalType="";
   se.quality=SIGNAL_QUALITY_NONE; se.confidence=0;
   se.priceAfter1Bar=0; se.priceAfter5Bars=0; se.priceAfter10Bars=0;
   se.maxFavorable=0; se.maxAdverse=0; se.outcome=SIGNAL_PENDING;
   se.atrAtSignal=0; se.regime=REGIME_UNKNOWN; se.weekday=0; se.hour=0; se.session="";
}

class CSignalJournal
{
private:
   string m_filename; int m_nextId;
public:
   void Init(string toolName) { string f="MQL5/Files/"+toolName; FolderCreate(f); m_filename=f+"/signals.csv"; m_nextId=1; }
   bool WriteEntry(const SignalEntry &se)
   {
      int h=FileOpen(m_filename, FILE_WRITE|FILE_READ|FILE_CSV|FILE_ANSI, ',');
      if(h==INVALID_HANDLE) return false; FileSeek(h,0,SEEK_END);
      FileWrite(h, se.id, se.signalTime, DoubleToString(se.signalPrice,5), se.signalType, (int)se.quality,
         DoubleToString(se.confidence,1), DoubleToString(se.priceAfter1Bar,5), DoubleToString(se.priceAfter5Bars,5),
         DoubleToString(se.priceAfter10Bars,5), DoubleToString(se.maxFavorable,1), DoubleToString(se.maxAdverse,1),
         (int)se.outcome, DoubleToString(se.atrAtSignal,2), (int)se.regime, se.weekday, se.hour, se.session);
      FileClose(h); return true;
   }
   int ReadAll(SignalEntry &entries[], int maxCount=200)
   {
      int h=FileOpen(m_filename, FILE_READ|FILE_CSV|FILE_ANSI, ',');
      if(h==INVALID_HANDLE) return 0; int count=0; ArrayResize(entries, maxCount);
      while(!FileIsEnding(h) && count<maxCount)
      {
         SignalEntry se; InitSignalEntry(se);
         se.id=(int)FileReadNumber(h); se.signalTime=(datetime)FileReadNumber(h);
         se.signalPrice=FileReadNumber(h); se.signalType=FileReadString(h);
         se.quality=(ENUM_SIGNAL_QUALITY)(int)FileReadNumber(h); se.confidence=FileReadNumber(h);
         se.priceAfter1Bar=FileReadNumber(h); se.priceAfter5Bars=FileReadNumber(h); se.priceAfter10Bars=FileReadNumber(h);
         se.maxFavorable=FileReadNumber(h); se.maxAdverse=FileReadNumber(h);
         se.outcome=(ENUM_SIGNAL_OUTCOME)(int)FileReadNumber(h);
         se.atrAtSignal=FileReadNumber(h); se.regime=(ENUM_MARKET_REGIME)(int)FileReadNumber(h);
         se.weekday=(int)FileReadNumber(h); se.hour=(int)FileReadNumber(h); se.session=FileReadString(h);
         entries[count]=se; count++;
      }
      FileClose(h); ArrayResize(entries, count); return count;
   }
   int GetCount() { int h=FileOpen(m_filename, FILE_READ|FILE_CSV|FILE_ANSI, ','); if(h==INVALID_HANDLE) return 0; int c=0; while(!FileIsEnding(h)) { FileReadString(h); c++; } FileClose(h); return c; }
   int GetNextId() { return m_nextId++; }
};

#endif // SESSIONSKILLZONES_SIGNAL_JOURNAL_MQH
