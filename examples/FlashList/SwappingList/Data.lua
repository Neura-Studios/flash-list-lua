local HttpService = game:GetService("HttpService")

type Array<T> = { T }

export type Employee = {
	id: string,
	userId: number,
	name: string,
	role: string,
}

local FIRST_NAMES: Array<string> = {
	"John",
	"Jane",
	"Bob",
	"Alice",
	"Charlie",
	"David",
	"Eve",
	"Frank",
	"Grace",
	"Hank",
	"Ivy",
	"Jack",
	"Kathy",
	"Larry",
	"Molly",
	"Nancy",
	"Oscar",
	"Peggy",
	"Quincy",
	"Rita",
	"Steve",
	"Tina",
	"Ulysses",
	"Violet",
	"Walter",
	"Xena",
	"Yolanda",
	"Zack",
	"Zoe",
	"Zelda",
	"Zane",
}

local LAST_NAMES: Array<string> = {
	"Smith",
	"Johnson",
	"Williams",
	"Jones",
	"Brown",
	"Davis",
	"Miller",
	"Wilson",
	"Moore",
	"Taylor",
	"Anderson",
	"Thomas",
	"Jackson",
	"White",
	"Harris",
	"Martin",
	"Thompson",
	"Garcia",
	"Martinez",
	"Robinson",
	"Clark",
	"Rodriguez",
	"Lewis",
	"Lee",
	"Walker",
	"Hall",
	"Allen",
	"Young",
	"Hernandez",
	"King",
	"Wright",
	"Lopez",
	"Hill",
	"Scott",
	"Green",
	"Adams",
	"Baker",
	"Gonzalez",
	"Nelson",
	"Carter",
	"Mitchell",
	"Perez",
	"Roberts",
	"Turner",
}

local userIdOffset = 0
local rng = Random.new(os.time())

local function generateStableEmployees(
	count: number,
	rolePrefix: string,
	idPrefix: string
): Array<Employee>
	local employees: Array<Employee> = {}

	for i = 1, count do
		local id = HttpService:GenerateGUID()
		local userId = rng:NextInteger(75380482, 1000000000)
		local firstName = FIRST_NAMES[rng:NextInteger(1, #FIRST_NAMES)]
		local lastName = LAST_NAMES[rng:NextInteger(1, #LAST_NAMES)]
		local role = rolePrefix

		table.insert(employees, {
			id = id,
			userId = userId,
			name = firstName .. " " .. lastName,
			role = role,
		})

		userIdOffset = userIdOffset + 1
	end

	return employees
end

local DEPARTMENTS = {
	{
		name = "Engineering",
		employees = generateStableEmployees(30, "Engineer", "ENG"),
	},
	{
		name = "Design",
		employees = generateStableEmployees(10, "Designer", "DES"),
	},
	{
		name = "Marketing",
		employees = generateStableEmployees(50, "Marketer", "MKT"),
	},
}

return DEPARTMENTS
