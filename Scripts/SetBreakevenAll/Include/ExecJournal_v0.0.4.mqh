//+------------------------------------------------------------------+
//| ExecJournal_v0.0.4.mqh — SetBreakevenAll Execution Journal
//| Copyright 2026, PutraWorks
//| Logs each: Set Breakeven
//+------------------------------------------------------------------+
#ifndef SETBREAKEVENALL_EXEC_JOURNAL_MQH
#define SETBREAKEVENALL_EXEC_JOURNAL_MQH

#include "ExecConfig_v0.0.4.mqh"

struct ExecEntry
{
   int id; datetime execTime; double execDuration;
   ENUM_EXEC_RESULT result; int itemsProcessed; string details; int weekday; int hour;
};

void InitExecEntry(ExecEntry &ee) { ee.id=0; ee.execTime=0; ee.execDuration=0; ee.result=EXEC_PENDING; ee.itemsProcessed=0; ee.details=""; ee.weekday=0; ee.hour=0; }

class CExecJournal
{
private:
   string m_filename; int m_nextId;
public:
   void Init(string toolName) { string f="MQL5/Files/"+toolName; FolderCreate(f); m_filename=f+"/exec_log.csv"; m_nextId=1; }
   bool WriteEntry(const ExecEntry &ee)
   {
      int h=FileOpen(m_filename, FILE_WRITE|FILE_READ|FILE_CSV|FILE_ANSI, ',');
      if(h==INVALID_HANDLE) return false; FileSeek(h,0,SEEK_END);
      FileWrite(h, ee.id, ee.execTime, DoubleToString(ee.execDuration,1), (int)ee.result, ee.itemsProcessed, ee.details, ee.weekday, ee.hour);
      FileClose(h); return true;
   }
   int ReadAll(ExecEntry &entries[], int maxCount=100)
   {
      int h=FileOpen(m_filename, FILE_READ|FILE_CSV|FILE_ANSI, ',');
      if(h==INVALID_HANDLE) return 0; int count=0; ArrayResize(entries, maxCount);
      while(!FileIsEnding(h) && count<maxCount)
      {
         ExecEntry ee; InitExecEntry(ee);
         ee.id=(int)FileReadNumber(h); ee.execTime=(datetime)FileReadNumber(h); ee.execDuration=FileReadNumber(h);
         ee.result=(ENUM_EXEC_RESULT)(int)FileReadNumber(h); ee.itemsProcessed=(int)FileReadNumber(h);
         ee.details=FileReadString(h); ee.weekday=(int)FileReadNumber(h); ee.hour=(int)FileReadNumber(h);
         entries[count]=ee; count++;
      }
      FileClose(h); ArrayResize(entries, count); return count;
   }
   int GetCount() { int h=FileOpen(m_filename, FILE_READ|FILE_CSV|FILE_ANSI, ','); if(h==INVALID_HANDLE) return 0; int c=0; while(!FileIsEnding(h)) { FileReadString(h); c++; } FileClose(h); return c; }
   int GetNextId() { return m_nextId++; }
};

#endif // SETBREAKEVENALL_EXEC_JOURNAL_MQH
