-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/platform/web/scrollcomponent/ScrollViewer.tsx

--!nolint LocalShadow

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Object = LuauPolyfill.Object
type Error = LuauPolyfill.Error

local React = require("@pkg/@jsdotlua/react")

local BaseScrollView = require("../../../core/scrollcomponent/BaseScrollView")
type BaseScrollView = BaseScrollView.BaseScrollView
type ScrollEvent = BaseScrollView.ScrollEvent
type ScrollViewDefaultProps = BaseScrollView.ScrollViewDefaultProps
local normalizeScrollEvent = require("./normalizeScrollEvent")
type NormalizedScrollEvent = normalizeScrollEvent.NormalizedScrollEvent

--[[
	A scrollviewer that mimics react native scrollview. Additionally on web it can start listening to window scroll events optionally.
	Supports both window scroll and scrollable divs inside other divs.
]]

type Props = ScrollViewDefaultProps & React.ElementProps<any>
type State = {}

export type ScrollViewer = BaseScrollView & {
	-- NOTE: We have to inline the React component types here to make Luau happy. I am sad.
	props: Props,
	state: State,

	setState: (
		self: ScrollViewer,
		partialState: State | ((State, Props) -> State?),
		callback: (() -> ())?
	) -> (),

	forceUpdate: (self: ScrollViewer, callback: (() -> ())?) -> (),

	init: (self: ScrollViewer, props: Props, context: any?) -> (),
	render: (self: ScrollViewer) -> React.Node,
	componentWillMount: (self: ScrollViewer) -> (),
	UNSAFE_componentWillMount: (self: ScrollViewer) -> (),
	componentDidMount: (self: ScrollViewer) -> (),
	componentWillReceiveProps: (
		self: ScrollViewer,
		nextProps: Props,
		nextContext: any
	) -> (),
	UNSAFE_componentWillReceiveProps: (
		self: ScrollViewer,
		nextProps: Props,
		nextContext: any
	) -> (),
	shouldComponentUpdate: (
		self: ScrollViewer,
		nextProps: Props,
		nextState: Props,
		nextContext: any
	) -> boolean,
	componentWillUpdate: (
		self: ScrollViewer,
		nextProps: Props,
		nextState: Props,
		nextContext: any
	) -> (),
	UNSAFE_componentWillUpdate: (
		self: ScrollViewer,
		nextProps: Props,
		nextState: Props,
		nextContext: any
	) -> (),
	componentDidUpdate: (
		self: ScrollViewer,
		prevProps: Props,
		prevState: Props,
		prevContext: any
	) -> (),
	componentWillUnmount: (self: ScrollViewer) -> (),
	componentDidCatch: (
		self: ScrollViewer,
		error: Error,
		info: {
			componentStack: string,
		}
	) -> (),
	getDerivedStateFromProps: (props: Props, state: State) -> State?,
	getDerivedStateFromError: ((error: Error) -> State?)?,
	getSnapshotBeforeUpdate: (props: Props, state: State) -> any,

	defaultProps: Props?,

	--
	-- *** PUBLIC ***
	--
	scrollTo: (
		self: ScrollViewer,
		scrollInput: { x: number, y: number, animated: boolean }
	) -> (),
	--
	-- *** PRIVATE ***
	--
	_mainFrameRef: ScrollingFrame | nil,
	_setFrameRef: any,
	_getRelevantOffset: any,
	_setRelevantOffset: any,
	_doAnimatedScroll: (self: ScrollViewer, offset: number) -> (),
	_onScroll: any,
	_easeInOut: (
		self: ScrollViewer,
		currentTime: number,
		start: number,
		change: number,
		duration: number
	) -> number,
}

-- ROBLOX deviation: Inheritance isn't supported for React-lua components. We won't extend off the bass component.
local ScrollViewer = React.Component:extend("ScrollViewer") :: ScrollViewer

ScrollViewer.defaultProps = {
	canChangeSize = false,
	horizontal = false,
	style = nil,
} :: any

function ScrollViewer:init(props: Props)
	local self = self :: ScrollViewer
	BaseScrollView.init(self, props)
	self._mainFrameRef = nil

	self._setFrameRef = function(frame: ScrollingFrame | nil)
		self._mainFrameRef = frame
	end

	self._getRelevantOffset = function(): number
		if self._mainFrameRef then
			if self.props.horizontal then
				return self._mainFrameRef.CanvasPosition.X
			else
				return self._mainFrameRef.CanvasPosition.Y
			end
		end
		return 0
	end

	self._setRelevantOffset = function(offset: number)
		if self._mainFrameRef then
			if self.props.horizontal then
				self._mainFrameRef.CanvasPosition =
					Vector2.new(offset, self._mainFrameRef.CanvasPosition.Y)
			else
				self._mainFrameRef.CanvasPosition =
					Vector2.new(self._mainFrameRef.CanvasPosition.X, offset)
			end
		end
	end

	self._onScroll = function(scrollEvent: ScrollEvent)
		if self.props.onScroll then
			self.props.onScroll(normalizeScrollEvent(self._mainFrameRef).divEvent)
		end
	end
end

function ScrollViewer:componentDidMount(): ()
	local self = self :: ScrollViewer
	if self.props.onSizeChanged and self._mainFrameRef then
		self.props.onSizeChanged({
			height = self._mainFrameRef.AbsoluteSize.Y,
			width = self._mainFrameRef.AbsoluteSize.X,
		})
	end
end

function ScrollViewer:scrollTo(
	scrollInput: { x: number, y: number, animated: boolean }
): ()
	if scrollInput.animated then
		self:_doAnimatedScroll(
			if self.props.horizontal then scrollInput.x else scrollInput.y
		)
	else
		self:_setRelevantOffset(
			if self.props.horizontal then scrollInput.x else scrollInput.y
		)
	end
end

function ScrollViewer:render()
	local self = self :: ScrollViewer
	return React.createElement(
		"ScrollingFrame",
		Object.assign({
			ref = self._setFrameRef,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromScale(1, 1),
			AutomaticCanvasSize = if self.props.horizontal
				then Enum.AutomaticSize.X
				else Enum.AutomaticSize.Y,
			ScrollingDirection = if self.props.horizontal
				then Enum.ScrollingDirection.X
				else Enum.ScrollingDirection.Y,
			ScrollBarThickness = 0,
			ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
			[React.Change.CanvasPosition] = self._onScroll,
			[React.Change.AbsoluteCanvasSize] = function()
				if self.props.onSizeChanged and self._mainFrameRef then
					self.props.onSizeChanged({
						height = self._mainFrameRef.AbsoluteSize.Y,
						width = self._mainFrameRef.AbsoluteSize.X,
					})
				end
			end,
		}, self.props.style),
		self.props.children
	)
end

function ScrollViewer:_doAnimatedScroll(offset: number): ()
	local start = self:_getRelevantOffset()
	if offset > start then
		start = math.max(offset - 800, start)
	else
		start = math.min(offset + 800, start)
	end
	local change = offset - start
	local increment = 20
	local duration = 200
	local function animateScroll(elapsedTime_: number)
		elapsedTime_ += increment
		local position = self:_easeInOut(elapsedTime_, start, change, duration)
		self:_setRelevantOffset(position)
		if elapsedTime_ < duration then
			task.delay(increment / 1000, function()
				return animateScroll(elapsedTime_)
			end)
		end
	end
	animateScroll(0)
end

function ScrollViewer:_easeInOut(
	currentTime: number,
	start: number,
	change: number,
	duration: number
): number
	currentTime /= duration / 2
	if currentTime < 1 then
		return change / 2 * currentTime * currentTime + start
	end
	currentTime -= 1
	return -change / 2 * (currentTime * (currentTime - 2) - 1) + start
end

return ScrollViewer
