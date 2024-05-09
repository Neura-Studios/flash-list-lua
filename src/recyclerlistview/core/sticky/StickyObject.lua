-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/sticky/StickyObject.tsx

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local console = LuauPolyfill.console
local Object = LuauPolyfill.Object
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object
type Error = LuauPolyfill.Error

local exports = {}

--[[
	Created by ananya.chandra on 20/09/18.
]]

local React = require("@pkg/@jsdotlua/react")

local LayoutManager = require("../layoutmanager/LayoutManager")
type Layout = LayoutManager.Layout
local LayoutProvider = require("../dependencies/LayoutProvider")
type Dimension = LayoutProvider.Dimension
local RecyclerListViewExceptions = require("../exceptions/RecyclerListViewExceptions")
local CustomError = require("../exceptions/CustomError")
local ViewabilityTracker = require("../ViewabilityTracker")
type WindowCorrection = ViewabilityTracker.WindowCorrection
local BinarySearch = require("../../utils/BinarySearch")

local StickyType = table.freeze({ HEADER = 0, FOOTER = 1 })
export type StickyType = number
exports.StickyType = StickyType

export type StickyObjectProps = {
	stickyIndices: Array<number> | nil,
	getLayoutForIndex: (index: number) -> Layout | nil,
	getDataForIndex: (index: number) -> any,
	getLayoutTypeForIndex: (index: number) -> string | number,
	getExtendedState: () -> Object | Array<unknown> | nil,
	getRLVRenderedSize: () -> Dimension | nil,
	getContentDimension: () -> Dimension | nil,
	getRowRenderer: (
	) -> (
		type_: any,
		data: any,
		index: number,
		extendedState: (Object | Array<unknown>)?
	) -> React.Node,
	overrideRowRenderer: ((
		type_: any,
		data: any,
		index: number,
		extendedState: (Object | Array<unknown>)?
	) -> React.Node)?,
	renderContainer: ((
		rowContent: React.Node,
		index: number,
		extendState: (Object | Array<unknown>)?
	) -> React.Node | nil)?,
	getWindowCorrection: (() -> WindowCorrection)?,

	objectType: "header" | "footer",
}

export type StickyObject = {
	-- NOTE: We have to inline the React component types here to make Luau happy. I am sad.
	props: StickyObjectProps,
	state: {},

	setState: (
		self: StickyObject,
		partialState: {} | (({}, StickyObjectProps) -> {}?),
		callback: (() -> ())?
	) -> (),

	forceUpdate: (self: StickyObject, callback: (() -> ())?) -> (),

	init: ((self: StickyObject, props: StickyObjectProps, context: any?) -> ())?,
	render: (self: StickyObject) -> React.Node,
	componentWillMount: ((self: StickyObject) -> ())?,
	UNSAFE_componentWillMount: ((self: StickyObject) -> ())?,
	componentDidMount: ((self: StickyObject) -> ())?,
	componentWillReceiveProps: ((
		self: StickyObject,
		nextProps: StickyObjectProps,
		nextContext: any
	) -> ())?,
	UNSAFE_componentWillReceiveProps: ((
		self: StickyObject,
		nextProps: StickyObjectProps,
		nextContext: any
	) -> ())?,
	shouldComponentUpdate: ((
		self: StickyObject,
		nextProps: StickyObjectProps,
		nextState: StickyObjectProps,
		nextContext: any
	) -> boolean)?,
	componentWillUpdate: ((
		self: StickyObject,
		nextProps: StickyObjectProps,
		nextState: StickyObjectProps,
		nextContext: any
	) -> ())?,
	UNSAFE_componentWillUpdate: ((
		self: StickyObject,
		nextProps: StickyObjectProps,
		nextState: StickyObjectProps,
		nextContext: any
	) -> ())?,
	componentDidUpdate: ((
		self: StickyObject,
		prevProps: StickyObjectProps,
		prevState: StickyObjectProps,
		prevContext: any
	) -> ())?,
	componentWillUnmount: ((self: StickyObject) -> ())?,
	componentDidCatch: ((
		self: StickyObject,
		error: Error,
		info: {
			componentStack: string,
		}
	) -> ())?,
	getDerivedStateFromProps: ((props: StickyObjectProps, state: {}) -> {}?)?,
	getDerivedStateFromError: ((error: Error) -> {}?)?,
	getSnapshotBeforeUpdate: ((props: StickyObjectProps, state: {}) -> any)?,

	defaultProps: StickyObjectProps?,

	--
	-- *** PUBLIC ***
	--
	onVisibleIndicesChanged: (self: StickyObject, all: Array<number>) -> (),
	onScroll: (self: StickyObject, offsetY: number) -> (),

	--
	-- *** PROTECTED ***
	--
	stickyType: StickyType,
	stickyTypeMultiplier: number,
	stickyVisibility: boolean,
	containerPosition: { top: number?, bottom: number? },
	currentIndex: number,
	currentStickyIndex: number,
	visibleIndices: Array<number>,
	bounceScrolling: boolean,
	hasReachedBoundary: (
		self: StickyObject,
		offsetY: number,
		windowBound: number?
	) -> boolean,
	initStickyParams: (self: StickyObject) -> (),
	calculateVisibleStickyIndex: (
		self: StickyObject,
		stickyIndices: Array<number> | nil,
		smallestVisibleIndex: number,
		largestVisibleIndex: number,
		offsetY: number,
		windowBound: number?
	) -> (),
	getNextYd: (self: StickyObject, _nextY: number, nextHeight: number) -> number,
	getCurrentYd: (
		self: StickyObject,
		currentY: number,
		currentHeight: number
	) -> number,
	getScrollY: (
		self: StickyObject,
		offsetY: number,
		scrollableHeight: number?
	) -> number | nil,
	stickyViewVisible: (
		self: StickyObject,
		_visible: boolean,
		shouldTriggerRender_: boolean?
	) -> (),
	getWindowCorrection: (
		self: StickyObject,
		props: StickyObjectProps
	) -> WindowCorrection,
	boundaryProcessing: (
		self: StickyObject,
		offsetY: number,
		windowBound: number?
	) -> (),
	--
	-- *** PRIVATE ***
	--
	_previousLayout: Layout | nil,
	_previousHeight: number | nil,
	_nextLayout: Layout | nil,
	_nextY: number | nil,
	_nextHeight: number | nil,
	_currentLayout: Layout | nil,
	_currentY: number | nil,
	_currentHeight: number | nil,
	_nextYd: number | nil,
	_currentYd: number | nil,
	_scrollableHeight: number | nil,
	_scrollableWidth: number | nil,
	_windowBound: number | nil,
	_stickyViewOffset: number,
	_previousStickyIndex: number,
	_nextStickyIndex: number,
	_firstCompute: boolean,
	_smallestVisibleIndex: number,
	_largestVisibleIndex: number,
	_offsetY: number,
	_windowCorrection: WindowCorrection,
	_updateDimensionParams: (self: StickyObject) -> (),
	_computeLayouts: (self: StickyObject, newStickyIndices: Array<number>?) -> (),
	_setSmallestAndLargestVisibleIndices: (
		self: StickyObject,
		indicesArray: Array<number>
	) -> (),
	_renderSticky: (self: StickyObject) -> React.Node,
	_getAdjustedOffsetY: (self: StickyObject, offsetY: number) -> number,
}

local StickyObject: StickyObject = React.Component:extend("StickyObject") :: any

function StickyObject:init(props)
	self.stickyType = StickyType.HEADER
	self.stickyTypeMultiplier = 1
	self.stickyVisibility = false
	self.containerPosition = {}
	self.currentIndex = 1
	self.currentStickyIndex = 1
	self.visibleIndices = {}
	self.bounceScrolling = false
	self._stickyViewOffset = 0
	self._previousStickyIndex = 1
	self._nextStickyIndex = 0
	self._firstCompute = true
	self._smallestVisibleIndex = 1
	self._largestVisibleIndex = 1
	self._offsetY = 0
	self._windowCorrection = { startCorrection = 0, endCorrection = 0, windowShift = 0 }
end

function StickyObject:componentDidUpdate(): ()
	self:_updateDimensionParams()
	self:calculateVisibleStickyIndex(
		self.props.stickyIndices,
		self._smallestVisibleIndex,
		self._largestVisibleIndex,
		self._offsetY,
		self._windowBound
	)
	self:_computeLayouts(self.props.stickyIndices)
	self:stickyViewVisible(self.stickyVisibility, false)
end

function StickyObject:render(): React.Node
	local noRenderContainerProps = Object.assign({
		Size = UDim2.new(1, 0, 0, self._scrollableHeight or 0),
	})

	local verticalOffset = self._stickyViewOffset
	if self.props.renderContainer then
		verticalOffset += self.containerPosition.top or 0
	end

	local contentProps = Object.assign({
		Position = UDim2.fromOffset(0, verticalOffset),
		BackgroundTransparency = 1,
		-- The higher the index of the object, the higher the ZIndex.
		ZIndex = self.currentStickyIndex,
	}, if not self.props.renderContainer then noRenderContainerProps else {})

	local content = React.createElement(
		"Frame",
		contentProps,
		if self.stickyVisibility then self:_renderSticky() else nil
	)

	if self.props.renderContainer then
		local _extendedState = self.props.getExtendedState()
		return self.props.renderContainer(
			content,
			self.currentStickyIndex,
			_extendedState
		)
	else
		return content
	end
end

function StickyObject:onVisibleIndicesChanged(all: Array<number>): ()
	if self._firstCompute then
		self:initStickyParams()
		self._offsetY = self:_getAdjustedOffsetY(self._offsetY)
		self._firstCompute = false
	end
	self:_updateDimensionParams()
	self:_setSmallestAndLargestVisibleIndices(all)
	self:calculateVisibleStickyIndex(
		self.props.stickyIndices,
		self._smallestVisibleIndex,
		self._largestVisibleIndex,
		self._offsetY,
		self._windowBound
	)
	self:_computeLayouts()
	self:stickyViewVisible(self.stickyVisibility)
end

function StickyObject:onScroll(offsetY: number): ()
	offsetY = self:_getAdjustedOffsetY(offsetY)
	self._offsetY = offsetY
	self:_updateDimensionParams()
	self:boundaryProcessing(offsetY, self._windowBound)
	if self._previousStickyIndex ~= nil then
		if
			self._previousStickyIndex * self.stickyTypeMultiplier
			>= self.currentStickyIndex * self.stickyTypeMultiplier
		then
			error(CustomError.new(RecyclerListViewExceptions.stickyIndicesArraySortError))
		end

		local scrollY = self:getScrollY(offsetY, self._scrollableHeight)
		if
			self._previousHeight
			and self._currentYd
			and scrollY
			and scrollY < self._currentYd
		then
			if scrollY > self._currentYd - self._previousHeight then
				self.currentIndex -= self.stickyTypeMultiplier
				local translate = (scrollY - self._currentYd + self._previousHeight)
					* (-1 * self.stickyTypeMultiplier)
				self._stickyViewOffset = translate
				self:_computeLayouts()
				self:stickyViewVisible(true)
			end
		else
			self._stickyViewOffset = 0
		end
	end
	if self._nextStickyIndex ~= nil then
		if
			self._nextStickyIndex * self.stickyTypeMultiplier
			<= self.currentStickyIndex * self.stickyTypeMultiplier
		then
			error(CustomError.new(RecyclerListViewExceptions.stickyIndicesArraySortError))
		end

		local scrollY: number | nil = self:getScrollY(offsetY, self._scrollableHeight)
		if
			self._currentHeight
			and self._nextYd
			and scrollY
			and scrollY + self._currentHeight > self._nextYd
		then
			if scrollY <= self._nextYd then
				local translate = (scrollY - self._nextYd + self._currentHeight)
					* (-1 * self.stickyTypeMultiplier)
				self._stickyViewOffset = translate
			elseif scrollY > self._nextYd then
				self.currentIndex += self.stickyTypeMultiplier
				self._stickyViewOffset = 0
				self:_computeLayouts()
				self:stickyViewVisible(true)
			end
		else
			self._stickyViewOffset = 0
		end
	end
end

function StickyObject:hasReachedBoundary(offsetY: number, windowBound: number?): boolean
	-- ROBLOX deviation: We can't support React component inheritance, so we have to inline the methods here.
	if self.props.objectType == "header" then
		return false
	elseif self.props.objectType == "footer" then
		if windowBound ~= nil then
			local endReachedMargin = math.round(offsetY - windowBound)
			return endReachedMargin >= 0
		end
		return false
	else
		error(`Invalid sticky object type: {self.props.objectType}`)
	end
end

function StickyObject:initStickyParams(): ()
	-- ROBLOX deviation: We can't support React component inheritance, so we have to inline the methods here.
	if self.props.objectType == "header" then
		self.stickyType = StickyType.HEADER
		self.stickyTypeMultiplier = 1
		self.containerPosition =
			{ top = self:getWindowCorrection(self.props).startCorrection }
		-- Kept as true contrary to as in StickyFooter because in case of initialOffset not given, onScroll isn't called and boundaryProcessing isn't done.
		-- Default behaviour in that case will be sticky header hidden.
		self.bounceScrolling = true
	elseif self.props.objectType == "footer" then
		self.stickyType = StickyType.FOOTER
		self.stickyTypeMultiplier = -1
		self.containerPosition =
			{ bottom = self:getWindowCorrection(self.props).endCorrection }
		self.bounceScrolling = false
	else
		error(`Invalid sticky object type: {self.props.objectType}`)
	end
end

function StickyObject:calculateVisibleStickyIndex(
	stickyIndices: Array<number> | nil,
	smallestVisibleIndex: number,
	largestVisibleIndex: number,
	offsetY: number,
	windowBound: number?
): ()
	-- ROBLOX deviation: We can't support React component inheritance, so we have to inline the methods here.
	if self.props.objectType == "header" then
		if stickyIndices and smallestVisibleIndex ~= nil then
			self.bounceScrolling = self:hasReachedBoundary(offsetY, windowBound)
			if smallestVisibleIndex < stickyIndices[1] or self.bounceScrolling then
				self.stickyVisibility = false
			else
				self.stickyVisibility = true
				local valueAndIndex = BinarySearch.findValueSmallerThanTarget(
					stickyIndices,
					smallestVisibleIndex
				)
				if valueAndIndex then
					self.currentIndex = valueAndIndex.index
					self.currentStickyIndex = valueAndIndex.value
				else
					console.log("Header sticky index calculation gone wrong.")
				end
			end
		end
	elseif self.props.objectType == "footer" then
		if stickyIndices and largestVisibleIndex ~= 1 then
			self.bounceScrolling = self:hasReachedBoundary(offsetY, windowBound)
			if
				largestVisibleIndex > stickyIndices[#stickyIndices]
				or self.bounceScrolling
			then
				self.stickyVisibility = false
				--This is needed only in when the window is non-scrollable.
				if (self :: any).props.alwaysStickyFooter and offsetY == 0 then
					self.stickyVisibility = true
				end
			else
				self.stickyVisibility = true
				local valueAndIndex = BinarySearch.findValueLargerThanTarget(
					stickyIndices,
					largestVisibleIndex
				)
				if valueAndIndex then
					self.currentIndex = valueAndIndex.index
					self.currentStickyIndex = valueAndIndex.value
				else
					console.log("Footer sticky index calculation gone wrong.")
				end
			end
		end
	else
		error(`Invalid sticky object type: {self.props.objectType}`)
	end
end

function StickyObject:getNextYd(nextY: number, nextHeight: number): number
	-- ROBLOX deviation: We can't support React component inheritance, so we have to inline the methods here.
	if self.props.objectType == "header" then
		return nextY
	elseif self.props.objectType == "footer" then
		return -1 * (nextY + nextHeight)
	else
		error(`Invalid sticky object type: {self.props.objectType}`)
	end
end

function StickyObject:getCurrentYd(currentY: number, currentHeight: number): number
	-- ROBLOX deviation: We can't support React component inheritance, so we have to inline the methods here.
	if self.props.objectType == "header" then
		return currentY
	elseif self.props.objectType == "footer" then
		return -1 * (currentY + currentHeight)
	else
		error(`Invalid sticky object type: {self.props.objectType}`)
	end
end

function StickyObject:getScrollY(offsetY: number, scrollableHeight: number?): number | nil
	-- ROBLOX deviation: We can't support React component inheritance, so we have to inline the methods here.
	if self.props.objectType == "header" then
		return offsetY
	elseif self.props.objectType == "footer" then
		return if scrollableHeight then -1 * (offsetY + scrollableHeight) else nil
	else
		error(`Invalid sticky object type: {self.props.objectType}`)
	end
end

function StickyObject:stickyViewVisible(
	_visible: boolean,
	shouldTriggerRender_: boolean?
): ()
	local shouldTriggerRender = if shouldTriggerRender_ ~= nil
		then shouldTriggerRender_
		else true
	self.stickyVisibility = _visible
	if shouldTriggerRender then
		self:setState({})
	end
end

function StickyObject:getWindowCorrection(props: StickyObjectProps): WindowCorrection
	local ref = if props.getWindowCorrection
		then props.getWindowCorrection()
		else props.getWindowCorrection
	return if ref then ref else self._windowCorrection
end

function StickyObject:boundaryProcessing(offsetY: number, windowBound: number?): ()
	local hasReachedBoundary: boolean = self:hasReachedBoundary(offsetY, windowBound)
	if self.bounceScrolling ~= hasReachedBoundary then
		self.bounceScrolling = hasReachedBoundary
		if self.bounceScrolling then
			self:stickyViewVisible(false)
		else
			self:onVisibleIndicesChanged(self.visibleIndices)
		end
	end
end

function StickyObject:_updateDimensionParams(): ()
	local rlvDimension = self.props.getRLVRenderedSize()
	if rlvDimension then
		self._scrollableHeight = rlvDimension.height
		self._scrollableWidth = rlvDimension.width
	end
	local contentDimension = self.props.getContentDimension()
	if contentDimension and self._scrollableHeight then
		self._windowBound = contentDimension.height - self._scrollableHeight
	end
end

function StickyObject:_computeLayouts(newStickyIndices: Array<number>?): ()
	local stickyIndices: Array<number>? = if newStickyIndices
		then newStickyIndices
		else self.props.stickyIndices
	if stickyIndices then
		self.currentStickyIndex = stickyIndices[self.currentIndex]
		self._previousStickyIndex =
			stickyIndices[self.currentIndex - self.stickyTypeMultiplier]
		self._nextStickyIndex =
			stickyIndices[self.currentIndex + self.stickyTypeMultiplier]

		if self.currentStickyIndex ~= nil then
			self._currentLayout = self.props.getLayoutForIndex(self.currentStickyIndex)
			self._currentY = if self._currentLayout then self._currentLayout.y else nil
			self._currentHeight = if self._currentLayout
				then self._currentLayout.height
				else nil
			self._currentYd = if self._currentY and self._currentHeight
				then self:getCurrentYd(self._currentY, self._currentHeight)
				else nil
		end
		if self._previousStickyIndex ~= nil then
			self._previousLayout = self.props.getLayoutForIndex(self._previousStickyIndex)
			self._previousHeight = if self._previousLayout
				then self._previousLayout.height
				else nil
		end
		if self._nextStickyIndex ~= nil then
			self._nextLayout = self.props.getLayoutForIndex(self._nextStickyIndex)
			self._nextY = if self._nextLayout then self._nextLayout.y else nil
			self._nextHeight = if self._nextLayout then self._nextLayout.height else nil
			self._nextYd = if self._nextY and self._nextHeight
				then self:getNextYd(self._nextY, self._nextHeight)
				else nil
		end
	end
end

function StickyObject:_setSmallestAndLargestVisibleIndices(
	indicesArray: Array<number>
): ()
	self.visibleIndices = indicesArray
	self._smallestVisibleIndex = indicesArray[1]
	self._largestVisibleIndex = indicesArray[#indicesArray]
end

function StickyObject:_renderSticky(): React.Node
	if self.currentStickyIndex ~= nil then
		local _stickyData = self.props.getDataForIndex(self.currentStickyIndex)
		local _stickyLayoutType =
			self.props.getLayoutTypeForIndex(self.currentStickyIndex)
		local _extendedState = self.props.getExtendedState()
		local _rowRenderer = self.props.getRowRenderer()

		if self.props.overrideRowRenderer then
			return self.props.overrideRowRenderer(
				_stickyLayoutType,
				_stickyData,
				self.currentStickyIndex,
				_extendedState
			)
		else
			return _rowRenderer(
				_stickyLayoutType,
				_stickyData,
				self.currentStickyIndex,
				_extendedState
			)
		end
	end

	return nil
end

function StickyObject:_getAdjustedOffsetY(offsetY: number): number
	return offsetY + self:getWindowCorrection(self.props).windowShift
end

exports.default = StickyObject
return exports
