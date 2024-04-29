-- Based on: https://github.com/Flipkart/recyclerlistview/blob/master/docs/guides/samplecode/web/Sample1.js

local React = require("@pkg/@jsdotlua/react")
local ReactRoblox = require("@pkg/@jsdotlua/react-roblox")

local FlashList = require("../../src")

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useMemo = React.useMemo

local ITEM_COUNT = 500

local function ItemRenderer(props)
	local data = props.data
	local index: number = props.index

	local backgroundColor = Color3.fromHSV(index / ITEM_COUNT, 0.5, 1.0)

	return e("TextLabel", {
		Size = UDim2.new(1, 0, 0, 160),
		BackgroundColor3 = backgroundColor,
		BorderSizePixel = 0,
		Text = `Item index: {index}\nCurrent time: {data.timeSinceMount}`,
		TextSize = 24,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
	}, {})
end

local function StoryComponent()
	local data, setData = useState({})

	local timeAtMount = useMemo(function()
		return os.time()
	end, {})

	useEffect(function()
		local isMounted = true
		task.spawn(function()
			while isMounted do
				local arr = table.create(ITEM_COUNT)
				for i = 1, ITEM_COUNT do
					arr[i] = {
						timeSinceMount = os.time() - timeAtMount,
					}
				end

				setData(arr)
				task.wait(1)
			end
		end)

		return function()
			isMounted = false
		end
	end, { timeAtMount })

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(400, 400),
		BackgroundTransparency = 1,
	}, {
		List = e(FlashList.FlashList, {
			data = data,
			estimatedItemSize = 160,
			numColumns = 2,
			renderItem = function(data)
				return e(ItemRenderer, {
					data = data.item,
					index = data.index,
				})
			end,
			keyExtractor = function(_item, index)
				return `Item_{index}`
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
