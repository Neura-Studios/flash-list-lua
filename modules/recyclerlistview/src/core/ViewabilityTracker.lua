-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/ViewabilityTracker.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
type Array<T> = LuauPolyfill.Array<T>

local BinarySearch = require("../utils/BinarySearch")
local LayoutProvider = require("./dependencies/LayoutProvider")
type Dimension = LayoutProvider.Dimension
local LayoutManager = require("./layoutmanager/LayoutManager")
type Layout = LayoutManager.Layout

--[[
	Given an offset this utility can compute visible items. Also tracks previously visible items to compute items which get hidden or visible
	Virtual renderer uses callbacks from this utility to main recycle pool and the render stack.
	The utility optimizes finding visible indexes by using the last visible items. However, that can be slow if scrollToOffset is explicitly called.
	We use binary search to optimize in most cases like while finding first visible item or initial offset. In future we'll also be using BS to speed up
	scroll to offset.
]]

export type Range = { start: number, ["end"]: number }
export type WindowCorrection = {
	windowShift: number,
	startCorrection: number,
	endCorrection: number,
}
export type TOnItemStatusChanged = (
	all: Array<number>,
	now: Array<number>,
	notNow: Array<number>
) -> ()

export type ViewabilityTracker = {
	onVisibleRowsChanged: TOnItemStatusChanged | nil,
	onEngagedRowsChanged: TOnItemStatusChanged | nil,
	init: (self: ViewabilityTracker, windowCorrection: WindowCorrection) -> (),
	setLayouts: (
		self: ViewabilityTracker,
		layouts: Array<Layout>,
		maxOffset: number
	) -> (),
	setDimensions: (
		self: ViewabilityTracker,
		dimension: Dimension,
		isHorizontal: boolean
	) -> (),
	forceRefresh: (self: ViewabilityTracker) -> boolean,
	forceRefreshWithOffset: (self: ViewabilityTracker, offset: number) -> (),
	updateOffset: (
		self: ViewabilityTracker,
		offset: number,
		isActual: boolean,
		windowCorrection: WindowCorrection
	) -> (),
	getLastOffset: (self: ViewabilityTracker) -> number,
	getLastActualOffset: (self: ViewabilityTracker) -> number,
	getEngagedIndexes: (self: ViewabilityTracker) -> Array<number>,
	findFirstLogicallyVisibleIndex: (self: ViewabilityTracker) -> number,
	updateRenderAheadOffset: (self: ViewabilityTracker, renderAheadOffset: number) -> (),
	getCurrentRenderAheadOffset: (self: ViewabilityTracker) -> number,
	setActualOffset: (self: ViewabilityTracker, actualOffset: number) -> (),
}
type ViewabilityTracker_private = { --
	-- *** PUBLIC ***
	--
	onVisibleRowsChanged: TOnItemStatusChanged | nil,
	onEngagedRowsChanged: TOnItemStatusChanged | nil,
	init: (self: ViewabilityTracker_private, windowCorrection: WindowCorrection) -> (),
	setLayouts: (
		self: ViewabilityTracker_private,
		layouts: Array<Layout>,
		maxOffset: number
	) -> (),
	setDimensions: (
		self: ViewabilityTracker_private,
		dimension: Dimension,
		isHorizontal: boolean
	) -> (),
	forceRefresh: (self: ViewabilityTracker_private) -> boolean,
	forceRefreshWithOffset: (self: ViewabilityTracker_private, offset: number) -> (),
	updateOffset: (
		self: ViewabilityTracker_private,
		offset: number,
		isActual: boolean,
		windowCorrection: WindowCorrection
	) -> (),
	getLastOffset: (self: ViewabilityTracker_private) -> number,
	getLastActualOffset: (self: ViewabilityTracker_private) -> number,
	getEngagedIndexes: (self: ViewabilityTracker_private) -> Array<number>,
	findFirstLogicallyVisibleIndex: (self: ViewabilityTracker_private) -> number,
	updateRenderAheadOffset: (
		self: ViewabilityTracker_private,
		renderAheadOffset: number
	) -> (),
	getCurrentRenderAheadOffset: (self: ViewabilityTracker_private) -> number,
	setActualOffset: (self: ViewabilityTracker_private, actualOffset: number) -> (),
	--
	-- *** PRIVATE ***
	--
	_currentOffset: number,
	_maxOffset: number,
	_renderAheadOffset: number,
	_visibleWindow: Range,
	_engagedWindow: Range,
	_relevantDim: Range,
	_isHorizontal: boolean,
	_windowBound: number,
	_visibleIndexes: Array<number>,
	_engagedIndexes: Array<number>,
	_layouts: Array<Layout>,
	_actualOffset: number,
	_defaultCorrection: WindowCorrection,
	_findFirstVisibleIndexOptimally: (self: ViewabilityTracker_private) -> number,
	_fitAndUpdate: (self: ViewabilityTracker_private, startIndex: number) -> (),
	_doInitialFit: (
		self: ViewabilityTracker_private,
		offset: number,
		windowCorrection: WindowCorrection
	) -> (), --TODO:Talha switch to binary search and remove atleast once logic in _fitIndexes
	_findFirstVisibleIndexLinearly: (self: ViewabilityTracker_private) -> number,
	_findFirstVisibleIndexUsingBS: (
		self: ViewabilityTracker_private,
		bias_: number?
	) -> number,
	_valueExtractorForBinarySearch: any, --TODO:Talha Optimize further in later revisions, alteast once logic can be replace with a BS lookup
	_fitIndexes: (
		self: ViewabilityTracker_private,
		newVisibleIndexes: Array<number>,
		newEngagedIndexes: Array<number>,
		startIndex: number,
		isReverse: boolean
	) -> (),
	_checkIntersectionAndReport: (
		self: ViewabilityTracker_private,
		index: number,
		insertOnTop: boolean,
		relevantDim: Range,
		newVisibleIndexes: Array<number>,
		newEngagedIndexes: Array<number>
	) -> boolean,
	_setRelevantBounds: (
		self: ViewabilityTracker_private,
		itemRect: Layout,
		relevantDim: Range
	) -> (),
	_isItemInBounds: (
		self: ViewabilityTracker_private,
		window: Range,
		itemBound: number
	) -> boolean,
	_isItemBoundsBeyondWindow: (
		self: ViewabilityTracker_private,
		window: Range,
		startBound: number,
		endBound: number
	) -> boolean,
	_isZeroHeightEdgeElement: (
		self: ViewabilityTracker_private,
		window: Range,
		startBound: number,
		endBound: number
	) -> boolean,
	_itemIntersectsWindow: (
		self: ViewabilityTracker_private,
		window: Range,
		startBound: number,
		endBound: number
	) -> boolean,
	_itemIntersectsEngagedWindow: (
		self: ViewabilityTracker_private,
		startBound: number,
		endBound: number
	) -> boolean,
	_itemIntersectsVisibleWindow: (
		self: ViewabilityTracker_private,
		startBound: number,
		endBound: number
	) -> boolean,
	_updateTrackingWindows: (
		self: ViewabilityTracker_private,
		offset: number,
		correction: WindowCorrection
	) -> (), --TODO:Talha optimize this
	_diffUpdateOriginalIndexesAndRaiseEvents: (
		self: ViewabilityTracker_private,
		newVisibleItems: Array<number>,
		newEngagedItems: Array<number>
	) -> (),
	_diffArraysAndCallFunc: (
		self: ViewabilityTracker_private,
		newItems: Array<number>,
		oldItems: Array<number>,
		func: TOnItemStatusChanged | nil
	) -> (), --TODO:Talha since arrays are sorted this can be much faster
	_calculateArrayDiff: (
		self: ViewabilityTracker_private,
		arr1: Array<number>,
		arr2: Array<number>
	) -> Array<number>,
}
type ViewabilityTracker_statics = {
	new: (renderAheadOffset: number, initialOffset: number) -> ViewabilityTracker,
}

local ViewabilityTracker = {} :: ViewabilityTracker & ViewabilityTracker_statics
local ViewabilityTracker_private =
	ViewabilityTracker :: ViewabilityTracker_private & ViewabilityTracker_statics;
(ViewabilityTracker :: any).__index = ViewabilityTracker

function ViewabilityTracker_private.new(
	renderAheadOffset: number,
	initialOffset: number
): ViewabilityTracker
	local self = setmetatable({}, ViewabilityTracker)
	self._layouts = {}
	self._valueExtractorForBinarySearch = function(index: number): number
		local itemRect = self._layouts[index];
		(self :: any):_setRelevantBounds(itemRect, (self :: any)._relevantDim)
		return (self :: any)._relevantDim["end"]
	end
	self._currentOffset = math.max(0, initialOffset)
	self._maxOffset = 0
	self._actualOffset = 0
	self._renderAheadOffset = renderAheadOffset
	self._visibleWindow = { start = 0, ["end"] = 0 }
	self._engagedWindow = { start = 0, ["end"] = 0 }
	self._isHorizontal = false
	self._windowBound = 0
	self._visibleIndexes = {} --needs to be sorted
	self._engagedIndexes = {} --needs to be sorted
	self.onVisibleRowsChanged = nil
	self.onEngagedRowsChanged = nil
	self._relevantDim = { start = 0, ["end"] = 0 }
	self._defaultCorrection = { startCorrection = 0, endCorrection = 0, windowShift = 0 }
	return (self :: any) :: ViewabilityTracker
end

function ViewabilityTracker_private:init(windowCorrection: WindowCorrection): ()
	self:_doInitialFit(self._currentOffset, windowCorrection)
end

function ViewabilityTracker_private:setLayouts(
	layouts: Array<Layout>,
	maxOffset: number
): ()
	self._layouts = layouts
	self._maxOffset = maxOffset
end

function ViewabilityTracker_private:setDimensions(
	dimension: Dimension,
	isHorizontal: boolean
): ()
	self._isHorizontal = isHorizontal
	self._windowBound = if isHorizontal then dimension.width else dimension.height
end

function ViewabilityTracker_private:forceRefresh(): boolean
	local shouldForceScroll = self._actualOffset >= 0
		and self._currentOffset >= self._maxOffset - self._windowBound
	self:forceRefreshWithOffset(self._currentOffset)
	return shouldForceScroll
end

function ViewabilityTracker_private:forceRefreshWithOffset(offset: number): ()
	self._currentOffset = -1
	self:updateOffset(offset, false, self._defaultCorrection)
end

function ViewabilityTracker_private:updateOffset(
	offset: number,
	isActual: boolean,
	windowCorrection: WindowCorrection
): ()
	local correctedOffset = offset
	if isActual then
		self._actualOffset = offset
		correctedOffset = math.min(
			self._maxOffset,
			math.max(
				0,
				offset + (windowCorrection.windowShift + windowCorrection.startCorrection)
			)
		)
	end
	if self._currentOffset ~= correctedOffset then
		self._currentOffset = correctedOffset
		self:_updateTrackingWindows(offset, windowCorrection)
		local startIndex = 0
		if #self._visibleIndexes > 0 then
			startIndex = self._visibleIndexes[1]
		end
		self:_fitAndUpdate(startIndex)
	end
end

function ViewabilityTracker_private:getLastOffset(): number
	return self._currentOffset
end

function ViewabilityTracker_private:getLastActualOffset(): number
	return self._actualOffset
end

function ViewabilityTracker_private:getEngagedIndexes(): Array<number>
	return self._engagedIndexes
end

function ViewabilityTracker_private:findFirstLogicallyVisibleIndex(): number
	local relevantIndex = self:_findFirstVisibleIndexUsingBS(0.001)
	local result = relevantIndex

	local i = relevantIndex
	while i >= 0 do
		if self._isHorizontal then
			if self._layouts[relevantIndex].x ~= self._layouts[i].x then
				break
			else
				result = i
			end
		else
			if self._layouts[relevantIndex].y ~= self._layouts[i].y then
				break
			else
				result = i
			end
		end
		i -= 1
	end

	print("findFirstLogicallyVisibleIndex", result)

	return result
end

function ViewabilityTracker_private:updateRenderAheadOffset(renderAheadOffset: number): ()
	self._renderAheadOffset = math.max(0, renderAheadOffset)
	self:forceRefreshWithOffset(self._currentOffset)
end

function ViewabilityTracker_private:getCurrentRenderAheadOffset(): number
	return self._renderAheadOffset
end

function ViewabilityTracker_private:setActualOffset(actualOffset: number): ()
	self._actualOffset = actualOffset
end

function ViewabilityTracker_private:_findFirstVisibleIndexOptimally(): number
	local firstVisibleIndex = 0
	if self._currentOffset > 5000 then
		firstVisibleIndex = self:_findFirstVisibleIndexUsingBS()
	elseif self._currentOffset > 0 then
		firstVisibleIndex = self:_findFirstVisibleIndexLinearly()
	end
	return firstVisibleIndex
end

function ViewabilityTracker_private:_fitAndUpdate(startIndex: number): ()
	local newVisibleItems: Array<number> = {}
	local newEngagedItems: Array<number> = {}
	self:_fitIndexes(newVisibleItems, newEngagedItems, startIndex, true)
	self:_fitIndexes(newVisibleItems, newEngagedItems, startIndex + 1, false)
	self:_diffUpdateOriginalIndexesAndRaiseEvents(newVisibleItems, newEngagedItems)
end

function ViewabilityTracker_private:_doInitialFit(
	offset: number,
	windowCorrection: WindowCorrection
): ()
	offset = math.min(self._maxOffset, math.max(0, offset))
	self:_updateTrackingWindows(offset, windowCorrection)
	local firstVisibleIndex = self:_findFirstVisibleIndexOptimally()
	self:_fitAndUpdate(firstVisibleIndex)
end

function ViewabilityTracker_private:_findFirstVisibleIndexLinearly(): number
	local relevantDim = { start = 0, ["end"] = 0 }
	for i, itemRect in self._layouts do
		self:_setRelevantBounds(itemRect, relevantDim)
		if self:_itemIntersectsVisibleWindow(relevantDim.start, relevantDim["end"]) then
			return i
		end
	end
	return 0
end

function ViewabilityTracker_private:_findFirstVisibleIndexUsingBS(bias_: number?): number
	local bias: number = if bias_ ~= nil then bias_ else 1
	local count = #self._layouts
	return BinarySearch.findClosestHigherValueIndex(
		count,
		self._visibleWindow.start + bias,
		self._valueExtractorForBinarySearch
	)
end

function ViewabilityTracker_private:_fitIndexes(
	newVisibleIndexes: Array<number>,
	newEngagedIndexes: Array<number>,
	startIndex: number,
	isReverse: boolean
): ()
	local count = #self._layouts
	local relevantDim: Range = { start = 0, ["end"] = 0 }
	local atLeastOneLocated = false
	if startIndex - 1 < count then
		if not isReverse then
			for i = startIndex, count do
				if
					self:_checkIntersectionAndReport(
						i,
						false,
						relevantDim,
						newVisibleIndexes,
						newEngagedIndexes
					)
				then
					atLeastOneLocated = true
				else
					if atLeastOneLocated then
						break
					end
				end
			end
		else
			for i = startIndex, 1, -1 do
				if
					self:_checkIntersectionAndReport(
						i,
						true,
						relevantDim,
						newVisibleIndexes,
						newEngagedIndexes
					)
				then
					atLeastOneLocated = true
				else
					if atLeastOneLocated then
						break
					end
				end
			end
		end
	end
end

function ViewabilityTracker_private:_checkIntersectionAndReport(
	index: number,
	insertOnTop: boolean,
	relevantDim: Range,
	newVisibleIndexes: Array<number>,
	newEngagedIndexes: Array<number>
): boolean
	local itemRect = self._layouts[index]
	local isFound = false
	self:_setRelevantBounds(itemRect, relevantDim)
	if self:_itemIntersectsVisibleWindow(relevantDim.start, relevantDim["end"]) then
		if insertOnTop then
			-- Array.splice(newVisibleIndexes, 1, 1, index)
			-- Array.splice(newEngagedIndexes, 1, 1, index)
			table.insert(newVisibleIndexes, 1, index)
			table.insert(newEngagedIndexes, 1, index)
		else
			table.insert(newVisibleIndexes, index)
			table.insert(newEngagedIndexes, index)
		end
		isFound = true
	elseif self:_itemIntersectsEngagedWindow(relevantDim.start, relevantDim["end"]) then
		--TODO: This needs to be optimized
		if insertOnTop then
			-- Array.splice(newEngagedIndexes, 1, 1, index)
			table.insert(newEngagedIndexes, 1, index)
		else
			table.insert(newEngagedIndexes, index)
		end
		isFound = true
	end
	return isFound
end

function ViewabilityTracker_private:_setRelevantBounds(
	itemRect: Layout,
	relevantDim: Range
): ()
	if self._isHorizontal then
		relevantDim["end"] = itemRect.x + itemRect.width
		relevantDim.start = itemRect.x
	else
		relevantDim["end"] = itemRect.y + itemRect.height
		relevantDim.start = itemRect.y
	end
end

function ViewabilityTracker_private:_isItemInBounds(
	window: Range,
	itemBound: number
): boolean
	return window.start < itemBound and window["end"] > itemBound
end

function ViewabilityTracker_private:_isItemBoundsBeyondWindow(
	window: Range,
	startBound: number,
	endBound: number
): boolean
	return window.start >= startBound and window["end"] <= endBound
end

function ViewabilityTracker_private:_isZeroHeightEdgeElement(
	window: Range,
	startBound: number,
	endBound: number
): boolean
	return startBound - endBound == 0
		and (window.start == startBound or window["end"] == endBound)
end

function ViewabilityTracker_private:_itemIntersectsWindow(
	window: Range,
	startBound: number,
	endBound: number
): boolean
	return self:_isItemInBounds(window, startBound)
		or self:_isItemInBounds(window, endBound)
		or self:_isItemBoundsBeyondWindow(window, startBound, endBound)
		or self:_isZeroHeightEdgeElement(window, startBound, endBound)
end

function ViewabilityTracker_private:_itemIntersectsEngagedWindow(
	startBound: number,
	endBound: number
): boolean
	return self:_itemIntersectsWindow(self._engagedWindow, startBound, endBound)
end

function ViewabilityTracker_private:_itemIntersectsVisibleWindow(
	startBound: number,
	endBound: number
): boolean
	return self:_itemIntersectsWindow(self._visibleWindow, startBound, endBound)
end

function ViewabilityTracker_private:_updateTrackingWindows(
	offset: number,
	correction: WindowCorrection
): ()
	local startCorrection = correction.windowShift + correction.startCorrection
	local bottomCorrection = correction.windowShift + correction.endCorrection
	local startOffset = offset + startCorrection
	local endOffset = offset + self._windowBound + bottomCorrection
	self._engagedWindow.start = math.max(0, startOffset - self._renderAheadOffset)
	self._engagedWindow["end"] = endOffset + self._renderAheadOffset
	self._visibleWindow.start = startOffset
	self._visibleWindow["end"] = endOffset
end

function ViewabilityTracker_private:_diffUpdateOriginalIndexesAndRaiseEvents(
	newVisibleItems: Array<
		number
	>,
	newEngagedItems: Array<
		number
	>
): ()
	self:_diffArraysAndCallFunc(
		newVisibleItems,
		self._visibleIndexes,
		self.onVisibleRowsChanged
	)
	self:_diffArraysAndCallFunc(
		newEngagedItems,
		self._engagedIndexes,
		self.onEngagedRowsChanged
	)
	self._visibleIndexes = newVisibleItems
	self._engagedIndexes = newEngagedItems
end

function ViewabilityTracker_private:_diffArraysAndCallFunc(
	newItems: Array<number>,
	oldItems: Array<number>,
	func: TOnItemStatusChanged | nil
): ()
	if func then
		local now = self:_calculateArrayDiff(newItems, oldItems)
		local notNow = self:_calculateArrayDiff(oldItems, newItems)
		if #now > 0 or #notNow > 0 then
			func(table.clone(newItems), now, notNow)
		end
	end
end

function ViewabilityTracker_private:_calculateArrayDiff(
	arr1: Array<number>,
	arr2: Array<number>
): Array<number>
	local len = #arr1
	local diffArr = {}
	for i = 1, len do
		if BinarySearch.findIndexOf(arr2, arr1[i]) == -1 then
			table.insert(diffArr, arr1[i])
		end
	end
	return diffArr
end

return ViewabilityTracker
