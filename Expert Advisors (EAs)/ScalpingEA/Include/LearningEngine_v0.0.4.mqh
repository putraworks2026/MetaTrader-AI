//+------------------------------------------------------------------+
//| LearningEngine_v0.0.4.mqh — ScalpingEA Post-Trade Learning
//| Copyright 2026, PutraWorks
//| Patterns: OversoldBounce, OverboughtDrop, SpreadSqueeze, MicroTrend
//+------------------------------------------------------------------+
#ifndef SCALPINGEA_LEARNING_ENGINE_MQH
#define SCALPINGEA_LEARNING_ENGINE_MQH

#include "Config_v0.0.4.mqh"
#include "TradingJournal_v0.0.4.mqh"

struct ML_Lesson { string category; string description; double impact; int occurrences; datetime created; };

class CLearningEngine
{
private: ML_Lesson m_lessons[]; int m_count; string m_fn;
public:
   void Init(string toolName) { m_count=0; m_fn="MQL5/Files/"+toolName+"/lessons.csv"; Load(); }
   void AnalyzeTrade(const JournalEntry &je)
   {
      if(je.outcome==OUTCOME_WIN) { ML_Lesson l; l.category="OversoldBounce"; l.description="Fails when spread>50% of TP"; l.impact=1.0; l.created=TimeCurrent(); l.occurrences=1; AddLesson(l); }
      else if(je.outcome==OUTCOME_LOSS) { ML_Lesson l; l.category="OversoldBounce"; l.description="CONTRADICTS: Fails when spread>50% of TP"; l.impact=-0.5; l.created=TimeCurrent(); l.occurrences=1; AddLesson(l); }
      if(je.outcome==OUTCOME_WIN) { ML_Lesson l; l.category="OverboughtDrop"; l.description="RSI oversold bounces better in ranges"; l.impact=1.0; l.created=TimeCurrent(); l.occurrences=1; AddLesson(l); }
      else if(je.outcome==OUTCOME_LOSS) { ML_Lesson l; l.category="OverboughtDrop"; l.description="CONTRADICTS: RSI oversold bounces better in ranges"; l.impact=-0.5; l.created=TimeCurrent(); l.occurrences=1; AddLesson(l); }
      if(je.outcome==OUTCOME_LOSS) { ML_Lesson l; l.category="SpreadSqueeze"; l.description="Micro-trend entries higher win rate"; l.impact=-0.8; l.created=TimeCurrent(); l.occurrences=1; AddLesson(l); }
      if(je.outcome==OUTCOME_LOSS) { ML_Lesson l; l.category="MicroTrend"; l.description="Avoid 15min around high-impact news"; l.impact=-0.8; l.created=TimeCurrent(); l.occurrences=1; AddLesson(l); }
      if(je.spreadAtEntry>20 && je.outcome==OUTCOME_LOSS) { ML_Lesson l; l.category="Spread"; l.description="High spread caused loss"; l.impact=-0.7; l.created=TimeCurrent(); l.occurrences=1; AddLesson(l); }
   }
   void AddLesson(const ML_Lesson &lesson)
   { for(int i=0;i<m_count;i++) if(m_lessons[i].category==lesson.category && m_lessons[i].description==lesson.description) { m_lessons[i].occurrences++; m_lessons[i].impact=(m_lessons[i].impact+lesson.impact)/2.0; return; } ArrayResize(m_lessons,m_count+1); m_lessons[m_count]=lesson; m_count++; }
   string GetTopLesson() { if(m_count==0) return "No lessons yet"; int b=0; for(int i=1;i<m_count;i++) if(MathAbs(m_lessons[i].impact)*m_lessons[i].occurrences>MathAbs(m_lessons[b].impact)*m_lessons[b].occurrences) b=i; return m_lessons[b].category+": "+m_lessons[b].description; }
   int GetLessonCount() { return m_count; }
   void Save() { int h=FileOpen(m_fn,FILE_WRITE|FILE_CSV|FILE_ANSI,','); if(h==INVALID_HANDLE) return; for(int i=0;i<m_count;i++) FileWrite(h,m_lessons[i].category,m_lessons[i].description,DoubleToString(m_lessons[i].impact,2),m_lessons[i].occurrences,m_lessons[i].created); FileClose(h); }
   void Load() { int h=FileOpen(m_fn,FILE_READ|FILE_CSV|FILE_ANSI,','); if(h==INVALID_HANDLE) return; m_count=0; while(!FileIsEnding(h)) { ML_Lesson l; l.category=FileReadString(h); l.description=FileReadString(h); l.impact=FileReadNumber(h); l.occurrences=(int)FileReadNumber(h); l.created=(datetime)FileReadNumber(h); ArrayResize(m_lessons,m_count+1); m_lessons[m_count]=l; m_count++; } FileClose(h); }
};

#endif // SCALPINGEA_LEARNING_ENGINE_MQH
