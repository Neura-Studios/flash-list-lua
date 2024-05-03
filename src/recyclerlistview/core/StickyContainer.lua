-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/StickyContainer.tsx

--!nolint LocalShadow

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Object = LuauPolyfill.Object
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object
type Error = LuauPolyfill.Error

--[[*
 * Created by ananya.chandra on 14/09/18.
 ]]

local React = require("@pkg/@jsdotlua/react")
local RecyclerListView = require("./RecyclerListView")
type RecyclerListView = RecyclerListView.RecyclerListView
type RecyclerListViewState = RecyclerListView.RecyclerListViewState
type RecyclerListViewProps = RecyclerListView.RecyclerListViewProps
local BaseScrollView = require("./scrollcomponent/BaseScrollView")
type ScrollEvent = BaseScrollView.ScrollEvent
local StickyObject = require("./sticky/StickyObject")
type StickyObjectProps = StickyObject.StickyObjectProps
local StickyHeader = require("./sticky/StickyHeader")
type StickyHeader = StickyHeader.StickyHeader
local StickyFooter = require("./sticky/StickyFooter")
type StickyFooter = StickyFooter.StickyFooter
local CustomError = require("./exceptions/CustomError")
local RecyclerListViewExceptions = require("./exceptions/RecyclerListViewExceptions")
local LayoutManager = require("./layoutmanager/LayoutManager")
type Layout = LayoutManager.Layout
local layoutProviderModule = require("./dependencies/LayoutProvider")
type BaseLayoutProvider = layoutProviderModule.BaseLayoutProvider
type Dimension = layoutProviderModule.Dimension
local DataProvider = require("./dependencies/DataProvider")
type BaseDataProvider = DataProvider.BaseDataProvider
local ViewabilityTracker = require("./ViewabilityTracker")
type WindowCorrection = ViewabilityTracker.WindowCorrection

export type StickyContainerProps = {
	children: RecyclerChild,
	stickyHeaderIndices: Array<number>?,
	stickyFooterIndices: Array<number>?,
	overrideRowRenderer: ((
		type_: any,
		data: any,
		index: number,
		extendedState: (Object | Array<unknown>)?
	) -> React.Node)?,
	applyWindowCorrection: ((
		offsetX: number,
		offsetY: number,
		windowCorrection: WindowCorrection
	) -> ())?,
	renderStickyContainer: ((
		stickyContent: React.Node,
		index: number,
		extendedState: (Object | Array<unknown>)?
	) -> React.Node)?,
	style: any?,
	alwaysStickyFooter: boolean?,
}

export type RecyclerChild = React.ReactElement<RecyclerListViewProps> & {
	ref: (recyclerRef: any) -> {},
	props: RecyclerListViewProps,
}

type Props = StickyContainerProps
type State = {}

export type StickyContainer = {
	-- NOTE: We have to inline the React component types here to make Luau happy. I am sad.
	props: Props,
	state: State,

	setState: (
		self: StickyContainer,
		partialState: State | (({}, Props) -> State?),
		callback: (() -> ())?
	) -> (),

	forceUpdate: (self: StickyContainer, callback: (() -> ())?) -> (),

	init: (self: StickyContainer, props: Props, context: any?) -> (),
	render: (self: StickyContainer) -> React.Node,
	componentWillMount: (self: StickyContainer) -> (),
	UNSAFE_componentWillMount: (self: StickyContainer) -> (),
	componentDidMount: (self: StickyContainer) -> (),
	componentWillReceiveProps: (
		self: StickyContainer,
		nextProps: Props,
		nextContext: any
	) -> (),
	UNSAFE_componentWillReceiveProps: (
		self: StickyContainer,
		nextProps: Props,
		nextContext: any
	) -> (),
	shouldComponentUpdate: (
		self: StickyContainer,
		nextProps: Props,
		nextState: Props,
		nextContext: any
	) -> boolean,
	componentWillUpdate: (
		self: StickyContainer,
		nextProps: Props,
		nextState: Props,
		nextContext: any
	) -> (),
	UNSAFE_componentWillUpdate: (
		self: StickyContainer,
		nextProps: Props,
		nextState: Props,
		nextContext: any
	) -> (),
	componentDidUpdate: (
		self: StickyContainer,
		prevProps: Props,
		prevState: Props,
		prevContext: any
	) -> (),
	componentWillUnmount: (self: StickyContainer) -> (),
	componentDidCatch: (
		self: StickyContainer,
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
	-- *** PRIVATE ***
	--
	_recyclerRef: RecyclerListView | nil,
	_dataProvider: BaseDataProvider,
	_layoutProvider: BaseLayoutProvider,
	_extendedState: Object | Array<unknown> | nil,
	_rowRenderer: (
		type_: any,
		data: any,
		index: number,
		extendedState: (Object | Array<unknown>)?
	) -> React.Node,
	_stickyHeaderRef: StickyHeader | nil,
	_stickyFooterRef: StickyFooter | nil,
	_visibleIndicesAll: Array<number>,
	_windowCorrection: WindowCorrection,
	_rlvRowRenderer: any,
	_getRecyclerRef: any,
	_getCurrentWindowCorrection: any,
	_getStickyHeaderRef: any,
	_getStickyFooterRef: any,
	_onVisibleIndicesChanged: any,
	_callStickyObjectsOnVisibleIndicesChanged: any,
	_onScroll: any,
	_getWindowCorrection: (
		self: StickyContainer,
		offsetX: number,
		offsetY: number,
		props: StickyContainerProps
	) -> WindowCorrection,
	_assertChildType: any,
	_isChildRecyclerInstance: any,
	_getLayoutForIndex: any,
	_getDataForIndex: any,
	_getLayoutTypeForIndex: any,
	_getExtendedState: any,
	_getRowRenderer: any,
	_getRLVRenderedSize: any,
	_getContentDimension: any,
	_applyWindowCorrection: any,
	_initParams: any,
}

-- local StickyContainer = (
-- 	setmetatable({}, { __index = ComponentCompat }) :: any
-- ) :: StickyContainer<any> & StickyContainer_statics
-- local StickyContainer =
-- 	StickyContainer :: StickyContainer<any> & StickyContainer_statics;
-- (StickyContainer :: any).__index = StickyContainer
-- StickyContainer.propTypes = {}

local StickyContainer = React.Component:extend("StickyContainer") :: StickyContainer

function StickyContainer:init(props: Props, context: any?)
	local self = self :: StickyContainer

	self._recyclerRef = nil
	self._stickyHeaderRef = nil
	self._stickyFooterRef = nil
	self._visibleIndicesAll = {}
	self._windowCorrection = { startCorrection = 0, endCorrection = 0, windowShift = 0 }

	self._rlvRowRenderer = function(
		type_,
		data: any,
		index: number,
		extendedState: (Object | Array<unknown>)?
	): React.Node
		if self.props.alwaysStickyFooter then
			local rlvDimension: Dimension | nil = self._getRLVRenderedSize()
			local contentDimension: Dimension | nil = self._getContentDimension()
			local isScrollable = false
			if rlvDimension and contentDimension then
				isScrollable = contentDimension.height > rlvDimension.height
			end
			if
				not isScrollable
				and self.props.stickyFooterIndices
				and index == self.props.stickyFooterIndices[1]
			then
				return nil
			end
		end
		return self._rowRenderer(type_, data, index, extendedState)
	end

	self._getRecyclerRef = function(recycler: any)
		self._recyclerRef = recycler
		if self.props.children.ref then
			if type(self.props.children.ref) == "function" then
				self.props.children.ref(recycler)
			else
				error(
					CustomError.new(RecyclerListViewExceptions.refNotAsFunctionException)
				)
			end
		end
	end

	self._getCurrentWindowCorrection = function(): WindowCorrection
		return self._windowCorrection
	end

	self._getStickyHeaderRef = function(stickyHeaderRef: any)
		if self._stickyHeaderRef ~= stickyHeaderRef then
			self._stickyHeaderRef = stickyHeaderRef
			-- TODO: Resetting state once ref is initialized. Can look for better solution.
			self._callStickyObjectsOnVisibleIndicesChanged(self._visibleIndicesAll)
		end
	end

	self._getStickyFooterRef = function(stickyFooterRef: any)
		if self._stickyFooterRef ~= stickyFooterRef then
			self._stickyFooterRef = stickyFooterRef
			-- TODO: Resetting state once ref is initialized. Can look for better solution.
			self._callStickyObjectsOnVisibleIndicesChanged(self._visibleIndicesAll)
		end
	end

	self._onVisibleIndicesChanged = function(
		all: Array<number>,
		now: Array<number>,
		notNow: Array<number>
	)
		self._visibleIndicesAll = all
		self._callStickyObjectsOnVisibleIndicesChanged(all)
		if
			self.props.children
			and self.props.children.props
			and self.props.children.props.onVisibleIndicesChanged
		then
			(self :: any).props.children.props:onVisibleIndicesChanged(all, now, notNow)
		end
	end

	self._callStickyObjectsOnVisibleIndicesChanged = function(all: Array<number>)
		if self._stickyHeaderRef then
			self._stickyHeaderRef:onVisibleIndicesChanged(all)
		end
		if self._stickyFooterRef then
			self._stickyFooterRef:onVisibleIndicesChanged(all)
		end
	end

	self._onScroll = function(rawEvent: ScrollEvent, offsetX: number, offsetY: number)
		self:_getWindowCorrection(offsetX, offsetY, self.props)
		if self._stickyHeaderRef then
			self._stickyHeaderRef:onScroll(offsetY)
		end
		if self._stickyFooterRef then
			self._stickyFooterRef:onScroll(offsetY)
		end
		if
			self.props.children
			and self.props.children.props
			and self.props.children.props.onScroll
		then
			local onScroll: any = self.props.children.props.onScroll
			onScroll(rawEvent, offsetX, offsetY)
		end
	end

	self._assertChildType = function()
		if
			React.Children.count(self.props.children) ~= 1
			or not self:_isChildRecyclerInstance()
		then
			error(
				CustomError.new(RecyclerListViewExceptions.wrongStickyChildTypeException)
			)
		end
	end

	self._isChildRecyclerInstance = function(): boolean
		return self.props.children ~= nil
			and self.props.children.props ~= nil
			and self.props.children.props.dataProvider ~= nil
			and self.props.children.props.rowRenderer ~= nil
			and self.props.children.props.layoutProvider ~= nil
	end

	self._getLayoutForIndex = function(index: number): Layout | nil
		if self._recyclerRef then
			return self._recyclerRef:getLayout(index)
		end
		return nil
	end

	self._getDataForIndex = function(index: number): any
		return self._dataProvider:getDataForIndex(index)
	end

	self._getLayoutTypeForIndex = function(index: number): string | number
		return self._layoutProvider:getLayoutTypeForIndex(index)
	end

	self._getExtendedState = function(): Object | Array<unknown> | nil
		return self._extendedState
	end

	self._getRowRenderer = function(): (
		type_: any,
		data: any,
		index: number,
		extendedState: (Object | Array<unknown>)?
	) -> React.Node
		return self._rowRenderer
	end

	self._getRLVRenderedSize = function(): Dimension | nil
		if self._recyclerRef then
			return self._recyclerRef:getRenderedSize()
		end
		return nil
	end

	self._getContentDimension = function(): Dimension | nil
		if self._recyclerRef then
			return self._recyclerRef:getContentDimension()
		end
		return nil
	end

	self._applyWindowCorrection = function(
		offsetX: number,
		offsetY: number,
		windowCorrection: WindowCorrection
	)
		if self.props.applyWindowCorrection then
			self.props.applyWindowCorrection(offsetX, offsetY, windowCorrection)
		end
	end

	self._initParams = function(props: Props)
		local childProps: RecyclerListViewProps = props.children.props
		self._dataProvider = childProps.dataProvider
		self._layoutProvider = childProps.layoutProvider
		self._extendedState = childProps.extendedState
		self._rowRenderer = childProps.rowRenderer
	end

	self:_assertChildType()
	local childProps: RecyclerListViewProps = props.children.props
	self._dataProvider = childProps.dataProvider
	self._layoutProvider = childProps.layoutProvider
	self._extendedState = childProps.extendedState
	self._rowRenderer = childProps.rowRenderer
	self:_getWindowCorrection(0, 0, props)
end

function StickyContainer:componentDidUpdate(): ()
	self._initParams(self.props)
end

function StickyContainer:render()
	self:_assertChildType()

	local recycler = React.cloneElement(
		self.props.children,
		Object.assign({}, self.props.children.props, {
			ref = self._getRecyclerRef,
			onVisibleIndicesChanged = self._onVisibleIndicesChanged,
			onScroll = self._onScroll,
			applyWindowCorrection = self._applyWindowCorrection,
			rowRenderer = self._rlvRowRenderer,
		})
	)

	return React.createElement("Frame", self.props.style or {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, recycler, self.props.stickyHeaderIndices and React.createElement(StickyHeader, {
		ref = function(stickyHeaderRef: any)
			return self._getStickyHeaderRef(stickyHeaderRef)
		end,
		stickyIndices = self.props.stickyHeaderIndices,
		getLayoutForIndex = self._getLayoutForIndex,
		getDataForIndex = self._getDataForIndex,
		getLayoutTypeForIndex = self._getLayoutTypeForIndex,
		getExtendedState = self._getExtendedState,
		getRLVRenderedSize = self._getRLVRenderedSize,
		getContentDimension = self._getContentDimension,
		getRowRenderer = self._getRowRenderer,
		overrideRowRenderer = self.props.overrideRowRenderer,
		renderContainer = self.props.renderStickyContainer,
		getWindowCorrection = self._getCurrentWindowCorrection,
	}), self.props.stickyFooterIndices and React.createElement(StickyFooter, {
		ref = function(stickyFooterRef: any)
			return self._getStickyFooterRef(stickyFooterRef)
		end,
		stickyIndices = self.props.stickyFooterIndices,
		getLayoutForIndex = self._getLayoutForIndex,
		getDataForIndex = self._getDataForIndex,
		getLayoutTypeForIndex = self._getLayoutTypeForIndex,
		getExtendedState = self._getExtendedState,
		getRLVRenderedSize = self._getRLVRenderedSize,
		getContentDimension = self._getContentDimension,
		getRowRenderer = self._getRowRenderer,
		overrideRowRenderer = self.props.overrideRowRenderer,
		renderContainer = self.props.renderStickyContainer,
		getWindowCorrection = self._getCurrentWindowCorrection,
		alwaysStickBottom = self.props.alwaysStickyFooter,
	}))
end

function StickyContainer:_getWindowCorrection(
	offsetX: number,
	offsetY: number,
	props: StickyContainerProps
): WindowCorrection
	return (
		props.applyWindowCorrection
		and props.applyWindowCorrection(offsetX, offsetY, self._windowCorrection)
	) or self._windowCorrection
end

return (StickyContainer :: any) :: React.FC<StickyContainerProps>
