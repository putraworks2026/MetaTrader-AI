//+------------------------------------------------------------------+
//|                                         MathStats.mqh        |
//|                              MetaTrader AI - Libraries           |
////          #4 — ATR, stdev, correlation, z-score helpers          |
//+------------------------------------------------------------------+
#ifndef __MATHSTATS_MQH__
#define __MATHSTATS_MQH__

#property copyright "MetaTrader AI"
#property version   "1.01"

//--- Mean of an array
double ArrayMean(const double &arr[], int count = -1)
{
    int n = (count < 0) ? ArraySize(arr) : count;
    if(n <= 0) return 0;
    double sum = 0;
    for(int i = 0; i < n; i++) sum += arr[i];
    return sum / n;
}

//--- Standard deviation (population)
double ArrayStdDev(const double &arr[], int count = -1)
{
    int n = (count < 0) ? ArraySize(arr) : count;
    if(n <= 1) return 0;
    double mean = ArrayMean(arr, n);
    double sumSq = 0;
    for(int i = 0; i < n; i++)
        sumSq += (arr[i] - mean) * (arr[i] - mean);
    return MathSqrt(sumSq / n);
}

//--- Standard deviation (sample, n-1)
double ArraySampleStdDev(const double &arr[], int count = -1)
{
    int n = (count < 0) ? ArraySize(arr) : count;
    if(n <= 1) return 0;
    double mean = ArrayMean(arr, n);
    double sumSq = 0;
    for(int i = 0; i < n; i++)
        sumSq += (arr[i] - mean) * (arr[i] - mean);
    return MathSqrt(sumSq / (n - 1));
}

//--- Z-score of latest value relative to array
double ZScore(const double &arr[], int count = -1)
{
    int n = (count < 0) ? ArraySize(arr) : count;
    if(n <= 1) return 0;
    double sd = ArrayStdDev(arr, n);
    if(sd == 0) return 0;
    double mean = ArrayMean(arr, n);
    return (arr[n-1] - mean) / sd;
}

//--- Pearson correlation between two arrays
double Correlation(const double &x[], const double &y[], int count = -1)
{
    int n = (count < 0) ? MathMin(ArraySize(x), ArraySize(y)) : count;
    if(n <= 1) return 0;

    double meanX = 0, meanY = 0;
    for(int i = 0; i < n; i++) { meanX += x[i]; meanY += y[i]; }
    meanX /= n; meanY /= n;

    double cov = 0, varX = 0, varY = 0;
    for(int i = 0; i < n; i++)
    {
        cov  += (x[i] - meanX) * (y[i] - meanY);
        varX += (x[i] - meanX) * (x[i] - meanX);
        varY += (y[i] - meanY) * (y[i] - meanY);
    }

    if(varX == 0 || varY == 0) return 0;
    return cov / MathSqrt(varX * varY);
}

//--- ATR (Average True Range) calculation
double CalculateATR(string symbol, ENUM_TIMEFRAMES tf, int period)
{
    int handle = iATR(symbol, tf, period);
    if(handle == INVALID_HANDLE) return 0;

    double atr[];
    ArraySetAsSeries(atr, true);
    if(CopyBuffer(handle, 0, 0, 2, atr) < 2) { IndicatorRelease(handle); return 0; }
    IndicatorRelease(handle);
    return atr[0];
}

//--- Simple Linear Regression (returns slope and intercept)
struct LinRegResult
{
    double slope;
    double intercept;
    double rSquared;
};

LinRegResult LinearRegression(const double &y[], const double &x[], int count)
{
    LinRegResult result;
    result.slope = 0;
    result.intercept = 0;
    result.rSquared = 0;

    if(count <= 1) return result;

    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0, sumYY = 0;
    for(int i = 0; i < count; i++)
    {
        sumX  += x[i];
        sumY  += y[i];
        sumXY += x[i] * y[i];
        sumXX += x[i] * x[i];
        sumYY += y[i] * y[i];
    }

    double denom = count * sumXX - sumX * sumX;
    if(denom == 0) return result;

    result.slope     = (count * sumXY - sumX * sumY) / denom;
    result.intercept = (sumY - result.slope * sumX) / count;

    // R-squared
    double meanY = sumY / count;
    double ssRes = 0, ssTot = 0;
    for(int i = 0; i < count; i++)
    {
        double predicted = result.slope * x[i] + result.intercept;
        ssRes += (y[i] - predicted) * (y[i] - predicted);
        ssTot += (y[i] - meanY) * (y[i] - meanY);
    }
    if(ssTot > 0) result.rSquared = 1 - (ssRes / ssTot);

    return result;
}

//--- RSI calculation
double CalculateRSI(const double &prices[], int period)
{
    int n = ArraySize(prices);
    if(n < period + 1) return 50;

    double gains = 0, losses = 0;
    for(int i = n - period; i < n; i++)
    {
        double change = prices[i] - prices[i-1];
        if(change > 0) gains += change;
        else           losses -= change;
    }

    double avgGain = gains / period;
    double avgLoss = losses / period;

    if(avgLoss == 0) return 100;
    double rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
}

//--- Percentage change between two values
double PercentChange(double oldVal, double newVal)
{
    if(oldVal == 0) return 0;
    return ((newVal - oldVal) / oldVal) * 100;
}

//--- Clamp value to range
double Clamp(double value, double minVal, double maxVal)
{
    return MathMax(minVal, MathMin(maxVal, value));
}

//--- Map value from one range to another
double MapRange(double value, double inMin, double inMax, double outMin, double outMax)
{
    if(inMax - inMin == 0) return outMin;
    return outMin + ((value - inMin) / (inMax - inMin)) * (outMax - outMin);
}

#endif // __MATHSTATS_MQH__
