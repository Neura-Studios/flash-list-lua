-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/sticky/StickyFooter.tsx

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local extends = LuauPolyfill.extends
local console = LuauPolyfill.console
type Array<T> = LuauPolyfill.Array<T>
type Error = LuauPolyfill.Error

--[[
	Created by ananya.chandra on 20/09/18.
]]

local React = require("@pkg/@jsdotlua/react")

local stickyObjectModule = require("./StickyObject")
local StickyObject = stickyObjectModule.default
type StickyObject = stickyObjectModule.StickyObject
type StickyObjectProps = stickyObjectModule.StickyObjectProps
local StickyType = stickyObjectModule.StickyType
local BinarySearch = require("../../utils/BinarySearch")
type ValueAndIndex = BinarySearch.ValueAndIndex
local ViewabilityTracker = require("../ViewabilityTracker")
type WindowCorrection = ViewabilityTracker.WindowCorrection

export type StickyFooterProps = StickyObjectProps & { alwaysStickyFooter: boolean? }

export type StickyFooter =
	StickyObject
	& { onScroll: (self: StickyFooter, offsetY: number) -> () }

type StickyFooter_private = StickyObject & {
	-- NOTE: We have to inline the React component types here to make Luau happy. I am sad.
	props: StickyFooterProps,
	state: {},

	setState: (
		self: StickyObject,
		partialState: {} | (({}, StickyFooterProps) -> {}?),
		callback: (() -> ())?
	) -> (),

	forceUpdate: (self: StickyObject, callback: (() -> ())?) -> (),

	init: ((self: StickyObject, props: StickyFooterProps, context: any?) -> ())?,
	render: (self: StickyObject) -> React.Node,
	componentWillMount: ((self: StickyObject) -> ())?,
	UNSAFE_componentWillMount: ((self: StickyObject) -> ())?,
	componentDidMount: ((self: StickyObject) -> ())?,
	componentWillReceiveProps: ((
		self: StickyObject,
		nextProps: StickyFooterProps,
		nextContext: any
	) -> ())?,
	UNSAFE_componentWillReceiveProps: ((
		self: StickyObject,
		nextProps: StickyFooterProps,
		nextContext: any
	) -> ())?,
	shouldComponentUpdate: ((
		self: StickyObject,
		nextProps: StickyFooterProps,
		nextState: StickyFooterProps,
		nextContext: any
	) -> boolean)?,
	componentWillUpdate: ((
		self: StickyObject,
		nextProps: StickyFooterProps,
		nextState: StickyFooterProps,
		nextContext: any
	) -> ())?,
	UNSAFE_componentWillUpdate: ((
		self: StickyObject,
		nextProps: StickyFooterProps,
		nextState: StickyFooterProps,
		nextContext: any
	) -> ())?,
	componentDidUpdate: ((
		self: StickyObject,
		prevProps: StickyFooterProps,
		prevState: StickyFooterProps,
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
	getDerivedStateFromProps: ((props: StickyFooterProps, state: {}) -> {}?)?,
	getDerivedStateFromError: ((error: Error) -> {}?)?,
	getSnapshotBeforeUpdate: ((props: StickyFooterProps, state: {}) -> any)?,

	defaultProps: StickyFooterProps?,

	--
	-- *** PUBLIC ***
	--
	onScroll: (self: StickyFooter_private, offsetY: number) -> (),
	--
	-- *** PROTECTED ***
	--
	initStickyParams: (self: StickyFooter_private) -> (),
	calculateVisibleStickyIndex: (
		self: StickyFooter_private,
		stickyIndices: Array<number> | nil,
		_smallestVisibleIndex: number,
		largestVisibleIndex: number,
		offsetY: number,
		windowBound: number?
	) -> (),
	getNextYd: (self: StickyFooter_private, nextY: number, nextHeight: number) -> number,
	getCurrentYd: (
		self: StickyFooter_private,
		currentY: number,
		currentHeight: number
	) -> number,
	getScrollY: (
		self: StickyFooter_private,
		offsetY: number,
		scrollableHeight: number
	) -> number | nil,
	hasReachedBoundary: (
		self: StickyFooter_private,
		offsetY: number,
		windowBound: number?
	) -> boolean,
}
type StickyFooter_statics = { new: <P>(props: P, context: any?) -> StickyFooter }

local StickyFooter =
	extends(StickyObject, "StickyFooter") :: StickyFooter_private & StickyFooter_statics

function StickyFooter:onScroll(offsetY: number): ()
	local endCorrection = self:getWindowCorrection(self.props).endCorrection
	if endCorrection then
		self.containerPosition = { bottom = endCorrection }
		offsetY -= endCorrection
	end

	StickyObject.onScroll(self, offsetY)
end

function StickyFooter:initStickyParams(): ()
	self.stickyType = StickyType.FOOTER
	self.stickyTypeMultiplier = -1
	self.containerPosition =
		{ bottom = self:getWindowCorrection(self.props).endCorrection }
	self.bounceScrolling = false
end

function StickyFooter:calculateVisibleStickyIndex(
	stickyIndices: Array<number> | nil,
	_smallestVisibleIndex: number,
	largestVisibleIndex: number,
	offsetY: number,
	windowBound: number?
): ()
	if stickyIndices and largestVisibleIndex ~= 1 then
		self.bounceScrolling = self:hasReachedBoundary(offsetY, windowBound)
		if
			largestVisibleIndex > stickyIndices[#stickyIndices] or self.bounceScrolling
		then
			self.stickyVisibility = false
			--This is needed only in when the window is non-scrollable.
			if (self :: any).props.alwaysStickyFooter and offsetY == 0 then
				self.stickyVisibility = true
			end
		else
			self.stickyVisibility = true
			local valueAndIndex =
				BinarySearch.findValueLargerThanTarget(stickyIndices, largestVisibleIndex)
			if valueAndIndex then
				self.currentIndex = valueAndIndex.index
				self.currentStickyIndex = valueAndIndex.value
			else
				console.log("Footer sticky index calculation gone wrong.")
			end
		end
	end
end

function StickyFooter:getNextYd(nextY: number, nextHeight: number): number
	return -1 * (nextY + nextHeight)
end

function StickyFooter:getCurrentYd(currentY: number, currentHeight: number): number
	return -1 * (currentY + currentHeight)
end

function StickyFooter:getScrollY(offsetY: number, scrollableHeight: number?): number | nil
	return if scrollableHeight then -1 * (offsetY + scrollableHeight) else nil
end

function StickyFooter:hasReachedBoundary(offsetY: number, windowBound: number?): boolean
	if windowBound ~= nil then
		local endReachedMargin = math.round(offsetY - windowBound)
		return endReachedMargin >= 0
	end
	return false
end

return StickyFooter
