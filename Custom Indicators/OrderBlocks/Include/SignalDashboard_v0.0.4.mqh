//+------------------------------------------------------------------+
//| SignalDashboard_v0.0.4.mqh — OrderBlocks Signal Accuracy Display
//| Copyright 2026, PutraWorks
//| Shows: OB Mitigation accuracy stats
//+------------------------------------------------------------------+
#ifndef ORDERBLOCKS_SIGNAL_DASHBOARD_MQH
#define ORDERBLOCKS_SIGNAL_DASHBOARD_MQH

class CSignalDashboard
{
private:
   string m_prefix; int m_x, m_y;
public:
   void Init(string toolName, int x=10, int y=20) { m_prefix=toolName+"_sdash_"; m_x=x; m_y=y; }
   void Update(string signalType, int totalSignals, int successes, int failures, double successRate, string topInsight, int patternCount)
   {
      Cleanup();
      string bg=m_prefix+"bg"; ObjectCreate(0,bg,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0,bg,OBJPROP_CORNER,CORNER_LEFT_UPPER); ObjectSetInteger(0,bg,OBJPROP_XDISTANCE,m_x); ObjectSetInteger(0,bg,OBJPROP_YDISTANCE,m_y);
      ObjectSetInteger(0,bg,OBJPROP_XSIZE,280); ObjectSetInteger(0,bg,OBJPROP_YSIZE,90); ObjectSetInteger(0,bg,OBJPROP_BGCOLOR,C'20,20,20');
      ObjectSetInteger(0,bg,OBJPROP_BORDER_TYPE,BORDER_FLAT); ObjectSetInteger(0,bg,OBJPROP_COLOR,clrDimGray);
      Lbl(m_prefix+"title","OrderBlocks Signal ML",m_x+10,m_y+5,clrGold,10);
      Lbl(m_prefix+"signal","Signal: OB Mitigation",m_x+10,m_y+22,clrSkyBlue,8);
      color rc=(successRate>=60)?clrLimeGreen:((successRate>=40)?clrOrange:clrCrimson);
      Lbl(m_prefix+"rate",StringFormat("Accuracy: %.1f%% (%d/%d)",successRate,successes,totalSignals),m_x+10,m_y+40,rc,8);
      Lbl(m_prefix+"patterns",StringFormat("Patterns: %d | Failures: %d",patternCount,failures),m_x+10,m_y+58,clrSilver,8);
      Lbl(m_prefix+"insight",topInsight,m_x+10,m_y+76,clrWheat,7);
   }
   void Lbl(string name, string text, int x, int y, color clr, int fs) { ObjectCreate(0,name,OBJ_LABEL,0,0,0); ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER); ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y); ObjectSetString(0,name,OBJPROP_TEXT,text); ObjectSetInteger(0,name,OBJPROP_COLOR,clr); ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fs); ObjectSetString(0,name,OBJPROP_FONT,"Consolas"); }
   void Cleanup() { ObjectsDeleteAll(0,m_prefix); }
};

#endif // ORDERBLOCKS_SIGNAL_DASHBOARD_MQH
