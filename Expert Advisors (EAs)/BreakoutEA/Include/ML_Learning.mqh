//+------------------------------------------------------------------+
//| ML_Learning.mqh — Machine Learning Engine
//| Part of: BreakoutEA v0.0.3
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef __ML_LEARNING_BREAKOUTEA_MQH__
#define __ML_LEARNING_BREAKOUTEA_MQH__

#include "ML_Config.mqh"
#include "ML_Journal.mqh"

//==================================================================
//  ML LESSON STRUCT
//==================================================================
struct ML_Lesson
{
   string   category;
   string   description;
   double   impact;
   int      occurrenceCount;
   datetime created;
};

class CMLLearning
{
private:
   ML_Lesson    m_lessons[];
   int          m_lessonCount;
   string       m_folder;
public:
   void Init(string toolName)
   {
      m_lessonCount = 0;
      m_folder = "MQL5/Files/" + toolName + "/lessons.csv";
      LoadLessons();
   }

   void AnalyzeTrade(const ML_JournalEntry &je)
   {
      ML_Lesson lesson;
      lesson.created = TimeCurrent();
      lesson.occurrenceCount = 1;

      // Entry timing analysis
      if(je.mfe > 0 && je.mae > 0)
      {
         double efficiency = (je.outcome == ML_OUTCOME_WIN) ?
            (je.profit / (je.mfe * SymbolInfoDouble(je.symbol, SYMBOL_POINT))) :
            0.0;

         if(efficiency > 0.8)
         {
            lesson.category = "EntryTiming";
            lesson.description = "Entry timing optimal for " + je.session + " session";
            lesson.impact = 1.0;
            AddLesson(lesson);
         }
         else if(efficiency < 0.3 && je.outcome == ML_OUTCOME_WIN)
         {
            lesson.category = "EntryTiming";
            lesson.description = "Left profit on table in " + je.session + " session";
            lesson.impact = -0.5;
            AddLesson(lesson);
         }
      }

      // Stop loss analysis
      if(je.outcome == ML_OUTCOME_LOSS && je.mae < 0)
      {
         double slPoints = MathAbs(je.openPrice - je.stopLoss) / SymbolInfoDouble(je.symbol, SYMBOL_POINT);
         if(je.mae < -slPoints * 0.5)
         {
            lesson.category = "StopLoss";
            lesson.description = "SL too tight — trade reversed before recovering";
            lesson.impact = -1.0;
            AddLesson(lesson);
         }
         else if(je.mae > -slPoints * 0.2)
         {
            lesson.category = "StopLoss";
            lesson.description = "SL too wide — small adverse move hit SL";
            lesson.impact = -0.5;
            AddLesson(lesson);
         }
      }

      // Session analysis
      if(je.outcome == ML_OUTCOME_WIN && je.profit > 0)
      {
         lesson.category = "Session";
         lesson.description = "Win in " + je.session + " hour " + IntegerToString(je.hour);
         lesson.impact = 0.5;
         AddLesson(lesson);
      }

      // Regime analysis
      if(je.regime == ML_REGIME_VOLATILE && je.outcome == ML_OUTCOME_LOSS)
      {
         lesson.category = "Regime";
         lesson.description = "Losses in volatile regime — consider filtering";
         lesson.impact = -0.8;
         AddLesson(lesson);
      }
   }

   void AddLesson(const ML_Lesson &lesson)
   {
      // Check if similar lesson exists
      for(int i = 0; i < m_lessonCount; i++)
      {
         if(m_lessons[i].category == lesson.category &&
            m_lessons[i].description == lesson.description)
         {
            m_lessons[i].occurrenceCount++;
            m_lessons[i].impact = (m_lessons[i].impact + lesson.impact) / 2.0;
            return;
         }
      }
      ArrayResize(m_lessons, m_lessonCount + 1);
      m_lessons[m_lessonCount] = lesson;
      m_lessonCount++;
   }

   string GetTopLesson()
   {
      if(m_lessonCount == 0) return "No lessons yet";
      int bestIdx = 0;
      double bestImpact = MathAbs(m_lessons[0].impact) * m_lessons[0].occurrenceCount;
      for(int i = 1; i < m_lessonCount; i++)
      {
         double impact = MathAbs(m_lessons[i].impact) * m_lessons[i].occurrenceCount;
         if(impact > bestImpact) { bestIdx = i; bestImpact = impact; }
      }
      return m_lessons[bestIdx].category + ": " + m_lessons[bestIdx].description;
   }

   void SaveLessons()
   {
      int handle = FileOpen(m_folder, FILE_WRITE | FILE_CSV | FILE_ANSI, ',');
      if(handle == INVALID_HANDLE) return;
      for(int i = 0; i < m_lessonCount; i++)
      {
         FileWrite(handle, m_lessons[i].category, m_lessons[i].description,
            DoubleToString(m_lessons[i].impact, 2), m_lessons[i].occurrenceCount, m_lessons[i].created);
      }
      FileClose(handle);
   }

   void LoadLessons()
   {
      int handle = FileOpen(m_folder, FILE_READ | FILE_CSV | FILE_ANSI, ',');
      if(handle == INVALID_HANDLE) return;
      m_lessonCount = 0;
      while(!FileIsEnding(handle))
      {
         ML_Lesson l;
         l.category = FileReadString(handle);
         l.description = FileReadString(handle);
         l.impact = FileReadNumber(handle);
         l.occurrenceCount = (int)FileReadNumber(handle);
         l.created = (datetime)FileReadNumber(handle);
         ArrayResize(m_lessons, m_lessonCount + 1);
         m_lessons[m_lessonCount] = l;
         m_lessonCount++;
      }
      FileClose(handle);
   }

   int GetLessonCount() { return m_lessonCount; }
};

#endif // __ML_LEARNING_BREAKOUTEA_MQH__
