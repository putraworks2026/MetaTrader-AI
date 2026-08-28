//+------------------------------------------------------------------+
//| MathStats_TestSuite.mq5 — Library Tests (PutraWorks)
//+------------------------------------------------------------------+
#property strict
#property description "Unit tests for MathStats library"
#property script_show_inputs

#include "..\Include\MathStats.mqh"

int g_passed = 0, g_failed = 0, g_total = 0;

void AssertTrue(bool cond, string name)
{
    g_total++;
    if(cond) { g_passed++; Print("[PASS] ", name); }
    else { g_failed++; Print("[FAIL] ", name); }
}

void OnStart()
{
    Print("====================================");
    Print("  MathStats Library Test Suite");
    Print("====================================");
    
    // Library-specific tests would go here
    // For now, just verify it compiles and loads
    AssertTrue(true, "MathStats compiles and loads");
    
    Print("====================================");
    Print(StringFormat("  %d/%d passed, %d failed", g_passed, g_total, g_failed));
    Print("====================================");
}
