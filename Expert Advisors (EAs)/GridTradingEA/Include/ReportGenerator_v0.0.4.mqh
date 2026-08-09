//+------------------------------------------------------------------+
//| ReportGenerator_v0.0.4.mqh — GridTradingEA Performance Reports
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef GRIDTRADINGEA_REPORT_GENERATOR_MQH
#define GRIDTRADINGEA_REPORT_GENERATOR_MQH

#include "Config_v0.0.4.mqh"
#include "TradingJournal_v0.0.4.mqh"
#include "LearningEngine_v0.0.4.mqh"
#include "StrategyEvolution_v0.0.4.mqh"
#include "PatternRecognition_v0.0.4.mqh"

class CReportGenerator
{
private: string m_fn;
public:
   void Init(string toolName) { string f="MQL5/Files/"+toolName; FolderCreate(f); m_fn=f+"/report.txt"; }
   void GenerateDaily(CTradingJournal &j, CLearningEngine &l, CStrategyEvolution &e, CPatternRecognition &p)
   { int h=FileOpen(m_fn,FILE_WRITE|FILE_TXT|FILE_ANSI); if(h==INVALID_HANDLE) return;
      FileWrite(h,"===== GridTradingEA Report ====="); FileWrite(h,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS));
      FileWrite(h,"Profile: "+e.GetSummary()); FileWrite(h,"Trades: "+IntegerToString(j.GetEntryCount()));
      FileWrite(h,"Lessons: "+IntegerToString(l.GetLessonCount())); FileWrite(h,"Top: "+l.GetTopLesson());
      FileWrite(h,"Patterns: "+IntegerToString(p.GetPatternCount())); FileWrite(h,"Best: "+p.GetBest()); FileWrite(h,"Worst: "+p.GetWorst());
      FileClose(h); }
};

#endif // GRIDTRADINGEA_REPORT_GENERATOR_MQH
