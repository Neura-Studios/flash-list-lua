-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/native/auto-layout/AutoLayoutViewNativeComponent.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Object = LuauPolyfill.Object

local React = require("@pkg/@jsdotlua/react")

-- TODO: In upstream, the native `AutoLayoutViewNativeComponent` component supports blank area tracking.
--  We need to implement that logic here if we want to support it too.

local AutoLayoutViewNativeComponent = React.forwardRef(function(props: any, ref)
	props = Object.assign({
		-- Size = UDim2.fromScale(1, 1),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
	}, props)

	return React.createElement("Frame", Object.assign({}, props, { ref = ref }), props.children)
end)

AutoLayoutViewNativeComponent.displayName = "CellContainer"

return AutoLayoutViewNativeComponent
