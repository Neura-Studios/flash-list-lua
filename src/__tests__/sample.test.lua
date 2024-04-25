local JestGlobals = require("@pkg/@jsdotlua/jest-globals")

local it = JestGlobals.it
local expect = JestGlobals.expect

it("should pass", function()
	expect(1).toBe(1)
end)
