-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/errors/CustomError.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Error = LuauPolyfill.Error

type Error = typeof(Error.new())

export type Exception = {
	message: string,
	type: string,
}

local CustomError = {}

function CustomError.new(exception: Exception): Error
	local self = Error.new(`{exception.type}: {exception.message}`)
	self.name = exception.type

	return self
end

return CustomError
