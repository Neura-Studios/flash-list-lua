-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/layoutmanager/GridLayoutManager.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Boolean = LuauPolyfill.Boolean
local Error = LuauPolyfill.Error
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object

local LayoutProvider = require("../dependencies/LayoutProvider")
type LayoutProvider = LayoutProvider.LayoutProvider
type Dimension = LayoutProvider.Dimension
local layoutManagerModule = require("./LayoutManager")
local WrapGridLayoutManager = layoutManagerModule.WrapGridLayoutManager
type WrapGridLayoutManager = layoutManagerModule.WrapGridLayoutManager
type Layout = layoutManagerModule.Layout

export type GridLayoutManager = WrapGridLayoutManager & {
	overrideLayout: (self: GridLayoutManager, index: number, dim: Dimension) -> boolean,
	getStyleOverridesForIndex: (
		self: GridLayoutManager,
		index: number
	) -> Object | Array<unknown> | nil,
}
type GridLayoutManager_private = { --
	-- *** PUBLIC ***
	--
	overrideLayout: (
		self: GridLayoutManager_private,
		index: number,
		dim: Dimension
	) -> boolean,
	getStyleOverridesForIndex: (
		self: GridLayoutManager_private,
		index: number
	) -> Object | Array<unknown> | nil,
	--
	-- *** PRIVATE ***
	--
	_maxSpan: number,
	_getSpan: (index: number) -> number,
	_isGridHorizontal: boolean | nil,
	_renderWindowSize: Dimension,
	_acceptableRelayoutDelta: number,
}
type GridLayoutManager_statics = {
	new: (
		layoutProvider: LayoutProvider,
		renderWindowSize: Dimension,
		getSpan: (index: number) -> number,
		maxSpan: number,
		acceptableRelayoutDelta: number,
		isHorizontal: boolean?,
		cachedLayouts: Array<Layout>?
	) -> GridLayoutManager,
}

local GridLayoutManager = (
	setmetatable({}, { __index = WrapGridLayoutManager }) :: any
) :: GridLayoutManager & GridLayoutManager_statics
local GridLayoutManager_private = (
	GridLayoutManager :: any
) :: GridLayoutManager_private & GridLayoutManager_statics;
(GridLayoutManager :: any).__index = GridLayoutManager

function GridLayoutManager_private.new(
	layoutProvider: LayoutProvider,
	renderWindowSize: Dimension,
	getSpan: (index: number) -> number,
	maxSpan: number,
	acceptableRelayoutDelta: number,
	isHorizontal_: boolean?,
	cachedLayouts: Array<Layout>?
): GridLayoutManager
	local self = setmetatable({}, GridLayoutManager)

	-- ROBLOX deviation: Manually do the constructor logic from super class because
	--  we can't run `super` in Lua.
	local isHorizontal: boolean = if isHorizontal_ ~= nil then isHorizontal_ else false
	do
		self._layoutProvider = layoutProvider
		self._window = renderWindowSize
		self._totalHeight = 0
		self._totalWidth = 0
		self._isHorizontal = not not isHorizontal
		self._layouts = if cachedLayouts then cachedLayouts else {}
	end

	self._getSpan = getSpan
	self._isGridHorizontal = isHorizontal
	self._renderWindowSize = renderWindowSize
	if acceptableRelayoutDelta < 0 then
		error(Error.new("acceptableRelayoutDelta cannot be less than 0"))
	else
		self._acceptableRelayoutDelta = acceptableRelayoutDelta
	end
	if maxSpan <= 0 then
		error(Error.new("Max Column Span cannot be less than or equal to 0"))
	else
		self._maxSpan = maxSpan
	end
	return (self :: any) :: GridLayoutManager
end

function GridLayoutManager_private:overrideLayout(index: number, dim: Dimension): boolean
	-- we are doing this because - when we provide decimal dimensions for a
	-- certain cell - the onlayout returns a different dimension in certain high end devices.
	-- This causes the layouting to behave weirdly as the new dimension might not adhere to the spans and the cells arrange themselves differently
	-- So, whenever we have layouts for a certain index, we explicitly override the dimension to those very layout values
	-- and call super so as to set the overridden flag as true
	local layout = (self :: any):getLayouts()[index]
	local heightDiff = math.abs(dim.height - layout.height)
	local widthDiff = math.abs(dim.width - layout.width)
	if Boolean.toJSBoolean(layout) then
		if self._isGridHorizontal then
			if heightDiff < self._acceptableRelayoutDelta then
				if widthDiff == 0 then
					return false
				end
				dim.height = layout.height
			end
		else
			if widthDiff < self._acceptableRelayoutDelta then
				if heightDiff == 0 then
					return false
				end
				dim.width = layout.width
			end
		end
	end

	-- ROBLOX deviation: We can't call `super` in Lua, so we have to manually call the
	--  super method.
	return WrapGridLayoutManager.overrideLayout(self :: any, index, dim)
end

function GridLayoutManager_private:getStyleOverridesForIndex(
	index: number
): Object | Array<unknown> | nil
	local columnSpanForIndex = self._getSpan(index)
	return if self._isGridHorizontal
		then {
			height = self._renderWindowSize.height / self._maxSpan * columnSpanForIndex,
		}
		else {
			width = self._renderWindowSize.width / self._maxSpan * columnSpanForIndex,
		}
end

return GridLayoutManager
