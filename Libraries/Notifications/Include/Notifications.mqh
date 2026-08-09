//+------------------------------------------------------------------+
//|                                        Notifications.mqh      |
//|                              MetaTrader AI - Libraries           |
//|          #3 — Push, email, sound, on-chart alerts                 |
//+------------------------------------------------------------------+
#ifndef __NOTIFICATIONS_MQH__
#define __NOTIFICATIONS_MQH__

#property copyright "MetaTrader AI"
#property version   "1.01"

//--- Notification configuration
struct NotifyConfig
{
    bool     enableSound;
    bool     enableAlert;
    bool     enablePush;
    bool     enableEmail;
    bool     enableChart;
    string   soundFile;
    string   emailSubject;
    color    chartAlertColor;
    int      chartAlertFontSize;
    int      maxAlertsPerMin;
};

NotifyConfig CreateDefaultNotifyConfig()
{
    NotifyConfig cfg;
    cfg.enableSound       = true;
    cfg.enableAlert       = true;
    cfg.enablePush        = false;
    cfg.enableEmail       = false;
    cfg.enableChart       = true;
    cfg.soundFile         = "alert.wav";
    cfg.emailSubject      = "EA Alert";
    cfg.chartAlertColor   = clrYellow;
    cfg.chartAlertFontSize = 10;
    cfg.maxAlertsPerMin   = 10;
    return cfg;
}

//--- Rate limiter
string   g_alertTimes[];
int      g_alertCount = 0;

bool RateLimited(NotifyConfig &cfg)
{
    datetime now = TimeCurrent();
    datetime cutoff = now - 60;

    // Remove old entries
    for(int i = g_alertCount - 1; i >= 0; i--)
    {
        if((datetime)StringToInteger(g_alertTimes[i]) < cutoff)
        {
            for(int j = i; j < g_alertCount - 1; j++) g_alertTimes[j] = g_alertTimes[j+1];
            g_alertCount--;
        }
    }

    if(g_alertCount >= cfg.maxAlertsPerMin) return true;

    ArrayResize(g_alertTimes, g_alertCount + 1);
    g_alertTimes[g_alertCount] = IntegerToString(now);
    g_alertCount++;
    return false;
}

//--- Main notification function
void Notify(NotifyConfig &cfg, string message, string chartPrefix = "ALERT")
{
    if(RateLimited(cfg))
    {
        Print("NOTIFY: Rate limited, skipping: ", message);
        return;
    }

    string timestamp = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES);
    string fullMsg = StringFormat("[%s] %s", timestamp, message);

    // Sound
    if(cfg.enableSound)
        PlaySound(cfg.soundFile);

    // Terminal alert
    if(cfg.enableAlert)
        Alert(fullMsg);

    // Push notification
    if(cfg.enablePush)
        SendNotification(fullMsg);

    // Email
    if(cfg.enableEmail)
        SendMail(cfg.emailSubject, fullMsg);

    // On-chart text
    if(cfg.enableChart)
        ShowChartAlert(chartPrefix, fullMsg, cfg);

    // Always log
    Print("NOTIFY: ", fullMsg);
}

//--- Show alert text on chart
void ShowChartAlert(string prefix, string message, NotifyConfig &cfg)
{
    // Find a free object name
    int id = 0;
    string name = prefix + "_0";
    while(ObjectFind(0, name) >= 0)
    {
        name = prefix + "_" + IntegerToString(++id);
    }

    // Create text label at bottom of chart
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 20 + id * (cfg.chartAlertFontSize + 4));
    ObjectSetString(0, name, OBJPROP_TEXT, message);
    ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, cfg.chartAlertFontSize);
    ObjectSetInteger(0, name, OBJPROP_COLOR, cfg.chartAlertColor);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

    // Auto-remove after 60 seconds (call ClearOldAlerts in OnTimer)
    ObjectSetInteger(0, name, OBJPROP_TIME, TimeCurrent());
}

//--- Clear old chart alerts (call from OnTimer)
void ClearOldAlerts(string prefix, int maxAgeSec = 60)
{
    datetime now = TimeCurrent();
    int total = ObjectsTotal(0, 0, OBJ_LABEL);

    for(int i = total - 1; i >= 0; i--)
    {
        string name = ObjectName(0, i, 0, OBJ_LABEL);
        if(StringFind(name, prefix) != 0) continue;

        datetime created = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME);
        if(now - created > maxAgeSec)
            ObjectDelete(0, name);
    }
}

//--- Clear all chart alerts
void ClearAllAlerts(string prefix)
{
    ObjectsDeleteAll(0, prefix);
}

//--- Convenience wrappers
void NotifyTrade(NotifyConfig &cfg, string action, string symbol, double lots, double price, string extra = "")
{
    string msg = StringFormat("%s %s %.2f lots @ %.5f %s", action, symbol, lots, price, extra);
    Notify(cfg, msg, "TRADE");
}

void NotifyRisk(NotifyConfig &cfg, string warning)
{
    string msg = "RISK WARNING: " + warning;
    Notify(cfg, msg, "RISK");
}

void NotifySignal(NotifyConfig &cfg, string signalType, string symbol, string details)
{
    string msg = StringFormat("SIGNAL: %s on %s — %s", signalType, symbol, details);
    Notify(cfg, msg, "SIGNAL");
}

#endif // __NOTIFICATIONS_MQH__
