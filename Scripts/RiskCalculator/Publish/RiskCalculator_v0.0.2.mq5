//+------------------------------------------------------------------+
//| RiskCalculator_v0.0.2.mq5 — Publish Entry Point
//| MetaTrader AI — Scripts
//| Version: v0.0.2
//+------------------------------------------------------------------+
#property copyright "MetaTrader AI"
#property version   "1.01"
#property script_show_inputs

#include "../Include/RiskCalculator.mqh"

input double   InpRiskPercent   = 1.0;    // Risk per trade (%)
input double   InpAccountBalance = 0;      // 0 = use current balance
input int      InpStopLossPips   = 50;      // Stop loss distance (pips)
input int      InpTakeProfitPips = 100;     // Take profit distance (pips)
input bool     InpShowPanel      = true;   // Show results on chart
input bool     InpPlaceOrders    = false;   // Place orders automatically
input ENUM_ORDER_TYPE InpDirection = ORDER_TYPE_BUY; // Buy or Sell

void OnStart()
{
    string symbol = _Symbol;

    // Use account balance or custom
    double balance = (InpAccountBalance > 0) ? InpAccountBalance : AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * (InpRiskPercent / 100.0);

    // Get symbol properties
    double pipSize = _Point * 10;  // 1 pip = 10 points
    double slPrice = InpStopLossPips * pipSize;
    double tpPrice = InpTakeProfitPips * pipSize;

    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double volumeMin = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double volumeMax = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double volumeStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

    if(tickSize == 0 || tickValue == 0)
    {
        Print("Error: Cannot get tick value/size for ", symbol);
        return;
    }

    // Calculate lot size: risk / (SL_pips * pip_value_per_lot)
    double slTicks = slPrice / tickSize;
    double lossPerLot = slTicks * tickValue;
    double lotSize = riskAmount / lossPerLot;

    // Normalize to broker volume step
    lotSize = MathRound(lotSize / volumeStep) * volumeStep;
    lotSize = MathMax(volumeMin, lotSize);
    lotSize = MathMin(volumeMax, lotSize);

    // Calculate potential profit
    double tpTicks = tpPrice / tickSize;
    double profitPerLot = tpTicks * tickValue;
    double potentialProfit = lotSize * profitPerLot;
    double potentialLoss = lotSize * lossPerLot;

    // Risk-reward ratio
    double rrRatio = (potentialLoss > 0) ? potentialProfit / potentialLoss : 0;

    string results = StringFormat(
        "══════ RISK CALCULATOR ══════\n"
        "Symbol:         %s\n"
        "Account Balance: %.2f %s\n"
        "Risk Percent:    %.1f%%\n"
        "Risk Amount:     %.2f %s\n\n"
        "Stop Loss:       %d pips (%.5f)\n"
        "Take Profit:     %d pips (%.5f)\n\n"
        "═══════ RESULTS ═══════\n"
        "Lot Size:        %.2f\n"
        "Potential Loss:  %.2f %s\n"
        "Potential Profit: %.2f %s\n"
        "Risk/Reward:     1:%.2f\n"
        "══════════════════════════",
        symbol,
        balance, AccountInfoString(ACCOUNT_CURRENCY),
        InpRiskPercent,
        riskAmount, AccountInfoString(ACCOUNT_CURRENCY),
        InpStopLossPips, slPrice,
        InpTakeProfitPips, tpPrice,
        lotSize,
        potentialLoss, AccountInfoString(ACCOUNT_CURRENCY),
        potentialProfit, AccountInfoString(ACCOUNT_CURRENCY),
        rrRatio
    );

    Print(results);

    if(InpShowPanel)
    {
        Comment(results);
    }

    if(InpPlaceOrders)
    {
        CTrade trade;
        double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
        double price = (InpDirection == ORDER_TYPE_BUY) ? ask : bid;
        double sl = (InpDirection == ORDER_TYPE_BUY) ? price - slPrice : price + slPrice;
        double tp = (InpDirection == ORDER_TYPE_BUY) ? price + tpPrice : price - tpPrice;

        if(InpDirection == ORDER_TYPE_BUY)
            trade.Buy(lotSize, symbol, price, sl, tp, "RiskCalc");
        else
            trade.Sell(lotSize, symbol, price, sl, tp, "RiskCalc");

        PrintFormat("Order placed: %s %.2f lots at %.5f", EnumToString(InpDirection), lotSize, price);
    }
}
