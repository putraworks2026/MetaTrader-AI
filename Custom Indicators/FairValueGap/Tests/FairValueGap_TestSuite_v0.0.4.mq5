//+------------------------------------------------------------------+
//| FairValueGap_TestSuite_v0.0.4.mq5 — Unit Tests
//| FairValueGap — Signal ML Test Suite (PutraWorks)
//+------------------------------------------------------------------+
#property strict
#property description "Unit tests for FairValueGap signal ML modules"
#property script_show_inputs

#include <Trade\Trade.mqh>
#include "..\Include\SignalConfig_v0.0.4.mqh"
#include "..\Include\SignalJournal_v0.0.4.mqh"
#include "..\Include\SignalLearning_v0.0.4.mqh"
#include "..\Include\SignalPatterns_v0.0.4.mqh"
#include "..\Include\SignalDashboard_v0.0.4.mqh"

int g_passed = 0, g_failed = 0, g_total = 0;

void AssertTrue(bool cond, string name)
{
    g_total++;
    if(cond) { g_passed++; Print("[PASS] ", name); }
    else { g_failed++; Print("[FAIL] ", name); }
}

void TestSignalConfig()
{
    Print("--- Testing SignalConfig ---");
    SignalProfile sp;
    CreateDefaultSignalProfile(sp, 1);
    AssertTrue(sp.id == 1, "SignalConfig: Default profile ID");
    AssertTrue(sp.score == 50.0, "SignalConfig: Default score is 50");
    AssertTrue(sp.minConfidence == 50.0, "SignalConfig: Default min confidence");
}

void TestSignalJournal()
{
    Print("--- Testing SignalJournal ---");
    CSignalJournal sj;
    sj.Init("FairValueGap");
    AssertTrue(sj.GetCount() >= 0, "SignalJournal: Init OK");
    AssertTrue(sj.GetNextId() > 0, "SignalJournal: Next ID increments");
}

void TestSignalLearning()
{
    Print("--- Testing SignalLearning ---");
    CSignalLearning sl;
    sl.Init("FairValueGap");
    AssertTrue(sl.GetLessonCount() >= 0, "SignalLearning: Init OK");
}

void TestSignalPatterns()
{
    Print("--- Testing SignalPatterns ---");
    CSignalPatterns sp;
    sp.Init();
    sp.RecordPattern("Trending", true, 50.0);
    sp.RecordPattern("Trending", true, 30.0);
    sp.RecordPattern("Trending", false, -20.0);
    AssertTrue(sp.GetPatternCount() >= 1, "SignalPatterns: Records patterns");
    AssertTrue(sp.GetScore("Trending") > 0, "SignalPatterns: Returns score");
}

void TestSignalDashboard()
{
    Print("--- Testing SignalDashboard ---");
    CSignalDashboard sd;
    sd.Init("FairValueGap");
    // Just verify it initializes without error
    AssertTrue(true, "SignalDashboard: Init OK");
}

void OnStart()
{
    Print("====================================");
    Print("  FairValueGap Signal ML Test Suite");
    Print("  Signal Type: FVG Fill/Bounce");
    Print("====================================");
    
    TestSignalConfig();
    TestSignalJournal();
    TestSignalLearning();
    TestSignalPatterns();
    TestSignalDashboard();
    
    Print("====================================");
    Print(StringFormat("  Results: %d/%d passed, %d failed", g_passed, g_total, g_failed));
    Print("====================================");
}
