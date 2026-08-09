//+------------------------------------------------------------------+
//| Dashboard_v0.0.4.mqh — BreakoutEA On-Chart Display
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef BREAKOUTEA_DASHBOARD_MQH
#define BREAKOUTEA_DASHBOARD_MQH

#include "Config_v0.0.4.mqh"

class CDashboard
{
private: string m_pre; int m_x,m_y;
public:
   void Init(string tool, int x=10, int y=20) { m_pre=tool+"_d_"; m_x=x; m_y=y; }
   void Update(string prof, int lessons, int pats, int pending, double pnl)
   { Cleanup(); string bg=m_pre+"bg"; ObjectCreate(0,bg,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0,bg,OBJPROP_CORNER,CORNER_LEFT_UPPER); ObjectSetInteger(0,bg,OBJPROP_XDISTANCE,m_x); ObjectSetInteger(0,bg,OBJPROP_YDISTANCE,m_y);
      ObjectSetInteger(0,bg,OBJPROP_XSIZE,300); ObjectSetInteger(0,bg,OBJPROP_YSIZE,110); ObjectSetInteger(0,bg,OBJPROP_BGCOLOR,C'20,20,20');
      ObjectSetInteger(0,bg,OBJPROP_BORDER_TYPE,BORDER_FLAT); ObjectSetInteger(0,bg,OBJPROP_COLOR,clrDimGray);
      L(m_pre+"t","BreakoutEA ML",m_x+10,m_y+5,clrGold,10); L(m_pre+"p",prof,m_x+10,m_y+25,clrWhite,8);
      L(m_pre+"s",StringFormat("L:%d P:%d Pen:%d",lessons,pats,pending),m_x+10,m_y+45,clrSilver,8);
      L(m_pre+"pnl",StringFormat("P&L: %.2f",pnl),m_x+10,m_y+65,(pnl>=0?clrLimeGreen:clrCrimson),8);
      L(m_pre+"f","PutraWorks v0.0.4",m_x+10,m_y+90,clrDimGray,7); }
   void L(string n, string t, int x, int y, color c, int fs) { ObjectCreate(0,n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER); ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y); ObjectSetString(0,n,OBJPROP_TEXT,t); ObjectSetInteger(0,n,OBJPROP_COLOR,c); ObjectSetInteger(0,n,OBJPROP_FONTSIZE,fs); ObjectSetString(0,n,OBJPROP_FONT,"Consolas"); }
   void Cleanup() { ObjectsDeleteAll(0,m_pre); }
};

#endif // BREAKOUTEA_DASHBOARD_MQH
