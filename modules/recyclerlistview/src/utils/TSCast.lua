-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/utils/TSCast.ts

-- ROBLOX deviation: Don't use a class with a static method, just use a function
local function cast<T>(obj: any): T
	return obj :: T
end

return cast
