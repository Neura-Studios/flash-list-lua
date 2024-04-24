-- Based on: https://github.com/Flipkart/recyclerlistview/blob/master/docs/guides/samplecode/web/Sample1.js

local React = require("@pkg/@jsdotlua/react")
local ReactRoblox = require("@pkg/@jsdotlua/react-roblox")

local FlashList = require("../../src")

local e = React.createElement
local useMemo = React.useMemo

local function generateArray(n: number)
	local arr = table.create(n)
	for i = 1, n do
		arr[i] = i
	end
	return arr
end

local ITEMS = generateArray(500)

local containerCount = 0
local function ItemRenderer(props)
	local data = props.data

	local cellId = useMemo(function()
		containerCount += 1
		return containerCount
	end, {})

	return e("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 0, 160),
		BackgroundColor3 = Color3.new(0.9, 0.9, 0.9),
		BorderSizePixel = 0,
		Text = `Data: {data}\nCell ID: {cellId}`,
	}, {
		Border = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1,
			Color = Color3.new(0, 0, 0),
		}),
	})
end

local function StoryComponent()
	return e("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(200, 400),
        BackgroundTransparency = 1,
    }, {
        List = e(FlashList.FlashList, {
            keyExtractor = function(item)
                return `Item_{item}`
            end,
            data = ITEMS,
            estimatedItemSize = 120,
            drawDistance = 250,
            renderItem = function(data)
                return e(ItemRenderer, {
                    data = data.data,
                })
            end
        })
    })
end

return function(target: GuiObject)
	local root = ReactRoblox.createRoot(target)
	root:render(e(StoryComponent, {}))

	return function()
		root:unmount()
	end
end
