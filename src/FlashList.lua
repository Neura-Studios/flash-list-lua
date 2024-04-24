-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/FlashList.tsx

--!nolint LocalShadow

local FlashListProps = require("./FlashListProps")
local RenderTargetOptions = FlashListProps.RenderTargetOptions

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Array = LuauPolyfill.Array
local clearTimeout = LuauPolyfill.clearTimeout
local console = LuauPolyfill.console
local Object = LuauPolyfill.Object
local setTimeout = LuauPolyfill.setTimeout
type Array<T> = LuauPolyfill.Array<T>

local React = require("@pkg/@jsdotlua/react")

local recyclerListViewModule = require("./recyclerlistview")
local RecyclerListView = recyclerListViewModule.RecyclerListView
local StickyContainer = recyclerListViewModule.StickyContainer
local DataProvider = recyclerListViewModule.DataProvider
type StickyContainerProps = recyclerListViewModule.StickyContainerProps

local ViewabilityManager = require("./viewability/ViewabilityManager")
local Warnings = require("./errors/Warnings")
local CustomError = require("./errors/CustomError")
local ExceptionList = require("./errors/ExceptionList")

local PlatformHelper = require("./native/config/PlatformHelper")
local PlatformConfig = PlatformHelper.PlatformConfig
local getFooterContainer = PlatformHelper.getFooterContainer
local getCellContainerPlatformStyles = PlatformHelper.getCellContainerPlatformStyles

local AutoLayoutView = require("./native/auto-layout/AutoLayoutView")
local CellContainer = require("./native/cell-container/CellContainer")

local ContentContainerUtils = require("./utils/ContentContainerUtils")
local getContentContainerPadding = ContentContainerUtils.getContentContainerPadding
local hasUnsupportedKeysInContentContainerStyle =
	ContentContainerUtils.hasUnsupportedKeysInContentContainerStyle
local updateContentStyle = ContentContainerUtils.updateContentStyle
type ContentStyleExplicit = ContentContainerUtils.ContentStyleExplicit

local RobloxUtils = require("./utils/RobloxUtils")
local getFillCrossSpaceStyle = RobloxUtils.getFillCrossSpaceStyle

local GridLayoutProviderWithProps = require("./GridLayoutProviderWithProps")
type GridLayoutProviderWithProps<T> =
	GridLayoutProviderWithProps.GridLayoutProviderWithProps<T>

local PureComponentWrapper = require("./PureComponentWrapper")

local e = React.createElement

type LayoutChangeEvent = any

-- TODO: Import from React Native.
type NativeSyntheticEvent<T> = any
type NativeScrollEvent = any

type FlashListComponent = FlashListProps.FlashListComponent
type FlashListProps<TItem> = FlashListProps.FlashListProps<TItem>
type FlashListState<TItem> = FlashListProps.FlashListState<TItem>
type RenderTarget = FlashListProps.RenderTarget

type StickyProps = StickyContainerProps & {
	children: any?,
}
local StickyHeaderContainer = StickyContainer :: React.FC<StickyProps>

local function validateProps(props: FlashListProps<unknown>)
	if props.onRefresh and type(props.refreshing) ~= "boolean" then
		error(CustomError.new(ExceptionList.refreshBooleanMissing))
	end

	if
		props.stickyHeaderIndices
		and #props.stickyHeaderIndices > 0
		and props.horizontal
	then
		error(CustomError.new(ExceptionList.stickyWhileHorizontalNotSupported))
	end

	if (props.numColumns :: number) > 1 and props.horizontal then
		error(CustomError.new(ExceptionList.columnsWhileHorizontalNotSupported))
	end

	-- Note: Skipping style check because it's not relevant in Roblox.

	if hasUnsupportedKeysInContentContainerStyle(props.contentContainerStyle) then
		console.warn(Warnings.styleContentContainerUnsupported)
	end

	return true
end

local FlashList: FlashListComponent = React.PureComponent:extend("FlashList")

FlashList.defaultProps = {
	data = {},
	numColumns = 1,
}

function FlashList:init(props)
	local self = self :: FlashListComponent

	-- self.rlvRef: RecyclerListView<RecyclerListViewProps, any>? = nil
	-- self.stickyContentContainerRef: PureComponentWrapper? = nil
	self.listFixedDimensionSize = 0
	-- self.transformStyle = PlatformConfig.invertedTransformStyle
	-- self.transformStyleHorizontal = PlatformConfig.invertedTransformStyleHorizontal

	self.distanceFromWindow = 0
	self.contentStyle = {
		paddingBottom = 0,
		paddingLeft = 0,
		paddingRight = 0,
		paddingTop = 0,
	}

	validateProps(props)

	self.loadStartTime = os.clock()
	self.isListLoaded = false
	self.windowCorrectionConfig = {
		applyToInitialOffset = true,
		applyToItemScroll = true,
		value = {
			endCorrection = 0,
			startCorrection = 0,
			windowShift = 0,
		},
	}

	-- self.postLoadTimeoutId: Timeout? = nil
	-- self.itemSizeWarningTimeoutId: Timeout? = nil
	-- self.renderedSizeWarningTimeoutId: Timeout? = nil

	if props.estimatedListSize ~= nil then
		if props.horizontal then
			self.listFixedDimensionSize = props.estimatedListSize.height
		else
			self.listFixedDimensionSize = props.estimatedListSize.width
		end
	end

	self.distanceFromWindow = props.estimatedFirstItemOffset
	if self.distanceFromWindow == nil then
		self.distanceFromWindow = (props.ListHeaderComponent and 1) or 0
	end

	self.isEmptyList = false
	self.state = FlashList.getInitialMutableState(self)
	self.viewabilityManager = ViewabilityManager.new(self)
	-- self.itemAnimator = getItemAnimator()

	self.onEndReached = function()
		if self.props.onEndReached ~= nil then
			self.props.onEndReached()
		end
	end

	self.getRefreshControl = function()
		if self.props.onRefresh ~= nil then
			-- return (
			-- 	<RefreshControl
			-- 		refreshing={self.props.refreshing}
			-- 		progressViewOffset={self.props.progressViewOffset}
			-- 		onRefresh={self.props.onRefresh}
			-- 	/>
			-- )

			return nil
		end

		return nil
	end

	self.onScrollBeginDrag = function(event: NativeSyntheticEvent<NativeScrollEvent>)
		self.recordInteraction()

		if self.props.onScrollBeginDrag ~= nil then
			self.props.onScrollBeginDrag(event)
		end
	end

	self.onScroll = function(event: NativeSyntheticEvent<NativeScrollEvent>)
		self.recordInteraction()
		self.viewabilityManager:updateViewableItems()

		if self.props.onScroll ~= nil then
			self.props.onScroll(event)
		end
	end

	self.getUpdatedWindowCorrectionConfig = function()
		if self.isInitialScrollIndexInFirstRow() then
			self.windowCorrectionConfig.applyToInitialOffset = false
		else
			self.windowCorrectionConfig.applyToInitialOffset = true
		end

		self.windowCorrectionConfig.value.windowShift = -self.distanceFromWindow

		return self.windowCorrectionConfig
	end

	self.isInitialScrollIndexInFirstRow = function()
		return (
			if self.props.initialScrollIndex ~= nil
				then self.props.initialScrollIndex
				else self.state.numColumns
		) < self.state.numColumns
	end

	self.validateListSize = function(event: LayoutChangeEvent)
		local height = event.nativeEvent.layout.height
		local width = event.nativeEvent.layout.width

		self.clearRenderSizeWarningTimeout()

		if math.floor(height) < 1 or math.floor(width) < 1 then
			self.renderedSizeWarningTimeoutId = setTimeout(function()
				console.warn(Warnings.unusableRenderedSize)
			end, 1000)
		end
	end

	self.handleSizeChange = function(event: LayoutChangeEvent)
		self.validateListSize(event)

		local oldSize: number = self.listFixedDimensionSize
		local newSize = if self.props.horizontal
			then event.nativeEvent.layout.height
			else event.nativeEvent.layout.width

		-- >0 check is to avoid rerender on mount where it would be redundant
		self.listFixedDimensionSize = newSize

		if oldSize > 0 and oldSize ~= newSize then
			local ref = if self.rlvRef then self.rlvRef.forceRerender else nil
			if ref ~= nil then
				ref(self.rlvRef)
			end
		end

		if self.props.onLayout ~= nil then
			self.props.onLayout(event)
		end
	end

	self.updateDistanceFromWindow = function(event: LayoutChangeEvent)
		local newDistanceFromWindow = if self.props.horizontal
			then event.nativeEvent.layout.x
			else event.nativeEvent.layout.y

		if self.distanceFromWindow ~= newDistanceFromWindow then
			self.distanceFromWindow = newDistanceFromWindow
			self.windowCorrectionConfig.value.windowShift = -self.distanceFromWindow
			self.viewabilityManager:updateViewableItems()
		end
	end

	self.getTransform = function()
		-- local transformStyle = if self.props.horizontal
		-- 	then self.transformStyleHorizontal
		-- 	else self.transformStyle

		-- return self.props.inverted and transformStyle or nil
		return nil
	end

	self.applyWindowCorrection = function(_, _, correctionObject: { windowShift: number })
		correctionObject.windowShift = -self.distanceFromWindow

		if self.stickyContainerRef then
			self.stickyContentContainerRef:setEnabled(self.isStickyEnabled)
		end
	end

	self.rowRendererSticky = function(index: number)
		return self.rowRendererWithIndex(
			index,
			FlashListProps.RenderTargetOptions.StickyHeader
		)
	end

	self.rowRendererWithIndex = function(index: number, target: RenderTarget)
		if self.props.renderItem ~= nil then
			return self.props.renderItem({
				extraData = if type(self.props.extraData) == "table"
					then self.props.extraData.value
					else nil,
				index = index,
				item = (self.props.data :: any)[index],
				target = target,
			})
		end
	end

	-- This will prevent render item calls unless data changes.
	-- Output of this method is received as children object so returning null here is no issue as long as we handle it inside our child container.
	-- @module getCellContainerChild acts as the new rowRenderer and is called directly from our child container.
	self.emptyRowRenderer = function()
		return nil
	end

	self.recyclerRef = function(ref: any)
		self.rlvRef = ref
	end

	self.stickyContentRef = function(ref: any)
		self.stickyContentContainerRef = ref
	end

	self.isStickyEnabled = function()
		local currentOffset = if self.rlvRef
			then self.rlvRef:getCurrentScrollOffset()
			else 0

		return currentOffset >= self.distanceFromWindow
	end

	self.onItemLayout = function(index: number)
		self.state.layoutProvider:reportItemLayout(index)
		self.raiseOnLoadEventIfNeeded()
	end

	self.raiseOnLoadEventIfNeeded = function()
		if not self.isListLoaded then
			self.isListLoaded = true

			if self.props.onLoad ~= nil then
				self.props.onLoad({
					elapsedTimeInMs = os.clock() - self.loadStartTime,
				})
			end

			self.runAfterOnLoad()
		end
	end

	self.runAfterOnLoad = function()
		if self.props.estimatedItemSize == nil then
			self.itemSizeWarningTimeoutId = setTimeout(function()
				local averageItemSize =
					math.floor(self.state.layoutProvider:averageItemSize())

				console.warn(
					string.gsub(
						Warnings.estimatedItemSizeMissingWarning,
						"@size",
						tostring(averageItemSize)
					)
				)
			end, 1000)
		end

		self.postLoadTimeoutId = setTimeout(function()
			-- This force update is required to remove dummy element rendered to measure horizontal list height when  the list doesn't update on its own.
			-- In most cases this timeout will never be triggered because list usually updates atleast once and this timeout is cleared on update.
			if self.props.horizontal then
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
		if self.renderSizeWarningTimeoutId ~= nil then
			clearTimeout(self.renderSizeWarningTimeoutId)
			self.renderSizeWarningTimeoutId = nil
		end
	end

	-- Disables recycling for the next frame so that layout animations run well.
	-- Warning: Avoid this when making large changes to the data as the list might draw too much to run animations. Single item insertions/deletions
	-- should be good. With recycling paused the list cannot do much optimization.
	-- The next render will run as normal and reuse items.
	self.prepareForLayoutAnimationRender = function()
		if self.props.keyExtractor == nil then
			console.warn(Warnings.missingKeyExtractor)
		else
			if self.rlvRef then
				self.rlvRef:prepareForLayoutAnimationRender()
			end
		end
	end

	self.scrollToEnd = function(params: { animated: boolean? }?)
		if self.rlvRef then
			local animated = false
			if params and params.animated ~= nil then
				animated = params.animated
			end

			self.rlvRef:scrollToEnd(animated)
		end
	end

	self.scrollToIndex = function(params: {
		animated: boolean?,
		index: number,
		viewOffset: number?,
		viewPosition: number?,
	})
		local layout = nil
		local listSize = nil

		if self.rlvRef then
			layout = self.rlvRef:getLayout(params.index)
			listSize = self.rlvRef:getRenderedSize()
		end

		if layout ~= nil and listSize ~= nil then
			local horizontal = self.props.horizontal
			local itemOffset = horizontal and layout.x or layout.y
			local fixedDimension = horizontal and listSize.width or listSize.height
			local itemSize = horizontal and layout.width or layout.height

			local viewPosition = params.viewPosition and params.viewPosition or 0
			local scrollOffset =
				math.max(0, itemOffset - viewPosition * (fixedDimension - itemSize))

			if self.rlvRef ~= nil then
				self.rlvRef:scrollToOffset(
					scrollOffset,
					scrollOffset,
					params.animated,
					true
				)
			end
		end
	end

	self.scrollToItem = function(params: {
		animated: boolean?,
		item: any,
		viewOffset: number?,
		viewPosition: number?,
	})
		local index = Array.indexOf(self.props.data or {}, params.item)
		if index and index >= 1 then
			self.scrollToIndex(Object.assign({}, params, { index = index }))
		end
	end

	self.scrollToOffset = function(params: {
		animated: boolean?,
		offset: number,
	})
		local x = self.props.horizontal and params.offset or 0
		local y = self.props.horizontal and 0 or params.offset

		if self.rlvRef ~= nil then
			self.rlvRef:scrollToOffset(x, y, params.animated)
		end
	end

	self.getScrollableNode = function()
		if self.rlvRef ~= nil then
			return self.rlvRef:getScrollableNode()
		end

		return nil
	end

	self.clearLayoutCacheOnUpdate = function()
		self.state.layoutProvider:markExpired()
	end

	self.recordInteraction = function()
		self.viewabilityManager:recordInteraction()
	end

	self.container = function(props: any, children: Array<React.Node>)
		self.clearPostLoadTimeout()

		return e(React.Fragment, {}, {
			Header = e(PureComponentWrapper, {
				enabled = (
						self.isListLoaded
						or #children > 0
						or self.isEmptyList
					) :: boolean,
				contentStyle = self.props.contentContainerStyle,
				horizontal = self.props.horizontal,
				header = self.props.ListHeaderComponent,
				extraData = self.state.extraData,
				headerStyle = self.props.ListHeaderComponentStyle,
				inverted = self.props.inverted,
				renderer = self.header,
			}),

			Content = e(
				AutoLayoutView,
				Object.assign({}, props, {
					onBlankAreaEvent = self.props.onBlankArea,
					onLayout = self.updateDistanceFromWindow,
					disableAutoLayout = self.props.disableAutoLayout,
				}),
				children
			),

			EmptyList = if self.isEmptyList
				then self:getValidComponent(self.props.ListEmptyComponent)
				else nil,

			Footer = e(PureComponentWrapper, {
				enabled = (
						self.isListLoaded
						or #children > 0
						or self.isEmptyList
					) :: boolean,
				contentStyle = self.props.contentContainerStyle,
				horizontal = self.props.horizontal,
				header = self.props.ListFooterComponent,
				extraData = self.state.extraData,
				headerStyle = self.props.ListFooterComponentStyle,
				inverted = self.props.inverted,
				renderer = self.footer,
			}),

			HeightMeasurement = self.getComponentForHeightMeasurement(),
		})
	end

	self.itemContainer = function(props: any, parentProps: any)
		local CellRendererComponent = self.props.CellRendererComponent or CellContainer
		props.width = nil

		return e(
			CellRendererComponent,
			Object.assign({}, props, {
				-- style = Object.assign({}, props.style, {
				-- 	-- flexDirection = self.props.horizontal and "row" or "column",
				-- 	-- alignItems = "stretch",
				-- 	-- ...self.getTransform(),
				-- 	-- ...
				-- }),
				-- index = parentProps.index,
			}, getCellContainerPlatformStyles(self.props.inverted, parentProps)),
			{
				CellContainerChild = e(PureComponentWrapper, {
					extendedState = parentProps.extendedState,
					internalSnapshot = parentProps.internalSnapshot,
					data = parentProps.data,
					arg = parentProps.index,
					renderer = self.getCellContainerChild,
				}),
			}
		)
	end

	self.separator = function(index: number)
		-- Make sure we have data and don't read out of bounds
		if self.props.data == nil or index >= #self.props.data then
			return nil :: React.Node
		end

		local data = self.props.data :: Array<any>
		local leadingItem = data[index]
		local trailingItem = data[index + 1]

		local props = {
			leadingItem = leadingItem,
			trailingItem = trailingItem,
		}

		local Separator = self.props.ItemSeparatorComponent
		return Separator and e(Separator, props)
	end

	self.header = function()
		return e(React.Fragment, {}, {
			e(View, {
				style = {
					paddingTop = self.contentStyle.paddingTop,
					paddingLeft = self.contentStyle.paddingLeft,
				},
			}),

			e(View, {
				style = Object.assign(
					{},
					self.props.ListHeaderComponentStyle,
					self.getTransform()
				),
			}, {
				self:getValidComponent(self.props.ListHeaderComponent),
			}),
		})
	end

	self.footer = function()
		-- The web version of CellContainer uses a div directly which doesn't compose styles the way a View does.
		-- We will skip using CellContainer on web to avoid this issue. `getFooterContainer` on web will
		-- return a View.
		local FooterContainer = getFooterContainer() or CellContainer

		return e(React.Fragment, {}, {
			e(FooterContainer, {
				index = -1,
				style = Object.assign(
					{},
					self.props.ListFooterComponentStyle,
					self.getTransform()
				),
			}, {
				self:getValidComponent(self.props.ListFooterComponent),
			}),

			e(View, {
				style = {
					paddingBottom = self.contentStyle.paddingBottom,
					paddingRight = self.contentStyle.paddingRight,
				},
			}),
		})
	end

	self.getComponentForHeightMeasurement = function()
		return if self.props.horizontal
				and not self.props.disableHorizontalListHeightMeasurement
				and not self.isListLoaded
				and self.state.dataProvider:getSize() > 0
			then e(
				"Frame",
				Object.assign({
					BackgroundTransparency = 1,
				}, getFillCrossSpaceStyle(self.props.horizontal)),
				{
					HeightMeasurement = self.rowRendererWithIndex(
						math.min(self.state.dataProvider:getSize(), 1),
						RenderTargetOptions.Measurement
					),
				}
			)
			else nil
	end

	self.getCellContainerChild = function(index: number)
		return e(React.Fragment, {}, {
			if self.props.inverted then self.separator(index) else nil,
			e(
				"Frame",
				Object.assign({
					BackgroundTransparency = 1,
				}, getFillCrossSpaceStyle(self.props.horizontal)),
				{
					ListItem = self.rowRendererWithIndex(index, RenderTargetOptions.Cell),
				}
			),
			if self.props.inverted then nil else self.separator(index),
		})
	end

	self.stickyOverrideRowRenderer = function(_, __, index: number, ___)
		return e(PureComponentWrapper, {
			ref = self.stickyContentRef,
			enabled = self.isStickyEnabled,
			arg = index,
			renderer = self.rowRendererSticky,
		})
	end
end

function FlashList:componentDidMount()
	local self = self :: FlashListComponent
	if self.props.data ~= nil and #self.props.data > 0 then
		self.raiseOnLoadEventIfNeeded()
	end
end

function FlashList:componentWillUnmount()
	local self = self :: FlashListComponent
	self.viewabilityManager:dispose()
	self.clearPostLoadTimeout()
	self.clearRenderSizeWarningTimeout()

	if self.itemSizeWarningTimeoutId ~= nil then
		clearTimeout(self.itemSizeWarningTimeoutId)
	end
end

function FlashList:render()
	local self = self :: FlashListComponent

	self.isEmptyList = self.state.dataProvider:getSize() == 0
	updateContentStyle(self.contentStyle, self.props.contentContainerStyle)

	local drawDistance = self.props.drawDistance
	local removeClippedSubviews = self.props.removeClippedSubviews
	local stickyHeaderIndices = self.props.stickyHeaderIndices
	local horizontal = self.props.horizontal
	local onEndReachedThreshold = self.props.onEndReachedThreshold
	local estimatedListSize = self.props.estimatedListSize
	local initialScrollIndex = self.props.initialScrollIndex
	local style = self.props.style
	local contentContainerStyle = self.props.contentContainerStyle
	local renderScrollComponent = self.props.renderScrollComponent

	-- RecyclerListView simply ignores if initialScrollIndex is set to 0 because it doesn't understand headers
	-- Using initialOffset to force RLV to scroll to the right place
	local initialOffset = (
		self.isInitialScrollIndexInFirstRow() and self.distanceFromWindow
	) or nil
	local finalDrawDistance = if drawDistance == nil
		then PlatformConfig.defaultDrawDistance
		else drawDistance

	local listViewProps = Object.assign({}, self.props, {
		ref = self.recyclerRef,
		layoutProvider = self.state.layoutProvider,
		dataProvider = self.state.dataProvider,
		rowRenderer = self.emptyRowRenderer,
		canChangeSize = true,
		isHorizontal = horizontal == true,
		scrollViewProps = Object.assign({
			onScrollBeginDrag = self.onScrollBeginDrag,
			onLayout = self.handleSizeChange,
			refreshControl = self.props.refreshControl or self.getRefreshControl(),

			-- Min values are being used to suppress RLV's bounded exception
			-- style = { minHeight = 1, minWidth = 1 },
			contentContainerStyle = Object.assign({
				backgroundColor = self.contentStyle.backgroundColor,
			}, getContentContainerPadding(self.contentStyle, horizontal)),
		}, self.props.overrideProps),
		forceNonDeterministicRendering = true,
		renderItemContainer = self.itemContainer,
		renderContentContainer = self.container,
		onEndReached = self.onEndReached,
		onEndReachedThresholdRelative = onEndReachedThreshold,
		extendedState = self.state.extraData,
		layoutSize = estimatedListSize,
		maxRenderAhead = 3 * finalDrawDistance,
		finalRenderAheadOffset = finalDrawDistance,
		renderAheadStep = finalDrawDistance,
		initialRenderIndex = if not self.isInitialScrollIndexInFirstRow()
			then initialScrollIndex
			else nil,
		initialOffset = initialOffset,
		onItemLayout = self.onItemLayout,
		onScroll = self.onScroll,
		onVisibleIndicesChanged = if self.viewabilityManager.shouldListenToVisibleIndices
			then function()
				self.viewabilityManager:onVisibleIndicesChanged()
			end
			else nil,
		windowCorrectionConfig = self.getUpdatedWindowCorrectionConfig(),
		itemAnimator = self.itemAnimator,
		suppressBoundedSizeException = true,
		externalScrollView = renderScrollComponent,
	})

	return e(StickyHeaderContainer, {
		overrideRowRenderer = self.stickyOverrideRowRenderer,
		applyWindowCorrection = self.applyWindowCorrection,
		stickyHeaderIndices = stickyHeaderIndices,
		-- style = if horizontal
		-- 	then { self.getTransform() }
		-- 	else { flex = 1, overflow = "hidden", self.getTransform() }
		children = nil :: any,
	}, e(RecyclerListView, listViewProps))
end

function FlashList:getValidComponent(
	component: React.AbstractComponent<unknown, unknown> | React.ReactElement | nil
): React.ReactElement | nil
	return (
		(React.isValidElement(component :: any) and component)
		or (component and e(component :: any))
		or nil
	)
end

function FlashList.getDerivedStateFromProps(
	nextProps: FlashListProps<unknown>,
	prevState: FlashListState<unknown>
): FlashListState<unknown>
	local newState = Object.assign({}, prevState)

	if prevState.numColumns ~= nextProps.numColumns then
		newState.numColumns = nextProps.numColumns or 1
		newState.layoutProvider =
			FlashList.getLayoutProvider(newState.numColumns, nextProps)
	elseif prevState.layoutProvider:updateProps(nextProps).hasExpired then
		newState.layoutProvider =
			FlashList.getLayoutProvider(newState.numColumns, nextProps)
	end

	-- RLV retries to reposition the first visible item on layout provider change.
	-- It's not required in our case so we're disabling it.
	newState.layoutProvider.shouldRefreshWithAnchoring =
		not if prevState.layoutProvider then prevState.layoutProvider.hasExpired else nil

	if nextProps.data ~= prevState.data then
		newState.data = nextProps.data
		newState.dataProvider = prevState.dataProvider:cloneWithRows(nextProps.data)

		if nextProps.renderItem ~= prevState.renderItem then
			newState.extraData = Object.assign({}, prevState.extraData)
		end
	end

	if
		nextProps.extraData
		~= (if prevState.extraData then prevState.extraData.value else nil)
	then
		newState.extraData = { value = nextProps.extraData }
	end

	newState.renderItem = nextProps.renderItem

	return newState
end

function FlashList.getInitialMutableState(
	flashList: FlashListComponent
): FlashListState<unknown>
	local getStableId: ((index: number) -> string)?

	if flashList.props.keyExtractor ~= nil then
		getStableId = function(index)
			return tostring(
				flashList.props.keyExtractor((flashList.props.data :: any)[index], index)
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

function FlashList.getLayoutProvider(
	numColumns: number,
	flashListProps: FlashListProps<unknown>
): GridLayoutProviderWithProps<unknown>
	return GridLayoutProviderWithProps.new(numColumns, function(index, props)
		local type = if props.getItemType ~= nil
			then props.getItemType(props.data[index], index, props.extraData)
			else nil

		return type or 0
	end, function(index, props, mutableLayout)
		if props.overrideItemLayout ~= nil then
			props.overrideItemLayout(
				mutableLayout,
				props.data[index],
				index,
				numColumns,
				props.extraData
			)
		end

		local ref = if mutableLayout then mutableLayout.span else nil
		return if ref ~= nil then ref else 1
	end, function(index, props, mutableLayout)
		if props.overrideItemLayout ~= nil then
			props.overrideItemLayout(
				mutableLayout,
				props.data[index],
				index,
				numColumns,
				props.extraData
			)
		end

		return if mutableLayout then mutableLayout.span else nil
	end, flashListProps)
end

return FlashList
