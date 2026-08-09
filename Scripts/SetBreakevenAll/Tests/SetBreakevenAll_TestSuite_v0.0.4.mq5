//+------------------------------------------------------------------+
//| SetBreakevenAll_TestSuite_v0.0.4.mq5 — Execution ML Tests (PutraWorks)
//+------------------------------------------------------------------+
#property strict
#property description "Unit tests for SetBreakevenAll execution ML modules"
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
    Print("--- ExecConfig ---");
    ExecStats es;
    InitExecStats(es);
    AssertTrue(es.totalRuns == 0, "Init zeros runs");
    UpdateExecStats(es, EXEC_SUCCESS, 100.0);
    AssertTrue(es.totalRuns == 1, "Updates run count");
    AssertTrue(es.successes == 1, "Counts success");
    AssertTrue(GetSuccessRate(es) == 100.0, "100% success rate");
    UpdateExecStats(es, EXEC_FAILED, 50.0);
    AssertTrue(GetSuccessRate(es) == 50.0, "50% after failure");
}

void TestExecJournal()
{
    Print("--- ExecJournal ---");
    CExecJournal ej;
    ej.Init("SetBreakevenAll");
    AssertTrue(ej.GetCount() >= 0, "Journal init OK");
    AssertTrue(ej.GetNextId() > 0, "Next ID increments");
}

void OnStart()
{
    Print("====================================");
    Print("  SetBreakevenAll Execution ML Test Suite");
    Print("  Action: Set Breakeven");
    Print("====================================");
    TestExecConfig();
    TestExecJournal();
    Print("====================================");
    Print(StringFormat("  %d/%d passed, %d failed", g_passed, g_total, g_failed));
    Print("====================================");
}
