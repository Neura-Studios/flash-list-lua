-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/VirtualRenderer.ts

--!nolint LocalShadow

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local console = LuauPolyfill.console
type Array<T> = LuauPolyfill.Array<T>

local RecycleItemPool = require("../utils/RecycleItemPool")
type RecycleItemPool = RecycleItemPool.RecycleItemPool
local layoutProviderModule = require("./dependencies/LayoutProvider")
type Dimension = layoutProviderModule.Dimension
type BaseLayoutProvider = layoutProviderModule.BaseLayoutProvider
local CustomError = require("./exceptions/CustomError")
local RecyclerListViewExceptions = require("./exceptions/RecyclerListViewExceptions")
local layoutManagerModule = require("./layoutmanager/LayoutManager")
type Point = layoutManagerModule.Point
type LayoutManager = layoutManagerModule.LayoutManager
local ViewabilityTracker = require("./ViewabilityTracker")
type ViewabilityTracker = ViewabilityTracker.ViewabilityTracker
type TOnItemStatusChanged = ViewabilityTracker.TOnItemStatusChanged
type WindowCorrection = ViewabilityTracker.WindowCorrection
local BaseDataProvider = require("./dependencies/DataProvider")
type BaseDataProvider = BaseDataProvider.BaseDataProvider

--[[**
 * Renderer which keeps track of recyclable items and the currently rendered items. Notifies list view to re render if something changes, like scroll offset
 ]]
export type RenderStackItem = { dataIndex: number? }
export type StableIdMapItem = { key: string, type: string | number }
export type RenderStack = { [string]: RenderStackItem }
export type RenderStackParams = {
	isHorizontal: boolean?,
	itemCount: number,
	initialOffset: number?,
	initialRenderIndex: number?,
	renderAheadOffset: number?,
}
export type StableIdProvider = (index: number) -> string
export type VirtualRenderer = {
	getLayoutDimension: (self: VirtualRenderer) -> Dimension,
	setOptimizeForAnimations: (self: VirtualRenderer, shouldOptimize: boolean) -> (),
	hasPendingAnimationOptimization: (self: VirtualRenderer) -> boolean,
	updateOffset: (
		self: VirtualRenderer,
		offsetX: number,
		offsetY: number,
		isActual: boolean,
		correction: WindowCorrection
	) -> (),
	attachVisibleItemsListener: (
		self: VirtualRenderer,
		callback: TOnItemStatusChanged
	) -> (),
	removeVisibleItemsListener: (self: VirtualRenderer) -> (),
	getLayoutManager: (self: VirtualRenderer) -> LayoutManager | nil,
	setParamsAndDimensions: (
		self: VirtualRenderer,
		params: RenderStackParams,
		dim: Dimension
	) -> (),
	setLayoutManager: (self: VirtualRenderer, layoutManager: LayoutManager) -> (),
	setLayoutProvider: (self: VirtualRenderer, layoutProvider: BaseLayoutProvider) -> (),
	getViewabilityTracker: (self: VirtualRenderer) -> ViewabilityTracker | nil,
	refreshWithAnchor: (self: VirtualRenderer) -> (),
	refresh: (self: VirtualRenderer) -> (),
	getInitialOffset: (self: VirtualRenderer) -> Point,
	init: (self: VirtualRenderer) -> (),
	startViewabilityTracker: (
		self: VirtualRenderer,
		windowCorrection: WindowCorrection
	) -> (),
	syncAndGetKey: (
		self: VirtualRenderer,
		index: number,
		overrideStableIdProvider: StableIdProvider?,
		newRenderStack: RenderStack?,
		keyToStableIdMap: { [string]: string }?
	) -> string, --Further optimize in later revision, pretty fast for now considering this is a low frequency event
	handleDataSetChange: (self: VirtualRenderer, newDataProvider: BaseDataProvider) -> (),
}
type VirtualRenderer_private = { --
	-- *** PUBLIC ***
	--
	getLayoutDimension: (self: VirtualRenderer_private) -> Dimension,
	setOptimizeForAnimations: (
		self: VirtualRenderer_private,
		shouldOptimize: boolean
	) -> (),
	hasPendingAnimationOptimization: (self: VirtualRenderer_private) -> boolean,
	updateOffset: (
		self: VirtualRenderer_private,
		offsetX: number,
		offsetY: number,
		isActual: boolean,
		correction: WindowCorrection
	) -> (),
	attachVisibleItemsListener: (
		self: VirtualRenderer_private,
		callback: TOnItemStatusChanged
	) -> (),
	removeVisibleItemsListener: (self: VirtualRenderer_private) -> (),
	getLayoutManager: (self: VirtualRenderer_private) -> LayoutManager | nil,
	setParamsAndDimensions: (
		self: VirtualRenderer_private,
		params: RenderStackParams,
		dim: Dimension
	) -> (),
	setLayoutManager: (self: VirtualRenderer_private, layoutManager: LayoutManager) -> (),
	setLayoutProvider: (
		self: VirtualRenderer_private,
		layoutProvider: BaseLayoutProvider
	) -> (),
	getViewabilityTracker: (self: VirtualRenderer_private) -> ViewabilityTracker | nil,
	refreshWithAnchor: (self: VirtualRenderer_private) -> (),
	refresh: (self: VirtualRenderer_private) -> (),
	getInitialOffset: (self: VirtualRenderer_private) -> Point,
	init: (self: VirtualRenderer_private) -> (),
	startViewabilityTracker: (
		self: VirtualRenderer_private,
		windowCorrection: WindowCorrection
	) -> (),
	syncAndGetKey: (
		self: VirtualRenderer_private,
		index: number,
		overrideStableIdProvider: StableIdProvider?,
		newRenderStack: RenderStack?,
		keyToStableIdMap: { [string]: string }?
	) -> string,
	handleDataSetChange: (
		self: VirtualRenderer_private,
		newDataProvider: BaseDataProvider
	) -> (),
	--
	-- *** PRIVATE ***
	--
	onVisibleItemsChanged: TOnItemStatusChanged | nil,
	_scrollOnNextUpdate: (point: Point) -> (),
	_stableIdToRenderKeyMap: { [string]: StableIdMapItem | nil },
	_engagedIndexes: { [number]: number | nil },
	_renderStack: RenderStack,
	_renderStackChanged: (renderStack: RenderStack) -> (),
	_fetchStableId: StableIdProvider,
	_isRecyclingEnabled: boolean,
	_isViewTrackerRunning: boolean,
	_markDirty: boolean,
	_startKey: number,
	_layoutProvider: BaseLayoutProvider, --TSI
	_recyclePool: RecycleItemPool, --TSI
	_params: RenderStackParams | nil,
	_layoutManager: LayoutManager | nil,
	_viewabilityTracker: ViewabilityTracker | nil,
	_dimensions: Dimension | nil,
	_optimizeForAnimations: boolean,
	_getCollisionAvoidingKey: (self: VirtualRenderer_private) -> string,
	_prepareViewabilityTracker: (self: VirtualRenderer_private) -> (),
	_onVisibleItemsChanged: any,
	_onEngagedItemsChanged: any, --Updates render stack and reports whether anything has changed
	_updateRenderStack: (
		self: VirtualRenderer_private,
		itemIndexes: Array<number>
	) -> boolean,
}
type VirtualRenderer_statics = {
	new: (
		renderStackChanged: (renderStack: RenderStack) -> (),
		scrollOnNextUpdate: (point: Point) -> (),
		fetchStableId: StableIdProvider,
		isRecyclingEnabled: boolean
	) -> VirtualRenderer,
}

local VirtualRenderer = {} :: VirtualRenderer & VirtualRenderer_statics
local VirtualRenderer_private =
	VirtualRenderer :: VirtualRenderer_private & VirtualRenderer_statics;
(VirtualRenderer :: any).__index = VirtualRenderer

function VirtualRenderer_private.new(
	renderStackChanged: (renderStack: RenderStack) -> (),
	scrollOnNextUpdate: (point: Point) -> (),
	fetchStableId: StableIdProvider,
	isRecyclingEnabled: boolean
): VirtualRenderer
	local self = setmetatable({}, VirtualRenderer)
	self._layoutProvider = nil :: BaseLayoutProvider?
	self._recyclePool = nil :: RecycleItemPool?
	self._layoutManager = nil
	self._viewabilityTracker = nil
	self._optimizeForAnimations = false

	self._onVisibleItemsChanged = function(
		all: Array<number>,
		now: Array<number>,
		notNow: Array<number>
	)
		-- TODO: Luau workaround for bug "TypeError: Metatable was not a table"
		local self: typeof(VirtualRenderer_private) = self :: any

		if self.onVisibleItemsChanged then
			self.onVisibleItemsChanged(all, now, notNow)
		end

		return nil
	end

	self._onEngagedItemsChanged = function(
		all: Array<number>,
		now: Array<number>,
		notNow: Array<number>
	)
		-- TODO: Luau workaround for bug "TypeError: Metatable was not a table"
		local self: typeof(VirtualRenderer_private) = self :: any

		local count = #notNow
		local resolvedKey
		local disengagedIndex = 1

		if self._isRecyclingEnabled then
			for i = 1, count do
				disengagedIndex = notNow[i]
				self._engagedIndexes[disengagedIndex] = nil

				if self._params and disengagedIndex <= self._params.itemCount then
					-- All the items which are now not visible can go to the
					-- recycle pool, the pool only needs to maintain keys since
					-- react can link a view to a key automatically
					resolvedKey =
						self._stableIdToRenderKeyMap[self._fetchStableId(disengagedIndex)]
					if resolvedKey ~= nil then
						self._recyclePool:putRecycledObject(
							self._layoutProvider:getLayoutTypeForIndex(disengagedIndex),
							resolvedKey.key
						)
					end
				end
			end
		end

		if self:_updateRenderStack(now) then
			-- Ask Recycler View to update itself
			self._renderStackChanged(self._renderStack)
		end

		return nil
	end

	--Keeps track of items that need to be rendered in the next render cycle
	self._renderStack = {}

	self._fetchStableId = fetchStableId

	--Keeps track of keys of all the currently rendered indexes, can eventually replace renderStack as well if no new use cases come up
	self._stableIdToRenderKeyMap = {}
	self._engagedIndexes = {}
	self._renderStackChanged = renderStackChanged
	self._scrollOnNextUpdate = scrollOnNextUpdate
	self._dimensions = nil
	self._params = nil
	self._isRecyclingEnabled = isRecyclingEnabled

	self._isViewTrackerRunning = false
	self._markDirty = false

	--Would be surprised if someone exceeds this
	self._startKey = 0

	self.onVisibleItemsChanged = nil

	return (self :: any) :: VirtualRenderer
end

function VirtualRenderer_private:getLayoutDimension(): Dimension
	if self._layoutManager then
		return self._layoutManager:getContentDimension()
	end
	return { height = 0, width = 0 }
end

function VirtualRenderer_private:setOptimizeForAnimations(shouldOptimize: boolean): ()
	self._optimizeForAnimations = shouldOptimize
end

function VirtualRenderer_private:hasPendingAnimationOptimization(): boolean
	return self._optimizeForAnimations
end

function VirtualRenderer_private:updateOffset(
	offsetX: number,
	offsetY: number,
	isActual: boolean,
	correction: WindowCorrection
): ()
	if self._viewabilityTracker then
		local offset = if self._params and self._params.isHorizontal
			then offsetX
			else offsetY
		if not self._isViewTrackerRunning then
			if isActual then
				self._viewabilityTracker:setActualOffset(offset)
			end
			self:startViewabilityTracker(correction)
		end
		self._viewabilityTracker:updateOffset(offset, isActual, correction)
	end
end

function VirtualRenderer_private:attachVisibleItemsListener(
	callback: TOnItemStatusChanged
): ()
	self.onVisibleItemsChanged = callback
end

function VirtualRenderer_private:removeVisibleItemsListener(): ()
	self.onVisibleItemsChanged = nil
	if self._viewabilityTracker then
		self._viewabilityTracker.onVisibleRowsChanged = nil
	end
end

function VirtualRenderer_private:getLayoutManager(): LayoutManager | nil
	return self._layoutManager
end

function VirtualRenderer_private:setParamsAndDimensions(
	params: RenderStackParams,
	dim: Dimension
): ()
	self._params = params
	self._dimensions = dim
end

function VirtualRenderer_private:setLayoutManager(layoutManager: LayoutManager): ()
	self._layoutManager = layoutManager
	if self._params then
		layoutManager:relayoutFromIndex(1, self._params.itemCount)
	end
end

function VirtualRenderer_private:setLayoutProvider(layoutProvider: BaseLayoutProvider): ()
	self._layoutProvider = layoutProvider
end

function VirtualRenderer_private:getViewabilityTracker(): ViewabilityTracker | nil
	return self._viewabilityTracker
end

function VirtualRenderer_private:refreshWithAnchor(): ()
	if self._viewabilityTracker then
		local firstVisibleIndex =
			self._viewabilityTracker:findFirstLogicallyVisibleIndex()
		self:_prepareViewabilityTracker()
		local offset = 0
		if self._layoutManager and self._params then
			firstVisibleIndex = math.min(self._params.itemCount, firstVisibleIndex)
			local point = self._layoutManager:getOffsetForIndex(firstVisibleIndex)
			self._scrollOnNextUpdate(point)
			offset = if self._params.isHorizontal then point.x else point.y
		end
		self._viewabilityTracker:forceRefreshWithOffset(offset)
	end
end

function VirtualRenderer_private:refresh(): ()
	if self._viewabilityTracker then
		self:_prepareViewabilityTracker()
		self._viewabilityTracker:forceRefresh()
	end
end

function VirtualRenderer_private:getInitialOffset(): Point
	local offset = { x = 0, y = 0 }
	if self._params then
		local initialRenderIndex = self._params.initialRenderIndex or 0
		if initialRenderIndex > 0 and self._layoutManager then
			offset = self._layoutManager:getOffsetForIndex(initialRenderIndex)
			self._params.initialOffset = if self._params.isHorizontal
				then offset.x
				else offset.y
		else
			if self._params.isHorizontal then
				offset.x = self._params.initialOffset or 0
				offset.y = 0
			else
				offset.y = self._params.initialOffset or 0
				offset.x = 0
			end
		end
	end
	return offset
end

function VirtualRenderer_private:init(): ()
	self:getInitialOffset()
	self._recyclePool = RecycleItemPool.new()
	if self._params then
		self._viewabilityTracker = ViewabilityTracker.new(
			self._params.renderAheadOffset or 0,
			self._params.initialOffset or 0
		)
	else
		self._viewabilityTracker = ViewabilityTracker.new(0, 0)
	end
	self:_prepareViewabilityTracker()
end

function VirtualRenderer_private:startViewabilityTracker(
	windowCorrection: WindowCorrection
): ()
	if self._viewabilityTracker then
		self._isViewTrackerRunning = true
		self._viewabilityTracker:init(windowCorrection)
	end
end

function VirtualRenderer_private:syncAndGetKey(
	index: number,
	overrideStableIdProvider: StableIdProvider?,
	newRenderStack: RenderStack?,
	keyToStableIdMap: { [string]: string }?
): string
	local getStableId = if overrideStableIdProvider
		then overrideStableIdProvider
		else self._fetchStableId
	local renderStack = if newRenderStack then newRenderStack else self._renderStack
	local stableIdItem = self._stableIdToRenderKeyMap[getStableId(index)]
	local key = if stableIdItem then stableIdItem.key else nil

	if key == nil then
		local type_ = self._layoutProvider:getLayoutTypeForIndex(index)
		key = self._recyclePool:getRecycledObject(type_)

		if key ~= nil then
			local itemMeta = renderStack[key]
			if itemMeta then
				local oldIndex = itemMeta.dataIndex
				itemMeta.dataIndex = index
				if oldIndex ~= nil and oldIndex ~= index then
					self._stableIdToRenderKeyMap[getStableId(oldIndex)] = nil
				end
			else
				renderStack[key] = { dataIndex = index }
				if keyToStableIdMap and keyToStableIdMap[key] then
					self._stableIdToRenderKeyMap[keyToStableIdMap[key]] = nil
				end
			end
		else
			key = getStableId(index)
			local key = key :: string
			if renderStack[key] then
				--Probable collision, warn and avoid
				--TODO: Disabled incorrectly triggering in some cases
				--console.warn(`Possible stableId collision @ {index}`)
				key = self:_getCollisionAvoidingKey()
			end
			renderStack[key] = { dataIndex = index }
		end

		local key = key :: string

		self._markDirty = true
		self._stableIdToRenderKeyMap[getStableId(index)] = { key = key, type = type_ }
	end

	local key = key :: string
	if self._engagedIndexes[index] ~= nil then
		self._recyclePool:removeFromPool(key)
	end

	local stackItem = renderStack[key]
	if stackItem and stackItem.dataIndex ~= index then
		--Probable collision, warn
		console.warn("Possible stableId collision @", index)
	end

	return key
end

function VirtualRenderer_private:handleDataSetChange(
	newDataProvider: BaseDataProvider
): ()
	local getStableId = newDataProvider.getStableId
	local maxIndex = newDataProvider:getSize()
	local activeStableIds: { [string]: number } = {}
	local newRenderStack: RenderStack = {}
	local keyToStableIdMap: { [string]: string } = {}

	-- Do not use recycle pool so that elements don't fly top to bottom or vice versa
	-- Doing this is expensive and can draw extra items
	if self._optimizeForAnimations and self._recyclePool then
		self._recyclePool:clearAll()
	end

	--Compute active stable ids and stale active keys and resync render stack
	for key in self._renderStack do
		if self._renderStack[key] ~= nil then
			local index = self._renderStack[key].dataIndex
			if index ~= nil then
				if index <= maxIndex then
					local stableId = getStableId(index)
					activeStableIds[stableId] = 1
				end
			end
		end
	end

	--Clean stable id to key map
	local oldActiveStableIds = Object.keys(self._stableIdToRenderKeyMap)
	for i, key in oldActiveStableIds do
		local stableIdItem = self._stableIdToRenderKeyMap[key]
		if stableIdItem then
			if not activeStableIds[key] then
				if not self._optimizeForAnimations and self._isRecyclingEnabled then
					self._recyclePool:putRecycledObject(
						stableIdItem.type,
						stableIdItem.key
					)
				end
				self._stableIdToRenderKeyMap[key] = nil

				local stackItem = self._renderStack[stableIdItem.key]
				local dataIndex = if stackItem then stackItem.dataIndex else nil
				if dataIndex ~= nil and dataIndex <= maxIndex and self._layoutManager then
					self._layoutManager:removeLayout(dataIndex)
				end
			else
				keyToStableIdMap[stableIdItem.key] = key
			end
		end
	end

	local renderStackKeys = Array.sort(Object.keys(self._renderStack), function(a, b)
		local firstItem = self._renderStack[a]
		local secondItem = self._renderStack[b]
		if firstItem and firstItem.dataIndex and secondItem and secondItem.dataIndex then
			return firstItem.dataIndex - secondItem.dataIndex
		end
		return 1
	end)

	for i, key in renderStackKeys do
		local index = self._renderStack[key].dataIndex
		if index ~= nil then
			if index <= maxIndex then
				local newKey = self:syncAndGetKey(
					index,
					getStableId,
					newRenderStack,
					keyToStableIdMap
				)
				local newStackItem = newRenderStack[newKey]
				if not newStackItem then
					newRenderStack[newKey] = { dataIndex = index }
				elseif newStackItem.dataIndex ~= index then
					local cllKey = self:_getCollisionAvoidingKey()
					newRenderStack[cllKey] = { dataIndex = index }
					self._stableIdToRenderKeyMap[getStableId(index)] = {
						key = cllKey,
						type = self._layoutProvider:getLayoutTypeForIndex(index),
					}
				end
			end
		end
		self._renderStack[key] = nil
	end

	Object.assign(self._renderStack, newRenderStack)

	for key in self._renderStack do
		if self._renderStack[key] ~= nil then
			local index = self._renderStack[key].dataIndex
			if index and not self._engagedIndexes[index] then
				local type_ = self._layoutProvider:getLayoutTypeForIndex(index)
				self._recyclePool:putRecycledObject(type_, key)
			end
		end
	end
end
function VirtualRenderer_private:_getCollisionAvoidingKey(): string
	local str = `#{self._startKey}_rlv_c`
	self._startKey += 1
	return str
end

function VirtualRenderer_private:_prepareViewabilityTracker(): ()
	if
		self._viewabilityTracker
		and self._layoutManager
		and self._dimensions
		and self._params
	then
		self._viewabilityTracker.onEngagedRowsChanged = self._onEngagedItemsChanged
		if self.onVisibleItemsChanged then
			self._viewabilityTracker.onVisibleRowsChanged = self._onVisibleItemsChanged
		end
		self._viewabilityTracker:setLayouts(
			self._layoutManager:getLayouts(),
			if self._params.isHorizontal
				then self._layoutManager:getContentDimension().width
				else self._layoutManager:getContentDimension().height
		)
		self._viewabilityTracker:setDimensions(
			{ height = self._dimensions.height, width = self._dimensions.width },
			if self._params.isHorizontal == nil then false else self._params.isHorizontal
		)
	else
		error(CustomError.new(RecyclerListViewExceptions.initializationException))
	end
end

function VirtualRenderer_private:_updateRenderStack(itemIndexes: Array<number>): boolean
	self._markDirty = false
	local count = #itemIndexes
	local index = 0
	local hasRenderStackChanged = false
	for i = 1, count do
		index = itemIndexes[i]
		self._engagedIndexes[index] = 1
		self:syncAndGetKey(index)
		hasRenderStackChanged = self._markDirty
	end
	self._markDirty = false
	return hasRenderStackChanged
end

return VirtualRenderer
