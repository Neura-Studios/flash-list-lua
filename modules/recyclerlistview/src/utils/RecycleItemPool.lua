-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/utils/RecycleItemPool.ts

--[[
	Recycle pool for maintaining recyclable items, supports segregation by type as well.
	Availability check, add/remove etc are all O(1), uses two maps to achieve constant time operation
]]

type PseudoSet = { [string]: string }
type NullablePseudoSet = {
	[string]: string | nil,
}

export type RecycleItemPool = {
	putRecycledObject: (
		self: RecycleItemPool,
		objectType: string | number,
		object: string
	) -> (),
	getRecycledObject: (
		self: RecycleItemPool,
		objectType: string | number
	) -> string | nil,
	removeFromPool: (self: RecycleItemPool, object: string) -> boolean,
	clearAll: (self: RecycleItemPool) -> (),
}

type RecycleItemPool_private = { --
	-- *** PUBLIC ***
	--
	putRecycledObject: (
		self: RecycleItemPool_private,
		objectType: string | number,
		object: string
	) -> (),
	getRecycledObject: (
		self: RecycleItemPool_private,
		objectType: string | number
	) -> string | nil,
	removeFromPool: (self: RecycleItemPool_private, object: string) -> boolean,
	clearAll: (self: RecycleItemPool_private) -> (),
	--
	-- *** PRIVATE ***
	--
	_recyclableObjectMap: { [string]: NullablePseudoSet },
	_availabilitySet: PseudoSet,
	_getRelevantSet: (
		self: RecycleItemPool_private,
		objectType: string
	) -> NullablePseudoSet,
	_stringify: (self: RecycleItemPool_private, objectType: string | number) -> string,
}

type RecycleItemPool_statics = { new: () -> RecycleItemPool }
local RecycleItemPool = {} :: RecycleItemPool & RecycleItemPool_statics
local RecycleItemPool_private =
	RecycleItemPool :: RecycleItemPool_private & RecycleItemPool_statics;
(RecycleItemPool :: any).__index = RecycleItemPool

function RecycleItemPool_private.new(): RecycleItemPool
	local self = setmetatable({}, RecycleItemPool)
	self._recyclableObjectMap = {}
	self._availabilitySet = {}
	return (self :: any) :: RecycleItemPool
end

function RecycleItemPool_private:putRecycledObject(
	objectType_: string | number,
	object: string
): ()
	local objectType = self:_stringify(objectType_)
	local objectSet = self:_getRelevantSet(objectType)
	if not self._availabilitySet[object] then
		objectSet[object] = nil
		self._availabilitySet[object] = objectType
	end
end

function RecycleItemPool_private:getRecycledObject(
	objectType_: string | number
): string | nil
	local objectType = self:_stringify(objectType_)
	local objectSet = self:_getRelevantSet(objectType)
	local recycledObject
	for property in objectSet do
		if objectSet[property] ~= nil then
			recycledObject = property
			break
		end
	end
	if recycledObject then
		objectSet[recycledObject] = nil
		self._availabilitySet[recycledObject] = nil
	end
	return recycledObject
end

function RecycleItemPool_private:removeFromPool(object: string): boolean
	if self._availabilitySet[object] then
		self:_getRelevantSet(self._availabilitySet[object])[object] = nil
		self._availabilitySet[object] = nil
		return true
	end
	return false
end

function RecycleItemPool_private:clearAll(): ()
	self._recyclableObjectMap = {}
	self._availabilitySet = {}
end

function RecycleItemPool_private:_getRelevantSet(objectType: string): NullablePseudoSet
	local objectSet = self._recyclableObjectMap[objectType]
	if not objectSet then
		objectSet = {}
		self._recyclableObjectMap[objectType] = objectSet
	end
	return objectSet
end

function RecycleItemPool_private:_stringify(objectType: string | number): string
	if type(objectType) == "number" then
		return tostring(objectType)
	end
	return objectType
end

return RecycleItemPool
