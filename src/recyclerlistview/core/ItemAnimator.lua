-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/core/ItemAnimator.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object

export type ItemAnimator = {
	--Web uses transforms for moving items while react native uses left, top
	--IMPORTANT: In case of native itemRef will be a View and in web/RNW div element so, override accordingly.

	--Just an external trigger, no itemRef available, you can return initial style overrides here i.e, let's say if you want to
	--set initial opacity to 0 you can do: return { opacity: 0 };
	animateWillMount: (atX: number, atY: number, itemIndex: number) -> Object | nil,

	--Called after mount, item may already be visible when this is called. Handle accordingly
	animateDidMount: (atX: number, atY: number, itemRef: Object, itemIndex: number) -> (),

	--Will be called if RLV cell is going to re-render, note that in case of non deterministic rendering width changes from layout
	--provider do not force re-render while they do so in deterministic. A re-render will apply the new layout which may cause a
	--jitter if you're in the middle of an animation. You need to handle those scenarios
	animateWillUpdate: (
		fromX: number,
		fromY: number,
		toX: number,
		toY: number,
		itemRef: Object,
		itemIndex: number
	) -> (),

	-- If handled return true, RLV may appropriately skip the render cycle to avoid UI jitters. This callback indicates that there
	--is no update in the cell other than its position
	animateShift: (
		fromX: number,
		fromY: number,
		toX: number,
		toY: number,
		itemRef: Object,
		itemIndex: number
	) -> boolean,

	--Called before unmount
	animateWillUnmount: (
		atX: number,
		atY: number,
		itemRef: Object,
		itemIndex: number
	) -> (),
}

export type BaseItemAnimator = {
	USE_NATIVE_DRIVER: boolean,

	animateWillMount: (
		self: BaseItemAnimator,
		atX: number,
		atY: number,
		itemIndex: number
	) -> GuiObject?,
	animateDidMount: (
		self: BaseItemAnimator,
		atX: number,
		atY: number,
		itemRef: GuiObject,
		itemIndex: number
	) -> (),
	animateWillUpdate: (
		self: BaseItemAnimator,
		fromX: number,
		fromY: number,
		toX: number,
		toY: number,
		itemRef: GuiObject,
		itemIndex: number
	) -> (),
	animateShift: (
		self: BaseItemAnimator,
		fromX: number,
		fromY: number,
		toX: number,
		toY: number,
		itemRef: GuiObject,
		itemIndex: number
	) -> boolean,
	animateWillUnmount: (
		self: BaseItemAnimator,
		atX: number,
		atY: number,
		itemRef: GuiObject,
		itemIndex: number
	) -> (),
}
type BaseItemAnimator_statics = { new: () -> BaseItemAnimator }

local BaseItemAnimator = {} :: BaseItemAnimator & BaseItemAnimator_statics;
(BaseItemAnimator :: any).__index = BaseItemAnimator
BaseItemAnimator.USE_NATIVE_DRIVER = false

function BaseItemAnimator.new(): BaseItemAnimator
	local self = setmetatable({}, BaseItemAnimator)
	return (self :: any) :: BaseItemAnimator
end

function BaseItemAnimator:animateWillMount(
	atX: number,
	atY: number,
	itemIndex: number
): GuiObject?
	return nil
end

function BaseItemAnimator:animateDidMount(
	atX: number,
	atY: number,
	itemRef: GuiObject,
	itemIndex: number
): ()
	--no need
end

function BaseItemAnimator:animateWillUpdate(
	fromX: number,
	fromY: number,
	toX: number,
	toY: number,
	itemRef: GuiObject,
	itemIndex: number
): ()
	--no need
end

function BaseItemAnimator:animateShift(
	fromX: number,
	fromY: number,
	toX: number,
	toY: number,
	itemRef: GuiObject,
	itemIndex: number
): boolean
	return false
end

function BaseItemAnimator:animateWillUnmount(
	atX: number,
	atY: number,
	itemRef: GuiObject,
	itemIndex: number
): ()
	--no need
end

return BaseItemAnimator
