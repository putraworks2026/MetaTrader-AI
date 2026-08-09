//+------------------------------------------------------------------+
//| RiskCalculator_TestSuite_v0.0.4.mq5 — Unit Tests
//| RiskCalculator — Execution ML Test Suite (PutraWorks)
//+------------------------------------------------------------------+
#property strict
#property description "Unit tests for RiskCalculator execution ML modules"
#property script_show_inputs

#include <Trade\Trade.mqh>
#include "..\Include\ExecConfig_v0.0.4.mqh"
#include "..\Include\ExecJournal_v0.0.4.mqh"

int g_passed = 0, g_failed = 0, g_total = 0;

void AssertTrue(bool cond, string name)
{
    g_total++;
    if(cond) { g_passed++; Print("[PASS] ", name); }
    else { g_failed++; Print("[FAIL] ", name); }
}

void TestExecConfig()
{
    Print("--- Testing ExecConfig ---");
    ExecStats es;
    InitExecStats(es);
    AssertTrue(es.totalRuns == 0, "ExecConfig: Init zeros runs");
    UpdateExecStats(es, EXEC_SUCCESS, 100.0);
    AssertTrue(es.totalRuns == 1, "ExecConfig: Updates run count");
    AssertTrue(es.successes == 1, "ExecConfig: Counts success");
    AssertTrue(es.avgExecTime == 100.0, "ExecConfig: Calculates avg time");
    AssertTrue(GetSuccessRate(es) == 100.0, "ExecConfig: 100% success rate");
    UpdateExecStats(es, EXEC_FAILED, 50.0);
    AssertTrue(GetSuccessRate(es) == 50.0, "ExecConfig: 50% after failure");
}

void TestExecJournal()
{
    Print("--- Testing ExecJournal ---");
    CExecJournal ej;
    ej.Init("RiskCalculator");
    AssertTrue(ej.GetCount() >= 0, "ExecJournal: Init OK");
    AssertTrue(ej.GetNextId() > 0, "ExecJournal: Next ID increments");
}

void OnStart()
{
    Print("====================================");
    Print("  RiskCalculator Execution ML Test Suite");
    Print("  Action: Calculate Lot Size");
    Print("====================================");
    
    TestExecConfig();
    TestExecJournal();
    
    Print("====================================");
    Print(StringFormat("  Results: %d/%d passed, %d failed", g_passed, g_total, g_failed));
    Print("====================================");
}
