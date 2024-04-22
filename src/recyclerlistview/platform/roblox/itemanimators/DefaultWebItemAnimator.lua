-- ROBLOX upstream: https://github.com/Flipkart/recyclerlistview/blob/1d310dffc80d63e4303bf1213d2f6b0ce498c33a/platform/web/itemanimators/DefaultWebItemAnimator.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object

local BaseItemAnimator = require("../../../core/ItemAnimator")
type BaseItemAnimator = BaseItemAnimator.BaseItemAnimator

--[[*
 * Default implementation of RLV layout animations for web. We simply hook in transform transitions to beautifully animate all
 * shift events.
 ]]
export type DefaultWebItemAnimator = BaseItemAnimator & {
	shouldAnimateOnce: boolean,
	animateWillMount: (
		self: DefaultWebItemAnimator,
		atX: number,
		atY: number,
		itemIndex: number
	) -> Object | Array<unknown> | nil,
	animateDidMount: (
		self: DefaultWebItemAnimator,
		atX: number,
		atY: number,
		itemRef: Object | Array<unknown>,
		itemIndex: number
	) -> (),
	animateWillUpdate: (
		self: DefaultWebItemAnimator,
		fromX: number,
		fromY: number,
		toX: number,
		toY: number,
		itemRef: Object | Array<unknown>,
		itemIndex: number
	) -> (),
	animateShift: (
		self: DefaultWebItemAnimator,
		fromX: number,
		fromY: number,
		toX: number,
		toY: number,
		itemRef: Object | Array<unknown>,
		itemIndex: number
	) -> boolean,
	animateWillUnmount: (
		self: DefaultWebItemAnimator,
		atX: number,
		atY: number,
		itemRef: Object | Array<unknown>,
		itemIndex: number
	) -> (),
}
type DefaultWebItemAnimator_private = BaseItemAnimator & {
	--
	-- *** PUBLIC ***
	--
	shouldAnimateOnce: boolean,
	animateWillMount: (
		self: DefaultWebItemAnimator_private,
		atX: number,
		atY: number,
		itemIndex: number
	) -> Object | Array<unknown> | nil,
	animateDidMount: (
		self: DefaultWebItemAnimator_private,
		atX: number,
		atY: number,
		itemRef: Object | Array<unknown>,
		itemIndex: number
	) -> (),
	animateWillUpdate: (
		self: DefaultWebItemAnimator_private,
		fromX: number,
		fromY: number,
		toX: number,
		toY: number,
		itemRef: Object | Array<unknown>,
		itemIndex: number
	) -> (),
	animateShift: (
		self: DefaultWebItemAnimator_private,
		fromX: number,
		fromY: number,
		toX: number,
		toY: number,
		itemRef: Object | Array<unknown>,
		itemIndex: number
	) -> boolean,
	animateWillUnmount: (
		self: DefaultWebItemAnimator_private,
		atX: number,
		atY: number,
		itemRef: Object | Array<unknown>,
		itemIndex: number
	) -> (),
	--
	-- *** PRIVATE ***
	--
	_hasAnimatedOnce: boolean,
	_isTimerOn: boolean,
}
type DefaultWebItemAnimator_statics = { new: () -> DefaultWebItemAnimator }
local DefaultWebItemAnimator = (
	setmetatable({}, { __index = BaseItemAnimator }) :: any
) :: DefaultWebItemAnimator & DefaultWebItemAnimator_statics
local DefaultWebItemAnimator_private =
	DefaultWebItemAnimator :: DefaultWebItemAnimator_private & DefaultWebItemAnimator_statics;
(DefaultWebItemAnimator :: any).__index = DefaultWebItemAnimator

function DefaultWebItemAnimator_private.new(): DefaultWebItemAnimator
	local self = setmetatable({}, DefaultWebItemAnimator)
	return (self :: any) :: DefaultWebItemAnimator
end

function DefaultWebItemAnimator_private:animateWillMount(
	atX: number,
	atY: number,
	itemIndex: number
): Object | Array<unknown> | nil
	-- TODO: Implement Roblox animations
	return nil
end

function DefaultWebItemAnimator_private:animateDidMount(
	atX: number,
	atY: number,
	itemRef: Object | Array<unknown>,
	itemIndex: number
): ()
	-- TODO: Implement Roblox animations
end

function DefaultWebItemAnimator_private:animateWillUpdate(
	fromX: number,
	fromY: number,
	toX: number,
	toY: number,
	itemRef: Object | Array<unknown>,
	itemIndex: number
): ()
	-- TODO: Implement Roblox animations
end

function DefaultWebItemAnimator_private:animateShift(
	fromX: number,
	fromY: number,
	toX: number,
	toY: number,
	itemRef: Object | Array<unknown>,
	itemIndex: number
): boolean
	-- TODO: Implement Roblox animations
	return false
end

function DefaultWebItemAnimator_private:animateWillUnmount(
	atX: number,
	atY: number,
	itemRef: Object | Array<unknown>,
	itemIndex: number
): ()
	-- TODO: Implement Roblox animations
end

return DefaultWebItemAnimator
