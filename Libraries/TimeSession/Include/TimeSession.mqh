//+------------------------------------------------------------------+
//|                                         TimeSession.mqh      |
//|                              MetaTrader AI - Libraries           |
//|          #5 — Session detection, timezone, market hours         |
//+------------------------------------------------------------------+
#ifndef __TIMESESSION_MQH__
#define __TIMESESSION_MQH__

#property copyright "MetaTrader AI"
#property version   "1.01"

//--- Session definitions (broker time hours)
struct TradingSession
{
    string   name;
    int      startHour;
    int      startMin;
    int      endHour;
    int      endMin;
    bool     enabled;
    color    sessionColor;
};

//--- Predefined sessions (adjust hours to your broker's server time)
TradingSession CreateAsianSession()
{
    TradingSession s;
    s.name = "Asian";    s.startHour = 0;  s.startMin = 0;
    s.endHour = 7;        s.endMin = 0;
    s.enabled = true;    s.sessionColor = clrDarkSlateGray;
    return s;
}

TradingSession CreateLondonSession()
{
    TradingSession s;
    s.name = "London";    s.startHour = 7;  s.startMin = 0;
    s.endHour = 16;       s.endMin = 0;
    s.enabled = true;    s.sessionColor = clrDodgerBlue;
    return s;
}

TradingSession CreateNYSession()
{
    TradingSession s;
    s.name = "New York";  s.startHour = 12; s.startMin = 0;
    s.endHour = 20;       s.endMin = 0;
    s.enabled = true;    s.sessionColor = clrCrimson;
    return s;
}

//--- Check if current time is within a session
bool IsInSession(TradingSession &session, datetime t = 0)
{
    if(!session.enabled) return false;
    if(t == 0) t = TimeCurrent();

    MqlDateTime dt;
    TimeToStruct(t, dt);

    int currentMinutes = dt.hour * 60 + dt.min;
    int startMinutes = session.startHour * 60 + session.startMin;
    int endMinutes   = session.endHour * 60 + session.endMin;

    // Handle sessions that cross midnight
    if(startMinutes < endMinutes)
        return (currentMinutes >= startMinutes && currentMinutes < endMinutes);
    else
        return (currentMinutes >= startMinutes || currentMinutes < endMinutes);
}

//--- Get current session name(s)
string GetCurrentSession()
{
    TradingSession asia = CreateAsianSession();
    TradingSession london = CreateLondonSession();
    TradingSession ny = CreateNYSession();

    string sessions = "";
    if(IsInSession(asia))   sessions += "Asian ";
    if(IsInSession(london)) sessions += "London ";
    if(IsInSession(ny))     sessions += "New York ";
    if(sessions == "") sessions = "Off-Session";
    return sessions;
}

//--- Check if market is active (any session open)
bool IsMarketActive()
{
    TradingSession asia = CreateAsianSession();
    TradingSession london = CreateLondonSession();
    TradingSession ny = CreateNYSession();
    return (IsInSession(asia) || IsInSession(london) || IsInSession(ny));
}

//--- Check if a specific time is within market hours
bool IsMarketHours(int hour, int minute)
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    dt.hour = hour;
    dt.min = minute;
    datetime t = StructToTime(dt);
    return IsMarketActive();
}

//--- Get seconds until session starts
int SecondsUntilSession(TradingSession &session)
{
    MqlDateTime now;
    TimeToStruct(TimeCurrent(), now);
    int currentMin = now.hour * 60 + now.min;
    int targetMin = session.startHour * 60 + session.startMin;

    int diff = targetMin - currentMin;
    if(diff < 0) diff += 24 * 60;
    return diff * 60;
}

//--- Get seconds until session ends
int SecondsUntilSessionEnd(TradingSession &session)
{
    if(!IsInSession(session)) return -1;

    MqlDateTime now;
    TimeToStruct(TimeCurrent(), now);
    int currentMin = now.hour * 60 + now.min;
    int targetMin = session.endHour * 60 + session.endMin;

    int diff = targetMin - currentMin;
    if(diff < 0) diff += 24 * 60;
    return diff * 60;
}

//--- Check if it's a trading day (Monday=1 ... Friday=5)
bool IsTradingDay(datetime t = 0)
{
    if(t == 0) t = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(t, dt);
    return (dt.day_of_week >= 1 && dt.day_of_week <= 5);
}

//--- Check if it's Friday (avoid late trades)
bool IsFriday(datetime t = 0)
{
    if(t == 0) t = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(t, dt);
    return (dt.day_of_week == 5);
}

//--- Get broker offset from UTC (in hours)
int GetBrokerUTCOffset()
{
    // GMT offset = (broker time - UTC) in hours
    // Use TimeGMT() and TimeCurrent() to calculate
    datetime gmt = TimeGMT();
    datetime broker = TimeCurrent();
    int diff = (int)((broker - gmt) / 3600);
    return diff;
}

//--- Convert broker time to UTC
datetime BrokerToUTC(datetime brokerTime)
{
    return brokerTime - GetBrokerUTCOffset() * 3600;
}

//--- Convert UTC to broker time
datetime UTCToBroker(datetime utcTime)
{
    return utcTime + GetBrokerUTCOffset() * 3600;
}

//--- Get day of week as string
string GetDayName(datetime t = 0)
{
    if(t == 0) t = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(t, dt);
    string days[] = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
    if(dt.day_of_week >= 0 && dt.day_of_week <= 6) return days[dt.day_of_week];
    return "Unknown";
}

//--- Format duration in human-readable format
string FormatDuration(int seconds)
{
    int days    = seconds / 86400;
    int hours   = (seconds % 86400) / 3600;
    int minutes = (seconds % 3600) / 60;
    int secs    = seconds % 60;

    if(days > 0) return StringFormat("%dd %dh %dm", days, hours, minutes);
    if(hours > 0) return StringFormat("%dh %dm %ds", hours, minutes, secs);
    if(minutes > 0) return StringFormat("%dm %ds", minutes, secs);
    return StringFormat("%ds", secs);
}

//--- Session overlap detection (high volatility periods)
bool IsSessionOverlap()
{
    TradingSession london = CreateLondonSession();
    TradingSession ny = CreateNYSession();
    return (IsInSession(london) && IsInSession(ny));
}

//--- Check if close to session end (within N minutes)
bool IsNearSessionEnd(int minutesBefore = 15)
{
    TradingSession london = CreateLondonSession();
    TradingSession ny = CreateNYSession();

    if(IsInSession(london))
    {
        int remaining = SecondsUntilSessionEnd(london);
        if(remaining > 0 && remaining <= minutesBefore * 60) return true;
    }
    if(IsInSession(ny))
    {
        int remaining = SecondsUntilSessionEnd(ny);
        if(remaining > 0 && remaining <= minutesBefore * 60) return true;
    }
    return false;
}

#endif // __TIMESESSION_MQH__
