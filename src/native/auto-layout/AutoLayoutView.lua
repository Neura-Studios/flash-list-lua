-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/native/auto-layout/AutoLayoutView.tsx

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
type Array<T> = LuauPolyfill.Array<T>

local exports = {}

local React = require("@pkg/@jsdotlua/react")
local useEffect = React.useEffect
type ReactNode = React.ReactNode

local AutoLayoutViewNativeComponent = require("./AutoLayoutViewNativeComponent")
local AutoLayoutViewNativeComponentProps = require("./AutoLayoutViewNativeComponentProps")
type OnBlankAreaEvent = AutoLayoutViewNativeComponentProps.OnBlankAreaEvent

export type BlankAreaEventHandler = (blankAreaEvent: BlankAreaEvent) -> ()

local listeners: Array<BlankAreaEventHandler> = {}
local function useOnNativeBlankAreaEvents(
	onBlankAreaEvent: (blankAreaEvent: BlankAreaEvent) -> ()
)
	useEffect(function()
		table.insert(listeners, onBlankAreaEvent)
		return function()
			Array.filter(listeners, function(callback)
				return callback ~= onBlankAreaEvent
			end)
		end
	end, { onBlankAreaEvent })
end
exports.useOnNativeBlankAreaEvents = useOnNativeBlankAreaEvents

export type BlankAreaEvent = {
	offsetStart: number,
	offsetEnd: number,
	blankArea: number,
}

export type AutoLayoutViewProps = {
	children: ReactNode?,
	onBlankAreaEvent: BlankAreaEventHandler?,
	onLayout: ((event: any) -> ())?,
	disableAutoLayout: boolean?,
}

type AutoLayoutView = React.React_Component<any, any> & {
	onBlankAreaEventCallback: any,
	broadcastBlankEvent: (self: AutoLayoutView, value: BlankAreaEvent) -> any,
}

local AutoLayoutView = React.Component:extend("AutoLayoutView") :: AutoLayoutView

function AutoLayoutView.init(self: AutoLayoutView)
	self.onBlankAreaEventCallback = function(ref0: OnBlankAreaEvent)
		local nativeEvent = ref0.nativeEvent
		local blankArea = math.max(nativeEvent.offsetStart, nativeEvent.offsetEnd)
		local blankEventValue = {
			blankArea = blankArea,
			offsetStart = nativeEvent.offsetStart,
			offsetEnd = nativeEvent.offsetEnd,
		}
		self:broadcastBlankEvent(blankEventValue)
		if self.props.onBlankAreaEvent then
			self.props.onBlankAreaEvent(blankEventValue)
		end
	end
end

function AutoLayoutView:broadcastBlankEvent(value: BlankAreaEvent)
	for _, listener in listeners do
		listener(value)
	end
end

function AutoLayoutView.render(self: AutoLayoutView)
	return React.createElement(
		AutoLayoutViewNativeComponent,
		Object.assign({}, self.props, {
			onBlankAreaEvent = self.onBlankAreaEventCallback,
			enableInstrumentation = #listeners > 0 and self.props.onBlankAreaEvent ~= nil,
			disableAutoLayout = self.props.disableAutoLayout,
		}),
		self.props.children
	)
end

return AutoLayoutView
