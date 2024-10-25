_G.__DEV__ = true

local React = require("@pkg/@jsdotlua/react")
local ReactRoblox = require("@pkg/@jsdotlua/react-roblox")

local ContactsList = require("./SwappingList")

local e = React.createElement

return function(target: GuiObject)
	local root = ReactRoblox.createRoot(target)
	root:render(e(React.StrictMode, {}, {
		Story = e(ContactsList, {}),
	}))

	return function()
		root:unmount()
	end
end
