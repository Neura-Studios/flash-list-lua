-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/native/auto-layout/AutoLayoutViewNativeComponentProps.ts

local React = require("@pkg/@jsdotlua/react")
type ReactNode = React.Node

export type OnBlankAreaEvent = {
	nativeEvent: {
		offsetStart: number,
		offsetEnd: number,
	},
}

type OnBlankAreaEventHandler = (event: OnBlankAreaEvent) -> ()

export type AutoLayoutViewNativeComponentProps = {
	children: ReactNode?,
	onBlankAreaEvent: OnBlankAreaEventHandler,
	enableInstrumentation: boolean,
	disableAutoLayout: boolean?,
}

return nil
