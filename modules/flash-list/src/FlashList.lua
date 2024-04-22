-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/FlashList.tsx

local FlashListProps = require("./FlashListProps")

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Object = LuauPolyfill.Object
local clearTimeout = LuauPolyfill.clearTimeout
local console = LuauPolyfill.console
local setTimeout = LuauPolyfill.setTimeout
local toJSBoolean = LuauPolyfill.Boolean.toJSBoolean

local React = require("@pkg/@jsdotlua/react")
local ViewabilityManager = require("./viewability/ViewabilityManager")
local Warnings = require("./errors/Warnings")

-- TODO: Import `GridLayoutProviderWithProps` and its type.
local GridLayoutProviderWithProps = { new = function(a, b, c, d, e) end }
type GridLayoutProviderWithProps<T> = any

type LayoutChangeEvent = any

-- TODO: Import from React Native.
type NativeSyntheticEvent<T> = any
type NativeScrollEvent = any

type FlashListComponent = FlashListProps.FlashListComponent
type FlashListProps<TItem> = FlashListProps.FlashListProps<TItem>
type FlashListState<TItem> = FlashListProps.FlashListState<TItem>
type RenderTarget = FlashListProps.RenderTarget

local FlashList: FlashListComponent = React.PureComponent:extend("FlashList")

function FlashList.init(self: FlashListComponent)
	local props = self.props

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

	self.isEmptyList = false
	-- self.viewabilityManager: ViewabilityManager<T>? = nil
	-- self.itemAnimator: BaseItemAnimator? = nil

	if toJSBoolean(props.estimatedListSize) then
		if toJSBoolean(props.horizontal) then
			self.listFixedDimensionSize = props.estimatedListSize.height
		else
			self.listFixedDimensionSize = props.estimatedListSize.width
		end
	end

	self.distanceFromWindow = props.estimatedFirstItemOffset
	if self.distanceFromWindow == nil then
		self.distanceFromWindow = (props.ListHeaderComponent and 1) or 0
	end

	self.state = FlashList.getInitialMutableState(self)
	self.viewabilityManager = ViewabilityManager.new(self)
	-- self.itemAnimator = getItemAnimator()
end

-- private validateProps() {
-- 	if (this.props.onRefresh && typeof this.props.refreshing !== "boolean") {
-- 		throw new CustomError(ExceptionList.refreshBooleanMissing);
-- 	}
-- 	if (
-- 		Number(this.props.stickyHeaderIndices?.length) > 0 &&
-- 		this.props.horizontal
-- 	) {
-- 		throw new CustomError(ExceptionList.stickyWhileHorizontalNotSupported);
-- 	}
-- 	if (Number(this.props.numColumns) > 1 && this.props.horizontal) {
-- 		throw new CustomError(ExceptionList.columnsWhileHorizontalNotSupported);
-- 	}

-- 	// `createAnimatedComponent` always passes a blank style object. To avoid warning while using AnimatedFlashList we've modified the check
-- 	// `style` prop can be an array. So we need to validate every object in array. Check: https://github.com/Shopify/flash-list/issues/651
-- 	if (
-- 		__DEV__ &&
-- 		Object.keys(StyleSheet.flatten(this.props.style ?? {})).length > 0
-- 	) {
-- 		console.warn(WarningList.styleUnsupported);
-- 	}
-- 	if (
-- 		hasUnsupportedKeysInContentContainerStyle(
-- 		this.props.contentContainerStyle
-- 	)
-- 	) {
-- 		console.warn(WarningList.styleContentContainerUnsupported);
-- 	}
-- }

function FlashList.onEndReached(self: FlashListComponent)
	if self.props.onEndReached ~= nil then
		self.props.onEndReached()
	end
end

function FlashList.getRefreshControl(self: FlashListComponent)
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
end

function FlashList.componentDidMount(self: FlashListComponent)
	if self.props.data ~= nil and #self.props.data > 0 then
		self:raiseOnLoadEventIfNeeded()
	end
end

function FlashList.componentWillUnmount(self: FlashListComponent)
	self.viewabilityManager:dispose()
	self:clearPostLoadTimeout()
	self:clearRenderSizeWarningTimeout()

	if self.itemSizeWarningTimeoutId ~= nil then
		clearTimeout(self.itemSizeWarningTimeoutId)
	end
end

-- render() {
--   this.isEmptyList = this.state.dataProvider.getSize() === 0;
--   updateContentStyle(this.contentStyle, this.props.contentContainerStyle);

--   const {
--     drawDistance,
--     removeClippedSubviews,
--     stickyHeaderIndices,
--     horizontal,
--     onEndReachedThreshold,
--     estimatedListSize,
--     initialScrollIndex,
--     style,
--     contentContainerStyle,
--     renderScrollComponent,
--     ...restProps
--   } = this.props;

--   // RecyclerListView simply ignores if initialScrollIndex is set to 0 because it doesn't understand headers
--   // Using initialOffset to force RLV to scroll to the right place
--   const initialOffset =
--     (this.isInitialScrollIndexInFirstRow() && this.distanceFromWindow) ||
--     undefined;
--   const finalDrawDistance =
--     drawDistance === undefined
--       ? PlatformConfig.defaultDrawDistance
--       : drawDistance;

--   return (
--     <StickyHeaderContainer
--       overrideRowRenderer={this.stickyOverrideRowRenderer}
--       applyWindowCorrection={this.applyWindowCorrection}
--       stickyHeaderIndices={stickyHeaderIndices}
--       style={
--         this.props.horizontal
--           ? { ...this.getTransform() }
--           : { flex: 1, overflow: "hidden", ...this.getTransform() }
--       }
--     >
--       <ProgressiveListView
--         {...restProps}
--         ref={this.recyclerRef}
--         layoutProvider={this.state.layoutProvider}
--         dataProvider={this.state.dataProvider}
--         rowRenderer={this.emptyRowRenderer}
--         canChangeSize
--         isHorizontal={Boolean(horizontal)}
--         scrollViewProps={{
--           onScrollBeginDrag: this.onScrollBeginDrag,
--           onLayout: this.handleSizeChange,
--           refreshControl:
--             this.props.refreshControl || this.getRefreshControl(),

--           // Min values are being used to suppress RLV's bounded exception
--           style: { minHeight: 1, minWidth: 1 },
--           contentContainerStyle: {
--             backgroundColor: this.contentStyle.backgroundColor,

--             // Required to handle a scrollview bug. Check: https://github.com/Shopify/flash-list/pull/187
--             minHeight: 1,
--             minWidth: 1,

--             ...getContentContainerPadding(this.contentStyle, horizontal),
--           },
--           ...this.props.overrideProps,
--         }}
--         forceNonDeterministicRendering
--         renderItemContainer={this.itemContainer}
--         renderContentContainer={this.container}
--         onEndReached={this.onEndReached}
--         onEndReachedThresholdRelative={onEndReachedThreshold || undefined}
--         extendedState={this.state.extraData}
--         layoutSize={estimatedListSize}
--         maxRenderAhead={3 * finalDrawDistance}
--         finalRenderAheadOffset={finalDrawDistance}
--         renderAheadStep={finalDrawDistance}
--         initialRenderIndex={
--           (!this.isInitialScrollIndexInFirstRow() && initialScrollIndex) ||
--           undefined
--         }
--         initialOffset={initialOffset}
--         onItemLayout={this.onItemLayout}
--         onScroll={this.onScroll}
--         onVisibleIndicesChanged={
--           this.viewabilityManager.shouldListenToVisibleIndices
--             ? this.viewabilityManager.onVisibleIndicesChanged
--             : undefined
--         }
--         windowCorrectionConfig={this.getUpdatedWindowCorrectionConfig()}
--         itemAnimator={this.itemAnimator}
--         suppressBoundedSizeException
--         externalScrollView={
--           renderScrollComponent as RecyclerListViewProps["externalScrollView"]
--         }
--       />
--     </StickyHeaderContainer>
--   );
-- }

function FlashList.onScrollBeginDrag(
	self: FlashListComponent,
	event: NativeSyntheticEvent<NativeScrollEvent>
)
	self:recordInteraction()

	if self.props.onScrollBeginDrag ~= nil then
		self.props.onScrollBeginDrag(event)
	end
end

function FlashList.onScroll(
	self: FlashListComponent,
	event: NativeSyntheticEvent<NativeScrollEvent>
)
	self:recordInteraction()
	self.viewabilityManager:updateViewableItems()

	if self.props.onScroll ~= nil then
		self.props.onScroll(event)
	end
end

function FlashList.getUpdatedWindowCorrectionConfig(self: FlashListComponent)
	if toJSBoolean(self:isInitialScrollIndexInFirstRow()) then
		self.windowCorrectionConfig.applyToIniitalOffset = false
	else
		self.windowCorrectionConfig.applyToIniitalOffset = true
	end

	self.windowCorrectionConfig.value.windowShift = -self.distanceFromWindow

	return self.windowCorrectionConfig
end

function FlashList.isInitialScrollIndexInFirstRow(self: FlashListComponent)
	return (
		if self.props.initialScrollIndex ~= nil
			then self.props.initialScrollIndex
			else self.state.numColumns
	) < self.state.numColumns
end

function FlashList.validateListSize(self: FlashListComponent, event: LayoutChangeEvent)
	local height = event.nativeEvent.layout.height
	local width = event.nativeEvent.layout.width

	self:clearRenderSizeWarningTimeout()

	if math.floor(height) < 1 or math.floor(width) < 1 then
		self.renderedSizeWarningTimeoutId = setTimeout(function()
			console.warn(Warnings.unusableRenderedSize)
		end, 1000)
	end
end

function FlashList.handleSizeChange(self: FlashListComponent, event: LayoutChangeEvent)
	self:validateListSize(event)

	local oldSize = self.listFixedDimensionSize
	local newSize = if toJSBoolean(self.props.horizontal)
		then event.nativeEvent.layout.height
		else event.nativeEvent.layout.width

	-- >0 check is to avoid rerender on mount where it would be redundant
	self.listFixedDimensionSize = newSize

	if oldSize > 0 and oldSize ~= newSize then
		local ref = if typeof(self.rlvRef) == "table"
			then self.rlvRef.forceRerender
			else nil
		if ref ~= nil then
			ref()
		end
	end

	if toJSBoolean(self.props.onLayout) then
		self.props.onLayout(event)
	end
end

-- private container = (props: object, children: React.ReactNode[]) => {
-- 	this.clearPostLoadTimeout();
-- 	return (
-- 	  <>
-- 		<PureComponentWrapper
-- 		  enabled={this.isListLoaded || children.length > 0 || this.isEmptyList}
-- 		  contentStyle={this.props.contentContainerStyle}
-- 		  horizontal={this.props.horizontal}
-- 		  header={this.props.ListHeaderComponent}
-- 		  extraData={this.state.extraData}
-- 		  headerStyle={this.props.ListHeaderComponentStyle}
-- 		  inverted={this.props.inverted}
-- 		  renderer={this.header}
-- 		/>
-- 		<AutoLayoutView
-- 		  {...props}
-- 		  onBlankAreaEvent={this.props.onBlankArea}
-- 		  onLayout={this.updateDistanceFromWindow}
-- 		  disableAutoLayout={this.props.disableAutoLayout}
-- 		>
-- 		  {children}
-- 		</AutoLayoutView>
-- 		{this.isEmptyList
-- 		  ? this.getValidComponent(this.props.ListEmptyComponent)
-- 		  : null}
-- 		<PureComponentWrapper
-- 		  enabled={this.isListLoaded || children.length > 0 || this.isEmptyList}
-- 		  contentStyle={this.props.contentContainerStyle}
-- 		  horizontal={this.props.horizontal}
-- 		  header={this.props.ListFooterComponent}
-- 		  extraData={this.state.extraData}
-- 		  headerStyle={this.props.ListFooterComponentStyle}
-- 		  inverted={this.props.inverted}
-- 		  renderer={this.footer}
-- 		/>
-- 		{this.getComponentForHeightMeasurement()}
-- 	  </>
-- 	);
--   };

--   private itemContainer = (props: any, parentProps: any) => {
-- 	const CellRendererComponent =
-- 	  this.props.CellRendererComponent ?? CellContainer;
-- 	return (
-- 	  <CellRendererComponent
-- 		{...props}
-- 		style={{
-- 		  ...props.style,
-- 		  flexDirection: this.props.horizontal ? "row" : "column",
-- 		  alignItems: "stretch",
-- 		  ...this.getTransform(),
-- 		  ...getCellContainerPlatformStyles(this.props.inverted!!, parentProps),
-- 		}}
-- 		index={parentProps.index}
-- 	  >
-- 		<PureComponentWrapper
-- 		  extendedState={parentProps.extendedState}
-- 		  internalSnapshot={parentProps.internalSnapshot}
-- 		  data={parentProps.data}
-- 		  arg={parentProps.index}
-- 		  renderer={this.getCellContainerChild}
-- 		/>
-- 	  </CellRendererComponent>
-- 	);
--   };

function FlashList.updateDistanceFromWindow(
	self: FlashListComponent,
	event: LayoutChangeEvent
)
	local newDistanceFromWindow = if toJSBoolean(self.props.horizontal)
		then event.nativeEvent.layout.x
		else event.nativeEvent.layout.y

	if self.distanceFromWindow ~= newDistanceFromWindow then
		self.distanceFromWindow = newDistanceFromWindow
		self.windowCorrectionConfig.value.windowShift = -self.distanceFromWindow
		self.viewabilityManager:updateViewableItems()
	end
end

function FlashList.getTransform(self: FlashListComponent)
	local transformStyle = if toJSBoolean(self.props.horizontal)
		then self.transformStyleHorizontal
		else self.transformStyle

	return toJSBoolean(self.props.inverted) and transformStyle or nil
end

-- private separator = (index: number) => {
-- 	// Make sure we have data and don't read out of bounds
-- 	if (
-- 	  this.props.data === null ||
-- 	  this.props.data === undefined ||
-- 	  index + 1 >= this.props.data.length
-- 	) {
-- 	  return null;
-- 	}

-- 	const leadingItem = this.props.data[index];
-- 	const trailingItem = this.props.data[index + 1];

-- 	const props = {
-- 	  leadingItem,
-- 	  trailingItem,
-- 	  // TODO: Missing sections as we don't have this feature implemented yet. Implement section, leadingSection and trailingSection.
-- 	  // https://github.com/facebook/react-native/blob/8bd3edec88148d0ab1f225d2119435681fbbba33/Libraries/Lists/VirtualizedSectionList.js#L285-L294
-- 	};
-- 	const Separator = this.props.ItemSeparatorComponent;
-- 	return Separator && <Separator {...props} />;
--   };

--   private header = () => {
-- 	return (
-- 	  <>
-- 		<View
-- 		  style={{
-- 			paddingTop: this.contentStyle.paddingTop,
-- 			paddingLeft: this.contentStyle.paddingLeft,
-- 		  }}
-- 		/>

-- 		<View
-- 		  style={[this.props.ListHeaderComponentStyle, this.getTransform()]}
-- 		>
-- 		  {this.getValidComponent(this.props.ListHeaderComponent)}
-- 		</View>
-- 	  </>
-- 	);
--   };

--   private footer = () => {
-- 	/** The web version of CellContainer uses a div directly which doesn't compose styles the way a View does.
-- 	 * We will skip using CellContainer on web to avoid this issue. `getFooterContainer` on web will
-- 	 * return a View. */
-- 	const FooterContainer = getFooterContainer() ?? CellContainer;
-- 	return (
-- 	  <>
-- 		<FooterContainer
-- 		  index={-1}
-- 		  style={[this.props.ListFooterComponentStyle, this.getTransform()]}
-- 		>
-- 		  {this.getValidComponent(this.props.ListFooterComponent)}
-- 		</FooterContainer>
-- 		<View
-- 		  style={{
-- 			paddingBottom: this.contentStyle.paddingBottom,
-- 			paddingRight: this.contentStyle.paddingRight,
-- 		  }}
-- 		/>
-- 	  </>
-- 	);
--   };

--   private getComponentForHeightMeasurement = () => {
-- 	return this.props.horizontal &&
-- 	  !this.props.disableHorizontalListHeightMeasurement &&
-- 	  !this.isListLoaded &&
-- 	  this.state.dataProvider.getSize() > 0 ? (
-- 	  <View style={{ opacity: 0 }} pointerEvents="none">
-- 		{this.rowRendererWithIndex(
-- 		  Math.min(this.state.dataProvider.getSize() - 1, 1),
-- 		  RenderTargetOptions.Measurement
-- 		)}
-- 	  </View>
-- 	) : null;
--   };

--   private getValidComponent(
-- 	component: React.ComponentType | React.ReactElement | null | undefined
--   ) {
-- 	const PassedComponent = component;
-- 	return (
-- 	  (React.isValidElement(PassedComponent) && PassedComponent) ||
-- 	  (PassedComponent && <PassedComponent />) ||
-- 	  null
-- 	);
--   }

function FlashList.applyWindowCorrection(
	self: FlashListComponent,
	_,
	_,
	correctionObject: { windowShift: number }
)
	correctionObject.windowShift = -self.distanceFromWindow

	if typeof(self.stickyContainerRef) == "table" then
		self.stickyContentContainerRef:setEnabled(self.isStickyEnabled)
	end
end

function FlashList.rowRendererSticky(self: FlashListComponent, index: number)
	return self:rowRendererWithIndex(
		index,
		FlashListProps.RenderTargetOptions.StickyHeader
	)
end

function FlashList.rowRendererWithIndex(
	self: FlashListComponent,
	index: number,
	target: RenderTarget
)
	if self.props.renderItem ~= nil then
		return self.props.renderItem({
			extraData = if typeof(self.props.extraData) == "table"
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
function FlashList.emptyRowRenderer(self: FlashListComponent)
	return nil
end

-- private getCellContainerChild = (index: number) => {
--     return (
--       <>
--         {this.props.inverted ? this.separator(index) : null}
--         <View
--           style={{
--             flexDirection:
--               this.props.horizontal || this.props.numColumns === 1
--                 ? "column"
--                 : "row",
--           }}
--         >
--           {this.rowRendererWithIndex(index, RenderTargetOptions.Cell)}
--         </View>
--         {this.props.inverted ? null : this.separator(index)}
--       </>
--     );
--   };

function FlashList.recyclerRef(self: FlashListComponent, ref: any)
	self.rlvRef = ref
end

function FlashList.stickyContentRef(self: FlashListComponent, ref: any)
	self.stickyContentContainerRef = ref
end

-- private stickyOverrideRowRenderer = (
--     _: any,
--     __: any,
--     index: number,
--     ___: any
--   ) => {
--     return (
--       <PureComponentWrapper
--         ref={this.stickyContentRef}
--         enabled={this.isStickyEnabled}
--         arg={index}
--         renderer={this.rowRendererSticky}
--       />
--     );
--   };

function FlashList.isStickyEnabled(self: FlashListComponent)
	local currentOffset = if typeof(self.rlvRef) == "table"
		then self.rlvRef:getCurrentScrollOffset()
		else 0

	return currentOffset >= self.distanceFromWindow
end

function FlashList.onItemLayout(self: FlashListComponent, index: number)
	self.state.layoutProvider:reportItemLayout(index)
	self:raiseOnLoadEventIfNeeded()
end

function FlashList.raiseOnLoadEventIfNeeded(self: FlashListComponent)
	if not toJSBoolean(self.isListLoaded) then
		self.isListLoaded = true

		if self.props.onLoad ~= nil then
			self.props.onLoad({
				elapsedTimeInMs = os.clock() - self.loadStartTime,
			})
		end

		self:runAfterOnLoad()
	end
end

function FlashList.runAfterOnLoad(self: FlashListComponent)
	if self.props.estimatedItemSize == nil then
		self.itemSizeWarningTimeoutId = setTimeout(function()
			local averageItemSize = math.floor(self.state.layoutProvider.averageItemSize)

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
		if toJSBoolean(self.props.horizontal) then
			self:forceUpdate()
		end
	end, 500)
end

function FlashList.clearPostLoadTimeout(self: FlashListComponent)
	if self.postLoadTimeoutId ~= nil then
		clearTimeout(self.postLoadTimeoutId)
		self.postLoadTimeoutId = nil
	end
end

function FlashList.clearRenderSizeWarningTimeout(self: FlashListComponent)
	if self.renderSizeWarningTimeoutId ~= nil then
		clearTimeout(self.renderSizeWarningTimeoutId)
		self.renderSizeWarningTimeoutId = nil
	end
end

-- Disables recycling for the next frame so that layout animations run well.
-- Warning: Avoid this when making large changes to the data as the list might draw too much to run animations. Single item insertions/deletions
-- should be good. With recycling paused the list cannot do much optimization.
-- The next render will run as normal and reuse items.
function FlashList.prepareForLayoutAnimationRender(self: FlashListComponent)
	if self.props.keyExtractor == nil then
		console.warn(Warnings.missingKeyExtractor)
	else
		if typeof(self.rlvRef) == "table" then
			self.rlvRef:prepareForLayoutAnimationRender()
		end
	end
end

function FlashList.scrollToEnd(self: FlashListComponent, params: { animated: boolean? }?)
	if typeof(self.rlvRef) == "table" then
		local animated = false
		if typeof(params) == "table" and params.animated ~= nil then
			animated = params.animated
		end

		self.rlvRef:scrollToEnd(animated)
	end
end

function FlashList.scrollToIndex(
	self: FlashListComponent,
	params: {
		animated: boolean?,
		index: number,
		viewOffset: number?,
		viewPosition: number?,
	}
)
	local layout = nil
	local listSize = nil

	if typeof(self.rlvRef) == "table" then
		layout = self.rlvRef:getLayout(params.index)
		listSize = self.rlvRef:getRenderedSize()
	end

	if toJSBoolean(layout) and toJSBoolean(listSize) then
		local horizontal = toJSBoolean(self.props.horizontal)
		local itemOffset = horizontal and layout.x or layout.y
		local fixedDimension = horizontal and listSize.width or listSize.height
		local itemSize = horizontal and layout.width or layout.height

		local scrollOffset = math.max(0, 0)
	end
end

function FlashList.getDerivedStateFromProps(
	nextProps: FlashListProps<unknown>,
	prevState: FlashListState<unknown>
): FlashListState<unknown>
	local newState = Object.assign({}, prevState)

	if prevState.numColumns ~= nextProps.numColumns then
		newState.numColumns = if toJSBoolean(nextProps.numColumns)
			then nextProps.numColumns
			else 1
		newState.layoutProvider =
			FlashList.getLayoutProvider(newState.numColumns, nextProps)
	elseif toJSBoolean(prevState.layoutProvider:updateProps(nextProps).hasExpired) then
		newState.layoutProvider =
			FlashList.getLayoutProvider(newState.numColumns, nextProps)
	end

	-- RLV retries to reposition the first visible item on layout provider change.
	-- It's not required in our case so we're disabling it.
	newState.layoutProvider.shouldRefreshWithAnchoring = not toJSBoolean(
		if typeof(prevState.layoutProvider) == "table"
			then prevState.layoutProvider.hasExpired
			else nil
	)

	if nextProps.data ~= prevState.data then
		newState.data = nextProps.data
		newState.dataProvider = prevState.dataProvider.cloneWithRows(nextProps.data)

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

function FlashList.getInitialMutableState(
	flashList: FlashListComponent
): FlashListState<unknown>
	-- local getStableId: ((index: number) -> string)?

	-- if flashList.props.keyExtractor ~= nil then
	-- 	getStableId = function(index)
	-- 		return tostring(
	-- 			flashList.props.keyExtractor((flashList.props.data :: any)[index], index)
	-- 		)
	-- 	end
	-- end

	return {
		data = nil,
		layoutProvider = nil :: any,
		-- dataProvider = DataProvider.new(function(r1, r2)
		-- 	return r1 ~= r2
		-- end, getStableId),
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

		return toJSBoolean(type) and type or 0
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

		local ref = if typeof(mutableLayout) == "table" then mutableLayout.span else nil
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

		return if typeof(mutableLayout) == "table" then mutableLayout.span else nil
	end, flashListProps)
end

return FlashList
