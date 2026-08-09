//+------------------------------------------------------------------+
//|                                        OrderManager.mqh       |
//|                              MetaTrader AI - Libraries           |
//|          #2 — Safe order sending with safety checks              |
//+------------------------------------------------------------------+
#ifndef __ORDERMANAGER_MQH__
#define __ORDERMANAGER_MQH__

#property copyright "MetaTrader AI"
#property version   "1.02"

#include <Trade/Trade.mqh>

//--- Extended trade manager with safety checks
class COrderManager
{
private:
    CTrade        m_trade;
    int           m_maxSlippage;
    string        m_magicComment;
    ulong         m_magicNumber;

public:
    COrderManager() : m_maxSlippage(30), m_magicComment("Auto")
    {
        m_trade.SetDeviationInPoints(m_maxSlippage);
    }

    void SetSlippage(int slippage)
    {
        m_maxSlippage = slippage;
        m_trade.SetDeviationInPoints(slippage);
    }

    void SetComment(string comment)  { m_magicComment = comment; }
    void SetMagic(ulong magic)       { m_trade.SetExpertMagicNumber(magic); }

    //--- Open buy with automatic SL/TP
    bool OpenBuy(string symbol, double lots, double slPips, double tpPips)
    {
        if(!ValidateSymbol(symbol)) return false;
        if(!ValidateVolume(symbol, lots)) return false;

        double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double sl = (slPips > 0)  ? ask - slPips * point * 10 : 0;
        double tp = (tpPips > 0)  ? ask + tpPips * point * 10 : 0;

        sl = NormalizeDouble(sl, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
        tp = NormalizeDouble(tp, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));

        if(m_trade.Buy(lots, symbol, ask, sl, tp, m_magicComment))
        {
            PrintFormat("BUY opened: %s %.2f lots @ %.5f | SL: %.5f | TP: %.5f",
                        symbol, lots, ask, sl, tp);
            return true;
        }
        else
        {
            PrintFormat("BUY FAILED: %s — %s", symbol, m_trade.ResultRetcodeDescription());
            return false;
        }
    }

    //--- Open sell with automatic SL/TP
    bool OpenSell(string symbol, double lots, double slPips, double tpPips)
    {
        if(!ValidateSymbol(symbol)) return false;
        if(!ValidateVolume(symbol, lots)) return false;

        double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double sl = (slPips > 0)  ? bid + slPips * point * 10 : 0;
        double tp = (tpPips > 0)  ? bid - tpPips * point * 10 : 0;

        sl = NormalizeDouble(sl, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
        tp = NormalizeDouble(tp, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));

        if(m_trade.Sell(lots, symbol, bid, sl, tp, m_magicComment))
        {
            PrintFormat("SELL opened: %s %.2f lots @ %.5f | SL: %.5f | TP: %.5f",
                        symbol, lots, bid, sl, tp);
            return true;
        }
        else
        {
            PrintFormat("SELL FAILED: %s — %s", symbol, m_trade.ResultRetcodeDescription());
            return false;
        }
    }

    //--- Close a specific position by ticket
    bool ClosePosition(ulong ticket)
    {
        if(!PositionSelectByTicket(ticket)) return false;
        if(m_trade.PositionClose(ticket))
        {
            PrintFormat("Position #%I64u closed", ticket);
            return true;
        }
        PrintFormat("Close FAILED: #%I64u — %s", ticket, m_trade.ResultRetcodeDescription());
        return false;
    }

    //--- Close all positions for a symbol
    int CloseAllSymbol(string symbol)
    {
        int closed = 0;
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            ulong ticket = PositionGetTicket(i);
            if(ticket == 0) continue;
            if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
            if(m_trade.PositionClose(ticket)) closed++;
        }
        return closed;
    }

    //--- Close all positions
    int CloseAll()
    {
        int closed = 0;
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            ulong ticket = PositionGetTicket(i);
            if(ticket == 0) continue;
            if(m_trade.PositionClose(ticket)) closed++;
        }
        return closed;
    }

    //--- Modify SL/TP
    bool ModifySLTP(ulong ticket, double newSL, double newTP)
    {
        if(!PositionSelectByTicket(ticket)) return false;
        string symbol = PositionGetString(POSITION_SYMBOL);
        int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        newSL = NormalizeDouble(newSL, digits);
        newTP = NormalizeDouble(newTP, digits);
        return m_trade.PositionModify(ticket, newSL, newTP);
    }

    //--- Partial close
    bool PartialClose(ulong ticket, double volume)
    {
        return m_trade.PositionClosePartial(ticket, volume);
    }

    //--- Trailing stop
    bool TrailingStop(ulong ticket, double trailPips)
    {
        if(!PositionSelectByTicket(ticket)) return false;

        string symbol = PositionGetString(POSITION_SYMBOL);
        long   type   = PositionGetInteger(POSITION_TYPE);
        double currentSL = PositionGetDouble(POSITION_SL);
        double currentTP = PositionGetDouble(POSITION_TP);
        double bid  = SymbolInfoDouble(symbol, SYMBOL_BID);
        double ask  = SymbolInfoDouble(symbol, SYMBOL_ASK);
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double trailDist = trailPips * point * 10;

        int stopsLevel = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
        double minDist = stopsLevel * point;

        if(type == POSITION_TYPE_BUY)
        {
            double newSL = bid - trailDist;
            if(newSL <= currentSL || newSL <= bid - minDist) return false;
            return m_trade.PositionModify(ticket, newSL, currentTP);
        }
        else
        {
            double newSL = ask + trailDist;
            if(currentSL > 0 && newSL >= currentSL) return false;
            if(newSL < ask + minDist) return false;
            return m_trade.PositionModify(ticket, newSL, currentTP);
        }
    }

    //--- Count open positions by symbol
    int CountPositions(string symbol)
    {
        int count = 0;
        for(int i = 0; i < PositionsTotal(); i++)
        {
            ulong ticket = PositionGetTicket(i);
            if(ticket == 0) continue;
            if(PositionGetString(POSITION_SYMBOL) == symbol) count++;
        }
        return count;
    }

    //--- Get total floating P/L
    double GetTotalProfit()
    {
        double total = 0;
        for(int i = 0; i < PositionsTotal(); i++)
        {
            ulong ticket = PositionGetTicket(i);
            if(ticket == 0) continue;
            total += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        }
        return total;
    }

private:
    bool ValidateSymbol(string symbol)
    {
        if(!SymbolInfoDouble(symbol, SYMBOL_BID)) return false;
        return SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_DISABLED;
    }

    bool ValidateVolume(string symbol, double volume)
    {
        double minVol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
        double maxVol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
        double step   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
        if(volume < minVol || volume > maxVol) return false;
        double normalized = MathRound(volume / step) * step;
        return MathAbs(normalized - volume) < step / 2;
    }
};

#endif // __ORDERMANAGER_MQH__
