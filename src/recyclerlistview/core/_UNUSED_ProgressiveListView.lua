-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/ProgressiveListView.tsx

--!nolint LocalShadow

local RunService = game:GetService("RunService")

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local extends = LuauPolyfill.extends
local Object = LuauPolyfill.Object

local React = require("@pkg/@jsdotlua/react")

local RecyclerListView = require("./RecyclerListView")
type RecyclerListView = RecyclerListView.RecyclerListView
type RecyclerListViewProps = RecyclerListView.RecyclerListViewProps
type RecyclerListViewState = RecyclerListView.RecyclerListViewState

export type ProgressiveListViewProps = RecyclerListViewProps & {
	maxRenderAhead: number?,
	renderAheadStep: number?,
	--[[
		A smaller final value can help in building up recycler pool in advance. This is only used if there is a valid updated cycle.
		e.g, if maxRenderAhead is 0 then there will be no cycle and final value will be unused
	]]
	finalRenderAheadOffset: number?,
}

--[[
	This will incrementally update renderAhead distance and render the page progressively.
	renderAheadOffset = initial value which will be incremented
	renderAheadStep = amount of increment made on each frame
	maxRenderAhead = maximum value for render ahead at the end of update cycle
	finalRenderAheadOffset = value to set after whole update cycle is completed. If undefined, final offset value will be equal to maxRenderAhead
 ]]
export type ProgressiveListView = RecyclerListView & {
	componentDidMount: (self: ProgressiveListView) -> (),
	componentWillUnmount: (self: ProgressiveListView) -> (),
}

type ProgressiveListView_private = RecyclerListView & {
	props: ProgressiveListViewProps,

	--
	-- *** PUBLIC ***
	--
	componentDidMount: (self: ProgressiveListView_private) -> (),
	componentWillUnmount: (self: ProgressiveListView_private) -> (),
	--
	-- *** PROTECTED ***
	--
	onItemLayout: (self: ProgressiveListView_private, index: number) -> (),
	--
	-- *** PRIVATE ***
	--
	renderAheadUpdateConnection: RBXScriptConnection?,
	isFirstLayoutComplete: boolean,
	updateRenderAheadProgressively: (
		self: ProgressiveListView_private,
		newVal: number
	) -> (),
	incrementRenderAhead: (self: ProgressiveListView_private) -> (),
	performFinalUpdate: (self: ProgressiveListView_private) -> (),
	cancelRenderAheadUpdate: (self: ProgressiveListView_private) -> (),
}
type ProgressiveListView_statics = { new: () -> ProgressiveListView }

-- local noop = function() end
-- local ProgressiveListView =
-- 	extends(RecyclerListView, "ProgressiveListView", noop) :: ProgressiveListView_private & ProgressiveListView_statics
local ProgressiveListView =
	React.Component:extend("ProgressiveListView") :: ProgressiveListView_private & ProgressiveListView_statics

ProgressiveListView.defaultProps = Object.assign({}, RecyclerListView.defaultProps, {
	maxRenderAhead = math.huge,
	renderAheadStep = 300,
	renderAheadOffset = 0,
})

function ProgressiveListView:init(props)
	print("PROGRESSIVE LIST INIT")
	local self = self :: ProgressiveListView_private
	self.isFirstLayoutComplete = false
	RecyclerListView.init(self, props)
end

function ProgressiveListView:componentDidMount(): ()
	print("PROGRESSIVE LIST MOUNTED")
	RecyclerListView.componentDidMount(self)

	local self = self :: ProgressiveListView_private
	if not self.props.forceNonDeterministicRendering then
		self:updateRenderAheadProgressively(self:getCurrentRenderAheadOffset())
	end
end

function ProgressiveListView:componentWillUnmount(): ()
	local self = self :: ProgressiveListView_private
	self:cancelRenderAheadUpdate()
	RecyclerListView.componentWillUnmount(self)
end

function ProgressiveListView:onItemLayout(index: number): ()
	local self = self :: ProgressiveListView_private
	if not self.isFirstLayoutComplete then
		self.isFirstLayoutComplete = true
		if self.props.forceNonDeterministicRendering then
			self:updateRenderAheadProgressively(self:getCurrentRenderAheadOffset())
		end
	end
	RecyclerListView.onItemLayout(self, index)
end

function ProgressiveListView:updateRenderAheadProgressively(newVal: number): ()
	local self = self :: ProgressiveListView_private
	self:cancelRenderAheadUpdate()
	-- Cancel any pending callback.
	local function updateLoop()
		if not self:updateRenderAheadOffset(newVal) then
			self:updateRenderAheadProgressively(newVal)
		else
			self:incrementRenderAhead()
		end
	end

	-- NOTE: The list might be running in a storybook plugin. In which case, mock the update loop
	if RunService:IsStudio() and RunService:IsEdit() then
		task.delay(0, updateLoop)
	else
		self.renderAheadUpdateConnection = RunService.RenderStepped:Once(updateLoop)
	end
end

function ProgressiveListView:incrementRenderAhead(): ()
	local self = self :: ProgressiveListView_private
	if self.props.maxRenderAhead and self.props.renderAheadStep then
		local layoutManager = self:getVirtualRenderer():getLayoutManager()
		local currentRenderAheadOffset = self:getCurrentRenderAheadOffset()
		if layoutManager then
			local contentDimension = layoutManager:getContentDimension()
			local maxContentSize = if self.props.isHorizontal
				then contentDimension.width
				else contentDimension.height
			if
				currentRenderAheadOffset < maxContentSize
				and currentRenderAheadOffset < self.props.maxRenderAhead
			then
				local newRenderAheadOffset = currentRenderAheadOffset
					+ self.props.renderAheadStep
				self:updateRenderAheadProgressively(newRenderAheadOffset)
			else
				self:performFinalUpdate()
			end
		end
	end
end

function ProgressiveListView:performFinalUpdate(): ()
	self:cancelRenderAheadUpdate()
	-- Cancel any pending callback.
	self.renderAheadUpdateConnection = RunService.RenderStepped:Once(function()
		if self.props.finalRenderAheadOffset ~= nil then
			self:updateRenderAheadOffset(self.props.finalRenderAheadOffset)
		end
	end)
end

function ProgressiveListView:cancelRenderAheadUpdate(): ()
	if self.renderAheadUpdateConnection ~= nil then
		self.renderAheadUpdateConnection:Disconnect()
		self.renderAheadUpdateConnection = nil
	end
end

return ProgressiveListView
