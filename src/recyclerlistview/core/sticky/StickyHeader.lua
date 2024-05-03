-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/sticky/StickyHeader.tsx

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Object = LuauPolyfill.Object

--[[
	Created by ananya.chandra on 20/09/18.
]]

local React = require("@pkg/@jsdotlua/react")

local stickyObjectModule = require("./StickyObject")
local StickyObject = stickyObjectModule.default
type StickyObjectProps = stickyObjectModule.StickyObjectProps

local StickyHeader = React.forwardRef(function(props: StickyObjectProps, ref)
	return React.createElement(
		StickyObject :: any,
		Object.assign({}, props, {
			ref = ref,
			objectType = "header",
		})
	)
end)

return (StickyHeader :: any) :: React.FC<StickyObjectProps>
