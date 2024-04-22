-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/viewability/ViewabilityHelper.ts

local CustomError = require("../errors/CustomError")
local ExceptionList = require("../errors/ExceptionList")

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Array = LuauPolyfill.Array
local Boolean = LuauPolyfill.Boolean
local Set = LuauPolyfill.Set
type Array<T> = LuauPolyfill.Array<T>
type Set<T> = LuauPolyfill.Set<T>

local RecyclerListView = require("../recyclerlistview")
type Dimension = RecyclerListView.Dimension
type Layout = RecyclerListView.Layout

type ViewabilityConfig = any

--[[
	Helper class for computing viewable items based on the passed `viewabilityConfig`.
	Methods in this class will be invoked on every scroll and should be optimized for performance.
]]

export type ViewabilityHelper = {
	hasInteracted: boolean,
	lastReportedViewableIndices: Array<number>,
	possiblyViewableIndices: Array<number>,
	-- DEVIATION: `timers: Set<NodeJS_Timeout>`
	timers: Set<any>,
	-- DEVIATION END
	viewabilityConfig: ViewabilityConfig?,
	viewableIndices: Array<number>,
	viewableIndicesChanged: (
		indices: Array<number>,
		newlyVisibleIndices: Array<number>,
		newlyNonvisibleIndices: Array<number>
	) -> (),

	dispose: (self: ViewabilityHelper) -> (),

	checkViewableIndicesChanges: (
		self: ViewabilityHelper,
		newViewableIndices: Array<number>
	) -> (),

	isItemViewable: (
		self: ViewabilityHelper,
		index: number,
		horizontal: boolean,
		scrollOffset: number,
		listSize: Dimension,
		viewAreaCoveragePercentThreshold: number?,
		itemVisiblePercentThreshold: number?,
		getLayout: (index: number) -> Layout?
	) -> boolean,

	updateViewableItems: (
		self: ViewabilityHelper,
		horizontal: boolean,
		scrollOffset: number,
		listSize: Dimension,
		getLayout: (index: number) -> Layout?,
		viewableIndices: Array<number>?
	) -> any,
}

local ViewabilityHelper = {}

function ViewabilityHelper.new(
	viewabilityConfig: ViewabilityConfig?,
	viewableIndicesChanged: (
		indices: Array<number>,
		newlyVisibleIndices: Array<number>,
		newlyNonvisibleIndices: Array<number>
	) -> ()
): ViewabilityHelper
	local self = setmetatable({}, ViewabilityHelper)

	self.hasInteracted = false
	self.lastReportedViewableIndices = {}
	self.possiblyViewableIndices = {}
	self.timers = Set.new()
	self.viewabilityConfig = viewabilityConfig
	self.viewableIndices = {}
	self.viewableIndicesChanged = viewableIndicesChanged

	return (self :: any) :: ViewabilityHelper
end

function ViewabilityHelper.dispose(self: ViewabilityHelper)
	Set.forEach(self.timers, LuauPolyfill.clearTimeout)
end

function ViewabilityHelper.checkViewableIndicesChanges(
	self: ViewabilityHelper,
	newViewableIndices: Array<number>
): ()
	local currentlyNewViewableIndices = Array.filter(newViewableIndices, function(index)
		return Array.includes(self.viewableIndices, index)
	end)

	local newlyVisibleItems = Array.filter(currentlyNewViewableIndices, function(index)
		return not Boolean.toJSBoolean(
			Array.includes(self.lastReportedViewableIndices, index)
		)
	end)

	local newlyNonvisibleItems = Array.filter(
		self.lastReportedViewableIndices,
		function(index)
			return not Boolean.toJSBoolean(
				Array.includes(currentlyNewViewableIndices, index)
			)
		end
	)

	if #newlyVisibleItems > 0 or #newlyNonvisibleItems > 0 then
		self.lastReportedViewableIndices = currentlyNewViewableIndices
		self.viewableIndicesChanged(
			currentlyNewViewableIndices,
			newlyVisibleItems,
			newlyNonvisibleItems
		)
	end
end

function ViewabilityHelper.isItemViewable(
	self: ViewabilityHelper,
	index: number,
	horizontal: boolean,
	scrollOffset: number,
	listSize: Dimension,
	viewAreaCoveragePercentThreshold: number?,
	itemVisiblePercentThreshold: number?,
	getLayout: (index: number) -> Layout?
): boolean
	local itemLayout = getLayout(index)
	if itemLayout == nil then
		return false
	end

	local itemTop = (
		if Boolean.toJSBoolean(horizontal) then itemLayout.x else itemLayout.y
	) - scrollOffset

	local itemSize = if Boolean.toJSBoolean(horizontal)
		then itemLayout.width
		else itemLayout.height

	local listMainSize = if Boolean.toJSBoolean(horizontal)
		then listSize.width
		else listSize.height

	local pixelsVisible = math.min(itemTop + itemSize, listMainSize)
		- math.max(itemTop, 0)

	if pixelsVisible == itemSize then
		return true
	end

	if pixelsVisible == 0 then
		return false
	end

	local viewAreaMode = viewAreaCoveragePercentThreshold ~= nil
	local percent = if Boolean.toJSBoolean(viewAreaMode)
		then pixelsVisible / listMainSize
		else pixelsVisible / itemSize

	local viewableAreaPercentThreshold = if Boolean.toJSBoolean(viewAreaMode)
		then (viewAreaCoveragePercentThreshold :: number) * 0.01
		else (if itemVisiblePercentThreshold ~= nil
			then itemVisiblePercentThreshold
			else 0) * 0.01

	return percent >= viewableAreaPercentThreshold
end

function ViewabilityHelper.updateViewableItems(
	self: ViewabilityHelper,
	horizontal: boolean,
	scrollOffset: number,
	listSize: Dimension,
	getLayout: (index: number) -> Layout?,
	viewableIndices: Array<number>?
): ()
	if viewableIndices ~= nil then
		self.possiblyViewableIndices = viewableIndices
	end

	local itemVisiblePercentThreshold = if typeof(self.viewabilityConfig) == "table"
		then self.viewabilityConfig.itemVisiblePercentThreshold
		else nil

	local viewAreaCoveragePercentThreshold = if typeof(self.viewabilityConfig)
			== "table"
		then self.viewabilityConfig.viewAreaCoveragePercentThreshold
		else nil

	if itemVisiblePercentThreshold ~= nil and viewAreaCoveragePercentThreshold ~= nil then
		error(
			CustomError.new(ExceptionList.multipleViewabilityThresholdTypesNotSupported)
		)
	end
	if
		Boolean.toJSBoolean((function()
			local ref = if typeof(self.viewabilityConfig) == "table"
				then self.viewabilityConfig.waitForInteraction
				else nil

			ref = if ref ~= nil then ref else false

			return if Boolean.toJSBoolean(ref)
				then not Boolean.toJSBoolean(self.hasInteracted)
				else ref
		end)())
	then
		return
	end
	local newViewableIndices = Array.filter(self.possiblyViewableIndices, function(index)
		return self:isItemViewable(
			index,
			horizontal,
			scrollOffset,
			listSize,
			viewAreaCoveragePercentThreshold,
			itemVisiblePercentThreshold,
			getLayout
		)
	end)

	self.viewableIndices = newViewableIndices

	local ref = if typeof(self.viewabilityConfig) == "table"
		then self.viewabilityConfig.minimumViewTime
		else nil

	local minimumViewTime = if ref ~= nil then ref else 250

	if minimumViewTime > 0 then
		local timeoutId
		timeoutId = LuauPolyfill.setTimeout(function()
			self.timers:delete(timeoutId)
			self:checkViewableIndicesChanges(newViewableIndices)
			self.timers:add(timeoutId)
		end, minimumViewTime)
	else
		self:checkViewableIndicesChanges(newViewableIndices)
	end
end

return ViewabilityHelper
