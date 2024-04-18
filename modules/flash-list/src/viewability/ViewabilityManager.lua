-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/viewability/ViewabilityManager.ts

--[[
	Manager for viewability tracking. It holds multiple viewability callback pairs and keeps them updated.
]]

export type ViewabilityManager<T> = {
	new<T>: ()
}
