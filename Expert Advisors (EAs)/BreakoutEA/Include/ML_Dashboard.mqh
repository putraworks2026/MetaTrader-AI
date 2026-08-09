//+------------------------------------------------------------------+
//| ML_Dashboard.mqh — On-Chart ML Dashboard
//| Part of: BreakoutEA v0.0.3
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef __ML_DASHBOARD_BREAKOUTEA_MQH__
#define __ML_DASHBOARD_BREAKOUTEA_MQH__

class CMLDashboard
{
private:
   string   m_prefix;
   int      m_x;
   int      m_y;
   color    m_bgColor;
   color    m_textColor;
   color    m_positiveColor;
   color    m_negativeColor;
public:
   void Init(string toolName, int x = 10, int y = 20)
   {
      m_prefix = toolName + "_ML_";
      m_x = x; m_y = y;
      m_bgColor = clrBlack;
      m_textColor = clrWhite;
      m_positiveColor = clrLimeGreen;
      m_negativeColor = clrCrimson;
   }

   void Update(string profileSummary, int lessonCount, int patternCount, int pendingChanges)
   {
      // Background panel
      string bgName = m_prefix + "bg";
      ObjectDelete(0, bgName);
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, m_x);
      ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, m_y);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE, 280);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE, 100);
      ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, m_bgColor);
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bgName, OBJPROP_COLOR, clrDimGray);

      // Title
      CreateLabel(m_prefix + "title", "ML Engine", m_x + 10, m_y + 5, clrGold, 10);
      // Profile summary
      CreateLabel(m_prefix + "profile", profileSummary, m_x + 10, m_y + 25, m_textColor, 8);
      // Stats line
      string stats = StringFormat("Lessons: %d | Patterns: %d | Pending: %d",
         lessonCount, patternCount, pendingChanges);
      CreateLabel(m_prefix + "stats", stats, m_x + 10, m_y + 45, m_textColor, 8);
      // Footer
      CreateLabel(m_prefix + "footer", "PutraWorks ML Engine v0.0.3", m_x + 10, m_y + 80, clrDimGray, 7);
   }

   void CreateLabel(string name, string text, int x, int y, color clr, int fontSize)
   {
      ObjectDelete(0, name);
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   }

   void Cleanup()
   {
      ObjectsDeleteAll(0, m_prefix);
   }
};

#endif // __ML_DASHBOARD_BREAKOUTEA_MQH__
