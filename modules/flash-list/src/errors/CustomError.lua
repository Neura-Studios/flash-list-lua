-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/errors/CustomError.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Error = LuauPolyfill.Error
local extends = LuauPolyfill.extends

type Error = typeof(Error.new())

export type Exception = {
	message: string,
	type: string,
}

local CustomError = extends(
	Error,
	"CustomError",
	function(this: Error, exception: Exception)
		this.name = exception.type
		this.message = exception.message
	end
)

return CustomError