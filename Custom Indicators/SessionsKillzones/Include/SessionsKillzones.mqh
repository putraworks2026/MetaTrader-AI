//+------------------------------------------------------------------+
//| SessionsKillzones.mqh — Include file for SessionsKillzones
//| MetaTrader AI — Function Library
//| Version: v0.0.2
//+------------------------------------------------------------------+
#ifndef __SESSIONSKILLZONES_MQH__
#define __SESSIONSKILLZONES_MQH__

//+------------------------------------------------------------------+
//|                                SessionsKillzones.mq5            |
//|                              MetaTrader AI - Custom Indicators   |
//|          Ranks #7 — London/NY/Asia session boxes + killzones     |
//+------------------------------------------------------------------+








void DrawSession(string prefix, string dayStr, datetime dayBegin, datetime dayEnd,
                 double dayHigh, double dayLow, int startHour, int endHour, color clr)
{
    datetime boxStart = dayBegin + startHour * 3600;
    datetime boxEnd   = dayBegin + endHour * 3600;
    if(boxEnd > dayEnd) boxEnd = dayEnd;

    string name = "SES_" + prefix + "_" + dayStr;

    ObjectCreate(0, name, OBJ_RECTANGLE, 0, boxStart, dayHigh, boxEnd, dayLow);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_BACK, InpFillBoxes);
    ObjectSetInteger(0, name, OBJPROP_FILL, InpFillBoxes);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

    if(InpShowLabels)
    {
        string lblName = "SES_LBL_" + prefix + "_" + dayStr;
        ObjectCreate(0, lblName, OBJ_TEXT, 0, boxStart, dayHigh);
        ObjectSetString(0, lblName, OBJPROP_TEXT, prefix);
        ObjectSetInteger(0, lblName, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 7);
        ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LEFT);
        ObjectSetInteger(0, lblName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, lblName, OBJPROP_HIDDEN, true);
    }
}

#endif // __SESSIONSKILLZONES_MQH__
