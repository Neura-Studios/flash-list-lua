-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/dependencies/GridLayoutProvider.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Error = LuauPolyfill.Error
type Array<T> = LuauPolyfill.Array<T>

local layoutProviderModule = require("./LayoutProvider")
local LayoutProvider = layoutProviderModule.LayoutProvider
type Dimension = layoutProviderModule.Dimension

local layoutManagerModule = require("../layoutmanager/LayoutManager")
type Layout = layoutManagerModule.Layout
type LayoutManager = layoutManagerModule.LayoutManager

local GridLayoutManager = require("../layoutmanager/GridLayoutManager")
type GridLayoutManager = GridLayoutManager.GridLayoutManager
type LayoutProvider = layoutProviderModule.LayoutProvider

export type GridLayoutProvider = LayoutProvider & {
	newLayoutManager: (
		self: GridLayoutProvider,
		renderWindowSize: Dimension,
		isHorizontal: boolean?,
		cachedLayouts: Array<Layout>?
	) -> LayoutManager,
}
type GridLayoutProvider_private = { --
	-- *** PUBLIC ***
	--
	newLayoutManager: (
		self: GridLayoutProvider_private,
		renderWindowSize: Dimension,
		isHorizontal: boolean?,
		cachedLayouts: Array<Layout>?
	) -> LayoutManager,
	--
	-- *** PRIVATE ***
	--
	_getHeightOrWidth: (index: number) -> number,
	_getSpan: (index: number) -> number,
	_maxSpan: number,
	_renderWindowSize: Dimension,
	_isHorizontal: boolean,
	_acceptableRelayoutDelta: number,
	setLayout: (
		self: GridLayoutProvider_private,
		dimension: Dimension,
		index: number
	) -> (),
}
type GridLayoutProvider_statics = {
	new: (
		maxSpan: number,
		getLayoutType: (index: number) -> string | number,
		getSpan: (index: number) -> number,
		-- If horizontal return width while spans will be rowspans. Opposite holds true if not horizontal
		getHeightOrWidth: (index: number) -> number,
		acceptableRelayoutDelta: number?
	) -> GridLayoutProvider,
}

local GridLayoutProvider = (
	setmetatable({}, { __index = LayoutProvider }) :: any
) :: GridLayoutProvider & GridLayoutProvider_statics
local GridLayoutProvider_private =
	(GridLayoutProvider :: any) :: GridLayoutProvider_private & GridLayoutProvider_statics;
(GridLayoutProvider :: any).__index = GridLayoutProvider

function GridLayoutProvider_private.new(
	maxSpan: number,
	getLayoutType: (index: number) -> string | number,
	getSpan: (index: number) -> number,
	getHeightOrWidth: (index: number) -> number,
	acceptableRelayoutDelta: number?
): GridLayoutProvider
	local self = setmetatable({}, GridLayoutProvider)

	self._getLayoutTypeForIndex = getLayoutType
	self._setLayoutForType = function(type_: any, dim: Dimension, index: number)
		(self :: any):setLayout(dim, index)
	end

	self._getHeightOrWidth = getHeightOrWidth
	self._getSpan = getSpan
	self._maxSpan = maxSpan
	self._acceptableRelayoutDelta = if acceptableRelayoutDelta == nil
		then 1
		else acceptableRelayoutDelta
	return (self :: any) :: GridLayoutProvider
end

function GridLayoutProvider_private:newLayoutManager(
	renderWindowSize: Dimension,
	isHorizontal: boolean?,
	cachedLayouts: Array<Layout>?
): LayoutManager
	self._isHorizontal = if isHorizontal == nil then false else isHorizontal
	self._renderWindowSize = renderWindowSize
	return GridLayoutManager.new(
		self :: any,
		renderWindowSize,
		self._getSpan,
		self._maxSpan,
		self._acceptableRelayoutDelta,
		self._isHorizontal,
		cachedLayouts
	)
end

function GridLayoutProvider_private:setLayout(dimension: Dimension, index: number): ()
	local maxSpan: number = self._maxSpan
	local itemSpan: number = self._getSpan(index)
	if itemSpan > maxSpan then
		error(
			Error.new(
				"Item span for index " .. tostring(index) .. " is more than the max span"
			)
		)
	end
	if self._renderWindowSize then
		if self._isHorizontal then
			dimension.width = self._getHeightOrWidth(index)
			dimension.height = self._renderWindowSize.height / maxSpan * itemSpan
		else
			dimension.height = self._getHeightOrWidth(index)
			dimension.width = self._renderWindowSize.width / maxSpan * itemSpan
		end
	else
		error(
			Error.new(
				"setLayout called before layoutmanager was created, cannot be handled"
			)
		)
	end
end

return GridLayoutProvider
