//+------------------------------------------------------------------+
//| ExecConfig_v0.0.4.mqh — CloseAllTrades Execution Configuration
//| Copyright 2026, PutraWorks
//| Action: Close Positions
//+------------------------------------------------------------------+
#ifndef CLOSEALLTRADES_EXEC_CONFIG_MQH
#define CLOSEALLTRADES_EXEC_CONFIG_MQH

enum ENUM_EXEC_RESULT { EXEC_PENDING=0, EXEC_SUCCESS=1, EXEC_PARTIAL=2, EXEC_FAILED=3, EXEC_CANCELLED=4 };

struct ExecStats
{
   int totalRuns; int successes; int failures; int partials;
   double totalExecTime; double avgExecTime; datetime lastRun;
};

void InitExecStats(ExecStats &es) { es.totalRuns=0; es.successes=0; es.failures=0; es.partials=0; es.totalExecTime=0; es.avgExecTime=0; es.lastRun=0; }
void UpdateExecStats(ExecStats &es, ENUM_EXEC_RESULT result, double execTime)
{
   es.totalRuns++;
   if(result==EXEC_SUCCESS) es.successes++; else if(result==EXEC_FAILED) es.failures++; else if(result==EXEC_PARTIAL) es.partials++;
   es.totalExecTime+=execTime; es.avgExecTime=es.totalExecTime/es.totalRuns; es.lastRun=TimeCurrent();
}
double GetSuccessRate(const ExecStats &es) { if(es.totalRuns==0) return 0; return (double)es.successes/es.totalRuns*100.0; }

#endif // CLOSEALLTRADES_EXEC_CONFIG_MQH
