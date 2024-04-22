-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/utils/BinarySearch.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
type Array<T> = LuauPolyfill.Array<T>

local CustomError = require("../core/exceptions/CustomError")

export type ValueAndIndex = { value: number, index: number }

-- ROBLOX deviation: Don't use a class with static members, just use functions.
local BinarySearch = {}

function BinarySearch.findClosestHigherValueIndex(
	size: number,
	targetValue: number,
	valueExtractor: (index: number) -> number
): number
	local low = 1
	local high = size
	local mid = math.floor((low + high) / 2)
	local lastValue = 0
	local absoluteLastDiff = math.abs(valueExtractor(mid) - targetValue)
	local result = mid
	local diff = 0
	local absoluteDiff = 0
	if absoluteLastDiff == 0 then
		return result
	end
	if high < 0 then
		error(CustomError.new({
			message = "The collection cannot be empty",
			type = "InvalidStateException",
		}))
	end
	while low <= high do
		mid = math.floor((low + high) / 2)
		lastValue = valueExtractor(mid)
		diff = lastValue - targetValue
		absoluteDiff = math.abs(diff)
		if diff >= 0 and absoluteDiff < absoluteLastDiff then
			absoluteLastDiff = absoluteDiff
			result = mid
		end
		if targetValue < lastValue then
			high = mid - 1
		elseif targetValue > lastValue then
			low = mid + 1
		else
			return mid
		end
	end
	return result
end

function BinarySearch.findClosestValueToTarget(
	values: Array<number>,
	target: number
): ValueAndIndex
	local low = 1
	local high = #values
	local mid = math.floor((low + high) / 2)
	local midValue = values[mid]
	local lastMidValue = midValue + 1
	while low <= high and midValue ~= lastMidValue do
		if midValue == target then
			break
		elseif midValue < target then
			low = mid
		elseif midValue > target then
			high = mid
		end
		mid = math.floor((low + high) / 2)
		lastMidValue = midValue
		midValue = values[mid]
	end
	return { value = midValue, index = mid }
end

function BinarySearch.findValueSmallerThanTarget(
	values: Array<number>,
	target: number
): ValueAndIndex | nil
	local low = 1
	local high = #values
	if target >= values[high] then
		return { value = values[high], index = high }
	elseif target < values[low] then
		return nil
	end
	local midValueAndIndex: ValueAndIndex =
		BinarySearch.findClosestValueToTarget(values, target)
	local midValue: number = midValueAndIndex.value
	local mid: number = midValueAndIndex.index
	if midValue <= target then
		return { value = midValue, index = mid }
	else
		return { value = values[mid - 1], index = mid - 1 }
	end
end

function BinarySearch.findValueLargerThanTarget(
	values: Array<number>,
	target: number
): ValueAndIndex | nil
	local low = 1
	local high = #values
	if target < values[low] then
		return { value = values[low], index = low }
	elseif target > values[high] then
		return nil
	end
	local midValueAndIndex: ValueAndIndex =
		BinarySearch.findClosestValueToTarget(values, target)
	local midValue: number = midValueAndIndex.value
	local mid: number = midValueAndIndex.index
	if midValue >= target then
		return { value = midValue, index = mid }
	else
		return { value = values[mid + 1], index = mid + 1 }
	end
end

function BinarySearch.findIndexOf(array: Array<number>, value: number): number
	local j = 1
	local length = #array
	local i = 0
	while j < length do
		i = bit32.arshift(length + j, 1)
		if value > array[i] then
			j = i + 1
		elseif value < array[i] then
			length = i
		else
			return i
		end
	end
	return -1
end

return BinarySearch
