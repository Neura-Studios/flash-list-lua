-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/devutils/debughandlers/resize/DefaultResizeDebugHandler.ts

local LayoutProvider = require("../../../dependencies/LayoutProvider")
type Dimension = LayoutProvider.Dimension

local ResizeDebugHandler = require("./ResizeDebugHandler")
type ResizeDebugHandler = ResizeDebugHandler.ResizeDebugHandler

export type DefaultResizeDebugHandler = {
	resizeDebug: (
		self: DefaultResizeDebugHandler,
		oldDim: Dimension,
		newDim: Dimension,
		index: number
	) -> (),
}
type DefaultResizeDebugHandler_private = { --
	-- *** PUBLIC ***
	--
	resizeDebug: (
		self: DefaultResizeDebugHandler_private,
		oldDim: Dimension,
		newDim: Dimension,
		index: number
	) -> (),
	--
	-- *** PRIVATE ***
	--
	relaxation: Dimension,
	onRelaxationViolation: (
		expectedDim: Dimension,
		actualDim: Dimension,
		index: number
	) -> (), -- Relaxation is the Dimension object where it accepts the relaxation to allow for each dimension.
	-- Any of the dimension (height or width) whose value for relaxation is less than 0 would be ignored.
}
type DefaultResizeDebugHandler_statics = {
	new: (
		relaxation: Dimension,
		onRelaxationViolation: (
			expectedDim: Dimension,
			actualDim: Dimension,
			index: number
		) -> ()
	) -> DefaultResizeDebugHandler,
}

local DefaultResizeDebugHandler =
	{} :: DefaultResizeDebugHandler & DefaultResizeDebugHandler_statics
local DefaultResizeDebugHandler_private =
	DefaultResizeDebugHandler :: DefaultResizeDebugHandler_private & DefaultResizeDebugHandler_statics;
(DefaultResizeDebugHandler :: any).__index = DefaultResizeDebugHandler

function DefaultResizeDebugHandler_private.new(
	relaxation: Dimension,
	onRelaxationViolation: (
		expectedDim: Dimension,
		actualDim: Dimension,
		index: number
	) -> ()
): DefaultResizeDebugHandler
	local self = setmetatable({}, DefaultResizeDebugHandler)
	self.relaxation = relaxation
	self.onRelaxationViolation = onRelaxationViolation
	return (self :: any) :: DefaultResizeDebugHandler
end

function DefaultResizeDebugHandler_private:resizeDebug(
	oldDim: Dimension,
	newDim: Dimension,
	index: number
): ()
	local isViolated: boolean = false
	if
		self.relaxation.height >= 0
		and math.abs(newDim.height - oldDim.height) >= self.relaxation.height
	then
		isViolated = true
	end
	if
		not isViolated
		and self.relaxation.width >= 0
		and math.abs(newDim.width - oldDim.width) >= self.relaxation.width
	then
		isViolated = true
	end
	if isViolated then
		self.onRelaxationViolation(oldDim, newDim, index)
	end
end

return DefaultResizeDebugHandler
