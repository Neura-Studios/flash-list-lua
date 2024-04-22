-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/utils/AverageWindow.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")

type Array<T> = LuauPolyfill.Array<T>

--[[
	Helper class to calculate running average of the most recent n values
]]

export type AverageWindow = {
	currentAverage: number,
	currentCount: number,
	inputValues: Array<number | nil>,
	nextIndex: number,

	addValue: (self: AverageWindow, value: number) -> (),
	currentValue: (self: AverageWindow) -> number,
	getNextIndex: (self: AverageWindow) -> number,
}

local AverageWindow = {}

function AverageWindow.new(size: number, startValue: number?): AverageWindow
	local self = setmetatable({}, AverageWindow)

	self.nextIndex = 0
	self.inputValues = { startValue }
	self.currentAverage = if startValue ~= nil then startValue else 0
	self.currentCount = if startValue == nil then 0 else 1
	self.nextIndex = self.currentCount

	return (self :: any) :: AverageWindow
end

function AverageWindow.addValue(self: AverageWindow, value: number): ()
	local target = self:getNextIndex()
	local oldValue = self.inputValues[target]
	local newCount = if oldValue == nil then self.currentCount + 1 else self.currentCount

	self.inputValues[target] = value
	self.currentCount = newCount
	self.currentAverage = self.currentAverage * (self.currentCount / newCount)
		+ (value - (if oldValue ~= nil then oldValue else 0)) / newCount
end

function AverageWindow.currentValue(self: AverageWindow): number
	return self.currentAverage
end

function AverageWindow.getNextIndex(self: AverageWindow): number
	local newTarget = self.nextIndex

	self.nextIndex = (self.nextIndex + 1) % #self.inputValues

	return newTarget
end

return AverageWindow
