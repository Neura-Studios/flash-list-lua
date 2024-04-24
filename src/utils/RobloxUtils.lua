local RobloxUtils = {}

local function getFillCrossSpaceStyle(horizontal: boolean)
	return {
		Size = if horizontal then UDim2.fromScale(0, 1) else UDim2.fromScale(1, 0),
		AutomaticSize = if horizontal then Enum.AutomaticSize.X else Enum.AutomaticSize.Y,
	}
end
RobloxUtils.getFillCrossSpaceStyle = getFillCrossSpaceStyle

return RobloxUtils
