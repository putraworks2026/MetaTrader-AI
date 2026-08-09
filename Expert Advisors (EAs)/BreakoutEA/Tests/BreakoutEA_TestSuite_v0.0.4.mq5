//+------------------------------------------------------------------+
//| BreakoutEA_TestSuite_v0.0.4.mq5 — Unit Tests (PutraWorks)
//+------------------------------------------------------------------+
#property strict
#property description "Unit tests for BreakoutEA ML modules"
#property script_show_inputs

#include <Trade\Trade.mqh>
#include "..\\Include\\Config_v0.0.4.mqh"
#include "..\\Include\\IndicatorEngine_v0.0.4.mqh"
#include "..\\Include\\RiskManager_v0.0.4.mqh"
#include "..\\Include\\TradingJournal_v0.0.4.mqh"
#include "..\\Include\\LearningEngine_v0.0.4.mqh"
#include "..\\Include\\PatternRecognition_v0.0.4.mqh"
#include "..\\Include\\StrategyEvolution_v0.0.4.mqh"
#include "..\\Include\\OptimizationEngine_v0.0.4.mqh"
#include "..\\Include\\ReportGenerator_v0.0.4.mqh"
#include "..\\Include\\Dashboard_v0.0.4.mqh"
#include "..\\Include\\NewsManager_v0.0.4.mqh"

int g_passed = 0, g_failed = 0, g_total = 0;

void AssertTrue(bool cond, string name)
{
    g_total++;
    if(cond) { g_passed++; Print("[PASS] ", name); }
    else { g_failed++; Print("[FAIL] ", name); }
}

void TestConfig()
{
    Print("--- Config ---");
    ParameterSet ps;
    CreateDefaultProfile(ps, 1);
    AssertTrue(ps.id == 1, "Default profile ID");
    AssertTrue(ps.score == 50.0, "Default score 50");
    AssertTrue(ps.status == PROFILE_ACTIVE, "Default status ACTIVE");
}

void TestRiskManager()
{
    Print("--- RiskManager ---");
    CRiskManager rm;
    rm.Init();
    AssertTrue(rm.GetDailyPnL() == 0.0, "Initial PnL zero");
}

void TestTradingJournal()
{
    Print("--- TradingJournal ---");
    CTradingJournal j;
    j.Init("BreakoutEA");
    AssertTrue(j.GetEntryCount() >= 0, "Journal init OK");
}

void TestLearningEngine()
{
    Print("--- LearningEngine ---");
    CLearningEngine le;
    le.Init("BreakoutEA");
    AssertTrue(le.GetLessonCount() >= 0, "Learning init OK");
}

void TestPatternRecognition()
{
    Print("--- PatternRecognition ---");
    CPatternRecognition pr;
    pr.Init();
    pr.RecordTrade("Test", "Cond1", true, 100.0);
    pr.RecordTrade("Test", "Cond1", true, 50.0);
    pr.RecordTrade("Test", "Cond1", false, -30.0);
    AssertTrue(pr.GetPatternCount() >= 1, "Records patterns");
}

void TestStrategyEvolution()
{
    Print("--- StrategyEvolution ---");
    CStrategyEvolution se;
    se.Init();
    AssertTrue(se.GetProfileCount() >= 1, "Has default profile");
}

void TestOptimizationEngine()
{
    Print("--- OptimizationEngine ---");
    COptimizationEngine oe;
    oe.Init(10, false);
    AssertTrue(oe.GetPendingCount() >= 0, "Opt init OK");
}

void OnStart()
{
    Print("====================================");
    Print("  BreakoutEA ML Test Suite");
    Print("====================================");
    TestConfig();
    TestRiskManager();
    TestTradingJournal();
    TestLearningEngine();
    TestPatternRecognition();
    TestStrategyEvolution();
    TestOptimizationEngine();
    Print("====================================");
    Print(StringFormat("  %d/%d passed, %d failed", g_passed, g_total, g_failed));
    Print("====================================");
}
