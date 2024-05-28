-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/PureComponentWrapper.tsx

local React = require("@pkg/@jsdotlua/react")

export type PureComponentWrapperProps = {
	renderer: (arg: unknown) -> React.Node | nil,
	--- Renderer is called with this argument.
	--- Don't change this value every time or else component will always rerender. Prefer primitives.
	arg: unknown?,
	enabled: boolean?,
}

--- Pure component wrapper that can be used to prevent renders of the `renderer`
--- method passed to the component. Any change in props will lead to `renderer`
--- getting called.
type PureComponentWrapper = React.ComponentClass<PureComponentWrapperProps> & {
	setEnabled: (self: PureComponentWrapper, enabled: boolean) -> any,
	overrideEnabled: boolean | nil,
}

local PureComponentWrapper =
	React.PureComponent:extend("PureComponentWrapper") :: PureComponentWrapper

PureComponentWrapper.defaultProps = {
	enabled = true,
} :: any

function PureComponentWrapper.init(self: PureComponentWrapper)
	self.overrideEnabled = nil
end

function PureComponentWrapper:setEnabled(enabled: boolean)
	if enabled ~= self.overrideEnabled then
		self.overrideEnabled = enabled
		self:forceUpdate()
	end
end

function PureComponentWrapper.render(self: PureComponentWrapper)
	if self.overrideEnabled == nil then
		return if self.props.enabled then self.props.renderer(self.props.arg) else nil
	else
		return if self.overrideEnabled then self.props.renderer(self.props.arg) else nil
	end
end

return PureComponentWrapper
