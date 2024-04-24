-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/viewability/ViewabilityManager.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Array = LuauPolyfill.Array
local Boolean = LuauPolyfill.Boolean
type Array<T> = LuauPolyfill.Array<T>

local FlashListProps = require("../FlashListProps")
type FlashList<T> = FlashListProps.FlashListComponent

local ViewabilityHelper = require("./ViewabilityHelper")
type ViewabilityHelper = ViewabilityHelper.ViewabilityHelper

local ViewToken = require("./ViewToken")
type ViewToken = ViewToken.ViewToken

-- TODO: Import types from their correct places
type ViewabilityConfig = any

--[[
	Manager for viewability tracking. It holds multiple viewability callback pairs and keeps them updated.
]]

export type ViewabilityManager<T> = {
	flashListRef: FlashList<T>,
	hasInteracted: boolean,
	viewabilityHelpers: Array<ViewabilityHelper>,

	createViewabilityHelper: (
		self: ViewabilityManager<T>,
		viewabilityConfig: ViewabilityConfig?,
		onViewableItemsChanged: (
			info: {
				changed: Array<ViewToken>,
				viewableItems: Array<ViewToken>,
			}
		) -> ()
	) -> ViewabilityHelper,
	dispose: (self: ViewabilityManager<T>) -> (),
	onVisibleIndicesChanged: (self: ViewabilityManager<T>, all: Array<number>) -> (),
	recordInteraction: (self: ViewabilityManager<T>) -> (),
	shouldListenToVisibleIndices: (self: ViewabilityManager<T>) -> boolean,
	updateViewableItems: (
		self: ViewabilityManager<T>,
		newViewableIndices: Array<number>?
	) -> (),
}

local ViewabilityManager = {}
ViewabilityManager.__index = ViewabilityManager

function ViewabilityManager.new<T>(flashListRef: FlashList<T>): ViewabilityManager<T>
	local self = setmetatable({}, ViewabilityManager)

	self.flashListRef = flashListRef
	self.hasInteracted = false
	self.viewabilityHelpers = {}

	if flashListRef.props.onViewableItemsChanged ~= nil then
		table.insert(
			self.viewabilityHelpers,
			(self :: any):createViewabilityHelper(
				flashListRef.props.viewabilityConfig,
				flashListRef.props.onViewableItemsChanged
			)
		)
	end

	if flashListRef.props.viewabilityConfigCallbackPairs ~= nil then
		Array.forEach(flashListRef.props.viewabilityConfigCallbackPairs, function(pair)
			table.insert(
				self.viewabilityHelpers,
				(self :: any):createViewabilityHelper(
					pair.viewabilityConfig,
					pair.onViewableItemsChanged
				)
			)
		end)
	end

	return (self :: any) :: ViewabilityManager<T>
end

function ViewabilityManager.createViewabilityHelper(
	self: ViewabilityManager<unknown>,
	viewabilityConfig: ViewabilityConfig?,
	onViewableItemsChanged: (
		info: {
			changed: Array<ViewToken>,
			viewableItems: Array<ViewToken>,
		}
	) -> ()
): ViewabilityHelper
	local function mapViewToken(index: number, isViewable: boolean): ViewToken
		local item = if typeof(self.flashListRef.props.data) == "table"
			then self.flashListRef.props.data[index]
			else nil
		local key = if item == nil or self.flashListRef.props.keyExtractor == nil
			then tostring(index)
			else self.flashListRef.props:keyExtractor(item, index)

		return {
			index = index,
			isViewable = isViewable,
			item = item,
			key = key,
			timestamp = DateTime.now().UnixTimestampMillis,
		}
	end

	return ViewabilityHelper.new(
		viewabilityConfig,
		function(indices, newlyVisibleIndices, newlyNonvisibleIndices)
			if onViewableItemsChanged ~= nil then
				onViewableItemsChanged({
					changed = Array.concat(
						{},
						unpack(Array.map(newlyVisibleIndices, function(index)
							return mapViewToken(index, true)
						end)),
						unpack(Array.map(newlyNonvisibleIndices, function(index)
							return mapViewToken(index, false)
						end))
					),
					viewableItems = Array.map(indices, function(index)
						return mapViewToken(index, true)
					end),
				})
			end
		end
	)
end

function ViewabilityManager.dispose(self: ViewabilityManager<unknown>): ()
	Array.forEach(self.viewabilityHelpers, function(viewabilityHelper: ViewabilityHelper)
		return viewabilityHelper:dispose()
	end)
end

function ViewabilityManager.onVisibleIndicesChanged(
	self: ViewabilityManager<unknown>,
	all: Array<number>
): ()
	self:updateViewableItems(all)
end

function ViewabilityManager.recordInteraction(self: ViewabilityManager<unknown>): ()
	if Boolean.toJSBoolean(self.hasInteracted) then
		return
	end

	self.hasInteracted = true

	Array.forEach(self.viewabilityHelpers, function(viewabilityHelper: ViewabilityHelper)
		viewabilityHelper.hasInteracted = true
	end)

	self:updateViewableItems()
end

function ViewabilityManager.shouldListenToVisibleIndices(
	self: ViewabilityManager<unknown>
): boolean
	return #self.viewabilityHelpers > 0
end

function ViewabilityManager.updateViewableItems(
	self: ViewabilityManager<unknown>,
	newViewableIndices: Array<number>?
): ()
	local ref = nil
	local listSize = self.flashListRef.props.estimatedListSize
	local scrollOffset = 0

	local recyclerListView = self.flashListRef.recyclerlistview_unsafe

	if typeof(recyclerListView) == "table" then
		local getRenderedSize = recyclerListView.getRenderedSize
		local getCurrentScrollOffset = recyclerListView.getCurrentScrollOffset

		ref = getRenderedSize ~= nil and getRenderedSize() or nil
		listSize = ref ~= nil and ref or listSize
		scrollOffset = (getCurrentScrollOffset ~= nil and getCurrentScrollOffset() or 0)
			- self.flashListRef.firstItemOffset
	end

	if listSize == nil or not Boolean.toJSBoolean(self.shouldListenToVisibleIndices) then
		return
	end

	Array.forEach(self.viewabilityHelpers, function(viewabilityHelper: ViewabilityHelper)
		viewabilityHelper:updateViewableItems(
			self.flashListRef.props.horizontal ~= nil
					and self.flashListRef.props.horizontal
				or false,
			scrollOffset,
			listSize,
			function(index: number)
				local ref = if typeof(recyclerListView) == "table"
					then self.flashListRef.recyclerlistview_unsafe.getLayout
					else nil

				return if ref ~= nil then ref(index) else nil
			end,
			newViewableIndices
		)
	end)
end

return ViewabilityManager
