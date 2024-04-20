-- Based on: https://github.com/Flipkart/recyclerlistview/blob/master/docs/guides/samplecode/web/Sample1.js

local React = require("@pkg/@jsdotlua/react")
local ReactRoblox = require("@pkg/@jsdotlua/react-roblox")

local RecyclerListView = require("../src/init")

local e = React.createElement
local useMemo = React.useMemo
local ViewTypes = {
	FULL = 0,
	HALF_LEFT = 1,
	HALF_RIGHT = 2,
}

local function generateArray(n: number)
	local arr = table.create(n)
	for i = 1, n do
		arr[i] = i
	end
	return arr
end

local containerCount = 0

local function CellContainer(props)
	local data = props.data

	local cellId = useMemo(function()
		containerCount += 1
		return containerCount
	end, {})

	return e("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0.9, 0.9, 0.9),
		BorderSizePixel = 0,
		Text = `Data: {data}\nCell ID: {cellId}`
	}, {
		Border = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1,
			Color = Color3.new(0, 0, 0),
		})
	})
end

local function StoryComponent()
	local width = 200

	-- Create the data provider and provide method which takes in two rows of
	-- data and return if those two are different or not.
	local dataProvider = useMemo(function()
		local dataProvider = RecyclerListView.DataProvider.new(function(r1, r2)
			return r1 ~= r2
		end)

		return dataProvider:cloneWithRows(generateArray(1000))
	end, {})

	-- Create the layout provider
	-- First method: Given an index return the type of item e.g ListItemType1,
	--  ListItemType2 in case you have variety of items in your list/grid
	--
	-- Second: Given a type and object set the height and width for that type
	--  on given object
	--
	-- If you need data based check you can access your data provider here
	-- You'll need data in most cases, we don't provide it by default to enable
	-- things like data virtualization in the future
	--
	-- NOTE: For complex lists LayoutProvider will also be complex it would
	-- then make sense to move it to a different file
	local layoutProvider = useMemo(function()
		return RecyclerListView.LayoutProvider.new(function(index)
			if index % 3 == 0 then
				return ViewTypes.FULL
			elseif index % 3 == 1 then
				return ViewTypes.HALF_LEFT
			else
				return ViewTypes.HALF_RIGHT
			end
		end, function(type, dim)
			if type == ViewTypes.FULL then
				dim.width = width
				dim.height = 140
			elseif type == ViewTypes.HALF_LEFT then
				dim.width = width / 2 - 0.0001
				dim.height = 160
			else
				dim.width = width / 2
				dim.height = 160
			end
		end)
	end, {})

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, width, 0.5, 0),
		BackgroundColor3 = Color3.new(0.6, 0.6, 0.6),
		BackgroundTransparency = 1,
	}, {
		List = e(RecyclerListView.RecyclerListView, {
			layoutProvider = layoutProvider,
			dataProvider = dataProvider,
			scrollViewProps = {
				style = {
					ScrollBarThickness = 12,
				}
			},
			rowRenderer = function(type, data)
				return e(CellContainer, {
					type = type,
					data = data,
				})
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
