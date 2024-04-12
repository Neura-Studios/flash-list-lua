-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/dependencies/LayoutProvider.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
type Array<T> = LuauPolyfill.Array<T>

local exports = {}

local layoutManagerModule = require("../layoutmanager/LayoutManager")
local WrapGridLayoutManager = layoutManagerModule.WrapGridLayoutManager

type Layout = any
type LayoutManager = any
type WrapGridLayoutManager = any

--[[
	Created by talha.naqvi on 05/04/17.

	You can create a new instance or inherit and override default methods
	You may need access to data provider here, it might make sense to pass a function which lets you fetch the latest data provider
	Why only indexes? The answer is to allow data virtualization in the future. Since layouts are accessed much before the actual render assuming having all
	data upfront will only limit possibilities in the future.

	By design LayoutProvider forces you to think in terms of view types. What that means is that you'll always be dealing with a finite set of view templates
	with deterministic dimensions. We want to eliminate unnecessary re-layouts that happen when height, by mistake, is not taken into consideration.
 	This patters ensures that your scrolling is as smooth as it gets. You can always increase the number of types to handle non deterministic scenarios.

	NOTE: You can also implement features such as ListView/GridView switch by simple changing your layout provider.
]]

export type BaseLayoutProvider = {
	-- Unset if your new layout provider doesn't require firstVisibleIndex preservation on application
	shouldRefreshWithAnchoring: boolean,
	getLayoutTypeForIndex: (self: BaseLayoutProvider, index: number) -> string | number,

	-- Check if given dimension contradicts with your layout provider, return true for mismatches. Returning true will
	-- cause a relayout to fix the discrepancy
	checkDimensionDiscrepancy: (
		self: BaseLayoutProvider,
		dimension: Dimension,
		type_: any,
		index: number
	) -> boolean,
	createLayoutManager: (
		self: BaseLayoutProvider,
		renderWindowSize: Dimension,
		isHorizontal: boolean?,
		cachedLayouts: Array<Layout>?
	) -> LayoutManager,
	getLayoutManager: (self: BaseLayoutProvider) -> LayoutManager | nil,
}
type BaseLayoutProvider_private = { --
	-- *** PUBLIC ***
	--
	shouldRefreshWithAnchoring: boolean,
	getLayoutTypeForIndex: (
		self: BaseLayoutProvider_private,
		index: number
	) -> string | number,
	checkDimensionDiscrepancy: (
		self: BaseLayoutProvider_private,
		dimension: Dimension,
		type_: any,
		index: number
	) -> boolean,
	createLayoutManager: (
		self: BaseLayoutProvider_private,
		renderWindowSize: Dimension,
		isHorizontal: boolean?,
		cachedLayouts: Array<Layout>?
	) -> LayoutManager,
	getLayoutManager: (self: BaseLayoutProvider_private) -> LayoutManager | nil,
	--
	-- *** PROTECTED ***
	--
	--Return your layout manager, you get all required dependencies here. Also, make sure to use cachedLayouts. RLV might cache layouts and give back to
	--in cases of context preservation. Make sure you use them if provided.
	-- IMP: Output of this method should be cached in lastLayoutManager. It's not required to be cached, but it's good for internal optimization.
	newLayoutManager: (
		self: BaseLayoutProvider_private,
		renderWindowSize: Dimension,
		isHorizontal: boolean?,
		cachedLayouts: Array<Layout>?
	) -> LayoutManager,
	--
	-- *** PRIVATE ***
	--
	_lastLayoutManager: LayoutManager, --Given an index a provider is expected to return a view type which used to recycling choices
}

type BaseLayoutProvider_statics = { new: () -> BaseLayoutProvider }
local BaseLayoutProvider = {} :: BaseLayoutProvider & BaseLayoutProvider_statics
local BaseLayoutProvider_private =
	BaseLayoutProvider :: BaseLayoutProvider_private & BaseLayoutProvider_statics;
(BaseLayoutProvider :: any).__index = BaseLayoutProvider

function BaseLayoutProvider_private.new(): BaseLayoutProvider
	local self = setmetatable({}, BaseLayoutProvider)
	self.shouldRefreshWithAnchoring = true
	return (self :: any) :: BaseLayoutProvider
end

function BaseLayoutProvider_private:getLayoutTypeForIndex(index: number): string | number
	error("not implemented abstract method")
end

function BaseLayoutProvider_private:checkDimensionDiscrepancy(
	dimension: Dimension,
	type_,
	index: number
): boolean
	error("not implemented abstract method")
end

function BaseLayoutProvider_private:createLayoutManager(
	renderWindowSize: Dimension,
	isHorizontal: boolean?,
	cachedLayouts: Array<Layout>?
): LayoutManager
	self._lastLayoutManager =
		self:newLayoutManager(renderWindowSize, isHorizontal, cachedLayouts)
	return self._lastLayoutManager
end

function BaseLayoutProvider_private:getLayoutManager(): LayoutManager | nil
	return self._lastLayoutManager
end

function BaseLayoutProvider_private:newLayoutManager(
	renderWindowSize: Dimension,
	isHorizontal: boolean?,
	cachedLayouts: Array<Layout>?
): LayoutManager
	error("not implemented abstract method")
end

exports.BaseLayoutProvider = BaseLayoutProvider

export type LayoutProvider = BaseLayoutProvider & {
	newLayoutManager: (
		self: LayoutProvider,
		renderWindowSize: Dimension,
		isHorizontal: boolean?,
		cachedLayouts: Array<Layout>?
	) -> LayoutManager,
	-- Provide a type for index, something which identifies the template of view about to load
	getLayoutTypeForIndex: (self: LayoutProvider, index: number) -> string | number,
	-- Given a type and dimension set the dimension values on given dimension object
	-- You can also get index here if you add an extra argument but we don't recommend using it.
	setComputedLayout: (
		self: LayoutProvider,
		type_: any,
		dimension: Dimension,
		index: number
	) -> (),
	checkDimensionDiscrepancy: (
		self: LayoutProvider,
		dimension: Dimension,
		type_: any,
		index: number
	) -> boolean,
}
type LayoutProvider_private = BaseLayoutProvider & { --
	-- *** PUBLIC ***
	--
	newLayoutManager: (
		self: LayoutProvider_private,
		renderWindowSize: Dimension,
		isHorizontal: boolean?,
		cachedLayouts: Array<Layout>?
	) -> LayoutManager,
	getLayoutTypeForIndex: (
		self: LayoutProvider_private,
		index: number
	) -> string | number,
	setComputedLayout: (
		self: LayoutProvider_private,
		type_: any,
		dimension: Dimension,
		index: number
	) -> (),
	checkDimensionDiscrepancy: (
		self: LayoutProvider_private,
		dimension: Dimension,
		type_: any,
		index: number
	) -> boolean,
	--
	-- *** PRIVATE ***
	--
	_getLayoutTypeForIndex: (index: number) -> string | number,
	_setLayoutForType: (type_: any, dim: Dimension, index: number) -> (),
	_tempDim: Dimension,
}
type LayoutProvider_statics = {
	new: (
		getLayoutTypeForIndex: (index: number) -> string | number,
		setLayoutForType: (type_: any, dim: Dimension, index: number) -> ()
	) -> LayoutProvider,
}

local LayoutProvider = (
	setmetatable({}, { __index = BaseLayoutProvider }) :: any
) :: LayoutProvider & LayoutProvider_statics
local LayoutProvider_private =
	LayoutProvider :: LayoutProvider_private & LayoutProvider_statics;
(LayoutProvider :: any).__index = LayoutProvider

function LayoutProvider_private.new(
	getLayoutTypeForIndex: (index: number) -> string | number,
	setLayoutForType: (type_: any, dim: Dimension, index: number) -> ()
): LayoutProvider
	local self = setmetatable({}, LayoutProvider)
	self._getLayoutTypeForIndex = getLayoutTypeForIndex
	self._setLayoutForType = setLayoutForType
	self._tempDim = { height = 0, width = 0 }
	return (self :: any) :: LayoutProvider
end

function LayoutProvider_private:newLayoutManager(
	renderWindowSize: Dimension,
	isHorizontal: boolean?,
	cachedLayouts: Array<Layout>?
): LayoutManager
	return WrapGridLayoutManager.new(self, renderWindowSize, isHorizontal, cachedLayouts)
end

function LayoutProvider_private:getLayoutTypeForIndex(index: number): string | number
	return (self :: any)._getLayoutTypeForIndex(index)
end

function LayoutProvider_private:setComputedLayout(
	type_,
	dimension: Dimension,
	index: number
): ()
	return self._setLayoutForType(type_, dimension, index)
end

function LayoutProvider_private:checkDimensionDiscrepancy(
	dimension: Dimension,
	type_,
	index: number
): boolean
	local dimension1 = dimension;
	(self :: any):setComputedLayout(type_, (self :: any)._tempDim, index)
	local dimension2 = (self :: any)._tempDim
	local layoutManager = self:getLayoutManager()
	if layoutManager then
		layoutManager:setMaxBounds(dimension2)
	end
	return dimension1.height ~= dimension2.height or dimension1.width ~= dimension2.width
end
exports.LayoutProvider = LayoutProvider

export type Dimension = { height: number, width: number }

return exports
