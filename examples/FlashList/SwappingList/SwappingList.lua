local React = require("@pkg/@jsdotlua/react")
local FlashList = require("../../../src")

local e = React.createElement
local useState = React.useState

local DEPARTMENTS = require("./Data")

type Employee = DEPARTMENTS.Employee
type HeaderItem = { type: string }
type ListItem = Employee | HeaderItem

-- Create a single header item to be used as the sticky header
local HEADER_ITEM: HeaderItem = { type = "header" }

local function DepartmentButton(props: {
	isSelected: boolean,
	text: string,
	onClick: () -> (),
	layoutOrder: number,
})
	return e("TextButton", {
		Size = UDim2.new(0.3, -8, 0, 40),
		BackgroundColor3 = if props.isSelected
			then Color3.new(0.2, 0.6, 1)
			else Color3.new(0.8, 0.8, 0.8),
		Text = props.text,
		TextColor3 = if props.isSelected
			then Color3.new(1, 1, 1)
			else Color3.new(0, 0, 0),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 16,
		[React.Event.Activated] = props.onClick,
		LayoutOrder = props.layoutOrder,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
	})
end

local function DepartmentButtons(props: {
	currentDepartmentIndex: number,
	switchDepartment: (index: number) -> (),
})
	local forceUpdate, setForceUpdate = React.useState(0)

	React.useEffect(function()
		setForceUpdate(forceUpdate + 1)
	end, { props.currentDepartmentIndex })

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, {
		UIListLayout = e("UIListLayout", {
			Padding = UDim.new(0, 8),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		Engineering = e(DepartmentButton, {
			isSelected = props.currentDepartmentIndex == 1,
			text = "Engineering",
			onClick = function()
				props.switchDepartment(1)
			end,
			layoutOrder = 1,
		}),

		Design = e(DepartmentButton, {
			isSelected = props.currentDepartmentIndex == 2,
			text = "Design",
			onClick = function()
				props.switchDepartment(2)
			end,
			layoutOrder = 2,
		}),

		Marketing = e(DepartmentButton, {
			isSelected = props.currentDepartmentIndex == 3,
			text = "Marketing",
			onClick = function()
				props.switchDepartment(3)
			end,
			layoutOrder = 3,
		}),
	})
end

local function EmployeeRow(props: {
	item: Employee,
})
	local thumbnailUrl = `rbxthumb://type=AvatarHeadShot&id={props.item.userId}&w=48&h=48`

	local role = props.item.role
	local color = Color3.new(1, 1, 1)
	if role == "Engineer" then
		color = Color3.new(0.8, 0.9, 1)
	elseif role == "Designer" then
		color = Color3.new(1, 0.8, 0.9)
	elseif role == "Marketer" then
		color = Color3.new(0.9, 0.8, 1)
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, {
		Image = e("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(48, 48),
			BackgroundColor3 = Color3.new(0.9, 0.9, 0.9),
			BorderSizePixel = 0,
			Image = thumbnailUrl,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),

		NameLabel = e("TextLabel", {
			Position = UDim2.new(0, 72, 0, 8),
			Size = UDim2.new(1, -84, 0, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.BuilderSansBold,
			Text = props.item.name,
			TextColor3 = Color3.new(0, 0, 0),
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),

		RoleLabel = e("TextLabel", {
			Position = UDim2.new(0, 72, 0, 32),
			Size = UDim2.new(1, -84, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.BuilderSans,
			Text = props.item.role,
			TextColor3 = Color3.new(0.4, 0.4, 0.4),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
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

local function SwappingList()
	local currentDepartmentIndex, setCurrentDepartmentIndex = useState(1)

	local function switchDepartment(index: number)
		setCurrentDepartmentIndex(index)
	end

	local data: { ListItem } = { HEADER_ITEM }
	for _, employee in ipairs(DEPARTMENTS[currentDepartmentIndex].employees) do
		table.insert(data, employee :: ListItem)
	end

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

		List = e(FlashList.FlashList :: any, {
			data = data,
			estimatedItemSize = 60,
			stickyHeaderIndices = { 1 }, -- Make the first item (our header) sticky
			ItemSeparatorComponent = ItemSeparator,
			renderItem = function(info: { item: ListItem, index: number })
				if (info.item :: any).type == "header" then
					return e(DepartmentButtons, {
						currentDepartmentIndex = currentDepartmentIndex,
						switchDepartment = switchDepartment,
					})
				else
					return e(EmployeeRow :: any, {
						item = info.item :: Employee,
					})
				end
			end,
			keyExtractor = function(item: ListItem, index: number): string
				if (item :: any).type == "header" then
					return "header"
				else
					return tostring((item :: Employee).id)
				end
			end,
		}),
	})
end

return SwappingList
