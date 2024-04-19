-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/dependencies/DataProvider.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local extends = LuauPolyfill.extends
type Array<T> = LuauPolyfill.Array<T>

local exports = {}

--[[
	You can create a new instance or inherit and override default methods
	Allows access to data and size. Clone with rows creates a new data provider and let listview know where to calculate row layout from.
 ]]
export type BaseDataProvider = {
	new: (
		rowHasChanged: (r1: any, r2: any) -> boolean,
		getStableId: ((index: number) -> string)?
	) -> BaseDataProvider,

	rowHasChanged: (r1: any, r2: any) -> boolean,
	--- In JS context make sure stable id is a string
	getStableId: (index: number) -> string,
	newInstance: (
		self: BaseDataProvider,
		rowHasChanged: (r1: any, r2: any) -> boolean,
		getStableId: ((index: number) -> string)?
	) -> BaseDataProvider,
	getDataForIndex: (self: BaseDataProvider, index: number) -> any,
	getAllData: (self: BaseDataProvider) -> Array<any>,
	getSize: (self: BaseDataProvider) -> number,
	hasStableIds: (self: BaseDataProvider) -> boolean,
	requiresDataChangeHandling: (self: BaseDataProvider) -> boolean,
	getFirstIndexToProcessInternal: (self: BaseDataProvider) -> number,
	--- No need to override this one
	--- If you already know the first row where rowHasChanged will be false pass it upfront to avoid loop
	cloneWithRows: (
		self: BaseDataProvider,
		newData: Array<any>,
		firstModifiedIndex: number?
	) -> DataProvider,

	--
	-- *** PRIVATE ***
	--
	_firstIndexToProcess: number,
	_size: number,
	_data: Array<any>,
	_hasStableIds: boolean,
	_requiresDataChangeHandling: boolean,
}

local BaseDataProvider = {} :: BaseDataProvider;
(BaseDataProvider :: any).__index = BaseDataProvider

function BaseDataProvider.new(
	rowHasChanged: (r1: any, r2: any) -> boolean,
	getStableId: ((index: number) -> string)?
): BaseDataProvider
	local self = setmetatable({}, BaseDataProvider)
	self._firstIndexToProcess = 0
	self._size = 0
	self._data = {}
	self._hasStableIds = false
	self._requiresDataChangeHandling = false
	self.rowHasChanged = rowHasChanged
	if getStableId then
		self.getStableId = getStableId
		self._hasStableIds = true
	else
		self.getStableId = function(index)
			return tostring(index)
		end
	end
	return (self :: any) :: BaseDataProvider
end

function BaseDataProvider:newInstance(
	rowHasChanged: (r1: any, r2: any) -> boolean,
	getStableId: ((index: number) -> string)?
): BaseDataProvider
	error("not implemented abstract method")
end

function BaseDataProvider:getDataForIndex(index: number): any
	return self._data[index]
end

function BaseDataProvider:getAllData(): Array<any>
	return self._data
end

function BaseDataProvider:getSize(): number
	return self._size
end

function BaseDataProvider:hasStableIds(): boolean
	return self._hasStableIds
end

function BaseDataProvider:requiresDataChangeHandling(): boolean
	return self._requiresDataChangeHandling
end

function BaseDataProvider:getFirstIndexToProcessInternal(): number
	return self._firstIndexToProcess
end

function BaseDataProvider:cloneWithRows(
	newData: Array<any>,
	firstModifiedIndex: number?
): DataProvider
	local dp = self:newInstance(
		self.rowHasChanged,
		if self._hasStableIds then self.getStableId else nil
	) :: BaseDataProvider

	local newSize = #newData
	local iterCount = math.min(self._size, newSize)
	if firstModifiedIndex == nil then
		local i = 1
		while i <= iterCount do
			if self.rowHasChanged(self._data[i], newData[i]) then
				break
			end
			i += 1
		end
		dp._firstIndexToProcess = i
	else
		dp._firstIndexToProcess = math.max(math.min(firstModifiedIndex, #self._data), 1)
	end
	if dp._firstIndexToProcess ~= #self._data then
		dp._requiresDataChangeHandling = true
	end
	dp._data = newData
	dp._size = newSize

	return (dp :: any) :: DataProvider
end

exports.BaseDataProvider = BaseDataProvider

export type DataProvider = BaseDataProvider & {
	newInstance: (
		self: DataProvider,
		rowHasChanged: (r1: any, r2: any) -> boolean,
		getStableId: ((index: number) -> string | nil)?
	) -> BaseDataProvider,
}

local DataProvider = extends(
	BaseDataProvider,
	"DataProvider",
	function(
		self: any,
		rowHasChanged: (r1: any, r2: any) -> boolean,
		getStableId: ((index: number) -> string)?
	)
		self._firstIndexToProcess = 0
		self._size = 0
		self._data = {}
		self._hasStableIds = false
		self._requiresDataChangeHandling = false
		self.rowHasChanged = rowHasChanged

		if getStableId then
			self.getStableId = getStableId
			self._hasStableIds = true
		else
			self.getStableId = function(index)
				return tostring(index)
			end
		end
	end
)

function DataProvider:newInstance(
	rowHasChanged: (r1: any, r2: any) -> boolean,
	getStableId: ((index: number) -> string | nil)?
)
	return DataProvider.new(rowHasChanged, getStableId)
end

exports.default = DataProvider
return exports
