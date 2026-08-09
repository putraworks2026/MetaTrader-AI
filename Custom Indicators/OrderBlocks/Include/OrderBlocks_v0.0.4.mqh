//+------------------------------------------------------------------+
//| OrderBlocks.mqh — Include file for OrderBlocks
//| MetaTrader AI — Function Library
//| Version: v0.0.3
//+------------------------------------------------------------------+
#ifndef __ORDERBLOCKS_MQH__
#define __ORDERBLOCKS_MQH__

//+------------------------------------------------------------------+
//|                                              OrderBlocks.mq5     |
//|                              MetaTrader AI - Custom Indicators   |
//|          Ranks #2 — Identifies ICT Order Blocks on chart         |
//+------------------------------------------------------------------+

//--- Input parameters

//--- Globals
struct OrderBlock
{
    double   high;
    double   low;
    datetime time;
    bool     is_bullish;  // Bullish OB = last bearish candle before bullish impulse
    bool     mitigated;   // Has price returned to test it?
    string   name;
};

OrderBlock g_blocks[];
int        g_blockCount = 0;
datetime   g_lastBarTime = 0;

//+------------------------------------------------------------------+

void DrawBlocks(datetime endTime)
{
    ObjectsDeleteAll(0, "OB_");

    for(int b = 0; b < g_blockCount; b++)
    {
        if(g_blocks[b].mitigated && InpRemoveMitted) continue;

        string rectName = "OB_Rect_" + IntegerToString(b);
        string labelName = "OB_Label_" + IntegerToString(b);

        ObjectCreate(0, rectName, OBJ_RECTANGLE, 0,
                     g_blocks[b].time, g_blocks[b].high,
                     endTime, g_blocks[b].low);

        color clr = g_blocks[b].is_bullish ? InpBullOBColor : InpBearOBColor;
        ObjectSetInteger(0, rectName, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, rectName, OBJPROP_BACK, InpFill);
        ObjectSetInteger(0, rectName, OBJPROP_FILL, InpFill);
        ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, rectName, OBJPROP_HIDDEN, true);

        if(InpShowLabels)
        {
            string label = g_blocks[b].is_bullish ? "Bull OB" : "Bear OB";
            ObjectCreate(0, labelName, OBJ_TEXT, 0, g_blocks[b].time, g_blocks[b].high);
            ObjectSetString(0, labelName, OBJPROP_TEXT, label);
            ObjectSetInteger(0, labelName, OBJPROP_COLOR, clr);
            ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 7);
            ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
        }
    }
}

#endif // __ORDERBLOCKS_MQH__
