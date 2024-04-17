-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/platform/web/scrollcomponent/ScrollComponent.tsx
type void = nil --[[ ROBLOX FIXME: adding `void` type alias to make it easier to use Luau `void` equivalent when supported ]]
local Packages --[[ ROBLOX comment: must define Packages module ]]
local LuauPolyfill = require(Packages.LuauPolyfill)
local Boolean = LuauPolyfill.Boolean
local exports = {}
local function _extends()
	_extends = Boolean.toJSBoolean(Object.assign) and Object.assign
		or function(target)
			do
				local i = 1
				while
					i
					< arguments.length --[[ ROBLOX CHECK: operator '<' works only if either both arguments are strings or both are a number ]]
				do
					local source = arguments[tostring(i)]
					for key in source do
						if Boolean.toJSBoolean(Object.prototype.hasOwnProperty(source, key)) then
							target[tostring(key)] = source[tostring(key)]
						end
					end
					i += 1
				end
			end
			return target
		end
	return _extends(self, table.unpack(arguments))
end
local React = require(Packages.react)
local Dimension =
	require(script.Parent.Parent.Parent.Parent.core.dependencies.LayoutProvider).Dimension
local baseScrollComponentModule =
	require(script.Parent.Parent.Parent.Parent.core.scrollcomponent.BaseScrollComponent)
local BaseScrollComponent = baseScrollComponentModule.default
local ScrollComponentProps = baseScrollComponentModule.ScrollComponentProps
local baseScrollViewModule =
	require(script.Parent.Parent.Parent.Parent.core.scrollcomponent.BaseScrollView)
local BaseScrollView = baseScrollViewModule.default
local ScrollEvent = baseScrollViewModule.ScrollEvent
local ScrollViewer = require(script.Parent.ScrollViewer).default
--[[**
 * The responsibility of a scroll component is to report its size, scroll events and provide a way to scroll to a given offset.
 * RecyclerListView works on top of this interface and doesn't care about the implementation. To support web we only had to provide
 * another component written on top of web elements
 ]]
export type ScrollComponent = BaseScrollComponent & {
	scrollTo: (self: ScrollComponent, x: number, y: number, animated: boolean) -> (),
	render: (self: ScrollComponent) -> JSX_Element,
}
type ScrollComponent_private = BaseScrollComponent & { --
	-- *** PUBLIC ***
	--
	scrollTo: (self: ScrollComponent_private, x: number, y: number, animated: boolean) -> (),
	render: (self: ScrollComponent_private) -> JSX_Element,
	--
	-- *** PRIVATE ***
	--
	_height: number,
	_width: number,
	_scrollViewRef: BaseScrollView | nil,--[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]]
	_onScroll: any,
	_onSizeChanged: any,
}
type ScrollComponent_statics = { new: (args: ScrollComponentProps) -> ScrollComponent }
local ScrollComponent = (
	setmetatable({}, { __index = BaseScrollComponent }) :: any
) :: ScrollComponent & ScrollComponent_statics
local ScrollComponent_private = ScrollComponent :: ScrollComponent_private & ScrollComponent_statics;
(ScrollComponent :: any).__index = ScrollComponent
ScrollComponent.defaultProps = {
	contentHeight = 0,
	contentWidth = 0,
	externalScrollView = ScrollViewer,
	isHorizontal = false,
	scrollThrottle = 16,
	canChangeSize = false,
}
function ScrollComponent_private.new(args: ScrollComponentProps): ScrollComponent
	local self = setmetatable({}, ScrollComponent) --[[ ROBLOX TODO: super constructor may be used ]]
	self._scrollViewRef = nil
	self._onScroll = function(e: ScrollEvent): void
		self.props:onScroll(e.nativeEvent.contentOffset.x, e.nativeEvent.contentOffset.y, e)
	end
	self._onSizeChanged = function(event: Dimension): void
		if Boolean.toJSBoolean(self.props.onSizeChanged) then
			self.props:onSizeChanged(event)
		end
	end;
	(error("not implemented") --[[ ROBLOX TODO: Unhandled node for type: Super ]] --[[ super ]])(
		args
	)
	self._height = 0
	self._width = 0
	return (self :: any) :: ScrollComponent
end
function ScrollComponent_private:scrollTo(x: number, y: number, animated: boolean): ()
	if Boolean.toJSBoolean(self._scrollViewRef) then
		self._scrollViewRef:scrollTo({ x = x, y = y, animated = animated })
	end
end
function ScrollComponent_private:render(): JSX_Element
	local Scroller = self.props.externalScrollView :: any --TSI
	return React.createElement(
		Scroller,
		_extends(
			{
				ref = function(scrollView: BaseScrollView)
					self._scrollViewRef = scrollView :: BaseScrollView | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]]
					return self._scrollViewRef
				end,
			},
			self.props,
			{
				horizontal = self.props.isHorizontal,
				onScroll = self._onScroll,
				onSizeChanged = self._onSizeChanged,
			}
		),
		React.createElement(
			"div",
			{ style = { height = self.props.contentHeight, width = self.props.contentWidth } },
			self.props.children
		),
		if Boolean.toJSBoolean(self.props.renderFooter)
			then React.createElement("div", {
				style = if Boolean.toJSBoolean(self.props.isHorizontal)
					then { left = self.props.contentWidth, position = "absolute", top = 0 }
					else nil,
			}, self.props:renderFooter())
			else nil
	)
end
exports.default = ScrollComponent
return exports
