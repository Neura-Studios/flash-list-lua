-- Similarly, data should never be `null | undefined` when `getStableId` is called.
-- Similarly, data should never be `null | undefined` when `getStableId` is called.
-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/FlashList.tsx
local Packages --[[ ROBLOX comment: must define Packages module ]]
local LuauPolyfill = require(Packages.LuauPolyfill)
local Boolean = LuauPolyfill.Boolean
local Object = LuauPolyfill.Object
local clearTimeout = LuauPolyfill.clearTimeout
local console = LuauPolyfill.console
local setTimeout = LuauPolyfill.setTimeout
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object
type Readonly<T> = T --[[ ROBLOX TODO: TS 'Readonly' built-in type is not available in Luau ]]
type ReturnType<T> = any --[[ ROBLOX TODO: TS 'ReturnType' built-in type is not available in Luau ]]
local exports = {}
local function _extends()
	_extends = Boolean.toJSBoolean(Object.assign) and Object.assign
		or function(target)
			do
				local i = 1
				while
					i
					< arguments.length --[[ ROBLOX CHECK: operator '<' works only if either both arguments are strings or both are a number ]]
				do
					local source = arguments[tostring(i)]
					for key in source do
						if
							Boolean.toJSBoolean(
								Object.prototype.hasOwnProperty(source, key)
							)
						then
							target[tostring(key)] = source[tostring(key)]
						end
					end
					i += 1
				end
			end
			return target
		end
	return _extends(self, table.unpack(arguments))
end
local React = require(Packages.react).default
local reactNativeModule = require(Packages["react-native"])
local View = reactNativeModule.View
local RefreshControl = reactNativeModule.RefreshControl
local LayoutChangeEvent = reactNativeModule.LayoutChangeEvent
local NativeSyntheticEvent = reactNativeModule.NativeSyntheticEvent
local StyleSheet = reactNativeModule.StyleSheet
local NativeScrollEvent = reactNativeModule.NativeScrollEvent
local recyclerlistviewModule = require(Packages.recyclerlistview)
local BaseItemAnimator = recyclerlistviewModule.BaseItemAnimator
local DataProvider = recyclerlistviewModule.DataProvider
local ProgressiveListView = recyclerlistviewModule.ProgressiveListView
local RecyclerListView = recyclerlistviewModule.RecyclerListView
local RecyclerListViewProps = recyclerlistviewModule.RecyclerListViewProps
local WindowCorrectionConfig = recyclerlistviewModule.WindowCorrectionConfig
local recyclerlistviewStickyModule = require(Packages.recyclerlistview.sticky)
local StickyContainer = recyclerlistviewStickyModule.default
local StickyContainerProps = recyclerlistviewStickyModule.StickyContainerProps
local AutoLayoutView = require(script.Parent.native["auto-layout"].AutoLayoutView).default
local CellContainer =
	require(script.Parent.native["cell-container"].CellContainer).default
local PureComponentWrapper =
	require(script.Parent.PureComponentWrapper).PureComponentWrapper
local GridLayoutProviderWithProps =
	require(script.Parent.GridLayoutProviderWithProps).default
local CustomError = require(script.Parent.errors.CustomError).default
local ExceptionList = require(script.Parent.errors.ExceptionList).default
local WarningList = require(script.Parent.errors.Warnings).default
local ViewabilityManager = require(script.Parent.viewability.ViewabilityManager).default
local flashListPropsModule = require(script.Parent.FlashListProps)
local FlashListProps = flashListPropsModule.FlashListProps
local RenderTarget = flashListPropsModule.RenderTarget
local RenderTargetOptions = flashListPropsModule.RenderTargetOptions
local platformHelperModule = require(script.Parent.native.config.PlatformHelper)
local getCellContainerPlatformStyles = platformHelperModule.getCellContainerPlatformStyles
local getFooterContainer = platformHelperModule.getFooterContainer
local getItemAnimator = platformHelperModule.getItemAnimator
local PlatformConfig = platformHelperModule.PlatformConfig
local contentContainerUtilsModule = require(script.Parent.utils.ContentContainerUtils)
local ContentStyleExplicit = contentContainerUtilsModule.ContentStyleExplicit
local getContentContainerPadding = contentContainerUtilsModule.getContentContainerPadding
local hasUnsupportedKeysInContentContainerStyle =
	contentContainerUtilsModule.hasUnsupportedKeysInContentContainerStyle
local updateContentStyle = contentContainerUtilsModule.updateContentStyle
type StickyProps = StickyContainerProps & { children: any }
local StickyHeaderContainer = StickyContainer :: React_ComponentClass<StickyProps>
export type FlashListState<T> = {
	dataProvider: DataProvider,
	numColumns: number,
	layoutProvider: GridLayoutProviderWithProps<T>,
	data: (
		ReadonlyArray<T> | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]]
	)?,
	extraData: ExtraData<unknown>?,
	renderItem: typeof((({} :: any) :: FlashListProps<T>).renderItem)?,
}
type ExtraData<T> = { value: T? }
type FlashList<T> = React_Component<any, any> & { --[[*
   * Disables recycling for the next frame so that layout animations run well.
   * Warning: Avoid this when making large changes to the data as the list might draw too much to run animations. Single item insertions/deletions
   * should be good. With recycling paused the list cannot do much optimization.
   * The next render will run as normal and reuse items.
   ]]
	prepareForLayoutAnimationRender: (self: FlashList) -> (),
	scrollToEnd: (
		self: FlashList,
		params: {
			animated: (boolean | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil)?,
		}?
	) -> any,
	scrollToIndex: (
		self: FlashList,
		params: {
			animated: (boolean | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil)?,
			index: number,
			viewOffset: (number | nil)?,
			viewPosition: (number | nil)?,
		}
	) -> any,
	scrollToItem: (
		self: FlashList,
		params: {
			animated: (boolean | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil)?,
			item: any,
			viewPosition: (number | nil)?,
			viewOffset: (number | nil)?,
		}
	) -> any,
	scrollToOffset: (
		self: FlashList,
		params: {
			animated: (boolean | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil)?,
			offset: number,
		}
	) -> any,
	getScrollableNode: (self: FlashList) -> number | nil,--[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]]
	--[[*
   * Allows access to internal recyclerlistview. This is useful for enabling access to its public APIs.
   * Warning: We may swap recyclerlistview for something else in the future. Use with caution.
   ]]
	--[[ eslint-disable @typescript-eslint/naming-convention ]]
	recyclerlistview_unsafe: (self: FlashList) -> any,
	--[[*
   * Specifies how far the first item is from top of the list. This would normally be a sum of header size and top/left padding applied to the list.
   ]]
	firstItemOffset: (self: FlashList) -> any,
	--[[*
   * FlashList will skip using layout cache on next update. Can be useful when you know the layout will change drastically for example, orientation change when used as a carousel.
   ]]
	clearLayoutCacheOnUpdate: (self: FlashList) -> any,
	--[[*
   * Tells the list an interaction has occurred, which should trigger viewability calculations, e.g. if waitForInteractions is true and the user has not scrolled.
   * This is typically called by taps on items or by navigation actions.
   ]]
	recordInteraction: any,
}
type FlashList_private<T> = { --
	-- *** PUBLIC ***
	--
	prepareForLayoutAnimationRender: (self: FlashList_private) -> (),
	scrollToEnd: (
		self: FlashList_private,
		params: {
			animated: (boolean | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil)?,
		}?
	) -> any,
	scrollToIndex: (
		self: FlashList_private,
		params: {
			animated: (boolean | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil)?,
			index: number,
			viewOffset: (number | nil)?,
			viewPosition: (number | nil)?,
		}
	) -> any,
	scrollToItem: (
		self: FlashList_private,
		params: {
			animated: (boolean | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil)?,
			item: any,
			viewPosition: (number | nil)?,
			viewOffset: (number | nil)?,
		}
	) -> any,
	scrollToOffset: (
		self: FlashList_private,
		params: {
			animated: (boolean | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil)?,
			offset: number,
		}
	) -> any,
	getScrollableNode: (self: FlashList_private) -> number | nil,--[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]]
	recyclerlistview_unsafe: (self: FlashList_private) -> any,
	firstItemOffset: (self: FlashList_private) -> any,
	clearLayoutCacheOnUpdate: (self: FlashList_private) -> any,
	recordInteraction: any,
	--
	-- *** PRIVATE ***
	--
	rlvRef: RecyclerListView<RecyclerListViewProps, any>,
	stickyContentContainerRef: PureComponentWrapper,
	listFixedDimensionSize: number,
	transformStyle: any,
	transformStyleHorizontal: any,
	distanceFromWindow: number,
	contentStyle: ContentStyleExplicit,
	loadStartTime: number,
	isListLoaded: boolean,
	windowCorrectionConfig: WindowCorrectionConfig,
	postLoadTimeoutId: ReturnType<typeof(setTimeout)>,
	itemSizeWarningTimeoutId: ReturnType<typeof(setTimeout)>,
	renderedSizeWarningTimeoutId: ReturnType<typeof(setTimeout)>,
	isEmptyList: boolean,
	viewabilityManager: ViewabilityManager<T>,
	itemAnimator: BaseItemAnimator,
	validateProps: (self: FlashList_private) -> any, -- Some of the state variables need to update when props change
	onEndReached: any,
	getRefreshControl: any,
	onScrollBeginDrag: any,
	onScroll: any,
	getUpdatedWindowCorrectionConfig: (self: FlashList_private) -> any,
	isInitialScrollIndexInFirstRow: (self: FlashList_private) -> any,
	validateListSize: (self: FlashList_private, event: LayoutChangeEvent) -> any,
	handleSizeChange: any,
	container: any,
	itemContainer: any,
	updateDistanceFromWindow: any,
	getTransform: (self: FlashList_private) -> any,
	separator: any,
	header: any,
	footer: any,
	getComponentForHeightMeasurement: any,
	getValidComponent: (
		self: FlashList_private,
		component: React_ComponentType | React_ReactElement | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil
	) -> any,
	applyWindowCorrection: any,
	rowRendererSticky: any,
	rowRendererWithIndex: any,
	--[[*
   * This will prevent render item calls unless data changes.
   * Output of this method is received as children object so returning null here is no issue as long as we handle it inside our child container.
   * @module getCellContainerChild acts as the new rowRenderer and is called directly from our child container.
   ]]
	emptyRowRenderer: any,
	getCellContainerChild: any,
	recyclerRef: any,
	stickyContentRef: any,
	stickyOverrideRowRenderer: any,
	isStickyEnabled: (self: FlashList_private) -> any,
	onItemLayout: any,
	raiseOnLoadEventIfNeeded: any,
	runAfterOnLoad: any,
	clearPostLoadTimeout: any,
	clearRenderSizeWarningTimeout: any,
} --[[ ROBLOX comment: Unhandled superclass type: LuaMemberExpression ]]
type FlashList_statics = {}
local FlashList = React.PureComponent:extend("FlashList") :: FlashList & FlashList_statics
local FlashList_private = FlashList :: FlashList_private<any> & FlashList_statics
FlashList.defaultProps = { data = {}, numColumns = 1 }
function FlashList_private.init(self: FlashList_private, props: FlashListProps<T>)
	self.listFixedDimensionSize = 0
	self.transformStyle = PlatformConfig.invertedTransformStyle
	self.transformStyleHorizontal = PlatformConfig.invertedTransformStyleHorizontal
	self.distanceFromWindow = 0
	self.contentStyle =
		{ paddingBottom = 0, paddingTop = 0, paddingLeft = 0, paddingRight = 0 }
	self.loadStartTime = 0
	self.isListLoaded = false
	self.windowCorrectionConfig = {
		value = { windowShift = 0, startCorrection = 0, endCorrection = 0 },
		applyToItemScroll = true,
		applyToInitialOffset = true,
	}
	self.isEmptyList = false
	self.onEndReached = function()
		if self.props.onEndReached ~= nil then
			self.props.onEndReached()
		end
	end
	self.getRefreshControl = function()
		if Boolean.toJSBoolean(self.props.onRefresh) then
			return React.createElement(RefreshControl, {
				refreshing = Boolean(self.props.refreshing),
				progressViewOffset = self.props.progressViewOffset,
				onRefresh = self.props.onRefresh,
			})
		end
	end
	self.onScrollBeginDrag = function(event: NativeSyntheticEvent<NativeScrollEvent>)
		self:recordInteraction()
		if self.props.onScrollBeginDrag ~= nil then
			self.props.onScrollBeginDrag(event)
		end
	end
	self.onScroll = function(event: NativeSyntheticEvent<NativeScrollEvent>)
		self:recordInteraction()
		self.viewabilityManager:updateViewableItems()
		if self.props.onScroll ~= nil then
			self.props.onScroll(event)
		end
	end
	self.handleSizeChange = function(event: LayoutChangeEvent)
		self:validateListSize(event)
		local newSize = if Boolean.toJSBoolean(self.props.horizontal)
			then event.nativeEvent.layout.height
			else event.nativeEvent.layout.width
		local oldSize = self.listFixedDimensionSize
		self.listFixedDimensionSize = newSize -- >0 check is to avoid rerender on mount where it would be redundant
		if
			oldSize > 0 --[[ ROBLOX CHECK: operator '>' works only if either both arguments are strings or both are a number ]]
			and oldSize ~= newSize
		then
			local ref = if typeof(self.rlvRef) == "table"
				then self.rlvRef.forceRerender
				else nil
			if ref ~= nil then
				ref()
			end
		end
		if Boolean.toJSBoolean(self.props.onLayout) then
			self.props:onLayout(event)
		end
	end
	self.container = function(
		props: Object | Array<unknown>,
		children: Array<React_ReactNode>
	)
		self:clearPostLoadTimeout()
		return React.createElement(
			React.Fragment,
			nil,
			React.createElement(PureComponentWrapper, {
				enabled = (function()
					local ref = Boolean.toJSBoolean(self.isListLoaded)
							and self.isListLoaded
						or children.length > 0 --[[ ROBLOX CHECK: operator '>' works only if either both arguments are strings or both are a number ]]
					return Boolean.toJSBoolean(ref) and ref or self.isEmptyList
				end)(),
				contentStyle = self.props.contentContainerStyle,
				horizontal = self.props.horizontal,
				header = self.props.ListHeaderComponent,
				extraData = self.state.extraData,
				headerStyle = self.props.ListHeaderComponentStyle,
				inverted = self.props.inverted,
				renderer = self.header,
			}),
			React.createElement(
				AutoLayoutView,
				_extends({}, props, {
					onBlankAreaEvent = self.props.onBlankArea,
					onLayout = self.updateDistanceFromWindow,
					disableAutoLayout = self.props.disableAutoLayout,
				}),
				children
			),
			if Boolean.toJSBoolean(self.isEmptyList)
				then self:getValidComponent(self.props.ListEmptyComponent)
				else nil,
			React.createElement(PureComponentWrapper, {
				enabled = (function()
					local ref = Boolean.toJSBoolean(self.isListLoaded)
							and self.isListLoaded
						or children.length > 0 --[[ ROBLOX CHECK: operator '>' works only if either both arguments are strings or both are a number ]]
					return Boolean.toJSBoolean(ref) and ref or self.isEmptyList
				end)(),
				contentStyle = self.props.contentContainerStyle,
				horizontal = self.props.horizontal,
				header = self.props.ListFooterComponent,
				extraData = self.state.extraData,
				headerStyle = self.props.ListFooterComponentStyle,
				inverted = self.props.inverted,
				renderer = self.footer,
			}),
			self:getComponentForHeightMeasurement()
		)
	end
	self.itemContainer = function(props: any, parentProps: any)
		local CellRendererComponent = if self.props.CellRendererComponent ~= nil
			then self.props.CellRendererComponent
			else CellContainer
		return React.createElement(
			CellRendererComponent,
			_extends({}, props, {
				style = Object.assign(
					{},
					props.style,
					{
						flexDirection = if Boolean.toJSBoolean(self.props.horizontal)
							then "row"
							else "column",
						alignItems = "stretch",
					},
					self:getTransform(),
					getCellContainerPlatformStyles(
						self.props.inverted :: any,
						parentProps
					)
				),
				index = parentProps.index,
			}),
			React.createElement(PureComponentWrapper, {
				extendedState = parentProps.extendedState,
				internalSnapshot = parentProps.internalSnapshot,
				data = parentProps.data,
				arg = parentProps.index,
				renderer = self.getCellContainerChild,
			})
		)
	end
	self.updateDistanceFromWindow = function(event: LayoutChangeEvent)
		local newDistanceFromWindow = if Boolean.toJSBoolean(self.props.horizontal)
			then event.nativeEvent.layout.x
			else event.nativeEvent.layout.y
		if self.distanceFromWindow ~= newDistanceFromWindow then
			self.distanceFromWindow = newDistanceFromWindow
			self.windowCorrectionConfig.value.windowShift = -self.distanceFromWindow
			self.viewabilityManager:updateViewableItems()
		end
	end
	self.separator = function(index: number)
		-- Make sure we have data and don't read out of bounds
		if
			self.props.data == nil
			or self.props.data == nil
			or index + 1 >= self.props.data.length --[[ ROBLOX CHECK: operator '>=' works only if either both arguments are strings or both are a number ]]
		then
			return nil
		end
		local leadingItem = self.props.data[tostring(index)]
		local trailingItem = self.props.data[tostring(index + 1)]
		local props = {
			leadingItem = leadingItem,
			trailingItem = trailingItem, -- TODO: Missing sections as we don't have this feature implemented yet. Implement section, leadingSection and trailingSection.
			-- https://github.com/facebook/react-native/blob/8bd3edec88148d0ab1f225d2119435681fbbba33/Libraries/Lists/VirtualizedSectionList.js#L285-L294
		}
		local Separator = self.props.ItemSeparatorComponent
		return if Boolean.toJSBoolean(Separator)
			then React.createElement(Separator, props)
			else Separator
	end
	self.header = function()
		return React.createElement(
			React.Fragment,
			nil,
			React.createElement(View, {
				style = {
					paddingTop = self.contentStyle.paddingTop,
					paddingLeft = self.contentStyle.paddingLeft,
				},
			}),
			React.createElement(
				View,
				{ style = { self.props.ListHeaderComponentStyle, self:getTransform() } },
				self:getValidComponent(self.props.ListHeaderComponent)
			)
		)
	end
	self.footer = function()
		--[[* The web version of CellContainer uses a div directly which doesn't compose styles the way a View does.
     * We will skip using CellContainer on web to avoid this issue. `getFooterContainer` on web will
     * return a View. ]]
		local ref = getFooterContainer()
		local FooterContainer = if ref ~= nil then ref else CellContainer
		return React.createElement(
			React.Fragment,
			nil,
			React.createElement(
				FooterContainer,
				{
					index = -1,
					style = { self.props.ListFooterComponentStyle, self:getTransform() },
				},
				self:getValidComponent(self.props.ListFooterComponent)
			),
			React.createElement(View, {
				style = {
					paddingBottom = self.contentStyle.paddingBottom,
					paddingRight = self.contentStyle.paddingRight,
				},
			})
		)
	end
	self.getComponentForHeightMeasurement = function()
		return if Boolean.toJSBoolean((function()
				local ref = if Boolean.toJSBoolean(self.props.horizontal)
					then not Boolean.toJSBoolean(
						self.props.disableHorizontalListHeightMeasurement
					)
					else self.props.horizontal
				local ref = if Boolean.toJSBoolean(ref)
					then not Boolean.toJSBoolean(self.isListLoaded)
					else ref
				return if Boolean.toJSBoolean(ref)
					then self.state.dataProvider:getSize()
						> 0 --[[ ROBLOX CHECK: operator '>' works only if either both arguments are strings or both are a number ]]
					else ref
			end)())
			then React.createElement(
				View,
				{ style = { opacity = 0 }, pointerEvents = "none" },
				self:rowRendererWithIndex(
					math.min(self.state.dataProvider:getSize() - 1, 1),
					RenderTargetOptions.Measurement
				)
			)
			else nil
	end
	self.applyWindowCorrection = function(
		_: any,
		__: any,
		correctionObject: { windowShift: number }
	)
		correctionObject.windowShift = -self.distanceFromWindow
		local ref = if typeof(self.stickyContentContainerRef) == "table"
			then self.stickyContentContainerRef.setEnabled
			else nil
		if ref ~= nil then
			ref(self.isStickyEnabled)
		end
	end
	self.rowRendererSticky = function(index: number)
		return self:rowRendererWithIndex(index, RenderTargetOptions.StickyHeader)
	end
	self.rowRendererWithIndex = function(index: number, target: RenderTarget)
		-- known issue: expected to pass separators which isn't available in RLV
		return if self.props.renderItem ~= nil
			then self.props.renderItem({
				item = (self.props.data :: any)[tostring(index)],
				index = index,
				target = target,
				extraData = if typeof(self.state.extraData) == "table"
					then self.state.extraData.value
					else nil,
			})
			else nil :: JSX_Element
	end
	self.emptyRowRenderer = function()
		return nil
	end
	self.getCellContainerChild = function(index: number)
		return React.createElement(
			React.Fragment,
			nil,
			if Boolean.toJSBoolean(self.props.inverted)
				then self:separator(index)
				else nil,
			React.createElement(View, {
				style = {
					flexDirection = if Boolean.toJSBoolean(
							Boolean.toJSBoolean(self.props.horizontal)
									and self.props.horizontal
								or self.props.numColumns == 1
						)
						then "column"
						else "row",
				},
			}, self:rowRendererWithIndex(index, RenderTargetOptions.Cell)),
			if Boolean.toJSBoolean(self.props.inverted)
				then nil
				else self:separator(index)
		)
	end
	self.recyclerRef = function(ref: any)
		self.rlvRef = ref
	end
	self.stickyContentRef = function(ref: any)
		self.stickyContentContainerRef = ref
	end
	self.stickyOverrideRowRenderer = function(_: any, __: any, index: number, ___: any)
		return React.createElement(PureComponentWrapper, {
			ref = self.stickyContentRef,
			enabled = self.isStickyEnabled,
			arg = index,
			renderer = self.rowRendererSticky,
		})
	end
	self.onItemLayout = function(index: number)
		-- Informing the layout provider about change to an item's layout. It already knows the dimensions so there's not need to pass them.
		self.state.layoutProvider:reportItemLayout(index)
		self:raiseOnLoadEventIfNeeded()
	end
	self.raiseOnLoadEventIfNeeded = function()
		if not Boolean.toJSBoolean(self.isListLoaded) then
			self.isListLoaded = true
			if self.props.onLoad ~= nil then
				self.props.onLoad({
					elapsedTimeInMs = DateTime.now().UnixTimestampMillis
						- self.loadStartTime,
				})
			end
			self:runAfterOnLoad()
		end
	end
	self.runAfterOnLoad = function()
		if self.props.estimatedItemSize == nil then
			self.itemSizeWarningTimeoutId = setTimeout(function()
				local averageItemSize =
					math.floor(self.state.layoutProvider.averageItemSize)
				console.warn(
					WarningList.estimatedItemSizeMissingWarning:replace(
						"@size",
						tostring(averageItemSize)
					)
				)
			end, 1000)
		end
		self.postLoadTimeoutId = setTimeout(function()
			-- This force update is required to remove dummy element rendered to measure horizontal list height when  the list doesn't update on its own.
			-- In most cases this timeout will never be triggered because list usually updates atleast once and this timeout is cleared on update.
			if Boolean.toJSBoolean(self.props.horizontal) then
				self:forceUpdate()
			end
		end, 500)
	end
	self.clearPostLoadTimeout = function()
		if self.postLoadTimeoutId ~= nil then
			clearTimeout(self.postLoadTimeoutId)
			self.postLoadTimeoutId = nil
		end
	end
	self.clearRenderSizeWarningTimeout = function()
		if self.renderedSizeWarningTimeoutId ~= nil then
			clearTimeout(self.renderedSizeWarningTimeoutId)
			self.renderedSizeWarningTimeoutId = nil
		end
	end
	self.recordInteraction = function()
		self.viewabilityManager:recordInteraction()
	end
	self.loadStartTime = DateTime.now().UnixTimestampMillis
	self:validateProps()
	if Boolean.toJSBoolean(props.estimatedListSize) then
		if Boolean.toJSBoolean(props.horizontal) then
			self.listFixedDimensionSize = props.estimatedListSize.height
		else
			self.listFixedDimensionSize = props.estimatedListSize.width
		end
	end
	self.distanceFromWindow = if props.estimatedFirstItemOffset ~= nil
		then props.estimatedFirstItemOffset
		else (function()
			local ref = if Boolean.toJSBoolean(props.ListHeaderComponent)
				then 1
				else props.ListHeaderComponent
			return Boolean.toJSBoolean(ref) and ref or 0
		end)() -- eslint-disable-next-line react/state-in-constructor
	self.state = FlashList:getInitialMutableState(self)
	self.viewabilityManager = ViewabilityManager.new(self)
	self.itemAnimator = getItemAnimator()
end
function FlashList_private:validateProps()
	if
		Boolean.toJSBoolean(
			if Boolean.toJSBoolean(self.props.onRefresh)
				then typeof(self.props.refreshing) ~= "boolean"
				else self.props.onRefresh
		)
	then
		error(CustomError.new(ExceptionList.refreshBooleanMissing))
	end
	if
		Boolean.toJSBoolean(
			Number(
				if typeof(self.props.stickyHeaderIndices) == "table"
					then self.props.stickyHeaderIndices.length
					else nil
			)
					> 0 --[[ ROBLOX CHECK: operator '>' works only if either both arguments are strings or both are a number ]]
				and self.props.horizontal
		)
	then
		error(CustomError.new(ExceptionList.stickyWhileHorizontalNotSupported))
	end
	if
		Boolean.toJSBoolean(
			Number(self.props.numColumns) > 1 --[[ ROBLOX CHECK: operator '>' works only if either both arguments are strings or both are a number ]]
				and self.props.horizontal
		)
	then
		error(CustomError.new(ExceptionList.columnsWhileHorizontalNotSupported))
	end -- `createAnimatedComponent` always passes a blank style object. To avoid warning while using AnimatedFlashList we've modified the check
	-- `style` prop can be an array. So we need to validate every object in array. Check: https://github.com/Shopify/flash-list/issues/651
	if
		Boolean.toJSBoolean(if Boolean.toJSBoolean(__DEV__)
			then Object.keys(
				StyleSheet:flatten(
					if self.props.style ~= nil then self.props.style else {}
				)
			).length > 0 --[[ ROBLOX CHECK: operator '>' works only if either both arguments are strings or both are a number ]]
			else __DEV__)
	then
		console.warn(WarningList.styleUnsupported)
	end
	if
		Boolean.toJSBoolean(
			hasUnsupportedKeysInContentContainerStyle(self.props.contentContainerStyle)
		)
	then
		console.warn(WarningList.styleContentContainerUnsupported)
	end
end
function FlashList_private.getDerivedStateFromProps(
	nextProps: Readonly<FlashListProps<T>>,
	prevState: FlashListState<T>
): FlashListState<T>
	local newState = Object.assign({}, prevState)
	if prevState.numColumns ~= nextProps.numColumns then
		newState.numColumns = Boolean.toJSBoolean(nextProps.numColumns)
				and nextProps.numColumns
			or 1
		newState.layoutProvider =
			FlashList:getLayoutProvider(newState.numColumns, nextProps)
	elseif
		Boolean.toJSBoolean(prevState.layoutProvider:updateProps(nextProps).hasExpired)
	then
		newState.layoutProvider =
			FlashList:getLayoutProvider(newState.numColumns, nextProps)
	end -- RLV retries to reposition the first visible item on layout provider change.
	-- It's not required in our case so we're disabling it
	newState.layoutProvider.shouldRefreshWithAnchoring = Boolean(
		not Boolean.toJSBoolean(
			if typeof(prevState.layoutProvider) == "table"
				then prevState.layoutProvider.hasExpired
				else nil
		)
	)
	if nextProps.data ~= prevState.data then
		newState.data = nextProps.data
		newState.dataProvider =
			prevState.dataProvider:cloneWithRows(nextProps.data :: Array<any>)
		if nextProps.renderItem ~= prevState.renderItem then
			newState.extraData = Object.assign({}, prevState.extraData)
		end
	end
	if
		nextProps.extraData
		~= (
			if typeof(prevState.extraData) == "table"
				then prevState.extraData.value
				else nil
		)
	then
		newState.extraData = { value = nextProps.extraData }
	end
	newState.renderItem = nextProps.renderItem
	return newState
end
function FlashList_private.getInitialMutableState(
	flashList: FlashList<T>
): FlashListState<T>
	local getStableId: (index: number) -> string | nil
	if flashList.props.keyExtractor ~= nil and flashList.props.keyExtractor ~= nil then
		getStableId = function(index)
			return -- We assume `keyExtractor` function will never change from being `null | undefined` to defined and vice versa.
				-- Similarly, data should never be `null | undefined` when `getStableId` is called.
				tostring(
				(flashList.props.keyExtractor :: any)(
					(flashList.props.data :: any)[tostring(index)],
					index
				)
			)
		end
	end
	return {
		data = nil,
		layoutProvider = nil :: any,
		dataProvider = DataProvider.new(function(r1, r2)
			return r1 ~= r2
		end, getStableId),
		numColumns = 0,
	}
end
function FlashList_private.getLayoutProvider(
	numColumns: number,
	flashListProps: FlashListProps<T>
)
	return GridLayoutProviderWithProps.new( -- max span or, total columns
		numColumns,
		function(index, props)
			-- type of the item for given index
			local type_ = if props.getItemType ~= nil
				then props.getItemType(
					(props.data :: any)[tostring(index)],
					index,
					props.extraData
				)
				else nil
			return Boolean.toJSBoolean(type_) and type_ or 0
		end,
		function(index, props, mutableLayout)
			-- span of the item at given index, item can choose to span more than one column
			if props.overrideItemLayout ~= nil then
				props.overrideItemLayout(
					mutableLayout,
					(props.data :: any)[tostring(index)],
					index,
					numColumns,
					props.extraData
				)
			end
			local ref = if typeof(mutableLayout) == "table"
				then mutableLayout.span
				else nil
			return if ref ~= nil then ref else 1
		end,
		function(index, props, mutableLayout)
			-- estimated size of the item an given index
			if props.overrideItemLayout ~= nil then
				props.overrideItemLayout(
					mutableLayout,
					(props.data :: any)[tostring(index)],
					index,
					numColumns,
					props.extraData
				)
			end
			return if typeof(mutableLayout) == "table" then mutableLayout.size else nil
		end,
		flashListProps
	)
end
function FlashList_private.componentDidMount(self: FlashList_private)
	if
		(if typeof(self.props.data) == "table" then self.props.data.length else nil) == 0
	then
		self:raiseOnLoadEventIfNeeded()
	end
end
function FlashList_private.componentWillUnmount(self: FlashList_private)
	self.viewabilityManager:dispose()
	self:clearPostLoadTimeout()
	self:clearRenderSizeWarningTimeout()
	if self.itemSizeWarningTimeoutId ~= nil then
		clearTimeout(self.itemSizeWarningTimeoutId)
	end
end
function FlashList_private.render(self: FlashList_private)
	self.isEmptyList = self.state.dataProvider:getSize() == 0
	updateContentStyle(self.contentStyle, self.props.contentContainerStyle)
	local drawDistance, removeClippedSubviews, stickyHeaderIndices, horizontal, onEndReachedThreshold, estimatedListSize, initialScrollIndex, style, contentContainerStyle, renderScrollComponent, restProps
	do
		local ref = self.props
		drawDistance, removeClippedSubviews, stickyHeaderIndices, horizontal, onEndReachedThreshold, estimatedListSize, initialScrollIndex, style, contentContainerStyle, renderScrollComponent, restProps =
			ref.drawDistance,
			ref.removeClippedSubviews,
			ref.stickyHeaderIndices,
			ref.horizontal,
			ref.onEndReachedThreshold,
			ref.estimatedListSize,
			ref.initialScrollIndex,
			ref.style,
			ref.contentContainerStyle,
			ref.renderScrollComponent,
			Object.assign({}, ref, {
				drawDistance = Object.None,
				removeClippedSubviews = Object.None,
				stickyHeaderIndices = Object.None,
				horizontal = Object.None,
				onEndReachedThreshold = Object.None,
				estimatedListSize = Object.None,
				initialScrollIndex = Object.None,
				style = Object.None,
				contentContainerStyle = Object.None,
				renderScrollComponent = Object.None,
			})
	end -- RecyclerListView simply ignores if initialScrollIndex is set to 0 because it doesn't understand headers
	-- Using initialOffset to force RLV to scroll to the right place
	local ref = self:isInitialScrollIndexInFirstRow()
	local ref = if Boolean.toJSBoolean(ref) then self.distanceFromWindow else ref
	local initialOffset = Boolean.toJSBoolean(ref) and ref or nil
	local finalDrawDistance = if drawDistance == nil
		then PlatformConfig.defaultDrawDistance
		else drawDistance
	return React.createElement(
		StickyHeaderContainer,
		{
			overrideRowRenderer = self.stickyOverrideRowRenderer,
			applyWindowCorrection = self.applyWindowCorrection,
			stickyHeaderIndices = stickyHeaderIndices,
			style = if Boolean.toJSBoolean(self.props.horizontal)
				then Object.assign({}, self:getTransform())
				else Object.assign(
					{},
					{ flex = 1, overflow = "hidden" },
					self:getTransform()
				),
		},
		React.createElement(
			ProgressiveListView,
			_extends({}, restProps, {
				ref = self.recyclerRef,
				layoutProvider = self.state.layoutProvider,
				dataProvider = self.state.dataProvider,
				rowRenderer = self.emptyRowRenderer,
				canChangeSize = true,
				isHorizontal = Boolean(horizontal),
				scrollViewProps = Object.assign({}, {
					onScrollBeginDrag = self.onScrollBeginDrag,
					onLayout = self.handleSizeChange,
					refreshControl = Boolean.toJSBoolean(self.props.refreshControl)
							and self.props.refreshControl
						or self:getRefreshControl(),
					-- Min values are being used to suppress RLV's bounded exception
					style = { minHeight = 1, minWidth = 1 },
					contentContainerStyle = Object.assign({}, {
						backgroundColor = self.contentStyle.backgroundColor,
						-- Required to handle a scrollview bug. Check: https://github.com/Shopify/flash-list/pull/187
						minHeight = 1,
						minWidth = 1,
					}, getContentContainerPadding(self.contentStyle, horizontal)),
				}, self.props.overrideProps),
				forceNonDeterministicRendering = true,
				renderItemContainer = self.itemContainer,
				renderContentContainer = self.container,
				onEndReached = self.onEndReached,
				onEndReachedThresholdRelative = Boolean.toJSBoolean(
					onEndReachedThreshold
				) and onEndReachedThreshold or nil,
				extendedState = self.state.extraData,
				layoutSize = estimatedListSize,
				maxRenderAhead = 3 * finalDrawDistance,
				finalRenderAheadOffset = finalDrawDistance,
				renderAheadStep = finalDrawDistance,
				initialRenderIndex = (function()
					local ref = not Boolean.toJSBoolean(
						self:isInitialScrollIndexInFirstRow()
					) and initialScrollIndex
					return Boolean.toJSBoolean(ref) and ref or nil
				end)(),
				initialOffset = initialOffset,
				onItemLayout = self.onItemLayout,
				onScroll = self.onScroll,
				onVisibleIndicesChanged = if Boolean.toJSBoolean(
						self.viewabilityManager.shouldListenToVisibleIndices
					)
					then self.viewabilityManager.onVisibleIndicesChanged
					else nil,
				windowCorrectionConfig = self:getUpdatedWindowCorrectionConfig(),
				itemAnimator = self.itemAnimator,
				suppressBoundedSizeException = true,
				externalScrollView = renderScrollComponent :: typeof((({} :: any) :: RecyclerListViewProps).externalScrollView),
			})
		)
	)
end
function FlashList_private:getUpdatedWindowCorrectionConfig()
	-- If the initial scroll index is in the first row then we're forcing RLV to use initialOffset and thus we need to disable window correction
	-- This isn't clean but it's the only way to get RLV to scroll to the right place
	-- TODO: Remove this when RLV fixes this. Current implementation will also fail if column span is overridden in the first row.
	if Boolean.toJSBoolean(self:isInitialScrollIndexInFirstRow()) then
		self.windowCorrectionConfig.applyToInitialOffset = false
	else
		self.windowCorrectionConfig.applyToInitialOffset = true
	end
	self.windowCorrectionConfig.value.windowShift = -self.distanceFromWindow
	return self.windowCorrectionConfig
end
function FlashList_private:isInitialScrollIndexInFirstRow()
	return (
		if self.props.initialScrollIndex ~= nil
			then self.props.initialScrollIndex
			else self.state.numColumns
	)
		< self.state.numColumns --[[ ROBLOX CHECK: operator '<' works only if either both arguments are strings or both are a number ]]
end
function FlashList_private:validateListSize(event: LayoutChangeEvent)
	local height, width
	do
		local ref = event.nativeEvent.layout
		height, width = ref.height, ref.width
	end
	self:clearRenderSizeWarningTimeout()
	if
		math.floor(height) <= 1 --[[ ROBLOX CHECK: operator '<=' works only if either both arguments are strings or both are a number ]]
		or math.floor(width) <= 1 --[[ ROBLOX CHECK: operator '<=' works only if either both arguments are strings or both are a number ]]
	then
		self.renderedSizeWarningTimeoutId = setTimeout(function()
			console.warn(WarningList.unusableRenderedSize)
		end, 1000)
	end
end
function FlashList_private:getTransform()
	local transformStyle = if Boolean.toJSBoolean(self.props.horizontal)
		then self.transformStyleHorizontal
		else self.transformStyle
	local ref = if Boolean.toJSBoolean(self.props.inverted)
		then transformStyle
		else self.props.inverted
	return Boolean.toJSBoolean(ref) and ref or nil
end
function FlashList_private:getValidComponent(
	component: React_ComponentType | React_ReactElement | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil
)
	local PassedComponent = component
	local ref = React.isValidElement(PassedComponent)
	local ref = if Boolean.toJSBoolean(ref) then PassedComponent else ref
	local ref = Boolean.toJSBoolean(ref) and ref
		or (
			if Boolean.toJSBoolean(PassedComponent)
				then React.createElement(PassedComponent, nil)
				else PassedComponent
		)
	return Boolean.toJSBoolean(ref) and ref or nil
end
function FlashList_private:isStickyEnabled()
	local ref = if typeof(self.rlvRef) == "table"
		then self.rlvRef.getCurrentScrollOffset
		else nil
	local ref = if ref ~= nil then ref() else nil
	local currentOffset = Boolean.toJSBoolean(ref) and ref or 0
	return currentOffset >= self.distanceFromWindow --[[ ROBLOX CHECK: operator '>=' works only if either both arguments are strings or both are a number ]]
end
function FlashList_private:prepareForLayoutAnimationRender(): ()
	if self.props.keyExtractor == nil or self.props.keyExtractor == nil then
		console.warn(WarningList.missingKeyExtractor)
	else
		local ref = if typeof(self.rlvRef) == "table"
			then self.rlvRef.prepareForLayoutAnimationRender
			else nil
		if ref ~= nil then
			ref()
		end
	end
end
function FlashList_private:scrollToEnd(
	params: {
		animated: (boolean | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil)?,
	}?
)
	local ref = if typeof(self.rlvRef) == "table" then self.rlvRef.scrollToEnd else nil
	if ref ~= nil then
		ref(Boolean(if typeof(params) == "table" then params.animated else nil))
	end
end
function FlashList_private:scrollToIndex(
	params: {
		animated: (boolean | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil)?,
		index: number,
		viewOffset: (number | nil)?,
		viewPosition: (number | nil)?,
	}
)
	local ref = if typeof(self.rlvRef) == "table" then self.rlvRef.getLayout else nil
	local layout = if ref ~= nil then ref(params.index) else nil
	local ref = if typeof(self.rlvRef) == "table"
		then self.rlvRef.getRenderedSize
		else nil
	local listSize = if ref ~= nil then ref() else nil
	if Boolean.toJSBoolean(if Boolean.toJSBoolean(layout) then listSize else layout) then
		local itemOffset = if Boolean.toJSBoolean(self.props.horizontal)
			then layout.x
			else layout.y
		local fixedDimension = if Boolean.toJSBoolean(self.props.horizontal)
			then listSize.width
			else listSize.height
		local itemSize = if Boolean.toJSBoolean(self.props.horizontal)
			then layout.width
			else layout.height
		local scrollOffset = math.max(
			0,
			itemOffset
				- (if params.viewPosition ~= nil then params.viewPosition else 0)
					* (fixedDimension - itemSize)
		) - (if params.viewOffset ~= nil then params.viewOffset else 0)
		local ref = if typeof(self.rlvRef) == "table"
			then self.rlvRef.scrollToOffset
			else nil
		if ref ~= nil then
			ref(scrollOffset, scrollOffset, Boolean(params.animated), true)
		end
	end
end
function FlashList_private:scrollToItem(
	params: {
		animated: (boolean | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil)?,
		item: any,
		viewPosition: (number | nil)?,
		viewOffset: (number | nil)?,
	}
)
	local ref = if typeof(self.props.data) == "table"
		then self.props.data.indexOf
		else nil
	local ref = if ref ~= nil then ref(params.item) else nil
	local index = if ref ~= nil then ref else -1
	if
		index
		>= 0 --[[ ROBLOX CHECK: operator '>=' works only if either both arguments are strings or both are a number ]]
	then
		self:scrollToIndex(Object.assign({}, params, { index = index }))
	end
end
function FlashList_private:scrollToOffset(
	params: {
		animated: (boolean | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] | nil)?,
		offset: number,
	}
)
	local x = if Boolean.toJSBoolean(self.props.horizontal) then params.offset else 0
	local y = if Boolean.toJSBoolean(self.props.horizontal) then 0 else params.offset
	local ref = if typeof(self.rlvRef) == "table" then self.rlvRef.scrollToOffset else nil
	if ref ~= nil then
		ref(x, y, Boolean(params.animated))
	end
end
function FlashList_private:getScrollableNode(): number | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]]
	local ref = if typeof(self.rlvRef) == "table"
		then self.rlvRef.getScrollableNode
		else nil
	local ref = if ref ~= nil then ref() else nil
	return Boolean.toJSBoolean(ref) and ref or nil
end
function FlashList_private:recyclerlistview_unsafe()
	return self.rlvRef
end
function FlashList_private:firstItemOffset()
	return self.distanceFromWindow
end
function FlashList_private:clearLayoutCacheOnUpdate()
	self.state.layoutProvider:markExpired()
end
exports.default = FlashList
return exports
