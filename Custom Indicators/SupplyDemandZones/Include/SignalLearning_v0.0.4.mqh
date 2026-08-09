//+------------------------------------------------------------------+
//| SignalLearning_v0.0.4.mqh — SupplyDemandZones Signal Reliability Learning
//| Copyright 2026, PutraWorks
//| Learns which Zone Touch signals are most reliable
//+------------------------------------------------------------------+
#ifndef SUPPLYDEMANDZONES_SIGNAL_LEARNING_MQH
#define SUPPLYDEMANDZONES_SIGNAL_LEARNING_MQH

#include "SignalConfig_v0.0.4.mqh"
#include "SignalJournal_v0.0.4.mqh"

struct SignalLesson { string condition; string description; double impact; int occurrences; datetime created; };

class CSignalLearning
{
private:
   SignalLesson m_lessons[]; int m_count; string m_filename;
public:
   void Init(string toolName) { m_count=0; m_filename="MQL5/Files/"+toolName+"/signal_lessons.csv"; LoadLessons(); }
   
   // SupplyDemandZones-specific: Zone Touch
   void AnalyzeSignal(const SignalEntry &se)
   {
      if(se.confidence>70 && se.outcome==SIGNAL_SUCCESS) AddLesson("HighConfidence","High-confidence Zone Touch signals succeed",1.0);
      else if(se.confidence>70 && se.outcome==SIGNAL_FAILED) AddLesson("HighConfidence","High-confidence Zone Touch FAILED - review threshold",-1.0);
      if(se.outcome==SIGNAL_FAILED && (se.hour<7 || se.hour>20)) AddLesson("OffHours","Zone Touch signals fail in off-hours",-0.5);
      if(se.regime==REGIME_VOLATILE && se.outcome==SIGNAL_FAILED) AddLesson("Volatile","Zone Touch signals fail in volatile regime",-0.8);
      if(se.regime==REGIME_TRENDING && se.outcome==SIGNAL_SUCCESS) AddLesson("Trending","Zone Touch signals succeed in trending regime",0.7);
      if(se.quality==SIGNAL_QUALITY_HIGH && se.outcome==SIGNAL_FAILED) AddLesson("QualityMismatch","High-quality Zone Touch failed - recalibrate",-0.9);
   }
   
   void AddLesson(string condition, string description, double impact)
   {
      for(int i=0;i<m_count;i++)
         if(m_lessons[i].condition==condition && m_lessons[i].description==description)
         { m_lessons[i].occurrences++; m_lessons[i].impact=(m_lessons[i].impact+impact)/2.0; return; }
      SignalLesson l; l.condition=condition; l.description=description; l.impact=impact; l.occurrences=1; l.created=TimeCurrent();
      ArrayResize(m_lessons, m_count+1); m_lessons[m_count]=l; m_count++;
   }
   
   string GetTopInsight() { if(m_count==0) return "No insights yet for Zone Touch"; int b=0; for(int i=1;i<m_count;i++) if(MathAbs(m_lessons[i].impact)*m_lessons[i].occurrences>MathAbs(m_lessons[b].impact)*m_lessons[b].occurrences) b=i; return m_lessons[b].condition+": "+m_lessons[b].description; }
   int GetLessonCount() { return m_count; }
   void SaveLessons() { int h=FileOpen(m_filename, FILE_WRITE|FILE_CSV|FILE_ANSI, ','); if(h==INVALID_HANDLE) return; for(int i=0;i<m_count;i++) FileWrite(h, m_lessons[i].condition, m_lessons[i].description, DoubleToString(m_lessons[i].impact,2), m_lessons[i].occurrences, m_lessons[i].created); FileClose(h); }
   void LoadLessons() { int h=FileOpen(m_filename, FILE_READ|FILE_CSV|FILE_ANSI, ','); if(h==INVALID_HANDLE) return; m_count=0; while(!FileIsEnding(h)) { SignalLesson l; l.condition=FileReadString(h); l.description=FileReadString(h); l.impact=FileReadNumber(h); l.occurrences=(int)FileReadNumber(h); l.created=(datetime)FileReadNumber(h); ArrayResize(m_lessons,m_count+1); m_lessons[m_count]=l; m_count++; } FileClose(h); }
};

#endif // SUPPLYDEMANDZONES_SIGNAL_LEARNING_MQH
