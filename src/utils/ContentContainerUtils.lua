-- ROBLOX upstream: https://github.com/shopify/flash-list/blob/da86222b74afc387c439b9f812d8184fa5e07732/utils/ContentContainerUtils.ts

local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local Boolean = LuauPolyfill.Boolean

local RecyclerListView = require("../recyclerlistview")
type Dimension = RecyclerListView.Dimension

-- TODO: Import types from their correct places
type ContentStyle = any
type OptionalContentStyle = any
type ViewStyle = any

local exports = {}

function exports.updateContentStyle(
	contentStyle: OptionalContentStyle?,
	contentContainerStyleSource: OptionalContentStyle?
): ContentStyle
	local ref = if contentContainerStyleSource ~= nil
		then contentContainerStyleSource
		else {}

	local backgroundColor = ref.backgroundColor
	local padding = ref.padding
	local paddingBottom = ref.paddingBottom
	local paddingHorizontal = ref.paddingHorizontal
	local paddingLeft = ref.paddingLeft
	local paddingRight = ref.paddingRight
	local paddingTop = ref.paddingTop
	local paddingVertical = ref.paddingVertical

	local paddingValid = Boolean.toJSBoolean(padding)
	local paddingBottomValid = Boolean.toJSBoolean(paddingBottom)
	local paddingHorizontalValid = Boolean.toJSBoolean(paddingHorizontal)
	local paddingLeftValid = Boolean.toJSBoolean(paddingLeft)
	local paddingRightValid = Boolean.toJSBoolean(paddingRight)
	local paddingTopValid = Boolean.toJSBoolean(paddingTop)
	local paddingVerticalValid = Boolean.toJSBoolean(paddingVertical)

	-- Remove later, we don't have a type for ContentStyle yet.
	assert(typeof(contentStyle) == "table", "Luau")

	contentStyle.backgroundColor = backgroundColor

	contentStyle.paddingBottom = if paddingBottomValid
		then paddingBottom
		elseif paddingVerticalValid then paddingVertical
		elseif paddingValid then padding
		else 0

	contentStyle.paddingLeft = if paddingLeftValid
		then paddingLeft
		elseif paddingHorizontalValid then paddingHorizontal
		elseif paddingValid then padding
		else 0

	contentStyle.paddingRight = if paddingRightValid
		then paddingRight
		elseif paddingHorizontalValid then paddingHorizontal
		elseif paddingValid then padding
		else 0

	contentStyle.paddingTop = if paddingTopValid
		then paddingTop
		elseif paddingVerticalValid then paddingVertical
		elseif paddingValid then padding
		else 0

	return contentStyle
end

function exports.hasUnsupportedKeysInContentContainerStyle(
	contentContainerStyleSource: ViewStyle?
): boolean
	local ref = if contentContainerStyleSource ~= nil
		then contentContainerStyleSource
		else {}

	for key in ref do
		if
			key ~= "backgroundColor"
			and key ~= "padding"
			and key ~= "paddingBottom"
			and key ~= "paddingHorizontal"
			and key ~= "paddingLeft"
			and key ~= "paddingRight"
			and key ~= "paddingTop"
			and key ~= "paddingVertical"
		then
			return true
		end
	end

	return false
end

function exports.applyContentContainerInsetForLayoutManager(
	dimension: Dimension,
	contentContainerStyle: ViewStyle?,
	horizontal: boolean?
): Dimension
	local contentStyle = exports.updateContentStyle({}, contentContainerStyle)

	if Boolean.toJSBoolean(horizontal) then
		dimension.height -= contentStyle.paddingBottom + contentStyle.paddingTop
	else
		dimension.width -= contentStyle.paddingLeft + contentStyle.paddingRight
	end

	return dimension
end

function exports.getContentContainerPadding(
	contentStyle: ContentStyle,
	horizontal: boolean?
): OptionalContentStyle
	if Boolean.toJSBoolean(horizontal) then
		return {
			paddingBottom = contentStyle.paddingBottom,
			paddingTop = contentStyle.paddingTop,
		}
	else
		return {
			paddingLeft = contentStyle.paddingLeft,
			paddingRight = contentStyle.paddingRight,
		}
	end
end

return exports
