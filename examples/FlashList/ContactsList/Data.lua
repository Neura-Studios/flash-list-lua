local HttpService = game:GetService("HttpService")

type Array<T> = { T }

export type Contact = {
	firstName: string,
	lastName: string,
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

-- First, build the list of contacts
local rng = Random.new(os.time())
local CONTACTS_COUNT = rng:NextInteger(150, 300)
local NAMES = {}

for i = 1, CONTACTS_COUNT do
	local firstName = FIRST_NAMES[rng:NextInteger(1, #FIRST_NAMES)]
	local lastName = LAST_NAMES[rng:NextInteger(1, #LAST_NAMES)]

	local id = HttpService:GenerateGUID()

    -- Generate a random Roblox user id for the thumbnail image
    local userId = rng:NextInteger(75380482, 1000000000)

	table.insert(NAMES, {
		id = id,
        userId = userId,
		firstName = firstName,
		lastName = lastName,
	})
end

-- Next, sort all of the names by last and first name and then group them by first letter
local CONTACTS: Array<string | Contact> = {}

table.sort(NAMES, function(a, b)
	if a.lastName == b.lastName then
		return a.firstName < b.firstName
	end
	return a.lastName < b.lastName
end)

local currentLetter = ""
for _, name in ipairs(NAMES) do
	local firstLetter = name.lastName:sub(1, 1)
	if firstLetter ~= currentLetter then
		currentLetter = firstLetter
		table.insert(CONTACTS, firstLetter)
	end
	table.insert(CONTACTS, name)
end

return CONTACTS
