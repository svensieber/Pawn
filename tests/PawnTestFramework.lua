-- tests/PawnTestFramework.lua
PawnTest = {
    results = {},
    current = nil,
    
    Start = function(self, name)
        self.current = {
            name = name,
            passed = 0,
            failed = 0,
            tests = {}
        }
    end,
    
    Assert = function(self, condition, message)
        if condition then
            self.current.passed = self.current.passed + 1
            table.insert(self.current.tests, {pass = true, msg = message})
        else
            self.current.failed = self.current.failed + 1
            table.insert(self.current.tests, {pass = false, msg = message})
            print("|cffff0000FAIL:|r " .. message)
        end
    end,
    
    End = function(self)
        self.results[self.current.name] = self.current
        print(format("%s: %d passed, %d failed", 
            self.current.name, 
            self.current.passed, 
            self.current.failed))
        self.current = nil
    end
}