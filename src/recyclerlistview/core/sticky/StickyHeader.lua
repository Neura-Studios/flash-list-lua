-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/sticky/StickyHeader.tsx

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local extends = LuauPolyfill.extends
local console = LuauPolyfill.console
type Array<T> = LuauPolyfill.Array<T>

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

export type StickyHeader =
	StickyObject
	& { onScroll: (self: StickyHeader, offsetY: number) -> () }

type StickyHeader_private = StickyObject & {
	--
	-- *** PUBLIC ***
	--
	onScroll: (self: StickyHeader_private, offsetY: number) -> (),
	--
	-- *** PROTECTED ***
	--
	initStickyParams: (self: StickyHeader_private) -> (),
	calculateVisibleStickyIndex: (
		self: StickyHeader_private,
		stickyIndices: Array<number> | nil,
		smallestVisibleIndex: number,
		largestVisibleIndex: number,
		offsetY: number,
		windowBound: number?
	) -> (),
	getNextYd: (self: StickyHeader_private, nextY: number, nextHeight: number) -> number,
	getCurrentYd: (
		self: StickyHeader_private,
		currentY: number,
		currentHeight: number
	) -> number,
	getScrollY: (
		self: StickyHeader_private,
		offsetY: number,
		scrollableHeight: number
	) -> number | nil,
	hasReachedBoundary: (
		self: StickyHeader_private,
		offsetY: number,
		_windowBound: number?
	) -> boolean,
}
type StickyHeader_statics = {
	new: (props: StickyObjectProps, context: any?) -> StickyHeader,
}

local noop = function() end
local StickyHeader =
	extends(StickyObject, "StickyHeader", noop) :: StickyHeader_private & StickyHeader_statics

function StickyHeader:onScroll(offsetY: number)
	local startCorrection = self:getWindowCorrection(self.props).startCorrection
	if startCorrection and startCorrection ~= 0 then
		self.containerPosition = { top = startCorrection }
		offsetY += startCorrection
	end

	StickyObject.onScroll(self, offsetY)
end

function StickyHeader:initStickyParams(): ()
	self.stickyType = StickyType.HEADER
	self.stickyTypeMultiplier = 1
	self.containerPosition =
		{ top = self:getWindowCorrection(self.props).startCorrection }
	-- Kept as true contrary to as in StickyFooter because in case of initialOffset not given, onScroll isn't called and boundaryProcessing isn't done.
	-- Default behaviour in that case will be sticky header hidden.
	self.bounceScrolling = true
end

function StickyHeader:calculateVisibleStickyIndex(
	stickyIndices: Array<number> | nil,
	smallestVisibleIndex: number,
	largestVisibleIndex: number,
	offsetY: number,
	windowBound: number?
): ()
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
end

function StickyHeader:getNextYd(nextY: number, nextHeight: number?): number
	return nextY
end

function StickyHeader:getCurrentYd(currentY: number, currentHeight: number?): number
	return currentY
end

function StickyHeader:getScrollY(offsetY: number, scrollableHeight: number?): number | nil
	return offsetY
end

function StickyHeader:hasReachedBoundary(offsetY: number, _windowBound: number?): boolean
	--TODO (Swapnil) Refer to talha and understand what needs to be done.
	return false
end

return (StickyHeader :: any) :: React.FC<StickyObjectProps>
