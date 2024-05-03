-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/RecyclerListView.tsx

local RunService = game:GetService("RunService")

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Object = LuauPolyfill.Object
local console = LuauPolyfill.console
local setTimeout = LuauPolyfill.setTimeout
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object
type Error = LuauPolyfill.Error

type Record<K, T> = { [K]: T }

--[[**
 * DONE: Reduce layout processing on data insert
 * DONE: Add notify data set changed and notify data insert option in data source
 * DONE: Add on end reached callback
 * DONE: Make another class for render stack generator
 * DONE: Simplify rendering a loading footer
 * DONE: Anchor first visible index on any insert/delete data wise
 * DONE: Build Scroll to index
 * DONE: Give viewability callbacks
 * DONE: Add full render logic in cases like change of dimensions
 * DONE: Fix all proptypes
 * DONE: Add Initial render Index support
 * DONE: Add animated scroll to web scrollviewer
 * DONE: Animate list view transition, including add/remove
 * DONE: Implement sticky headers and footers
 * TODO: Destroy less frequently used items in recycle pool, this will help in case of too many types.
 * TODO: Make viewability callbacks configurable
 * TODO: Observe size changes on web to optimize for reflowability
 * TODO: Solve //TSI
 ]]

local React = require("@pkg/@jsdotlua/react")
local ContextProvider = require("./dependencies/ContextProvider")
type ContextProvider = ContextProvider.ContextProvider
local DataProvider = require("./dependencies/DataProvider")
type BaseDataProvider = DataProvider.BaseDataProvider
local layoutProviderModule = require("./dependencies/LayoutProvider")
type Dimension = layoutProviderModule.Dimension
type BaseLayoutProvider = layoutProviderModule.BaseLayoutProvider
local CustomError = require("./exceptions/CustomError")
local RecyclerListViewExceptions = require("./exceptions/RecyclerListViewExceptions")
local layoutManagerModule = require("./layoutmanager/LayoutManager")
type Point = layoutManagerModule.Point
type Layout = layoutManagerModule.Layout
type LayoutManager = layoutManagerModule.LayoutManager
local Constants = require("./constants/Constants")
local Messages = require("./constants/Messages")
local BaseScrollComponent = require("./scrollcomponent/BaseScrollComponent")
type BaseScrollComponent = BaseScrollComponent.BaseScrollComponent
local baseScrollViewModule = require("./scrollcomponent/BaseScrollView")
type BaseScrollView = baseScrollViewModule.BaseScrollView
type ScrollEvent = baseScrollViewModule.ScrollEvent
type ScrollViewDefaultProps = baseScrollViewModule.ScrollViewDefaultProps
local viewabilityTrackerModule = require("./ViewabilityTracker")
type TOnItemStatusChanged = viewabilityTrackerModule.TOnItemStatusChanged
type WindowCorrection = viewabilityTrackerModule.WindowCorrection
local VirtualRenderer = require("./VirtualRenderer")
type VirtualRenderer = VirtualRenderer.VirtualRenderer
type RenderStack = VirtualRenderer.RenderStack
type RenderStackItem = VirtualRenderer.RenderStackItem
type RenderStackParams = VirtualRenderer.RenderStackParams
local BaseItemAnimator = require("./ItemAnimator")
type ItemAnimator = BaseItemAnimator.ItemAnimator
type BaseItemAnimator = BaseItemAnimator.BaseItemAnimator
local DebugHandlers = require("./devutils/debughandlers/DebugHandlers")
type DebugHandlers = DebugHandlers.DebugHandlers

local ScrollComponent = require("../platform/roblox/scrollcomponent/ScrollComponent")
local ViewRenderer = require("../platform/roblox/viewrenderer/ViewRenderer")

--[[**
 * This is the main component, please refer to samples to understand how to use.
 * For advanced usage check out prop descriptions below.
 * You also get common methods such as: scrollToIndex, scrollToItem, scrollToTop, scrollToEnd, scrollToOffset, getCurrentScrollOffset,
 * findApproxFirstVisibleIndex.
 * You'll need a ref to Recycler in order to call these
 * Needs to have bounded size in all cases other than window scrolling (web).
 *
 * NOTE: React Native implementation uses ScrollView internally which means you get all ScrollView features as well such as Pull To Refresh, paging enabled
 *       You can easily create a recycling image flip view using one paging enabled flag. Read about ScrollView features in official
 *       react native documentation.
 * NOTE: If you see blank space look at the renderAheadOffset prop and make sure your data provider has a good enough rowHasChanged method.
 *       Blanks are totally avoidable with this listview.
 * NOTE: Also works on web (experimental)
 * NOTE: For reflowability set canChangeSize to true (experimental)
 ]]
export type OnRecreateParams = { lastOffset: number? }
export type RecyclerListViewProps = {
	layoutProvider: BaseLayoutProvider,
	dataProvider: BaseDataProvider,
	rowRenderer: (
		type_: any,
		data: any,
		index: number,
		extendedState: (Object | Array<unknown>)?
	) -> React.Node,
	contextProvider: ContextProvider?,
	renderAheadOffset: number?,
	isHorizontal: boolean?,
	onScroll: ((rawEvent: ScrollEvent, offsetX: number, offsetY: number) -> ())?,
	onRecreate: ((params: OnRecreateParams) -> ())?,
	onEndReached: (() -> ())?,
	onEndReachedThreshold: number?,
	onEndReachedThresholdRelative: number?,
	onVisibleIndexesChanged: TOnItemStatusChanged?,
	onVisibleIndicesChanged: TOnItemStatusChanged?,
	renderFooter: (() -> React.Node)?,
	externalScrollView: {
		__unhandledIdentifier__: nil, --[[ ROBLOX TODO: Unhandled node for type: TSConstructSignatureDeclaration ]] --[[ new (props: ScrollViewDefaultProps): BaseScrollView; ]]
	}?,
	layoutSize: Dimension?,
	initialOffset: number?,
	initialRenderIndex: number?,
	scrollThrottle: number?,
	canChangeSize: boolean?,
	disableRecycling: boolean?,
	forceNonDeterministicRendering: boolean?,
	extendedState: (Object | Array<unknown>)?,
	itemAnimator: ItemAnimator?,
	optimizeForInsertDeleteAnimations: boolean?,
	style: (Object | Array<unknown> | number)?,
	debugHandlers: DebugHandlers?,
	renderContentContainer: ((
		props: (Object | Array<unknown>)?,
		children: React.Node?
	) -> React.Node)?,
	renderItemContainer: ((
		props: Object | Array<unknown>,
		parentProps: Object | Array<unknown>,
		children: React.Node?
	) -> React.Node)?,
	--For all props that need to be proxied to inner/external scrollview. Put them in an object and they'll be spread
	--and passed down. For better typescript support.
	scrollViewProps: (Object | Array<unknown>)?,
	applyWindowCorrection: ((
		offsetX: number,
		offsetY: number,
		windowCorrection: WindowCorrection
	) -> ())?,
	onItemLayout: ((index: number) -> ())?,
	windowCorrectionConfig: {
		value: WindowCorrection?,
		applyToInitialOffset: boolean?,
		applyToItemScroll: boolean?,
	}?,
	--This can lead to inconsistent behavior. Use with caution.
	--If set to true, recyclerlistview will not measure itself if scrollview mounts with zero height or width.
	--If there are no following events with right dimensions nothing will be rendered.
	suppressBoundedSizeException: boolean?,

	-- ROBLOX deviation: Merge `ProgressiveListView` into `RecyclerListView` to avoid inheritance complexities with React-lua.
	maxRenderAhead: number?,
	renderAheadStep: number?,
	--[[
		A smaller final value can help in building up recycler pool in advance. This is only used if there is a valid updated cycle.
		e.g, if maxRenderAhead is 0 then there will be no cycle and final value will be unused
	]]
	finalRenderAheadOffset: number?,
}

export type RecyclerListViewState = {
	renderStack: RenderStack,
	internalSnapshot: Record<string, Object | Array<unknown>>,
}

export type WindowCorrectionConfig = {
	value: WindowCorrection,
	applyToInitialOffset: boolean,
	applyToItemScroll: boolean,
}

export type RecyclerListView = {
	-- NOTE: We have to inline the React component types here to make Luau happy. I am sad.
	props: RecyclerListViewProps,
	state: RecyclerListViewState,

	setState: (
		self: RecyclerListView,
		partialState: RecyclerListViewState
			| ((RecyclerListViewState, RecyclerListViewProps) -> RecyclerListViewState?),
		callback: (() -> ())?
	) -> (),

	forceUpdate: (self: RecyclerListView, callback: (() -> ())?) -> (),

	init: (
		self: RecyclerListView,
		props: RecyclerListViewProps,
		context: any?
	) -> (),
	render: (self: RecyclerListView) -> React.Node,
	componentWillMount: (self: RecyclerListView) -> (),
	UNSAFE_componentWillMount: (self: RecyclerListView) -> (),
	componentDidMount: (self: RecyclerListView) -> (),
	componentWillReceiveProps: (
		self: RecyclerListView,
		nextProps: RecyclerListViewProps,
		nextContext: any
	) -> (),
	UNSAFE_componentWillReceiveProps: (
		self: RecyclerListView,
		nextProps: RecyclerListViewProps,
		nextContext: any
	) -> (),
	shouldComponentUpdate: (
		self: RecyclerListView,
		nextProps: RecyclerListViewProps,
		nextState: RecyclerListViewProps,
		nextContext: any
	) -> boolean,
	componentWillUpdate: (
		self: RecyclerListView,
		nextProps: RecyclerListViewProps,
		nextState: RecyclerListViewProps,
		nextContext: any
	) -> (),
	UNSAFE_componentWillUpdate: (
		self: RecyclerListView,
		nextProps: RecyclerListViewProps,
		nextState: RecyclerListViewProps,
		nextContext: any
	) -> (),
	componentDidUpdate: (
		self: RecyclerListView,
		prevProps: RecyclerListViewProps,
		prevState: RecyclerListViewProps,
		prevContext: any
	) -> (),
	componentWillUnmount: (self: RecyclerListView) -> (),
	componentDidCatch: (
		self: RecyclerListView,
		error: Error,
		info: {
			componentStack: string,
		}
	) -> (),
	getDerivedStateFromProps: (
		props: RecyclerListViewProps,
		state: RecyclerListViewState
	) -> RecyclerListViewState?,
	getDerivedStateFromError: ((error: Error) -> RecyclerListViewState?)?,
	getSnapshotBeforeUpdate: (
		props: RecyclerListViewProps,
		state: RecyclerListViewState
	) -> (),

	defaultProps: RecyclerListViewProps?,

	--
	-- *** PUBLIC ***
	--
	scrollToIndex: (self: RecyclerListView, index: number, animate: boolean?) -> (),
	--- This API is almost similar to scrollToIndex, but differs when the view is already in viewport.
	--- Instead of bringing the view to the top of the viewport, it will calculate the overflow of the @param index
	--- and scroll to just bring the entire view to viewport.
	bringToFocus: (self: RecyclerListView, index: number, animate: boolean?) -> (),
	scrollToItem: (self: RecyclerListView, data: any, animate: boolean?) -> (),
	getLayout: (self: RecyclerListView, index: number) -> Layout | nil,
	scrollToTop: (self: RecyclerListView, animate: boolean?) -> (),
	scrollToEnd: (self: RecyclerListView, animate: boolean?) -> (),
	-- useWindowCorrection specifies if correction should be applied to these offsets in case you implement
	-- `applyWindowCorrection` method
	scrollToOffset: any, -- You can use requestAnimationFrame callback to change renderAhead in multiple frames to enable advanced progressive
	-- rendering when view types are very complex. This method returns a boolean saying if the update was committed. Retry in
	-- the next frame if you get a failure (if mount wasn't complete). Value should be greater than or equal to 0;
	-- Very useful when you have a page where you need a large renderAheadOffset. Setting it at once will slow down the load and
	-- this will help mitigate that.
	updateRenderAheadOffset: (
		self: RecyclerListView,
		renderAheadOffset: number
	) -> boolean,
	getCurrentRenderAheadOffset: (self: RecyclerListView) -> number,
	getCurrentScrollOffset: (self: RecyclerListView) -> number,
	findApproxFirstVisibleIndex: (self: RecyclerListView) -> number,
	getRenderedSize: (self: RecyclerListView) -> Dimension,
	getContentDimension: (self: RecyclerListView) -> Dimension,
	-- Force Rerender forcefully to update view renderer. Use this in rare circumstances
	forceRerender: (self: RecyclerListView) -> (),
	getScrollableNode: (self: RecyclerListView) -> number | nil,
	-- Disables recycling for the next frame so that layout animations run well.
	-- WARNING: Avoid this when making large changes to the data as the list might draw too much to run animations. Single item insertions/deletions
	-- should be good. With recycling paused the list cannot do much optimization.
	-- The next render will run as normal and reuse items.
	prepareForLayoutAnimationRender: (self: RecyclerListView) -> (),
	--
	-- *** PROTECTED ***
	--
	getVirtualRenderer: (self: RecyclerListView) -> VirtualRenderer,
	onItemLayout: (self: RecyclerListView, index: number) -> (),
	--
	-- *** PRIVATE ***
	--
	refreshRequestDebouncer: (callback: () -> ()) -> (),
	_virtualRenderer: VirtualRenderer,
	_onEndReachedCalled: boolean,
	_initComplete: boolean,
	_isMounted: boolean,
	_relayoutReqIndex: number,
	_params: RenderStackParams,
	_layout: Dimension,
	_pendingScrollToOffset: Point | nil,
	_pendingRenderStack: RenderStack,
	_tempDim: Dimension,
	_initialOffset: number,
	_cachedLayouts: Array<Layout>,
	_scrollComponent: BaseScrollComponent | nil,
	_windowCorrectionConfig: WindowCorrectionConfig, --If the native content container is used, then positions of the list items are changed on the native side. The animated library used
	--by the default item animator also changes the same positions which could lead to inconsistency. Hence, the base item animator which
	--does not perform any such animations will be used.
	_defaultItemAnimator: ItemAnimator,
	_onItemLayout: any,
	_processInitialOffset: (self: RecyclerListView) -> (),
	_getContextFromContextProvider: (
		self: RecyclerListView,
		props: RecyclerListViewProps
	) -> (),
	_checkAndChangeLayouts: (
		self: RecyclerListView,
		newProps: RecyclerListViewProps,
		forceFullRender: boolean?
	) -> (),
	_refreshViewability: (self: RecyclerListView) -> (),
	_queueStateRefresh: (self: RecyclerListView) -> (),
	_onSizeChanged: any,
	_initStateIfRequired: (self: RecyclerListView, stack: RenderStack?) -> boolean,
	_renderStackWhenReady: any,
	_initTrackers: (self: RecyclerListView, props: RecyclerListViewProps) -> (),
	_getWindowCorrection: (
		self: RecyclerListView,
		offsetX: number,
		offsetY: number,
		props: RecyclerListViewProps
	) -> WindowCorrection,
	_assertDependencyPresence: (
		self: RecyclerListView,
		props: RecyclerListViewProps
	) -> (),
	_assertType: (self: RecyclerListView, type_: any) -> (),
	_dataHasChanged: any,
	_renderRowUsingMeta: (
		self: RecyclerListView,
		itemMeta: RenderStackItem
	) -> React.Node,
	_onViewContainerSizeChange: any,
	_checkExpectedDimensionDiscrepancy: (
		self: RecyclerListView,
		itemRect: Dimension,
		type_: any,
		index: number
	) -> (),
	_generateRenderStack: (self: RecyclerListView) -> Array<React.Node>,
	_onScroll: any,
	_processOnEndReached: (self: RecyclerListView) -> (),

	-- ROBLOX deviation: Merge `ProgressiveListView` into `RecyclerListView` to avoid inheritance complexities with React-lua.
	renderAheadUpdateConnection: RBXScriptConnection?,
	isFirstLayoutComplete: boolean,
	updateRenderAheadProgressively: (self: RecyclerListView, newVal: number) -> (),
	incrementRenderAhead: (self: RecyclerListView) -> (),
	performFinalUpdate: (self: RecyclerListView) -> (),
	cancelRenderAheadUpdate: (self: RecyclerListView) -> (),
}

local RecyclerListView: RecyclerListView =
	React.Component:extend("RecyclerListView") :: any

RecyclerListView.defaultProps = {
	canChangeSize = false,
	disableRecycling = false,
	initialOffset = 0,
	initialRenderIndex = 0,
	isHorizontal = false,
	onEndReachedThreshold = 0,
	onEndReachedThresholdRelative = 0,
	-- renderAheadOffset = if IS_WEB then 1000 else 250,
	renderAheadOffset = 250,
} :: any

function RecyclerListView:init(props)
	self.refreshRequestDebouncer = function(callback)
		task.delay(0, callback)
	end
	self._onEndReachedCalled = false
	self._initComplete = false
	self._isMounted = true
	self._relayoutReqIndex = -1
	self._params = {
		initialOffset = 0,
		initialRenderIndex = 0,
		isHorizontal = false,
		itemCount = 0,
		renderAheadOffset = 250,
	}
	self._layout = { height = 0, width = 0 }
	self._pendingScrollToOffset = nil
	self._tempDim = { height = 0, width = 0 }
	self._initialOffset = 0
	self._scrollComponent = nil
	self._defaultItemAnimator = BaseItemAnimator.new() :: any

	-- ROBLOX deviation: Merge `ProgressiveListView` into `RecyclerListView` to avoid inheritance complexities with React-lua.
	self.isFirstLayoutComplete = false

	self.scrollToOffset = function(
		x: number,
		y: number,
		animate_: boolean?,
		useWindowCorrection_: boolean?
	)
		local animate: boolean = if animate_ ~= nil then animate_ else false
		local useWindowCorrection: boolean = if useWindowCorrection_ ~= nil
			then useWindowCorrection_
			else false
		if self._scrollComponent then
			if self.props.isHorizontal then
				y = 0
				x = if useWindowCorrection
					then x - self._windowCorrectionConfig.value.windowShift
					else x
			else
				x = 0
				y = if useWindowCorrection
					then y - self._windowCorrectionConfig.value.windowShift
					else y
			end
			self._scrollComponent:scrollTo(x, y, animate)
		end
	end

	self._onItemLayout = function(index: number)
		self:onItemLayout(index)
	end

	self._onSizeChanged = function(layout: Dimension)
		if layout.height == 0 or layout.width == 0 then
			if not self.props.suppressBoundedSizeException then
				error(CustomError.new(RecyclerListViewExceptions.layoutException))
			else
				return
			end
		end

		if not self.props.canChangeSize and self.props.layoutSize then
			return
		end

		local hasHeightChanged = self._layout.height ~= layout.height
		local hasWidthChanged = self._layout.width ~= layout.width
		self._layout.height = layout.height
		self._layout.width = layout.width
		if not self._initComplete then
			self._initComplete = true
			self:_initTrackers(self.props)
			self:_processOnEndReached()
		else
			if
				(hasHeightChanged and hasWidthChanged)
				or (hasHeightChanged and self.props.isHorizontal)
				or (hasWidthChanged and not self.props.isHorizontal)
			then
				self:_checkAndChangeLayouts(self.props, true)
			else
				self:_refreshViewability()
			end
		end
	end

	self._renderStackWhenReady = function(stack: RenderStack)
		-- TODO: Flickers can further be reduced by setting _pendingScrollToOffset in constructor
		-- rather than in _onSizeChanged -> _initTrackers
		if self._pendingScrollToOffset then
			self._pendingRenderStack = stack
			return
		end
		if not self:_initStateIfRequired(stack) then
			self:setState(function()
				return { renderStack = stack } :: any
			end)
		end
	end

	self._dataHasChanged = function(row1: any, row2: any): boolean
		return self.props.dataProvider.rowHasChanged(row1, row2)
	end

	self._onViewContainerSizeChange = function(dim: Dimension, index: number)
		--Cannot be null here
		local layoutManager: LayoutManager =
			self._virtualRenderer:getLayoutManager() :: LayoutManager

		if self.props.debugHandlers and self.props.debugHandlers.resizeDebugHandler then
			local itemRect = layoutManager:getLayouts()[index]
			self.props.debugHandlers.resizeDebugHandler.resizeDebug({
				width = itemRect.width,
				height = itemRect.height,
			}, dim, index)
		end

		-- Add extra protection for overrideLayout as it can only be called when non-deterministic rendering is used.
		if
			self.props.forceNonDeterministicRendering
			and layoutManager:overrideLayout(index, dim)
		then
			if self._relayoutReqIndex == -1 then
				self._relayoutReqIndex = index
			else
				self._relayoutReqIndex = math.min(self._relayoutReqIndex, index)
			end
			self:_queueStateRefresh()
		end
	end

	self._onScroll = function(offsetX: number, offsetY: number, rawEvent: ScrollEvent)
		-- correction to be positive to shift offset upwards; negative to push offset downwards.
		-- extracting the correction value from logical offset and updating offset of virtual renderer.
		self._virtualRenderer:updateOffset(
			offsetX,
			offsetY,
			true,
			self:_getWindowCorrection(offsetX, offsetY, self.props)
		)

		if self.props.onScroll then
			self.props.onScroll(rawEvent, offsetX, offsetY)
		end

		self:_processOnEndReached()
	end

	self._virtualRenderer = VirtualRenderer.new(
		self._renderStackWhenReady,
		function(offset)
			self._pendingScrollToOffset = offset
		end,
		function(index)
			return self.props.dataProvider.getStableId(index)
		end,
		not props.disableRecycling
	)

	if self.props.windowCorrectionConfig then
		local windowCorrection
		if self.props.windowCorrectionConfig.value then
			windowCorrection = self.props.windowCorrectionConfig.value
		else
			windowCorrection = { startCorrection = 0, endCorrection = 0, windowShift = 0 }
		end
		self._windowCorrectionConfig = {
			applyToItemScroll = not not self.props.windowCorrectionConfig.applyToItemScroll,
			applyToInitialOffset = not not self.props.windowCorrectionConfig.applyToInitialOffset,
			value = windowCorrection,
		}
	else
		self._windowCorrectionConfig = {
			applyToItemScroll = false,
			applyToInitialOffset = false,
			value = { startCorrection = 0, endCorrection = 0, windowShift = 0 },
		}
	end

	self:_getContextFromContextProvider(props)

	if props.layoutSize then
		self._layout.height = props.layoutSize.height
		self._layout.width = props.layoutSize.width
		self._initComplete = true
		self:_initTrackers(props)
	else
		self.state = { internalSnapshot = {}, renderStack = {} }
	end
end

function RecyclerListView:componentDidUpdate(prevProps): ()
	do
		local newProps = self.props
		self.props = prevProps

		self:_assertDependencyPresence(newProps)
		self:_checkAndChangeLayouts(newProps)
		if not newProps.onVisibleIndicesChanged then
			self._virtualRenderer:removeVisibleItemsListener()
		end
		if newProps.onVisibleIndexesChanged then
			error(
				CustomError.new(
					RecyclerListViewExceptions.usingOldVisibleIndexesChangedParam
				)
			)
		end
		if newProps.onVisibleIndicesChanged then
			self._virtualRenderer:attachVisibleItemsListener(
				newProps.onVisibleIndicesChanged
			)
		end

		self.props = newProps
	end

	self:_processInitialOffset()
	self:_processOnEndReached()
	self:_checkAndChangeLayouts(self.props)
	self._virtualRenderer:setOptimizeForAnimations(false)
end

function RecyclerListView:componentDidMount(): ()
	-- ROBLOX deviation: Merge `ProgressiveListView` into `RecyclerListView` to avoid inheritance complexities with React-lua.
	if not self.props.forceNonDeterministicRendering then
		self:updateRenderAheadProgressively(self:getCurrentRenderAheadOffset())
	end

	if self._initComplete then
		self:_processInitialOffset()
		self:_processOnEndReached()
	end
end

function RecyclerListView:componentWillUnmount(): ()
	-- ROBLOX deviation: Merge `ProgressiveListView` into `RecyclerListView` to avoid inheritance complexities with React-lua.
	self:cancelRenderAheadUpdate()

	self._isMounted = false
	if self.props.contextProvider then
		local uniqueKey = self.props.contextProvider:getUniqueKey()
		if uniqueKey then
			self.props.contextProvider:save(
				uniqueKey .. Constants.CONTEXT_PROVIDER_OFFSET_KEY_SUFFIX,
				self:getCurrentScrollOffset()
			)

			if self.props.forceNonDeterministicRendering then
				if self._virtualRenderer then
					local layoutManager = self._virtualRenderer:getLayoutManager()
					if layoutManager then
						local layoutsToCache = layoutManager:getLayouts()
						self.props.contextProvider:save(
							uniqueKey .. Constants.CONTEXT_PROVIDER_LAYOUT_KEY_SUFFIX,
							-- JSON.stringify({ layoutArray = layoutsToCache })
							-- ROBLOX deviation: Store a table directly because JSON serde is slow with HTTPService
							{ layoutArray = layoutsToCache }
						)
					end
				end
			end
		end
	end
end

function RecyclerListView:scrollToIndex(index: number, animate: boolean?): ()
	local layoutManager = self._virtualRenderer:getLayoutManager()
	if layoutManager then
		local offsets = layoutManager:getOffsetForIndex(index)
		self:scrollToOffset(
			offsets.x,
			offsets.y,
			animate,
			self._windowCorrectionConfig.applyToItemScroll
		)
	else
		console.warn(Messages.WARN_SCROLL_TO_INDEX)
	end
end

function RecyclerListView:bringToFocus(index: number, animate: boolean?): ()
	local listSize = self:getRenderedSize()
	local itemLayout = self:getLayout(index)
	local currentScrollOffset = self:getCurrentScrollOffset()
		+ self._windowCorrectionConfig.value.windowShift
	local isHorizontal = self.props.isHorizontal
	if itemLayout then
		local mainAxisLayoutDimen = if isHorizontal
			then itemLayout.width
			else itemLayout.height
		local mainAxisLayoutPos = if isHorizontal then itemLayout.x else itemLayout.y
		local mainAxisListDimen = if isHorizontal then listSize.width else listSize.height
		local screenEndPos = mainAxisListDimen + currentScrollOffset
		if
			mainAxisLayoutDimen > mainAxisListDimen
			or mainAxisLayoutPos < currentScrollOffset
			or mainAxisLayoutPos > screenEndPos
		then
			self:scrollToIndex(index)
		else
			local viewEndPos = mainAxisLayoutPos + mainAxisLayoutDimen
			if viewEndPos > screenEndPos then
				local offset = viewEndPos - screenEndPos
				self:scrollToOffset(
					offset + currentScrollOffset,
					offset + currentScrollOffset,
					animate,
					true
				)
			end
		end
	end
end

function RecyclerListView:scrollToItem(data: any, animate: boolean?): ()
	local count = self.props.dataProvider:getSize()
	for i = 1, count do
		if self.props.dataProvider:getDataForIndex(i) == data then
			self:scrollToIndex(i, animate)
			break
		end
	end
end

function RecyclerListView:getLayout(index: number): Layout | nil
	local layoutManager = self._virtualRenderer:getLayoutManager()
	return if layoutManager then layoutManager:getLayouts()[index] else nil
end

function RecyclerListView:scrollToTop(animate: boolean?): ()
	self:scrollToOffset(0, 0, animate)
end

function RecyclerListView:scrollToEnd(animate: boolean?): ()
	local lastIndex = self.props.dataProvider:getSize()
	self:scrollToIndex(lastIndex, animate)
end

function RecyclerListView:updateRenderAheadOffset(renderAheadOffset: number): boolean
	local viewabilityTracker = self._virtualRenderer:getViewabilityTracker()
	if viewabilityTracker then
		viewabilityTracker:updateRenderAheadOffset(renderAheadOffset)
		return true
	end
	return false
end

function RecyclerListView:getCurrentRenderAheadOffset(): number
	local viewabilityTracker = self._virtualRenderer:getViewabilityTracker()
	if viewabilityTracker then
		return viewabilityTracker:getCurrentRenderAheadOffset()
	end
	return self.props.renderAheadOffset :: any
end

function RecyclerListView:getCurrentScrollOffset(): number
	local viewabilityTracker = self._virtualRenderer:getViewabilityTracker()
	return if viewabilityTracker then viewabilityTracker:getLastActualOffset() else 0
end

function RecyclerListView:findApproxFirstVisibleIndex(): number
	local viewabilityTracker = self._virtualRenderer:getViewabilityTracker()
	return if viewabilityTracker
		then viewabilityTracker:findFirstLogicallyVisibleIndex()
		else 0
end

function RecyclerListView:getRenderedSize(): Dimension
	return self._layout
end

function RecyclerListView:getContentDimension(): Dimension
	return self._virtualRenderer:getLayoutDimension()
end

function RecyclerListView:forceRerender(): ()
	self:setState({ internalSnapshot = {} } :: any)
end

function RecyclerListView:getScrollableNode(): number | nil
	if self._scrollComponent and self._scrollComponent.getScrollableNode then
		return self._scrollComponent:getScrollableNode()
	end
	return nil
end

function RecyclerListView:render()
	return React.createElement(
		ScrollComponent,
		Object.assign(
			{
				ref = function(scrollComponent)
					self._scrollComponent = scrollComponent :: BaseScrollComponent | nil
					return self._scrollComponent
				end,
			},
			self.props,
			self.props.scrollViewProps,
			{
				onScroll = self._onScroll,
				onSizeChanged = self._onSizeChanged,
				contentHeight = if self._initComplete
					then self._virtualRenderer:getLayoutDimension().height
					else 0,
				contentWidth = if self._initComplete
					then self._virtualRenderer:getLayoutDimension().width
					else 0,
				renderAheadOffset = self:getCurrentRenderAheadOffset(),
			}
		),
		self:_generateRenderStack()
	)
end

function RecyclerListView:prepareForLayoutAnimationRender(): ()
	self._virtualRenderer:setOptimizeForAnimations(true)
end

function RecyclerListView:getVirtualRenderer(): VirtualRenderer
	return self._virtualRenderer
end

function RecyclerListView:onItemLayout(index: number): ()
	-- ROBLOX deviation: Merge `ProgressiveListView` into `RecyclerListView` to avoid inheritance complexities with React-lua.
	if not self.isFirstLayoutComplete then
		self.isFirstLayoutComplete = true
		if self.props.forceNonDeterministicRendering then
			self:updateRenderAheadProgressively(self:getCurrentRenderAheadOffset())
		end
	end

	if self.props.onItemLayout then
		self.props.onItemLayout(index)
	end
end

function RecyclerListView:_processInitialOffset(): ()
	if self._pendingScrollToOffset then
		setTimeout(function()
			if self._pendingScrollToOffset then
				local offset = self._pendingScrollToOffset
				self._pendingScrollToOffset = nil
				if self.props.isHorizontal then
					offset.y = 0
				else
					offset.x = 0
				end
				self:scrollToOffset(
					offset.x,
					offset.y,
					false,
					self._windowCorrectionConfig.applyToInitialOffset
				)
				if self._pendingRenderStack then
					self:_renderStackWhenReady(self._pendingRenderStack)
					self._pendingRenderStack = nil :: any
				end
			end
		end, 0)
	end
end

function RecyclerListView:_getContextFromContextProvider(props: RecyclerListViewProps): ()
	if props.contextProvider then
		local uniqueKey = props.contextProvider:getUniqueKey()
		if uniqueKey then
			local offset = props.contextProvider:get(
				uniqueKey .. Constants.CONTEXT_PROVIDER_OFFSET_KEY_SUFFIX
			)
			if type(offset) == "number" and offset > 0 then
				self._initialOffset = offset
				if props.onRecreate then
					props.onRecreate({ lastOffset = self._initialOffset })
				end
				props.contextProvider:remove(
					uniqueKey .. Constants.CONTEXT_PROVIDER_OFFSET_KEY_SUFFIX
				)
			end
			if props.forceNonDeterministicRendering then
				local cachedLayouts = props.contextProvider:get(
					uniqueKey .. Constants.CONTEXT_PROVIDER_LAYOUT_KEY_SUFFIX
				)
				if cachedLayouts then
					self._cachedLayouts = cachedLayouts :: Array<Layout>
					props.contextProvider:remove(
						uniqueKey .. Constants.CONTEXT_PROVIDER_LAYOUT_KEY_SUFFIX
					)
				end
			end
		end
	end
end

function RecyclerListView:_checkAndChangeLayouts(
	newProps: RecyclerListViewProps,
	forceFullRender: boolean?
): ()
	self._params.isHorizontal = newProps.isHorizontal
	self._params.itemCount = newProps.dataProvider:getSize()
	self._virtualRenderer:setParamsAndDimensions(self._params, self._layout)
	self._virtualRenderer:setLayoutProvider(newProps.layoutProvider)
	if
		newProps.dataProvider:hasStableIds()
		and self.props.dataProvider ~= newProps.dataProvider
	then
		if newProps.dataProvider:requiresDataChangeHandling() then
			self._virtualRenderer:handleDataSetChange(newProps.dataProvider)
		elseif self._virtualRenderer:hasPendingAnimationOptimization() then
			console.warn(Messages.ANIMATION_ON_PAGINATION)
		end
	end
	if
		self.props.layoutProvider ~= newProps.layoutProvider
		or self.props.isHorizontal ~= newProps.isHorizontal
	then
		--TODO:Talha use old layout manager
		self._virtualRenderer:setLayoutManager(
			newProps.layoutProvider:createLayoutManager(
				self._layout,
				newProps.isHorizontal
			)
		)
		if newProps.layoutProvider.shouldRefreshWithAnchoring then
			self._virtualRenderer:refreshWithAnchor()
		else
			self._virtualRenderer:refresh()
		end
		self:_refreshViewability()
	elseif self.props.dataProvider ~= newProps.dataProvider then
		if newProps.dataProvider:getSize() > self.props.dataProvider:getSize() then
			self._onEndReachedCalled = false
		end
		local layoutManager = self._virtualRenderer:getLayoutManager()
		if layoutManager then
			layoutManager:relayoutFromIndex(
				newProps.dataProvider:getFirstIndexToProcessInternal(),
				newProps.dataProvider:getSize()
			)
			self._virtualRenderer:refresh()
		end
	elseif forceFullRender then
		local layoutManager = self._virtualRenderer:getLayoutManager()
		if layoutManager then
			local cachedLayouts = layoutManager:getLayouts()
			self._virtualRenderer:setLayoutManager(
				newProps.layoutProvider:createLayoutManager(
					self._layout,
					newProps.isHorizontal,
					cachedLayouts
				)
			)
			self:_refreshViewability()
		end
	elseif self._relayoutReqIndex >= 1 then
		local layoutManager = self._virtualRenderer:getLayoutManager()
		if layoutManager then
			local dataProviderSize = newProps.dataProvider:getSize()
			layoutManager:relayoutFromIndex(
				math.min(math.max(dataProviderSize, 1), self._relayoutReqIndex),
				dataProviderSize
			)
			self._relayoutReqIndex = -1
			self:_refreshViewability()
		end
	end
end

function RecyclerListView:_refreshViewability(): ()
	self._virtualRenderer:refresh()
	self:_queueStateRefresh()
end

function RecyclerListView:_queueStateRefresh(): ()
	self.refreshRequestDebouncer(function()
		if self._isMounted then
			self:setState(function(prevState)
				return prevState
			end)
		end
	end)
end

function RecyclerListView:_initStateIfRequired(stack: RenderStack?): boolean
	if not self.state then
		self.state = { internalSnapshot = {}, renderStack = stack } :: any
		return true
	end
	return false
end

function RecyclerListView:_initTrackers(props: RecyclerListViewProps): ()
	self:_assertDependencyPresence(props)
	if props.onVisibleIndexesChanged then
		error(
			CustomError.new(RecyclerListViewExceptions.usingOldVisibleIndexesChangedParam)
		)
	end
	if props.onVisibleIndicesChanged then
		self._virtualRenderer:attachVisibleItemsListener(
			props.onVisibleIndicesChanged :: any
		)
	end
	self._params = {
		initialOffset = if self._initialOffset
			then self._initialOffset
			else props.initialOffset,
		initialRenderIndex = props.initialRenderIndex,
		isHorizontal = props.isHorizontal,
		itemCount = props.dataProvider:getSize(),
		renderAheadOffset = props.renderAheadOffset,
	}
	self._virtualRenderer:setParamsAndDimensions(self._params, self._layout)
	local layoutManager = props.layoutProvider:createLayoutManager(
		self._layout,
		props.isHorizontal,
		self._cachedLayouts
	)
	self._virtualRenderer:setLayoutManager(layoutManager)
	self._virtualRenderer:setLayoutProvider(props.layoutProvider)
	self._virtualRenderer:init()
	local offset = self._virtualRenderer:getInitialOffset()
	local contentDimension = layoutManager:getContentDimension()
	if
		offset.y > 0 and contentDimension.height > self._layout.height
		or offset.x > 0 and contentDimension.width > self._layout.width
	then
		self._pendingScrollToOffset = offset
		if not self:_initStateIfRequired() then
			self:setState({} :: any)
		end
	else
		self._virtualRenderer:startViewabilityTracker(
			self:_getWindowCorrection(offset.x, offset.y, props)
		)
	end
end

function RecyclerListView:_getWindowCorrection(
	offsetX: number,
	offsetY: number,
	props: RecyclerListViewProps
): WindowCorrection
	return (
		props.applyWindowCorrection
		and props.applyWindowCorrection(
			offsetX,
			offsetY,
			self._windowCorrectionConfig.value
		)
	) or self._windowCorrectionConfig.value
end

function RecyclerListView:_assertDependencyPresence(props: RecyclerListViewProps): ()
	if not props.dataProvider or not props.layoutProvider then
		error(CustomError.new(RecyclerListViewExceptions.unresolvedDependenciesException))
	end
end

function RecyclerListView:_assertType(type_): ()
	if not type_ and type_ ~= 0 then
		error(CustomError.new(RecyclerListViewExceptions.itemTypeNullException))
	end
end

function RecyclerListView:_renderRowUsingMeta(itemMeta: RenderStackItem): React.Node | nil
	local dataSize = self.props.dataProvider:getSize()
	local dataIndex = itemMeta.dataIndex
	if dataIndex ~= nil and dataIndex <= dataSize then
		local itemRect = (self._virtualRenderer:getLayoutManager() :: LayoutManager):getLayouts()[dataIndex]
		local data = self.props.dataProvider:getDataForIndex(dataIndex)
		local type_ = self.props.layoutProvider:getLayoutTypeForIndex(dataIndex)
		local key = self._virtualRenderer:syncAndGetKey(dataIndex)
		local styleOverrides = (self._virtualRenderer:getLayoutManager() :: LayoutManager):getStyleOverridesForIndex(
			dataIndex
		)
		self:_assertType(type_)
		if not self.props.forceNonDeterministicRendering then
			self:_checkExpectedDimensionDiscrepancy(itemRect, type_, dataIndex)
		end
		return React.createElement(ViewRenderer, {
			key = key,
			data = data,
			dataHasChanged = self._dataHasChanged,
			x = itemRect.x,
			y = itemRect.y,
			layoutType = type_,
			index = dataIndex,
			styleOverrides = styleOverrides,
			layoutProvider = self.props.layoutProvider,
			forceNonDeterministicRendering = self.props.forceNonDeterministicRendering,
			isHorizontal = self.props.isHorizontal,
			onSizeChanged = self._onViewContainerSizeChange,
			childRenderer = self.props.rowRenderer,
			height = itemRect.height,
			width = itemRect.width,
			itemAnimator = if self.props.itemAnimator
				then self.props.itemAnimator
				else self._defaultItemAnimator,
			extendedState = self.props.extendedState,
			internalSnapshot = self.state.internalSnapshot,
			renderItemContainer = self.props.renderItemContainer,
			onItemLayout = self._onItemLayout,
		})
	end
	return nil
end

function RecyclerListView:_checkExpectedDimensionDiscrepancy(
	itemRect: Dimension,
	type_,
	index: number
): ()
	if self.props.layoutProvider:checkDimensionDiscrepancy(itemRect, type_, index) then
		if self._relayoutReqIndex == -1 then
			self._relayoutReqIndex = index
		else
			self._relayoutReqIndex = math.min(self._relayoutReqIndex, index)
		end
	end
end

function RecyclerListView:_generateRenderStack(): Array<React.Node | nil>
	local renderedItems = {}
	if self.state and self.state.renderStack then
		for key, stackItem in self.state.renderStack do
			table.insert(renderedItems, self:_renderRowUsingMeta(stackItem))
		end
	end
	return renderedItems
end

function RecyclerListView:_processOnEndReached(): ()
	if self.props.onEndReached and self._virtualRenderer then
		local layout = self._virtualRenderer:getLayoutDimension()
		local viewabilityTracker = self._virtualRenderer:getViewabilityTracker()
		if viewabilityTracker then
			local windowBound = if self.props.isHorizontal
				then layout.width - self._layout.width
				else layout.height - self._layout.height
			local lastOffset = if viewabilityTracker
				then viewabilityTracker:getLastOffset()
				else 0
			local threshold = windowBound - lastOffset

			local listLength = if self.props.isHorizontal
				then self._layout.width
				else self._layout.height
			local triggerOnEndThresholdRelative = listLength
				* if self.props.onEndReachedThresholdRelative
					then self.props.onEndReachedThresholdRelative
					else 0
			local triggerOnEndThreshold = if self.props.onEndReachedThreshold
				then self.props.onEndReachedThreshold
				else 0

			if
				threshold <= triggerOnEndThresholdRelative
				or threshold <= triggerOnEndThreshold
			then
				if self.props.onEndReached and not self._onEndReachedCalled then
					self._onEndReachedCalled = true
					self.props.onEndReached()
				end
			else
				self._onEndReachedCalled = false
			end
		end
	end
end

function RecyclerListView:updateRenderAheadProgressively(newVal: number): ()
	self:cancelRenderAheadUpdate()
	-- Cancel any pending callback.
	local function updateLoop()
		if not self:updateRenderAheadOffset(newVal) then
			self:updateRenderAheadProgressively(newVal)
		else
			self:incrementRenderAhead()
		end
	end

	-- NOTE: The list might be running in a storybook plugin. In which case, mock the update loop
	if RunService:IsStudio() and not RunService:IsRunning() then
		task.delay(0, updateLoop)
	else
		self.renderAheadUpdateConnection = RunService.RenderStepped:Once(updateLoop)
	end
end

function RecyclerListView:incrementRenderAhead(): ()
	if self.props.maxRenderAhead and self.props.renderAheadStep then
		local layoutManager = self:getVirtualRenderer():getLayoutManager()
		local currentRenderAheadOffset = self:getCurrentRenderAheadOffset()
		if layoutManager then
			local contentDimension = layoutManager:getContentDimension()
			local maxContentSize = if self.props.isHorizontal
				then contentDimension.width
				else contentDimension.height
			if
				currentRenderAheadOffset < maxContentSize
				and currentRenderAheadOffset < self.props.maxRenderAhead
			then
				local newRenderAheadOffset = currentRenderAheadOffset
					+ self.props.renderAheadStep
				self:updateRenderAheadProgressively(newRenderAheadOffset)
			else
				self:performFinalUpdate()
			end
		end
	end
end

function RecyclerListView:performFinalUpdate(): ()
	self:cancelRenderAheadUpdate()
	-- Cancel any pending callback.

	local function updateLoop()
		if self.props.finalRenderAheadOffset ~= nil then
			self:updateRenderAheadOffset(self.props.finalRenderAheadOffset)
		end
	end

	-- NOTE: The list might be running in a storybook plugin. In which case, mock the update loop
	if RunService:IsStudio() and not RunService:IsRunning() then
		task.delay(0, updateLoop)
	else
		self.renderAheadUpdateConnection = RunService.RenderStepped:Once(updateLoop)
	end
end

function RecyclerListView:cancelRenderAheadUpdate(): ()
	if self.renderAheadUpdateConnection ~= nil then
		self.renderAheadUpdateConnection:Disconnect()
		self.renderAheadUpdateConnection = nil
	end
end

-- RecyclerListView.propTypes = {
-- 	--Refer the sample
-- 	layoutProvider = PropTypes:instanceOf(BaseLayoutProvider).isRequired,
-- 	--Refer the sample
-- 	dataProvider = PropTypes:instanceOf(BaseDataProvider).isRequired,
-- 	--Used to maintain scroll position in case view gets destroyed e.g, cases of back navigation
-- 	contextProvider = PropTypes:instanceOf(ContextProvider),
-- 	--Methods which returns react component to be rendered. You get type of view and data in the callback.
-- 	rowRenderer = PropTypes.func.isRequired,
-- 	--Initial offset you want to start rendering from, very useful if you want to maintain scroll context across pages.
-- 	initialOffset = PropTypes.number,
-- 	--Specify how many pixels in advance do you want views to be rendered. Increasing this value can help reduce blanks (if any). However keeping this as low
-- 	--as possible should be the intent. Higher values also increase re-render compute
-- 	renderAheadOffset = PropTypes.number,
-- 	--Whether the listview is horizontally scrollable. Both use staggeredGrid implementation
-- 	isHorizontal = PropTypes.bool,
-- 	--On scroll callback onScroll(rawEvent, offsetX, offsetY), note you get offsets no need to read scrollTop/scrollLeft
-- 	onScroll = PropTypes.func,
-- 	--callback onRecreate(params), when recreating recycler view from context provider. Gives you the initial params in the first
-- 	--frame itself to allow you to render content accordingly
-- 	onRecreate = PropTypes.func,
-- 	--Provide your own ScrollView Component. The contract for the scroll event should match the native scroll event contract, i.e.
-- 	-- scrollEvent = { nativeEvent: { contentOffset: { x: offset, y: offset } } }
-- 	--Note: Please extend BaseScrollView to achieve expected behaviour
-- 	externalScrollView = PropTypes:oneOfType({ PropTypes.func, PropTypes.object }),
-- 	--Callback given when user scrolls to the end of the list or footer just becomes visible, useful in incremental loading scenarios
-- 	onEndReached = PropTypes.func,
-- 	--Specify how many pixels in advance you onEndReached callback
-- 	onEndReachedThreshold = PropTypes.number,
-- 	--Specify how far from the end (in units of visible length of the list)
-- 	--the bottom edge of the list must be from the end of the content to trigger the onEndReached callback
-- 	onEndReachedThresholdRelative = PropTypes.number,
-- 	--Deprecated. Please use onVisibleIndicesChanged instead.
-- 	onVisibleIndexesChanged = PropTypes.func,
-- 	--Provides visible index, helpful in sending impression events etc, onVisibleIndicesChanged(all, now, notNow)
-- 	onVisibleIndicesChanged = PropTypes.func,
-- 	--Provide this method if you want to render a footer. Helpful in showing a loader while doing incremental loads.
-- 	renderFooter = PropTypes.func,
-- 	--Specify the initial item index you want rendering to start from. Preferred over initialOffset if both are specified.
-- 	initialRenderIndex = PropTypes.number,
-- 	--Specify the estimated size of the recyclerlistview to render the list items in the first pass. If provided, recyclerlistview will
-- 	--use these dimensions to fill in the items in the first render. If not provided, recyclerlistview will first render with no items
-- 	--and then fill in the items based on the size given by its onLayout event. canChangeSize can be set to true to relayout items when
-- 	--the size changes.
-- 	layoutSize = PropTypes.object,
-- 	--iOS only. Scroll throttle duration.
-- 	scrollThrottle = PropTypes.number,
-- 	--Specify if size can change, listview will automatically relayout items. For web, works only with useWindowScroll = true
-- 	canChangeSize = PropTypes.bool,
-- 	--Web only. Layout elements in window instead of a scrollable div.
-- 	useWindowScroll = PropTypes.bool,
-- 	--Turns off recycling. You still get progressive rendering and all other features. Good for lazy rendering. This should not be used in most cases.
-- 	disableRecycling = PropTypes.bool,
-- 	--Default is false, if enabled dimensions provided in layout provider will not be strictly enforced.
-- 	--Rendered dimensions will be used to relayout items. Slower if enabled.
-- 	forceNonDeterministicRendering = PropTypes.bool,
-- 	--In some cases the data passed at row level may not contain all the info that the item depends upon, you can keep all other info
-- 	--outside and pass it down via this prop. Changing this object will cause everything to re-render. Make sure you don't change
-- 	--it often to ensure performance. Re-renders are heavy.
-- 	extendedState = PropTypes.object,
-- 	--Enables animating RecyclerListView item cells e.g, shift, add, remove etc. This prop can be used to pass an external item animation implementation.
-- 	--Look into BaseItemAnimator/DefaultJSItemAnimator/DefaultNativeItemAnimator/DefaultWebItemAnimator for more info.
-- 	--By default there are few animations, to disable completely simply pass blank new BaseItemAnimator() object. Remember, create
-- 	--one object and keep it do not create multiple object of type BaseItemAnimator.
-- 	--Note: You might want to look into DefaultNativeItemAnimator to check an implementation based on LayoutAnimation. By default,
-- 	--animations are JS driven to avoid workflow interference. Also, please note LayoutAnimation is buggy on Android.
-- 	itemAnimator = PropTypes:instanceOf(BaseItemAnimator),
-- 	--All of the Recyclerlistview item cells are enclosed inside this item container. The idea is pass a native UI component which implements a
-- 	--view shifting algorithm to remove the overlaps between the neighbouring views. This is achieved by shifting them by the appropriate
-- 	--amount in the correct direction if the estimated sizes of the item cells are not accurate. If this props is passed, it will be used to
-- 	--enclose the list items and otherwise a default react native View will be used for the same.
-- 	renderContentContainer = PropTypes.func,
-- 	--This container is for wrapping individual cells that are being rendered by recyclerlistview unlike contentContainer which wraps all of them.
-- 	renderItemContainer = PropTypes.func,
-- 	--Deprecated in favour of `prepareForLayoutAnimationRender` method
-- 	optimizeForInsertDeleteAnimations = PropTypes.bool,
-- 	--To pass down style to inner ScrollView
-- 	style = PropTypes:oneOfType({ PropTypes.object, PropTypes.number }),
-- 	--For TS use case, not necessary with JS use.
-- 	--For all props that need to be proxied to inner/external scrollview. Put them in an object and they'll be spread
-- 	--and passed down.
-- 	scrollViewProps = PropTypes.object,
-- 	-- Used when the logical offsetY differs from actual offsetY of recyclerlistview, could be because some other component is overlaying the recyclerlistview.
-- 	-- For e.x. toolbar within CoordinatorLayout are overlapping the recyclerlistview.
-- 	-- This method exposes the windowCorrection object of RecyclerListView, user can modify the values in realtime.
-- 	applyWindowCorrection = PropTypes.func,
-- 	-- This can be used to hook an itemLayoutListener to listen to which item at what index is layout.
-- 	-- To get the layout params of the item, you can use the ref to call method getLayout(index), e.x. : `this._recyclerRef.getLayout(index)`
-- 	-- but there is a catch here, since there might be a pending relayout due to which the queried layout might not be precise.
-- 	-- Caution: RLV only listens to layout changes if forceNonDeterministicRendering is true
-- 	onItemLayout = PropTypes.func,
-- 	--Used to specify is window correction config and whether it should be applied to some scroll events
-- 	windowCorrectionConfig = PropTypes.object,
-- }

return RecyclerListView
