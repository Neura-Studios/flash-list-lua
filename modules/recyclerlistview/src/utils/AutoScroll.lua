-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/utils/AutoScroll.ts

type void = nil --[[ ROBLOX FIXME: adding `void` type alias to make it easier to use Luau `void` equivalent when supported ]]

local RunService = game:GetService("RunService")

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Promise = require("@pkg/@jsdotlua/promise")
type Promise<T> = LuauPolyfill.Promise<T>

export type Scrollable = {
	scrollToOffset: (self: Scrollable, x: number, y: number, animate: boolean) -> (),
}

-- ROBLOX deviation: Don't use a class with static members, just use functions.
local AutoScroll = {}

function AutoScroll.scrollNow(
	scrollable: Scrollable,
	fromX: number,
	fromY: number,
	toX: number,
	toY: number,
	speedMultiplier_: number?
): Promise<void>
	local speedMultiplier = speedMultiplier_ or 1

	return Promise.new(function(resolve)
		scrollable:scrollToOffset(fromX, fromY, false)
		local incrementPerMs = 0.1 * speedMultiplier
		-- ROBLOX deviation: Using `os.clock` instead of `DateTime` for faster reads
		local startTime = os.clock()
		local startX = fromX
		local startY = fromY

		-- ROBLOX deviation: Using `RunService` render loop instead of `requestAnimationFrame` browser API
		local connection
		connection = RunService.RenderStepped:Connect(function()
			-- ROBLOX deviation: Using `os.clock` instead of `DateTime` for faster reads
			local currentTime = os.clock()
			local timeElapsed = currentTime - startTime
			local distanceToCover = incrementPerMs * timeElapsed
			startX += distanceToCover
			startY += distanceToCover
			scrollable:scrollToOffset(math.min(toX, startX), math.min(toY, startY), false)
			startTime = currentTime
			if math.min(toX, startX) == toX and math.min(toY, startY) == toY then
				connection:Disconnect()
				resolve()
			end
		end)
	end)
end

return AutoScroll
