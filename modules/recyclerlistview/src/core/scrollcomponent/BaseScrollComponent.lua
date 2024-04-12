-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/scrollcomponent/BaseScrollComponent.tsx

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object

local React = require("@pkg/@jsdotlua/react")
local LayoutProvider = require("../dependencies/LayoutProvider")
type Dimension = LayoutProvider.Dimension

local baseScrollViewModule = require("./BaseScrollView")
type ScrollEvent = baseScrollViewModule.ScrollEvent

export type ScrollComponentProps = {
	onSizeChanged: (dimensions: Dimension) -> (),
	onScroll: (offsetX: number, offsetY: number, rawEvent: ScrollEvent) -> (),
	contentHeight: number,
	contentWidth: number,
	canChangeSize: boolean?,
	externalScrollView: any?,
	isHorizontal: boolean?,
	renderFooter: (() -> React.Node | Array<React.Node> | nil)?,
	scrollThrottle: number?,
	useWindowScroll: boolean?,
	onLayout: any?,
	renderContentContainer: ((
		props: (Object | Array<unknown>)?,
		children: React.Node?
	) -> React.Node | nil)?,
	renderAheadOffset: number,
	layoutSize: Dimension?,
}

export type BaseScrollComponent = React.AbstractComponent<any, any> & {
	scrollTo: (self: BaseScrollComponent, x: number, y: number, animate: boolean) -> (),
	-- Override and return node handle to your custom scrollview. Useful if you need to use Animated Events.
	getScrollableNode: (self: BaseScrollComponent) -> number | nil,
}
type BaseScrollComponent_statics = {}

local BaseScrollComponent =
	React.Component:extend("BaseScrollComponent") :: BaseScrollComponent & BaseScrollComponent_statics

function BaseScrollComponent:scrollTo(x: number, y: number, animate: boolean): ()
	error("not implemented abstract method")
end

function BaseScrollComponent:getScrollableNode(): number | nil
	return nil
end

return BaseScrollComponent
