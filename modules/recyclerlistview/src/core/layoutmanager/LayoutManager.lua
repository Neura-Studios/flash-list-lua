-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/layoutmanager/LayoutManager.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Array = LuauPolyfill.Array
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object

local exports = {}

--[[
	Computes the positions and dimensions of items that will be rendered by the
	list. The output from this is utilized by viewability tracker to compute the
	lists of visible/hidden item.
]]

-- ROBLOX deviation: Cast to `any` to avoid cyclic dependency
-- local layoutProviderModule = require("../dependencies/LayoutProvider")
type Dimension = any -- layoutProviderModule.Dimension
type LayoutProvider = any -- layoutProviderModule.LayoutProvider

local CustomError = require("../exceptions/CustomError")

export type LayoutManager = {
	getOffsetForIndex: (self: LayoutManager, index: number) -> Point,
	-- You can override this incase you want to override style in some cases e.g, say you want to enfore width but not height
	getStyleOverridesForIndex: (
		self: LayoutManager,
		index: number
	) -> Object | Array<unknown> | nil,
	-- Removes item at the specified index
	removeLayout: (self: LayoutManager, index: number) -> (),
	-- Return the dimension of entire content inside the list
	getContentDimension: (self: LayoutManager) -> Dimension,
	-- Return all computed layouts as an array, frequently called, you are expected to return a cached array. Don't compute here.
	getLayouts: (self: LayoutManager) -> Array<Layout>,
	-- RLV will call this method in case of mismatch with actual rendered dimensions in case of non deterministic rendering
	-- You are expected to cache this value and prefer it over estimates provided
	-- No need to relayout which RLV will trigger. You should only relayout when relayoutFromIndex is called.
	-- Layout managers can choose to ignore the override requests like in case of grid layout where width changes
	-- can be ignored for a vertical layout given it gets computed via the given column span.
	overrideLayout: (self: LayoutManager, index: number, dim: Dimension) -> boolean, --Recompute layouts from given index, compute heavy stuff should be here
	relayoutFromIndex: (self: LayoutManager, startIndex: number, itemCount: number) -> (),
}

type LayoutManager_statics = { new: () -> LayoutManager }
local LayoutManager = {} :: LayoutManager & LayoutManager_statics;
(LayoutManager :: any).__index = LayoutManager

function LayoutManager.new(): LayoutManager
	local self = setmetatable({}, LayoutManager)
	return (self :: any) :: LayoutManager
end

function LayoutManager:getOffsetForIndex(index: number): Point
	local layouts = self:getLayouts()
	if #layouts > index then
		return { x = layouts[index].x, y = layouts[index].y }
	else
		error(CustomError.new({
			message = "No layout available for index: " .. tostring(index),
			type = "LayoutUnavailableException",
		}))
	end
end

function LayoutManager:getStyleOverridesForIndex(
	index: number
): Object | Array<unknown> | nil
	return nil
end

function LayoutManager:removeLayout(index: number): ()
	local layouts = self:getLayouts()
	if index < #layouts then
		Array.splice(layouts, index, 2)
	end
	if index == 1 and #layouts > 0 then
		local firstLayout = layouts[1]
		firstLayout.x = 0
		firstLayout.y = 0
	end
end

function LayoutManager:getContentDimension(): Dimension
	error("not implemented abstract method")
end

function LayoutManager:getLayouts(): Array<Layout>
	error("not implemented abstract method")
end

function LayoutManager:overrideLayout(index: number, dim: Dimension): boolean
	error("not implemented abstract method")
end

function LayoutManager:relayoutFromIndex(startIndex: number, itemCount: number): ()
	error("not implemented abstract method")
end

exports.LayoutManager = LayoutManager

export type WrapGridLayoutManager = LayoutManager & {
	getContentDimension: (self: WrapGridLayoutManager) -> Dimension,
	getLayouts: (self: WrapGridLayoutManager) -> Array<Layout>,
	getOffsetForIndex: (self: WrapGridLayoutManager, index: number) -> Point,
	overrideLayout: (
		self: WrapGridLayoutManager,
		index: number,
		dim: Dimension
	) -> boolean,
	setMaxBounds: (self: WrapGridLayoutManager, itemDim: Dimension) -> (),
	relayoutFromIndex: (
		self: WrapGridLayoutManager,
		startIndex: number,
		itemCount: number
	) -> (),
}
type WrapGridLayoutManager_private = { --
	-- *** PUBLIC ***
	--
	getContentDimension: (self: WrapGridLayoutManager_private) -> Dimension,
	getLayouts: (self: WrapGridLayoutManager_private) -> Array<Layout>,
	getOffsetForIndex: (self: WrapGridLayoutManager_private, index: number) -> Point,
	overrideLayout: (
		self: WrapGridLayoutManager_private,
		index: number,
		dim: Dimension
	) -> boolean,
	setMaxBounds: (self: WrapGridLayoutManager_private, itemDim: Dimension) -> (),
	relayoutFromIndex: (
		self: WrapGridLayoutManager_private,
		startIndex: number,
		itemCount: number
	) -> (),
	--
	-- *** PRIVATE ***
	--
	_layoutProvider: LayoutProvider,
	_window: Dimension,
	_totalHeight: number,
	_totalWidth: number,
	_isHorizontal: boolean,
	_layouts: Array<Layout>,
	_pointDimensionsToRect: (self: WrapGridLayoutManager_private, itemRect: Layout) -> (),
	_setFinalDimensions: (self: WrapGridLayoutManager_private, maxBound: number) -> (),
	_locateFirstNeighbourIndex: (
		self: WrapGridLayoutManager_private,
		startIndex: number
	) -> number,
	_checkBounds: (
		self: WrapGridLayoutManager_private,
		itemX: number,
		itemY: number,
		itemDim: Dimension,
		isHorizontal: boolean
	) -> boolean,
}
type WrapGridLayoutManager_statics = {
	new: (
		layoutProvider: LayoutProvider,
		renderWindowSize: Dimension,
		isHorizontal_: boolean?,
		cachedLayouts: Array<Layout>?
	) -> WrapGridLayoutManager,
}

local WrapGridLayoutManager = (
	setmetatable({}, { __index = LayoutManager }) :: any
) :: WrapGridLayoutManager & WrapGridLayoutManager_statics
local WrapGridLayoutManager_private = (
	WrapGridLayoutManager :: any
) :: WrapGridLayoutManager_private & WrapGridLayoutManager_statics;
(WrapGridLayoutManager :: any).__index = WrapGridLayoutManager

function WrapGridLayoutManager_private.new(
	layoutProvider: LayoutProvider,
	renderWindowSize: Dimension,
	isHorizontal_: boolean?,
	cachedLayouts: Array<Layout>?
): WrapGridLayoutManager
	local self = setmetatable({}, WrapGridLayoutManager)
	local isHorizontal: boolean = if isHorizontal_ ~= nil then isHorizontal_ else false

	self._layoutProvider = layoutProvider
	self._window = renderWindowSize
	self._totalHeight = 0
	self._totalWidth = 0
	self._isHorizontal = not not isHorizontal
	self._layouts = if cachedLayouts then cachedLayouts else {}
	return (self :: any) :: WrapGridLayoutManager
end

function WrapGridLayoutManager_private:getContentDimension(): Dimension
	return { height = self._totalHeight, width = self._totalWidth }
end

function WrapGridLayoutManager_private:getLayouts(): Array<Layout>
	return self._layouts
end

function WrapGridLayoutManager_private:getOffsetForIndex(index: number): Point
	if #self._layouts > index then
		return {
			x = self._layouts[index].x,
			y = self._layouts[index].y,
		}
	else
		error(CustomError.new({
			message = "No layout available for index: " .. tostring(index),
			type = "LayoutUnavailableException",
		}))
	end
end

function WrapGridLayoutManager_private:overrideLayout(
	index: number,
	dim: Dimension
): boolean
	local layout = self._layouts[index]
	if layout then
		layout.isOverridden = true
		layout.width = dim.width
		layout.height = dim.height
	end
	return true
end

function WrapGridLayoutManager_private:setMaxBounds(itemDim: Dimension): ()
	if self._isHorizontal then
		itemDim.height = math.min(self._window.height, itemDim.height)
	else
		itemDim.width = math.min(self._window.width, itemDim.width)
	end
end

function WrapGridLayoutManager_private:relayoutFromIndex(
	startIndex: number,
	itemCount: number
): ()
	startIndex = self:_locateFirstNeighbourIndex(startIndex)
	local startX = 0
	local startY = 0
	local maxBound = 0

	local startVal = self._layouts[startIndex]
	if startVal then
		startX = startVal.x
		startY = startVal.y
		self:_pointDimensionsToRect(startVal)
	end

	local oldItemCount = #self._layouts
	local itemDim = { height = 0, width = 0 }
	local itemRect = nil

	local oldLayout = nil

	for i = startIndex, itemCount do
		oldLayout = self._layouts[i]
		local layoutType = self._layoutProvider:getLayoutTypeForIndex(i)
		if oldLayout and oldLayout.isOverridden and oldLayout.type == layoutType then
			itemDim.height = oldLayout.height
			itemDim.width = oldLayout.width
		else
			self._layoutProvider:setComputedLayout(layoutType, itemDim, i)
		end
		self:setMaxBounds(itemDim)
		while not self:_checkBounds(startX, startY, itemDim, self._isHorizontal) do
			if self._isHorizontal then
				startX += maxBound
				startY = 0
				self._totalWidth += maxBound
			else
				startX = 0
				startY += maxBound
				self._totalHeight += maxBound
			end
			maxBound = 0
		end

		maxBound = if self._isHorizontal
			then math.max(maxBound, itemDim.width)
			else math.max(maxBound, itemDim.height)

		if i > oldItemCount then
			table.insert(self._layouts, {
				x = startX,
				y = startY,
				height = itemDim.height,
				width = itemDim.width,
				type = layoutType,
			})
		else
			itemRect = self._layouts[i]
			itemRect.x = startX
			itemRect.y = startY
			itemRect.type = layoutType
			itemRect.width = itemDim.width
			itemRect.height = itemDim.height
		end

		if self._isHorizontal then
			startY += itemDim.height
		else
			startX += itemDim.width
		end
	end

	if oldItemCount > itemCount then
		Array.splice(self._layouts, itemCount, oldItemCount - itemCount)
	end
	self:_setFinalDimensions(maxBound)
end

function WrapGridLayoutManager_private:_pointDimensionsToRect(itemRect: Layout): ()
	if self._isHorizontal then
		self._totalWidth = itemRect.x
	else
		self._totalHeight = itemRect.y
	end
end

function WrapGridLayoutManager_private:_setFinalDimensions(maxBound: number): ()
	if self._isHorizontal then
		self._totalHeight = self._window.height
		self._totalWidth += maxBound
	else
		self._totalWidth = self._window.width
		self._totalHeight += maxBound
	end
end

function WrapGridLayoutManager_private:_locateFirstNeighbourIndex(
	startIndex: number
): number
	if startIndex == 0 then
		return 0
	end
	local i = startIndex
	while i > 0 do
		if self._isHorizontal then
			if self._layouts[i].y == 0 then
				break
			end
		elseif self._layouts[i].x == 0 then
			break
		end
		i -= 1
	end
	return i
end

function WrapGridLayoutManager_private:_checkBounds(
	itemX: number,
	itemY: number,
	itemDim: Dimension,
	isHorizontal: boolean
): boolean
	return if isHorizontal
		then itemY + itemDim.height <= self._window.height + 0.9
		else itemX + itemDim.width <= self._window.width + 0.9
end

exports.WrapGridLayoutManager = WrapGridLayoutManager

export type Layout = Dimension & Point & { isOverridden: boolean?, type: string | number }
export type Point = { x: number, y: number }

return exports
