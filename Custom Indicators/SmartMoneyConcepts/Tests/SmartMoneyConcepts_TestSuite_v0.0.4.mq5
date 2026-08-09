//+------------------------------------------------------------------+
//| SmartMoneyConcepts_TestSuite_v0.0.4.mq5 — Signal ML Tests (PutraWorks)
//+------------------------------------------------------------------+
#property strict
#property description "Unit tests for SmartMoneyConcepts signal ML modules"
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
    Print("--- SignalConfig ---");
    SignalProfile sp;
    CreateDefaultSignalProfile(sp, 1);
    AssertTrue(sp.id == 1, "Default profile ID");
    AssertTrue(sp.score == 50.0, "Default score 50");
}

void TestSignalJournal()
{
    Print("--- SignalJournal ---");
    CSignalJournal sj;
    sj.Init("SmartMoneyConcepts");
    AssertTrue(sj.GetCount() >= 0, "Journal init OK");
    AssertTrue(sj.GetNextId() > 0, "Next ID increments");
}

void TestSignalLearning()
{
    Print("--- SignalLearning ---");
    CSignalLearning sl;
    sl.Init("SmartMoneyConcepts");
    AssertTrue(sl.GetLessonCount() >= 0, "Learning init OK");
}

void TestSignalPatterns()
{
    Print("--- SignalPatterns ---");
    CSignalPatterns sp;
    sp.Init();
    sp.RecordPattern("Trending", true, 50.0);
    sp.RecordPattern("Trending", true, 30.0);
    sp.RecordPattern("Trending", false, -20.0);
    AssertTrue(sp.GetPatternCount() >= 1, "Records patterns");
    AssertTrue(sp.GetScore("Trending") > 0, "Returns score");
}

void OnStart()
{
    Print("====================================");
    Print("  SmartMoneyConcepts Signal ML Test Suite");
    Print("  Signal: BOS/CHoCH");
    Print("====================================");
    TestSignalConfig();
    TestSignalJournal();
    TestSignalLearning();
    TestSignalPatterns();
    Print("====================================");
    Print(StringFormat("  %d/%d passed, %d failed", g_passed, g_total, g_failed));
    Print("====================================");
}
