-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/viewrenderer/BaseViewRenderer.tsx

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object

local React = require("@pkg/@jsdotlua/react")

local layoutProviderModule = require("../dependencies/LayoutProvider")
type Dimension = layoutProviderModule.Dimension
type BaseLayoutProvider = layoutProviderModule.BaseLayoutProvider

local ItemAnimator = require("../ItemAnimator")
type ItemAnimator = ItemAnimator.ItemAnimator

--[[**
 * View renderer is responsible for creating a container of size provided by LayoutProvider and render content inside it.
 * Also enforces a logic to prevent re renders. RecyclerListView keeps moving these ViewRendereres around using transforms to enable recycling.
 * View renderer will only update if its position, dimensions or given data changes. Make sure to have a relevant shouldComponentUpdate as well.
 * This is second of the two things recycler works on. Implemented both for web and react native.
 ]]
export type ViewRendererProps<T> = {
	x: number,
	y: number,
	height: number,
	width: number,
	childRenderer: (
		type_: any,
		data: T,
		index: number,
		extendedState: (Object | Array<unknown>)?
	) -> React.Node | Array<React.Node> | nil,
	layoutType: string | number,
	dataHasChanged: (r1: T, r2: T) -> boolean,
	onSizeChanged: (dim: Dimension, index: number) -> (),
	data: any,
	index: number,
	itemAnimator: ItemAnimator,
	styleOverrides: (Object | Array<unknown>)?,
	forceNonDeterministicRendering: boolean?,
	isHorizontal: boolean?,
	extendedState: (Object | Array<unknown>)?,
	internalSnapshot: (Object | Array<unknown>)?,
	layoutProvider: BaseLayoutProvider?,
	onItemLayout: ((index: number) -> ())?,
	renderItemContainer: ((
		props: Object | Array<unknown>,
		parentProps: ViewRendererProps<T>,
		children: React.Node?
	) -> React.Node)?,
}

export type BaseViewRenderer<T> = React.AbstractComponent<ViewRendererProps<T>, {}> & {
	isRendererMounted: boolean,
}

type BaseViewRenderer_private<T> = React.AbstractComponent<ViewRendererProps<T>, {}> & {
	-- *** PUBLIC ***
	--
	isRendererMounted: boolean,
	--
	-- *** PROTECTED ***
	--
	animatorStyleOverrides: Object | Array<unknown> | nil,
	getRef: (self: any) -> Object | Array<unknown> | nil,
	renderChild: (self: any) -> React.Node | Array<React.Node> | nil,
}
type BaseViewRenderer_statics = { new: <T>() -> BaseViewRenderer<T> }

local BaseViewRenderer = React.Component:extend("BaseViewRenderer")

function BaseViewRenderer.init<T>(): BaseViewRenderer<T>
	local self = setmetatable({}, BaseViewRenderer)
	self.isRendererMounted = true
	return (self :: any) :: BaseViewRenderer<T>
end

function BaseViewRenderer:shouldComponentUpdate(newProps: ViewRendererProps<any>): boolean
	local hasMoved = self.props.x ~= newProps.x or self.props.y ~= newProps.y

	local hasSizeChanged = not newProps.forceNonDeterministicRendering
			and (self.props.width ~= newProps.width or self.props.height ~= newProps.height)
		or self.props.layoutProvider ~= newProps.layoutProvider

	local hasExtendedStateChanged = self.props.extendedState ~= newProps.extendedState
	local hasInternalSnapshotChanged = self.props.internalSnapshot ~= newProps.internalSnapshot
	local hasDataChanged = self.props.dataHasChanged
		and self.props.dataHasChanged(self.props.data, newProps.data)
		or self.props.dataHasChanged

	local shouldUpdate = hasSizeChanged or hasDataChanged or hasExtendedStateChanged or hasInternalSnapshotChanged
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

function BaseViewRenderer:componentDidMount(): ()
	self.animatorStyleOverrides = nil
	self.props.itemAnimator:animateDidMount(
		self.props.x,
		self.props.y,
		self:getRef() :: Object | Array<unknown>,
		self.props.index
	)
end

function BaseViewRenderer:componentWillMountCompat(): ()
	self.animatorStyleOverrides = self.props.itemAnimator:animateWillMount(
		self.props.x,
		self.props.y,
		self.props.index
	)
end

function BaseViewRenderer:componentWillUnmount(): ()
	self.isRendererMounted = false
	self.props.itemAnimator:animateWillUnmount(
		self.props.x,
		self.props.y,
		self:getRef() :: Object | Array<unknown>,
		self.props.index
	)
end

function BaseViewRenderer:componentDidUpdate(): ()
	-- no op
end

function BaseViewRenderer:getRef(): Object | Array<unknown> | nil
	error("not implemented abstract method")
end

function BaseViewRenderer:renderChild(): React.Node
	return self.props:childRenderer(
		self.props.layoutType,
		self.props.data,
		self.props.index,
		self.props.extendedState
	)
end

return BaseViewRenderer
