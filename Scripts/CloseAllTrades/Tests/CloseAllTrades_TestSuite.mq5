//+------------------------------------------------------------------+
//| CloseAllTrades_TestSuite.mq5 — Unit Tests
//| CloseAllTrades — Self-Improving MT5 AI Tool (PutraWorks)
//+------------------------------------------------------------------+
#property strict
#property description "Unit tests for CloseAllTrades modules"
#property script_show_inputs

#include <Trade\Trade.mqh>
#include "..\Include\Config.mqh"
#include "..\Include\IndicatorEngine.mqh"
#include "..\Include\RiskManager.mqh"
#include "..\Include\TradingJournal.mqh"
#include "..\Include\LearningEngine.mqh"
#include "..\Include\PatternRecognition.mqh"
#include "..\Include\StrategyEvolution.mqh"
#include "..\Include\OptimizationEngine.mqh"
#include "..\Include\ReportGenerator.mqh"
#include "..\Include\Dashboard.mqh"
#include "..\Include\NewsManager.mqh"

//==================================================================
//  TEST FRAMEWORK
//==================================================================

int g_testsPassed = 0;
int g_testsFailed = 0;
int g_testsTotal  = 0;

void AssertTrue(bool condition, string testName)
{
   g_testsTotal++;
   if(condition)
   {
      g_testsPassed++;
      Print("[PASS] ", testName);
   }
   else
   {
      g_testsFailed++;
      Print("[FAIL] ", testName);
   }
}

void AssertEqual(int actual, int expected, string testName)
{
   g_testsTotal++;
   if(actual == expected)
   {
      g_testsPassed++;
      Print("[PASS] ", testName);
   }
   else
   {
      g_testsFailed++;
      Print("[FAIL] ", testName, " expected=", expected, " actual=", actual);
   }
}

//==================================================================
//  TEST SUITE
//==================================================================

void TestConfig()
{
   Print("--- Testing Config ---");
   ML_ParameterSet ps;
   ML_CreateDefaultProfile(ps, 1);
   AssertTrue(ps.id == 1, "Config: Default profile ID");
   AssertTrue(ps.score == 50.0, "Config: Default score is 50");
   AssertTrue(ps.status == ML_PROFILE_ACTIVE, "Config: Default status is ACTIVE");
}

void TestRiskManager()
{
   Print("--- Testing RiskManager ---");
   CRiskManager rm;
   rm.Init();
   AssertTrue(rm.CanOpenPosition(), "RiskManager: Can open position initially");
}

void TestTradingJournal()
{
   Print("--- Testing TradingJournal ---");
   CTradingJournal journal;
   journal.Init("CloseAllTrades");
   AssertTrue(journal.GetEntryCount() >= 0, "TradingJournal: Init OK");
}

void TestLearningEngine()
{
   Print("--- Testing LearningEngine ---");
   CLearningEngine le;
   le.Init("CloseAllTrades");
   AssertTrue(le.GetLessonCount() >= 0, "LearningEngine: Init OK");
}

void TestPatternRecognition()
{
   Print("--- Testing PatternRecognition ---");
   CPatternRecognition pr;
   pr.Init();
   pr.RecordPattern("test", "condition1", true, 100.0);
   pr.RecordPattern("test", "condition1", true, 50.0);
   AssertTrue(pr.GetPatternCount() >= 1, "PatternRecognition: Records patterns");
}

void TestStrategyEvolution()
{
   Print("--- Testing StrategyEvolution ---");
   CStrategyEvolution se;
   se.Init();
   AssertTrue(se.GetProfileCount() >= 1, "StrategyEvolution: Has default profile");
}

void TestOptimizationEngine()
{
   Print("--- Testing OptimizationEngine ---");
   COptimizationEngine oe;
   oe.Init();
   AssertTrue(oe.GetPendingCount() >= 0, "OptimizationEngine: Init OK");
}

//==================================================================
//  MAIN
//==================================================================

void OnStart()
{
   Print("====================================");
   Print("  CloseAllTrades Test Suite");
   Print("====================================");
   
   TestConfig();
   TestRiskManager();
   TestTradingJournal();
   TestLearningEngine();
   TestPatternRecognition();
   TestStrategyEvolution();
   TestOptimizationEngine();
   
   Print("====================================");
   Print(StringFormat("  Results: %d/%d passed, %d failed",
      g_testsPassed, g_testsTotal, g_testsFailed));
   Print("====================================");
}
