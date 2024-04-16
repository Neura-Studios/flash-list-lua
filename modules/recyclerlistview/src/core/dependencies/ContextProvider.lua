-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/dependencies/ContextProvider.ts

--[[
	Context provider is useful in cases where your view gets destroyed and you want to maintain scroll position when recyclerlistview is recreated e.g,
	back navigation in android when previous fragments onDestroyView has already been called. Since recyclerlistview only renders visible items you
	can instantly jump to any location.

	Use this interface and implement the given methods to preserve context.
 ]]

export type ContextValue = string | number | { [string | number]: any }

export type ContextProvider = {
	--- Should be of string type, anything which is unique in global scope of your application
	getUniqueKey: (self: ContextProvider) -> string,
	--- Let recycler view save a value, you can use apis like session storage/async storage here
	save: (self: ContextProvider, key: string, value: ContextValue) -> (),
	--- Get value for a key
	get: (self: ContextProvider, key: string) -> ContextValue,
	--- Remove key value pair
	remove: (self: ContextProvider, key: string) -> (),
}

type ContextProvider_statics = { new: () -> ContextProvider }
local ContextProvider = {} :: ContextProvider & ContextProvider_statics;
(ContextProvider :: any).__index = ContextProvider

function ContextProvider.new(): ContextProvider
	local self = setmetatable({}, ContextProvider)
	return (self :: any) :: ContextProvider
end

function ContextProvider:getUniqueKey(): string
	error("not implemented abstract method")
end
function ContextProvider:save(key: string, value: ContextValue): ()
	error("not implemented abstract method")
end
function ContextProvider:get(key: string): string | number
	error("not implemented abstract method")
end
function ContextProvider:remove(key: string): ()
	error("not implemented abstract method")
end

return ContextProvider
