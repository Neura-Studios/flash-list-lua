-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/platform/web/scrollcomponent/ScrollComponent.tsx

--!nolint LocalShadow

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Object = LuauPolyfill.Object
type Error = LuauPolyfill.Error

local React = require("@pkg/@jsdotlua/react")

local LayoutProvider = require("../../../core/dependencies/LayoutProvider")
type Dimension = LayoutProvider.Dimension
local BaseScrollComponent = require("../../../core/scrollcomponent/BaseScrollComponent")
type BaseScrollComponent = BaseScrollComponent.BaseScrollComponent
type ScrollComponentProps = BaseScrollComponent.ScrollComponentProps
local BaseScrollView = require("../../../core/scrollcomponent/BaseScrollView")
type BaseScrollView = BaseScrollView.BaseScrollView
type ScrollEvent = BaseScrollView.ScrollEvent
local ScrollViewer = require("./ScrollViewer")

--[[
    The responsibility of a scroll component is to report its size, scroll events and provide a way to scroll to a given offset.
    RecyclerListView works on top of this interface and doesn't care about the implementation. To support web we only had to provide
    another component written on top of web elements
]]

type Props = ScrollComponentProps & React.ElementProps<any>
type State = {}

export type ScrollComponent = BaseScrollComponent & {
	-- NOTE: We have to inline the React component types here to make Luau happy. I am sad.
	props: Props,
	state: State,

	setState: (
		self: ScrollComponent,
		partialState: State | ((State, Props) -> State?),
		callback: (() -> ())?
	) -> (),

	forceUpdate: (self: ScrollComponent, callback: (() -> ())?) -> (),

	init: (self: ScrollComponent, props: Props, context: any?) -> (),
	render: (self: ScrollComponent) -> React.Node,
	componentWillMount: (self: ScrollComponent) -> (),
	UNSAFE_componentWillMount: (self: ScrollComponent) -> (),
	componentDidMount: (self: ScrollComponent) -> (),
	componentWillReceiveProps: (
		self: ScrollComponent,
		nextProps: Props,
		nextContext: any
	) -> (),
	UNSAFE_componentWillReceiveProps: (
		self: ScrollComponent,
		nextProps: Props,
		nextContext: any
	) -> (),
	shouldComponentUpdate: (
		self: ScrollComponent,
		nextProps: Props,
		nextState: Props,
		nextContext: any
	) -> boolean,
	componentWillUpdate: (
		self: ScrollComponent,
		nextProps: Props,
		nextState: Props,
		nextContext: any
	) -> (),
	UNSAFE_componentWillUpdate: (
		self: ScrollComponent,
		nextProps: Props,
		nextState: Props,
		nextContext: any
	) -> (),
	componentDidUpdate: (
		self: ScrollComponent,
		prevProps: Props,
		prevState: Props,
		prevContext: any
	) -> (),
	componentWillUnmount: (self: ScrollComponent) -> (),
	componentDidCatch: (
		self: ScrollComponent,
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
	scrollTo: (self: ScrollComponent, x: number, y: number, animated: boolean) -> (),
	--
	-- *** PRIVATE ***
	--
	_height: number,
	_width: number,
	_scrollViewRef: BaseScrollView | nil,
	_onScroll: any,
	_onSizeChanged: any,
}

-- ROBLOX deviation: Inheritance isn't supported for React-lua components. We won't extend off the bass component.
local ScrollComponent = React.Component:extend("ScrollComponent") :: ScrollComponent

ScrollComponent.defaultProps = {
	contentHeight = 0,
	contentWidth = 0,
	externalScrollView = ScrollViewer,
	isHorizontal = false,
	scrollThrottle = 16,
	canChangeSize = false,
} :: any

function ScrollComponent:init(props: Props)
	local self = self :: ScrollComponent

	self._scrollViewRef = nil
	self._onScroll = function(e: ScrollEvent)
		props.onScroll(e.nativeEvent.contentOffset.x, e.nativeEvent.contentOffset.y, e)
	end
	self._onSizeChanged = function(event: Dimension)
		if props.onSizeChanged then
			props.onSizeChanged(event)
		end
	end

	self._height = 0
	self._width = 0
end

function ScrollComponent:scrollTo(x: number, y: number, animated: boolean): ()
	local self = self :: ScrollComponent
	if self._scrollViewRef then
		self._scrollViewRef:scrollTo({ x = x, y = y, animated = animated })
	end
end

function ScrollComponent:render()
	local self = self :: ScrollComponent
	local Scroller = self.props.externalScrollView :: any

	local scrollerProps = Object.assign({}, self.props, {
		horizontal = self.props.isHorizontal,
		onScroll = self._onScroll,
		onSizeChanged = self._onSizeChanged,
		ref = function(scrollView: BaseScrollView)
			self._scrollViewRef = scrollView
		end,
	})

	local footerChild = self.props.renderFooter
		and React.createElement("Frame", {
			Position = self.props.isHorizontal
				and UDim2.fromOffset(self.props.contentWidth, 0),
		}, self.props.renderFooter())

	return React.createElement(Scroller, scrollerProps, {
		ChildrenContainer = React.createElement("Frame", {
			Size = UDim2.fromOffset(self.props.contentWidth, self.props.contentHeight),
			BackgroundTransparency = 1,
		}, self.props.children, footerChild),
	})
end

function ScrollComponent:getScrollableNode()
	return nil
end

return ScrollComponent
