local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jest = require("@pkg/@jsdotlua/jest")

local JestRoots = {
	ReplicatedStorage:WaitForChild("TestTarget"),
}

local success, result = Jest.runCLI(ReplicatedStorage, {
	verbose = true,
	ci = false,
}, JestRoots):await()

if not success then
	error(result)
end

task.wait(0.5)
