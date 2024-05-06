local React = require("@pkg/@jsdotlua/react")
local FlashList = require("../../../src")

local e = React.createElement

local CONTACTS = require("./Data")
local STICKY_HEADER_INDICES = {}
for index, item in CONTACTS do
	if type(item) == "string" then
		table.insert(STICKY_HEADER_INDICES, index)
	end
end

local function SectionHeader(props: { item: string })
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Color3.new(0.9, 0.9, 0.9),
		BorderSizePixel = 0,
	}, {
		Label = e("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.BuilderSansBold,
			Text = props.item,
			TextColor3 = Color3.new(0, 0, 0),
			TextSize = 24,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		}, {
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
			}),
		}),
	})
end

local function Row(props: {
	index: number,
	maxIndex: number,
	item: {
		userId: number,
		firstName: string,
		lastName: string,
	},
})
	local fullName = `{props.item.firstName} {props.item.lastName}`
	local thumbnailUrl = `rbxthumb://type=AvatarHeadShot&id={props.item.userId}&w=48&h=48`

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, {
		Image = e("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(36, 36),
			BackgroundColor3 = Color3.fromHSV(props.index / props.maxIndex, 0.5, 0.5),
			BorderSizePixel = 0,
			Image = thumbnailUrl,
		}, {
			UICorners = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),

			BorderStroke = e("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.new(0.223529, 0.223529, 0.223529),
				Thickness = 1,
				Transparency = 0.6,
			}),
		}),

		Label = e("TextLabel", {
			Position = UDim2.fromOffset(60, 0),
			Size = UDim2.new(1, -60, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.BuilderSans,
			Text = fullName,
			TextColor3 = Color3.new(0, 0, 0),
			TextSize = 24,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		}),
	})
end

local function ItemSeparator()
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.new(0.9, 0.9, 0.9),
		BorderSizePixel = 0,
	})
end

local function ContactsList()
	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0, 0.8),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, {
		AspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 0.46,
			AspectType = Enum.AspectType.ScaleWithParentSize,
			DominantAxis = Enum.DominantAxis.Height,
		}),

		List = e(FlashList.FlashList, {
			data = CONTACTS,
			stickyHeaderIndices = STICKY_HEADER_INDICES,
			estimatedItemSize = 72,
			-- drawDistance = 0,
			ItemSeparatorComponent = ItemSeparator :: any,
			renderItem = function(data)
				local item = data.item :: any

				if type(item) == "string" then
					return e(SectionHeader, {
						item = item,
					}) :: any
				else
					return e(Row, {
						item = item,
						index = data.index,
						maxIndex = #CONTACTS,
					})
				end
			end,
			getItemType = function(item)
				-- To achieve better performance, specify the type based on the item
				return if type(item) == "string" then "sectionHeader" else "row"
			end,
			keyExtractor = function(item)
				if type(item) == "string" then
					return `Section_{item}`
				else
					local item_ = item :: any
					return item_.id
				end
			end,
		}),
	})
end

return ContactsList
