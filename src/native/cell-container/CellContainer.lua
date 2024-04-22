-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/native/cell-container/CellContainer.web.tsx

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Object = LuauPolyfill.Object

local React = require("@pkg/@jsdotlua/react")

-- On Roblox we use a Frame instead of cell container till we build native Roblox implementations
local CellContainer = React.forwardRef(function(props: any, ref)
	props = Object.assign({
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, props)

	return React.createElement(
		"Frame",
		Object.assign({}, props, { ref = ref }),
		props.children
	)
end)

CellContainer.displayName = "CellContainer"

return CellContainer
