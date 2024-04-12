-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/exceptions/CustomError.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Error = LuauPolyfill.Error
type Error = LuauPolyfill.Error
local extends = LuauPolyfill.extends

export type Exception = { type: string, message: string }

local CustomError = extends(Error, "CustomError", function(this: Error, exception: Exception)
	this.name = exception.type
	this.message = exception.message
end)

return CustomError
