-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/native/config/PlatformHelper.web.ts

local exports = {}

local React = require("@pkg/@jsdotlua/react")
local RecyclerListView = require("../../recyclerlistview")
type BaseItemAnimator = RecyclerListView.BaseItemAnimator

-- TODO: Should we automatically select one of the these defaults?
local _DEFAULT_DRAW_DISTANCE_WEB = 2000
local DEFAULT_DRAW_DISTANCE_MOBILE = 250

local PlatformConfig = {
	defaultDrawDistance = DEFAULT_DRAW_DISTANCE_MOBILE,
	-- ROBLOX deviation: We don't expose an `inverted` API so the following properties are not required.
	-- invertedTransformStyle = { transform = { { scaleY = -1 } } },
	-- invertedTransformStyleHorizontal = { transform = { { scaleX = -1 } } },
}

local function getCellContainerPlatformStyles(
	inverted: boolean,
	parentProps: {
		x: number,
		y: number,
		isHorizontal: boolean?,
	}
): {
	transform: string,
	WebkitTransform: string,
} | nil
	return nil
end

local function getItemAnimator(): BaseItemAnimator | nil
	return nil
end

local function getFooterContainer(): React.AbstractComponent<any, any> | nil
	return nil
end

exports.PlatformConfig = PlatformConfig
exports.getCellContainerPlatformStyles = getCellContainerPlatformStyles
exports.getItemAnimator = getItemAnimator
exports.getFooterContainer = getFooterContainer

return exports
