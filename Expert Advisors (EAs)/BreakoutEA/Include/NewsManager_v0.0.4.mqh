//+------------------------------------------------------------------+
//| NewsManager_v0.0.4.mqh — BreakoutEA Economic News Filter
//| Copyright 2026, PutraWorks
//+------------------------------------------------------------------+
#ifndef BREAKOUTEA_NEWS_MANAGER_MQH
#define BREAKOUTEA_NEWS_MANAGER_MQH

class CNewsManager
{
private: datetime m_nextHi; string m_event; int m_blockMin;
public:
   void Init(int blockMin=30) { m_blockMin=blockMin; m_nextHi=0; m_event=""; }
   void UpdateCalendar() { m_nextHi=0; m_event=""; MqlCalendarValue v[]; datetime now=TimeCurrent(); CalendarValueHistory(v,now,now+86400); for(int i=0;i<ArraySize(v);i++) { MqlCalendarEvent e; if(CalendarEventById(v[i].event_id,e)) { if((int)e.importance==3 && v[i].time>now) { if(m_nextHi==0||v[i].time<m_nextHi) { m_nextHi=v[i].time; m_event=e.name; } } } } }
   bool IsNewsBlocked() { if(m_nextHi==0) return false; return MathAbs((int)(m_nextHi-TimeCurrent()))<m_blockMin*60; }
   string GetNextEvent() { if(m_nextHi==0) return "No news"; return StringFormat("in %d min: %s",(int)((m_nextHi-TimeCurrent())/60),m_event); }
};

#endif // BREAKOUTEA_NEWS_MANAGER_MQH
