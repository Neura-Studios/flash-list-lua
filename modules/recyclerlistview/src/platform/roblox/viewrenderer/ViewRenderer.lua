-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/platform/web/viewrenderer/ViewRenderer.tsx

--!nolint LocalShadow

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Object = LuauPolyfill.Object
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object
type Error = LuauPolyfill.Error

local React = require("@pkg/@jsdotlua/react")
local LayoutProvider = require("../../../core/dependencies/LayoutProvider")
type Dimension = LayoutProvider.Dimension
local BaseViewRenderer = require("../../../core/viewrenderer/BaseViewRenderer")
type BaseViewRenderer<T> = BaseViewRenderer.BaseViewRenderer<T>
type ViewRendererProps<T> = BaseViewRenderer.ViewRendererProps<T>

type Props = ViewRendererProps<any>
type State = {}

--[[**
 * View renderer is responsible for creating a container of size provided by LayoutProvider and render content inside it.
 * Also enforces a logic to prevent re renders. RecyclerListView keeps moving these ViewRenderers around using transforms to enable recycling.
 * View renderer will only update if its position, dimensions or given data changes. Make sure to have a relevant shouldComponentUpdate as well.
 * This is second of the two things recycler works on. Implemented both for web and react native.
 ]]
export type ViewRenderer = BaseViewRenderer<any> & {
	-- NOTE: We have to inline the React component types here to make Luau happy. I am sad.
	props: Props,
	state: State,

	setState: (
		self: ViewRenderer,
		partialState: State | ((State, Props) -> State?),
		callback: (() -> ())?
	) -> (),

	forceUpdate: (self: ViewRenderer, callback: (() -> ())?) -> (),

	init: (self: ViewRenderer, props: Props, context: any?) -> (),
	render: (self: ViewRenderer) -> React.Node,
	componentWillMount: (self: ViewRenderer) -> (),
	UNSAFE_componentWillMount: (self: ViewRenderer) -> (),
	componentDidMount: (self: ViewRenderer) -> (),
	componentWillReceiveProps: (
		self: ViewRenderer,
		nextProps: Props,
		nextContext: any
	) -> (),
	UNSAFE_componentWillReceiveProps: (
		self: ViewRenderer,
		nextProps: Props,
		nextContext: any
	) -> (),
	shouldComponentUpdate: (
		self: ViewRenderer,
		nextProps: Props,
		nextState: Props,
		nextContext: any
	) -> boolean,
	componentWillUpdate: (
		self: ViewRenderer,
		nextProps: Props,
		nextState: Props,
		nextContext: any
	) -> (),
	UNSAFE_componentWillUpdate: (
		self: ViewRenderer,
		nextProps: Props,
		nextState: Props,
		nextContext: any
	) -> (),
	componentDidUpdate: (
		self: ViewRenderer,
		prevProps: Props,
		prevState: Props,
		prevContext: any
	) -> (),
	componentWillUnmount: (self: ViewRenderer) -> (),
	componentDidCatch: (
		self: ViewRenderer,
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
	-- *** PROTECTED ***
	--
	getRef: (self: ViewRenderer) -> Frame | nil,
	--
	-- *** PRIVATE ***
	--
	_dim: Dimension,
	_mainFrame: Frame | nil,
	_isPendingSizeUpdate: boolean,
	_renderItemContainer: (
		self: ViewRenderer,
		props: Object | Array<unknown>,
		parentProps: ViewRendererProps<any>,
		children: React.Node
	) -> React.Node,
	_setRef: any,
	_checkSizeChange: (self: ViewRenderer, fromObserver_: boolean?) -> (),
	_onItemRendered: (self: ViewRenderer) -> (),
}

local ViewRenderer = React.Component:extend("ViewRenderer") :: ViewRenderer

function ViewRenderer:init()
	local self = self :: ViewRenderer
	BaseViewRenderer.init(self)

	self._dim = { width = 0, height = 0 }
	self._mainDiv = nil
	self._isPendingSizeUpdate = false
	self._setRef = function(frame: Frame)
		self._mainFrame = frame
	end
end

function ViewRenderer:componentDidMount(): ()
	local self = self :: ViewRenderer

	self.animatorStyleOverrides = nil
	self.props.itemAnimator:animateDidMount(
		self.props.x,
		self.props.y,
		self:getRef(),
		self.props.index
	)

	self:_checkSizeChange()
end

function ViewRenderer:componentDidUpdate(): ()
	local self = self :: ViewRenderer

	self._isPendingSizeUpdate = false
	self:_checkSizeChange()
end

function ViewRenderer:render()
	local self = self :: ViewRenderer

	-- ROBLOX deviation: Upstream uses a lot of flexbox properties. I'm avoiding this for now to keep complexity low.
	-- However, our implementation below might not be correct.
	local styleProps = if self.props.forceNonDeterministicRendering
		then {
			Position = UDim2.fromOffset(self.props.x, self.props.y),
			-- TODO: Is this correct?
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
		}
		else {
			Position = UDim2.fromOffset(self.props.x, self.props.y),
			Size = UDim2.fromOffset(self.props.width, self.props.height),
			ClipsDescendants = true,
			BackgroundTransparency = 1,
		}

	local props = Object.assign(
		{ ref = self._setRef },
		styleProps,
		self.props.styleOverrides,
		self.animatorStyleOverrides
	)

	return self:_renderItemContainer(props, self.props, self:renderChild())
end

function ViewRenderer:getRef(): Frame | nil
	local self = self :: ViewRenderer
	return self._mainFrame
end

function ViewRenderer:_renderItemContainer(
	props: Object | Array<unknown>,
	parentProps: ViewRendererProps<any>,
	children: React.Node
): React.Node
	local self = self :: ViewRenderer

	local renderItemContainer = self.props.renderItemContainer :: ((
		props: Object | Array<unknown>,
		parentProps: ViewRendererProps<any>,
		children: React.Node
	) -> React.Node)?

	local ref = if renderItemContainer ~= nil
		then renderItemContainer(props, parentProps, children)
		else nil
	return if ref then ref else React.createElement("Frame", props, children)
end

function ViewRenderer:_checkSizeChange(fromObserver_: boolean?): ()
	local self = self :: ViewRenderer

	local fromObserver: boolean = if fromObserver_ ~= nil then fromObserver_ else false
	if self.props.forceNonDeterministicRendering and self.props.onSizeChanged then
		local mainFrame = self._mainFrame
		if mainFrame then
			self._dim.width = mainFrame.AbsoluteSize.X
			self._dim.height = mainFrame.AbsoluteSize.Y
			if
				self.props.width ~= self._dim.width
				or self.props.height ~= self._dim.height
			then
				self._isPendingSizeUpdate = true
				self.props.onSizeChanged(self._dim, self.props.index)
			elseif fromObserver and self._isPendingSizeUpdate then
				self.props:onSizeChanged(self._dim, self.props.index)
			end
		end
	end
	self:_onItemRendered()
end

function ViewRenderer:_onItemRendered(): ()
	local self = self :: ViewRenderer
	local onItemLayout = self.props.onItemLayout :: ((number) -> ())?
	if onItemLayout then
		onItemLayout(self.props.index)
	end
end

function ViewRenderer:shouldComponentUpdate(newProps: ViewRendererProps<any>): boolean
	local hasMoved = self.props.x ~= newProps.x or self.props.y ~= newProps.y

	local hasSizeChanged = not newProps.forceNonDeterministicRendering
			and (self.props.width ~= newProps.width or self.props.height ~= newProps.height)
		or self.props.layoutProvider ~= newProps.layoutProvider

	local hasExtendedStateChanged = self.props.extendedState ~= newProps.extendedState
	local hasInternalSnapshotChanged = self.props.internalSnapshot
		~= newProps.internalSnapshot
	local hasDataChanged = self.props.dataHasChanged
			and self.props.dataHasChanged(self.props.data, newProps.data)
		or self.props.dataHasChanged

	local shouldUpdate = hasSizeChanged
		or hasDataChanged
		or hasExtendedStateChanged
		or hasInternalSnapshotChanged
	if shouldUpdate then
		newProps.itemAnimator.animateWillUpdate(
			self.props.x,
			self.props.y,
			newProps.x,
			newProps.y,
			self:getRef(),
			newProps.index
		)
	elseif hasMoved then
		shouldUpdate = not newProps.itemAnimator.animateShift(
			self.props.x,
			self.props.y,
			newProps.x,
			newProps.y,
			self:getRef(),
			newProps.index
		)
	end

	return shouldUpdate
end

function ViewRenderer:getSnapshotBeforeUpdate(): ()
	self.animatorStyleOverrides = self.props.itemAnimator:animateWillMount(
		self.props.x,
		self.props.y,
		self.props.index
	)
end

function ViewRenderer:componentWillUnmount(): ()
	self.isRendererMounted = false
	self.props.itemAnimator:animateWillUnmount(
		self.props.x,
		self.props.y,
		self:getRef() :: Object | Array<unknown>,
		self.props.index
	)
end

function ViewRenderer:renderChild(): React.Node
	return self.props.childRenderer(
		self.props.layoutType,
		self.props.data,
		self.props.index,
		self.props.extendedState
	)
end

return ViewRenderer
