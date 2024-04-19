-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/scrollcomponent/BaseScrollView.tsx

local React = require("@pkg/@jsdotlua/react")
local LayoutProvider = require("../dependencies/LayoutProvider")
type Dimension = LayoutProvider.Dimension

type Map<K, V> = { [K]: V }

export type ScrollViewDefaultProps = {
	onScroll: (event: ScrollEvent) -> (),
	onSizeChanged: (dimensions: Dimension) -> (),
	horizontal: boolean,
	canChangeSize: boolean,
	style: Map<string, any>,
}

export type ScrollEvent = {
	nativeEvent: {
		contentOffset: { x: number, y: number },
		layoutMeasurement: Dimension?,
		contentSize: Dimension?,
	},
}

export type BaseScrollView = React.AbstractComponent<any, any> & {
	scrollTo: (
		self: BaseScrollView,
		scrollInput: { x: number, y: number, animated: boolean }
	) -> (),
}
type BaseScrollView_statics = {}

local BaseScrollView =
	React.Component:extend("BaseScrollView") :: BaseScrollView & BaseScrollView_statics

function BaseScrollView.init(self: BaseScrollView, props: ScrollViewDefaultProps) end
function BaseScrollView:scrollTo(
	scrollInput: { x: number, y: number, animated: boolean }
): ()
	error("not implemented abstract method")
end

return BaseScrollView
