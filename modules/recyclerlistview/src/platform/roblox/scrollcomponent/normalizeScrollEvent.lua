-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/platform/web/scrollcomponent/ScrollEventNormalizer.ts

local BaseScrollView = require("../../../core/scrollcomponent/BaseScrollView")
type ScrollEvent = BaseScrollView.ScrollEvent

export type NormalizedScrollEvent = {
	divEvent: ScrollEvent,
	-- ROBLOX deviation: Window events aren't included because Roblox has no concept of a global window.
	-- windowEvent: ScrollEvent,
}

-- ROBLOX deviation: Instead of using a class, we have a utility function that created a
--  normalized scroll event table.
--
-- NOTE: In upstream, the properties are implemented as getter functions. Here
--  they are just regular values. This might cause issues.
local function normalizeScrollEvent(target: ScrollingFrame): NormalizedScrollEvent
	local divEvent: ScrollEvent = {
		nativeEvent = {
			contentOffset = {
				x = target.CanvasPosition.X,
				y = target.CanvasPosition.Y,
			},
			contentSize = {
				height = target.AbsoluteCanvasSize.Y,
				width = target.AbsoluteCanvasSize.X,
			},
			layoutMeasurement = {
				height = target.AbsoluteSize.Y,
				width = target.AbsoluteSize.X,
			},
		},
	}

	-- ROBLOX deviation: Window events aren't included because Roblox has no concept of a global window.
	-- local windowEvent: ScrollEvent = {
	-- 	nativeEvent = {
	-- 		contentOffset = {
	-- 			x = function(self): number
	-- 				return if window.scrollX == nil
	-- 					then window.pageXOffset
	-- 					else window.scrollX
	-- 			end,
	-- 			y = function(self): number
	-- 				return if window.scrollY == nil
	-- 					then window.pageYOffset
	-- 					else window.scrollY
	-- 			end,
	-- 		},
	-- 		contentSize = {
	-- 			height = function(self): number
	-- 				return target.offsetHeight
	-- 			end,
	-- 			width = function(self): number
	-- 				return target.offsetWidth
	-- 			end,
	-- 		},
	-- 		layoutMeasurement = {
	-- 			height = function(self): number
	-- 				return window.innerHeight
	-- 			end,
	-- 			width = function(self): number
	-- 				return window.innerWidth
	-- 			end,
	-- 		},
	-- 	},
	-- }

	return {
		divEvent = divEvent,
		-- ROBLOX deviation: Window events aren't included because Roblox has no concept of a global window.
		-- windowEvent = windowEvent,
	}
end

return normalizeScrollEvent
