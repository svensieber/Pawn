-- tests/PawnTestFramework.lua
-- Test framework for Pawn Turtle-WoW backport
-- Provides simple assertion-based testing for in-game testing

PawnTest = {
    results = {},
    current = nil,
    totalPassed = 0,
    totalFailed = 0,
    
    Start = function(self, name)
        self.current = {
            name = name,
            passed = 0,
            failed = 0,
            tests = {},
            startTime = GetTime and GetTime() or os.clock()
        }
        
        if self.PrintStatus then
            self:PrintStatus("Starting test suite: " .. name)
        end
    end,
    
    Assert = function(self, condition, message)
        if not self.current then
            print("ERROR: No test suite started. Call PawnTest:Start() first")
            return
        end
        
        message = message or "Assertion"
        
        if condition then
            self.current.passed = self.current.passed + 1
            table.insert(self.current.tests, {
                pass = true, 
                msg = message,
                time = GetTime and GetTime() or os.clock()
            })
        else
            self.current.failed = self.current.failed + 1
            table.insert(self.current.tests, {
                pass = false, 
                msg = message,
                time = GetTime and GetTime() or os.clock()
            })
            
            -- Print failure immediately
            local color = "|cffff0000" -- Red color for WoW
            local reset = "|r"
            if not GetTime then -- Not in WoW
                color = ""
                reset = ""
            end
            print(color .. "FAIL: " .. reset .. message)
        end
    end,
    
    AssertEquals = function(self, expected, actual, message)
        message = message or string.format("Expected %s, got %s", tostring(expected), tostring(actual))
        self:Assert(expected == actual, message)
    end,
    
    AssertNotNil = function(self, value, message)
        message = message or string.format("Value should not be nil")
        self:Assert(value ~= nil, message)
    end,
    
    AssertNil = function(self, value, message)
        message = message or string.format("Value should be nil, got %s", tostring(value))
        self:Assert(value == nil, message)
    end,
    
    AssertType = function(self, value, expectedType, message)
        message = message or string.format("Expected type %s, got %s", expectedType, type(value))
        self:Assert(type(value) == expectedType, message)
    end,
    
    AssertTableEquals = function(self, expected, actual, message)
        local function tablesEqual(t1, t2)
            if type(t1) ~= "table" or type(t2) ~= "table" then
                return false
            end
            
            for k, v in pairs(t1) do
                if type(v) == "table" then
                    if not tablesEqual(v, t2[k]) then
                        return false
                    end
                elseif v ~= t2[k] then
                    return false
                end
            end
            
            for k, v in pairs(t2) do
                if t1[k] == nil then
                    return false
                end
            end
            
            return true
        end
        
        message = message or "Tables are not equal"
        self:Assert(tablesEqual(expected, actual), message)
    end,
    
    End = function(self)
        if not self.current then
            print("ERROR: No test suite to end")
            return
        end
        
        local endTime = GetTime and GetTime() or os.clock()
        local duration = endTime - self.current.startTime
        
        -- Store results
        self.results[self.current.name] = self.current
        
        -- Update totals
        self.totalPassed = self.totalPassed + self.current.passed
        self.totalFailed = self.totalFailed + self.current.failed
        
        -- Print summary
        local color = self.current.failed > 0 and "|cffffff00" or "|cff00ff00"
        local reset = "|r"
        if not GetTime then -- Not in WoW
            color = ""
            reset = ""
        end
        
        print(string.format("%s%s: %d passed, %d failed (%.2f seconds)%s", 
            color,
            self.current.name, 
            self.current.passed, 
            self.current.failed,
            duration,
            reset))
        
        self.current = nil
    end,
    
    RunSuite = function(self, suiteName, testFunction)
        self:Start(suiteName)
        
        -- Protected call to catch errors
        local success, error = pcall(testFunction, self)
        
        if not success then
            print("|cffff0000ERROR in test suite: " .. (error or "Unknown error") .. "|r")
            self.current.failed = self.current.failed + 1
        end
        
        self:End()
    end,
    
    PrintSummary = function(self)
        print("\n" .. string.rep("=", 60))
        print("TEST SUMMARY")
        print(string.rep("=", 60))
        
        for suiteName, suite in pairs(self.results) do
            local status = suite.failed > 0 and "FAILED" or "PASSED"
            local color = suite.failed > 0 and "|cffff0000" or "|cff00ff00"
            local reset = "|r"
            
            if not GetTime then -- Not in WoW
                color = ""
                reset = ""
            end
            
            print(string.format("%s%-30s %s (%d/%d)%s", 
                color,
                suiteName,
                status,
                suite.passed,
                suite.passed + suite.failed,
                reset))
        end
        
        print(string.rep("-", 60))
        print(string.format("TOTAL: %d passed, %d failed", 
            self.totalPassed, 
            self.totalFailed))
        print(string.rep("=", 60))
    end,
    
    Reset = function(self)
        self.results = {}
        self.current = nil
        self.totalPassed = 0
        self.totalFailed = 0
    end,
    
    -- Helper function for printing with colors (if in WoW)
    PrintStatus = function(self, message)
        if GetTime then
            print("|cff8ec3e6" .. message .. "|r")
        else
            print(message)
        end
    end
}

-- Example test suites for Pawn
PawnTestSuites = {
    -- Basic functionality tests
    BasicTests = function(test)
        test:Assert(1 == 1, "Basic math works")
        test:AssertEquals("string", type("test"), "String type check")
        test:AssertNotNil({}, "Empty table is not nil")
        test:AssertType(123, "number", "Number type check")
    end,
    
    -- API compatibility tests
    APITests = function(test)
        -- These will only pass in WoW
        if GetItemInfo then
            test:AssertType(GetItemInfo, "function", "GetItemInfo exists")
        end
        
        if GetContainerNumSlots then
            test:AssertType(GetContainerNumSlots, "function", "GetContainerNumSlots exists")
        end
        
        -- Test our compatibility layer
        if PawnAPICompat then
            test:AssertNotNil(PawnAPICompat, "PawnAPICompat exists")
            test:AssertType(PawnAPICompat.GetContainerNumSlots, "function", "Compat GetContainerNumSlots exists")
        end
    end,
    
    -- Stat parsing tests
    StatParsingTests = function(test)
        if not PawnStatParser then
            test:Assert(false, "PawnStatParser not loaded")
            return
        end
        
        -- Test basic stat parsing
        local testCases = {
            {text = "+10 Strength", expected = {Strength = 10}},
            {text = "+5 All Stats", expected = {Strength = 5, Agility = 5, Stamina = 5, Intellect = 5, Spirit = 5}},
            {text = "Increases attack power by 20.", expected = {AttackPower = 20}},
        }
        
        for _, testCase in ipairs(testCases) do
            local stats = {}
            PawnStatParser:ParseLine(testCase.text, stats)
            test:AssertTableEquals(testCase.expected, stats, "Parse: " .. testCase.text)
        end
    end
}

-- Command to run all tests
function PawnRunAllTests()
    PawnTest:Reset()
    
    print("\nRunning Pawn Test Suite...")
    print(string.rep("=", 60))
    
    for suiteName, testFunc in pairs(PawnTestSuites) do
        PawnTest:RunSuite(suiteName, testFunc)
    end
    
    PawnTest:PrintSummary()
end

-- Slash command for in-game testing
if GetTime then -- Only register in WoW
    SLASH_PAWNTEST1 = "/pawntest"
    SlashCmdList["PAWNTEST"] = function(msg)
        if msg == "all" then
            PawnRunAllTests()
        elseif msg == "basic" then
            PawnTest:RunSuite("BasicTests", PawnTestSuites.BasicTests)
        elseif msg == "api" then
            PawnTest:RunSuite("APITests", PawnTestSuites.APITests)
        elseif msg == "stats" then
            PawnTest:RunSuite("StatParsingTests", PawnTestSuites.StatParsingTests)
        else
            print("Pawn Test Framework")
            print("Usage:")
            print("  /pawntest all    - Run all tests")
            print("  /pawntest basic  - Run basic tests")
            print("  /pawntest api    - Run API tests")
            print("  /pawntest stats  - Run stat parsing tests")
        end
    end
end