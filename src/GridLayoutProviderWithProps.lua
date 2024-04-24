-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/GridLayoutProviderWithProps.ts

--!nolint LocalShadow

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Object = LuauPolyfill.Object
local extends = LuauPolyfill.extends
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object

local recyclerlistviewModule = require("./recyclerlistview")
type Dimension = recyclerlistviewModule.Dimension
local GridLayoutProvider = recyclerlistviewModule.GridLayoutProvider
type GridLayoutProvider = recyclerlistviewModule.GridLayoutProvider
type Layout = recyclerlistviewModule.Layout
type LayoutManager = recyclerlistviewModule.LayoutManager
local FlashListProps = require("./FlashListProps")
type FlashListProps<T> = FlashListProps.FlashListProps<T>
local AverageWindow = require("./utils/AverageWindow")
type AverageWindow = AverageWindow.AverageWindow
local applyContentContainerInsetForLayoutManager =
	require("./utils/ContentContainerUtils").applyContentContainerInsetForLayoutManager

export type GridLayoutProviderWithProps<T> = GridLayoutProvider & {
	new: (
		maxSpan: number,
		getLayoutType: (
			index: number,
			props: FlashListProps<T>,
			mutableLayout: { span: number?, size: number? }
		) -> string | number,
		getSpan: (
			index: number,
			props: FlashListProps<T>,
			mutableLayout: { span: number?, size: number? }
		) -> number,
		getHeightOrWidth: (
			index: number,
			props: FlashListProps<T>,
			mutableLayout: { span: number?, size: number? }
		) -> number | nil,
		props: FlashListProps<T>,
		acceptableRelayoutDelta: number?
	) -> GridLayoutProviderWithProps<T>,

	--
	-- *** PUBLIC ***
	--
	defaultEstimatedItemSize: number,
	updateProps: (
		self: GridLayoutProviderWithProps<T>,
		props: FlashListProps<T>
	) -> GridLayoutProviderWithProps<T>,
	hasExpired: (self: GridLayoutProviderWithProps<T>) -> any,
	markExpired: (self: GridLayoutProviderWithProps<T>) -> any,
	reportItemLayout: (self: GridLayoutProviderWithProps<T>, index: number) -> any,
	averageItemSize: (self: GridLayoutProviderWithProps<T>) -> any,
	newLayoutManager: (
		self: GridLayoutProviderWithProps<T>,
		renderWindowSize: Dimension,
		isHorizontal: boolean?,
		cachedLayouts: Array<Layout>?
	) -> LayoutManager,

	--
	-- *** PRIVATE ***
	--
	props: FlashListProps<T>,
	layoutObject: Object,
	averageWindow: AverageWindow,
	renderWindowInsets: Dimension,
	_hasExpired: boolean,
	updateCachedDimensions: (
		self: GridLayoutProviderWithProps<T>,
		cachedLayouts: Array<Layout>,
		layoutManager: LayoutManager
	) -> any,
	getCleanLayoutObj: (self: GridLayoutProviderWithProps<T>) -> any,
	getAdjustedRenderWindowSize: (
		self: GridLayoutProviderWithProps<T>,
		renderWindowSize: Dimension
	) -> any,
}

local GridLayoutProviderWithProps
GridLayoutProviderWithProps = extends(
	GridLayoutProvider,
	"GridLayoutProviderWithProps",
	function<T>(
		self: GridLayoutProviderWithProps<T>,
		maxSpan: number,
		getLayoutType: (
			index: number,
			props: FlashListProps<T>,
			mutableLayout: { span: number?, size: number? }
		) -> string | number,
		getSpan: (
			index: number,
			props: FlashListProps<T>,
			mutableLayout: { span: number?, size: number? }
		) -> number,
		getHeightOrWidth: (
			index: number,
			props: FlashListProps<T>,
			mutableLayout: { span: number?, size: number? }
		) -> number | nil,
		props: FlashListProps<T>,
		acceptableRelayoutDelta: number?
	)
		self.layoutObject = { span = nil, size = nil }
		self.renderWindowInsets = { width = 0, height = 0 }
		self._hasExpired = false
		self.defaultEstimatedItemSize = 100

		-- super(
		-- 	maxSpan,
		-- 	(i) => {
		-- 		return getLayoutType(i, this.props, this.getCleanLayoutObj());
		-- 	},
		-- 	(i) => {
		-- 		return getSpan(i, this.props, this.getCleanLayoutObj());
		-- 	},
		-- 	(i) => {
		-- 		return (
		-- 		// Using average item size if no override has been provided by the developer
		-- 		getHeightOrWidth(i, this.props, this.getCleanLayoutObj()) ??
		-- 		this.averageItemSize
		-- 		);
		-- 	},
		-- 	acceptableRelayoutDelta
		-- );
		do
			local maxSpan_ = maxSpan
			local getLayoutType_ = function(i)
				return getLayoutType(i, self.props, self:getCleanLayoutObj())
			end
			local getSpan_ = function(i)
				return getSpan(i, self.props, self:getCleanLayoutObj())
			end
			local getHeightOrWidth_ = function(i)
				-- Using average item size if no override has been provided by the developer
				return getHeightOrWidth(i, self.props, self:getCleanLayoutObj())
					or self:averageItemSize()
			end
			local acceptableRelayoutDelta_ = acceptableRelayoutDelta

			local self = self :: any
			self._getLayoutTypeForIndex = getLayoutType_
			self._setLayoutForType = function(type_: any, dim: Dimension, index: number)
				(self :: any):setLayout(dim, index)
			end

			self._getHeightOrWidth = getHeightOrWidth_
			self._getSpan = getSpan_
			self._maxSpan = maxSpan_
			self._acceptableRelayoutDelta = if acceptableRelayoutDelta_ == nil
				then 1
				else acceptableRelayoutDelta_
		end

		self.props = props
		self.averageWindow = AverageWindow.new(
			1,
			if props.estimatedItemSize ~= nil
				then props.estimatedItemSize
				else self.defaultEstimatedItemSize
		)
		self.renderWindowInsets = GridLayoutProviderWithProps.getAdjustedRenderWindowSize(
			self,
			self.renderWindowInsets
		)
	end
)

function GridLayoutProviderWithProps:updateProps(
	props: FlashListProps<unknown>
): GridLayoutProviderWithProps<unknown>
	local self = self :: GridLayoutProviderWithProps<unknown>
	local newInsetValues = applyContentContainerInsetForLayoutManager(
		{ height = 0, width = 0 },
		props.contentContainerStyle,
		props.horizontal
	)
	local hasExpired = self._hasExpired
		or self.props.numColumns ~= props.numColumns
		or newInsetValues.height ~= self.renderWindowInsets.height
		or newInsetValues.width ~= self.renderWindowInsets.width
	self._hasExpired = hasExpired
	self.renderWindowInsets = newInsetValues
	self.props = props
	return self
end

function GridLayoutProviderWithProps:hasExpired()
	local self = self :: GridLayoutProviderWithProps<unknown>
	return self._hasExpired
end

function GridLayoutProviderWithProps:markExpired()
	local self = self :: GridLayoutProviderWithProps<unknown>
	self._hasExpired = true
end

function GridLayoutProviderWithProps:reportItemLayout(index: number)
	local self = self :: GridLayoutProviderWithProps<unknown>

	local layoutManager: LayoutManager? = self:getLayoutManager()
	local layout = layoutManager and layoutManager:getLayouts()[index]
	if layout then
		-- For the same index we can now return different estimates because average is updated in realtime
		-- Marking the layout as overridden will help layout manager avoid using the average after initial measurement
		layout.isOverridden = true
		self.averageWindow:addValue(
			if self.props.horizontal then layout.width else layout.height
		)
	end
end

function GridLayoutProviderWithProps:averageItemSize()
	local self = self :: GridLayoutProviderWithProps<unknown>
	return self.averageWindow.currentAverage
end

function GridLayoutProviderWithProps:newLayoutManager(
	renderWindowSize: Dimension,
	isHorizontal: boolean?,
	cachedLayouts: Array<Layout>?
): LayoutManager
	local self = self :: GridLayoutProviderWithProps<unknown>

	-- Average window is updated whenever a new layout manager is created. This is because old values are not relevant anymore.
	local estimatedItemCount = math.max(
		3,
		math.round(
			(
				if self.props.horizontal
					then renderWindowSize.width
					else renderWindowSize.height
			)
				/ (
					if self.props.estimatedItemSize ~= nil
						then self.props.estimatedItemSize
						else self.defaultEstimatedItemSize
				)
		)
	)
	self.averageWindow = AverageWindow.new(
		2 * (self.props.numColumns or 1) * estimatedItemCount,
		self.averageWindow.currentAverage
	)
	local newLayoutManager = GridLayoutProvider.newLayoutManager(
		self,
		self:getAdjustedRenderWindowSize(renderWindowSize),
		isHorizontal,
		cachedLayouts
	)
	if cachedLayouts then
		self:updateCachedDimensions(cachedLayouts, newLayoutManager)
	end
	return newLayoutManager
end

function GridLayoutProviderWithProps:updateCachedDimensions(
	cachedLayouts: Array<Layout>,
	layoutManager: LayoutManager
)
	local layoutCount = #cachedLayouts
	for i = 1, layoutCount do
		cachedLayouts[i] = Object.assign(
			{},
			cachedLayouts[i],
			layoutManager:getStyleOverridesForIndex(i)
		)
	end
end

function GridLayoutProviderWithProps:getCleanLayoutObj()
	local self = self :: GridLayoutProviderWithProps<unknown>
	self.layoutObject.size = nil
	self.layoutObject.span = nil
	return self.layoutObject
end

function GridLayoutProviderWithProps:getAdjustedRenderWindowSize(
	renderWindowSize: Dimension
)
	local self = self :: GridLayoutProviderWithProps<unknown>
	return applyContentContainerInsetForLayoutManager(
		Object.assign({}, renderWindowSize),
		self.props.contentContainerStyle,
		self.props.horizontal
	)
end

return GridLayoutProviderWithProps
