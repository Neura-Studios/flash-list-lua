-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/platform/web/scrollcomponent/ScrollViewer.tsx
type void = nil --[[ ROBLOX FIXME: adding `void` type alias to make it easier to use Luau `void` equivalent when supported ]]
local Packages --[[ ROBLOX comment: must define Packages module ]]
local LuauPolyfill = require(Packages.LuauPolyfill)
local Boolean = LuauPolyfill.Boolean
local Object = LuauPolyfill.Object
local exports = {}
local React = require(Packages.react)
local baseScrollViewModule =
	require(script.Parent.Parent.Parent.Parent.core.scrollcomponent.BaseScrollView)
local BaseScrollView = baseScrollViewModule.default
local ScrollEvent = baseScrollViewModule.ScrollEvent
local ScrollViewDefaultProps = baseScrollViewModule.ScrollViewDefaultProps
local debounce = require(Packages["lodash.debounce"])
local ScrollEventNormalizer = require(script.Parent.ScrollEventNormalizer).ScrollEventNormalizer
--[[**
 * A scrollviewer that mimics react native scrollview. Additionally on web it can start listening to window scroll events optionally.
 * Supports both window scroll and scrollable divs inside other divs.
 ]]
export type ScrollViewer = BaseScrollView & {
	componentDidMount: (self: ScrollViewer) -> (),
	componentWillUnmount: (self: ScrollViewer) -> (),
	scrollTo: (self: ScrollViewer, scrollInput: { x: number, y: number, animated: boolean }) -> (),
	render: (self: ScrollViewer) -> JSX_Element,
}
type ScrollViewer_private = BaseScrollView & { --
	-- *** PUBLIC ***
	--
	componentDidMount: (self: ScrollViewer_private) -> (),
	componentWillUnmount: (self: ScrollViewer_private) -> (),
	scrollTo: (
		self: ScrollViewer_private,
		scrollInput: { x: number, y: number, animated: boolean }
	) -> (),
	render: (self: ScrollViewer_private) -> JSX_Element,
	--
	-- *** PRIVATE ***
	--
	scrollEndEventSimulator: any,
	_mainDivRef: HTMLDivElement | nil,--[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]]
	_isScrolling: boolean,
	_scrollEventNormalizer: ScrollEventNormalizer | nil,--[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]]
	_setDivRef: any,
	_getRelevantOffset: any,
	_setRelevantOffset: any,
	_isScrollEnd: any,
	_trackScrollOccurence: any,
	_doAnimatedScroll: (self: ScrollViewer_private, offset: number) -> (),
	_startListeningToDivEvents: (self: ScrollViewer_private) -> (),
	_startListeningToWindowEvents: (self: ScrollViewer_private) -> (),
	_onWindowResize: any,
	_windowOnScroll: any,
	_onScroll: any,
	_easeInOut: (
		self: ScrollViewer_private,
		currentTime: number,
		start: number,
		change: number,
		duration: number
	) -> number,
}
type ScrollViewer_statics = { new: () -> ScrollViewer }
local ScrollViewer = (
	setmetatable({}, { __index = BaseScrollView }) :: any
) :: ScrollViewer & ScrollViewer_statics
local ScrollViewer_private = ScrollViewer :: ScrollViewer_private & ScrollViewer_statics;
(ScrollViewer :: any).__index = ScrollViewer
ScrollViewer.defaultProps =
	{ canChangeSize = false, horizontal = false, style = nil, useWindowScroll = false }
function ScrollViewer_private.new(): ScrollViewer
	local self = setmetatable({}, ScrollViewer) --[[ ROBLOX TODO: super constructor may be used ]]
	self.scrollEndEventSimulator = debounce(function(executable: () -> ())
		executable()
	end, 1200)
	self._mainDivRef = nil
	self._isScrolling = false
	self._scrollEventNormalizer = nil
	self._setDivRef = function(
		div: HTMLDivElement | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]]
	): void
		self._mainDivRef = div
		if Boolean.toJSBoolean(div) then
			self._scrollEventNormalizer = ScrollEventNormalizer.new(div)
		else
			self._scrollEventNormalizer = nil
		end
	end
	self._getRelevantOffset = function(): number
		if not Boolean.toJSBoolean(self.props.useWindowScroll) then
			if Boolean.toJSBoolean(self._mainDivRef) then
				if Boolean.toJSBoolean(self.props.horizontal) then
					return self._mainDivRef.scrollLeft
				else
					return self._mainDivRef.scrollTop
				end
			end
			return 0
		else
			if Boolean.toJSBoolean(self.props.horizontal) then
				return window.scrollX
			else
				return window.scrollY
			end
		end
	end
	self._setRelevantOffset = function(offset: number): void
		if not Boolean.toJSBoolean(self.props.useWindowScroll) then
			if Boolean.toJSBoolean(self._mainDivRef) then
				if Boolean.toJSBoolean(self.props.horizontal) then
					self._mainDivRef.scrollLeft = offset
				else
					self._mainDivRef.scrollTop = offset
				end
			end
		else
			if Boolean.toJSBoolean(self.props.horizontal) then
				window:scrollTo(offset, 0)
			else
				window:scrollTo(0, offset)
			end
		end
	end
	self._isScrollEnd = function(): void
		if Boolean.toJSBoolean(self._mainDivRef) then
			self._mainDivRef.style.pointerEvents = "auto"
		end
		self._isScrolling = false
	end
	self._trackScrollOccurence = function(): void
		if not Boolean.toJSBoolean(self._isScrolling) then
			if Boolean.toJSBoolean(self._mainDivRef) then
				self._mainDivRef.style.pointerEvents = "none"
			end
			self._isScrolling = true
		end
		self:scrollEndEventSimulator(self._isScrollEnd)
	end
	self._onWindowResize = function(): void
		if
			Boolean.toJSBoolean(
				if Boolean.toJSBoolean(self.props.onSizeChanged)
					then self.props.useWindowScroll
					else self.props.onSizeChanged
			)
		then
			self.props:onSizeChanged({ height = window.innerHeight, width = window.innerWidth })
		end
	end
	self._windowOnScroll = function(): void
		if Boolean.toJSBoolean(self.props.onScroll) then
			if Boolean.toJSBoolean(self._scrollEventNormalizer) then
				self.props:onScroll(self._scrollEventNormalizer.windowEvent)
			end
		end
	end
	self._onScroll = function(): void
		if Boolean.toJSBoolean(self.props.onScroll) then
			if Boolean.toJSBoolean(self._scrollEventNormalizer) then
				self.props:onScroll(self._scrollEventNormalizer.divEvent)
			end
		end
	end
	return (self :: any) :: ScrollViewer
end
function ScrollViewer_private:componentDidMount(): ()
	if Boolean.toJSBoolean(self.props.onSizeChanged) then
		if Boolean.toJSBoolean(self.props.useWindowScroll) then
			self:_startListeningToWindowEvents()
			self.props:onSizeChanged({ height = window.innerHeight, width = window.innerWidth })
		elseif Boolean.toJSBoolean(self._mainDivRef) then
			self:_startListeningToDivEvents()
			self.props:onSizeChanged({
				height = self._mainDivRef.clientHeight,
				width = self._mainDivRef.clientWidth,
			})
		end
	end
end
function ScrollViewer_private:componentWillUnmount(): ()
	window:removeEventListener("scroll", self._windowOnScroll)
	if Boolean.toJSBoolean(self._mainDivRef) then
		self._mainDivRef:removeEventListener("scroll", self._onScroll)
	end
	window:removeEventListener("resize", self._onWindowResize)
end
function ScrollViewer_private:scrollTo(scrollInput: { x: number, y: number, animated: boolean }): ()
	if Boolean.toJSBoolean(scrollInput.animated) then
		self:_doAnimatedScroll(
			if Boolean.toJSBoolean(self.props.horizontal) then scrollInput.x else scrollInput.y
		)
	else
		self:_setRelevantOffset(
			if Boolean.toJSBoolean(self.props.horizontal) then scrollInput.x else scrollInput.y
		)
	end
end
function ScrollViewer_private:render(): JSX_Element
	return if not Boolean.toJSBoolean(self.props.useWindowScroll)
		then React.createElement("div", {
			ref = self._setDivRef,
			style = Object.assign({}, {
				WebkitOverflowScrolling = "touch",
				height = "100%",
				overflowX = if Boolean.toJSBoolean(self.props.horizontal)
					then "scroll"
					else "hidden",
				overflowY = if not Boolean.toJSBoolean(self.props.horizontal)
					then "scroll"
					else "hidden",
				width = "100%",
			}, self.props.style),
		}, React.createElement("div", { style = { position = "relative" } }, self.props.children))
		else React.createElement("div", {
			ref = self._setDivRef,
			style = Object.assign({}, { position = "relative" }, self.props.style),
		}, self.props.children)
end
function ScrollViewer_private:_doAnimatedScroll(offset: number): ()
	local start = self:_getRelevantOffset()
	if
		offset
		> start --[[ ROBLOX CHECK: operator '>' works only if either both arguments are strings or both are a number ]]
	then
		start = math.max(offset - 800, start)
	else
		start = math.min(offset + 800, start)
	end
	local change = offset - start
	local increment = 20
	local duration = 200
	local function animateScroll(elapsedTime_)
		elapsedTime_ += increment
		local position = self:_easeInOut(elapsedTime_, start, change, duration)
		self:_setRelevantOffset(position)
		if
			elapsedTime_
			< duration --[[ ROBLOX CHECK: operator '<' works only if either both arguments are strings or both are a number ]]
		then
			window:setTimeout(function()
				return animateScroll(elapsedTime_)
			end, increment)
		end
	end
	animateScroll(0)
end
function ScrollViewer_private:_startListeningToDivEvents(): ()
	if Boolean.toJSBoolean(self._mainDivRef) then
		self._mainDivRef:addEventListener("scroll", self._onScroll)
	end
end
function ScrollViewer_private:_startListeningToWindowEvents(): ()
	window:addEventListener("scroll", self._windowOnScroll)
	if Boolean.toJSBoolean(self.props.canChangeSize) then
		window:addEventListener("resize", self._onWindowResize)
	end
end
function ScrollViewer_private:_easeInOut(
	currentTime: number,
	start: number,
	change: number,
	duration: number
): number
	currentTime /= duration / 2
	if
		currentTime
		< 1 --[[ ROBLOX CHECK: operator '<' works only if either both arguments are strings or both are a number ]]
	then
		return change / 2 * currentTime * currentTime + start
	end
	currentTime -= 1
	return -change / 2 * (currentTime * (currentTime - 2) - 1) + start
end
exports.default = ScrollViewer
return exports
