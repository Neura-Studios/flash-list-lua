-- Based on: https://github.com/Flipkart/recyclerlistview/blob/master/docs/guides/samplecode/web/Sample1.js

local React = require("@pkg/@jsdotlua/react")
local ReactRoblox = require("@pkg/@jsdotlua/react-roblox")

local FlashList = require("../../src")

local e = React.createElement
local useMemo = React.useMemo
local useRef = React.useRef

local function generateArray(n: number)
	local arr = table.create(n)
	for i = 1, n do
		arr[i] = i
	end
	return arr
end

local ITEM_COUNT = 500
local ITEMS = generateArray(ITEM_COUNT)

local function ItemRenderer(props)
	local data = props.data
	local index: number = props.index

	local backgroundColor = Color3.fromHSV(index / ITEM_COUNT, 0.5, 1.0)

	return e("TextLabel", {
		Size = UDim2.new(1, 0, 0, 160),
		BackgroundColor3 = backgroundColor,
		BorderSizePixel = 0,
		Text = `Data: {data}`,
		TextSize = 24,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
	}, {})
end

local function StoryComponent()
	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(400, 400),
		BackgroundTransparency = 1,
	}, {
		List = e(FlashList.FlashList, {
			data = ITEMS,
			estimatedItemSize = 160,
			numColumns = 2,
			renderItem = function(data)
				return e(ItemRenderer, {
					data = data.item,
					index = data.index,
				})
			end,
			keyExtractor = function(item)
				return `Item_{item}`
			end,
		}),
	})
end

return function(target: GuiObject)
	local root = ReactRoblox.createRoot(target)
	root:render(e(StoryComponent, {}))

	return function()
		root:unmount()
	end
end
