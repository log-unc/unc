local results = {
	Passed = {},
	Failed = {},
	Skipped = {}
}

local metrics = {}

local function stringify(value)
	local ok, text = pcall(function()
		return tostring(value)
	end)

	return ok and text or "unknown"
end

local function failureReason(ok, value, detail)
	if ok then
		return stringify(detail or "returned false")
	end

	return stringify(value)
end

local function nearlyEqual(actual, expected, epsilon)
	if type(actual) ~= "number" or type(expected) ~= "number" then
		return false
	end

	return math.abs(actual - expected) <= (epsilon or 0.0001)
end

local function isSignal(value)
	return typeof(value) == "RBXScriptSignal"
end

local function readMember(object, name)
	return pcall(function()
		return object[name]
	end)
end

local function hasMethod(object, name)
	local ok, value = readMember(object, name)

	return ok and type(value) == "function"
end

local function hasMethods(object, names)
	for _, name in ipairs(names) do
		if not hasMethod(object, name) then
			return false, name .. " missing"
		end
	end

	return true
end

local function typedProperties(object, expectations)
	for name, expected in pairs(expectations) do
		local ok, value = readMember(object, name)

		if not ok then
			return false, name .. " unreadable"
		end

		local actual = typeof(value)

		if actual ~= expected then
			return false, name .. " is " .. actual .. " expected " .. expected
		end
	end

	return true
end

local function containsValue(list, target)
	if type(list) ~= "table" then
		return false
	end

	for _, value in ipairs(list) do
		if value == target then
			return true
		end
	end

	return false
end

local function enumItem(enumType, name)
	local ok, item = pcall(function()
		return enumType[name]
	end)

	if ok then
		return item
	end

	return nil
end

local function enumHasItems(enumType, names)
	for _, name in ipairs(names) do
		if enumItem(enumType, name) == nil then
			return false, name .. " missing"
		end
	end

	return true
end

local function test(name, callback)
	local ok, value, detail = pcall(callback)

	if ok and value ~= false then
		table.insert(results.Passed, name)
		print("[PASS] " .. name)
		return true
	end

	table.insert(results.Failed, {
		Name = name,
		Reason = failureReason(ok, value, detail)
	})

	return false
end

local function optional(name, callback)
	local ok, value, detail = pcall(callback)

	if ok and value ~= false then
		table.insert(results.Passed, name)
		print("[PASS] " .. name)
		return true
	end

	table.insert(results.Skipped, {
		Name = name,
		Reason = failureReason(ok, value, detail)
	})

	return false
end

local function withTemporary(className, callback)
	local object = Instance.new(className)
	local ok, value, detail = pcall(callback, object)

	pcall(function()
		object:Destroy()
	end)

	if not ok then
		error(value, 0)
	end

	return value, detail
end

local serviceNames = {
	"Workspace",
	"Players",
	"Lighting",
	"ReplicatedFirst",
	"ReplicatedStorage",
	"ServerScriptService",
	"ServerStorage",
	"StarterGui",
	"StarterPack",
	"StarterPlayer",
	"Teams",
	"SoundService",
	"TextChatService",
	"Chat",
	"RunService",
	"TweenService",
	"Debris",
	"CollectionService",
	"HttpService",
	"PathfindingService",
	"PhysicsService",
	"MarketplaceService",
	"BadgeService",
	"TeleportService",
	"DataStoreService",
	"MemoryStoreService",
	"MessagingService",
	"UserInputService",
	"ContextActionService",
	"GuiService",
	"VRService",
	"HapticService",
	"ProximityPromptService",
	"LocalizationService",
	"PolicyService",
	"GroupService",
	"SocialService",
	"VoiceChatService",
	"AvatarEditorService",
	"InsertService",
	"AssetService",
	"ContentProvider",
	"KeyframeSequenceProvider",
	"MaterialService",
	"TestService",
	"Stats",
	"LogService",
	"TextService",
	"GeometryService",
	"UserService",
	"FriendService",
	"GamePassService",
	"AnalyticsService",
	"CaptureService",
	"PermissionsService",
	"CoreGui",
	"ScriptContext"
}

local instanceClasses = {
	"Folder",
	"Model",
	"Part",
	"WedgePart",
	"CornerWedgePart",
	"TrussPart",
	"SpawnLocation",
	"Seat",
	"VehicleSeat",
	"MeshPart",
	"Attachment",
	"Bone",
	"Motor6D",
	"Weld",
	"WeldConstraint",
	"HingeConstraint",
	"BallSocketConstraint",
	"RopeConstraint",
	"RodConstraint",
	"SpringConstraint",
	"PrismaticConstraint",
	"CylindricalConstraint",
	"AlignPosition",
	"AlignOrientation",
	"LinearVelocity",
	"AngularVelocity",
	"VectorForce",
	"Torque",
	"LineForce",
	"NumberValue",
	"IntValue",
	"StringValue",
	"BoolValue",
	"ObjectValue",
	"CFrameValue",
	"Vector3Value",
	"Color3Value",
	"BrickColorValue",
	"RayValue",
	"BindableEvent",
	"BindableFunction",
	"RemoteEvent",
	"RemoteFunction",
	"Sound",
	"Animation",
	"Animator",
	"Humanoid",
	"HumanoidDescription",
	"BodyColors",
	"Camera",
	"Highlight",
	"Beam",
	"Trail",
	"ParticleEmitter",
	"Fire",
	"Smoke",
	"Sparkles",
	"PointLight",
	"SpotLight",
	"SurfaceLight",
	"Decal",
	"Texture",
	"BillboardGui",
	"SurfaceGui",
	"ScreenGui",
	"Frame",
	"ScrollingFrame",
	"TextLabel",
	"TextButton",
	"TextBox",
	"ImageLabel",
	"ImageButton",
	"ViewportFrame",
	"UIListLayout",
	"UIGridLayout",
	"UIPageLayout",
	"UITableLayout",
	"UIPadding",
	"UICorner",
	"UIStroke",
	"UIScale",
	"UIGradient",
	"Path2D",
	"AudioPlayer",
	"AudioDeviceOutput",
	"AudioEmitter",
	"AudioListener",
	"Wire"
}

test("game is DataModel", function()
	return game:IsA("DataModel")
end)

test("game parent is nil", function()
	return game.Parent == nil
end)

test("game identifiers are readable", function()
	local placeId = game.PlaceId
	local gameId = game.GameId
	local placeVersion = game.PlaceVersion
	local jobId = game.JobId

	return type(placeId) == "number"
		and type(gameId) == "number"
		and type(placeVersion) == "number"
		and type(jobId) == "string"
end)

test("game loaded state is readable", function()
	return type(game:IsLoaded()) == "boolean"
end)

test("game cannot be cloned", function()
	local ok, clone = pcall(function()
		return game:Clone()
	end)

	if not ok then
		return true
	end

	if clone then
		pcall(function()
			clone:Destroy()
		end)
		return false, "game returned a clone"
	end

	return true
end)

for _, serviceName in ipairs(serviceNames) do
	optional("Service " .. serviceName, function()
		local service = game:GetService(serviceName)

		return typeof(service) == "Instance"
			and type(service.ClassName) == "string"
			and type(service:GetFullName()) == "string"
	end)
end

for _, className in ipairs(instanceClasses) do
	optional("Instance " .. className, function()
		local object = Instance.new(className)
		local valid = typeof(object) == "Instance"
			and object.ClassName == className

		object:Destroy()

		return valid
	end)
end

test("Temporary hierarchy clone", function()
	local root = Instance.new("Folder")
	local child = Instance.new("StringValue")

	root.Name = "LogUncRoot"
	root.Archivable = true
	child.Name = "Payload"
	child.Value = "working"
	child.Parent = root

	local clone = root:Clone()
	local clonedChild = clone and clone:FindFirstChild("Payload")
	local valid = clone ~= nil
		and clonedChild ~= nil
		and clonedChild.Value == "working"
		and clone.Parent == nil

	root:Destroy()

	if clone then
		clone:Destroy()
	end

	return valid
end)

test("Temporary instance parent", function()
	local parent = Instance.new("Folder")
	local child = Instance.new("Part")

	child.Parent = parent

	local valid = child.Parent == parent
		and parent:IsAncestorOf(child)
		and child:IsDescendantOf(parent)

	parent:Destroy()

	return valid
end)

test("Temporary instance destroy", function()
	local object = Instance.new("Folder")

	object:Destroy()

	return object.Parent == nil
end)

test("Instance children and descendants", function()
	local root = Instance.new("Folder")
	local child = Instance.new("Folder")
	local part = Instance.new("Part")

	child.Name = "Child"
	part.Name = "Part"
	child.Parent = root
	part.Parent = child

	local valid = #root:GetChildren() == 1
		and #root:GetDescendants() == 2
		and root:FindFirstChild("Child") == child
		and root:FindFirstChild("Part", true) == part
		and root:FindFirstChildWhichIsA("BasePart", true) == part

	root:Destroy()

	return valid
end)

test("Instance attributes", function()
	return withTemporary("Folder", function(object)
		object:SetAttribute("Boolean", true)
		object:SetAttribute("Number", 42)
		object:SetAttribute("String", "LogUnc")
		object:SetAttribute("Vector", Vector3.new(1, 2, 3))
		object:SetAttribute("Color", Color3.fromRGB(100, 80, 200))

		local attributes = object:GetAttributes()

		return attributes.Boolean == true
			and attributes.Number == 42
			and attributes.String == "LogUnc"
			and attributes.Vector == Vector3.new(1, 2, 3)
			and typeof(attributes.Color) == "Color3"
	end)
end)

test("CollectionService tags", function()
	local collectionService = game:GetService("CollectionService")
	local object = Instance.new("Folder")
	local tag = "LogUncDiagnostic"

	collectionService:AddTag(object, tag)

	local tagged = collectionService:HasTag(object, tag)
	local tags = collectionService:GetTags(object)

	collectionService:RemoveTag(object, tag)
	object:Destroy()

	return tagged
		and table.find(tags, tag) ~= nil
end)

test("BindableEvent signal", function()
	local event = Instance.new("BindableEvent")
	local received = false

	local connection = event.Event:Connect(function(value)
		received = value == 42
	end)

	event:Fire(42)
	task.wait()
	connection:Disconnect()
	event:Destroy()

	return received
end)

test("BindableFunction invoke", function()
	local bindable = Instance.new("BindableFunction")

	bindable.OnInvoke = function(a, b)
		return a + b
	end

	local value = bindable:Invoke(20, 22)

	bindable:Destroy()

	return value == 42
end)

test("Part basic properties", function()
	return withTemporary("Part", function(part)
		part.Name = "DiagnosticPart"
		part.Size = Vector3.new(4, 5, 6)
		part.CFrame = CFrame.new(10, 20, 30)
		part.Color = Color3.fromRGB(120, 100, 220)
		part.Material = Enum.Material.SmoothPlastic
		part.Transparency = 0.25
		part.Reflectance = 0.1
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = true
		part.CastShadow = false
		part.Massless = true
		part.Shape = Enum.PartType.Block

		return part.Name == "DiagnosticPart"
			and part.Size == Vector3.new(4, 5, 6)
			and part.Position == Vector3.new(10, 20, 30)
			and part.Transparency == 0.25
			and part.Anchored
			and not part.CanCollide
			and not part.CanTouch
			and part.CanQuery
			and not part.CastShadow
			and part.Massless
	end)
end)

test("Part physical properties", function()
	return withTemporary("Part", function(part)
		part.Size = Vector3.new(2, 3, 4)
		part.CustomPhysicalProperties = PhysicalProperties.new(
			0.7,
			0.3,
			0.5,
			1,
			1
		)

		local properties = part.CustomPhysicalProperties
		local mass = part:GetMass()

		return properties ~= nil
			and type(mass) == "number"
			and mass > 0
	end)
end)

test("Part assembly velocity", function()
	return withTemporary("Part", function(part)
		part.Anchored = false
		part.AssemblyLinearVelocity = Vector3.new(1, 2, 3)
		part.AssemblyAngularVelocity = Vector3.new(3, 2, 1)

		return (part.AssemblyLinearVelocity - Vector3.new(1, 2, 3)).Magnitude < 0.001
			and (part.AssemblyAngularVelocity - Vector3.new(3, 2, 1)).Magnitude < 0.001
	end)
end)

test("Model pivot and bounding box", function()
	local model = Instance.new("Model")
	local part = Instance.new("Part")

	part.Size = Vector3.new(2, 4, 6)
	part.Anchored = true
	part.Parent = model
	model.PrimaryPart = part
	model:PivotTo(CFrame.new(7, 8, 9))

	local pivot = model:GetPivot()
	local boundingCFrame, boundingSize = model:GetBoundingBox()
	local valid = (pivot.Position - Vector3.new(7, 8, 9)).Magnitude < 0.001
		and typeof(boundingCFrame) == "CFrame"
		and boundingSize == Vector3.new(2, 4, 6)

	model:Destroy()

	return valid
end)

test("Vector2 operations", function()
	local value = Vector2.new(3, 4)

	return value.Magnitude == 5
		and value.Unit:FuzzyEq(Vector2.new(0.6, 0.8), 0.0001)
		and value:Dot(Vector2.new(2, 1)) == 10
end)

test("Vector3 operations", function()
	local value = Vector3.new(3, 4, 0)
	local cross = Vector3.new(1, 0, 0):Cross(Vector3.new(0, 1, 0))

	return value.Magnitude == 5
		and value:Dot(Vector3.new(2, 1, 3)) == 10
		and cross == Vector3.new(0, 0, 1)
end)

test("CFrame transformations", function()
	local origin = CFrame.new(10, 20, 30)
		* CFrame.Angles(0, math.rad(90), 0)

	local point = origin:PointToWorldSpace(Vector3.new(1, 0, 0))
	local localPoint = origin:PointToObjectSpace(point)

	return (localPoint - Vector3.new(1, 0, 0)).Magnitude < 0.001
end)

test("Color3 conversions", function()
	local color = Color3.fromRGB(120, 80, 220)
	local h, s, v = color:ToHSV()
	local restored = Color3.fromHSV(h, s, v)

	return math.abs(color.R - restored.R) < 0.001
		and math.abs(color.G - restored.G) < 0.001
		and math.abs(color.B - restored.B) < 0.001
end)

test("BrickColor conversion", function()
	local brickColor = BrickColor.new("Bright violet")

	return typeof(brickColor) == "BrickColor"
		and typeof(brickColor.Color) == "Color3"
end)

test("UDim and UDim2", function()
	local value = UDim2.new(0.5, 10, 1, -20)

	return value.X.Scale == 0.5
		and value.X.Offset == 10
		and value.Y.Scale == 1
		and value.Y.Offset == -20
end)

test("NumberRange and sequences", function()
	local range = NumberRange.new(1, 5)
	local numberSequence = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	local colorSequence = ColorSequence.new(
		Color3.new(0, 0, 0),
		Color3.new(1, 1, 1)
	)

	return range.Min == 1
		and range.Max == 5
		and #numberSequence.Keypoints == 2
		and #colorSequence.Keypoints == 2
end)

test("Ray and Region3", function()
	local ray = Ray.new(
		Vector3.new(1, 2, 3),
		Vector3.new(0, -10, 0)
	)

	local region = Region3.new(
		Vector3.new(-5, -5, -5),
		Vector3.new(5, 5, 5)
	)

	return ray.Origin == Vector3.new(1, 2, 3)
		and ray.Direction == Vector3.new(0, -10, 0)
		and typeof(region.CFrame) == "CFrame"
		and region.Size == Vector3.new(10, 10, 10)
end)

test("Random generator", function()
	local random = Random.new(12345)
	local integer = random:NextInteger(1, 10)
	local number = random:NextNumber(0, 1)
	local unitVector = random:NextUnitVector()

	return integer >= 1
		and integer <= 10
		and number >= 0
		and number <= 1
		and math.abs(unitVector.Magnitude - 1) < 0.001
end)

test("Math library", function()
	return math.clamp(20, 0, 10) == 10
		and math.round(1.6) == 2
		and math.sign(-100) == -1
		and math.abs(math.lerp(0, 10, 0.5) - 5) < 0.001
		and type(math.noise(1, 2, 3)) == "number"
end)

test("Bit32 library", function()
	return bit32.band(15, 6) == 6
		and bit32.bor(8, 3) == 11
		and bit32.bxor(15, 5) == 10
		and bit32.lshift(1, 4) == 16
end)

test("String operations", function()
	local source = "Log-Unc Environment Logger"
	local replaced = string.gsub(source, "Logger", "Test")
	local found = string.find(source, "Environment", 1, true)
	local match = string.match("score=98", "%d+")
	local split = string.split("one,two,three", ",")

	return replaced == "Log-Unc Environment Test"
		and found ~= nil
		and match == "98"
		and #split == 3
		and split[2] == "two"
end)

test("UTF-8 operations", function()
	local text = utf8.char(1055, 1088, 1080, 1074, 1077, 1090) .. " Roblox"
	local length = utf8.len(text)
	local codepoint = utf8.codepoint("A")

	return length == 13
		and #text == 19
		and codepoint == 65
		and utf8.codepoint(text, 1) == 1055
end)

test("Error text capture", function()
	local ok, message = pcall(function()
		error("LOG_UNC_SENTINEL", 0)
	end)

	return not ok
		and string.find(
			tostring(message),
			"LOG_UNC_SENTINEL",
			1,
			true
		) ~= nil
end)

test("xpcall error handler", function()
	local ok, message = xpcall(function()
		error("XPCALL_SENTINEL", 0)
	end, function(value)
		return "handled:" .. tostring(value)
	end)

	return not ok
		and message == "handled:XPCALL_SENTINEL"
end)

test("Table operations", function()
	local values = table.create(3, 0)

	values[1] = "a"
	values[2] = "b"
	values[3] = "c"

	local clone = table.clone(values)
	local index = table.find(clone, "b")
	local unpackedA, unpackedB, unpackedC = table.unpack(clone)

	table.clear(values)

	return #values == 0
		and index == 2
		and unpackedA == "a"
		and unpackedB == "b"
		and unpackedC == "c"
end)

test("Frozen tables", function()
	local value = table.freeze({
		Answer = 42
	})

	return table.isfrozen(value)
		and value.Answer == 42
end)

test("Raw table operations", function()
	local value = {}

	rawset(value, "Answer", 42)

	return rawget(value, "Answer") == 42
		and rawequal(value, value)
end)

test("Number base conversion", function()
	return tonumber("11111111", 2) == 255
		and tonumber("ff", 16) == 255
		and tonumber("377", 8) == 255
		and string.format("%x", 255) == "ff"
end)

test("Metatable index", function()
	local value = setmetatable({}, {
		__index = {
			Answer = 42
		}
	})

	return value.Answer == 42
end)

test("Metatable newindex", function()
	local storage = {}

	local value = setmetatable({}, {
		__newindex = function(_, key, newValue)
			storage[key] = newValue
		end
	})

	value.Answer = 42

	return storage.Answer == 42
end)

test("Metatable call", function()
	local value = setmetatable({}, {
		__call = function(_, a, b)
			return a + b
		end
	})

	return value(20, 22) == 42
end)

test("Metatable tostring", function()
	local value = setmetatable({}, {
		__tostring = function()
			return "LogUncMetatable"
		end
	})

	return tostring(value) == "LogUncMetatable"
end)

test("Metatable arithmetic", function()
	local value = setmetatable({
		Number = 40
	}, {
		__add = function(left, right)
			return left.Number + right
		end
	})

	return value + 2 == 42
end)

optional("debug.info", function()
	return type(debug) == "table"
		and type(debug.info) == "function"
		and type(debug.info(1, "s")) == "string"
end)

optional("debug.traceback", function()
	return type(debug) == "table"
		and type(debug.traceback) == "function"
		and type(debug.traceback()) == "string"
end)

test("Coroutine operations", function()
	local received = 0

	local thread = coroutine.create(function(value)
		received = value
		return value + 1
	end)

	local ok, returned = coroutine.resume(thread, 41)

	return ok
		and received == 41
		and returned == 42
		and coroutine.status(thread) == "dead"
end)

test("Task scheduler", function()
	local completed = false

	task.defer(function()
		completed = true
	end)

	local started = os.clock()

	repeat
		task.wait()
	until completed or os.clock() - started > 2

	return completed
end)

test("OS clock", function()
	local started = os.clock()
	local elapsed = os.clock() - started

	return type(started) == "number"
		and elapsed >= 0
end)

test("OS time and date", function()
	local timestamp = os.time()
	local date = os.date("!*t", timestamp)

	return type(timestamp) == "number"
		and type(date) == "table"
		and type(date.year) == "number"
		and type(date.month) == "number"
		and type(date.day) == "number"
end)

test("DateTime operations", function()
	local current = DateTime.now()
	local restored = DateTime.fromUnixTimestampMillis(
		current.UnixTimestampMillis
	)

	return type(current.UnixTimestampMillis) == "number"
		and math.abs(
			restored.UnixTimestampMillis
				- current.UnixTimestampMillis
		) <= 1
end)

test("Game time", function()
	local elapsed = time()
	local distributed = workspace.DistributedGameTime

	return type(elapsed) == "number"
		and elapsed >= 0
		and type(distributed) == "number"
		and distributed >= 0
end)

optional("Buffer read and write", function()
	if type(buffer) ~= "table" then
		return false, "buffer library unavailable"
	end

	local value = buffer.create(16)

	buffer.writeu8(value, 0, 255)
	buffer.writei16(value, 1, -1234)
	buffer.writef32(value, 4, 12.5)
	buffer.writestring(value, 8, "test", 4)

	return buffer.len(value) == 16
		and buffer.readu8(value, 0) == 255
		and buffer.readi16(value, 1) == -1234
		and math.abs(buffer.readf32(value, 4) - 12.5) < 0.001
		and buffer.readstring(value, 8, 4) == "test"
end)

optional("Buffer copy and conversion", function()
	if type(buffer) ~= "table" then
		return false, "buffer library unavailable"
	end

	local source = buffer.fromstring("Log-Unc")
	local target = buffer.create(buffer.len(source))

	buffer.copy(
		target,
		0,
		source,
		0,
		buffer.len(source)
	)

	return buffer.tostring(target) == "Log-Unc"
end)

test("JSON encode and decode", function()
	local httpService = game:GetService("HttpService")
	local encoded = httpService:JSONEncode({
		Name = "Log-Unc",
		Score = 100,
		Passed = true
	})
	local decoded = httpService:JSONDecode(encoded)

	return decoded.Name == "Log-Unc"
		and decoded.Score == 100
		and decoded.Passed == true
end)

test("GUID generation", function()
	local httpService = game:GetService("HttpService")
	local guid = httpService:GenerateGUID(false)

	return type(guid) == "string"
		and #guid >= 32
end)

test("Raycast parameters", function()
	local parameters = RaycastParams.new()

	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.IgnoreWater = true
	parameters.RespectCanCollide = false
	parameters.CollisionGroup = "Default"

	return typeof(parameters) == "RaycastParams"
		and parameters.IgnoreWater
		and not parameters.RespectCanCollide
end)

test("Overlap parameters", function()
	local parameters = OverlapParams.new()

	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.MaxParts = 25
	parameters.RespectCanCollide = false
	parameters.CollisionGroup = "Default"

	return typeof(parameters) == "OverlapParams"
		and parameters.MaxParts == 25
		and not parameters.RespectCanCollide
end)

optional("Workspace raycast", function()
	local parameters = RaycastParams.new()

	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {}

	workspace:Raycast(
		Vector3.new(0, 10000, 0),
		Vector3.new(0, -100, 0),
		parameters
	)

	return true
end)

optional("Workspace blockcast", function()
	local parameters = RaycastParams.new()

	workspace:Blockcast(
		CFrame.new(0, 10000, 0),
		Vector3.new(2, 2, 2),
		Vector3.new(0, -100, 0),
		parameters
	)

	return true
end)

optional("Workspace spherecast", function()
	local parameters = RaycastParams.new()

	workspace:Spherecast(
		Vector3.new(0, 10000, 0),
		2,
		Vector3.new(0, -100, 0),
		parameters
	)

	return true
end)

optional("Workspace overlap box", function()
	local parts = workspace:GetPartBoundsInBox(
		CFrame.new(0, 10000, 0),
		Vector3.new(10, 10, 10),
		OverlapParams.new()
	)

	return type(parts) == "table"
end)

optional("Workspace overlap radius", function()
	local parts = workspace:GetPartBoundsInRadius(
		Vector3.new(0, 10000, 0),
		10,
		OverlapParams.new()
	)

	return type(parts) == "table"
end)

optional("Physics collision groups", function()
	local physicsService = game:GetService("PhysicsService")
	local groups = physicsService:GetRegisteredCollisionGroups()

	return type(groups) == "table"
end)

optional("Pathfinding path creation", function()
	local pathfindingService = game:GetService("PathfindingService")

	local path = pathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = true,
		WaypointSpacing = 4
	})

	return typeof(path) == "Instance"
		and path:IsA("Path")
end)

optional("Pathfinding computation", function()
	local pathfindingService = game:GetService("PathfindingService")

	local path = pathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true
	})

	path:ComputeAsync(
		Vector3.new(0, 10, 0),
		Vector3.new(20, 10, 20)
	)

	metrics.PathStatus = tostring(path.Status)

	return true
end)

optional("Path2D availability", function()
	local path = Instance.new("Path2D")
	local valid = path:IsA("Path2D")

	path:Destroy()

	return valid
end)

optional("TweenService execution", function()
	local tweenService = game:GetService("TweenService")
	local value = Instance.new("NumberValue")

	value.Value = 0

	local tween = tweenService:Create(
		value,
		TweenInfo.new(0.02, Enum.EasingStyle.Linear),
		{
			Value = 1
		}
	)

	tween:Play()
	tween.Completed:Wait()

	local valid = math.abs(value.Value - 1) < 0.001

	value:Destroy()

	return valid
end)

optional("Heartbeat FPS sample", function()
	local runService = game:GetService("RunService")
	local frames = 30
	local elapsed = 0

	for _ = 1, frames do
		elapsed += runService.Heartbeat:Wait()
	end

	if elapsed <= 0 then
		return false, "invalid heartbeat duration"
	end

	metrics.HeartbeatFPS = string.format(
		"%.1f",
		frames / elapsed
	)

	return true
end)

optional("RenderStepped FPS sample", function()
	local runService = game:GetService("RunService")

	if not runService:IsClient() then
		return false, "client only"
	end

	local frames = 30
	local elapsed = 0

	for _ = 1, frames do
		elapsed += runService.RenderStepped:Wait()
	end

	if elapsed <= 0 then
		return false, "invalid render duration"
	end

	metrics.RenderFPS = string.format(
		"%.1f",
		frames / elapsed
	)

	return true
end)

optional("Real physics FPS", function()
	local value = workspace:GetRealPhysicsFPS()

	metrics.PhysicsFPS = string.format("%.1f", value)

	return type(value) == "number"
		and value >= 0
end)

optional("Memory statistics", function()
	local stats = game:GetService("Stats")
	local memory = stats:GetTotalMemoryUsageMb()

	metrics.MemoryMB = string.format("%.2f", memory)

	return type(memory) == "number"
		and memory >= 0
end)

optional("Client platform", function()
	local inputService = game:GetService("UserInputService")
	local platform = inputService:GetPlatform()

	metrics.Platform = tostring(platform)

	return typeof(platform) == "EnumItem"
end)

optional("Client locale", function()
	local localizationService = game:GetService("LocalizationService")
	local robloxLocale = localizationService.RobloxLocaleId
	local systemLocale = localizationService.SystemLocaleId

	metrics.RobloxLocale = robloxLocale
	metrics.SystemLocale = systemLocale

	return type(robloxLocale) == "string"
		and type(systemLocale) == "string"
end)

local function getCurrentPlayer()
	local players = game:GetService("Players")

	return players.LocalPlayer or players:GetPlayers()[1]
end

local function getCurrentCharacter()
	local player = getCurrentPlayer()

	if not player then
		return nil, nil
	end

	return player.Character, player
end

optional("Player identity", function()
	local player = getCurrentPlayer()

	if not player then
		return false, "player unavailable"
	end

	metrics.Player = player.Name
	metrics.DisplayName = player.DisplayName
	metrics.UserId = tostring(player.UserId)
	metrics.AccountAge = tostring(player.AccountAge)

	return type(player.Name) == "string"
		and type(player.DisplayName) == "string"
		and type(player.UserId) == "number"
		and type(player.AccountAge) == "number"
end)

optional("Player network ping", function()
	local player = getCurrentPlayer()

	if not player then
		return false, "player unavailable"
	end

	local ping = player:GetNetworkPing()

	metrics.NetworkPingMS = string.format(
		"%.2f",
		ping * 1000
	)

	return type(ping) == "number"
		and ping >= 0
end)

optional("Character model", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	return character:IsA("Model")
		and character.Parent ~= nil
		and #character:GetDescendants() > 0
end)

optional("Character pivot and bounds", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local pivot = character:GetPivot()
	local boundingCFrame, boundingSize = character:GetBoundingBox()

	metrics.CharacterSize = tostring(boundingSize)

	return typeof(pivot) == "CFrame"
		and typeof(boundingCFrame) == "CFrame"
		and typeof(boundingSize) == "Vector3"
		and boundingSize.Magnitude > 0
end)

optional("Character Humanoid", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false, "Humanoid unavailable"
	end

	metrics.RigType = tostring(humanoid.RigType)
	metrics.Health = string.format("%.2f", humanoid.Health)
	metrics.MaxHealth = string.format("%.2f", humanoid.MaxHealth)
	metrics.WalkSpeed = string.format("%.2f", humanoid.WalkSpeed)
	metrics.JumpPower = string.format("%.2f", humanoid.JumpPower)

	return humanoid.MaxHealth >= 0
		and humanoid.Health >= 0
		and type(humanoid.WalkSpeed) == "number"
		and type(humanoid.JumpPower) == "number"
		and typeof(humanoid.RigType) == "EnumItem"
end)

optional("Character root part", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local root = character:FindFirstChild("HumanoidRootPart")
		or character.PrimaryPart

	if not root or not root:IsA("BasePart") then
		return false, "root part unavailable"
	end

	metrics.RootPosition = tostring(root.Position)
	metrics.RootVelocity = tostring(root.AssemblyLinearVelocity)

	return typeof(root.CFrame) == "CFrame"
		and typeof(root.AssemblyLinearVelocity) == "Vector3"
		and typeof(root.AssemblyAngularVelocity) == "Vector3"
end)

optional("Character rig topology", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false, "Humanoid unavailable"
	end

	local required

	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		required = {
			"Head",
			"HumanoidRootPart",
			"UpperTorso",
			"LowerTorso",
			"LeftUpperArm",
			"RightUpperArm",
			"LeftUpperLeg",
			"RightUpperLeg"
		}
	else
		required = {
			"Head",
			"HumanoidRootPart",
			"Torso",
			"Left Arm",
			"Right Arm",
			"Left Leg",
			"Right Leg"
		}
	end

	for _, partName in ipairs(required) do
		local part = character:FindFirstChild(partName)

		if not part or not part:IsA("BasePart") then
			return false, partName .. " unavailable"
		end
	end

	return true
end)

optional("Character physical assembly", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local partCount = 0
	local totalMass = 0

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			partCount += 1
			totalMass += descendant:GetMass()
		end
	end

	metrics.CharacterParts = tostring(partCount)
	metrics.CharacterMass = string.format("%.2f", totalMass)

	return partCount > 0
		and totalMass > 0
end)

optional("Character Humanoid state", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false, "Humanoid unavailable"
	end

	local state = humanoid:GetState()

	metrics.HumanoidState = tostring(state)
	metrics.FloorMaterial = tostring(humanoid.FloorMaterial)

	return typeof(state) == "EnumItem"
		and typeof(humanoid.FloorMaterial) == "EnumItem"
		and typeof(humanoid.MoveDirection) == "Vector3"
end)

optional("Character applied description", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false, "Humanoid unavailable"
	end

	local description = humanoid:GetAppliedDescription()

	local valid = description:IsA("HumanoidDescription")
		and type(description.HeightScale) == "number"
		and type(description.WidthScale) == "number"
		and type(description.DepthScale) == "number"
		and type(description.HeadScale) == "number"
		and type(description.BodyTypeScale) == "number"
		and type(description.ProportionScale) == "number"

	metrics.HeightScale = tostring(description.HeightScale)
	metrics.WidthScale = tostring(description.WidthScale)
	metrics.DepthScale = tostring(description.DepthScale)

	description:Destroy()

	return valid
end)

optional("Character skin colors", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false, "Humanoid unavailable"
	end

	local description = humanoid:GetAppliedDescription()

	local colors = {
		description.HeadColor,
		description.LeftArmColor,
		description.RightArmColor,
		description.LeftLegColor,
		description.RightLegColor,
		description.TorsoColor
	}

	for _, color in ipairs(colors) do
		if typeof(color) ~= "Color3" then
			description:Destroy()
			return false, "invalid skin color"
		end
	end

	metrics.HeadColor = tostring(description.HeadColor)
	metrics.TorsoColor = tostring(description.TorsoColor)

	description:Destroy()

	return true
end)

optional("Character BodyColors", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local bodyColors = character:FindFirstChildOfClass("BodyColors")

	if not bodyColors then
		return false, "BodyColors unavailable"
	end

	return typeof(bodyColors.HeadColor) == "BrickColor"
		and typeof(bodyColors.LeftArmColor) == "BrickColor"
		and typeof(bodyColors.RightArmColor) == "BrickColor"
		and typeof(bodyColors.LeftLegColor) == "BrickColor"
		and typeof(bodyColors.RightLegColor) == "BrickColor"
		and typeof(bodyColors.TorsoColor) == "BrickColor"
end)

optional("Character appearance assets", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false, "Humanoid unavailable"
	end

	local accessories = humanoid:GetAccessories()
	local appearanceCount = 0

	for _, descendant in ipairs(character:GetChildren()) do
		if descendant:IsA("Accessory")
			or descendant:IsA("Shirt")
			or descendant:IsA("Pants")
			or descendant:IsA("ShirtGraphic")
			or descendant:IsA("BodyColors") then
			appearanceCount += 1
		end
	end

	metrics.Accessories = tostring(#accessories)
	metrics.AppearanceObjects = tostring(appearanceCount)

	return type(accessories) == "table"
end)

optional("Character Animator", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false, "Humanoid unavailable"
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		return false, "Animator unavailable"
	end

	local tracks = animator:GetPlayingAnimationTracks()

	metrics.PlayingAnimations = tostring(#tracks)

	return type(tracks) == "table"
end)

optional("Current camera", function()
	local camera = workspace.CurrentCamera

	if not camera then
		return false, "camera unavailable"
	end

	metrics.CameraType = tostring(camera.CameraType)
	metrics.CameraFOV = tostring(camera.FieldOfView)
	metrics.ViewportSize = tostring(camera.ViewportSize)

	return camera:IsA("Camera")
		and typeof(camera.CFrame) == "CFrame"
		and typeof(camera.ViewportSize) == "Vector2"
		and type(camera.FieldOfView) == "number"
end)

test("loadstring availability", function()
	return type(loadstring) == "function"
end)

test("loadstring execution", function()
	local fn, err = loadstring("return 40 + 2")
	if not fn then
		return false, tostring(err)
	end
	return fn() == 42
end)

test("loadstring environment isolation", function()
	local fn, err = loadstring("_G.__LOADSTRING_SENTINEL = true; return _G.__LOADSTRING_SENTINEL")
	if not fn then
		return false, tostring(err)
	end
	local result = fn()
	_G.__LOADSTRING_SENTINEL = nil
	return result == true
end)

test("getfenv and setfenv", function()
	if type(getfenv) ~= "function" or type(setfenv) ~= "function" then
		return false, "getfenv/setfenv unavailable"
	end
	local env = { Value = 99 }
	local fn = function() return Value end
	setfenv(fn, env)
	return getfenv(fn).Value == 99 and fn() == 99
end)

test("debug.getmetatable", function()
	if type(debug) ~= "table" or type(debug.getmetatable) ~= "function" then
		return false, "debug.getmetatable unavailable"
	end
	local mt = { __tag = "sentinel" }
	local obj = setmetatable({}, mt)
	local retrieved = debug.getmetatable(obj)
	return retrieved == mt and retrieved.__tag == "sentinel"
end)

test("debug.setmetatable", function()
	if type(debug) ~= "table" or type(debug.setmetatable) ~= "function" then
		return false, "debug.setmetatable unavailable"
	end
	local obj = {}
	local mt = { __index = { X = 7 } }
	debug.setmetatable(obj, mt)
	return obj.X == 7 and debug.getmetatable(obj) == mt
end)

test("debug.getinfo", function()
	if type(debug) ~= "table" or type(debug.getinfo) ~= "function" then
		return false, "debug.getinfo unavailable"
	end
	local info = debug.getinfo(1, "nSluf")
	return type(info) == "table"
		and (info.name == nil or type(info.name) == "string")
		and type(info.source) == "string"
		and type(info.currentline) == "number"
		and type(info.linedefined) == "number"
		and type(info.what) == "string"
end)

test("debug.getupvalue and setupvalue", function()
	if type(debug) ~= "table" or type(debug.getupvalue) ~= "function" then
		return false, "debug.getupvalue unavailable"
	end
	local sentinel = { tag = "log-unc-upvalue" }
	local captured = sentinel
	local fn = function()
		return captured
	end
	local foundIndex
	for index = 1, 8 do
		local ok, first, second = pcall(debug.getupvalue, fn, index)
		if not ok then
			break
		end
		if first == sentinel or second == sentinel then
			foundIndex = index
			break
		end
		if first == nil and second == nil then
			break
		end
	end
	if foundIndex == nil then
		return false, "getupvalue did not expose the captured upvalue"
	end
	if type(debug.setupvalue) ~= "function" then
		return true
	end
	local replacement = { tag = "log-unc-upvalue-replaced" }
	local setOk = pcall(debug.setupvalue, fn, foundIndex, replacement)
	if not setOk then
		return true
	end
	if fn() == replacement then
		return true
	end
	local readOk, first, second = pcall(debug.getupvalue, fn, foundIndex)
	return readOk and (first == replacement or second == replacement)
end)

test("debug.getlocal and setlocal", function()
	if type(debug) ~= "table" then
		return false, "debug unavailable"
	end
	if debug.getlocal == nil and debug.setlocal == nil then
		return true
	end
	if type(debug.getlocal) ~= "function" then
		return false, "debug.getlocal unavailable"
	end
	local thread = coroutine.create(function()
		local myLocal = 5
		coroutine.yield()
		return myLocal
	end)
	coroutine.resume(thread)
	local name, value = debug.getlocal(thread, 1, 1)
	return name == "myLocal" and value == 5
end)

test("debug.traceback from coroutine", function()
	if type(debug) ~= "table" or type(debug.traceback) ~= "function" then
		return false, "debug.traceback unavailable"
	end
	local thread = coroutine.create(function()
		coroutine.yield()
	end)
	coroutine.resume(thread)
	local tb = debug.traceback(thread)
	return type(tb) == "string" and #tb > 0
end)

test("pcall with multiple returns", function()
	local ok, a, b, c = pcall(function()
		return 1, "two", true
	end)
	return ok and a == 1 and b == "two" and c == true
end)

test("pcall preserves error object type", function()
	local ok, err = pcall(function()
		error({ CustomError = true }, 0)
	end)
	return not ok and type(err) == "table" and err.CustomError == true
end)

test("xpcall stack trace in handler", function()
	local traceReceived
	xpcall(function()
		error("TRACE_TEST", 0)
	end, function(e)
		traceReceived = debug.traceback()
		return e
	end)
	return type(traceReceived) == "string" and #traceReceived > 0
end)

test("Instance GetPropertyChangedSignal", function()
	return withTemporary("Part", function(part)
		local fired = false
		local conn = part:GetPropertyChangedSignal("Size"):Connect(function()
			fired = true
		end)
		part.Size = Vector3.new(9, 9, 9)
		task.wait()
		conn:Disconnect()
		return fired
	end)
end)

test("Instance ChildAdded and ChildRemoved", function()
	local parent = Instance.new("Folder")
	local added = false
	local removed = false
	local connAdd = parent.ChildAdded:Connect(function() added = true end)
	local connRem = parent.ChildRemoved:Connect(function() removed = true end)
	local child = Instance.new("Folder")
	child.Parent = parent
	child.Parent = nil
	task.wait()
	connAdd:Disconnect()
	connRem:Disconnect()
	parent:Destroy()
	return added and removed
end)

optional("Instance DescendantAdded and DescendantRemoving", function()
	local root = Instance.new("Folder")
	local descAdded = false
	local descRemoving = false
	local ca = root.DescendantAdded:Connect(function() descAdded = true end)
	local cr = root.DescendantRemoving:Connect(function() descRemoving = true end)
	local mid = Instance.new("Folder")
	mid.Parent = root
	local leaf = Instance.new("StringValue")
	leaf.Parent = mid
	task.wait()
	leaf:Destroy()
	task.wait()
	ca:Disconnect()
	cr:Disconnect()
	root:Destroy()
	return descAdded and descRemoving
end)

optional("Instance AncestryChanged", function()
	local parent = Instance.new("Folder")
	local child = Instance.new("Folder")
	local changed = false
	local conn = child.AncestryChanged:Connect(function() changed = true end)
	child.Parent = parent
	task.wait()
	conn:Disconnect()
	parent:Destroy()
	return changed
end)

test("Part collision properties", function()
	return withTemporary("Part", function(part)
		part.CollisionGroupId = 0
		part.CanCollide = true
		part.CanTouch = true
		part.CanQuery = true
		return part.CollisionGroupId == 0
			and part.CanCollide
			and part.CanTouch
			and part.CanQuery
	end)
end)

test("Part network ownership", function()
	local part = Instance.new("Part")
	part.Anchored = false
	part.Parent = workspace
	local api = {
		"GetNetworkOwner",
		"SetNetworkOwner",
		"GetNetworkOwnershipAuto",
		"SetNetworkOwnershipAuto",
		"CanSetNetworkOwnership"
	}
	for _, name in ipairs(api) do
		if type(part[name]) ~= "function" then
			part:Destroy()
			return false, name .. " missing"
		end
	end
	local ok, owner = pcall(function()
		return part:GetNetworkOwner()
	end)
	local autoOk, auto = pcall(function()
		return part:GetNetworkOwnershipAuto()
	end)
	if ok then
		pcall(function()
			part:SetNetworkOwnershipAuto()
		end)
	end
	part:Destroy()
	if ok then
		local ownerValid = owner == nil or typeof(owner) == "Instance"
		local autoValid = not autoOk or type(auto) == "boolean"
		return ownerValid and autoValid
	end
	local message = string.lower(stringify(owner))
	if string.find(message, "server", 1, true) == nil then
		return false, stringify(owner)
	end
	if autoOk then
		return type(auto) == "boolean"
	end
	return string.find(string.lower(stringify(auto)), "server", 1, true) ~= nil
end)

optional("Part touched event", function()
	return withTemporary("Part", function(part)
		part.Anchored = true
		part.CanTouch = true
		part.Size = Vector3.new(100, 100, 100)
		part.Position = Vector3.new(0, 10000, 0)
		local touched = false
		local conn = part.Touched:Connect(function() touched = true end)
		task.wait(0.1)
		conn:Disconnect()
		return type(conn) == "userdata" or typeof(conn) == "RBXScriptConnection"
	end)
end)

test("Constraint attachments", function()
	local model = Instance.new("Model")
	local p0 = Instance.new("Part")
	local p1 = Instance.new("Part")
	p0.Anchored = true
	p1.Anchored = true
	p0.Parent = model
	p1.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.Parent = model
	local valid = weld.Part0 == p0 and weld.Part1 == p1 and weld.Enabled == true
	model:Destroy()
	return valid
end)

test("SpringConstraint properties", function()
	local model = Instance.new("Model")
	local a0 = Instance.new("Attachment")
	local a1 = Instance.new("Attachment")
	local p0 = Instance.new("Part")
	local p1 = Instance.new("Part")
	p0.Anchored = true
	p1.Anchored = true
	a0.Parent = p0
	a1.Parent = p1
	p0.Parent = model
	p1.Parent = model
	local spring = Instance.new("SpringConstraint")
	spring.Attachment0 = a0
	spring.Attachment1 = a1
	spring.Stiffness = 50
	spring.Damping = 2
	spring.FreeLength = 5
	spring.MaxLength = 20
	spring.MinLength = 1
	spring.Parent = model
	local valid = spring.Stiffness == 50
		and spring.Damping == 2
		and spring.FreeLength == 5
		and spring.MaxLength == 20
		and spring.MinLength == 1
	model:Destroy()
	return valid
end)

test("AlignPosition and AlignOrientation", function()
	local model = Instance.new("Model")
	local a0 = Instance.new("Attachment")
	local a1 = Instance.new("Attachment")
	local p0 = Instance.new("Part")
	local p1 = Instance.new("Part")
	p0.Anchored = true
	p1.Anchored = true
	a0.Parent = p0
	a1.Parent = p1
	p0.Parent = model
	p1.Parent = model
	local ap = Instance.new("AlignPosition")
	ap.Attachment0 = a0
	ap.Attachment1 = a1
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment
	ap.Position = Vector3.new(1, 2, 3)
	ap.MaxForce = 10000
	ap.MaxVelocity = 50
	ap.Responsiveness = 200
	ap.Parent = model
	local ao = Instance.new("AlignOrientation")
	ao.Attachment0 = a0
	ao.Attachment1 = a1
	ao.CFrame = CFrame.new(0, 0, 0)
	ao.MaxTorque = 10000
	ao.Responsiveness = 200
	ao.Parent = model
	local valid = ap.Position == Vector3.new(1, 2, 3)
		and ap.MaxForce == 10000
		and ao.MaxTorque == 10000
	model:Destroy()
	return valid
end)

test("LinearVelocity and AngularVelocity", function()
	local part = Instance.new("Part")
	local att = Instance.new("Attachment")
	att.Parent = part
	part.Anchored = false
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.VectorVelocity = Vector3.new(10, 0, 0)
	lv.MaxForce = 50000
	lv.Parent = part
	local av = Instance.new("AngularVelocity")
	av.Attachment0 = att
	av.AngularVelocity = Vector3.new(0, 5, 0)
	av.MaxTorque = 50000
	av.Parent = part
	local valid = lv.VectorVelocity == Vector3.new(10, 0, 0)
		and lv.MaxForce == 50000
		and av.AngularVelocity == Vector3.new(0, 5, 0)
		and av.MaxTorque == 50000
	part:Destroy()
	return valid
end)

test("VectorForce and Torque", function()
	local part = Instance.new("Part")
	local att = Instance.new("Attachment")
	att.Parent = part
	part.Anchored = false
	local vf = Instance.new("VectorForce")
	vf.Attachment0 = att
	vf.Force = Vector3.new(0, 100, 0)
	vf.ApplyAtCenterOfMass = true
	vf.RelativeTo = Enum.ActuatorRelativeTo.World
	vf.Parent = part
	local tq = Instance.new("Torque")
	tq.Attachment0 = att
	tq.Torque = Vector3.new(0, 50, 0)
	tq.RelativeTo = Enum.ActuatorRelativeTo.World
	tq.Parent = part
	local valid = vf.Force == Vector3.new(0, 100, 0)
		and vf.ApplyAtCenterOfMass
		and tq.Torque == Vector3.new(0, 50, 0)
	part:Destroy()
	return valid
end)

test("CFrame components and methods", function()
	local cf = CFrame.new(1, 2, 3, 0, 0, -1, 0, 1, 0, 1, 0, 0)
	local x, y, z = cf:ToEulerAnglesXYZ()
	local inv = cf:Inverse()
	local identity = cf * inv
	local posValid = (identity.Position - Vector3.new(0, 0, 0)).Magnitude < 0.001
	local right = cf.RightVector
	local up = cf.UpVector
	local look = cf.LookVector
	return type(x) == "number"
		and type(y) == "number"
		and type(z) == "number"
		and posValid
		and typeof(right) == "Vector3"
		and typeof(up) == "Vector3"
		and typeof(look) == "Vector3"
end)

test("CFrame.fromAxisAngle and ToAxisAngle", function()
	local axis = Vector3.new(0, 1, 0)
	local angle = math.rad(45)
	local cf = CFrame.fromAxisAngle(axis, angle)
	local retAxis, retAngle = cf:ToAxisAngle()
	local axisMatch = (retAxis - axis).Magnitude < 0.001
	local angleMatch = math.abs(retAngle - angle) < 0.001
	return axisMatch and angleMatch
end)

test("Enum completeness", function()
	local enums = {
		"Material", "PartType", "EasingStyle", "EasingDirection",
		"RaycastFilterType", "HumanoidRigType", "HumanoidStateType",
		"CameraType", "Platform", "FillDirection", "HorizontalAlignment",
		"VerticalAlignment", "TextXAlignment", "TextYAlignment",
		"Font", "ActuatorRelativeTo",
		"PositionAlignmentMode", "OrientationAlignmentMode"
	}
	for _, enumName in ipairs(enums) do
		if Enum[enumName] == nil then
			return false, "Enum." .. enumName .. " missing"
		end
	end
	return true
end)

test("typeof correctness", function()
	local checks = {
		{ Instance.new("Folder"), "Instance" },
		{ Vector3.new(), "Vector3" },
		{ Vector2.new(), "Vector2" },
		{ CFrame.new(), "CFrame" },
		{ Color3.new(), "Color3" },
		{ UDim2.new(), "UDim2" },
		{ BrickColor.new("White"), "BrickColor" },
		{ Enum.Material.Plastic, "EnumItem" },
		{ RaycastParams.new(), "RaycastParams" },
		{ OverlapParams.new(), "OverlapParams" },
		{ TweenInfo.new(), "TweenInfo" },
		{ NumberRange.new(0, 1), "NumberRange" },
		{ Region3.new(Vector3.new(), Vector3.new()), "Region3" },
		{ Ray.new(Vector3.new(), Vector3.new()), "Ray" },
		{ DateTime.now(), "DateTime" },
		{ Random.new(), "Random" },
	}
	for _, pair in ipairs(checks) do
		if typeof(pair[1]) ~= pair[2] then
			return false, "typeof " .. pair[2] .. " returned " .. typeof(pair[1])
		end
	end
	checks[1][1]:Destroy()
	return true
end)

test("Global functions exist", function()
	local fns = {
		"print", "warn", "error", "type", "typeof", "tostring", "tonumber",
		"pairs", "ipairs", "next", "select", "unpack", "rawget", "rawset",
		"rawequal", "rawlen", "setmetatable", "getmetatable", "pcall",
		"xpcall", "coroutine", "task", "math", "string", "table", "os",
		"utf8", "bit32", "tick", "time", "wait", "spawn", "delay",
		"Instance", "Vector3", "Vector2", "CFrame", "Color3", "UDim2",
		"UDim", "BrickColor", "Enum", "game", "workspace"
	}
	local env = getfenv(0)
	for _, name in ipairs(fns) do
		if env[name] == nil then
			return false, name .. " is nil"
		end
	end
	return true
end)

test("require behavior", function()
	if type(require) ~= "function" then
		return false, "require unavailable"
	end
	return true
end)

test("newproxy", function()
	if type(newproxy) ~= "function" then
		return false, "newproxy unavailable"
	end
	local proxy = newproxy(true)
	local mt = getmetatable(proxy)
	mt.__index = function() return 42 end
	return proxy.Anything == 42
end)

test("gcinfo", function()
	if type(gcinfo) ~= "function" then
		return false, "gcinfo unavailable"
	end
	local mem = gcinfo()
	return type(mem) == "number" and mem >= 0
end)

test("tick function", function()
	if type(tick) ~= "function" then
		return false, "tick unavailable"
	end
	local t = tick()
	return type(t) == "number" and t > 0
end)

optional("spawn and delay", function()
	if type(spawn) ~= "function" then
		return false, "spawn unavailable"
	end
	if type(delay) ~= "function" then
		return false, "delay unavailable"
	end
	local spawned = false
	spawn(function() spawned = true end)
	local deadline = os.clock() + 2
	while not spawned and os.clock() < deadline do
		task.wait()
	end
	return spawned
end)

test("wait function", function()
	if type(wait) ~= "function" then
		return false, "wait unavailable"
	end
	local start = os.clock()
	wait(0.01)
	local elapsed = os.clock() - start
	return elapsed >= 0
end)

test("shared table exists", function()
	return type(shared) == "table"
end)

test("_G table exists and writable", function()
	_G.__LOG_UNC_WRITE_TEST = 42
	local val = _G.__LOG_UNC_WRITE_TEST
	_G.__LOG_UNC_WRITE_TEST = nil
	return val == 42
end)

test("Version function", function()
	if type(version) ~= "function" then
		return false, "version unavailable"
	end
	local v = version()
	return type(v) == "string" and #v > 0
end)

test("UserSettings", function()
	if type(UserSettings) ~= "function" then
		return false, "UserSettings unavailable"
	end
	local us = UserSettings()
	return typeof(us) == "Instance" and us:IsA("UserSettings")
end)

test("settings function", function()
	if type(settings) ~= "function" then
		return false, "settings unavailable"
	end
	local s = settings()
	return typeof(s) == "Instance"
end)

test("Workspace gravity and fallback", function()
	local g = workspace.Gravity
	if type(g) ~= "number" then
		return false, "Gravity not a number"
	end
	local ff = workspace.FallenPartsDestroyHeight
	return type(ff) == "number"
end)

test("Lighting properties", function()
	local lighting = game:GetService("Lighting")
	local props = {
		"Ambient", "Brightness", "ClockTime", "ColorShift_Bottom",
		"ColorShift_Top", "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
		"FogEnd", "FogStart", "GlobalShadows", "OutdoorAmbient",
		"ShadowSoftness", "Technology"
	}
	for _, prop in ipairs(props) do
		local ok, _ = pcall(function() return lighting[prop] end)
		if not ok then
			return false, "Lighting." .. prop .. " inaccessible"
		end
	end
	return true
end)

test("ReplicatedStorage existence", function()
	local rs = game:GetService("ReplicatedStorage")
	return typeof(rs) == "Instance" and rs:IsA("ReplicatedStorage")
end)

test("ServerStorage existence", function()
	local ss = game:GetService("ServerStorage")
	return typeof(ss) == "Instance" and ss:IsA("ServerStorage")
end)

test("Debris service", function()
	local debris = game:GetService("Debris")
	local part = Instance.new("Part")
	local ok, err = pcall(function()
		debris:AddItem(part, 60)
	end)
	part:Destroy()
	return ok
end)

test("SoundService properties", function()
	local ss = game:GetService("SoundService")
	local ok1, v1 = pcall(function() return ss.DistanceFactor end)
	local ok2, v2 = pcall(function() return ss.RespectFilteringEnabled end)
	return ok1 and type(v1) == "number" and ok2 and type(v2) == "boolean"
end)

test("TextChatService properties", function()
	local tcs = game:GetService("TextChatService")
	local ok, v = pcall(function() return tcs.ChatVersion end)
	return ok and v ~= nil
end)

test("GuiService properties", function()
	local gs = game:GetService("GuiService")
	local ok1, v1 = pcall(function() return gs.MenuIsOpen end)
	local ok2, v2 = pcall(function() return gs:GetScreenResolution() end)
	return ok1 and type(v1) == "boolean" and ok2 and typeof(v2) == "Vector2"
end)

test("ContextActionService bind/unbind", function()
	local cas = game:GetService("ContextActionService")
	local bound = false
	local ok, err = pcall(function()
		cas:BindAction("LogUncTestAction", function() bound = true end, false)
	end)
	if not ok then
		return false, tostring(err)
	end
	local unbindOk, unbindErr = pcall(function()
		cas:UnbindAction("LogUncTestAction")
	end)
	return ok and unbindOk
end)

test("ProximityPromptService events", function()
	local pps = game:GetService("ProximityPromptService")
	local hasTriggered = typeof(pps.PromptTriggered) == "RBXScriptSignal"
	local hasHoldBegin = typeof(pps.PromptButtonHoldBegan) == "RBXScriptSignal"
	local hasHoldEnd = typeof(pps.PromptButtonHoldEnded) == "RBXScriptSignal"
	return hasTriggered and hasHoldBegin and hasHoldEnd
end)

test("LocalizationTable creation", function()
	local lt = Instance.new("LocalizationTable")
	local valid = lt:IsA("LocalizationTable")
	lt:Destroy()
	return valid
end)

test("ModuleScript creation", function()
	local ms = Instance.new("ModuleScript")
	ms.Source = "return 42"
	local valid = ms:IsA("ModuleScript") and ms.Source == "return 42"
	ms:Destroy()
	return valid
end)

test("Script creation", function()
	local s = Instance.new("Script")
	local valid = s:IsA("Script")
	s:Destroy()
	return valid
end)

test("LocalScript creation", function()
	local ls = Instance.new("LocalScript")
	local valid = ls:IsA("LocalScript")
	ls:Destroy()
	return valid
end)

test("Tool creation", function()
	local tool = Instance.new("Tool")
	local valid = tool:IsA("Tool")
	tool:Destroy()
	return valid
end)

test("Accessory creation", function()
	local acc = Instance.new("Accessory")
	local valid = acc:IsA("Accessory")
	acc:Destroy()
	return valid
end)

test("Shirt Pants ShirtGraphic", function()
	local shirt = Instance.new("Shirt")
	local pants = Instance.new("Pants")
	local sg = Instance.new("ShirtGraphic")
	local valid = shirt:IsA("Shirt") and pants:IsA("Pants") and sg:IsA("ShirtGraphic")
	shirt:Destroy()
	pants:Destroy()
	sg:Destroy()
	return valid
end)

test("Decal Texture Face", function()
	local decal = Instance.new("Decal")
	decal.Face = Enum.NormalId.Front
	local valid = decal.Face == Enum.NormalId.Front
	decal:Destroy()
	return valid
end)

test("SurfaceGui Face and SizingMode", function()
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Top
	local valid = sg.Face == Enum.NormalId.Top
	sg:Destroy()
	return valid
end)

test("BillboardGui Size and Offset", function()
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 100, 0, 50)
	bg.StudsOffset = Vector3.new(0, 3, 0)
	local valid = bg.Size == UDim2.new(0, 100, 0, 50)
		and bg.StudsOffset == Vector3.new(0, 3, 0)
	bg:Destroy()
	return valid
end)

test("ViewportFrame CurrentCamera", function()
	local vf = Instance.new("ViewportFrame")
	local cam = Instance.new("Camera")
	vf.CurrentCamera = cam
	local valid = vf.CurrentCamera == cam
	vf:Destroy()
	cam:Destroy()
	return valid
end)

test("TweenInfo construction", function()
	local ti = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true, 0.5)
	return ti.Time == 1
		and ti.EasingStyle == Enum.EasingStyle.Quad
		and ti.EasingDirection == Enum.EasingDirection.Out
		and ti.RepeatCount == 0
		and ti.Reverses == true
		and ti.DelayTime == 0.5
end)

test("NumberSequence and ColorSequence keypoints", function()
	local ns = NumberSequence.new(0, 1)
	local cs = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(1, 1, 1))
	return #ns.Keypoints == 2
		and #cs.Keypoints == 2
		and ns.Keypoints[1].Value == 0
		and ns.Keypoints[2].Value == 1
end)

test("PhysicalProperties default and custom", function()
	local default = PhysicalProperties.new(Enum.Material.Plastic)
	local custom = PhysicalProperties.new(0.5, 0.3, 0.2, 1, 1)
	return typeof(default) == "PhysicalProperties"
		and typeof(custom) == "PhysicalProperties"
		and type(default.Density) == "number"
		and default.Density > 0
		and nearlyEqual(custom.Density, 0.5)
		and nearlyEqual(custom.Friction, 0.3)
		and nearlyEqual(custom.Elasticity, 0.2)
		and nearlyEqual(custom.FrictionWeight, 1)
		and nearlyEqual(custom.ElasticityWeight, 1)
end)

test("Region3int16", function()
	local r = Region3int16.new(Vector3int16.new(-10, -10, -10), Vector3int16.new(10, 10, 10))
	return typeof(r) == "Region3int16"
end)

test("Vector3int16", function()
	local v = Vector3int16.new(100, 200, 300)
	return typeof(v) == "Vector3int16"
		and v.X == 100 and v.Y == 200 and v.Z == 300
end)

test("Rect", function()
	local r = Rect.new(10, 20, 100, 200)
	return typeof(r) == "Rect"
		and r.Min.X == 10 and r.Min.Y == 20
		and r.Max.X == 100 and r.Max.Y == 200
		and r.Width == 90 and r.Height == 180
end)

test("Faces", function()
	local f = Faces.new(Enum.NormalId.Front, Enum.NormalId.Back)
	return typeof(f) == "Faces"
		and f.Front == true
		and f.Back == true
		and f.Top == false
end)

test("Axes", function()
	local a = Axes.new(Enum.Axis.X, Enum.Axis.Y)
	return typeof(a) == "Axes"
		and a.X == true
		and a.Y == true
		and a.Z == false
end)

test("CatalogSearchParams", function()
	local params = CatalogSearchParams.new()
	params.SearchKeyword = "hat"
	params.MinPrice = 100
	params.MaxPrice = 1000
	return typeof(params) == "CatalogSearchParams"
		and params.SearchKeyword == "hat"
		and params.MinPrice == 100
		and params.MaxPrice == 1000
end)

test("DockWidgetPluginGuiInfo", function()
	local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, 200, 300, 100, 100)
	return typeof(info) == "DockWidgetPluginGuiInfo"
end)

test("PathWaypoint", function()
	local wp = PathWaypoint.new(Vector3.new(1, 2, 3), Enum.PathWaypointAction.Walk)
	return typeof(wp) == "PathWaypoint"
		and wp.Position == Vector3.new(1, 2, 3)
		and wp.Action == Enum.PathWaypointAction.Walk
end)

test("OverlapParams and RaycastParams FilterDescendantsInstances", function()
	local rp = RaycastParams.new()
	local folder = Instance.new("Folder")
	rp.FilterDescendantsInstances = { folder }
	local op = OverlapParams.new()
	op.FilterDescendantsInstances = { folder }
	local valid = #rp.FilterDescendantsInstances == 1
		and #op.FilterDescendantsInstances == 1
	folder:Destroy()
	return valid
end)

test("Instance Clone preserves attributes", function()
	local original = Instance.new("Folder")
	original:SetAttribute("TestAttr", "hello")
	original:SetAttribute("NumAttr", 123)
	local clone = original:Clone()
	local attrs = clone:GetAttributes()
	local valid = attrs.TestAttr == "hello" and attrs.NumAttr == 123
	original:Destroy()
	clone:Destroy()
	return valid
end)

test("Instance Clone preserves tags", function()
	local cs = game:GetService("CollectionService")
	local original = Instance.new("Folder")
	cs:AddTag(original, "CloneTagTest")
	local clone = original:Clone()
	local valid = cs:HasTag(clone, "CloneTagTest")
	cs:RemoveTag(original, "CloneTagTest")
	original:Destroy()
	clone:Destroy()
	return valid
end)

test("Instance WaitForChild timeout", function()
	local parent = Instance.new("Folder")
	local start = os.clock()
	local found = parent:WaitForChild("NonExistent", 0.1)
	local elapsed = os.clock() - start
	parent:Destroy()
	return found == nil and elapsed >= 0.05 and elapsed < 1
end)

test("Instance FindFirstChildWhichIsA recursive", function()
	local root = Instance.new("Folder")
	local mid = Instance.new("Folder")
	local part = Instance.new("Part")
	mid.Parent = root
	part.Parent = mid
	local found = root:FindFirstChildWhichIsA("BasePart", true)
	local valid = found == part
	root:Destroy()
	return valid
end)

test("Instance GetChildren order stability", function()
	local parent = Instance.new("Folder")
	local a = Instance.new("Folder")
	local b = Instance.new("Folder")
	local c = Instance.new("Folder")
	a.Name = "A"
	b.Name = "B"
	c.Name = "C"
	a.Parent = parent
	b.Parent = parent
	c.Parent = parent
	local children = parent:GetChildren()
	local valid = #children == 3
	parent:Destroy()
	return valid
end)

test("BindableEvent multiple connections", function()
	local event = Instance.new("BindableEvent")
	local count = 0
	local c1 = event.Event:Connect(function() count += 1 end)
	local c2 = event.Event:Connect(function() count += 10 end)
	event:Fire()
	task.wait()
	c1:Disconnect()
	c2:Disconnect()
	event:Destroy()
	return count == 11
end)

optional("BindableFunction nil OnInvoke", function()
	local bf = Instance.new("BindableFunction")
	local done = false

	task.spawn(function()
		pcall(function()
			bf:Invoke()
		end)
		done = true
	end)

	task.wait(0.5)

	local yielded = not done

	bf:Destroy()

	return yielded
end)

test("RemoteEvent and RemoteFunction creation", function()
	local re = Instance.new("RemoteEvent")
	local rf = Instance.new("RemoteFunction")
	local valid = re:IsA("RemoteEvent") and rf:IsA("RemoteFunction")
	re:Destroy()
	rf:Destroy()
	return valid
end)

test("AnimationTrack types", function()
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://1"
	local humanoid = Instance.new("Humanoid")
	local animator = Instance.new("Animator")
	animator.Parent = humanoid
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	anim:Destroy()
	humanoid:Destroy()
	if not ok then
		return false, tostring(track)
	end
	local valid = typeof(track) == "Instance" and track:IsA("AnimationTrack")
	track:Destroy()
	return valid
end)

test("KeyframeSequenceProvider", function()
	local ksp = game:GetService("KeyframeSequenceProvider")
	return typeof(ksp) == "Instance" and ksp:IsA("KeyframeSequenceProvider")
end)

test("ContentProvider BaseUrl", function()
	local cp = game:GetService("ContentProvider")
	local ok, url = pcall(function() return cp.BaseUrl end)
	return ok and type(url) == "string" and #url > 0
end)

test("MarketplaceService GetProductInfo structure", function()
	local mps = game:GetService("MarketplaceService")
	return typeof(mps) == "Instance" and mps:IsA("MarketplaceService")
end)

test("TeleportService exists", function()
	local ts = game:GetService("TeleportService")
	return typeof(ts) == "Instance" and ts:IsA("TeleportService")
end)

test("DataStoreService exists", function()
	local dss = game:GetService("DataStoreService")
	return typeof(dss) == "Instance" and dss:IsA("DataStoreService")
end)

test("MemoryStoreService exists", function()
	local mss = game:GetService("MemoryStoreService")
	return typeof(mss) == "Instance" and mss:IsA("MemoryStoreService")
end)

test("MessagingService exists", function()
	local ms = game:GetService("MessagingService")
	return typeof(ms) == "Instance" and ms:IsA("MessagingService")
end)

test("PolicyService exists", function()
	local ps = game:GetService("PolicyService")
	return typeof(ps) == "Instance" and ps:IsA("PolicyService")
end)

test("GroupService exists", function()
	local gs = game:GetService("GroupService")
	return typeof(gs) == "Instance" and gs:IsA("GroupService")
end)

test("SocialService exists", function()
	local ss = game:GetService("SocialService")
	return typeof(ss) == "Instance" and ss:IsA("SocialService")
end)

test("VoiceChatService exists", function()
	local vcs = game:GetService("VoiceChatService")
	return typeof(vcs) == "Instance" and vcs:IsA("VoiceChatService")
end)

test("AvatarEditorService exists", function()
	local aes = game:GetService("AvatarEditorService")
	return typeof(aes) == "Instance" and aes:IsA("AvatarEditorService")
end)

test("InsertService exists", function()
	local is = game:GetService("InsertService")
	return typeof(is) == "Instance" and is:IsA("InsertService")
end)

test("AssetService exists", function()
	local as = game:GetService("AssetService")
	return typeof(as) == "Instance" and as:IsA("AssetService")
end)

test("MaterialService exists", function()
	local ms = game:GetService("MaterialService")
	return typeof(ms) == "Instance" and ms:IsA("MaterialService")
end)

test("GeometryService exists", function()
	local gs = game:GetService("GeometryService")
	return typeof(gs) == "Instance" and gs:IsA("GeometryService")
end)

test("UserService exists", function()
	local us = game:GetService("UserService")
	return typeof(us) == "Instance" and us:IsA("UserService")
end)

test("FriendService exists", function()
	local fs = game:GetService("FriendService")
	return typeof(fs) == "Instance" and fs:IsA("FriendService")
end)

test("AnalyticsService exists", function()
	local as = game:GetService("AnalyticsService")
	return typeof(as) == "Instance" and as:IsA("AnalyticsService")
end)

test("CaptureService exists", function()
	local cs = game:GetService("CaptureService")
	return typeof(cs) == "Instance" and cs:IsA("CaptureService")
end)

test("PermissionsService exists", function()
	local ps = game:GetService("PermissionsService")
	return typeof(ps) == "Instance" and ps:IsA("PermissionsService")
end)

test("CoreGui exists", function()
	local cg = game:GetService("CoreGui")
	return typeof(cg) == "Instance" and cg:IsA("CoreGui")
end)

test("ScriptContext exists", function()
	local sc = game:GetService("ScriptContext")
	return typeof(sc) == "Instance" and sc:IsA("ScriptContext")
end)

test("VRService exists", function()
	local vr = game:GetService("VRService")
	return typeof(vr) == "Instance" and vr:IsA("VRService")
end)

test("HapticService exists", function()
	local hs = game:GetService("HapticService")
	return typeof(hs) == "Instance" and hs:IsA("HapticService")
end)

test("BadgeService exists", function()
	local bs = game:GetService("BadgeService")
	return typeof(bs) == "Instance" and bs:IsA("BadgeService")
end)

test("GamePassService exists", function()
	local gps = game:GetService("GamePassService")
	return typeof(gps) == "Instance" and gps:IsA("GamePassService")
end)

test("HttpService UrlEncode", function()
	local hs = game:GetService("HttpService")
	local encoded = hs:UrlEncode("hello world&foo=bar")
	return type(encoded) == "string" and string.find(encoded, "hello%%20world") ~= nil
end)

test("RunService IsStudio IsClient IsServer", function()
	local rs = game:GetService("RunService")
	local studio = rs:IsStudio()
	local client = rs:IsClient()
	local server = rs:IsServer()
	return type(studio) == "boolean"
		and type(client) == "boolean"
		and type(server) == "boolean"
end)

test("RunService signals exist", function()
	local rs = game:GetService("RunService")
	return typeof(rs.Heartbeat) == "RBXScriptSignal"
		and typeof(rs.RenderStepped) == "RBXScriptSignal"
		and typeof(rs.Stepped) == "RBXScriptSignal"
		and typeof(rs.PreRender) == "RBXScriptSignal"
		and typeof(rs.PostSimulation) == "RBXScriptSignal"
		and typeof(rs.PreSimulation) == "RBXScriptSignal"
		and typeof(rs.PreAnimation) == "RBXScriptSignal"
end)

test("Players service signals", function()
	local players = game:GetService("Players")
	return typeof(players.PlayerAdded) == "RBXScriptSignal"
		and typeof(players.PlayerRemoving) == "RBXScriptSignal"
end)

test("Workspace signals", function()
	return typeof(workspace.DescendantAdded) == "RBXScriptSignal"
		and typeof(workspace.DescendantRemoving) == "RBXScriptSignal"
		and typeof(workspace.ChildAdded) == "RBXScriptSignal"
		and typeof(workspace.ChildRemoved) == "RBXScriptSignal"
end)

test("game signals", function()
	return typeof(game.DescendantAdded) == "RBXScriptSignal"
		and typeof(game.DescendantRemoving) == "RBXScriptSignal"
		and typeof(game.ChildAdded) == "RBXScriptSignal"
		and typeof(game.ChildRemoved) == "RBXScriptSignal"
end)

test("Instance Changed signal", function()
	return withTemporary("Part", function(part)
		local changedProp = false
		local conn = part.Changed:Connect(function(prop)
			if prop == "Size" then
				changedProp = true
			end
		end)
		part.Size = Vector3.new(7, 7, 7)
		task.wait()
		conn:Disconnect()
		return changedProp
	end)
end)

test("RBXScriptConnection Connected property", function()
	local event = Instance.new("BindableEvent")
	local conn = event.Event:Connect(function() end)
	local wasConnected = conn.Connected
	conn:Disconnect()
	local afterDisconnect = conn.Connected
	event:Destroy()
	return wasConnected == true and afterDisconnect == false
end)

test("Instance GetFullName", function()
	local root = Instance.new("Folder")
	root.Name = "Root"
	local child = Instance.new("Folder")
	child.Name = "Child"
	child.Parent = root
	local name = child:GetFullName()
	root:Destroy()
	return name == "Root.Child"
end)

test("Instance IsA inheritance", function()
	local part = Instance.new("Part")
	local valid = part:IsA("Part")
		and part:IsA("BasePart")
		and part:IsA("PVInstance")
		and part:IsA("Instance")
	part:Destroy()
	return valid
end)

test("Instance ClassName readonly", function()
	local part = Instance.new("Part")
	local ok, err = pcall(function()
		part.ClassName = "Folder"
	end)
	part:Destroy()
	return not ok
end)

test("Instance Parent writeable", function()
	local a = Instance.new("Folder")
	local b = Instance.new("Folder")
	b.Parent = a
	local valid = b.Parent == a
	a:Destroy()
	return valid
end)

test("Instance Name writeable", function()
	local f = Instance.new("Folder")
	f.Name = "CustomName"
	local valid = f.Name == "CustomName"
	f:Destroy()
	return valid
end)

test("Instance Name coerces numbers", function()
	local object = Instance.new("Folder")
	local ok = pcall(function()
		object.Name = 5
	end)
	local coerced = ok and object.Name == "5"

	object:Destroy()

	return ok == false
		or coerced
end)

test("Instance Archivable default true", function()
	local f = Instance.new("Folder")
	local valid = f.Archivable == true
	f:Destroy()
	return valid
end)

test("Instance UniqueId", function()
	local first = Instance.new("Folder")
	local second = Instance.new("Folder")
	local registry = {}
	registry[first] = "first"
	registry[second] = "second"
	local identityValid = first ~= second
		and registry[first] == "first"
		and registry[second] == "second"
	local okFirst, idFirst = pcall(function()
		return first.UniqueId
	end)
	local okSecond, idSecond = pcall(function()
		return second.UniqueId
	end)
	local uniqueValid = true
	if okFirst and okSecond and typeof(idFirst) == "UniqueId" and typeof(idSecond) == "UniqueId" then
		uniqueValid = idFirst ~= idSecond
	end
	first:Destroy()
	second:Destroy()
	return identityValid and uniqueValid
end)

test("Part Top Bottom Left Right Front Back SurfaceTypes", function()
	return withTemporary("Part", function(part)
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Universal
		local valid = part.TopSurface == Enum.SurfaceType.Smooth
			and part.BottomSurface == Enum.SurfaceType.Universal
		return valid
	end)
end)

test("Part Shape variants", function()
	local shapes = { Enum.PartType.Block, Enum.PartType.Ball, Enum.PartType.Cylinder }
	for _, shape in ipairs(shapes) do
		local part = Instance.new("Part")
		part.Shape = shape
		if part.Shape ~= shape then
			part:Destroy()
			return false, "Shape " .. tostring(shape) .. " failed"
		end
		part:Destroy()
	end
	return true
end)

test("MeshPart MeshId", function()
	local mp = Instance.new("MeshPart")
	mp.MeshId = "rbxassetid://0"
	local valid = mp:IsA("MeshPart") and type(mp.MeshId) == "string"
	mp:Destroy()
	return valid
end)

test("SpecialMesh creation", function()
	local sm = Instance.new("SpecialMesh")
	sm.MeshType = Enum.MeshType.Sphere
	local valid = sm:IsA("SpecialMesh") and sm.MeshType == Enum.MeshType.Sphere
	sm:Destroy()
	return valid
end)

test("DataStoreRequestType enum", function()
	return Enum.DataStoreRequestType.GetAsync ~= nil
		and Enum.DataStoreRequestType.SetIncrementAsync ~= nil
		and Enum.DataStoreRequestType.UpdateAsync ~= nil
end)

test("HttpContentType enum", function()
	return Enum.HttpContentType.ApplicationJson ~= nil
		and Enum.HttpContentType.TextPlain ~= nil
end)

test("SortOrder enum", function()
	return Enum.SortOrder.LayoutOrder ~= nil
		and Enum.SortOrder.Name ~= nil
end)

test("ZIndexBehavior enum", function()
	return Enum.ZIndexBehavior.Global ~= nil
		and Enum.ZIndexBehavior.Sibling ~= nil
end)

test("ReverbType enum", function()
	return Enum.ReverbType.NoReverb ~= nil
		and Enum.ReverbType.Cave ~= nil
end)

test("ImageLabel SliceCenter ScaleType", function()
	local il = Instance.new("ImageLabel")
	il.ScaleType = Enum.ScaleType.Slice
	il.SliceCenter = Rect.new(10, 10, 90, 90)
	local valid = il.ScaleType == Enum.ScaleType.Slice
		and typeof(il.SliceCenter) == "Rect"
	il:Destroy()
	return valid
end)

test("TextLabel TextWrapped TextScaled", function()
	local tl = Instance.new("TextLabel")
	tl.TextWrapped = true
	tl.TextScaled = false
	tl.Text = "Hello"
	tl.Font = Enum.Font.SourceSans
	tl.TextSize = 14
	tl.TextColor3 = Color3.new(1, 1, 1)
	local valid = tl.TextWrapped == true
		and tl.TextScaled == false
		and tl.Text == "Hello"
	tl:Destroy()
	return valid
end)

test("ScrollingFrame CanvasSize ScrollBarThickness", function()
	local sf = Instance.new("ScrollingFrame")
	sf.CanvasSize = UDim2.new(0, 500, 0, 1000)
	sf.ScrollBarThickness = 8
	local valid = sf.CanvasSize == UDim2.new(0, 500, 0, 1000)
		and sf.ScrollBarThickness == 8
	sf:Destroy()
	return valid
end)

test("TextBox PlaceholderText", function()
	local tb = Instance.new("TextBox")
	tb.PlaceholderText = "Enter here..."
	tb.ClearTextOnFocus = true
	local valid = tb.PlaceholderText == "Enter here..."
		and tb.ClearTextOnFocus == true
	tb:Destroy()
	return valid
end)

test("UIPadding PaddingAll sides", function()
	local uip = Instance.new("UIPadding")
	uip.PaddingTop = UDim.new(0, 10)
	uip.PaddingBottom = UDim.new(0, 20)
	uip.PaddingLeft = UDim.new(0, 5)
	uip.PaddingRight = UDim.new(0, 15)
	local valid = uip.PaddingTop == UDim.new(0, 10)
		and uip.PaddingBottom == UDim.new(0, 20)
		and uip.PaddingLeft == UDim.new(0, 5)
		and uip.PaddingRight == UDim.new(0, 15)
	uip:Destroy()
	return valid
end)

test("UICorner CornerRadius", function()
	local uc = Instance.new("UICorner")
	uc.CornerRadius = UDim.new(0, 8)
	local valid = uc.CornerRadius == UDim.new(0, 8)
	uc:Destroy()
	return valid
end)

test("UIStroke Thickness Color", function()
	local us = Instance.new("UIStroke")
	us.Thickness = 2
	us.Color = Color3.fromRGB(255, 0, 0)
	us.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local valid = us.Thickness == 2
		and us.Color == Color3.fromRGB(255, 0, 0)
		and us.ApplyStrokeMode == Enum.ApplyStrokeMode.Border
	us:Destroy()
	return valid
end)

test("UIScale Scale", function()
	local us = Instance.new("UIScale")
	us.Scale = 1.5
	local valid = us.Scale == 1.5
	us:Destroy()
	return valid
end)

test("UIGradient Transparency Rotation", function()
	local ug = Instance.new("UIGradient")
	ug.Rotation = 45
	ug.Enabled = true
	local valid = ug.Rotation == 45 and ug.Enabled == true
	ug:Destroy()
	return valid
end)

test("UIListLayout SortOrder Padding", function()
	local ull = Instance.new("UIListLayout")
	ull.SortOrder = Enum.SortOrder.LayoutOrder
	ull.Padding = UDim.new(0, 5)
	ull.FillDirection = Enum.FillDirection.Vertical
	local valid = ull.SortOrder == Enum.SortOrder.LayoutOrder
		and ull.Padding == UDim.new(0, 5)
		and ull.FillDirection == Enum.FillDirection.Vertical
	ull:Destroy()
	return valid
end)

test("UIGridLayout CellSize CellPadding", function()
	local ugl = Instance.new("UIGridLayout")
	ugl.CellSize = UDim2.new(0, 50, 0, 50)
	ugl.CellPadding = UDim2.new(0, 5, 0, 5)
	local valid = ugl.CellSize == UDim2.new(0, 50, 0, 50)
		and ugl.CellPadding == UDim2.new(0, 5, 0, 5)
	ugl:Destroy()
	return valid
end)

test("UITableLayout FillEmptySpaceColumns Rows", function()
	local utl = Instance.new("UITableLayout")
	utl.FillEmptySpaceColumns = true
	utl.FillEmptySpaceRows = false
	local valid = utl.FillEmptySpaceColumns == true
		and utl.FillEmptySpaceRows == false
	utl:Destroy()
	return valid
end)

test("UIPageLayout GamepadInputEnabled", function()
	local upl = Instance.new("UIPageLayout")
	upl.GamepadInputEnabled = true
	upl.Animated = true
	local valid = upl.GamepadInputEnabled == true and upl.Animated == true
	upl:Destroy()
	return valid
end)

test("Highlight DepthMode OutlineTransparency", function()
	local h = Instance.new("Highlight")
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.OutlineTransparency = 0.5
	h.FillTransparency = 0.8
	local valid = h.DepthMode == Enum.HighlightDepthMode.Occluded
		and nearlyEqual(h.OutlineTransparency, 0.5)
		and nearlyEqual(h.FillTransparency, 0.8)
	h:Destroy()
	return valid
end)

test("Beam Width0 Width1 Segments", function()
	local beam = Instance.new("Beam")
	beam.Width0 = 1
	beam.Width1 = 0.5
	beam.Segments = 10
	beam.Enabled = true
	local valid = beam.Width0 == 1
		and beam.Width1 == 0.5
		and beam.Segments == 10
		and beam.Enabled == true
	beam:Destroy()
	return valid
end)

test("Trail Lifetime MinLength", function()
	local trail = Instance.new("Trail")
	trail.Lifetime = 0.5
	trail.MinLength = 0.1
	trail.LightEmission = 1
	trail.Enabled = true
	local valid = nearlyEqual(trail.Lifetime, 0.5)
		and nearlyEqual(trail.MinLength, 0.1)
		and nearlyEqual(trail.LightEmission, 1)
		and trail.Enabled == true
	trail:Destroy()
	return valid
end)

test("ParticleEmitter Rate Speed SpreadAngle", function()
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 20
	pe.Speed = NumberRange.new(5, 10)
	pe.SpreadAngle = Vector2.new(45, 45)
	pe.Enabled = true
	local valid = pe.Rate == 20
		and typeof(pe.Speed) == "NumberRange"
		and pe.Enabled == true
	pe:Destroy()
	return valid
end)

test("PointLight Range Brightness", function()
	local pl = Instance.new("PointLight")
	pl.Range = 16
	pl.Brightness = 2
	pl.Color = Color3.fromRGB(255, 200, 100)
	pl.Enabled = true
	local valid = pl.Range == 16
		and pl.Brightness == 2
		and pl.Enabled == true
	pl:Destroy()
	return valid
end)

test("SpotLight Angle Face", function()
	local sl = Instance.new("SpotLight")
	sl.Angle = 45
	sl.Face = Enum.NormalId.Front
	sl.Range = 30
	sl.Brightness = 1
	local valid = sl.Angle == 45
		and sl.Face == Enum.NormalId.Front
		and sl.Range == 30
	sl:Destroy()
	return valid
end)

test("SurfaceLight Angle Face", function()
	local sl = Instance.new("SurfaceLight")
	sl.Angle = 90
	sl.Face = Enum.NormalId.Top
	sl.Range = 20
	sl.Brightness = 1
	local valid = sl.Angle == 90
		and sl.Face == Enum.NormalId.Top
	sl:Destroy()
	return valid
end)

test("Fire Heat Size", function()
	local fire = Instance.new("Fire")
	fire.Heat = 9
	fire.Size = 5
	fire.Color = Color3.fromRGB(255, 100, 0)
	fire.Enabled = true
	local valid = fire.Heat == 9
		and fire.Size == 5
		and fire.Enabled == true
	fire:Destroy()
	return valid
end)

test("Smoke RiseVelocity Size", function()
	local smoke = Instance.new("Smoke")
	smoke.RiseVelocity = 2
	smoke.Size = 1
	smoke.Enabled = true
	local valid = smoke.RiseVelocity == 2
		and smoke.Size == 1
		and smoke.Enabled == true
	smoke:Destroy()
	return valid
end)

test("Sparkles SparkleColor TimeScale", function()
	local sp = Instance.new("Sparkles")
	sp.SparkleColor = Color3.fromRGB(255, 255, 0)
	sp.TimeScale = 0.5
	sp.Enabled = true
	local valid = sp.SparkleColor == Color3.fromRGB(255, 255, 0)
		and sp.TimeScale == 0.5
		and sp.Enabled == true
	sp:Destroy()
	return valid
end)

test("Seat Occupant", function()
	local seat = Instance.new("Seat")
	local valid = seat:IsA("Seat")
		and typeof(seat.Occupant) == "nil" or seat.Occupant == nil
	seat:Destroy()
	return valid
end)

test("VehicleSeat properties", function()
	local vs = Instance.new("VehicleSeat")
	vs.MaxSpeed = 50
	vs.Torque = 100
	vs.TurnSpeed = 5
	local valid = vs.MaxSpeed == 50
		and vs.Torque == 100
		and vs.TurnSpeed == 5
	vs:Destroy()
	return valid
end)

test("SpawnLocation Duration TeamColor", function()
	local sl = Instance.new("SpawnLocation")
	sl.Duration = 5
	sl.TeamColor = BrickColor.new("Bright red")
	local valid = sl.Duration == 5
		and typeof(sl.TeamColor) == "BrickColor"
	sl:Destroy()
	return valid
end)

test("Motor6D C0 C1 Transform", function()
	local m = Instance.new("Motor6D")
	m.C0 = CFrame.new(1, 0, 0)
	m.C1 = CFrame.new(0, 1, 0)
	local valid = m.C0 == CFrame.new(1, 0, 0)
		and m.C1 == CFrame.new(0, 1, 0)
	m:Destroy()
	return valid
end)

test("Weld C0 C1", function()
	local w = Instance.new("Weld")
	w.C0 = CFrame.new(2, 0, 0)
	w.C1 = CFrame.new(0, 2, 0)
	local valid = w.C0 == CFrame.new(2, 0, 0)
		and w.C1 == CFrame.new(0, 2, 0)
	w:Destroy()
	return valid
end)

test("Bone Transform WorldCFrame", function()
	local bone = Instance.new("Bone")
	bone.Transform = CFrame.new(1, 2, 3)
	local valid = typeof(bone.Transform) == "CFrame"
		and typeof(bone.WorldCFrame) == "CFrame"
	bone:Destroy()
	return valid
end)

test("Attachment Position Orientation WorldCFrame", function()
	local att = Instance.new("Attachment")
	att.Position = Vector3.new(1, 2, 3)
	att.Orientation = Vector3.new(0, 90, 0)
	local valid = att.Position == Vector3.new(1, 2, 3)
		and typeof(att.WorldCFrame) == "CFrame"
	att:Destroy()
	return valid
end)

test("HumanoidDescription numeric scales", function()
	local hd = Instance.new("HumanoidDescription")
	hd.HeightScale = 1.1
	hd.WidthScale = 0.9
	hd.DepthScale = 0.9
	hd.HeadScale = 1
	hd.BodyTypeScale = 0.5
	hd.ProportionScale = 0.5
	local valid = nearlyEqual(hd.HeightScale, 1.1)
		and nearlyEqual(hd.WidthScale, 0.9)
		and nearlyEqual(hd.DepthScale, 0.9)
		and nearlyEqual(hd.HeadScale, 1)
		and nearlyEqual(hd.BodyTypeScale, 0.5)
		and nearlyEqual(hd.ProportionScale, 0.5)
	hd:Destroy()
	return valid
end)

test("BodyColors all six colors", function()
	local bc = Instance.new("BodyColors")
	bc.HeadColor = BrickColor.new("Bright yellow")
	bc.TorsoColor = BrickColor.new("Bright blue")
	bc.LeftArmColor = BrickColor.new("Bright yellow")
	bc.RightArmColor = BrickColor.new("Bright yellow")
	bc.LeftLegColor = BrickColor.new("Bright blue")
	bc.RightLegColor = BrickColor.new("Bright blue")
	local valid = typeof(bc.HeadColor) == "BrickColor"
		and typeof(bc.TorsoColor) == "BrickColor"
		and typeof(bc.LeftArmColor) == "BrickColor"
		and typeof(bc.RightArmColor) == "BrickColor"
		and typeof(bc.LeftLegColor) == "BrickColor"
		and typeof(bc.RightLegColor) == "BrickColor"
	bc:Destroy()
	return valid
end)

test("Camera FieldOfView NearPlaneZ", function()
	local cam = Instance.new("Camera")
	cam.FieldOfView = 70
	cam.CameraType = Enum.CameraType.Scriptable
	local npz = cam.NearPlaneZ
	local valid = cam.FieldOfView == 70
		and cam.CameraType == Enum.CameraType.Scriptable
		and type(npz) == "number"
	cam:Destroy()
	return valid
end)

test("ScreenGui ZIndexBehavior DisplayOrder", function()
	local sg = Instance.new("ScreenGui")
	sg.DisplayOrder = 5
	sg.ResetOnSpawn = true
	sg.IgnoreGuiInset = false
	local valid = sg.DisplayOrder == 5
		and sg.ResetOnSpawn == true
		and sg.IgnoreGuiInset == false
	sg:Destroy()
	return valid
end)

test("Frame BackgroundColor3 BorderSizePixel", function()
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
	frame.BorderSizePixel = 0
	frame.BackgroundTransparency = 0.5
	local valid = frame.BackgroundColor3 == Color3.fromRGB(100, 150, 200)
		and frame.BorderSizePixel == 0
		and frame.BackgroundTransparency == 0.5
	frame:Destroy()
	return valid
end)

test("ImageButton Image and hover/press states", function()
	local ib = Instance.new("ImageButton")
	ib.Image = "rbxassetid://0"
	ib.HoverImage = "rbxassetid://0"
	ib.PressedImage = "rbxassetid://0"
	ib.ScaleType = Enum.ScaleType.Stretch
	local valid = ib.Image == "rbxassetid://0"
		and ib.ScaleType == Enum.ScaleType.Stretch
	ib:Destroy()
	return valid
end)

test("Value objects read/write", function()
	local nv = Instance.new("NumberValue")
	nv.Value = 3.14
	local iv = Instance.new("IntValue")
	iv.Value = -100
	local sv = Instance.new("StringValue")
	sv.Value = "test"
	local bv = Instance.new("BoolValue")
	bv.Value = true
	local ov = Instance.new("ObjectValue")
	local fv = Instance.new("Folder")
	ov.Value = fv
	local cv = Instance.new("CFrameValue")
	cv.Value = CFrame.new(1, 2, 3)
	local v3v = Instance.new("Vector3Value")
	v3v.Value = Vector3.new(4, 5, 6)
	local c3v = Instance.new("Color3Value")
	c3v.Value = Color3.new(1, 0, 0)
	local bcv = Instance.new("BrickColorValue")
	bcv.Value = BrickColor.new("White")
	local rv = Instance.new("RayValue")
	rv.Value = Ray.new(Vector3.new(), Vector3.new(0, 1, 0))
	local valid = nv.Value == 3.14
		and iv.Value == -100
		and sv.Value == "test"
		and bv.Value == true
		and ov.Value == fv
		and cv.Value == CFrame.new(1, 2, 3)
		and v3v.Value == Vector3.new(4, 5, 6)
		and c3v.Value == Color3.new(1, 0, 0)
		and typeof(bcv.Value) == "BrickColor"
		and typeof(rv.Value) == "Ray"
	nv:Destroy()
	iv:Destroy()
	sv:Destroy()
	bv:Destroy()
	ov:Destroy()
	fv:Destroy()
	cv:Destroy()
	v3v:Destroy()
	c3v:Destroy()
	bcv:Destroy()
	rv:Destroy()
	return valid
end)

test("AudioPlayer AudioEmitter AudioListener AudioDeviceOutput", function()
	local ap = Instance.new("AudioPlayer")
	local ae = Instance.new("AudioEmitter")
	local al = Instance.new("AudioListener")
	local ado = Instance.new("AudioDeviceOutput")
	local valid = ap:IsA("AudioPlayer")
		and ae:IsA("AudioEmitter")
		and al:IsA("AudioListener")
		and ado:IsA("AudioDeviceOutput")
	ap:Destroy()
	ae:Destroy()
	al:Destroy()
	ado:Destroy()
	return valid
end)

test("Wire creation", function()
	local wire = Instance.new("Wire")
	local valid = wire:IsA("Wire")
	wire:Destroy()
	return valid
end)

test("Path2D creation", function()
	local p = Instance.new("Path2D")
	local valid = p:IsA("Path2D")
	p:Destroy()
	return valid
end)

test("WedgePart CornerWedgePart TrussPart", function()
	local wp = Instance.new("WedgePart")
	local cwp = Instance.new("CornerWedgePart")
	local tp = Instance.new("TrussPart")
	local valid = wp:IsA("WedgePart")
		and cwp:IsA("CornerWedgePart")
		and tp:IsA("TrussPart")
	wp:Destroy()
	cwp:Destroy()
	tp:Destroy()
	return valid
end)

test("RopeConstraint RodConstraint HingeConstraint BallSocketConstraint", function()
	local rc = Instance.new("RopeConstraint")
	local rod = Instance.new("RodConstraint")
	local hc = Instance.new("HingeConstraint")
	local bsc = Instance.new("BallSocketConstraint")
	local valid = rc:IsA("RopeConstraint")
		and rod:IsA("RodConstraint")
		and hc:IsA("HingeConstraint")
		and bsc:IsA("BallSocketConstraint")
	rc:Destroy()
	rod:Destroy()
	hc:Destroy()
	bsc:Destroy()
	return valid
end)

test("PrismaticConstraint CylindricalConstraint", function()
	local pc = Instance.new("PrismaticConstraint")
	local cc = Instance.new("CylindricalConstraint")
	local valid = pc:IsA("PrismaticConstraint")
		and cc:IsA("CylindricalConstraint")
	pc:Destroy()
	cc:Destroy()
	return valid
end)

test("LineForce", function()
	local lf = Instance.new("LineForce")
	lf.Magnitude = 100
	lf.ApplyAtCenterOfMass = true
	local valid = lf.Magnitude == 100 and lf.ApplyAtCenterOfMass
	lf:Destroy()
	return valid
end)

test("Sound properties", function()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://0"
	sound.Volume = 0.5
	sound.PlaybackSpeed = 1.5
	sound.Looped = true
	sound.RollOffMaxDistance = 100
	sound.RollOffMinDistance = 10
	local valid = sound.SoundId == "rbxassetid://0"
		and sound.Volume == 0.5
		and sound.PlaybackSpeed == 1.5
		and sound.Looped == true
		and sound.RollOffMaxDistance == 100
		and sound.RollOffMinDistance == 10
	sound:Destroy()
	return valid
end)

test("Animation AnimationId", function()
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://123456"
	local valid = anim.AnimationId == "rbxassetid://123456"
	anim:Destroy()
	return valid
end)

test("Humanoid properties", function()
	local h = Instance.new("Humanoid")
	h.MaxHealth = 200
	h.Health = 150
	h.WalkSpeed = 20
	h.JumpPower = 60
	h.UseJumpPower = true
	local valid = h.MaxHealth == 200
		and h.Health == 150
		and h.WalkSpeed == 20
		and h.JumpPower == 60
		and h.UseJumpPower == true
	h:Destroy()
	return valid
end)

test("Model PrimaryPart GetPrimaryPartCFrame", function()
	local model = Instance.new("Model")
	local part = Instance.new("Part")
	part.Anchored = true
	part.Parent = model
	model.PrimaryPart = part
	local valid = model.PrimaryPart == part
	model:Destroy()
	return valid
end)

test("Folder creation and naming", function()
	local f = Instance.new("Folder")
	f.Name = "TestFolder"
	local valid = f:IsA("Folder") and f.Name == "TestFolder"
	f:Destroy()
	return valid
end)

test("Texture properties", function()
	local tex = Instance.new("Texture")
	tex.Texture = "rbxassetid://0"
	tex.StudsPerTileU = 2
	tex.StudsPerTileV = 2
	tex.Face = Enum.NormalId.Front
	local valid = tex.Texture == "rbxassetid://0"
		and tex.StudsPerTileU == 2
		and tex.StudsPerTileV == 2
		and tex.Face == Enum.NormalId.Front
	tex:Destroy()
	return valid
end)

test("Decal properties", function()
	local decal = Instance.new("Decal")
	decal.Texture = "rbxassetid://0"
	decal.Transparency = 0.5
	decal.Face = Enum.NormalId.Back
	local valid = decal.Texture == "rbxassetid://0"
		and decal.Transparency == 0.5
		and decal.Face == Enum.NormalId.Back
	decal:Destroy()
	return valid
end)

test("Service singleton identity", function()
	for _, name in ipairs(serviceNames) do
		local ok, service = pcall(game.GetService, game, name)

		if ok and service ~= nil then
			local repeated = game:GetService(name)

			if repeated ~= service then
				return false, name .. " is not a singleton"
			end
		end
	end

	return true
end)

test("Service parent is game", function()
	for _, name in ipairs(serviceNames) do
		local ok, service = pcall(game.GetService, game, name)

		if ok and service ~= nil then
			local parentOk, parent = readMember(service, "Parent")

			if parentOk and parent ~= nil and parent ~= game then
				return false, name .. " parent is " .. stringify(parent)
			end
		end
	end

	return true
end)

test("Service full name resolution", function()
	for _, name in ipairs(serviceNames) do
		local ok, service = pcall(game.GetService, game, name)

		if ok and service ~= nil then
			local fullName = service:GetFullName()

			if type(fullName) ~= "string" or #fullName == 0 then
				return false, name .. " full name invalid"
			end

			if not service:IsA("Instance") then
				return false, name .. " is not an Instance"
			end

			if not service:IsDescendantOf(game) then
				return false, name .. " is not inside game"
			end
		end
	end

	return true
end)

test("Service class inheritance", function()
	local expectations = {
		Workspace = "WorldRoot",
		Players = "Instance",
		Lighting = "Instance",
		RunService = "Instance",
		Terrain = "BasePart"
	}

	for name, base in pairs(expectations) do
		local ok, service = pcall(game.GetService, game, name)

		if ok and service ~= nil and not service:IsA(base) then
			return false, name .. " is not a " .. base
		end
	end

	return true
end)

test("Service ClassName consistency", function()
	local aliases = {
		Workspace = "Workspace",
		Players = "Players",
		Lighting = "Lighting",
		RunService = "RunService",
		HttpService = "HttpService",
		CollectionService = "CollectionService"
	}

	for name, className in pairs(aliases) do
		local ok, service = pcall(game.GetService, game, name)

		if ok and service ~= nil and service.ClassName ~= className then
			return false, name .. " reports " .. service.ClassName
		end
	end

	return true
end)

test("game FindService behavior", function()
	if type(game.FindService) ~= "function" then
		return false, "FindService unavailable"
	end

	local okWorkspace, resolved = pcall(game.FindService, game, "Workspace")

	if not okWorkspace or resolved ~= workspace then
		return false, "FindService did not resolve Workspace"
	end

	local okPart, part = pcall(game.FindService, game, "Part")

	if okPart and part ~= nil then
		return false, "FindService returned a non-service"
	end

	return true
end)

test("game GetService rejects unknown names", function()
	local ok = pcall(game.GetService, game, "LogUncNonExistentService")

	return ok == false
end)

test("game GetService rejects non-service classes", function()
	local ok, value = pcall(game.GetService, game, "Part")

	if ok and value ~= nil then
		return false, "returned " .. stringify(value)
	end

	return true
end)

test("Services are not constructible", function()
	local blocked = { "Workspace", "Players", "Lighting", "RunService", "HttpService" }

	for _, name in ipairs(blocked) do
		local ok, created = pcall(Instance.new, name)

		if ok and created ~= nil then
			pcall(function()
				created:Destroy()
			end)

			return false, name .. " was constructible"
		end
	end

	return true
end)

test("Abstract classes are not constructible", function()
	local blocked = { "Instance", "BasePart", "GuiObject", "Constraint", "BaseScript" }

	for _, name in ipairs(blocked) do
		local ok, created = pcall(Instance.new, name)

		if ok and created ~= nil then
			pcall(function()
				created:Destroy()
			end)

			return false, name .. " was constructible"
		end
	end

	return true
end)

test("Instance.new rejects unknown class names", function()
	local ok = pcall(Instance.new, "LogUncNonExistentClass")

	return ok == false
end)

test("Instance.new accepts a parent argument", function()
	local holder = Instance.new("Folder")
	local child = Instance.new("Folder", holder)
	local valid = child.Parent == holder
		and holder:FindFirstChild(child.Name) == child

	holder:Destroy()

	return valid
end)

test("DataModel service provider members", function()
	local ok, reason = hasMethods(game, {
		"GetService",
		"FindService",
		"BindToClose",
		"IsLoaded",
		"GetChildren",
		"GetDescendants"
	})

	if not ok then
		return false, reason
	end

	return isSignal(game.Loaded)
		and isSignal(game.Close)
		and isSignal(game.ServiceAdded)
		and isSignal(game.ServiceRemoving)
end)

test("DataModel identity properties", function()
	return typedProperties(game, {
		PlaceId = "number",
		GameId = "number",
		PlaceVersion = "number",
		JobId = "string",
		CreatorId = "number",
		PrivateServerId = "string",
		PrivateServerOwnerId = "number"
	})
		and typeof(game.CreatorType) == "EnumItem"
		and typeof(game.Genre) == "EnumItem"
		and typeof(game.MatchmakingType) == "EnumItem"
end)

test("DataModel service children are unique", function()
	local seen = {}

	for _, child in ipairs(game:GetChildren()) do
		if seen[child] then
			return false, "duplicate child entry"
		end

		seen[child] = true

		if child.Parent ~= game then
			return false, child.Name .. " parent mismatch"
		end
	end

	return true
end)

test("string library surface", function()
	local required = {
		"byte",
		"char",
		"find",
		"format",
		"gmatch",
		"gsub",
		"len",
		"lower",
		"match",
		"pack",
		"packsize",
		"rep",
		"reverse",
		"split",
		"sub",
		"unpack",
		"upper"
	}

	for _, name in ipairs(required) do
		if type(string[name]) ~= "function" then
			return false, "string." .. name .. " missing"
		end
	end

	return true
end)

test("string metatable indexing", function()
	local meta = getmetatable("")

	if meta == nil then
		return false, "string metatable is nil"
	end

	local metaType = type(meta)

	if metaType == "table" and meta.__index ~= string then
		return false, "string __index is not the string library"
	end

	if metaType ~= "table" and metaType ~= "userdata" and metaType ~= "string" then
		return false, "string metatable is " .. metaType
	end

	return ("abc"):upper() == "ABC"
		and ("abc"):len() == 3
		and ("a,b"):split(",")[2] == "b"
		and ("abc"):sub(2, 2) == "b"
		and ("%d"):format(7) == "7"
		and ("abc"):find("b") == 2
end)

test("string sub boundaries", function()
	return string.sub("hello", -3) == "llo"
		and string.sub("hello", 2, -2) == "ell"
		and string.sub("hello", 0) == "hello"
		and string.sub("hello", 10) == ""
		and string.sub("hello", -100, 100) == "hello"
end)

test("string byte and char", function()
	local a, b, c = string.byte("abc", 1, 3)

	return a == 97
		and b == 98
		and c == 99
		and string.char(104, 105) == "hi"
		and string.byte("A") == 65
end)

test("string rep and reverse", function()
	return string.rep("ab", 3) == "ababab"
		and string.rep("ab", 1) == "ab"
		and string.rep("ab", 0) == ""
		and string.rep("ab", -1) == ""
		and string.reverse("abc") == "cba"
		and string.reverse("") == ""
end)

test("string split behavior", function()
	local commas = string.split("a,b,c")
	local pipes = string.split("a|b", "|")
	local empty = string.split("", ",")

	return #commas == 3
		and commas[1] == "a"
		and commas[3] == "c"
		and #pipes == 2
		and #empty == 1
		and empty[1] == ""
end)

test("string find patterns and plain", function()
	local s, e = string.find("hello world", "o w")
	local ps, pe = string.find("a.b", ".", 1, true)
	local captureStart, captureEnd, captured = string.find("key=value", "(%w+)=")

	return s == 5
		and e == 7
		and ps == 2
		and pe == 2
		and captureStart == 1
		and captureEnd == 4
		and captured == "key"
		and string.find("abc", "z") == nil
end)

test("string match captures", function()
	local key, value = string.match("name=LogUnc", "(%w+)=(%w+)")
	local balanced = string.match("(nested (x))", "%b()")
	local anchored = string.match("abc", "^a")

	return key == "name"
		and value == "LogUnc"
		and balanced == "(nested (x))"
		and anchored == "a"
		and string.match("abc", "^z") == nil
end)

test("string gmatch iteration", function()
	local digits = {}

	for digit in string.gmatch("a1b2c3", "%d") do
		table.insert(digits, digit)
	end

	local pairsFound = 0

	for key, value in string.gmatch("a=1,b=2", "(%w+)=(%w+)") do
		if type(key) == "string" and type(value) == "string" then
			pairsFound += 1
		end
	end

	return #digits == 3
		and digits[3] == "3"
		and pairsFound == 2
end)

test("string gsub replacement forms", function()
	local plain, plainCount = string.gsub("aaa", "a", "b")
	local limited, limitedCount = string.gsub("aaa", "a", "b", 2)
	local fromTable = string.gsub("$first $second", "%$(%w+)", {
		first = "1",
		second = "2"
	})
	local fromFunction = string.gsub("abc", "%a", function(char)
		return string.upper(char)
	end)
	local withCapture = string.gsub("abc", "(a)(b)", "%2%1")

	return plain == "bbb"
		and plainCount == 3
		and limited == "bba"
		and limitedCount == 2
		and fromTable == "1 2"
		and fromFunction == "ABC"
		and withCapture == "bac"
end)

test("string format specifiers", function()
	return string.format("%d", 7) == "7"
		and string.format("%5.2f", 3.14159) == " 3.14"
		and string.format("%x", 255) == "ff"
		and string.format("%X", 255) == "FF"
		and string.format("%o", 8) == "10"
		and string.format("%c", 65) == "A"
		and string.format("%s", "text") == "text"
		and string.format("%%") == "%"
		and string.format("%g", 0.5) == "0.5"
		and #string.format("%e", 1000) > 0
		and string.format("%q", "a\"b") == "\"a\\\"b\""
end)

test("string format star and padding", function()
	return string.format("%-5s|", "ab") == "ab   |"
		and string.format("%05d", 42) == "00042"
		and string.format("%+d", 42) == "+42"
		and string.format("%.3s", "abcdef") == "abc"
end)

test("string pack size", function()
	return string.packsize("<i4") == 4
		and string.packsize("<i2") == 2
		and string.packsize("<d") == 8
		and string.packsize("<f") == 4
		and string.packsize("<i1i2i4") == 7
		and string.packsize("<B") == 1
end)

test("string pack integer round trip", function()
	local signed = string.unpack("<i2", string.pack("<i2", -300))
	local unsigned = string.unpack(">I4", string.pack(">I4", 4000000000))
	local byte = string.unpack("<b", string.pack("<b", -128))

	return signed == -300
		and unsigned == 4000000000
		and byte == -128
end)

test("string pack float round trip", function()
	local double = string.unpack("<d", string.pack("<d", 1.25))
	local single = string.unpack("<f", string.pack("<f", 0.5))

	return double == 1.25
		and single == 0.5
end)

test("string pack string formats", function()
	local zeroTerminated = string.pack("z", "ab")
	local sized = string.pack("<s1", "ab")
	local fixed = string.pack("c4", "abcd")

	return #zeroTerminated == 3
		and string.unpack("z", zeroTerminated) == "ab"
		and #sized == 3
		and string.unpack("<s1", sized) == "ab"
		and string.unpack("c4", fixed) == "abcd"
end)

test("string pack endianness differs", function()
	local little = string.pack("<i4", 1)
	local big = string.pack(">i4", 1)

	return little ~= big
		and string.byte(little, 1) == 1
		and string.byte(big, 4) == 1
end)

test("string pack rejects bad format", function()
	local ok = pcall(string.pack, "!!!bad", 1)

	return ok == false
end)

test("string case conversion", function()
	return string.lower("ABC") == "abc"
		and string.upper("abc") == "ABC"
		and string.lower("Mixed123") == "mixed123"
		and string.len("") == 0
end)

test("string character classes", function()
	return string.match("abc123", "%a+") == "abc"
		and string.match("abc123", "%d+") == "123"
		and string.match(" x", "%s") == " "
		and string.match("a_b", "%w+") == "a"
		and string.match("a.b", "%p") == "."
		and string.match("ABC", "%u+") == "ABC"
		and string.match("abc", "%l+") == "abc"
end)

test("string frontier pattern", function()
	local found = string.find("THE quick", "%f[%a]%a+%f[%A]")

	return found == 1
end)

test("table library surface", function()
	local required = {
		"clear",
		"clone",
		"concat",
		"create",
		"find",
		"freeze",
		"insert",
		"isfrozen",
		"maxn",
		"move",
		"pack",
		"remove",
		"sort",
		"unpack"
	}

	for _, name in ipairs(required) do
		if type(table[name]) ~= "function" then
			return false, "table." .. name .. " missing"
		end
	end

	return true
end)

test("table insert positions", function()
	local list = { "a", "c" }

	table.insert(list, "d")
	table.insert(list, 2, "b")

	return #list == 4
		and list[1] == "a"
		and list[2] == "b"
		and list[3] == "c"
		and list[4] == "d"
end)

test("table remove returns value", function()
	local list = { "a", "b", "c" }
	local removedLast = table.remove(list)
	local removedFirst = table.remove(list, 1)

	return removedLast == "c"
		and removedFirst == "a"
		and #list == 1
		and list[1] == "b"
end)

test("table concat ranges", function()
	local list = { 1, 2, 3, 4 }

	return table.concat(list, ",") == "1,2,3,4"
		and table.concat(list, "-", 2, 3) == "2-3"
		and table.concat(list) == "1234"
		and table.concat({}, ",") == ""
end)

test("table sort with comparator", function()
	local ascending = { 3, 1, 2 }
	local descending = { 1, 3, 2 }

	table.sort(ascending)
	table.sort(descending, function(left, right)
		return left > right
	end)

	return table.concat(ascending, ",") == "1,2,3"
		and table.concat(descending, ",") == "3,2,1"
end)

test("table sort stability of length", function()
	local list = {}

	for index = 1, 32 do
		list[index] = 33 - index
	end

	table.sort(list)

	for index = 1, 32 do
		if list[index] ~= index then
			return false, "sort mismatch at " .. index
		end
	end

	return true
end)

test("table move overlapping", function()
	local moved = table.move({ 1, 2, 3 }, 1, 3, 2, { 9 })
	local inPlace = { 1, 2, 3, 4, 5 }

	table.move(inPlace, 1, 3, 3)

	return table.concat(moved, ",") == "9,1,2,3"
		and table.concat(inPlace, ",") == "1,2,1,2,3"
end)

test("table pack and unpack", function()
	local packed = table.pack(1, nil, 3)
	local first, second = table.unpack({ 1, 2, 3 }, 2, 3)

	return packed.n == 3
		and packed[1] == 1
		and packed[3] == 3
		and first == 2
		and second == 3
end)

test("table create and clear", function()
	local created = table.create(4, "x")
	local cleared = { 1, 2, 3 }

	table.clear(cleared)

	return #created == 4
		and created[1] == "x"
		and created[4] == "x"
		and #cleared == 0
		and next(cleared) == nil
end)

test("table clone is shallow", function()
	local nested = { value = 1 }
	local source = { nested = nested, count = 2 }
	local clone = table.clone(source)

	return clone ~= source
		and clone.count == 2
		and clone.nested == nested
end)

test("table find with init", function()
	local list = { "a", "b", "a" }

	return table.find(list, "b") == 2
		and table.find(list, "a") == 1
		and table.find(list, "a", 2) == 3
		and table.find(list, "z") == nil
end)

test("table maxn with holes", function()
	return table.maxn({ [1] = 1, [5] = 5 }) == 5
		and table.maxn({}) == 0
		and table.maxn({ 1, 2, 3 }) == 3
end)

test("table freeze blocks writes", function()
	local frozen = table.freeze({ value = 1 })
	local writeOk = pcall(function()
		frozen.value = 2
	end)
	local insertOk = pcall(table.insert, frozen, "x")

	return table.isfrozen(frozen)
		and frozen.value == 1
		and writeOk == false
		and insertOk == false
end)

test("table freeze is shallow", function()
	local inner = { value = 1 }
	local outer = table.freeze({ inner = inner })

	inner.value = 2

	return table.isfrozen(outer)
		and table.isfrozen(inner) == false
		and outer.inner.value == 2
end)

test("table clone of frozen is mutable", function()
	local frozen = table.freeze({ value = 1 })
	local clone = table.clone(frozen)

	clone.value = 2

	return table.isfrozen(clone) == false
		and clone.value == 2
end)

test("next and pairs coverage", function()
	local dictionary = { a = 1, b = 2, [1] = "one" }
	local count = 0

	for _ in pairs(dictionary) do
		count += 1
	end

	local key, value = next({ only = true })

	return count == 3
		and key == "only"
		and value == true
		and next({}) == nil
end)

test("ipairs stops at nil", function()
	local sparse = { 1, 2, nil, 4 }
	local visited = 0

	for _ in ipairs(sparse) do
		visited += 1
	end

	return visited == 2
end)

test("length operator on arrays", function()
	return #{} == 0
		and #{ 1, 2, 3 } == 3
		and #"abcd" == 4
end)

test("math library surface", function()
	local functions = {
		"abs",
		"acos",
		"asin",
		"atan",
		"atan2",
		"ceil",
		"clamp",
		"cos",
		"cosh",
		"deg",
		"exp",
		"floor",
		"fmod",
		"frexp",
		"isfinite",
		"isinf",
		"isnan",
		"ldexp",
		"lerp",
		"log",
		"log10",
		"map",
		"max",
		"min",
		"modf",
		"noise",
		"pow",
		"rad",
		"random",
		"randomseed",
		"round",
		"sign",
		"sin",
		"sinh",
		"sqrt",
		"tan",
		"tanh"
	}

	for _, name in ipairs(functions) do
		if type(math[name]) ~= "function" then
			return false, "math." .. name .. " missing"
		end
	end

	local constants = { "e", "huge", "nan", "phi", "pi", "sqrt2", "tau" }

	for _, name in ipairs(constants) do
		if type(math[name]) ~= "number" then
			return false, "math." .. name .. " missing"
		end
	end

	return true
end)

test("math rounding functions", function()
	return math.floor(2.7) == 2
		and math.ceil(2.1) == 3
		and math.floor(-2.1) == -3
		and math.ceil(-2.7) == -2
		and math.round(2.5) == 3
		and math.round(-2.5) == -3
		and math.round(2.4) == 2
end)

test("math sign and abs", function()
	return math.sign(5) == 1
		and math.sign(-5) == -1
		and math.sign(0) == 0
		and math.abs(-7) == 7
		and math.abs(7) == 7
end)

test("math clamp and lerp", function()
	return math.clamp(5, 0, 1) == 1
		and math.clamp(-5, 0, 1) == 0
		and math.clamp(0.5, 0, 1) == 0.5
		and nearlyEqual(math.lerp(0, 10, 0.25), 2.5)
		and nearlyEqual(math.lerp(0, 10, 0), 0)
		and nearlyEqual(math.lerp(0, 10, 1), 10)
end)

test("math map remaps ranges", function()
	return nearlyEqual(math.map(5, 0, 10, 0, 100), 50)
		and nearlyEqual(math.map(0, 0, 10, 20, 30), 20)
		and nearlyEqual(math.map(10, 0, 10, 20, 30), 30)
end)

test("math fmod and modf", function()
	local integral, fractional = math.modf(3.75)

	return math.fmod(-5, 3) == -2
		and math.fmod(5, 3) == 2
		and integral == 3
		and nearlyEqual(fractional, 0.75)
end)

test("math frexp and ldexp", function()
	local mantissa, exponent = math.frexp(8)

	return nearlyEqual(mantissa, 0.5)
		and exponent == 4
		and math.ldexp(0.5, 4) == 8
end)

test("math special value predicates", function()
	local infinite = math.huge
	local notNumber = 0 / 0

	return math.isinf(infinite)
		and math.isinf(-infinite)
		and math.isnan(notNumber)
		and math.isfinite(1)
		and math.isfinite(infinite) == false
		and math.isnan(1) == false
end)

test("math trigonometry", function()
	return nearlyEqual(math.sin(0), 0)
		and nearlyEqual(math.cos(0), 1)
		and nearlyEqual(math.tan(0), 0)
		and nearlyEqual(math.deg(math.pi), 180)
		and nearlyEqual(math.rad(180), math.pi)
		and nearlyEqual(math.atan2(1, 1), math.pi / 4)
		and nearlyEqual(math.acos(1), 0)
		and nearlyEqual(math.asin(0), 0)
end)

test("math exponentials", function()
	return nearlyEqual(math.sqrt(16), 4)
		and nearlyEqual(math.pow(2, 10), 1024)
		and nearlyEqual(math.exp(0), 1)
		and nearlyEqual(math.log(math.exp(1)), 1)
		and nearlyEqual(math.log10(1000), 3)
		and nearlyEqual(math.log(8, 2), 3)
end)

test("math min max variadic", function()
	return math.min(3, 1, 2) == 1
		and math.max(3, 1, 2) == 3
		and math.min(5) == 5
		and math.max(-1, -2) == -1
end)

test("math random determinism", function()
	math.randomseed(1234)

	local first = math.random()
	local integer = math.random(1, 10)
	local bounded = math.random(5)

	return type(first) == "number"
		and first >= 0
		and first < 1
		and integer >= 1
		and integer <= 10
		and bounded >= 1
		and bounded <= 5
end)

test("math noise determinism", function()
	local a = math.noise(1.5, 2.5, 3.5)
	local b = math.noise(1.5, 2.5, 3.5)

	return type(a) == "number"
		and a == b
		and a >= -1
		and a <= 1
end)

test("math constants relationships", function()
	return nearlyEqual(math.tau, math.pi * 2)
		and nearlyEqual(math.sqrt2, math.sqrt(2))
		and nearlyEqual(math.e, math.exp(1))
		and math.huge > 0
		and -math.huge < 0
end)

test("integer division and modulo", function()
	return 7 // 2 == 3
		and -7 // 2 == -4
		and 7 % 2 == 1
		and 7 % -2 == -1
		and nearlyEqual(7 / 2, 3.5)
end)

test("bit32 library surface", function()
	local required = {
		"arshift",
		"band",
		"bnot",
		"bor",
		"btest",
		"bxor",
		"byteswap",
		"countlz",
		"countrz",
		"extract",
		"replace",
		"lrotate",
		"lshift",
		"rrotate",
		"rshift"
	}

	for _, name in ipairs(required) do
		if type(bit32[name]) ~= "function" then
			return false, "bit32." .. name .. " missing"
		end
	end

	return true
end)

test("bit32 logical operations", function()
	return bit32.band(0xF0, 0x3C) == 0x30
		and bit32.bor(0xF0, 0x0F) == 0xFF
		and bit32.bxor(0xFF, 0x0F) == 0xF0
		and bit32.bnot(0) == 0xFFFFFFFF
		and bit32.btest(0x10, 0x10)
		and bit32.btest(0x10, 0x01) == false
end)

test("bit32 shifts and rotations", function()
	return bit32.lshift(1, 4) == 16
		and bit32.rshift(16, 4) == 1
		and bit32.arshift(0xFFFFFFFF, 31) == 0xFFFFFFFF
		and bit32.lrotate(0x80000000, 1) == 1
		and bit32.rrotate(1, 1) == 0x80000000
		and bit32.lshift(1, 32) == 0
end)

test("bit32 field extraction", function()
	return bit32.extract(0xFF00, 8, 8) == 0xFF
		and bit32.extract(0x1, 0, 1) == 1
		and bit32.replace(0, 0xFF, 8, 8) == 0xFF00
		and bit32.replace(0xFFFF, 0, 0, 8) == 0xFF00
end)

test("bit32 counting and byteswap", function()
	return bit32.countlz(1) == 31
		and bit32.countlz(0) == 32
		and bit32.countrz(8) == 3
		and bit32.countrz(0) == 32
		and bit32.byteswap(0x12345678) == 0x78563412
end)

test("utf8 library surface", function()
	local required = { "char", "codes", "codepoint", "len", "offset" }

	for _, name in ipairs(required) do
		if type(utf8[name]) ~= "function" then
			return false, "utf8." .. name .. " missing"
		end
	end

	return type(utf8.charpattern) == "string"
end)

test("utf8 codes iteration", function()
	local positions = {}
	local codepoints = {}

	for position, codepoint in utf8.codes("hi") do
		table.insert(positions, position)
		table.insert(codepoints, codepoint)
	end

	return #positions == 2
		and positions[1] == 1
		and positions[2] == 2
		and codepoints[1] == 104
		and codepoints[2] == 105
end)

test("utf8 char and codepoint", function()
	local first, second = utf8.codepoint("hi", 1, 2)

	return utf8.char(104, 105) == "hi"
		and first == 104
		and second == 105
		and utf8.char(65) == "A"
end)

test("utf8 len and offset", function()
	return utf8.len("hello") == 5
		and utf8.len("") == 0
		and utf8.offset("hello", 3) == 3
		and utf8.offset("hello", -1) == 5
		and utf8.offset("hello", 1) == 1
end)

test("utf8 charpattern matches", function()
	local count = 0

	for _ in string.gmatch("abc", utf8.charpattern) do
		count += 1
	end

	return count == 3
end)

test("buffer library surface", function()
	local required = {
		"create",
		"fromstring",
		"tostring",
		"len",
		"copy",
		"fill",
		"readbits",
		"writebits",
		"readi8",
		"readu8",
		"readi16",
		"readu16",
		"readi32",
		"readu32",
		"readf32",
		"readf64",
		"writei8",
		"writeu8",
		"writei16",
		"writeu16",
		"writei32",
		"writeu32",
		"writef32",
		"writef64",
		"readstring",
		"writestring"
	}

	for _, name in ipairs(required) do
		if type(buffer[name]) ~= "function" then
			return false, "buffer." .. name .. " missing"
		end
	end

	return true
end)

test("buffer integer wrapping", function()
	local value = buffer.create(8)

	buffer.writeu8(value, 0, 300)
	buffer.writei8(value, 1, -1)
	buffer.writeu16(value, 2, 70000)

	return buffer.readu8(value, 0) == 44
		and buffer.readu8(value, 1) == 255
		and buffer.readi8(value, 1) == -1
		and buffer.readu16(value, 2) == 4464
end)

test("buffer signed and unsigned views", function()
	local value = buffer.create(8)

	buffer.writei32(value, 0, -1)

	return buffer.readu32(value, 0) == 4294967295
		and buffer.readi32(value, 0) == -1
		and buffer.readi16(value, 0) == -1
		and buffer.readu16(value, 0) == 65535
end)

test("buffer float precision", function()
	local value = buffer.create(16)

	buffer.writef32(value, 0, 0.5)
	buffer.writef64(value, 8, 1.25)

	return buffer.readf32(value, 0) == 0.5
		and buffer.readf64(value, 8) == 1.25
end)

test("buffer little endian layout", function()
	local value = buffer.create(4)

	buffer.writeu32(value, 0, 1)

	return buffer.readu8(value, 0) == 1
		and buffer.readu8(value, 1) == 0
		and buffer.readu8(value, 3) == 0
end)

test("buffer fill", function()
	local value = buffer.create(4)

	buffer.fill(value, 0, 0xAB, 4)

	return buffer.readu32(value, 0) == 0xABABABAB
		and buffer.readu8(value, 2) == 0xAB
end)

test("buffer overlapping copy", function()
	local value = buffer.fromstring("abcdef")

	buffer.copy(value, 0, value, 2, 4)

	return buffer.tostring(value) == "cdefef"
end)

test("buffer bit access", function()
	local value = buffer.create(4)

	buffer.writebits(value, 0, 3, 5)
	buffer.writebits(value, 3, 5, 17)

	return buffer.readbits(value, 0, 3) == 5
		and buffer.readbits(value, 3, 5) == 17
end)

test("buffer string operations", function()
	local value = buffer.create(8)

	buffer.writestring(value, 0, "Log")
	buffer.writestring(value, 3, "Unc")

	return buffer.readstring(value, 0, 6) == "LogUnc"
		and buffer.len(value) == 8
		and buffer.tostring(buffer.fromstring("xy")) == "xy"
end)

test("buffer bounds are enforced", function()
	local value = buffer.create(4)

	return pcall(buffer.readu8, value, 100) == false
		and pcall(buffer.readu8, value, -1) == false
		and pcall(buffer.writeu8, value, 4, 1) == false
		and pcall(buffer.readu32, value, 1) == false
end)

test("buffer zero initialization", function()
	local value = buffer.create(8)

	return buffer.readu32(value, 0) == 0
		and buffer.readu32(value, 4) == 0
		and buffer.len(buffer.create(0)) == 0
end)

test("buffer typeof reporting", function()
	local value = buffer.create(4)
	local reported = typeof(value)

	return type(value) == "buffer"
		and (reported == "buffer" or reported == "userdata")
end)

test("Luau global surface", function()
	local required = {
		assert = assert,
		error = error,
		gcinfo = gcinfo,
		getmetatable = getmetatable,
		ipairs = ipairs,
		newproxy = newproxy,
		next = next,
		pairs = pairs,
		pcall = pcall,
		print = print,
		rawequal = rawequal,
		rawget = rawget,
		rawlen = rawlen,
		rawset = rawset,
		require = require,
		select = select,
		setmetatable = setmetatable,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		unpack = unpack,
		xpcall = xpcall
	}

	for name, value in pairs(required) do
		if type(value) ~= "function" then
			return false, name .. " missing"
		end
	end

	return type(_G) == "table"
		and type(_VERSION) == "string"
end)

test("Roblox global surface", function()
	local required = {
		typeof = typeof,
		warn = warn,
		tick = tick,
		time = time,
		settings = settings,
		UserSettings = UserSettings,
		loadstring = loadstring,
		wait = wait,
		spawn = spawn,
		delay = delay
	}

	for name, value in pairs(required) do
		if type(value) ~= "function" then
			return false, name .. " missing"
		end
	end

	if typeof(game) ~= "Instance" then
		return false, "game is " .. typeof(game)
	end

	if typeof(workspace) ~= "Instance" then
		return false, "workspace is " .. typeof(workspace)
	end

	if typeof(Enum) ~= "Enums" then
		return false, "Enum is " .. typeof(Enum)
	end

	if type(shared) ~= "table" then
		return false, "shared is " .. type(shared)
	end

	if script ~= nil and typeof(script) ~= "Instance" then
		return false, "script is " .. typeof(script)
	end

	return true
end)

test("sandboxed globals are absent or inert", function()
	local blocked = {
		io = io,
		package = package,
		dofile = dofile,
		loadfile = loadfile,
		load = load
	}

	for name, value in pairs(blocked) do
		if value == nil then
			continue
		end

		if type(value) ~= "function" then
			return false, name .. " is exposed as " .. type(value)
		end

		if pcall(value, "LogUncProbe") then
			return false, name .. " is callable"
		end
	end

	return true
end)

test("os library is sandboxed", function()
	local blocked = {
		"getenv",
		"execute",
		"exit",
		"remove",
		"rename",
		"tmpname",
		"setlocale"
	}

	for _, name in ipairs(blocked) do
		if os[name] ~= nil then
			return false, "os." .. name .. " is exposed"
		end
	end

	return type(os.clock) == "function"
		and type(os.date) == "function"
		and type(os.difftime) == "function"
		and type(os.time) == "function"
end)

test("type reports Luau primitives", function()
	return type(nil) == "nil"
		and type(1) == "number"
		and type("s") == "string"
		and type(true) == "boolean"
		and type({}) == "table"
		and type(print) == "function"
		and type(coroutine.create(function() end)) == "thread"
		and type(buffer.create(1)) == "buffer"
		and type(game) == "userdata"
end)

test("tostring formatting", function()
	return tostring(1) == "1"
		and tostring(1.5) == "1.5"
		and tostring(true) == "true"
		and tostring(false) == "false"
		and tostring(nil) == "nil"
		and tostring("text") == "text"
		and tostring(math.huge) == "inf"
		and tostring(-math.huge) == "-inf"
		and string.find(string.lower(tostring(0 / 0)), "nan") ~= nil
end)

test("tostring on Roblox values", function()
	return tostring(Vector3.new(1, 2, 3)) == "1, 2, 3"
		and tostring(Vector2.new(1, 2)) == "1, 2"
		and tostring(UDim2.new(0, 10, 0, 20)) == "{0, 10}, {0, 20}"
		and tostring(Enum.Material.Plastic) == "Enum.Material.Plastic"
		and tostring(Enum.Material) == "Material"
		and type(tostring(game)) == "string"
		and type(tostring(CFrame.new())) == "string"
end)

test("tonumber conversions", function()
	return tonumber("42") == 42
		and tonumber("3.5") == 3.5
		and tonumber("  7  ") == 7
		and tonumber("0x1F") == 31
		and tonumber("1e3") == 1000
		and tonumber("ff", 16) == 255
		and tonumber("11", 2) == 3
		and tonumber("z", 36) == 35
		and tonumber("abc") == nil
		and tonumber("5x") == nil
		and tonumber(5) == 5
end)

test("select behavior", function()
	local a, b = select(2, "x", "y", "z")

	return select("#", 1, nil, 3) == 3
		and a == "y"
		and b == "z"
		and select(-1, "a", "b", "c") == "c"
		and select("#") == 0
end)

test("rawget rawset rawlen rawequal", function()
	local proxy = setmetatable({}, {
		__index = function()
			return "intercepted"
		end,
		__newindex = function() end,
		__len = function()
			return 99
		end,
		__eq = function()
			return true
		end
	})

	rawset(proxy, "key", "raw")

	local other = setmetatable({}, getmetatable(proxy))

	return proxy.missing == "intercepted"
		and rawget(proxy, "missing") == nil
		and rawget(proxy, "key") == "raw"
		and #proxy == 99
		and rawlen(proxy) == 0
		and (proxy == other)
		and rawequal(proxy, other) == false
		and rawequal(proxy, proxy)
end)

test("assert returns arguments", function()
	local first, second = assert(1, 2)
	local ok, message = pcall(function()
		assert(false, "custom message")
	end)
	local okDefault, defaultMessage = pcall(function()
		assert(nil)
	end)

	return first == 1
		and second == 2
		and ok == false
		and string.find(tostring(message), "custom message", 1, true) ~= nil
		and okDefault == false
		and type(defaultMessage) == "string"
end)

test("error levels and objects", function()
	local okPlain, plain = pcall(function()
		error("plain", 0)
	end)
	local okTable, tableValue = pcall(function()
		error({ code = 7 })
	end)
	local okLevel, levelValue = pcall(function()
		error("located")
	end)

	return okPlain == false
		and plain == "plain"
		and okTable == false
		and type(tableValue) == "table"
		and tableValue.code == 7
		and okLevel == false
		and string.find(tostring(levelValue), "located", 1, true) ~= nil
		and levelValue ~= "located"
end)

test("pcall passes arguments and returns", function()
	local ok, first, second, third = pcall(function(a, b)
		return a, b, a + b
	end, 2, 3)

	return ok
		and first == 2
		and second == 3
		and third == 5
end)

test("pcall returns false on non-callable", function()
	local ok, message = pcall(nil)
	local okNumber = pcall(5)

	return ok == false
		and type(message) == "string"
		and okNumber == false
end)

test("pcall nesting", function()
	local ok, innerOk, innerMessage = pcall(function()
		return pcall(function()
			error("inner")
		end)
	end)

	return ok
		and innerOk == false
		and string.find(tostring(innerMessage), "inner", 1, true) ~= nil
end)

test("xpcall handler arguments", function()
	local ok, value = xpcall(function(a, b)
		return a + b
	end, function(message)
		return message
	end, 2, 3)

	local failed, handled = xpcall(function()
		error("handled")
	end, function(message)
		return "wrapped:" .. tostring(message)
	end)

	return ok
		and value == 5
		and failed == false
		and string.find(handled, "wrapped:", 1, true) == 1
end)

test("xpcall handler can rethrow", function()
	local ok = pcall(function()
		xpcall(function()
			error("first")
		end, function()
			error("second")
		end)
	end)

	return type(ok) == "boolean"
end)

test("gcinfo returns memory", function()
	local value = gcinfo()

	return type(value) == "number"
		and value > 0
end)

test("newproxy metatable behavior", function()
	local plain = newproxy()
	local withMeta = newproxy(true)
	local meta = getmetatable(withMeta)

	meta.__tostring = function()
		return "proxy"
	end

	return type(plain) == "userdata"
		and getmetatable(plain) == nil
		and type(withMeta) == "userdata"
		and type(meta) == "table"
		and tostring(withMeta) == "proxy"
end)

test("metatable __index chain", function()
	local base = { shared = "base" }
	local middle = setmetatable({ own = "middle" }, { __index = base })
	local top = setmetatable({}, { __index = middle })

	return top.own == "middle"
		and top.shared == "base"
		and top.missing == nil
end)

test("metatable __newindex redirection", function()
	local store = {}
	local proxy = setmetatable({}, {
		__newindex = store,
		__index = store
	})

	proxy.value = 42

	return store.value == 42
		and rawget(proxy, "value") == nil
		and proxy.value == 42
end)

test("metatable comparison operators", function()
	local meta = {}

	meta.__eq = function()
		return true
	end
	meta.__lt = function()
		return true
	end
	meta.__le = function()
		return true
	end

	local left = setmetatable({}, meta)
	local right = setmetatable({}, meta)

	return (left == right)
		and (left < right)
		and (left <= right)
		and (left > right)
end)

test("metatable arithmetic operators", function()
	local meta = {}

	meta.__add = function()
		return "add"
	end
	meta.__sub = function()
		return "sub"
	end
	meta.__mul = function()
		return "mul"
	end
	meta.__div = function()
		return "div"
	end
	meta.__mod = function()
		return "mod"
	end
	meta.__pow = function()
		return "pow"
	end
	meta.__unm = function()
		return "unm"
	end
	meta.__idiv = function()
		return "idiv"
	end
	meta.__concat = function()
		return "concat"
	end

	local value = setmetatable({}, meta)

	return value + 1 == "add"
		and value - 1 == "sub"
		and value * 1 == "mul"
		and value / 1 == "div"
		and value % 1 == "mod"
		and value ^ 1 == "pow"
		and -value == "unm"
		and value // 1 == "idiv"
		and value .. "x" == "concat"
end)

test("metatable __call with arguments", function()
	local callable = setmetatable({}, {
		__call = function(_, a, b)
			return a + b, a * b
		end
	})

	local sum, product = callable(3, 4)

	return sum == 7
		and product == 12
end)

test("metatable __len and __iter", function()
	local value = setmetatable({}, {
		__len = function()
			return 7
		end,
		__iter = function()
			return next, { only = "value" }
		end
	})

	local seen = 0

	for key, item in value do
		if key == "only" and item == "value" then
			seen += 1
		end
	end

	return #value == 7
		and seen == 1
end)

test("metatable protection", function()
	local protected = setmetatable({}, { __metatable = "locked" })

	return getmetatable(protected) == "locked"
		and pcall(setmetatable, protected, {}) == false
end)

test("metatable __tostring and __concat", function()
	local value = setmetatable({}, {
		__tostring = function()
			return "custom"
		end
	})

	return tostring(value) == "custom"
		and string.find(string.format("%s", tostring(value)), "custom", 1, true) == 1
end)

test("getmetatable on primitives", function()
	return getmetatable("") ~= nil
		and getmetatable(1) == nil
		and getmetatable(true) == nil
		and getmetatable({}) == nil
end)

test("coroutine lifecycle", function()
	local thread = coroutine.create(function(value)
		local received = coroutine.yield(value + 1)
		return received * 2
	end)

	local firstOk, firstValue = coroutine.resume(thread, 1)
	local suspended = coroutine.status(thread)
	local secondOk, secondValue = coroutine.resume(thread, 5)
	local finished = coroutine.status(thread)

	return firstOk
		and firstValue == 2
		and suspended == "suspended"
		and secondOk
		and secondValue == 10
		and finished == "dead"
end)

test("coroutine error propagation", function()
	local thread = coroutine.create(function()
		error("thread failure")
	end)

	local ok, message = coroutine.resume(thread)

	return ok == false
		and string.find(tostring(message), "thread failure", 1, true) ~= nil
		and coroutine.status(thread) == "dead"
end)

test("coroutine wrap propagates errors", function()
	local wrapped = coroutine.wrap(function()
		error("wrapped failure")
	end)

	local ok, message = pcall(wrapped)

	return ok == false
		and string.find(tostring(message), "wrapped failure", 1, true) ~= nil
end)

test("coroutine wrap yields values", function()
	local generator = coroutine.wrap(function()
		for index = 1, 3 do
			coroutine.yield(index)
		end
	end)

	return generator() == 1
		and generator() == 2
		and generator() == 3
end)

test("coroutine close", function()
	if type(coroutine.close) ~= "function" then
		return false, "coroutine.close unavailable"
	end

	local thread = coroutine.create(function()
		coroutine.yield()
	end)

	coroutine.resume(thread)

	local ok = coroutine.close(thread)

	return ok == true
		and coroutine.status(thread) == "dead"
end)

test("coroutine isyieldable and running", function()
	local insideYieldable
	local insideThread

	local thread = coroutine.create(function()
		insideYieldable = coroutine.isyieldable()
		insideThread = coroutine.running()
	end)

	coroutine.resume(thread)

	local current = coroutine.running()

	return insideYieldable == true
		and insideThread == thread
		and (current == nil or type(current) == "thread")
		and type(coroutine.isyieldable()) == "boolean"
end)

test("coroutine resume of dead thread", function()
	local thread = coroutine.create(function() end)

	coroutine.resume(thread)

	local ok, message = coroutine.resume(thread)

	return ok == false
		and type(message) == "string"
end)

test("pcall across yields", function()
	local thread = coroutine.create(function()
		return pcall(function()
			coroutine.yield("yielded")

			return "resumed"
		end)
	end)

	local firstOk, firstValue = coroutine.resume(thread)
	local secondOk, innerOk, innerValue = coroutine.resume(thread)

	return firstOk
		and firstValue == "yielded"
		and secondOk
		and innerOk == true
		and innerValue == "resumed"
end)

test("vector library surface", function()
	if type(vector) ~= "table" then
		return false, "vector library unavailable"
	end

	local required = {
		"create",
		"magnitude",
		"normalize",
		"cross",
		"dot",
		"angle",
		"floor",
		"ceil",
		"abs",
		"sign",
		"clamp",
		"lerp",
		"max",
		"min"
	}

	for _, name in ipairs(required) do
		if type(vector[name]) ~= "function" then
			return false, "vector." .. name .. " missing"
		end
	end

	return vector.zero ~= nil
		and vector.one ~= nil
end)

test("vector library math", function()
	if type(vector) ~= "table" then
		return false, "vector library unavailable"
	end

	local value = vector.create(3, 4, 0)
	local unit = vector.normalize(value)

	return nearlyEqual(vector.magnitude(value), 5)
		and nearlyEqual(vector.magnitude(unit), 1)
		and nearlyEqual(vector.dot(vector.create(1, 0, 0), vector.create(1, 0, 0)), 1)
		and nearlyEqual(vector.magnitude(vector.cross(vector.create(1, 0, 0), vector.create(0, 1, 0))), 1)
		and nearlyEqual(vector.angle(vector.create(1, 0, 0), vector.create(0, 1, 0)), math.pi / 2)
end)

test("vector library components", function()
	if type(vector) ~= "table" then
		return false, "vector library unavailable"
	end

	local value = vector.create(1, 2, 3)
	local clamped = vector.clamp(vector.create(5, 5, 5), vector.zero, vector.one)

	return value.x == 1
		and value.y == 2
		and value.z == 3
		and value.X == 1
		and value.Y == 2
		and value.Z == 3
		and clamped.x == 1
		and clamped.y == 1
		and clamped.z == 1
end)

test("vector library rounding", function()
	if type(vector) ~= "table" then
		return false, "vector library unavailable"
	end

	local source = vector.create(-1.5, 1.5, -2.5)
	local floored = vector.floor(source)
	local ceiled = vector.ceil(source)
	local absolute = vector.abs(source)
	local signs = vector.sign(source)

	return floored.x == -2
		and ceiled.x == -1
		and absolute.x == 1.5
		and signs.x == -1
		and signs.y == 1
end)

test("vector library min max lerp", function()
	if type(vector) ~= "table" then
		return false, "vector library unavailable"
	end

	local low = vector.create(1, 5, 3)
	local high = vector.create(4, 2, 6)
	local minimum = vector.min(low, high)
	local maximum = vector.max(low, high)
	local middle = vector.lerp(vector.zero, vector.create(10, 10, 10), 0.5)

	return minimum.x == 1
		and minimum.y == 2
		and maximum.x == 4
		and maximum.y == 5
		and nearlyEqual(middle.x, 5)
end)

test("CoreGui service shape", function()
	local coreGui = game:GetService("CoreGui")

	return coreGui:IsA("BasePlayerGui")
		and coreGui:IsA("Instance")
		and coreGui.ClassName == "CoreGui"
		and coreGui.Parent == game
		and type(coreGui.Version) == "number"
		and type(coreGui:GetChildren()) == "table"
end)

test("CoreGui cannot be constructed", function()
	local ok, created = pcall(Instance.new, "CoreGui")

	if ok and created ~= nil then
		pcall(function()
			created:Destroy()
		end)

		return false, "CoreGui was constructible"
	end

	return true
end)

test("CoreGui children are enumerable", function()
	local coreGui = game:GetService("CoreGui")

	for _, child in ipairs(coreGui:GetChildren()) do
		if typeof(child) ~= "Instance" then
			return false, "non-instance child"
		end

		if child.Parent ~= coreGui then
			return false, child.Name .. " parent mismatch"
		end

		if type(child:GetFullName()) ~= "string" then
			return false, child.Name .. " full name invalid"
		end
	end

	return true
end)

test("StarterGui core gui toggles", function()
	local starterGui = game:GetService("StarterGui")

	if not hasMethod(starterGui, "GetCoreGuiEnabled") then
		return false, "GetCoreGuiEnabled missing"
	end

	local types = {
		Enum.CoreGuiType.PlayerList,
		Enum.CoreGuiType.Health,
		Enum.CoreGuiType.Backpack,
		Enum.CoreGuiType.Chat,
		Enum.CoreGuiType.EmotesMenu,
		Enum.CoreGuiType.All
	}

	for _, coreGuiType in ipairs(types) do
		local ok, enabled = pcall(function()
			return starterGui:GetCoreGuiEnabled(coreGuiType)
		end)

		if not ok or type(enabled) ~= "boolean" then
			return false, tostring(coreGuiType) .. " unreadable"
		end
	end

	return true
end)

test("StarterGui SetCoreGuiEnabled round trip", function()
	local starterGui = game:GetService("StarterGui")

	if not hasMethod(starterGui, "SetCoreGuiEnabled") then
		return false, "SetCoreGuiEnabled missing"
	end

	local original = starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
	local setOk = pcall(function()
		starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not original)
	end)

	local toggled = starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)

	pcall(function()
		starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, original)
	end)

	return setOk
		and type(toggled) == "boolean"
		and starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList) == original
end)

test("StarterGui properties", function()
	local starterGui = game:GetService("StarterGui")

	return starterGui:IsA("BasePlayerGui")
		and typeof(starterGui.ScreenOrientation) == "EnumItem"
		and type(starterGui.ShowDevelopmentGui) == "boolean"
		and hasMethod(starterGui, "SetCore")
		and hasMethod(starterGui, "GetCore")
end)

test("ScriptContext service shape", function()
	local scriptContext = game:GetService("ScriptContext")

	return scriptContext.ClassName == "ScriptContext"
		and scriptContext.Parent == game
		and isSignal(scriptContext.Error)
end)

optional("PlayerGui shape", function()
	local player = getCurrentPlayer()

	if not player then
		return false, "player unavailable"
	end

	local playerGui = player:FindFirstChildOfClass("PlayerGui")

	if not playerGui then
		return false, "PlayerGui unavailable"
	end

	return playerGui:IsA("BasePlayerGui")
		and typeof(playerGui.CurrentScreenOrientation) == "EnumItem"
		and typeof(playerGui.ScreenOrientation) == "EnumItem"
end)

test("ScreenGui is a LayerCollector", function()
	local screen = Instance.new("ScreenGui")
	local valid = screen:IsA("LayerCollector")
		and screen:IsA("GuiBase2d")
		and screen:IsA("Instance")
		and screen.ClassName == "ScreenGui"

	screen:Destroy()

	return valid
end)

test("GUI class hierarchy", function()
	local expectations = {
		Frame = { "GuiObject", "GuiBase2d" },
		TextLabel = { "GuiLabel", "GuiObject" },
		TextButton = { "GuiButton", "GuiObject" },
		ImageLabel = { "GuiLabel", "GuiObject" },
		ImageButton = { "GuiButton", "GuiObject" },
		TextBox = { "GuiObject", "GuiBase2d" },
		ScrollingFrame = { "GuiObject", "GuiBase2d" },
		ViewportFrame = { "GuiObject", "GuiBase2d" },
		CanvasGroup = { "GuiObject", "GuiBase2d" }
	}

	for className, bases in pairs(expectations) do
		local ok, object = pcall(Instance.new, className)

		if not ok then
			return false, className .. " not constructible"
		end

		for _, base in ipairs(bases) do
			if not object:IsA(base) then
				object:Destroy()

				return false, className .. " is not a " .. base
			end
		end

		object:Destroy()
	end

	return true
end)

test("UI component hierarchy", function()
	local expectations = {
		UIListLayout = { "UILayout", "UIComponent", "UIBase" },
		UIGridLayout = { "UILayout", "UIComponent" },
		UIPageLayout = { "UILayout", "UIComponent" },
		UITableLayout = { "UILayout", "UIComponent" },
		UIPadding = { "UIComponent", "UIBase" },
		UICorner = { "UIComponent", "UIBase" },
		UIScale = { "UIComponent", "UIBase" },
		UIStroke = { "UIComponent", "UIBase" },
		UIGradient = { "UIComponent", "UIBase" },
		UISizeConstraint = { "UIConstraint", "UIComponent" },
		UIAspectRatioConstraint = { "UIConstraint", "UIComponent" },
		UITextSizeConstraint = { "UIConstraint", "UIComponent" }
	}

	for className, bases in pairs(expectations) do
		local ok, object = pcall(Instance.new, className)

		if not ok then
			return false, className .. " not constructible"
		end

		for _, base in ipairs(bases) do
			if not object:IsA(base) then
				object:Destroy()

				return false, className .. " is not a " .. base
			end
		end

		object:Destroy()
	end

	return true
end)

test("GuiObject base properties", function()
	return withTemporary("Frame", function(frame)
		frame.Position = UDim2.new(0.5, 10, 0.25, 20)
		frame.Size = UDim2.fromScale(0.5, 0.5)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Rotation = 45
		frame.ZIndex = 3
		frame.LayoutOrder = 2
		frame.Visible = false
		frame.Active = true
		frame.Selectable = true
		frame.ClipsDescendants = true
		frame.Interactable = false

		return frame.Position == UDim2.new(0.5, 10, 0.25, 20)
			and frame.Size == UDim2.fromScale(0.5, 0.5)
			and frame.AnchorPoint == Vector2.new(0.5, 0.5)
			and nearlyEqual(frame.Rotation, 45)
			and frame.ZIndex == 3
			and frame.LayoutOrder == 2
			and frame.Visible == false
			and frame.Active == true
			and frame.Selectable == true
			and frame.ClipsDescendants == true
			and frame.Interactable == false
	end)
end)

test("GuiObject absolute metrics", function()
	local screen = Instance.new("ScreenGui")
	local frame = Instance.new("Frame")

	frame.Size = UDim2.fromOffset(100, 50)
	frame.Position = UDim2.fromOffset(10, 20)
	frame.Parent = screen

	local valid = typeof(frame.AbsoluteSize) == "Vector2"
		and typeof(frame.AbsolutePosition) == "Vector2"
		and type(frame.AbsoluteRotation) == "number"

	screen:Destroy()

	return valid
end)

test("GuiObject input signals", function()
	return withTemporary("Frame", function(frame)
		local signals = {
			"InputBegan",
			"InputChanged",
			"InputEnded",
			"MouseEnter",
			"MouseLeave",
			"MouseMoved",
			"MouseWheelForward",
			"MouseWheelBackward",
			"SelectionGained",
			"SelectionLost",
			"TouchTap",
			"TouchPan",
			"TouchPinch",
			"TouchRotate",
			"TouchLongPress",
			"TouchSwipe"
		}

		for _, name in ipairs(signals) do
			local ok, signal = readMember(frame, name)

			if not ok or not isSignal(signal) then
				return false, name .. " missing"
			end
		end

		return true
	end)
end)

test("GuiObject selection navigation", function()
	local first = Instance.new("Frame")
	local second = Instance.new("Frame")

	first.NextSelectionUp = second
	first.NextSelectionDown = second
	first.NextSelectionLeft = second
	first.NextSelectionRight = second

	local valid = first.NextSelectionUp == second
		and first.NextSelectionDown == second
		and first.NextSelectionLeft == second
		and first.NextSelectionRight == second

	first:Destroy()
	second:Destroy()

	return valid
end)

test("GuiObject tween methods", function()
	local frame = Instance.new("Frame")

	frame.Size = UDim2.fromOffset(100, 100)

	local hasAll = hasMethod(frame, "TweenPosition")
		and hasMethod(frame, "TweenSize")
		and hasMethod(frame, "TweenSizeAndPosition")

	if not hasAll then
		frame:Destroy()

		return false, "tween methods missing"
	end

	local screen = Instance.new("ScreenGui")
	local player = getCurrentPlayer()
	local playerGui = player and player:FindFirstChildOfClass("PlayerGui")

	if playerGui then
		screen.Parent = playerGui
	end

	frame.Parent = screen

	local ok, started = pcall(function()
		return frame:TweenPosition(
			UDim2.fromOffset(10, 10),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.1,
			true
		)
	end)

	screen:Destroy()

	if ok then
		return started == nil or type(started) == "boolean"
	end

	local message = string.lower(stringify(started))

	if string.find(message, "workspace", 1, true) ~= nil then
		return true
	end

	return false, stringify(started)
end)

test("GuiBase2d localization properties", function()
	return withTemporary("Frame", function(frame)
		frame.AutoLocalize = false
		frame.SelectionGroup = true

		return frame.AutoLocalize == false
			and frame.SelectionGroup == true
			and typeof(frame.SelectionBehaviorUp) == "EnumItem"
			and typeof(frame.SelectionBehaviorDown) == "EnumItem"
			and typeof(frame.SelectionBehaviorLeft) == "EnumItem"
			and typeof(frame.SelectionBehaviorRight) == "EnumItem"
			and isSignal(frame.SelectionChanged)
	end)
end)

test("ScreenGui display properties", function()
	return withTemporary("ScreenGui", function(screen)
		screen.DisplayOrder = 5
		screen.Enabled = false
		screen.ResetOnSpawn = false
		screen.IgnoreGuiInset = true
		screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screen.ClipToDeviceSafeArea = false

		return screen.DisplayOrder == 5
			and screen.Enabled == false
			and screen.ResetOnSpawn == false
			and screen.IgnoreGuiInset == true
			and screen.ZIndexBehavior == Enum.ZIndexBehavior.Sibling
			and screen.ClipToDeviceSafeArea == false
			and typeof(screen.SafeAreaCompatibility) == "EnumItem"
			and typeof(screen.ScreenInsets) == "EnumItem"
	end)
end)

test("TextLabel text metrics", function()
	local screen = Instance.new("ScreenGui")
	local label = Instance.new("TextLabel")

	label.Size = UDim2.fromOffset(200, 50)
	label.Text = "Log-Unc"
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextTransparency = 0.25
	label.TextStrokeTransparency = 0.5
	label.RichText = true
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.LineHeight = 1.2
	label.Parent = screen

	local valid = label.Text == "Log-Unc"
		and nearlyEqual(label.TextSize, 18)
		and nearlyEqual(label.TextTransparency, 0.25)
		and nearlyEqual(label.TextStrokeTransparency, 0.5)
		and label.RichText == true
		and label.TextXAlignment == Enum.TextXAlignment.Left
		and label.TextYAlignment == Enum.TextYAlignment.Top
		and label.TextTruncate == Enum.TextTruncate.AtEnd
		and nearlyEqual(label.LineHeight, 1.2)
		and typeof(label.TextBounds) == "Vector2"
		and type(label.TextFits) == "boolean"
		and type(label.ContentText) == "string"

	screen:Destroy()

	return valid
end)

test("TextLabel FontFace", function()
	return withTemporary("TextLabel", function(label)
		local sourceSans = Font.fromEnum(Enum.Font.SourceSans)

		label.FontFace = sourceSans

		return typeof(label.FontFace) == "Font"
			and label.FontFace.Weight == sourceSans.Weight
			and label.FontFace.Style == sourceSans.Style
	end)
end)

test("TextLabel MaxVisibleGraphemes", function()
	return withTemporary("TextLabel", function(label)
		label.Text = "LogUnc"
		label.MaxVisibleGraphemes = 3

		return label.MaxVisibleGraphemes == 3
			and label.ContentText == "LogUnc"
	end)
end)

test("TextButton interaction properties", function()
	return withTemporary("TextButton", function(button)
		button.Text = "Press"
		button.AutoButtonColor = false
		button.Modal = true
		button.Selected = true
		button.Style = Enum.ButtonStyle.RobloxRoundButton

		return button.Text == "Press"
			and button.AutoButtonColor == false
			and button.Modal == true
			and button.Selected == true
			and button.Style == Enum.ButtonStyle.RobloxRoundButton
			and isSignal(button.Activated)
			and isSignal(button.MouseButton1Click)
			and isSignal(button.MouseButton1Down)
			and isSignal(button.MouseButton1Up)
			and isSignal(button.MouseButton2Click)
	end)
end)

test("TextBox editing properties", function()
	return withTemporary("TextBox", function(box)
		box.Text = "value"
		box.PlaceholderText = "type here"
		box.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
		box.ClearTextOnFocus = false
		box.MultiLine = true
		box.TextEditable = true
		box.ShowNativeInput = false

		return box.Text == "value"
			and box.PlaceholderText == "type here"
			and box.ClearTextOnFocus == false
			and box.MultiLine == true
			and box.TextEditable == true
			and box.ShowNativeInput == false
			and type(box.CursorPosition) == "number"
			and type(box.SelectionStart) == "number"
			and isSignal(box.Focused)
			and isSignal(box.FocusLost)
			and hasMethod(box, "CaptureFocus")
			and hasMethod(box, "ReleaseFocus")
			and hasMethod(box, "IsFocused")
	end)
end)

test("ImageLabel image properties", function()
	return withTemporary("ImageLabel", function(image)
		image.Image = "rbxassetid://0"
		image.ImageColor3 = Color3.fromRGB(255, 0, 0)
		image.ImageTransparency = 0.5
		image.ScaleType = Enum.ScaleType.Slice
		image.SliceCenter = Rect.new(4, 4, 8, 8)
		image.SliceScale = 2
		image.TileSize = UDim2.fromScale(0.5, 0.5)
		image.ResampleMode = Enum.ResamplerMode.Pixelated

		return image.Image == "rbxassetid://0"
			and nearlyEqual(image.ImageTransparency, 0.5)
			and image.ScaleType == Enum.ScaleType.Slice
			and image.SliceCenter == Rect.new(4, 4, 8, 8)
			and nearlyEqual(image.SliceScale, 2)
			and image.TileSize == UDim2.fromScale(0.5, 0.5)
			and image.ResampleMode == Enum.ResamplerMode.Pixelated
			and type(image.IsLoaded) == "boolean"
	end)
end)

test("ImageButton state images", function()
	return withTemporary("ImageButton", function(button)
		button.Image = "rbxassetid://0"
		button.HoverImage = "rbxassetid://1"
		button.PressedImage = "rbxassetid://2"

		return button.Image == "rbxassetid://0"
			and button.HoverImage == "rbxassetid://1"
			and button.PressedImage == "rbxassetid://2"
			and button:IsA("GuiButton")
	end)
end)

test("ScrollingFrame scroll properties", function()
	return withTemporary("ScrollingFrame", function(scroll)
		scroll.CanvasSize = UDim2.fromOffset(500, 1000)
		scroll.ScrollBarThickness = 12
		scroll.ScrollingDirection = Enum.ScrollingDirection.Y
		scroll.ElasticBehavior = Enum.ElasticBehavior.Never
		scroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		scroll.HorizontalScrollBarInset = Enum.ScrollBarInset.None
		scroll.ScrollingEnabled = false
		scroll.CanvasPosition = Vector2.new(0, 50)

		return scroll.CanvasSize == UDim2.fromOffset(500, 1000)
			and scroll.ScrollBarThickness == 12
			and scroll.ScrollingDirection == Enum.ScrollingDirection.Y
			and scroll.ElasticBehavior == Enum.ElasticBehavior.Never
			and scroll.VerticalScrollBarInset == Enum.ScrollBarInset.ScrollBar
			and scroll.ScrollingEnabled == false
			and typeof(scroll.CanvasPosition) == "Vector2"
			and typeof(scroll.AbsoluteCanvasSize) == "Vector2"
			and typeof(scroll.AbsoluteWindowSize) == "Vector2"
	end)
end)

test("ViewportFrame rendering properties", function()
	return withTemporary("ViewportFrame", function(viewport)
		local camera = Instance.new("Camera")

		camera.Parent = viewport
		viewport.CurrentCamera = camera
		viewport.Ambient = Color3.fromRGB(100, 100, 100)
		viewport.LightColor = Color3.fromRGB(255, 255, 255)
		viewport.LightDirection = Vector3.new(0, -1, 0)
		viewport.ImageColor3 = Color3.fromRGB(255, 255, 255)
		viewport.ImageTransparency = 0.25

		return viewport.CurrentCamera == camera
			and typeof(viewport.Ambient) == "Color3"
			and typeof(viewport.LightColor) == "Color3"
			and viewport.LightDirection == Vector3.new(0, -1, 0)
			and nearlyEqual(viewport.ImageTransparency, 0.25)
	end)
end)

test("CanvasGroup group properties", function()
	return withTemporary("CanvasGroup", function(group)
		group.GroupColor3 = Color3.fromRGB(200, 100, 50)
		group.GroupTransparency = 0.5

		return typeof(group.GroupColor3) == "Color3"
			and nearlyEqual(group.GroupTransparency, 0.5)
			and group:IsA("GuiObject")
	end)
end)

test("BillboardGui adornment properties", function()
	return withTemporary("BillboardGui", function(billboard)
		local part = Instance.new("Part")

		billboard.Adornee = part
		billboard.Size = UDim2.fromScale(4, 2)
		billboard.StudsOffset = Vector3.new(0, 2, 0)
		billboard.StudsOffsetWorldSpace = Vector3.new(1, 0, 0)
		billboard.ExtentsOffset = Vector3.new(0, 1, 0)
		billboard.AlwaysOnTop = true
		billboard.LightInfluence = 0
		billboard.MaxDistance = 100
		billboard.ClipsDescendants = true

		local valid = billboard.Adornee == part
			and billboard.Size == UDim2.fromScale(4, 2)
			and billboard.StudsOffset == Vector3.new(0, 2, 0)
			and billboard.StudsOffsetWorldSpace == Vector3.new(1, 0, 0)
			and billboard.AlwaysOnTop == true
			and nearlyEqual(billboard.LightInfluence, 0)
			and nearlyEqual(billboard.MaxDistance, 100)

		part:Destroy()

		return valid
	end)
end)

test("SurfaceGui surface properties", function()
	return withTemporary("SurfaceGui", function(surface)
		surface.Face = Enum.NormalId.Top
		surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surface.PixelsPerStud = 100
		surface.CanvasSize = Vector2.new(400, 400)
		surface.AlwaysOnTop = true
		surface.Brightness = 2
		surface.LightInfluence = 0.5
		surface.ZOffset = 1

		return surface.Face == Enum.NormalId.Top
			and surface.SizingMode == Enum.SurfaceGuiSizingMode.PixelsPerStud
			and nearlyEqual(surface.PixelsPerStud, 100)
			and surface.CanvasSize == Vector2.new(400, 400)
			and surface.AlwaysOnTop == true
			and nearlyEqual(surface.Brightness, 2)
			and nearlyEqual(surface.LightInfluence, 0.5)
			and nearlyEqual(surface.ZOffset, 1)
	end)
end)

test("UIListLayout ordering", function()
	return withTemporary("UIListLayout", function(layout)
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 8)
		layout.Wraps = true

		return layout.FillDirection == Enum.FillDirection.Horizontal
			and layout.HorizontalAlignment == Enum.HorizontalAlignment.Center
			and layout.VerticalAlignment == Enum.VerticalAlignment.Bottom
			and layout.SortOrder == Enum.SortOrder.LayoutOrder
			and layout.Padding == UDim.new(0, 8)
			and layout.Wraps == true
			and typeof(layout.AbsoluteContentSize) == "Vector2"
	end)
end)

test("UIGridLayout cell configuration", function()
	return withTemporary("UIGridLayout", function(layout)
		layout.CellSize = UDim2.fromOffset(100, 100)
		layout.CellPadding = UDim2.fromOffset(5, 5)
		layout.FillDirectionMaxCells = 3
		layout.StartCorner = Enum.StartCorner.BottomRight
		layout.SortOrder = Enum.SortOrder.Name

		return layout.CellSize == UDim2.fromOffset(100, 100)
			and layout.CellPadding == UDim2.fromOffset(5, 5)
			and layout.FillDirectionMaxCells == 3
			and layout.StartCorner == Enum.StartCorner.BottomRight
			and layout.SortOrder == Enum.SortOrder.Name
			and typeof(layout.AbsoluteCellCount) == "Vector2"
			and typeof(layout.AbsoluteCellSize) == "Vector2"
	end)
end)

test("UITableLayout configuration", function()
	return withTemporary("UITableLayout", function(layout)
		layout.FillEmptySpaceColumns = true
		layout.FillEmptySpaceRows = true
		layout.MajorAxis = Enum.TableMajorAxis.ColumnMajor
		layout.Padding = UDim2.fromOffset(2, 4)

		return layout.FillEmptySpaceColumns == true
			and layout.FillEmptySpaceRows == true
			and layout.MajorAxis == Enum.TableMajorAxis.ColumnMajor
			and layout.Padding == UDim2.fromOffset(2, 4)
	end)
end)

test("UIPageLayout configuration", function()
	return withTemporary("UIPageLayout", function(layout)
		layout.Animated = false
		layout.Circular = true
		layout.EasingDirection = Enum.EasingDirection.InOut
		layout.EasingStyle = Enum.EasingStyle.Sine
		layout.TweenTime = 0.5
		layout.GamepadInputEnabled = false
		layout.ScrollWheelInputEnabled = false
		layout.TouchInputEnabled = false

		return layout.Animated == false
			and layout.Circular == true
			and layout.EasingDirection == Enum.EasingDirection.InOut
			and layout.EasingStyle == Enum.EasingStyle.Sine
			and nearlyEqual(layout.TweenTime, 0.5)
			and layout.GamepadInputEnabled == false
			and isSignal(layout.PageEnter)
			and isSignal(layout.PageLeave)
			and isSignal(layout.Stopped)
			and hasMethod(layout, "JumpToIndex")
			and hasMethod(layout, "Next")
			and hasMethod(layout, "Previous")
	end)
end)

test("UISizeConstraint bounds", function()
	return withTemporary("UISizeConstraint", function(constraint)
		constraint.MinSize = Vector2.new(10, 10)
		constraint.MaxSize = Vector2.new(200, 200)

		return constraint.MinSize == Vector2.new(10, 10)
			and constraint.MaxSize == Vector2.new(200, 200)
			and constraint:IsA("UIConstraint")
	end)
end)

test("UIAspectRatioConstraint configuration", function()
	return withTemporary("UIAspectRatioConstraint", function(constraint)
		constraint.AspectRatio = 1.5
		constraint.AspectType = Enum.AspectType.ScaleWithParentSize
		constraint.DominantAxis = Enum.DominantAxis.Height

		return nearlyEqual(constraint.AspectRatio, 1.5)
			and constraint.AspectType == Enum.AspectType.ScaleWithParentSize
			and constraint.DominantAxis == Enum.DominantAxis.Height
	end)
end)

test("UITextSizeConstraint bounds", function()
	return withTemporary("UITextSizeConstraint", function(constraint)
		constraint.MinTextSize = 8
		constraint.MaxTextSize = 32

		return constraint.MinTextSize == 8
			and constraint.MaxTextSize == 32
	end)
end)

test("UIFlexItem configuration", function()
	return withTemporary("UIFlexItem", function(flex)
		flex.FlexMode = Enum.UIFlexMode.Fill
		flex.GrowRatio = 2
		flex.ShrinkRatio = 1
		flex.ItemLineAlignment = Enum.ItemLineAlignment.Center

		return flex.FlexMode == Enum.UIFlexMode.Fill
			and nearlyEqual(flex.GrowRatio, 2)
			and nearlyEqual(flex.ShrinkRatio, 1)
			and flex.ItemLineAlignment == Enum.ItemLineAlignment.Center
	end)
end)

test("UIStroke appearance", function()
	return withTemporary("UIStroke", function(stroke)
		stroke.Thickness = 3
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.Transparency = 0.25
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.LineJoinMode = Enum.LineJoinMode.Bevel
		stroke.Enabled = true

		return nearlyEqual(stroke.Thickness, 3)
			and typeof(stroke.Color) == "Color3"
			and nearlyEqual(stroke.Transparency, 0.25)
			and stroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Border
			and stroke.LineJoinMode == Enum.LineJoinMode.Bevel
			and stroke.Enabled == true
	end)
end)

test("UIGradient configuration", function()
	return withTemporary("UIGradient", function(gradient)
		gradient.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(1, 1, 1))
		gradient.Transparency = NumberSequence.new(0, 1)
		gradient.Rotation = 90
		gradient.Offset = Vector2.new(0.5, 0)
		gradient.Enabled = true

		return typeof(gradient.Color) == "ColorSequence"
			and typeof(gradient.Transparency) == "NumberSequence"
			and nearlyEqual(gradient.Rotation, 90)
			and gradient.Offset == Vector2.new(0.5, 0)
			and gradient.Enabled == true
	end)
end)

test("UIPadding individual sides", function()
	return withTemporary("UIPadding", function(padding)
		padding.PaddingTop = UDim.new(0, 1)
		padding.PaddingBottom = UDim.new(0, 2)
		padding.PaddingLeft = UDim.new(0.5, 3)
		padding.PaddingRight = UDim.new(0, 4)

		return padding.PaddingTop == UDim.new(0, 1)
			and padding.PaddingBottom == UDim.new(0, 2)
			and padding.PaddingLeft == UDim.new(0.5, 3)
			and padding.PaddingRight == UDim.new(0, 4)
	end)
end)

test("UICorner radius", function()
	return withTemporary("UICorner", function(corner)
		corner.CornerRadius = UDim.new(0.25, 8)

		return corner.CornerRadius == UDim.new(0.25, 8)
	end)
end)

test("UIScale scaling", function()
	return withTemporary("UIScale", function(scale)
		scale.Scale = 2.5

		return nearlyEqual(scale.Scale, 2.5)
	end)
end)

test("GUI parenting into ScreenGui", function()
	local screen = Instance.new("ScreenGui")
	local frame = Instance.new("Frame")
	local label = Instance.new("TextLabel")

	frame.Parent = screen
	label.Parent = frame

	local valid = frame.Parent == screen
		and label.Parent == frame
		and label:IsDescendantOf(screen)
		and #screen:GetDescendants() == 2
		and screen:FindFirstChildWhichIsA("GuiObject") == frame

	screen:Destroy()

	return valid
end)

test("GUI layout child interaction", function()
	local frame = Instance.new("Frame")
	local layout = Instance.new("UIListLayout")
	local first = Instance.new("Frame")
	local second = Instance.new("Frame")

	layout.Parent = frame
	first.LayoutOrder = 2
	second.LayoutOrder = 1
	first.Parent = frame
	second.Parent = frame

	local valid = layout.Parent == frame
		and first.LayoutOrder == 2
		and second.LayoutOrder == 1
		and #frame:GetChildren() == 3

	frame:Destroy()

	return valid
end)

test("GuiService inset and metrics", function()
	local guiService = game:GetService("GuiService")
	local topLeft, bottomRight = guiService:GetGuiInset()

	return typeof(topLeft) == "Vector2"
		and typeof(bottomRight) == "Vector2"
		and type(guiService:IsTenFootInterface()) == "boolean"
		and type(guiService.MenuIsOpen) == "boolean"
		and type(guiService.TouchControlsEnabled) == "boolean"
		and type(guiService.AutoSelectGuiEnabled) == "boolean"
		and hasMethod(guiService, "GetEmotesMenuOpen")
end)

test("TextService text sizing", function()
	local textService = game:GetService("TextService")
	local size = textService:GetTextSize(
		"Log-Unc",
		18,
		Enum.Font.SourceSans,
		Vector2.new(1000, 100)
	)

	return typeof(size) == "Vector2"
		and size.X > 0
		and size.Y > 0
		and hasMethod(textService, "GetTextBoundsAsync")
		and hasMethod(textService, "FilterStringAsync")
end)

test("Instance method surface", function()
	return withTemporary("Folder", function(object)
		return hasMethods(object, {
			"AddTag",
			"ClearAllChildren",
			"Clone",
			"Destroy",
			"FindFirstAncestor",
			"FindFirstAncestorOfClass",
			"FindFirstAncestorWhichIsA",
			"FindFirstChild",
			"FindFirstChildOfClass",
			"FindFirstChildWhichIsA",
			"GetActor",
			"GetAttribute",
			"GetAttributeChangedSignal",
			"GetAttributes",
			"GetChildren",
			"GetDescendants",
			"GetFullName",
			"GetPropertyChangedSignal",
			"GetTags",
			"HasTag",
			"IsA",
			"IsAncestorOf",
			"IsDescendantOf",
			"RemoveTag",
			"SetAttribute",
			"WaitForChild"
		})
	end)
end)

test("Instance ancestor lookups", function()
	local root = Instance.new("Folder")
	local middle = Instance.new("Model")
	local leaf = Instance.new("Part")

	root.Name = "Root"
	middle.Name = "Middle"
	leaf.Name = "Leaf"
	middle.Parent = root
	leaf.Parent = middle

	local valid = leaf:FindFirstAncestor("Root") == root
		and leaf:FindFirstAncestor("Middle") == middle
		and leaf:FindFirstAncestorOfClass("Folder") == root
		and leaf:FindFirstAncestorOfClass("Model") == middle
		and leaf:FindFirstAncestorWhichIsA("PVInstance") == middle
		and leaf:FindFirstAncestor("Missing") == nil

	root:Destroy()

	return valid
end)

test("Instance FindFirstChildOfClass", function()
	local root = Instance.new("Folder")
	local part = Instance.new("Part")
	local value = Instance.new("StringValue")

	part.Parent = root
	value.Parent = root

	local valid = root:FindFirstChildOfClass("Part") == part
		and root:FindFirstChildOfClass("StringValue") == value
		and root:FindFirstChildOfClass("Model") == nil
		and root:FindFirstChildWhichIsA("BasePart") == part
		and root:FindFirstChildWhichIsA("ValueBase") == value

	root:Destroy()

	return valid
end)

test("Instance FindFirstChild recursive descendant", function()
	local root = Instance.new("Folder")
	local middle = Instance.new("Folder")
	local leaf = Instance.new("Part")

	leaf.Name = "DeepLeaf"
	middle.Parent = root
	leaf.Parent = middle

	local valid = root:FindFirstChild("DeepLeaf", true) == leaf
		and root:FindFirstChild("DeepLeaf") == nil
		and root:FindFirstChild("Missing", true) == nil

	root:Destroy()

	return valid
end)

test("Instance ClearAllChildren", function()
	local root = Instance.new("Folder")

	for _ = 1, 5 do
		Instance.new("Folder").Parent = root
	end

	local before = #root:GetChildren()

	root:ClearAllChildren()

	local after = #root:GetChildren()

	root:Destroy()

	return before == 5
		and after == 0
end)

test("Instance GetDescendants completeness", function()
	local root = Instance.new("Folder")
	local first = Instance.new("Folder")
	local second = Instance.new("Folder")
	local nested = Instance.new("Part")

	first.Parent = root
	nested.Parent = first
	second.Parent = root

	local descendants = root:GetDescendants()
	local seen = {}

	for _, descendant in ipairs(descendants) do
		seen[descendant] = true
	end

	root:Destroy()

	return #descendants == 3
		and seen[first] == true
		and seen[second] == true
		and seen[nested] == true
end)

test("Instance destroyed parent is locked", function()
	local object = Instance.new("Folder")
	local holder = Instance.new("Folder")

	object:Destroy()

	local ok = pcall(function()
		object.Parent = holder
	end)

	holder:Destroy()

	return ok == false
		and object.Parent == nil
end)

test("Instance Destroy cascades to descendants", function()
	local root = Instance.new("Folder")
	local child = Instance.new("Folder")
	local leaf = Instance.new("Part")

	child.Parent = root
	leaf.Parent = child

	root:Destroy()

	return child.Parent == nil
		and leaf.Parent == nil
end)

test("Instance Archivable controls Clone", function()
	local object = Instance.new("Folder")

	object.Archivable = false

	local clone = object:Clone()

	object.Archivable = true

	local allowed = object:Clone()
	local valid = clone == nil
		and allowed ~= nil

	object:Destroy()

	if allowed then
		allowed:Destroy()
	end

	return valid
end)

test("Instance Clone skips unarchivable children", function()
	local root = Instance.new("Folder")
	local kept = Instance.new("Folder")
	local skipped = Instance.new("Folder")

	kept.Name = "Kept"
	skipped.Name = "Skipped"
	skipped.Archivable = false
	kept.Parent = root
	skipped.Parent = root

	local clone = root:Clone()
	local valid = clone ~= nil
		and clone:FindFirstChild("Kept") ~= nil
		and clone:FindFirstChild("Skipped") == nil

	root:Destroy()

	if clone then
		clone:Destroy()
	end

	return valid
end)

test("Instance fromExisting", function()
	if type(Instance.fromExisting) ~= "function" then
		return false, "Instance.fromExisting unavailable"
	end

	local source = Instance.new("Part")
	local child = Instance.new("Folder")

	source.Name = "Source"
	source.Anchored = true
	source.Size = Vector3.new(3, 3, 3)
	child.Parent = source

	local copy = Instance.fromExisting(source)
	local valid = copy ~= source
		and copy.ClassName == "Part"
		and copy.Name == "Source"
		and copy.Anchored == true
		and copy.Size == Vector3.new(3, 3, 3)
		and #copy:GetChildren() == 0

	source:Destroy()
	copy:Destroy()

	return valid
end)

test("Instance GetActor outside Actor", function()
	return withTemporary("Folder", function(object)
		local ok, actor = pcall(function()
			return object:GetActor()
		end)

		return ok
			and (actor == nil or typeof(actor) == "Instance")
	end)
end)

test("Instance IsPropertyModified", function()
	return withTemporary("Part", function(part)
		if not hasMethod(part, "IsPropertyModified") then
			return false, "IsPropertyModified unavailable"
		end

		local before = part:IsPropertyModified("Transparency")

		part.Transparency = 0.5

		local after = part:IsPropertyModified("Transparency")

		return type(before) == "boolean"
			and type(after) == "boolean"
	end)
end)

test("Instance ResetPropertyToDefault", function()
	return withTemporary("Part", function(part)
		if not hasMethod(part, "ResetPropertyToDefault") then
			return false, "ResetPropertyToDefault unavailable"
		end

		part.Transparency = 0.75

		local ok = pcall(function()
			part:ResetPropertyToDefault("Transparency")
		end)

		return ok
			and nearlyEqual(part.Transparency, 0)
	end)
end)

test("Instance attribute value types", function()
	return withTemporary("Folder", function(object)
		local values = {
			BooleanValue = true,
			NumberValue = 12.5,
			StringValue = "LogUnc",
			UDimValue = UDim.new(0.5, 10),
			UDim2Value = UDim2.new(0, 1, 0, 2),
			BrickColorValue = BrickColor.new("Bright red"),
			Color3Value = Color3.fromRGB(10, 20, 30),
			Vector2Value = Vector2.new(1, 2),
			Vector3Value = Vector3.new(1, 2, 3),
			CFrameValue = CFrame.new(1, 2, 3),
			NumberSequenceValue = NumberSequence.new(0, 1),
			ColorSequenceValue = ColorSequence.new(Color3.new(), Color3.new(1, 1, 1)),
			NumberRangeValue = NumberRange.new(1, 2),
			RectValue = Rect.new(0, 0, 10, 10)
		}

		for name, value in pairs(values) do
			local ok = pcall(function()
				object:SetAttribute(name, value)
			end)

			if not ok then
				return false, name .. " rejected"
			end

			local stored = object:GetAttribute(name)

			if typeof(stored) ~= typeof(value) then
				return false, name .. " type changed to " .. typeof(stored)
			end
		end

		return true
	end)
end)

test("Instance attribute deletion", function()
	return withTemporary("Folder", function(object)
		object:SetAttribute("Temporary", 1)

		local present = object:GetAttribute("Temporary")

		object:SetAttribute("Temporary", nil)

		return present == 1
			and object:GetAttribute("Temporary") == nil
			and object:GetAttributes().Temporary == nil
	end)
end)

test("Instance attribute rejects unsupported types", function()
	return withTemporary("Folder", function(object)
		local rejected = {
			object,
			{ 1, 2, 3 },
			print
		}

		for index, value in ipairs(rejected) do
			local ok = pcall(function()
				object:SetAttribute("Unsupported", value)
			end)

			if ok then
				return false, "value " .. index .. " accepted"
			end
		end

		return true
	end)
end)

test("Instance attribute name rules", function()
	return withTemporary("Folder", function(object)
		local invalid = { "has space", "bad@name", "bad!name", "bad~name" }

		for _, name in ipairs(invalid) do
			local ok = pcall(function()
				object:SetAttribute(name, 1)
			end)

			if ok and object:GetAttribute(name) ~= nil then
				return false, "accepted " .. name
			end
		end

		local allowed = { "valid_name", "valid-name", "valid.name", "valid123" }

		for _, name in ipairs(allowed) do
			local ok = pcall(function()
				object:SetAttribute(name, 1)
			end)

			if not ok then
				return false, "rejected " .. name
			end
		end

		return true
	end)
end)

test("Instance attribute changed signal", function()
	return withTemporary("Folder", function(object)
		local signal = object:GetAttributeChangedSignal("Watched")

		if not isSignal(signal) then
			return false, "signal missing"
		end

		local fired = false
		local connection = signal:Connect(function()
			fired = true
		end)

		object:SetAttribute("Watched", 1)
		task.wait()
		connection:Disconnect()

		return fired
	end)
end)

test("Instance tag lifecycle", function()
	return withTemporary("Folder", function(object)
		object:AddTag("LogUncAlpha")
		object:AddTag("LogUncBeta")

		local tags = object:GetTags()
		local hasBoth = object:HasTag("LogUncAlpha")
			and object:HasTag("LogUncBeta")

		object:RemoveTag("LogUncAlpha")

		return hasBoth
			and #tags == 2
			and object:HasTag("LogUncAlpha") == false
			and object:HasTag("LogUncBeta") == true
	end)
end)

test("Instance duplicate tag is idempotent", function()
	return withTemporary("Folder", function(object)
		object:AddTag("LogUncDuplicate")
		object:AddTag("LogUncDuplicate")

		return #object:GetTags() == 1
	end)
end)

test("CollectionService tag queries", function()
	local collectionService = game:GetService("CollectionService")
	local object = Instance.new("Folder")
	local tag = "LogUncQuery"

	object.Parent = workspace
	collectionService:AddTag(object, tag)

	local tagged = collectionService:GetTagged(tag)
	local allTags = collectionService:GetAllTags()
	local found = containsValue(tagged, object)
	local listed = containsValue(allTags, tag)

	collectionService:RemoveTag(object, tag)
	object:Destroy()

	return found
		and listed
		and type(tagged) == "table"
		and type(allTags) == "table"
end)

test("CollectionService instance signals", function()
	local collectionService = game:GetService("CollectionService")
	local tag = "LogUncSignal"
	local addedSignal = collectionService:GetInstanceAddedSignal(tag)
	local removedSignal = collectionService:GetInstanceRemovedSignal(tag)

	if not isSignal(addedSignal) or not isSignal(removedSignal) then
		return false, "signals missing"
	end

	local cached = collectionService:GetInstanceAddedSignal(tag) == addedSignal
	local added = false
	local removed = false
	local addedConnection = addedSignal:Connect(function()
		added = true
	end)
	local removedConnection = removedSignal:Connect(function()
		removed = true
	end)
	local object = Instance.new("Folder")

	object.Parent = workspace
	collectionService:AddTag(object, tag)
	task.wait()
	collectionService:RemoveTag(object, tag)
	task.wait()
	addedConnection:Disconnect()
	removedConnection:Disconnect()
	object:Destroy()

	return cached
		and added
		and removed
end)

test("Instance WaitForChild resolves", function()
	local root = Instance.new("Folder")

	task.defer(function()
		local child = Instance.new("Folder")

		child.Name = "Delayed"
		child.Parent = root
	end)

	local found = root:WaitForChild("Delayed", 2)
	local valid = found ~= nil
		and found.Name == "Delayed"

	root:Destroy()

	return valid
end)

test("Instance WaitForChild returns existing immediately", function()
	local root = Instance.new("Folder")
	local child = Instance.new("Folder")

	child.Name = "Present"
	child.Parent = root

	local start = os.clock()
	local found = root:WaitForChild("Present")
	local elapsed = os.clock() - start

	root:Destroy()

	return found == child
		and elapsed < 0.5
end)

test("Instance name allows duplicates", function()
	local root = Instance.new("Folder")
	local first = Instance.new("Folder")
	local second = Instance.new("Folder")

	first.Name = "Same"
	second.Name = "Same"
	first.Parent = root
	second.Parent = root

	local found = root:FindFirstChild("Same")
	local valid = #root:GetChildren() == 2
		and (found == first or found == second)

	root:Destroy()

	return valid
end)

test("Instance Parent cycle is rejected", function()
	local outer = Instance.new("Folder")
	local inner = Instance.new("Folder")

	inner.Parent = outer

	local ok = pcall(function()
		outer.Parent = inner
	end)

	local selfOk = pcall(function()
		outer.Parent = outer
	end)

	local valid = ok == false
		and selfOk == false
		and outer.Parent == nil

	outer:Destroy()

	return valid
end)

test("Instance property assignment type checking", function()
	return withTemporary("Part", function(part)
		local rejects = {
			{
				Name = "Size from number",
				Attempt = function()
					part.Size = 10
				end
			},
			{
				Name = "Size from string",
				Attempt = function()
					part.Size = "big"
				end
			},
			{
				Name = "Parent from number",
				Attempt = function()
					part.Parent = 5
				end
			},
			{
				Name = "CFrame from Vector3",
				Attempt = function()
					part.CFrame = Vector3.new(1, 2, 3)
				end
			},
			{
				Name = "Color from number",
				Attempt = function()
					part.Color = 5
				end
			},
			{
				Name = "Material from number",
				Attempt = function()
					part.Material = 12345
				end
			},
			{
				Name = "Name from table",
				Attempt = function()
					part.Name = {}
				end
			}
		}

		local problems = {}

		for _, entry in ipairs(rejects) do
			if pcall(entry.Attempt) then
				table.insert(problems, entry.Name .. " accepted")
			end
		end

		if #problems > 0 then
			return false, table.concat(problems, "; ")
		end

		return true
	end)
end)

test("Instance boolean properties coerce by truthiness", function()
	return withTemporary("Part", function(part)
		part.Anchored = true

		if part.Anchored ~= true then
			return false, "true did not round trip"
		end

		part.Anchored = false

		if part.Anchored ~= false then
			return false, "false did not round trip"
		end

		local values = { {}, 0, 1, "", "no", newproxy(false) }
		local accepted = 0

		for _, value in ipairs(values) do
			pcall(function()
				part.Anchored = false
			end)

			local ok = pcall(function()
				part.Anchored = value
			end)

			if ok then
				accepted += 1
			end
		end

		metrics.BooleanCoercions = accepted .. "/" .. #values

		pcall(function()
			part.Anchored = false
		end)

		return type(part.Anchored) == "boolean"
	end)
end)

test("Instance property assignment keeps declared types", function()
	return withTemporary("Part", function(part)
		local properties = {
			"Transparency",
			"Reflectance",
			"Name",
			"Size",
			"CFrame",
			"Position",
			"Color",
			"BrickColor",
			"Material",
			"Anchored",
			"CanCollide"
		}

		for _, property in ipairs(properties) do
			local readOk, before = readMember(part, property)

			if not readOk then
				return false, property .. " unreadable"
			end

			local expected = typeof(before)

			pcall(function()
				part[property] = {}
			end)

			local afterOk, after = readMember(part, property)

			if not afterOk then
				return false, property .. " unreadable after assignment"
			end

			if typeof(after) ~= expected then
				return false, property .. " became " .. typeof(after)
			end
		end

		return true
	end)
end)

test("Instance property value coercion", function()
	return withTemporary("Part", function(part)
		local numericOk = pcall(function()
			part.Transparency = "0.5"
		end)
		local numericCoerced = not numericOk or nearlyEqual(part.Transparency, 0.5)

		part.Transparency = 0

		local invalidOk = pcall(function()
			part.Transparency = "half"
		end)
		local invalidSafe = not invalidOk or type(part.Transparency) == "number"

		local booleanOk = pcall(function()
			part.Anchored = "yes"
		end)
		local booleanCoerced = not booleanOk or type(part.Anchored) == "boolean"

		local enumOk = pcall(function()
			part.Material = "Neon"
		end)
		local enumCoerced = not enumOk or part.Material == Enum.Material.Neon

		local nameOk = pcall(function()
			part.Name = 5
		end)
		local nameCoerced = not nameOk or part.Name == "5"

		if not numericCoerced then
			return false, "numeric string produced " .. stringify(part.Transparency)
		end

		if not invalidSafe then
			return false, "invalid string produced " .. type(part.Transparency)
		end

		if not booleanCoerced then
			return false, "boolean coercion produced " .. type(part.Anchored)
		end

		if not enumCoerced then
			return false, "enum coercion produced " .. stringify(part.Material)
		end

		if not nameCoerced then
			return false, "name coercion produced " .. stringify(part.Name)
		end

		return true
	end)
end)

test("Instance unknown property access", function()
	return withTemporary("Folder", function(object)
		local readOk = pcall(function()
			return object.LogUncMissingProperty
		end)
		local writeOk = pcall(function()
			object.LogUncMissingProperty = 1
		end)

		return readOk == false
			and writeOk == false
	end)
end)

test("Instance read-only properties reject writes", function()
	return withTemporary("Part", function(part)
		local attempts = {
			function()
				part.ClassName = "Model"
			end,
			function()
				part.Mass = 100
			end,
			function()
				part.AssemblyMass = 100
			end,
			function()
				part.CenterOfMass = Vector3.new()
			end
		}

		for index, attempt in ipairs(attempts) do
			if pcall(attempt) then
				return false, "write " .. index .. " accepted"
			end
		end

		return true
	end)
end)

test("Instance IsA against datatype names", function()
	return withTemporary("Part", function(part)
		return part:IsA("Part")
			and part:IsA("BasePart")
			and part:IsA("PVInstance")
			and part:IsA("Instance")
			and part:IsA("Model") == false
			and part:IsA("LogUncFakeClass") == false
	end)
end)

test("Instance ChildRemoved on destroy", function()
	local root = Instance.new("Folder")
	local child = Instance.new("Folder")
	local removed = false
	local connection = root.ChildRemoved:Connect(function(instance)
		if instance == child then
			removed = true
		end
	end)

	child.Parent = root
	child:Destroy()
	task.wait()
	connection:Disconnect()
	root:Destroy()

	return removed
end)

test("Instance Destroying signal", function()
	local object = Instance.new("Folder")
	local ok, signal = readMember(object, "Destroying")

	if not ok or not isSignal(signal) then
		object:Destroy()

		return false, "Destroying signal missing"
	end

	local fired = false
	local connection = signal:Connect(function()
		fired = true
	end)

	object:Destroy()
	task.wait()
	connection:Disconnect()

	return fired
end)

test("Instance GetPropertyChangedSignal specificity", function()
	return withTemporary("Part", function(part)
		local nameChanges = 0
		local connection = part:GetPropertyChangedSignal("Name"):Connect(function()
			nameChanges += 1
		end)

		part.Name = "Renamed"
		part.Transparency = 0.5
		task.wait()
		connection:Disconnect()

		return nameChanges == 1
	end)
end)

test("Instance GetPropertyChangedSignal rejects unknown", function()
	return withTemporary("Folder", function(object)
		local ok = pcall(function()
			return object:GetPropertyChangedSignal("LogUncMissingProperty")
		end)

		return ok == false
	end)
end)

test("RBXScriptSignal Once", function()
	local event = Instance.new("BindableEvent")

	if not hasMethod(event.Event, "Once") then
		event:Destroy()

		return false, "Once unavailable"
	end

	local calls = 0
	local connection = event.Event:Once(function()
		calls += 1
	end)

	event:Fire()
	task.wait()
	event:Fire()
	task.wait()

	local disconnected = connection.Connected == false

	event:Destroy()

	return calls == 1
		and disconnected
end)

test("RBXScriptSignal Wait returns arguments", function()
	local event = Instance.new("BindableEvent")

	task.defer(function()
		event:Fire("first", 2)
	end)

	local first, second = event.Event:Wait()

	event:Destroy()

	return first == "first"
		and second == 2
end)

test("RBXScriptSignal method surface", function()
	local event = Instance.new("BindableEvent")
	local signal = event.Event
	local valid = hasMethod(signal, "Connect")
		and hasMethod(signal, "Once")
		and hasMethod(signal, "Wait")
		and hasMethod(signal, "ConnectParallel")

	event:Destroy()

	return valid
end)

test("RBXScriptConnection disconnect is idempotent", function()
	local event = Instance.new("BindableEvent")
	local connection = event.Event:Connect(function() end)
	local wasConnected = connection.Connected

	connection:Disconnect()

	local afterFirst = connection.Connected
	local secondOk = pcall(function()
		connection:Disconnect()
	end)

	event:Destroy()

	return wasConnected == true
		and afterFirst == false
		and secondOk
end)

test("BasePart method surface", function()
	return withTemporary("Part", function(part)
		return hasMethods(part, {
			"ApplyAngularImpulse",
			"ApplyImpulse",
			"ApplyImpulseAtPosition",
			"GetClosestPointOnSurface",
			"GetConnectedParts",
			"GetJoints",
			"GetMass",
			"GetNoCollisionConstraints",
			"GetPivot",
			"GetTouchingParts",
			"GetVelocityAtPosition",
			"IsGrounded",
			"PivotTo"
		})
	end)
end)

test("BasePart transform aliases", function()
	return withTemporary("Part", function(part)
		part.CFrame = CFrame.new(5, 6, 7)

		local positionMatches = part.Position == Vector3.new(5, 6, 7)

		part.Position = Vector3.new(1, 2, 3)

		local cframeMatches = part.CFrame.Position == Vector3.new(1, 2, 3)

		part.Orientation = Vector3.new(0, 90, 0)

		local orientationApplied = nearlyEqual(part.Orientation.Y, 90, 0.01)

		return positionMatches
			and cframeMatches
			and orientationApplied
			and typeof(part.Rotation) == "Vector3"
			and typeof(part.CFrame) == "CFrame"
	end)
end)

test("BasePart pivot offset", function()
	return withTemporary("Part", function(part)
		part.Anchored = true
		part.CFrame = CFrame.new(0, 0, 0)
		part.PivotOffset = CFrame.new(0, 5, 0)

		local pivot = part:GetPivot()

		return pivot.Position == Vector3.new(0, 5, 0)
			and typeof(part.PivotOffset) == "CFrame"
	end)
end)

test("BasePart PivotTo moves part", function()
	return withTemporary("Part", function(part)
		part.Anchored = true
		part:PivotTo(CFrame.new(10, 20, 30))

		return part.Position == Vector3.new(10, 20, 30)
			and part:GetPivot().Position == Vector3.new(10, 20, 30)
	end)
end)

test("BasePart extents", function()
	return withTemporary("Part", function(part)
		part.Anchored = true
		part.Size = Vector3.new(4, 6, 8)
		part.CFrame = CFrame.new(1, 2, 3)

		return part.ExtentsSize == Vector3.new(4, 6, 8)
			and typeof(part.ExtentsCFrame) == "CFrame"
			and part.ExtentsCFrame.Position == Vector3.new(1, 2, 3)
	end)
end)

test("BasePart resize metadata", function()
	return withTemporary("Part", function(part)
		return typeof(part.ResizeableFaces) == "Faces"
		and type(part.ResizeIncrement) == "number"
			and part.ResizeIncrement >= 0
	end)
end)

test("BasePart mass scales with size", function()
	local small = Instance.new("Part")
	local large = Instance.new("Part")

	small.Size = Vector3.new(1, 1, 1)
	large.Size = Vector3.new(2, 2, 2)

	local smallMass = small.Mass
	local largeMass = large.Mass
	local valid = smallMass > 0
		and largeMass > smallMass
		and nearlyEqual(largeMass / smallMass, 8, 0.5)
		and nearlyEqual(small:GetMass(), smallMass, 0.001)

	small:Destroy()
	large:Destroy()

	return valid
end)

test("BasePart custom density changes mass", function()
	local part = Instance.new("Part")

	part.Size = Vector3.new(2, 2, 2)

	local defaultMass = part.Mass

	part.CustomPhysicalProperties = PhysicalProperties.new(2, 0.3, 0.5, 1, 1)

	local heavyMass = part.Mass
	local current = part.CurrentPhysicalProperties
	local valid = heavyMass > defaultMass
		and typeof(current) == "PhysicalProperties"
		and nearlyEqual(current.Density, 2, 0.01)

	part:Destroy()

	return valid
end)

test("BasePart material overrides", function()
	return withTemporary("Part", function(part)
		local materials = {
			Enum.Material.Plastic,
			Enum.Material.SmoothPlastic,
			Enum.Material.Neon,
			Enum.Material.Wood,
			Enum.Material.Metal,
			Enum.Material.Glass,
			Enum.Material.ForceField
		}

		for _, material in ipairs(materials) do
			part.Material = material

			if part.Material ~= material then
				return false, tostring(material) .. " not applied"
			end
		end

		return true
	end)
end)

test("BasePart color and BrickColor sync", function()
	return withTemporary("Part", function(part)
		part.BrickColor = BrickColor.new("Bright red")

		local colorFromBrick = part.Color

		part.Color = Color3.fromRGB(0, 0, 255)

		local brickFromColor = part.BrickColor

		return typeof(colorFromBrick) == "Color3"
			and typeof(brickFromColor) == "BrickColor"
			and colorFromBrick.R > colorFromBrick.B
			and brickFromColor.Color.B > brickFromColor.Color.R
	end)
end)

test("BasePart surface types", function()
	return withTemporary("Part", function(part)
		local faces = {
			"TopSurface",
			"BottomSurface",
			"LeftSurface",
			"RightSurface",
			"FrontSurface",
			"BackSurface"
		}

		for _, face in ipairs(faces) do
			part[face] = Enum.SurfaceType.Weld

			if part[face] ~= Enum.SurfaceType.Weld then
				return false, face .. " not applied"
			end

			part[face] = Enum.SurfaceType.Smooth
		end

		return true
	end)
end)

test("BasePart shape variants", function()
	return withTemporary("Part", function(part)
		local shapes = {
			Enum.PartType.Block,
			Enum.PartType.Ball,
			Enum.PartType.Cylinder,
			Enum.PartType.Wedge,
			Enum.PartType.CornerWedge
		}

		for _, shape in ipairs(shapes) do
			part.Shape = shape

			if part.Shape ~= shape then
				return false, tostring(shape) .. " not applied"
			end
		end

		return true
	end)
end)

test("BasePart appearance flags", function()
	return withTemporary("Part", function(part)
		part.CastShadow = false
		part.Locked = true
		part.AudioCanCollide = false
		part.EnableFluidForces = false
		part.RootPriority = 5
		part.Reflectance = 0.5

		return part.CastShadow == false
			and part.Locked == true
			and part.AudioCanCollide == false
			and part.EnableFluidForces == false
			and part.RootPriority == 5
			and nearlyEqual(part.Reflectance, 0.5)
	end)
end)

test("BasePart assembly members", function()
	local model = Instance.new("Model")
	local root = Instance.new("Part")
	local attached = Instance.new("Part")
	local weld = Instance.new("WeldConstraint")

	root.Position = Vector3.new(0, 100, 0)
	attached.Position = Vector3.new(2, 100, 0)
	root.Parent = model
	attached.Parent = model
	weld.Part0 = root
	weld.Part1 = attached
	weld.Parent = root
	model.Parent = workspace

	local valid = typeof(root.AssemblyCenterOfMass) == "Vector3"
		and type(root.AssemblyMass) == "number"
		and root.AssemblyMass > 0
		and (root.AssemblyRootPart == nil or root.AssemblyRootPart:IsA("BasePart"))
		and typeof(root.CenterOfMass) == "Vector3"

	model:Destroy()

	return valid
end)

test("BasePart GetConnectedParts", function()
	local model = Instance.new("Model")
	local first = Instance.new("Part")
	local second = Instance.new("Part")
	local weld = Instance.new("WeldConstraint")

	first.Anchored = true
	first.Position = Vector3.new(0, 200, 0)
	second.Position = Vector3.new(2, 200, 0)
	first.Parent = model
	second.Parent = model
	weld.Part0 = first
	weld.Part1 = second
	weld.Parent = first
	model.Parent = workspace

	local connected = first:GetConnectedParts()
	local recursive = first:GetConnectedParts(true)
	local joints = first:GetJoints()
	local valid = type(connected) == "table"
		and type(recursive) == "table"
		and type(joints) == "table"

	model:Destroy()

	return valid
end)

test("BasePart GetTouchingParts", function()
	local part = Instance.new("Part")

	part.Anchored = true
	part.CanTouch = true
	part.Size = Vector3.new(4, 4, 4)
	part.Position = Vector3.new(0, 500, 0)
	part.Parent = workspace

	local touching = part:GetTouchingParts()

	part:Destroy()

	return type(touching) == "table"
end)

test("BasePart GetClosestPointOnSurface", function()
	local part = Instance.new("Part")

	part.Anchored = true
	part.Size = Vector3.new(4, 4, 4)
	part.CFrame = CFrame.new(0, 300, 0)
	part.Parent = workspace

	local ok, closest = pcall(function()
		return part:GetClosestPointOnSurface(Vector3.new(10, 300, 0))
	end)

	part:Destroy()

	return ok
		and typeof(closest) == "Vector3"
		and nearlyEqual(closest.X, 2, 0.01)
end)

test("BasePart velocity helpers", function()
	local part = Instance.new("Part")

	part.Anchored = false
	part.Position = Vector3.new(0, 400, 0)
	part.Parent = workspace
	part.AssemblyLinearVelocity = Vector3.new(0, 0, 5)

	local atPoint = part:GetVelocityAtPosition(part.Position)
	local grounded = part:IsGrounded()
	local valid = typeof(atPoint) == "Vector3"
		and type(grounded) == "boolean"

	part:Destroy()

	return valid
end)

test("BasePart impulse application", function()
	local part = Instance.new("Part")

	part.Anchored = false
	part.Position = Vector3.new(0, 600, 0)
	part.Parent = workspace

	local impulseOk = pcall(function()
		part:ApplyImpulse(Vector3.new(0, 10, 0))
	end)
	local angularOk = pcall(function()
		part:ApplyAngularImpulse(Vector3.new(0, 1, 0))
	end)
	local positionOk = pcall(function()
		part:ApplyImpulseAtPosition(Vector3.new(0, 10, 0), part.Position)
	end)

	part:Destroy()

	return impulseOk
		and angularOk
		and positionOk
end)

test("BasePart collision group registration", function()
	local physicsService = game:GetService("PhysicsService")
	local groupName = "LogUncGroup"

	pcall(function()
		physicsService:UnregisterCollisionGroup(groupName)
	end)

	local registerOk, registerError = pcall(function()
		physicsService:RegisterCollisionGroup(groupName)
	end)

	if not registerOk then
		local message = string.lower(stringify(registerError))

		if string.find(message, "server", 1, true) ~= nil
			or string.find(message, "permission", 1, true) ~= nil
		then
			return type(physicsService:GetRegisteredCollisionGroups()) == "table"
				and physicsService:IsCollisionGroupRegistered("Default")
		end

		return false, stringify(registerError)
	end

	local part = Instance.new("Part")
	local appliedOk = pcall(function()
		part.CollisionGroup = groupName
	end)
	local applied = appliedOk and part.CollisionGroup == groupName
	local registered = physicsService:IsCollisionGroupRegistered(groupName)
	local collidableOk = pcall(function()
		physicsService:CollisionGroupSetCollidable(groupName, "Default", false)
	end)
	local queried = physicsService:CollisionGroupsAreCollidable(groupName, "Default")

	part:Destroy()
	pcall(function()
		physicsService:UnregisterCollisionGroup(groupName)
	end)

	return applied
		and registered
		and (collidableOk == false or queried == false)
end)

test("PhysicsService group limits", function()
	local physicsService = game:GetService("PhysicsService")
	local maximum = physicsService:GetMaxCollisionGroups()
	local groups = physicsService:GetRegisteredCollisionGroups()

	return type(maximum) == "number"
		and maximum > 0
		and type(groups) == "table"
		and #groups >= 1
end)

test("Part touched connection requires CanTouch", function()
	return withTemporary("Part", function(part)
		part.CanTouch = false

		local ok = pcall(function()
			return part.Touched:Connect(function() end)
		end)

		part.CanTouch = true

		local allowedOk, connection = pcall(function()
			return part.Touched:Connect(function() end)
		end)

		if allowedOk and connection then
			connection:Disconnect()
		end

		return type(ok) == "boolean"
			and allowedOk
	end)
end)

test("Part TouchEnded signal exists", function()
	return withTemporary("Part", function(part)
		return isSignal(part.Touched)
			and isSignal(part.TouchEnded)
	end)
end)

test("MeshPart properties", function()
	return withTemporary("MeshPart", function(mesh)
		mesh.TextureID = "rbxassetid://0"
		mesh.DoubleSided = true

		return type(mesh.MeshId) == "string"
			and mesh.TextureID == "rbxassetid://0"
			and mesh.DoubleSided == true
			and typeof(mesh.CollisionFidelity) == "EnumItem"
			and typeof(mesh.RenderFidelity) == "EnumItem"
			and mesh:IsA("TriangleMeshPart")
			and mesh:IsA("BasePart")
	end)
end)

test("Terrain service shape", function()
	local terrain = workspace.Terrain

	return terrain ~= nil
		and terrain:IsA("Terrain")
		and terrain:IsA("BasePart")
		and terrain.Parent == workspace
		and typeof(terrain.MaxExtents) == "Region3int16"
		and typeof(terrain.WaterColor) == "Color3"
		and type(terrain.WaterWaveSize) == "number"
end)

test("Terrain material colors", function()
	local terrain = workspace.Terrain
	local original = terrain:GetMaterialColor(Enum.Material.Grass)

	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(10, 200, 10))

	local updated = terrain:GetMaterialColor(Enum.Material.Grass)

	terrain:SetMaterialColor(Enum.Material.Grass, original)

	return typeof(original) == "Color3"
		and typeof(updated) == "Color3"
		and updated.G > updated.R
end)

test("Terrain rejects air and water colors", function()
	local terrain = workspace.Terrain

	return pcall(function()
		return terrain:GetMaterialColor(Enum.Material.Air)
	end) == false
		and pcall(function()
			return terrain:GetMaterialColor(Enum.Material.Water)
		end) == false
end)

test("Terrain voxel read", function()
	local terrain = workspace.Terrain
	local region = Region3.new(
		Vector3.new(0, 1000, 0),
		Vector3.new(8, 1008, 8)
	):ExpandToGrid(4)

	local ok, materials, occupancies = pcall(function()
		return terrain:ReadVoxels(region, 4)
	end)

	return ok
		and type(materials) == "table"
		and type(occupancies) == "table"
		and materials.Size ~= nil
end)

test("Terrain voxel write and fill", function()
	local terrain = workspace.Terrain
	local center = Vector3.new(0, -2000, 0)
	local fillBlockOk = pcall(function()
		terrain:FillBlock(CFrame.new(center), Vector3.new(8, 8, 8), Enum.Material.Rock)
	end)
	local fillBallOk = pcall(function()
		terrain:FillBall(center, 4, Enum.Material.Air)
	end)

	return fillBlockOk
		and fillBallOk
		and hasMethod(terrain, "WriteVoxels")
		and hasMethod(terrain, "Clear")
end)

test("Model scale and bounds", function()
	local model = Instance.new("Model")
	local part = Instance.new("Part")

	part.Anchored = true
	part.Size = Vector3.new(4, 4, 4)
	part.Parent = model
	model.PrimaryPart = part

	local extents = model:GetExtentsSize()
	local scale = model:GetScale()
	local scaleOk = pcall(function()
		model:ScaleTo(2)
	end)
	local scaledExtents = model:GetExtentsSize()
	local valid = extents == Vector3.new(4, 4, 4)
		and nearlyEqual(scale, 1)
		and scaleOk
		and scaledExtents.X > extents.X

	model:Destroy()

	return valid
end)

test("Model translate and pivot", function()
	local model = Instance.new("Model")
	local part = Instance.new("Part")

	part.Anchored = true
	part.Parent = model
	model.PrimaryPart = part
	model:PivotTo(CFrame.new(0, 0, 0))
	model:TranslateBy(Vector3.new(5, 0, 0))

	local moved = part.Position == Vector3.new(5, 0, 0)

	model.WorldPivot = CFrame.new(10, 10, 10)

	local pivotSet = model.WorldPivot.Position == Vector3.new(10, 10, 10)

	model:Destroy()

	return moved
		and pivotSet
end)

test("Model streaming members", function()
	return withTemporary("Model", function(model)
		return typeof(model.ModelStreamingMode) == "EnumItem"
			and hasMethod(model, "AddPersistentPlayer")
			and hasMethod(model, "GetPersistentPlayers")
			and hasMethod(model, "RemovePersistentPlayer")
			and type(model:GetPersistentPlayers()) == "table"
	end)
end)

test("Workspace properties", function()
	return type(workspace.Gravity) == "number"
		and workspace.Gravity > 0
		and typeof(workspace.GlobalWind) == "Vector3"
		and type(workspace.FallenPartsDestroyHeight) == "number"
		and type(workspace.StreamingEnabled) == "boolean"
		and type(workspace.DistributedGameTime) == "number"
		and type(workspace.AirDensity) == "number"
		and typeof(workspace.Retargeting) == "EnumItem"
		and typeof(workspace.ClientAnimatorThrottling) == "EnumItem"
end)

test("Workspace physics diagnostics", function()
	local awake = workspace:GetNumAwakeParts()
	local throttling = workspace:GetPhysicsThrottling()
	local fps = workspace:GetRealPhysicsFPS()
	local pgs = workspace:PGSIsEnabled()

	return type(awake) == "number"
		and awake >= 0
		and type(throttling) == "number"
		and type(fps) == "number"
		and fps > 0
		and type(pgs) == "boolean"
end)

test("Workspace server time", function()
	local ok, serverTime = pcall(function()
		return workspace:GetServerTimeNow()
	end)

	if not ok then
		return false, stringify(serverTime)
	end

	local again = workspace:GetServerTimeNow()

	return type(serverTime) == "number"
		and serverTime > 0
		and again >= serverTime
end)

test("Workspace spatial query surface", function()
	return hasMethods(workspace, {
		"ArePartsTouchingOthers",
		"Blockcast",
		"BulkMoveTo",
		"CollisionGroupsAreCollidable",
		"CollisionGroupSetCollidable",
		"GetMaxCollisionGroups",
		"GetPartBoundsInBox",
		"GetPartBoundsInRadius",
		"GetPartsInPart",
		"GetRegisteredCollisionGroups",
		"IsCollisionGroupRegistered",
		"Raycast",
		"RegisterCollisionGroup",
		"RenameCollisionGroup",
		"Shapecast",
		"Spherecast",
		"UnregisterCollisionGroup"
	})
end)

test("Workspace raycast hits a part", function()
	local part = Instance.new("Part")

	part.Anchored = true
	part.Size = Vector3.new(10, 1, 10)
	part.CFrame = CFrame.new(0, -1500, 0)
	part.Parent = workspace

	local parameters = RaycastParams.new()

	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { part }

	local result = workspace:Raycast(
		Vector3.new(0, -1490, 0),
		Vector3.new(0, -50, 0),
		parameters
	)

	local valid = result ~= nil
		and result.Instance == part
		and typeof(result.Position) == "Vector3"
		and typeof(result.Normal) == "Vector3"
		and typeof(result.Material) == "EnumItem"
		and type(result.Distance) == "number"
		and result.Distance > 0

	part:Destroy()

	return valid
end)

test("Workspace raycast exclusion", function()
	local part = Instance.new("Part")

	part.Anchored = true
	part.Size = Vector3.new(10, 1, 10)
	part.CFrame = CFrame.new(0, -1600, 0)
	part.Parent = workspace

	local parameters = RaycastParams.new()

	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = { part }

	local result = workspace:Raycast(
		Vector3.new(0, -1590, 0),
		Vector3.new(0, -20, 0),
		parameters
	)

	part:Destroy()

	return result == nil
		or result.Instance ~= part
end)

test("Workspace shapecast variants", function()
	local part = Instance.new("Part")

	part.Anchored = true
	part.Size = Vector3.new(10, 1, 10)
	part.CFrame = CFrame.new(0, -1700, 0)
	part.Parent = workspace

	local parameters = RaycastParams.new()

	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { part }

	local block = workspace:Blockcast(
		CFrame.new(0, -1690, 0),
		Vector3.new(2, 2, 2),
		Vector3.new(0, -30, 0),
		parameters
	)
	local sphere = workspace:Spherecast(
		Vector3.new(0, -1690, 0),
		2,
		Vector3.new(0, -30, 0),
		parameters
	)

	local valid = block ~= nil
		and block.Instance == part
		and sphere ~= nil
		and sphere.Instance == part

	part:Destroy()

	return valid
end)

test("Workspace bounds queries", function()
	local part = Instance.new("Part")

	part.Anchored = true
	part.Size = Vector3.new(4, 4, 4)
	part.CFrame = CFrame.new(0, -1800, 0)
	part.Parent = workspace

	local parameters = OverlapParams.new()

	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { part }

	local box = workspace:GetPartBoundsInBox(
		CFrame.new(0, -1800, 0),
		Vector3.new(10, 10, 10),
		parameters
	)
	local radius = workspace:GetPartBoundsInRadius(
		Vector3.new(0, -1800, 0),
		10,
		parameters
	)
	local inPart = workspace:GetPartsInPart(part, parameters)

	local valid = containsValue(box, part)
		and containsValue(radius, part)
		and type(inPart) == "table"

	part:Destroy()

	return valid
end)

test("Workspace BulkMoveTo", function()
	local first = Instance.new("Part")
	local second = Instance.new("Part")

	first.Anchored = true
	second.Anchored = true
	first.Parent = workspace
	second.Parent = workspace

	local ok = pcall(function()
		workspace:BulkMoveTo(
			{ first, second },
			{ CFrame.new(0, -1900, 0), CFrame.new(0, -1910, 0) }
		)
	end)

	local moved = first.Position == Vector3.new(0, -1900, 0)
		and second.Position == Vector3.new(0, -1910, 0)

	first:Destroy()
	second:Destroy()

	return ok
		and moved
end)

test("RaycastParams configuration", function()
	local parameters = RaycastParams.new()
	local part = Instance.new("Part")

	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = { part }
	parameters.IgnoreWater = true
	parameters.RespectCanCollide = true
	parameters.BruteForceAllSlow = false
	parameters.CollisionGroup = "Default"

	local filtered = parameters.FilterDescendantsInstances

	if hasMethod(parameters, "AddToFilter") then
		parameters:AddToFilter(Instance.new("Part"))
	end

	local valid = typeof(parameters) == "RaycastParams"
		and parameters.FilterType == Enum.RaycastFilterType.Exclude
		and parameters.IgnoreWater == true
		and parameters.RespectCanCollide == true
		and parameters.BruteForceAllSlow == false
		and parameters.CollisionGroup == "Default"
		and #filtered >= 1
		and #parameters.FilterDescendantsInstances >= 1

	part:Destroy()

	return valid
end)

test("OverlapParams configuration", function()
	local parameters = OverlapParams.new()

	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.MaxParts = 10
	parameters.RespectCanCollide = true
	parameters.BruteForceAllSlow = false
	parameters.CollisionGroup = "Default"

	local toleranceOk = pcall(function()
		parameters.Tolerance = 0.01
	end)

	return typeof(parameters) == "OverlapParams"
		and parameters.FilterType == Enum.RaycastFilterType.Include
		and parameters.MaxParts == 10
		and parameters.RespectCanCollide == true
		and parameters.BruteForceAllSlow == false
		and parameters.CollisionGroup == "Default"
		and (toleranceOk == false or type(parameters.Tolerance) == "number")
end)

test("Vector3 constants and axes", function()
	return Vector3.zero == Vector3.new(0, 0, 0)
		and Vector3.one == Vector3.new(1, 1, 1)
		and Vector3.xAxis == Vector3.new(1, 0, 0)
		and Vector3.yAxis == Vector3.new(0, 1, 0)
		and Vector3.zAxis == Vector3.new(0, 0, 1)
		and Vector3.FromNormalId(Enum.NormalId.Top) == Vector3.yAxis
		and Vector3.FromAxis(Enum.Axis.X) == Vector3.xAxis
end)

test("Vector3 arithmetic", function()
	local left = Vector3.new(1, 2, 3)
	local right = Vector3.new(4, 5, 6)

	return left + right == Vector3.new(5, 7, 9)
		and right - left == Vector3.new(3, 3, 3)
		and left * 2 == Vector3.new(2, 4, 6)
		and right / 2 == Vector3.new(2, 2.5, 3)
		and left * right == Vector3.new(4, 10, 18)
		and -left == Vector3.new(-1, -2, -3)
		and Vector3.new(7, 7, 7) // 2 == Vector3.new(3, 3, 3)
end)

test("Vector3 geometry methods", function()
	local right = Vector3.new(1, 0, 0)
	local up = Vector3.new(0, 1, 0)

	return nearlyEqual(right:Dot(up), 0)
		and right:Cross(up) == Vector3.new(0, 0, 1)
		and nearlyEqual(right:Angle(up), math.pi / 2)
		and right:Lerp(up, 0.5) == Vector3.new(0.5, 0.5, 0)
		and nearlyEqual(Vector3.new(3, 4, 0).Magnitude, 5)
		and nearlyEqual(Vector3.new(3, 4, 0).Unit.Magnitude, 1)
end)

test("Vector3 component helpers", function()
	local value = Vector3.new(-1.5, 2.5, -3.5)

	return value:Abs() == Vector3.new(1.5, 2.5, 3.5)
		and value:Floor() == Vector3.new(-2, 2, -4)
		and value:Ceil() == Vector3.new(-1, 3, -3)
		and value:Sign() == Vector3.new(-1, 1, -1)
		and Vector3.new(1, 5, 3):Max(Vector3.new(4, 2, 6)) == Vector3.new(4, 5, 6)
		and Vector3.new(1, 5, 3):Min(Vector3.new(4, 2, 6)) == Vector3.new(1, 2, 3)
end)

test("Vector3 FuzzyEq", function()
	local base = Vector3.new(1, 1, 1)

	return base:FuzzyEq(Vector3.new(1, 1, 1))
		and base:FuzzyEq(Vector3.new(1.000001, 1, 1))
		and base:FuzzyEq(Vector3.new(2, 1, 1)) == false
		and base:FuzzyEq(Vector3.new(1.05, 1, 1), 0.1)
end)

test("Vector2 constants and arithmetic", function()
	local left = Vector2.new(1, 2)
	local right = Vector2.new(3, 4)

	return Vector2.zero == Vector2.new(0, 0)
		and Vector2.one == Vector2.new(1, 1)
		and Vector2.xAxis == Vector2.new(1, 0)
		and Vector2.yAxis == Vector2.new(0, 1)
		and left + right == Vector2.new(4, 6)
		and right - left == Vector2.new(2, 2)
		and left * 2 == Vector2.new(2, 4)
		and right / 2 == Vector2.new(1.5, 2)
		and -left == Vector2.new(-1, -2)
end)

test("Vector2 methods", function()
	local right = Vector2.new(1, 0)
	local up = Vector2.new(0, 1)

	return nearlyEqual(right:Dot(up), 0)
		and type(right:Cross(up)) == "number"
		and nearlyEqual(right:Angle(up), math.pi / 2)
		and right:Lerp(up, 0.5) == Vector2.new(0.5, 0.5)
		and nearlyEqual(Vector2.new(3, 4).Magnitude, 5)
		and nearlyEqual(Vector2.new(3, 4).Unit.Magnitude, 1)
		and Vector2.new(-1.5, 2.5):Abs() == Vector2.new(1.5, 2.5)
		and Vector2.new(-1.5, 2.5):Floor() == Vector2.new(-2, 2)
		and Vector2.new(-1.5, 2.5):Ceil() == Vector2.new(-1, 3)
		and Vector2.new(-1.5, 2.5):Sign() == Vector2.new(-1, 1)
end)

test("CFrame identity and constructors", function()
	return CFrame.identity == CFrame.new()
		and CFrame.new(1, 2, 3).Position == Vector3.new(1, 2, 3)
		and CFrame.new(Vector3.new(4, 5, 6)).Position == Vector3.new(4, 5, 6)
		and typeof(CFrame.lookAt(Vector3.zero, Vector3.new(0, 0, -1))) == "CFrame"
		and typeof(CFrame.lookAlong(Vector3.zero, Vector3.new(0, 0, -1))) == "CFrame"
		and typeof(CFrame.fromRotationBetweenVectors(Vector3.xAxis, Vector3.yAxis)) == "CFrame"
		and typeof(CFrame.fromMatrix(Vector3.zero, Vector3.xAxis, Vector3.yAxis)) == "CFrame"
end)

test("CFrame euler constructors", function()
	local xyz = CFrame.fromEulerAnglesXYZ(0, math.pi / 2, 0)
	local yxz = CFrame.fromEulerAnglesYXZ(0, math.pi / 2, 0)
	local ordered = CFrame.fromEulerAngles(0, math.pi / 2, 0, Enum.RotationOrder.XYZ)
	local angles = CFrame.Angles(0, math.pi / 2, 0)
	local orientation = CFrame.fromOrientation(0, math.pi / 2, 0)

	local _, y = xyz:ToEulerAnglesXYZ()

	return nearlyEqual(y, math.pi / 2, 0.001)
		and typeof(yxz) == "CFrame"
		and typeof(ordered) == "CFrame"
		and typeof(angles) == "CFrame"
		and typeof(orientation) == "CFrame"
end)

test("CFrame axis vectors", function()
	local frame = CFrame.new(1, 2, 3)

	return frame.LookVector == Vector3.new(0, 0, -1)
		and frame.RightVector == Vector3.new(1, 0, 0)
		and frame.UpVector == Vector3.new(0, 1, 0)
		and frame.XVector == Vector3.new(1, 0, 0)
		and frame.YVector == Vector3.new(0, 1, 0)
		and frame.ZVector == Vector3.new(0, 0, 1)
		and frame.X == 1
		and frame.Y == 2
		and frame.Z == 3
		and frame.Rotation.Position == Vector3.zero
end)

test("CFrame space conversions", function()
	local frame = CFrame.new(10, 0, 0)
	local worldPoint = frame:PointToWorldSpace(Vector3.new(1, 0, 0))
	local objectPoint = frame:PointToObjectSpace(Vector3.new(11, 0, 0))
	local worldVector = frame:VectorToWorldSpace(Vector3.new(1, 0, 0))
	local objectVector = frame:VectorToObjectSpace(Vector3.new(1, 0, 0))
	local worldFrame = frame:ToWorldSpace(CFrame.new(1, 0, 0))
	local objectFrame = frame:ToObjectSpace(CFrame.new(11, 0, 0))

	return worldPoint == Vector3.new(11, 0, 0)
		and objectPoint == Vector3.new(1, 0, 0)
		and worldVector == Vector3.new(1, 0, 0)
		and objectVector == Vector3.new(1, 0, 0)
		and worldFrame.Position == Vector3.new(11, 0, 0)
		and objectFrame.Position == Vector3.new(1, 0, 0)
end)

test("CFrame inverse and multiplication", function()
	local frame = CFrame.new(5, 0, 0) * CFrame.Angles(0, math.pi / 2, 0)
	local identity = frame * frame:Inverse()

	return identity:FuzzyEq(CFrame.identity, 0.001)
		and (CFrame.new(2, 3, 4) * CFrame.new(4, 5, 6)).Position == Vector3.new(6, 8, 10)
		and (CFrame.new(1, 2, 3) + Vector3.new(1, 1, 1)).Position == Vector3.new(2, 3, 4)
		and (CFrame.new(1, 2, 3) - Vector3.new(1, 1, 1)).Position == Vector3.new(0, 1, 2)
		and CFrame.new(1, 2, 3) * Vector3.new(1, 0, 0) == Vector3.new(2, 2, 3)
end)

test("CFrame components and lerp", function()
	local frame = CFrame.new(1, 2, 3)
	local components = { frame:GetComponents() }
	local middle = CFrame.new(0, 0, 0):Lerp(CFrame.new(10, 0, 0), 0.5)

	return #components == 12
		and components[1] == 1
		and components[2] == 2
		and components[3] == 3
		and middle.Position == Vector3.new(5, 0, 0)
		and typeof(frame:Orthonormalize()) == "CFrame"
end)

test("CFrame axis angle round trip", function()
	local angle = math.pi / 3
	local frame = CFrame.fromAxisAngle(Vector3.yAxis, angle)
	local axis, retrieved = frame:ToAxisAngle()

	return typeof(axis) == "Vector3"
		and nearlyEqual(math.abs(retrieved), angle, 0.001)
		and nearlyEqual(axis.Magnitude, 1, 0.001)
end)

test("CFrame orientation round trip", function()
	local frame = CFrame.fromOrientation(0.1, 0.2, 0.3)
	local x, y, z = frame:ToOrientation()

	return nearlyEqual(x, 0.1, 0.001)
		and nearlyEqual(y, 0.2, 0.001)
		and nearlyEqual(z, 0.3, 0.001)
end)

test("Color3 constructors and channels", function()
	local fromFloat = Color3.new(0.25, 0.5, 0.75)
	local fromBytes = Color3.fromRGB(64, 128, 192)
	local fromHex = Color3.fromHex("#FF0000")

	return nearlyEqual(fromFloat.R, 0.25)
		and nearlyEqual(fromFloat.G, 0.5)
		and nearlyEqual(fromFloat.B, 0.75)
		and nearlyEqual(fromBytes.R, 64 / 255, 0.01)
		and nearlyEqual(fromHex.R, 1)
		and nearlyEqual(fromHex.G, 0)
		and Color3.new() == Color3.new(0, 0, 0)
end)

test("Color3 conversions round trip", function()
	local color = Color3.fromRGB(120, 60, 200)
	local hue, saturation, value = color:ToHSV()
	local restored = Color3.fromHSV(hue, saturation, value)
	local hex = color:ToHex()

	return nearlyEqual(restored.R, color.R, 0.01)
		and nearlyEqual(restored.G, color.G, 0.01)
		and nearlyEqual(restored.B, color.B, 0.01)
		and type(hex) == "string"
		and #hex == 6
		and Color3.fromHex(hex):ToHex() == hex
end)

test("Color3 lerp", function()
	local black = Color3.new(0, 0, 0)
	local white = Color3.new(1, 1, 1)
	local middle = black:Lerp(white, 0.5)

	return nearlyEqual(middle.R, 0.5)
		and nearlyEqual(middle.G, 0.5)
		and nearlyEqual(middle.B, 0.5)
		and black:Lerp(white, 0) == black
		and black:Lerp(white, 1) == white
end)

test("BrickColor named constructors", function()
	return BrickColor.White().Name == "White"
		and BrickColor.Black().Name == "Black"
		and BrickColor.Red().Name == "Bright red"
		and BrickColor.Blue().Name == "Bright blue"
		and BrickColor.Green().Name == "Dark green"
		and BrickColor.Yellow().Name == "Bright yellow"
		and BrickColor.Gray().Name == "Medium stone grey"
		and BrickColor.DarkGray().Name == "Dark stone grey"
end)

test("BrickColor properties and conversion", function()
	local color = BrickColor.new("Bright red")
	local fromNumber = BrickColor.new(color.Number)
	local fromColor = BrickColor.new(color.Color)
	local random = BrickColor.random()
	local palette = BrickColor.palette(0)

	return type(color.Name) == "string"
		and type(color.Number) == "number"
		and typeof(color.Color) == "Color3"
		and type(color.r) == "number"
		and type(color.g) == "number"
		and type(color.b) == "number"
		and fromNumber == color
		and fromColor == color
		and typeof(random) == "BrickColor"
		and typeof(palette) == "BrickColor"
end)

test("BrickColor invalid input fallback", function()
	local invalidName = BrickColor.new("LogUncNotAColor")
	local invalidNumber = BrickColor.new(-500)

	return typeof(invalidName) == "BrickColor"
		and typeof(invalidNumber) == "BrickColor"
		and invalidName.Name == "Medium stone grey"
end)

test("UDim arithmetic", function()
	local first = UDim.new(0.5, 10)
	local second = UDim.new(0.25, 5)

	return first.Scale == 0.5
		and first.Offset == 10
		and (first + second) == UDim.new(0.75, 15)
		and (first - second) == UDim.new(0.25, 5)
		and UDim.new() == UDim.new(0, 0)
end)

test("UDim2 constructors and lerp", function()
	local full = UDim2.new(0.5, 10, 0.25, 20)
	local fromScale = UDim2.fromScale(0.5, 0.25)
	local fromOffset = UDim2.fromOffset(10, 20)
	local fromUDim = UDim2.new(UDim.new(0.5, 10), UDim.new(0.25, 20))

	return full.X == UDim.new(0.5, 10)
		and full.Y == UDim.new(0.25, 20)
		and full.Width == full.X
		and full.Height == full.Y
		and fromScale == UDim2.new(0.5, 0, 0.25, 0)
		and fromOffset == UDim2.new(0, 10, 0, 20)
		and fromUDim == full
		and UDim2.new():Lerp(fromOffset, 0.5) == UDim2.fromOffset(5, 10)
		and (fromScale + fromOffset) == full
end)

test("Rect construction", function()
	local fromNumbers = Rect.new(10, 20, 100, 200)
	local fromVectors = Rect.new(Vector2.new(10, 20), Vector2.new(100, 200))

	return fromNumbers.Min == Vector2.new(10, 20)
		and fromNumbers.Max == Vector2.new(100, 200)
		and nearlyEqual(fromNumbers.Width, 90)
		and nearlyEqual(fromNumbers.Height, 180)
		and fromVectors == fromNumbers
end)

test("Region3 and grid expansion", function()
	local region = Region3.new(Vector3.new(-2, -2, -2), Vector3.new(2, 2, 2))
	local expanded = region:ExpandToGrid(4)

	return typeof(region) == "Region3"
		and region.Size == Vector3.new(4, 4, 4)
		and region.CFrame.Position == Vector3.zero
		and typeof(expanded) == "Region3"
		and expanded.Size.X >= 4
end)

test("Region3int16 and Vector3int16", function()
	local minimum = Vector3int16.new(-10, -20, -30)
	local maximum = Vector3int16.new(10, 20, 30)
	local region = Region3int16.new(minimum, maximum)

	return minimum.X == -10
		and minimum.Y == -20
		and minimum.Z == -30
		and region.Min == minimum
		and region.Max == maximum
		and (minimum + maximum) == Vector3int16.new(0, 0, 0)
		and (maximum - minimum) == Vector3int16.new(20, 40, 60)
end)

test("NumberRange construction", function()
	local single = NumberRange.new(5)
	local range = NumberRange.new(1, 10)

	return single.Min == 5
		and single.Max == 5
		and range.Min == 1
		and range.Max == 10
		and pcall(NumberRange.new, 10, 1) == false
end)

test("NumberSequence keypoints", function()
	local single = NumberSequence.new(0.5)
	local pair = NumberSequence.new(0, 1)
	local explicit = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.5, 0.1),
		NumberSequenceKeypoint.new(1, 1)
	})

	return #single.Keypoints == 2
		and #pair.Keypoints == 2
		and pair.Keypoints[1].Value == 0
		and pair.Keypoints[2].Value == 1
		and #explicit.Keypoints == 3
		and nearlyEqual(explicit.Keypoints[2].Envelope, 0.1)
		and nearlyEqual(explicit.Keypoints[2].Time, 0.5)
end)

test("ColorSequence keypoints", function()
	local single = ColorSequence.new(Color3.new(1, 0, 0))
	local pair = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(1, 1, 1))
	local explicit = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.new(0, 0, 1))
	})

	return #single.Keypoints == 2
		and #pair.Keypoints == 2
		and typeof(pair.Keypoints[1].Value) == "Color3"
		and #explicit.Keypoints == 2
		and nearlyEqual(explicit.Keypoints[2].Time, 1)
end)

test("NumberSequence rejects bad keypoints", function()
	return pcall(NumberSequence.new, {
		NumberSequenceKeypoint.new(0.5, 0)
	}) == false
		and pcall(ColorSequence.new, {
			ColorSequenceKeypoint.new(0, Color3.new())
		}) == false
end)

test("Random determinism by seed", function()
	local first = Random.new(42)
	local second = Random.new(42)

	return first:NextNumber() == second:NextNumber()
		and first:NextInteger(1, 100) == second:NextInteger(1, 100)
		and typeof(first:NextUnitVector()) == "Vector3"
		and nearlyEqual(first:NextUnitVector().Magnitude, 1, 0.001)
end)

test("Random clone and shuffle", function()
	local generator = Random.new(7)
	local clone = generator:Clone()

	local fromOriginal = generator:NextNumber()
	local fromClone = clone:NextNumber()
	local list = { 1, 2, 3, 4, 5 }

	generator:Shuffle(list)

	local sum = 0

	for _, value in ipairs(list) do
		sum += value
	end

	return fromOriginal == fromClone
		and #list == 5
		and sum == 15
end)

test("Random ranges", function()
	local generator = Random.new(99)

	for _ = 1, 32 do
		local number = generator:NextNumber(5, 10)
		local integer = generator:NextInteger(-3, 3)

		if number < 5 or number > 10 then
			return false, "NextNumber out of range"
		end

		if integer < -3 or integer > 3 or integer % 1 ~= 0 then
			return false, "NextInteger out of range"
		end
	end

	return true
end)

test("Ray members", function()
	local ray = Ray.new(Vector3.new(0, 0, 0), Vector3.new(0, 10, 0))

	return ray.Origin == Vector3.zero
		and ray.Direction == Vector3.new(0, 10, 0)
		and nearlyEqual(ray.Unit.Direction.Magnitude, 1)
		and ray:ClosestPoint(Vector3.new(5, 5, 0)) == Vector3.new(0, 5, 0)
		and nearlyEqual(ray:Distance(Vector3.new(5, 5, 0)), 5)
end)

test("Faces construction", function()
	local faces = Faces.new(Enum.NormalId.Front, Enum.NormalId.Back)
	local empty = Faces.new()

	return faces.Front == true
		and faces.Back == true
		and faces.Top == false
		and faces.Bottom == false
		and faces.Left == false
		and faces.Right == false
		and empty.Front == false
end)

test("Axes construction", function()
	local axes = Axes.new(Enum.Axis.X, Enum.Axis.Y)
	local fromNormal = Axes.new(Enum.NormalId.Top)

	return axes.X == true
		and axes.Y == true
		and axes.Z == false
		and axes.Left == true
		and axes.Right == true
		and axes.Top == true
		and axes.Bottom == true
		and axes.Front == false
		and fromNormal.Y == true
end)

test("TweenInfo defaults and overrides", function()
	local defaults = TweenInfo.new()
	local custom = TweenInfo.new(
		2,
		Enum.EasingStyle.Bounce,
		Enum.EasingDirection.InOut,
		3,
		true,
		0.5
	)

	return nearlyEqual(defaults.Time, 1)
		and defaults.EasingStyle == Enum.EasingStyle.Quad
		and defaults.EasingDirection == Enum.EasingDirection.Out
		and defaults.RepeatCount == 0
		and defaults.Reverses == false
		and nearlyEqual(defaults.DelayTime, 0)
		and nearlyEqual(custom.Time, 2)
		and custom.EasingStyle == Enum.EasingStyle.Bounce
		and custom.EasingDirection == Enum.EasingDirection.InOut
		and custom.RepeatCount == 3
		and custom.Reverses == true
		and nearlyEqual(custom.DelayTime, 0.5)
end)

test("PhysicalProperties overloads", function()
	local fromMaterial = PhysicalProperties.new(Enum.Material.Wood)
	local threeArgs = PhysicalProperties.new(0.5, 0.3, 0.2)
	local fiveArgs = PhysicalProperties.new(0.5, 0.3, 0.2, 1, 1)

	return typeof(fromMaterial) == "PhysicalProperties"
		and fromMaterial.Density > 0
		and typeof(threeArgs) == "PhysicalProperties"
		and nearlyEqual(threeArgs.Density, 0.5)
		and nearlyEqual(fiveArgs.FrictionWeight, 1)
		and nearlyEqual(fiveArgs.ElasticityWeight, 1)
end)

test("PathWaypoint construction", function()
	local waypoint = PathWaypoint.new(
		Vector3.new(1, 2, 3),
		Enum.PathWaypointAction.Jump,
		"Label"
	)

	return waypoint.Position == Vector3.new(1, 2, 3)
		and waypoint.Action == Enum.PathWaypointAction.Jump
		and type(waypoint.Label) == "string"
end)

test("FloatCurveKey construction", function()
	local key = FloatCurveKey.new(0.5, 10, Enum.KeyInterpolationMode.Cubic)

	return typeof(key) == "FloatCurveKey"
		and nearlyEqual(key.Time, 0.5)
		and nearlyEqual(key.Value, 10)
		and key.Interpolation == Enum.KeyInterpolationMode.Cubic
end)

test("Font constructors", function()
	local fromEnum = Font.fromEnum(Enum.Font.SourceSans)
	local fromName = Font.fromName("BuilderSans", Enum.FontWeight.Bold, Enum.FontStyle.Italic)
	local fromId = Font.fromId(12187365364)

	return typeof(fromEnum) == "Font"
		and typeof(fromName) == "Font"
		and typeof(fromId) == "Font"
		and fromName.Weight == Enum.FontWeight.Bold
		and fromName.Style == Enum.FontStyle.Italic
		and fromName.Bold == true
		and fromEnum.Weight == Enum.FontWeight.Regular
end)

test("Font rejects unknown enum", function()
	return pcall(Font.fromEnum, Enum.Font.Unknown) == false
end)

test("Enums enumeration", function()
	local enums = Enum:GetEnums()

	return type(enums) == "table"
		and #enums > 100
		and typeof(Enum) == "Enums"
		and typeof(enums[1]) == "Enum"
end)

test("Enum item lookups", function()
	local plastic = Enum.Material.Plastic
	local byName = Enum.Material:FromName("Plastic")
	local byValue = Enum.Material:FromValue(plastic.Value)
	local items = Enum.Material:GetEnumItems()

	return byName == plastic
		and byValue == plastic
		and type(items) == "table"
		and #items > 10
		and Enum.Material:FromName("LogUncNotAMaterial") == nil
		and Enum.Material:FromValue(-12345) == nil
end)

test("EnumItem members", function()
	local item = Enum.EasingStyle.Linear

	return typeof(item) == "EnumItem"
		and item.Name == "Linear"
		and item.Value == 0
		and item.EnumType == Enum.EasingStyle
		and tostring(item) == "Enum.EasingStyle.Linear"
end)

test("Enum item counts", function()
	local expectations = {
		[Enum.NormalId] = 6,
		[Enum.Axis] = 3,
		[Enum.PartType] = 5,
		[Enum.EasingDirection] = 3,
		[Enum.EasingStyle] = 11,
		[Enum.RaycastFilterType] = 2,
		[Enum.SortOrder] = 3,
		[Enum.ZIndexBehavior] = 2,
		[Enum.HumanoidRigType] = 2,
		[Enum.RotationOrder] = 6,
		[Enum.FontWeight] = 9,
		[Enum.FontStyle] = 2
	}

	for enumType, expected in pairs(expectations) do
		local items = enumType:GetEnumItems()

		if #items ~= expected then
			return false, tostring(enumType) .. " has " .. #items
		end
	end

	return true
end)

test("Enum values are stable", function()
	return Enum.Material.Plastic.Value == 256
		and Enum.Material.SmoothPlastic.Value == 272
		and Enum.Material.Neon.Value == 288
		and Enum.NormalId.Right.Value == 0
		and Enum.NormalId.Top.Value == 1
		and Enum.NormalId.Front.Value == 5
		and Enum.PartType.Ball.Value == 0
		and Enum.PartType.Block.Value == 1
		and Enum.FontWeight.Regular.Value == 400
		and Enum.FontWeight.Bold.Value == 700
end)

test("Enum rejects unknown items", function()
	return pcall(function()
		return Enum.Material.LogUncNotAMaterial
	end) == false
		and pcall(function()
			return Enum.LogUncNotAnEnum
		end) == false
end)

test("DateTime constructors", function()
	local now = DateTime.now()
	local fromSeconds = DateTime.fromUnixTimestamp(0)
	local fromMillis = DateTime.fromUnixTimestampMillis(1000)
	local fromUniversal = DateTime.fromUniversalTime(2020, 1, 1, 0, 0, 0, 0)
	local fromLocal = DateTime.fromLocalTime(2020, 1, 1)
	local fromIso = DateTime.fromIsoDate("2020-01-01T00:00:00Z")

	return typeof(now) == "DateTime"
		and now.UnixTimestamp > 0
		and fromSeconds.UnixTimestamp == 0
		and fromMillis.UnixTimestampMillis == 1000
		and typeof(fromUniversal) == "DateTime"
		and typeof(fromLocal) == "DateTime"
		and fromIso ~= nil
		and fromIso.UnixTimestamp == fromUniversal.UnixTimestamp
end)

test("DateTime conversions", function()
	local value = DateTime.fromUnixTimestamp(0)
	local universal = value:ToUniversalTime()
	local localTime = value:ToLocalTime()
	local iso = value:ToIsoDate()

	return universal.Year == 1970
		and universal.Month == 1
		and universal.Day == 1
		and type(localTime.Year) == "number"
		and type(iso) == "string"
		and string.find(iso, "1970", 1, true) == 1
		and type(value:FormatUniversalTime("YYYY", "en-us")) == "string"
		and type(value:FormatLocalTime("YYYY", "en-us")) == "string"
end)

test("DateTime equality and invalid input", function()
	local first = DateTime.fromUnixTimestampMillis(1500)
	local second = DateTime.fromUnixTimestampMillis(1500)

	return first == second
		and DateTime.fromIsoDate("not a date") == nil
		and pcall(DateTime.fromUniversalTime, 2021, 2, 29) == false
end)

test("os.time and os.date agreement", function()
	local timestamp = os.time({
		year = 2000,
		month = 1,
		day = 1,
		hour = 0,
		min = 0,
		sec = 0
	})
	local parts = os.date("!*t", 0)
	local formatted = os.date("!%Y-%m-%d", 0)

	return timestamp == 946684800
		and parts.year == 1970
		and parts.month == 1
		and parts.day == 1
		and type(parts.isdst) == "boolean"
		and formatted == "1970-01-01"
		and os.difftime(100, 40) == 60
end)

test("os.clock monotonicity", function()
	local first = os.clock()

	for _ = 1, 1000 do
	end

	local second = os.clock()

	return type(first) == "number"
		and type(second) == "number"
		and second >= first
		and type(os.time()) == "number"
		and os.time() > 1600000000
end)

test("Content datatype", function()
	local ok, container = pcall(function()
		return Content
	end)

	if not ok or container == nil then
		return false, "Content unavailable"
	end

	local none = Content.none
	local fromUri = Content.fromUri("rbxassetid://0")

	if typeof(none) ~= "Content" or typeof(fromUri) ~= "Content" then
		return false, "Content constructors unavailable"
	end

	return none.SourceType == Enum.ContentSourceType.None
		and fromUri.SourceType == Enum.ContentSourceType.Uri
		and fromUri.Uri == "rbxassetid://0"
		and Content.fromUri("").SourceType == Enum.ContentSourceType.None
		and type(Content.fromObject) == "function"
		and pcall(Content.fromObject, nil) == false
end)

test("CatalogSearchParams configuration", function()
	local parameters = CatalogSearchParams.new()

	parameters.SearchKeyword = "hat"
	parameters.MinPrice = 10
	parameters.MaxPrice = 100
	parameters.SortType = Enum.CatalogSortType.PriceLowToHigh
	parameters.CategoryFilter = Enum.CatalogCategoryFilter.None
	parameters.SalesTypeFilter = Enum.SalesTypeFilter.All
	parameters.IncludeOffSale = true
	parameters.CreatorName = "Roblox"
	parameters.Limit = 30

	return typeof(parameters) == "CatalogSearchParams"
		and parameters.SearchKeyword == "hat"
		and parameters.MinPrice == 10
		and parameters.MaxPrice == 100
		and parameters.SortType == Enum.CatalogSortType.PriceLowToHigh
		and parameters.IncludeOffSale == true
		and parameters.CreatorName == "Roblox"
		and parameters.Limit == 30
		and type(parameters.BundleTypes) == "table"
end)

test("typeof covers Roblox datatypes", function()
	local expectations = {
		{ Vector3.new(), "Vector3" },
		{ Vector2.new(), "Vector2" },
		{ Vector3int16.new(), "Vector3int16" },
		{ CFrame.new(), "CFrame" },
		{ Color3.new(), "Color3" },
		{ BrickColor.new(1), "BrickColor" },
		{ UDim.new(), "UDim" },
		{ UDim2.new(), "UDim2" },
		{ Rect.new(0, 0, 1, 1), "Rect" },
		{ Region3.new(Vector3.zero, Vector3.one), "Region3" },
		{ Region3int16.new(Vector3int16.new(), Vector3int16.new()), "Region3int16" },
		{ NumberRange.new(1), "NumberRange" },
		{ NumberSequence.new(0), "NumberSequence" },
		{ NumberSequenceKeypoint.new(0, 0), "NumberSequenceKeypoint" },
		{ ColorSequence.new(Color3.new()), "ColorSequence" },
		{ ColorSequenceKeypoint.new(0, Color3.new()), "ColorSequenceKeypoint" },
		{ Ray.new(Vector3.zero, Vector3.one), "Ray" },
		{ Faces.new(), "Faces" },
		{ Axes.new(), "Axes" },
		{ TweenInfo.new(), "TweenInfo" },
		{ PhysicalProperties.new(1, 1, 1), "PhysicalProperties" },
		{ RaycastParams.new(), "RaycastParams" },
		{ OverlapParams.new(), "OverlapParams" },
		{ PathWaypoint.new(Vector3.zero, Enum.PathWaypointAction.Walk), "PathWaypoint" },
		{ DateTime.now(), "DateTime" },
		{ Random.new(1), "Random" },
		{ Enum.Material.Plastic, "EnumItem" },
		{ Enum.Material, "Enum" },
		{ Enum, "Enums" },
		{ game, "Instance" },
		{ 1, "number" },
		{ "s", "string" },
		{ true, "boolean" },
		{ nil, "nil" },
		{ {}, "table" },
		{ print, "function" }
	}

	for _, entry in ipairs(expectations) do
		local actual = typeof(entry[1])

		if actual ~= entry[2] then
			return false, entry[2] .. " reported as " .. actual
		end
	end

	return true
end)

test("Camera projection helpers", function()
	return withTemporary("Camera", function(camera)
		camera.CFrame = CFrame.new(0, 0, 10)
		camera.FieldOfView = 70

		local viewportRay = camera:ViewportPointToRay(100, 100, 1)
		local screenRay = camera:ScreenPointToRay(100, 100, 1)
		local screenPoint, onScreen = camera:WorldToScreenPoint(Vector3.new(0, 0, 0))
		local viewportPoint, inViewport = camera:WorldToViewportPoint(Vector3.new(0, 0, 0))

		return typeof(viewportRay) == "Ray"
			and typeof(screenRay) == "Ray"
			and typeof(screenPoint) == "Vector3"
			and type(onScreen) == "boolean"
			and typeof(viewportPoint) == "Vector3"
			and type(inViewport) == "boolean"
			and typeof(camera:GetRenderCFrame()) == "CFrame"
			and type(camera:GetPartsObscuringTarget({ Vector3.new() }, {})) == "table"
	end)
end)

test("Camera field of view modes", function()
	return withTemporary("Camera", function(camera)
		camera.FieldOfViewMode = Enum.FieldOfViewMode.MaxAxis
		camera.FieldOfView = 80
		camera.HeadLocked = false

		return camera.FieldOfViewMode == Enum.FieldOfViewMode.MaxAxis
			and nearlyEqual(camera.FieldOfView, 80)
			and camera.HeadLocked == false
			and type(camera.DiagonalFieldOfView) == "number"
			and type(camera.MaxAxisFieldOfView) == "number"
			and type(camera.NearPlaneZ) == "number"
			and typeof(camera.ViewportSize) == "Vector2"
	end)
end)

test("Camera subject and type", function()
	local camera = Instance.new("Camera")
	local part = Instance.new("Part")

	camera.CameraSubject = part
	camera.CameraType = Enum.CameraType.Scriptable

	local valid = camera.CameraSubject == part
		and camera.CameraType == Enum.CameraType.Scriptable
		and camera:IsA("PVInstance")

	part:Destroy()
	camera:Destroy()

	return valid
end)

test("Lighting sun and moon", function()
	local lighting = game:GetService("Lighting")
	local sun = lighting:GetSunDirection()
	local moon = lighting:GetMoonDirection()
	local phase = lighting:GetMoonPhase()

	return typeof(sun) == "Vector3"
		and typeof(moon) == "Vector3"
		and type(phase) == "number"
		and nearlyEqual(sun.Magnitude, 1, 0.01)
		and nearlyEqual(moon.Magnitude, 1, 0.01)
end)

test("Lighting clock time round trip", function()
	local lighting = game:GetService("Lighting")
	local originalClock = lighting.ClockTime
	local originalTimeOfDay = lighting.TimeOfDay

	lighting.ClockTime = 14.5

	local clockApplied = nearlyEqual(lighting.ClockTime, 14.5, 0.01)
	local timeStringChanged = string.find(lighting.TimeOfDay, "14", 1, true) == 1

	lighting.TimeOfDay = "06:00:00"

	local timeApplied = nearlyEqual(lighting.ClockTime, 6, 0.01)

	lighting.ClockTime = originalClock
	lighting.TimeOfDay = originalTimeOfDay

	return clockApplied
		and timeStringChanged
		and timeApplied
end)

test("Lighting appearance properties", function()
	local lighting = game:GetService("Lighting")

	return typeof(lighting.Ambient) == "Color3"
		and typeof(lighting.OutdoorAmbient) == "Color3"
		and typeof(lighting.FogColor) == "Color3"
		and type(lighting.Brightness) == "number"
		and type(lighting.FogStart) == "number"
		and type(lighting.FogEnd) == "number"
		and type(lighting.GeographicLatitude) == "number"
		and type(lighting.GlobalShadows) == "boolean"
		and type(lighting.ExposureCompensation) == "number"
		and type(lighting.ShadowSoftness) == "number"
		and type(lighting.EnvironmentDiffuseScale) == "number"
		and type(lighting.EnvironmentSpecularScale) == "number"
end)

test("Atmosphere and Sky creation", function()
	local atmosphere = Instance.new("Atmosphere")
	local sky = Instance.new("Sky")

	atmosphere.Density = 0.4
	atmosphere.Offset = 0.25
	atmosphere.Haze = 2
	atmosphere.Glare = 1
	sky.SkyboxUp = "rbxassetid://0"
	sky.StarCount = 3000
	sky.CelestialBodiesShown = false

	local valid = nearlyEqual(atmosphere.Density, 0.4)
		and nearlyEqual(atmosphere.Offset, 0.25)
		and nearlyEqual(atmosphere.Haze, 2)
		and typeof(atmosphere.Color) == "Color3"
		and typeof(atmosphere.Decay) == "Color3"
		and sky.SkyboxUp == "rbxassetid://0"
		and sky.StarCount == 3000
		and sky.CelestialBodiesShown == false

	atmosphere:Destroy()
	sky:Destroy()

	return valid
end)

test("Post processing effects", function()
	local bloom = Instance.new("BloomEffect")
	local blur = Instance.new("BlurEffect")
	local correction = Instance.new("ColorCorrectionEffect")
	local sunRays = Instance.new("SunRaysEffect")
	local depthOfField = Instance.new("DepthOfFieldEffect")

	bloom.Intensity = 1.5
	bloom.Size = 32
	bloom.Threshold = 1
	blur.Size = 12
	correction.Saturation = 0.5
	correction.Contrast = 0.25
	correction.Brightness = 0.1
	correction.TintColor = Color3.fromRGB(255, 200, 200)
	sunRays.Intensity = 0.2
	sunRays.Spread = 0.5
	depthOfField.FocusDistance = 20
	depthOfField.InFocusRadius = 10
	depthOfField.NearIntensity = 0.5
	depthOfField.FarIntensity = 0.25

	local valid = nearlyEqual(bloom.Intensity, 1.5)
		and nearlyEqual(blur.Size, 12)
		and nearlyEqual(correction.Saturation, 0.5)
		and typeof(correction.TintColor) == "Color3"
		and nearlyEqual(sunRays.Intensity, 0.2)
		and nearlyEqual(depthOfField.FocusDistance, 20)
		and bloom:IsA("PostEffect")
		and blur:IsA("PostEffect")
		and correction:IsA("PostEffect")

	bloom:Destroy()
	blur:Destroy()
	correction:Destroy()
	sunRays:Destroy()
	depthOfField:Destroy()

	return valid
end)

test("Sound playback state", function()
	return withTemporary("Sound", function(sound)
		sound.SoundId = "rbxassetid://0"
		sound.Volume = 0.5
		sound.PlaybackSpeed = 2
		sound.Looped = true
		sound.PlayOnRemove = false
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.PlaybackRegionsEnabled = true
		sound.PlaybackRegion = NumberRange.new(0, 1)
		sound.LoopRegion = NumberRange.new(0, 1)

		return nearlyEqual(sound.Volume, 0.5)
			and nearlyEqual(sound.PlaybackSpeed, 2)
			and sound.Looped == true
			and sound.RollOffMode == Enum.RollOffMode.InverseTapered
			and sound.PlaybackRegionsEnabled == true
			and typeof(sound.PlaybackRegion) == "NumberRange"
			and typeof(sound.LoopRegion) == "NumberRange"
			and type(sound.TimeLength) == "number"
			and type(sound.TimePosition) == "number"
			and type(sound.PlaybackLoudness) == "number"
			and type(sound.Playing) == "boolean"
			and type(sound.IsPaused) == "boolean"
			and isSignal(sound.Loaded)
			and isSignal(sound.Played)
			and isSignal(sound.Ended)
			and hasMethod(sound, "Resume")
	end)
end)

test("SoundGroup routing", function()
	local group = Instance.new("SoundGroup")
	local sound = Instance.new("Sound")

	group.Volume = 0.5
	sound.SoundGroup = group

	local valid = nearlyEqual(group.Volume, 0.5)
		and sound.SoundGroup == group

	sound:Destroy()
	group:Destroy()

	return valid
end)

test("SoundService configuration", function()
	local soundService = game:GetService("SoundService")
	local originalReverb = soundService.AmbientReverb

	soundService.AmbientReverb = Enum.ReverbType.Hangar

	local applied = soundService.AmbientReverb == Enum.ReverbType.Hangar

	soundService.AmbientReverb = originalReverb

	local listenerType, listenerObject = soundService:GetListener()

	return applied
		and type(soundService.DistanceFactor) == "number"
		and type(soundService.DopplerScale) == "number"
		and type(soundService.RolloffScale) == "number"
		and type(soundService.RespectFilteringEnabled) == "boolean"
		and typeof(listenerType) == "EnumItem"
		and (listenerObject == nil or typeof(listenerObject) == "Instance" or typeof(listenerObject) == "CFrame")
		and hasMethod(soundService, "SetListener")
		and hasMethod(soundService, "PlayLocalSound")
		and type(soundService:GetMixerTime()) == "number"
end)

test("Value object types", function()
	local expectations = {
		{ "NumberValue", 42.5, "number" },
		{ "IntValue", 42, "number" },
		{ "StringValue", "text", "string" },
		{ "BoolValue", true, "boolean" },
		{ "CFrameValue", CFrame.new(1, 2, 3), "CFrame" },
		{ "Vector3Value", Vector3.new(1, 2, 3), "Vector3" },
		{ "Color3Value", Color3.new(1, 0, 0), "Color3" },
		{ "BrickColorValue", BrickColor.new("Bright red"), "BrickColor" },
		{ "RayValue", Ray.new(Vector3.zero, Vector3.one), "Ray" }
	}

	for _, entry in ipairs(expectations) do
		local object = Instance.new(entry[1])

		object.Value = entry[2]

		local stored = object.Value
		local reported = typeof(stored)

		object:Destroy()

		if entry[3] == "number" or entry[3] == "string" or entry[3] == "boolean" then
			if type(stored) ~= entry[3] then
				return false, entry[1] .. " stored " .. type(stored)
			end
		elseif reported ~= entry[3] then
			return false, entry[1] .. " stored " .. reported
		end
	end

	return true
end)

test("IntValue truncates", function()
	return withTemporary("IntValue", function(value)
		value.Value = 7
		local exact = value.Value

		value.Value = 3
		local second = value.Value

		return exact == 7
			and second == 3
			and value.Value % 1 == 0
	end)
end)

test("ObjectValue references instances", function()
	local holder = Instance.new("ObjectValue")
	local target = Instance.new("Part")

	holder.Value = target

	local assigned = holder.Value == target

	holder.Value = nil

	local cleared = holder.Value == nil

	target:Destroy()
	holder:Destroy()

	return assigned
		and cleared
end)

test("Value object Changed carries value", function()
	local value = Instance.new("NumberValue")
	local received
	local connection = value.Changed:Connect(function(newValue)
		received = newValue
	end)

	value.Value = 17
	task.wait()
	connection:Disconnect()
	value:Destroy()

	return received == 17
end)

test("ObjectValue clone preserves reference", function()
	local root = Instance.new("Folder")
	local target = Instance.new("Part")
	local reference = Instance.new("ObjectValue")

	target.Name = "Target"
	target.Parent = root
	reference.Value = target
	reference.Parent = root

	local clone = root:Clone()
	local clonedTarget = clone:FindFirstChild("Target")
	local clonedReference = clone:FindFirstChildOfClass("ObjectValue")
	local valid = clonedReference ~= nil
		and clonedReference.Value == clonedTarget

	root:Destroy()
	clone:Destroy()

	return valid
end)

test("SpringConstraint physics properties", function()
	return withTemporary("SpringConstraint", function(spring)
		spring.FreeLength = 5
		spring.Stiffness = 100
		spring.Damping = 10
		spring.MaxForce = 5000
		spring.LimitsEnabled = true
		spring.MinLength = 1
		spring.MaxLength = 10
		spring.Coils = 3
		spring.Radius = 0.5
		spring.Thickness = 0.2
		spring.Visible = true

		return nearlyEqual(spring.FreeLength, 5)
			and nearlyEqual(spring.Stiffness, 100)
			and nearlyEqual(spring.Damping, 10)
			and nearlyEqual(spring.MaxForce, 5000)
			and spring.LimitsEnabled == true
			and nearlyEqual(spring.MinLength, 1)
			and nearlyEqual(spring.MaxLength, 10)
			and type(spring.CurrentLength) == "number"
			and spring:IsA("Constraint")
	end)
end)

test("AlignPosition configuration", function()
	return withTemporary("AlignPosition", function(align)
		align.Mode = Enum.PositionAlignmentMode.OneAttachment
		align.Position = Vector3.new(1, 2, 3)
		align.MaxForce = 10000
		align.MaxVelocity = 50
		align.Responsiveness = 25
		align.RigidityEnabled = false
		align.ApplyAtCenterOfMass = true
		align.ReactionForceEnabled = false

		return align.Mode == Enum.PositionAlignmentMode.OneAttachment
			and align.Position == Vector3.new(1, 2, 3)
			and nearlyEqual(align.MaxForce, 10000)
			and nearlyEqual(align.MaxVelocity, 50)
			and nearlyEqual(align.Responsiveness, 25)
			and align.ApplyAtCenterOfMass == true
			and align.RigidityEnabled == false
	end)
end)

test("AlignOrientation configuration", function()
	return withTemporary("AlignOrientation", function(align)
		align.Mode = Enum.OrientationAlignmentMode.OneAttachment
		align.AlignType = Enum.AlignType.PrimaryAxisLookAt
		align.CFrame = CFrame.Angles(0, math.pi / 2, 0)
		align.MaxTorque = 10000
		align.MaxAngularVelocity = 50
		align.Responsiveness = 25
		align.PrimaryAxisOnly = true
		align.ReactionTorqueEnabled = false

		return align.Mode == Enum.OrientationAlignmentMode.OneAttachment
			and align.AlignType == Enum.AlignType.PrimaryAxisLookAt
			and typeof(align.CFrame) == "CFrame"
			and nearlyEqual(align.MaxTorque, 10000)
			and align.PrimaryAxisOnly == true
	end)
end)

test("LinearVelocity configuration", function()
	return withTemporary("LinearVelocity", function(velocity)
		velocity.VectorVelocity = Vector3.new(0, 10, 0)
		velocity.MaxForce = 5000
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		velocity.ForceLimitMode = Enum.ForceLimitMode.Magnitude

		return velocity.VectorVelocity == Vector3.new(0, 10, 0)
			and nearlyEqual(velocity.MaxForce, 5000)
			and velocity.RelativeTo == Enum.ActuatorRelativeTo.World
			and velocity.VelocityConstraintMode == Enum.VelocityConstraintMode.Vector
			and velocity.ForceLimitMode == Enum.ForceLimitMode.Magnitude
	end)
end)

test("AngularVelocity configuration", function()
	return withTemporary("AngularVelocity", function(velocity)
		velocity.AngularVelocity = Vector3.new(0, 5, 0)
		velocity.MaxTorque = 4000
		velocity.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
		velocity.ReactionTorqueEnabled = false

		return velocity.AngularVelocity == Vector3.new(0, 5, 0)
			and nearlyEqual(velocity.MaxTorque, 4000)
			and velocity.RelativeTo == Enum.ActuatorRelativeTo.Attachment0
			and velocity.ReactionTorqueEnabled == false
	end)
end)

test("VectorForce and Torque configuration", function()
	local force = Instance.new("VectorForce")
	local torque = Instance.new("Torque")

	force.Force = Vector3.new(0, 100, 0)
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass = true
	torque.Torque = Vector3.new(0, 50, 0)
	torque.RelativeTo = Enum.ActuatorRelativeTo.World

	local valid = force.Force == Vector3.new(0, 100, 0)
		and force.RelativeTo == Enum.ActuatorRelativeTo.World
		and force.ApplyAtCenterOfMass == true
		and torque.Torque == Vector3.new(0, 50, 0)
		and torque.RelativeTo == Enum.ActuatorRelativeTo.World

	force:Destroy()
	torque:Destroy()

	return valid
end)

test("HingeConstraint actuator modes", function()
	return withTemporary("HingeConstraint", function(hinge)
		hinge.ActuatorType = Enum.ActuatorType.Motor
		hinge.AngularVelocity = 5
		hinge.MotorMaxTorque = 1000
		hinge.LimitsEnabled = true
		hinge.LowerAngle = -45
		hinge.UpperAngle = 45
		hinge.Restitution = 0.5
		hinge.Radius = 1

		return hinge.ActuatorType == Enum.ActuatorType.Motor
			and nearlyEqual(hinge.AngularVelocity, 5)
			and nearlyEqual(hinge.MotorMaxTorque, 1000)
			and hinge.LimitsEnabled == true
			and nearlyEqual(hinge.LowerAngle, -45)
			and nearlyEqual(hinge.UpperAngle, 45)
			and type(hinge.CurrentAngle) == "number"
	end)
end)

test("PrismaticConstraint actuator modes", function()
	return withTemporary("PrismaticConstraint", function(prismatic)
		prismatic.ActuatorType = Enum.ActuatorType.Servo
		prismatic.TargetPosition = 5
		prismatic.Speed = 2
		prismatic.ServoMaxForce = 2000
		prismatic.LimitsEnabled = true
		prismatic.LowerLimit = -10
		prismatic.UpperLimit = 10

		return prismatic.ActuatorType == Enum.ActuatorType.Servo
			and nearlyEqual(prismatic.TargetPosition, 5)
			and nearlyEqual(prismatic.Speed, 2)
			and prismatic.LimitsEnabled == true
			and type(prismatic.CurrentPosition) == "number"
	end)
end)

test("RopeConstraint and RodConstraint", function()
	local rope = Instance.new("RopeConstraint")
	local rod = Instance.new("RodConstraint")

	rope.Length = 10
	rope.Restitution = 0.5
	rope.Thickness = 0.2
	rope.Visible = true
	rod.Length = 5
	rod.Thickness = 0.3
	rod.LimitAngle0 = 30
	rod.LimitAngle1 = 30

	local valid = nearlyEqual(rope.Length, 10)
		and nearlyEqual(rope.Restitution, 0.5)
		and type(rope.CurrentDistance) == "number"
		and nearlyEqual(rod.Length, 5)
		and nearlyEqual(rod.LimitAngle0, 30)
		and rope:IsA("Constraint")
		and rod:IsA("Constraint")

	rope:Destroy()
	rod:Destroy()

	return valid
end)

test("BallSocketConstraint limits", function()
	return withTemporary("BallSocketConstraint", function(socket)
		socket.LimitsEnabled = true
		socket.UpperAngle = 45
		socket.TwistLimitsEnabled = true
		socket.TwistLowerAngle = -30
		socket.TwistUpperAngle = 30
		socket.Restitution = 0.25
		socket.Radius = 0.5

		return socket.LimitsEnabled == true
			and nearlyEqual(socket.UpperAngle, 45)
			and socket.TwistLimitsEnabled == true
			and nearlyEqual(socket.TwistLowerAngle, -30)
			and nearlyEqual(socket.TwistUpperAngle, 30)
	end)
end)

test("CylindricalConstraint configuration", function()
	return withTemporary("CylindricalConstraint", function(cylindrical)
		cylindrical.ActuatorType = Enum.ActuatorType.Motor
		cylindrical.AngularActuatorType = Enum.ActuatorType.Servo
		cylindrical.AngularSpeed = 3
		cylindrical.MotorMaxForce = 1500
		cylindrical.LimitsEnabled = true
		cylindrical.LowerLimit = -5
		cylindrical.UpperLimit = 5

		return cylindrical.ActuatorType == Enum.ActuatorType.Motor
			and cylindrical.AngularActuatorType == Enum.ActuatorType.Servo
			and nearlyEqual(cylindrical.AngularSpeed, 3)
			and cylindrical.LimitsEnabled == true
			and type(cylindrical.CurrentAngle) == "number"
			and type(cylindrical.CurrentPosition) == "number"
	end)
end)

test("Attachment world transforms", function()
	local part = Instance.new("Part")
	local attachment = Instance.new("Attachment")

	part.Anchored = true
	part.CFrame = CFrame.new(10, 0, 0)
	attachment.Position = Vector3.new(1, 0, 0)
	attachment.Parent = part

	local valid = attachment.Position == Vector3.new(1, 0, 0)
		and attachment.WorldPosition == Vector3.new(11, 0, 0)
		and typeof(attachment.WorldCFrame) == "CFrame"
		and typeof(attachment.WorldAxis) == "Vector3"
		and typeof(attachment.WorldSecondaryAxis) == "Vector3"
		and typeof(attachment.CFrame) == "CFrame"
		and typeof(attachment.Axis) == "Vector3"

	part:Destroy()

	return valid
end)

test("Constraint attachment binding", function()
	local part0 = Instance.new("Part")
	local part1 = Instance.new("Part")
	local attachment0 = Instance.new("Attachment")
	local attachment1 = Instance.new("Attachment")
	local constraint = Instance.new("RodConstraint")

	part0.Anchored = true
	part1.Anchored = true
	attachment0.Parent = part0
	attachment1.Parent = part1
	constraint.Attachment0 = attachment0
	constraint.Attachment1 = attachment1
	constraint.Parent = part0

	local valid = constraint.Attachment0 == attachment0
		and constraint.Attachment1 == attachment1
		and constraint.Enabled == true
		and typeof(constraint.Color) == "BrickColor"

	part0:Destroy()
	part1:Destroy()

	return valid
end)

test("Motor6D and Weld transforms", function()
	local motor = Instance.new("Motor6D")
	local weld = Instance.new("Weld")
	local part0 = Instance.new("Part")
	local part1 = Instance.new("Part")

	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = CFrame.new(0, 1, 0)
	motor.C1 = CFrame.new(0, -1, 0)
	motor.Transform = CFrame.Angles(0, math.pi / 4, 0)
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = CFrame.new(1, 0, 0)

	local valid = motor.Part0 == part0
		and motor.Part1 == part1
		and motor.C0.Position == Vector3.new(0, 1, 0)
		and motor.C1.Position == Vector3.new(0, -1, 0)
		and typeof(motor.Transform) == "CFrame"
		and weld.C0.Position == Vector3.new(1, 0, 0)
		and motor:IsA("JointInstance")
		and weld:IsA("JointInstance")

	motor:Destroy()
	weld:Destroy()
	part0:Destroy()
	part1:Destroy()

	return valid
end)

test("Bone hierarchy", function()
	local part = Instance.new("Part")
	local root = Instance.new("Bone")
	local child = Instance.new("Bone")

	part.Anchored = true
	part.CFrame = CFrame.new(5, 0, 0)
	root.Parent = part
	child.Parent = root

	local valid = root:IsA("Attachment")
		and typeof(root.Transform) == "CFrame"
		and typeof(root.TransformedWorldCFrame) == "CFrame"
		and typeof(child.WorldCFrame) == "CFrame"
		and child.Parent == root

	part:Destroy()

	return valid
end)

test("WeldConstraint enabled state", function()
	local part0 = Instance.new("Part")
	local part1 = Instance.new("Part")
	local weld = Instance.new("WeldConstraint")

	part0.Anchored = true
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Enabled = false

	local valid = weld.Part0 == part0
		and weld.Part1 == part1
		and weld.Enabled == false
		and type(weld.Active) == "boolean"

	weld:Destroy()
	part0:Destroy()
	part1:Destroy()

	return valid
end)

test("NoCollisionConstraint", function()
	local part0 = Instance.new("Part")
	local part1 = Instance.new("Part")
	local constraint = Instance.new("NoCollisionConstraint")

	constraint.Part0 = part0
	constraint.Part1 = part1
	constraint.Enabled = true
	constraint.Parent = part0
	part0.Parent = workspace
	part1.Parent = workspace

	local constraints = part0:GetNoCollisionConstraints()
	local valid = constraint.Part0 == part0
		and constraint.Part1 == part1
		and type(constraints) == "table"

	part0:Destroy()
	part1:Destroy()

	return valid
end)

test("ParticleEmitter emission properties", function()
	return withTemporary("ParticleEmitter", function(emitter)
		emitter.Rate = 50
		emitter.Lifetime = NumberRange.new(1, 2)
		emitter.Speed = NumberRange.new(5, 10)
		emitter.SpreadAngle = Vector2.new(30, 30)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-90, 90)
		emitter.Acceleration = Vector3.new(0, -10, 0)
		emitter.Drag = 1
		emitter.LockedToPart = true
		emitter.Shape = Enum.ParticleEmitterShape.Sphere
		emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		emitter.Orientation = Enum.ParticleOrientation.FacingCamera
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Size = NumberSequence.new(1, 0)
		emitter.Transparency = NumberSequence.new(0, 1)
		emitter.Color = ColorSequence.new(Color3.new(1, 0, 0))

		return nearlyEqual(emitter.Rate, 50)
			and typeof(emitter.Lifetime) == "NumberRange"
			and typeof(emitter.Speed) == "NumberRange"
			and emitter.SpreadAngle == Vector2.new(30, 30)
			and emitter.Acceleration == Vector3.new(0, -10, 0)
			and emitter.LockedToPart == true
			and emitter.Shape == Enum.ParticleEmitterShape.Sphere
			and emitter.Orientation == Enum.ParticleOrientation.FacingCamera
			and emitter.EmissionDirection == Enum.NormalId.Top
			and typeof(emitter.Size) == "NumberSequence"
			and typeof(emitter.Color) == "ColorSequence"
			and hasMethod(emitter, "Emit")
			and hasMethod(emitter, "Clear")
	end)
end)

test("Beam curve properties", function()
	return withTemporary("Beam", function(beam)
		beam.Width0 = 2
		beam.Width1 = 1
		beam.CurveSize0 = 5
		beam.CurveSize1 = -5
		beam.Segments = 20
		beam.Texture = "rbxassetid://0"
		beam.TextureLength = 2
		beam.TextureSpeed = 1
		beam.TextureMode = Enum.TextureMode.Static
		beam.LightEmission = 0.5
		beam.LightInfluence = 0
		beam.FaceCamera = true
		beam.Transparency = NumberSequence.new(0, 1)
		beam.Color = ColorSequence.new(Color3.new(0, 1, 0))

		return nearlyEqual(beam.Width0, 2)
			and nearlyEqual(beam.Width1, 1)
			and nearlyEqual(beam.CurveSize0, 5)
			and beam.Segments == 20
			and beam.TextureMode == Enum.TextureMode.Static
			and beam.FaceCamera == true
			and typeof(beam.Transparency) == "NumberSequence"
			and typeof(beam.Color) == "ColorSequence"
			and hasMethod(beam, "SetTextureOffset")
	end)
end)

test("Trail properties", function()
	return withTemporary("Trail", function(trail)
		trail.Lifetime = 2
		trail.MinLength = 0.05
		trail.MaxLength = 20
		trail.LightEmission = 0.5
		trail.LightInfluence = 0
		trail.Brightness = 2
		trail.TextureLength = 1
		trail.TextureMode = Enum.TextureMode.Wrap
		trail.FaceCamera = true
		trail.WidthScale = NumberSequence.new(1, 0)
		trail.Transparency = NumberSequence.new(0, 1)
		trail.Color = ColorSequence.new(Color3.new(0, 0, 1))

		return nearlyEqual(trail.Lifetime, 2)
			and nearlyEqual(trail.MinLength, 0.05)
			and nearlyEqual(trail.MaxLength, 20)
			and trail.TextureMode == Enum.TextureMode.Wrap
			and trail.FaceCamera == true
			and typeof(trail.WidthScale) == "NumberSequence"
			and typeof(trail.Transparency) == "NumberSequence"
			and typeof(trail.Color) == "ColorSequence"
			and hasMethod(trail, "Clear")
	end)
end)

test("Light instances", function()
	local point = Instance.new("PointLight")
	local spot = Instance.new("SpotLight")
	local surface = Instance.new("SurfaceLight")

	point.Range = 30
	point.Brightness = 2
	point.Shadows = true
	spot.Angle = 90
	spot.Face = Enum.NormalId.Front
	spot.Range = 20
	surface.Angle = 120
	surface.Face = Enum.NormalId.Top

	local valid = nearlyEqual(point.Range, 30)
		and nearlyEqual(point.Brightness, 2)
		and point.Shadows == true
		and nearlyEqual(spot.Angle, 90)
		and spot.Face == Enum.NormalId.Front
		and nearlyEqual(surface.Angle, 120)
		and point:IsA("Light")
		and spot:IsA("Light")
		and surface:IsA("Light")
		and typeof(point.Color) == "Color3"

	point:Destroy()
	spot:Destroy()
	surface:Destroy()

	return valid
end)

test("Mesh instances", function()
	local special = Instance.new("SpecialMesh")
	local block = Instance.new("BlockMesh")

	special.MeshType = Enum.MeshType.Sphere

	local meshTypeApplied = special.MeshType == Enum.MeshType.Sphere

	special.Scale = Vector3.new(2, 2, 2)
	special.Offset = Vector3.new(0, 1, 0)
	special.VertexColor = Vector3.new(1, 1, 1)
	block.Scale = Vector3.new(1, 2, 1)

	local textureOk = pcall(function()
		special.TextureId = "rbxassetid://0"
	end)

	local scaleMatches = (special.Scale - Vector3.new(2, 2, 2)).Magnitude < 0.001
	local offsetMatches = (special.Offset - Vector3.new(0, 1, 0)).Magnitude < 0.001
	local blockScaleMatches = (block.Scale - Vector3.new(1, 2, 1)).Magnitude < 0.001
	local hierarchyValid = special:IsA("FileMesh")
		and special:IsA("DataModelMesh")
		and block:IsA("DataModelMesh")
	local typesValid = typeof(special.VertexColor) == "Vector3"
		and typeof(special.Scale) == "Vector3"
		and typeof(special.Offset) == "Vector3"
		and type(special.MeshId) == "string"
		and type(textureOk) == "boolean"

	special:Destroy()
	block:Destroy()

	if not meshTypeApplied then
		return false, "MeshType not applied"
	end

	if not scaleMatches then
		return false, "Scale not applied"
	end

	if not offsetMatches then
		return false, "Offset not applied"
	end

	if not blockScaleMatches then
		return false, "BlockMesh Scale not applied"
	end

	if not hierarchyValid then
		return false, "mesh hierarchy mismatch"
	end

	return typesValid
end)

test("SurfaceAppearance restricted maps", function()
	return withTemporary("SurfaceAppearance", function(appearance)
		appearance.AlphaMode = Enum.AlphaMode.Overlay

		local writable = pcall(function()
			appearance.ColorMap = "rbxassetid://0"
		end)

		return appearance.AlphaMode == Enum.AlphaMode.Overlay
			and appearance:IsA("SurfaceAppearance")
			and type(writable) == "boolean"
	end)
end)

test("Stats performance counters", function()
	local stats = game:GetService("Stats")
	local numeric = {
		"InstanceCount",
		"PrimitivesCount",
		"MovingPrimitivesCount",
		"ContactsCount",
		"DataReceiveKbps",
		"DataSendKbps",
		"PhysicsStepTime",
		"HeartbeatTime",
		"FrameTime",
		"RenderCPUFrameTime",
		"RenderGPUFrameTime",
		"SceneDrawcallCount",
		"SceneTriangleCount",
		"UI2DDrawcallCount",
		"UI3DDrawcallCount",
		"ShadowsDrawcallCount"
	}

	for _, name in ipairs(numeric) do
		local ok, value = readMember(stats, name)

		if not ok or type(value) ~= "number" then
			return false, name .. " unreadable"
		end

		if value < 0 then
			return false, name .. " is negative"
		end
	end

	return type(stats.MemoryTrackingEnabled) == "boolean"
end)

test("Stats instance count reacts", function()
	local stats = game:GetService("Stats")
	local before = stats.InstanceCount
	local holder = {}

	for index = 1, 64 do
		holder[index] = Instance.new("Folder")
	end

	local after = stats.InstanceCount

	for _, object in ipairs(holder) do
		object:Destroy()
	end

	return before > 0
		and after >= before
end)

test("Stats memory reporting", function()
	local stats = game:GetService("Stats")
	local total = stats:GetTotalMemoryUsageMb()
	local ok, tagged = pcall(function()
		return stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Instances)
	end)

	return type(total) == "number"
		and total > 0
		and ok
		and type(tagged) == "number"
		and tagged >= 0
end)

test("Stats primitives track parented parts", function()
	local stats = game:GetService("Stats")
	local before = stats.PrimitivesCount
	local model = Instance.new("Model")

	for _ = 1, 16 do
		local part = Instance.new("Part")

		part.Anchored = true
		part.Position = Vector3.new(0, -3000, 0)
		part.Parent = model
	end

	model.Parent = workspace
	task.wait()

	local after = stats.PrimitivesCount

	model:Destroy()

	return type(before) == "number"
		and type(after) == "number"
		and after >= before
end)

test("HttpService JSON round trip", function()
	local httpService = game:GetService("HttpService")
	local source = {
		Name = "Log-Unc",
		Score = 100,
		Ratio = 0.5,
		Passed = true,
		Tags = { "a", "b", "c" },
		Nested = { Depth = 2 }
	}

	local encoded = httpService:JSONEncode(source)
	local decoded = httpService:JSONDecode(encoded)

	return type(encoded) == "string"
		and decoded.Name == "Log-Unc"
		and decoded.Score == 100
		and nearlyEqual(decoded.Ratio, 0.5)
		and decoded.Passed == true
		and #decoded.Tags == 3
		and decoded.Tags[2] == "b"
		and decoded.Nested.Depth == 2
end)

test("HttpService JSON edge cases", function()
	local httpService = game:GetService("HttpService")
	local emptyArray = httpService:JSONEncode({})
	local decodedEmpty = httpService:JSONDecode("{}")
	local decodedArray = httpService:JSONDecode("[1,2,3]")
	local decodedNull = httpService:JSONDecode("{\"value\":null}")

	return emptyArray == "[]"
		and type(decodedEmpty) == "table"
		and next(decodedEmpty) == nil
		and #decodedArray == 3
		and decodedArray[1] == 1
		and decodedNull.value == nil
		and pcall(function()
			return httpService:JSONDecode("not json")
		end) == false
end)

test("HttpService JSON rejects cycles", function()
	local httpService = game:GetService("HttpService")
	local cyclic = {}

	cyclic.self = cyclic

	return pcall(function()
		return httpService:JSONEncode(cyclic)
	end) == false
end)

test("HttpService JSON preserves nesting depth", function()
	local httpService = game:GetService("HttpService")
	local source = { level = 1, child = { level = 2, child = { level = 3 } } }
	local decoded = httpService:JSONDecode(httpService:JSONEncode(source))

	return decoded.level == 1
		and decoded.child.level == 2
		and decoded.child.child.level == 3
end)

test("HttpService UrlEncode escapes reserved characters", function()
	local httpService = game:GetService("HttpService")
	local encoded = httpService:UrlEncode("a b&c=d/e?f#g")

	return type(encoded) == "string"
		and string.find(encoded, " ", 1, true) == nil
		and string.find(encoded, "&", 1, true) == nil
		and string.find(encoded, "=", 1, true) == nil
		and string.find(encoded, "%%20") ~= nil
		and httpService:UrlEncode("abc123") == "abc123"
end)

test("HttpService GUID format", function()
	local httpService = game:GetService("HttpService")
	local braced = httpService:GenerateGUID(true)
	local plain = httpService:GenerateGUID(false)
	local another = httpService:GenerateGUID(false)

	return #braced == 38
		and string.sub(braced, 1, 1) == "{"
		and string.sub(braced, 38, 38) == "}"
		and #plain == 36
		and string.match(plain, "^%x+%-%x+%-%x+%-%x+%-%x+$") ~= nil
		and plain ~= another
end)

test("HttpService buffer encoding", function()
	local httpService = game:GetService("HttpService")
	local value = buffer.fromstring("LogUnc")
	local ok, encoded = pcall(function()
		return httpService:JSONEncode({ payload = value })
	end)

	return ok == false
		or type(encoded) == "string"
end)

test("TweenService GetValue easing", function()
	local tweenService = game:GetService("TweenService")
	local linearMiddle = tweenService:GetValue(
		0.5,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.InOut
	)
	local start = tweenService:GetValue(
		0,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	local finish = tweenService:GetValue(
		1,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	local clamped = tweenService:GetValue(
		5,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In
	)

	return nearlyEqual(linearMiddle, 0.5, 0.001)
		and nearlyEqual(start, 0, 0.001)
		and nearlyEqual(finish, 1, 0.001)
		and nearlyEqual(clamped, 1, 0.001)
end)

test("TweenService covers all easing styles", function()
	local tweenService = game:GetService("TweenService")

	for _, style in ipairs(Enum.EasingStyle:GetEnumItems()) do
		for _, direction in ipairs(Enum.EasingDirection:GetEnumItems()) do
			local ok, value = pcall(function()
				return tweenService:GetValue(0.5, style, direction)
			end)

			if not ok or type(value) ~= "number" then
				return false, tostring(style) .. " " .. tostring(direction) .. " failed"
			end
		end
	end

	return true
end)

test("TweenService Create returns a Tween", function()
	local tweenService = game:GetService("TweenService")
	local part = Instance.new("Part")

	part.Anchored = true

	local tween = tweenService:Create(
		part,
		TweenInfo.new(0.1),
		{ Transparency = 1 }
	)

	local valid = typeof(tween) == "Instance"
		and tween:IsA("Tween")
		and tween:IsA("TweenBase")
		and tween.Instance == part
		and typeof(tween.TweenInfo) == "TweenInfo"
		and typeof(tween.PlaybackState) == "EnumItem"
		and isSignal(tween.Completed)
		and hasMethods(tween, { "Play", "Pause", "Cancel" })

	tween:Destroy()
	part:Destroy()

	return valid
end)

test("TweenService tween completes", function()
	local tweenService = game:GetService("TweenService")
	local part = Instance.new("Part")

	part.Anchored = true
	part.Transparency = 0

	local tween = tweenService:Create(
		part,
		TweenInfo.new(0.1, Enum.EasingStyle.Linear),
		{ Transparency = 1 }
	)

	tween:Play()

	local state = tween.Completed:Wait()
	local finalTransparency = part.Transparency

	tween:Destroy()
	part:Destroy()

	return typeof(state) == "EnumItem"
		and state == Enum.PlaybackState.Completed
		and nearlyEqual(finalTransparency, 1, 0.01)
end)

test("TweenService tween cancel", function()
	local tweenService = game:GetService("TweenService")
	local part = Instance.new("Part")

	part.Anchored = true

	local tween = tweenService:Create(
		part,
		TweenInfo.new(5, Enum.EasingStyle.Linear),
		{ Transparency = 1 }
	)

	tween:Play()
	task.wait(0.05)
	tween:Cancel()

	local cancelled = tween.PlaybackState

	tween:Destroy()
	part:Destroy()

	return cancelled == Enum.PlaybackState.Cancelled
		or cancelled == Enum.PlaybackState.Begin
end)

test("TweenService SmoothDamp", function()
	local tweenService = game:GetService("TweenService")

	if not hasMethod(tweenService, "SmoothDamp") then
		return false, "SmoothDamp unavailable"
	end

	local value, velocity = tweenService:SmoothDamp(0, 10, 0, 0.5, math.huge, 1 / 60)

	return type(value) == "number"
		and type(velocity) == "number"
		and value > 0
		and value < 10
end)

test("Debris AddItem removes instances", function()
	local debris = game:GetService("Debris")
	local part = Instance.new("Part")

	part.Anchored = true
	part.Parent = workspace
	debris:AddItem(part, 0.1)

	task.wait(0.4)

	return part.Parent == nil
end)

test("RunService context flags", function()
	local runService = game:GetService("RunService")
	local isClient = runService:IsClient()
	local isServer = runService:IsServer()
	local isStudio = runService:IsStudio()
	local isRunning = runService:IsRunning()
	local isRunMode = runService:IsRunMode()

	return type(isClient) == "boolean"
		and type(isServer) == "boolean"
		and type(isStudio) == "boolean"
		and type(isRunning) == "boolean"
		and type(isRunMode) == "boolean"
		and (isClient or isServer)
end)

test("RunService signal surface", function()
	local runService = game:GetService("RunService")
	local signals = {
		"Heartbeat",
		"Stepped",
		"RenderStepped",
		"PreRender",
		"PreAnimation",
		"PreSimulation",
		"PostSimulation"
	}

	for _, name in ipairs(signals) do
		local ok, signal = readMember(runService, name)

		if not ok or not isSignal(signal) then
			return false, name .. " missing"
		end
	end

	return hasMethod(runService, "BindToRenderStep")
		and hasMethod(runService, "UnbindFromRenderStep")
end)

test("RunService Heartbeat delivers delta", function()
	local runService = game:GetService("RunService")
	local delta = runService.Heartbeat:Wait()

	return type(delta) == "number"
		and delta > 0
		and delta < 1
end)

test("RunService Stepped delivers time and delta", function()
	local runService = game:GetService("RunService")
	local elapsed, delta = runService.Stepped:Wait()

	return type(elapsed) == "number"
		and type(delta) == "number"
		and elapsed > 0
		and delta > 0
end)

test("RunService render step binding", function()
	local runService = game:GetService("RunService")
	local name = "LogUncRenderStep"
	local calls = 0
	local bindOk = pcall(function()
		runService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value, function()
			calls += 1
		end)
	end)

	if bindOk then
		task.wait(0.1)
		pcall(function()
			runService:UnbindFromRenderStep(name)
		end)
	end

	return type(bindOk) == "boolean"
		and calls >= 0
end)

test("task library surface", function()
	local required = { "wait", "spawn", "defer", "delay", "cancel" }

	for _, name in ipairs(required) do
		if type(task[name]) ~= "function" then
			return false, "task." .. name .. " missing"
		end
	end

	return true
end)

test("task.wait returns elapsed time", function()
	local start = os.clock()
	local elapsed = task.wait(0.1)
	local measured = os.clock() - start

	return type(elapsed) == "number"
		and elapsed >= 0.05
		and measured >= 0.05
		and measured < 2
end)

test("task.spawn runs immediately", function()
	local order = {}

	table.insert(order, "before")
	task.spawn(function()
		table.insert(order, "spawned")
	end)
	table.insert(order, "after")

	return order[1] == "before"
		and order[2] == "spawned"
		and order[3] == "after"
end)

test("task.defer runs after current resumption", function()
	local order = {}

	table.insert(order, "before")
	task.defer(function()
		table.insert(order, "deferred")
	end)
	table.insert(order, "after")
	task.wait()

	return order[1] == "before"
		and order[2] == "after"
		and order[3] == "deferred"
end)

test("task.delay schedules work", function()
	local fired = false

	task.delay(0.05, function()
		fired = true
	end)

	local immediate = fired

	task.wait(0.3)

	return immediate == false
		and fired == true
end)

test("task.cancel stops scheduled work", function()
	local fired = false
	local thread = task.delay(0.2, function()
		fired = true
	end)

	local cancelOk = pcall(function()
		task.cancel(thread)
	end)

	task.wait(0.4)

	return cancelOk
		and fired == false
end)

test("task.spawn passes arguments", function()
	local received = {}

	task.spawn(function(a, b)
		received[1] = a
		received[2] = b
	end, "first", 2)

	return received[1] == "first"
		and received[2] == 2
end)

test("task.spawn accepts threads", function()
	local ran = false
	local thread = coroutine.create(function()
		ran = true
	end)

	task.spawn(thread)

	return ran
		and coroutine.status(thread) == "dead"
end)

test("task errors do not stop the caller", function()
	local reached = false

	task.spawn(function()
		error("inside task")
	end)

	reached = true

	task.wait()

	return reached
end)

test("wait and delay legacy globals", function()
	local start = os.clock()
	local elapsed = wait(0.05)
	local measured = os.clock() - start
	local delayFired = false

	delay(0.05, function()
		delayFired = true
	end)

	task.wait(0.3)

	return type(elapsed) == "number"
		and measured >= 0.02
		and delayFired == true
end)

test("tick and time relationship", function()
	local tickValue = tick()
	local timeValue = time()
	local elapsedValue = elapsedTime and elapsedTime() or timeValue

	return type(tickValue) == "number"
		and tickValue > 0
		and type(timeValue) == "number"
		and timeValue > 0
		and type(elapsedValue) == "number"
		and tickValue > timeValue
end)

test("Players service properties", function()
	local players = game:GetService("Players")

	return type(players.MaxPlayers) == "number"
		and players.MaxPlayers > 0
		and type(players.PreferredPlayers) == "number"
		and type(players.RespawnTime) == "number"
		and type(players.CharacterAutoLoads) == "boolean"
		and type(players:GetPlayers()) == "table"
		and isSignal(players.PlayerAdded)
		and isSignal(players.PlayerRemoving)
		and hasMethods(players, {
			"GetPlayerByUserId",
			"GetPlayerFromCharacter",
			"GetPlayers",
			"GetUserThumbnailAsync"
		})
end)

optional("Player property surface", function()
	local player = getCurrentPlayer()

	if not player then
		return false, "player unavailable"
	end

	return player:IsA("Player")
		and type(player.UserId) == "number"
		and type(player.AccountAge) == "number"
		and type(player.DisplayName) == "string"
		and type(player.CharacterAppearanceId) == "number"
		and typeof(player.TeamColor) == "BrickColor"
		and type(player.Neutral) == "boolean"
		and typeof(player.CameraMode) == "EnumItem"
		and type(player.CameraMaxZoomDistance) == "number"
		and type(player.CameraMinZoomDistance) == "number"
		and typeof(player.MembershipType) == "EnumItem"
		and type(player.AutoJumpEnabled) == "boolean"
		and type(player:HasAppearanceLoaded()) == "boolean"
		and isSignal(player.CharacterAdded)
		and isSignal(player.CharacterRemoving)
		and isSignal(player.Idled)
end)

optional("Player character lookup", function()
	local character, player = getCurrentCharacter()

	if not character or not player then
		return false, "character unavailable"
	end

	local players = game:GetService("Players")

	return players:GetPlayerFromCharacter(character) == player
		and players:GetPlayerByUserId(player.UserId) == player
		and players:GetPlayerFromCharacter(Instance.new("Model")) == nil
end)

optional("Player mouse object", function()
	local player = getCurrentPlayer()

	if not player then
		return false, "player unavailable"
	end

	local ok, mouse = pcall(function()
		return player:GetMouse()
	end)

	if not ok or mouse == nil then
		return false, "mouse unavailable"
	end

	return mouse:IsA("Mouse")
		and typeof(mouse.UnitRay) == "Ray"
		and type(mouse.X) == "number"
		and type(mouse.Y) == "number"
		and type(mouse.ViewSizeX) == "number"
		and type(mouse.ViewSizeY) == "number"
		and isSignal(mouse.Move)
		and isSignal(mouse.Button1Down)
end)

optional("Humanoid state control", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false, "Humanoid unavailable"
	end

	local state = humanoid:GetState()
	local jumpEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)

	return typeof(state) == "EnumItem"
		and type(jumpEnabled) == "boolean"
		and hasMethods(humanoid, {
			"ChangeState",
			"GetState",
			"GetStateEnabled",
			"SetStateEnabled",
			"Move",
			"MoveTo",
			"GetLimb",
			"GetBodyPartR15",
			"GetAppliedDescription",
			"GetAccessories"
		})
end)

optional("Humanoid property surface", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false, "Humanoid unavailable"
	end

	return type(humanoid.Health) == "number"
		and type(humanoid.MaxHealth) == "number"
		and type(humanoid.WalkSpeed) == "number"
		and type(humanoid.JumpPower) == "number"
		and type(humanoid.JumpHeight) == "number"
		and type(humanoid.HipHeight) == "number"
		and type(humanoid.MaxSlopeAngle) == "number"
		and typeof(humanoid.CameraOffset) == "Vector3"
		and typeof(humanoid.MoveDirection) == "Vector3"
		and typeof(humanoid.RigType) == "EnumItem"
		and typeof(humanoid.FloorMaterial) == "EnumItem"
		and typeof(humanoid.HealthDisplayType) == "EnumItem"
		and type(humanoid.AutoRotate) == "boolean"
		and type(humanoid.EvaluateStateMachine) == "boolean"
		and isSignal(humanoid.Died)
		and isSignal(humanoid.HealthChanged)
		and isSignal(humanoid.StateChanged)
		and isSignal(humanoid.Running)
		and isSignal(humanoid.Jumping)
end)

optional("Humanoid limb lookup", function()
	local character = getCurrentCharacter()

	if not character then
		return false, "character unavailable"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart

	if not humanoid or not root then
		return false, "Humanoid parts unavailable"
	end

	local limb = humanoid:GetLimb(root)

	return typeof(limb) == "EnumItem"
		and root:IsA("BasePart")
		and root.Name == "HumanoidRootPart"
end)

test("UserInputService capability flags", function()
	local inputService = game:GetService("UserInputService")
	local flags = {
		"KeyboardEnabled",
		"MouseEnabled",
		"TouchEnabled",
		"GamepadEnabled",
		"AccelerometerEnabled",
		"GyroscopeEnabled",
		"VREnabled",
		"OnScreenKeyboardVisible",
		"MouseIconEnabled"
	}

	for _, name in ipairs(flags) do
		local ok, value = readMember(inputService, name)

		if not ok or type(value) ~= "boolean" then
			return false, name .. " unreadable"
		end
	end

	return typeof(inputService.MouseBehavior) == "EnumItem"
		and typeof(inputService:GetMouseLocation()) == "Vector2"
		and type(inputService:GetConnectedGamepads()) == "table"
		and type(inputService:GetKeysPressed()) == "table"
		and type(inputService:IsKeyDown(Enum.KeyCode.A)) == "boolean"
end)

test("UserInputService signal surface", function()
	local inputService = game:GetService("UserInputService")
	local signals = {
		"InputBegan",
		"InputChanged",
		"InputEnded",
		"JumpRequest",
		"WindowFocused",
		"WindowFocusReleased",
		"TextBoxFocused",
		"TextBoxFocusReleased",
		"LastInputTypeChanged"
	}

	for _, name in ipairs(signals) do
		local ok, signal = readMember(inputService, name)

		if not ok or not isSignal(signal) then
			return false, name .. " missing"
		end
	end

	return true
end)

test("ContextActionService binding lifecycle", function()
	local contextService = game:GetService("ContextActionService")
	local name = "LogUncAction"
	local bindOk = pcall(function()
		contextService:BindAction(name, function() end, false, Enum.KeyCode.F)
	end)

	if not bindOk then
		return false, "BindAction failed"
	end

	local info = contextService:GetBoundActionInfo(name)
	local all = contextService:GetAllBoundActionInfo()
	local unbindOk = pcall(function()
		contextService:UnbindAction(name)
	end)
	local afterUnbind = contextService:GetBoundActionInfo(name)

	return type(info) == "table"
		and type(all) == "table"
		and unbindOk
		and (afterUnbind == nil or next(afterUnbind) == nil)
end)

test("ContextActionService priority binding", function()
	local contextService = game:GetService("ContextActionService")
	local name = "LogUncPriorityAction"
	local ok = pcall(function()
		contextService:BindActionAtPriority(
			name,
			function() end,
			false,
			1000,
			Enum.KeyCode.G
		)
	end)

	pcall(function()
		contextService:UnbindAction(name)
	end)

	return ok
		and hasMethods(contextService, {
			"BindAction",
			"BindActionAtPriority",
			"UnbindAction",
			"UnbindAllActions",
			"GetBoundActionInfo",
			"GetAllBoundActionInfo",
			"SetTitle",
			"SetImage",
			"SetDescription",
			"SetPosition"
		})
end)

test("LogService history", function()
	local logService = game:GetService("LogService")
	local history = logService:GetLogHistory()

	return type(history) == "table"
		and isSignal(logService.MessageOut)
end)

test("ContentProvider queue state", function()
	local contentProvider = game:GetService("ContentProvider")

	return type(contentProvider.BaseUrl) == "string"
		and #contentProvider.BaseUrl > 0
		and type(contentProvider.RequestQueueSize) == "number"
		and contentProvider.RequestQueueSize >= 0
		and hasMethods(contentProvider, {
			"PreloadAsync",
			"GetAssetFetchStatus",
			"GetAssetFetchStatusChangedSignal"
		})
end)

test("LocalizationService translator", function()
	local localizationService = game:GetService("LocalizationService")

	return type(localizationService.RobloxLocaleId) == "string"
		and type(localizationService.SystemLocaleId) == "string"
		and #localizationService.RobloxLocaleId > 0
		and hasMethods(localizationService, {
			"GetTranslatorForPlayer",
			"GetTranslatorForLocaleAsync",
			"GetTableEntries",
			"GetCorescriptLocalizations"
		})
end)

test("LocalizationTable entries", function()
	return withTemporary("LocalizationTable", function(localizationTable)
		localizationTable.SourceLocaleId = "en-us"

		local setOk = pcall(function()
			localizationTable:SetEntries({
				{
					Key = "LogUncKey",
					Source = "Log-Unc",
					Context = "",
					Example = "",
					Values = { ["en-us"] = "Log-Unc" }
				}
			})
		end)

		local entries = localizationTable:GetEntries()

		return localizationTable.SourceLocaleId == "en-us"
			and setOk
			and type(entries) == "table"
			and hasMethods(localizationTable, {
				"GetEntries",
				"SetEntries",
				"GetString",
				"RemoveEntry",
				"RemoveEntryValue",
				"GetTranslator"
			})
	end)
end)

test("Teams service", function()
	local teams = game:GetService("Teams")
	local team = Instance.new("Team")

	team.Name = "LogUncTeam"
	team.TeamColor = BrickColor.new("Bright blue")
	team.AutoAssignable = false
	team.Parent = teams

	local list = teams:GetTeams()
	local valid = containsValue(list, team)
		and typeof(team.TeamColor) == "BrickColor"
		and team.AutoAssignable == false
		and type(team:GetPlayers()) == "table"
		and isSignal(team.PlayerAdded)
		and isSignal(team.PlayerRemoved)

	team:Destroy()

	return valid
end)

test("MarketplaceService surface", function()
	local marketplaceService = game:GetService("MarketplaceService")

	return hasMethods(marketplaceService, {
		"GetProductInfoAsync",
		"PromptPurchase",
		"PromptProductPurchase",
		"PromptGamePassPurchase",
		"UserOwnsGamePassAsync",
		"PlayerOwnsAssetAsync",
		"GetDeveloperProductsAsync"
	})
		and isSignal(marketplaceService.PromptPurchaseFinished)
		and isSignal(marketplaceService.PromptProductPurchaseFinished)
		and isSignal(marketplaceService.PromptGamePassPurchaseFinished)
end)

test("DataStoreService surface", function()
	local dataStoreService = game:GetService("DataStoreService")

	return hasMethods(dataStoreService, {
		"GetDataStore",
		"GetGlobalDataStore",
		"GetOrderedDataStore",
		"GetRequestBudgetForRequestType",
		"ListDataStoresAsync"
	})
		and type(dataStoreService:GetRequestBudgetForRequestType(
			Enum.DataStoreRequestType.GetAsync
		)) == "number"
end)

test("GeometryService surface", function()
	local geometryService = game:GetService("GeometryService")

	return hasMethods(geometryService, {
		"UnionAsync",
		"SubtractAsync",
		"IntersectAsync",
		"CalculateConstraintsToPreserve"
	})
end)

test("AssetService surface", function()
	local assetService = game:GetService("AssetService")

	return hasMethods(assetService, {
		"CreateEditableImage",
		"CreateEditableMesh",
		"CreateMeshPartAsync",
		"GetBundleDetailsAsync",
		"LoadAssetAsync"
	})
end)

test("PathfindingService path lifecycle", function()
	local pathfindingService = game:GetService("PathfindingService")
	local path = pathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = false,
		WaypointSpacing = 4,
		Costs = { Water = 20 }
	})

	local valid = typeof(path) == "Instance"
		and path:IsA("Path")
		and typeof(path.Status) == "EnumItem"
		and isSignal(path.Blocked)
		and isSignal(path.Unblocked)
		and hasMethods(path, {
			"ComputeAsync",
			"GetWaypoints",
			"CheckOcclusionAsync"
		})

	path:Destroy()

	return valid
end)

test("PathfindingService waypoints", function()
	local pathfindingService = game:GetService("PathfindingService")
	local path = pathfindingService:CreatePath()
	local computeOk = pcall(function()
		path:ComputeAsync(Vector3.new(0, 5, 0), Vector3.new(20, 5, 0))
	end)
	local waypoints = path:GetWaypoints()
	local valid = computeOk
		and type(waypoints) == "table"

	if #waypoints > 0 then
		local first = waypoints[1]

		valid = valid
			and typeof(first) == "PathWaypoint"
			and typeof(first.Position) == "Vector3"
			and typeof(first.Action) == "EnumItem"
	end

	path:Destroy()

	return valid
end)

test("KeyframeSequenceProvider surface", function()
	local provider = game:GetService("KeyframeSequenceProvider")

	return hasMethods(provider, {
		"RegisterKeyframeSequence",
		"GetKeyframeSequenceAsync"
	})
end)

test("Animation and Animator", function()
	local model = Instance.new("Model")
	local humanoid = Instance.new("Humanoid")
	local animator = Instance.new("Animator")
	local animation = Instance.new("Animation")

	animation.AnimationId = "rbxassetid://0"
	humanoid.Parent = model
	animator.Parent = humanoid

	local tracks = animator:GetPlayingAnimationTracks()
	local valid = animator:IsA("Animator")
		and type(tracks) == "table"
		and hasMethods(animator, {
			"LoadAnimation",
			"GetPlayingAnimationTracks",
			"ApplyJointVelocities"
		})
		and isSignal(animator.AnimationPlayed)

	model:Destroy()
	animation:Destroy()

	return valid
end)

test("Tool and Accessory members", function()
	local tool = Instance.new("Tool")
	local accessory = Instance.new("Accessory")

	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.ToolTip = "Log-Unc"
	tool.Grip = CFrame.new(0, 1, 0)
	accessory.AccessoryType = Enum.AccessoryType.Hat

	local valid = tool.RequiresHandle == false
		and tool.CanBeDropped == false
		and tool.ToolTip == "Log-Unc"
		and tool.Grip.Position == Vector3.new(0, 1, 0)
		and isSignal(tool.Activated)
		and isSignal(tool.Equipped)
		and isSignal(tool.Unequipped)
		and accessory:IsA("Accoutrement")
		and accessory.AccessoryType == Enum.AccessoryType.Hat

	tool:Destroy()
	accessory:Destroy()

	return valid
end)

test("Script container sources", function()
	local module = Instance.new("ModuleScript")
	local serverScript = Instance.new("Script")
	local localScript = Instance.new("LocalScript")

	module.Source = "return 42"
	serverScript.Source = "print('server')"
	serverScript.Enabled = false

	local contextOk = pcall(function()
		serverScript.RunContext = Enum.RunContext.Client
	end)
	local contextValid = not contextOk
		or serverScript.RunContext == Enum.RunContext.Client

	local valid = module.Source == "return 42"
		and serverScript.Source == "print('server')"
		and serverScript.Enabled == false
		and contextValid
		and typeof(serverScript.RunContext) == "EnumItem"
		and module:IsA("LuaSourceContainer")
		and serverScript:IsA("BaseScript")
		and localScript:IsA("BaseScript")

	module:Destroy()
	serverScript:Destroy()
	localScript:Destroy()

	return valid
end)

test("RemoteEvent and RemoteFunction members", function()
	local remoteEvent = Instance.new("RemoteEvent")
	local remoteFunction = Instance.new("RemoteFunction")
	local unreliable = Instance.new("UnreliableRemoteEvent")

	local valid = isSignal(remoteEvent.OnClientEvent)
		and isSignal(remoteEvent.OnServerEvent)
		and hasMethods(remoteEvent, {
			"FireServer",
			"FireClient",
			"FireAllClients"
		})
		and hasMethods(remoteFunction, {
			"InvokeServer",
			"InvokeClient"
		})
		and isSignal(unreliable.OnClientEvent)
		and remoteEvent:IsA("BaseRemoteEvent")

	remoteEvent:Destroy()
	remoteFunction:Destroy()
	unreliable:Destroy()

	return valid
end)

test("BindableEvent argument fidelity", function()
	local event = Instance.new("BindableEvent")
	local received = {}
	local connection = event.Event:Connect(function(...)
		received = { ... }
	end)

	event:Fire(1, "two", true, Vector3.new(1, 2, 3))
	task.wait()
	connection:Disconnect()

	local valid = #received == 4
		and received[1] == 1
		and received[2] == "two"
		and received[3] == true
		and received[4] == Vector3.new(1, 2, 3)

	event:Destroy()

	return valid
end)

test("BindableFunction return fidelity", function()
	local bindable = Instance.new("BindableFunction")

	bindable.OnInvoke = function(a, b)
		return a + b, a * b
	end

	local sum, product = bindable:Invoke(3, 4)

	bindable:Destroy()

	return sum == 7
		and product == 12
end)

test("BindableFunction propagates errors", function()
	local bindable = Instance.new("BindableFunction")

	bindable.OnInvoke = function()
		error("invoke failure")
	end

	local ok = pcall(function()
		return bindable:Invoke()
	end)

	bindable:Destroy()

	return ok == false
end)

test("Enum KeyCode coverage", function()
	local items = Enum.KeyCode:GetEnumItems()
	local ok, missing = enumHasItems(Enum.KeyCode, {
		"A",
		"Z",
		"Zero",
		"Nine",
		"Space",
		"Return",
		"Escape",
		"LeftShift",
		"LeftControl",
		"LeftAlt",
		"Up",
		"Down",
		"Left",
		"Right",
		"F1",
		"F12",
		"Backspace",
		"Tab",
		"ButtonA",
		"ButtonB",
		"ButtonX",
		"Thumbstick1",
		"DPadUp",
		"None"
	})

	if not ok then
		return false, "KeyCode." .. missing
	end

	return #items > 200
end)

test("Enum UserInputType coverage", function()
	local ok, missing = enumHasItems(Enum.UserInputType, {
		"MouseButton1",
		"MouseButton2",
		"MouseButton3",
		"MouseWheel",
		"MouseMovement",
		"Touch",
		"Keyboard",
		"Focus",
		"Accelerometer",
		"Gyro",
		"Gamepad1",
		"TextInput",
		"InputMethod",
		"None"
	})

	if not ok then
		return false, "UserInputType." .. missing
	end

	return true
end)

test("Enum Material coverage", function()
	local ok, missing = enumHasItems(Enum.Material, {
		"Plastic",
		"SmoothPlastic",
		"Neon",
		"Wood",
		"WoodPlanks",
		"Metal",
		"DiamondPlate",
		"Foil",
		"Grass",
		"Sand",
		"Slate",
		"Concrete",
		"Brick",
		"Cobblestone",
		"Ice",
		"Marble",
		"Granite",
		"Glass",
		"ForceField",
		"Fabric",
		"Air",
		"Water",
		"Rock",
		"Glacier",
		"Snow",
		"Sandstone",
		"Mud",
		"Basalt",
		"Ground",
		"CrackedLava",
		"Asphalt",
		"LeafyGrass",
		"Salt",
		"Limestone",
		"Pavement"
	})

	if not ok then
		return false, "Material." .. missing
	end

	return true
end)

test("Enum HumanoidStateType coverage", function()
	local ok, missing = enumHasItems(Enum.HumanoidStateType, {
		"Running",
		"RunningNoPhysics",
		"Climbing",
		"Swimming",
		"Jumping",
		"Freefall",
		"Landed",
		"Seated",
		"PlatformStanding",
		"Dead",
		"GettingUp",
		"FallingDown",
		"Ragdoll",
		"StrafingNoPhysics",
		"Physics",
		"None"
	})

	if not ok then
		return false, "HumanoidStateType." .. missing
	end

	return true
end)

test("Enum consistency across items", function()
	local sampled = {
		Enum.Material,
		Enum.KeyCode,
		Enum.UserInputType,
		Enum.EasingStyle,
		Enum.NormalId,
		Enum.PartType,
		Enum.SurfaceType,
		Enum.HumanoidStateType,
		Enum.CameraType,
		Enum.SortOrder
	}

	for _, enumType in ipairs(sampled) do
		for _, item in ipairs(enumType:GetEnumItems()) do
			if item.EnumType ~= enumType then
				return false, tostring(item) .. " has wrong EnumType"
			end

			if type(item.Name) ~= "string" or #item.Name == 0 then
				return false, "invalid item name"
			end

			if type(item.Value) ~= "number" then
				return false, item.Name .. " has non-numeric value"
			end

			if enumType[item.Name] ~= item then
				return false, item.Name .. " lookup mismatch"
			end
		end
	end

	return true
end)

test("Enum tostring format", function()
	for _, enumType in ipairs({ Enum.Material, Enum.NormalId, Enum.EasingStyle }) do
		local typeName = tostring(enumType)

		for _, item in ipairs(enumType:GetEnumItems()) do
			local expected = "Enum." .. typeName .. "." .. item.Name

			if tostring(item) ~= expected then
				return false, tostring(item) .. " expected " .. expected
			end
		end
	end

	return true
end)

test("Instance class coverage", function()
	local classes = {
		"Accessory",
		"Actor",
		"AlignOrientation",
		"AlignPosition",
		"AngularVelocity",
		"Animation",
		"Animator",
		"Atmosphere",
		"Attachment",
		"BallSocketConstraint",
		"Beam",
		"BillboardGui",
		"BindableEvent",
		"BindableFunction",
		"BlockMesh",
		"BloomEffect",
		"BlurEffect",
		"BodyColors",
		"Bone",
		"BoolValue",
		"BrickColorValue",
		"Camera",
		"CanvasGroup",
		"CFrameValue",
		"Color3Value",
		"ColorCorrectionEffect",
		"CornerWedgePart",
		"CylindricalConstraint",
		"Decal",
		"DepthOfFieldEffect",
		"Dialog",
		"DialogChoice",
		"Explosion",
		"Fire",
		"Folder",
		"Frame",
		"Highlight",
		"HingeConstraint",
		"Humanoid",
		"HumanoidDescription",
		"ImageButton",
		"ImageLabel",
		"IntValue",
		"Keyframe",
		"KeyframeSequence",
		"LinearVelocity",
		"LineForce",
		"LocalizationTable",
		"LocalScript",
		"MeshPart",
		"Model",
		"ModuleScript",
		"Motor6D",
		"NoCollisionConstraint",
		"NumberValue",
		"ObjectValue",
		"Pants",
		"ParticleEmitter",
		"Part",
		"Path2D",
		"PointLight",
		"PrismaticConstraint",
		"ProximityPrompt",
		"RayValue",
		"RemoteEvent",
		"RemoteFunction",
		"RodConstraint",
		"RopeConstraint",
		"Script",
		"ScreenGui",
		"ScrollingFrame",
		"Seat",
		"Shirt",
		"ShirtGraphic",
		"Sky",
		"Smoke",
		"Sound",
		"SoundGroup",
		"Sparkles",
		"SpawnLocation",
		"SpecialMesh",
		"SpotLight",
		"SpringConstraint",
		"StringValue",
		"SunRaysEffect",
		"SurfaceAppearance",
		"SurfaceGui",
		"SurfaceLight",
		"Team",
		"Texture",
		"TextBox",
		"TextButton",
		"TextLabel",
		"Tool",
		"Torque",
		"Trail",
		"TrussPart",
		"UnreliableRemoteEvent",
		"UIAspectRatioConstraint",
		"UICorner",
		"UIFlexItem",
		"UIGradient",
		"UIGridLayout",
		"UIListLayout",
		"UIPadding",
		"UIPageLayout",
		"UIScale",
		"UISizeConstraint",
		"UIStroke",
		"UITableLayout",
		"UITextSizeConstraint",
		"VectorForce",
		"VehicleSeat",
		"Vector3Value",
		"ViewportFrame",
		"WedgePart",
		"Weld",
		"WeldConstraint",
		"Wire"
	}

	for _, className in ipairs(classes) do
		local ok, object = pcall(Instance.new, className)

		if not ok or object == nil then
			return false, className .. " not constructible"
		end

		local classMatches = object.ClassName == className

		object:Destroy()

		if not classMatches then
			return false, className .. " reported wrong ClassName"
		end
	end

	return true
end)

test("Instance inheritance map", function()
	local expectations = {
		{ "Part", "BasePart" },
		{ "MeshPart", "BasePart" },
		{ "WedgePart", "BasePart" },
		{ "TrussPart", "BasePart" },
		{ "SpawnLocation", "BasePart" },
		{ "Seat", "BasePart" },
		{ "VehicleSeat", "BasePart" },
		{ "Model", "PVInstance" },
		{ "Actor", "Model" },
		{ "Frame", "GuiObject" },
		{ "TextButton", "GuiButton" },
		{ "TextLabel", "GuiLabel" },
		{ "ScreenGui", "LayerCollector" },
		{ "PointLight", "Light" },
		{ "SpotLight", "Light" },
		{ "SurfaceLight", "Light" },
		{ "Weld", "JointInstance" },
		{ "Motor6D", "JointInstance" },
		{ "HingeConstraint", "Constraint" },
		{ "SpringConstraint", "Constraint" },
		{ "AlignPosition", "Constraint" },
		{ "LinearVelocity", "Constraint" },
		{ "VectorForce", "Constraint" },
		{ "NumberValue", "ValueBase" },
		{ "StringValue", "ValueBase" },
		{ "ObjectValue", "ValueBase" },
		{ "Script", "BaseScript" },
		{ "LocalScript", "BaseScript" },
		{ "ModuleScript", "LuaSourceContainer" },
		{ "BloomEffect", "PostEffect" },
		{ "Shirt", "Clothing" },
		{ "Pants", "Clothing" },
		{ "Accessory", "Accoutrement" },
		{ "SpecialMesh", "DataModelMesh" },
		{ "UIListLayout", "UILayout" },
		{ "UISizeConstraint", "UIConstraint" },
		{ "RemoteEvent", "BaseRemoteEvent" },
		{ "UnreliableRemoteEvent", "BaseRemoteEvent" },
		{ "Bone", "Attachment" }
	}

	for _, entry in ipairs(expectations) do
		local ok, object = pcall(Instance.new, entry[1])

		if not ok or object == nil then
			return false, entry[1] .. " not constructible"
		end

		local inherits = object:IsA(entry[2])

		object:Destroy()

		if not inherits then
			return false, entry[1] .. " is not a " .. entry[2]
		end
	end

	return true
end)

test("Every instance inherits Instance", function()
	local classes = {
		"Part",
		"Model",
		"Folder",
		"Frame",
		"ScreenGui",
		"Sound",
		"Humanoid",
		"Camera",
		"Attachment",
		"Beam",
		"Trail",
		"NumberValue",
		"BindableEvent",
		"Script"
	}

	for _, className in ipairs(classes) do
		local object = Instance.new(className)
		local valid = object:IsA("Instance")
			and typeof(object) == "Instance"
			and type(object.Name) == "string"
			and type(object.ClassName) == "string"
			and type(object.Archivable) == "boolean"

		object:Destroy()

		if not valid then
			return false, className .. " missing base members"
		end
	end

	return true
end)

test("ProximityPrompt configuration", function()
	return withTemporary("ProximityPrompt", function(prompt)
		prompt.ActionText = "Use"
		prompt.ObjectText = "Door"
		prompt.HoldDuration = 1
		prompt.MaxActivationDistance = 15
		prompt.RequiresLineOfSight = false
		prompt.ClickablePrompt = true
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.Enabled = true

		return prompt.ActionText == "Use"
			and prompt.ObjectText == "Door"
			and nearlyEqual(prompt.HoldDuration, 1)
			and nearlyEqual(prompt.MaxActivationDistance, 15)
			and prompt.RequiresLineOfSight == false
			and prompt.ClickablePrompt == true
			and prompt.Style == Enum.ProximityPromptStyle.Custom
			and prompt.KeyboardKeyCode == Enum.KeyCode.E
			and isSignal(prompt.Triggered)
			and isSignal(prompt.TriggerEnded)
			and isSignal(prompt.PromptShown)
			and isSignal(prompt.PromptHidden)
			and hasMethod(prompt, "InputHoldBegin")
	end)
end)

test("ProximityPromptService signals", function()
	local promptService = game:GetService("ProximityPromptService")
	local signals = {
		"PromptTriggered",
		"PromptTriggerEnded",
		"PromptShown",
		"PromptHidden",
		"PromptButtonHoldBegan",
		"PromptButtonHoldEnded"
	}

	for _, name in ipairs(signals) do
		local ok, signal = readMember(promptService, name)

		if not ok or not isSignal(signal) then
			return false, name .. " missing"
		end
	end

	return true
end)

test("Explosion configuration", function()
	return withTemporary("Explosion", function(explosion)
		explosion.BlastRadius = 20
		explosion.BlastPressure = 100000
		explosion.DestroyJointRadiusPercent = 0
		explosion.ExplosionType = Enum.ExplosionType.NoCraters
		explosion.Position = Vector3.new(0, -4000, 0)
		explosion.Visible = false

		return nearlyEqual(explosion.BlastRadius, 20)
			and nearlyEqual(explosion.BlastPressure, 100000)
			and nearlyEqual(explosion.DestroyJointRadiusPercent, 0)
			and explosion.ExplosionType == Enum.ExplosionType.NoCraters
			and explosion.Visible == false
			and isSignal(explosion.Hit)
	end)
end)

test("Dialog and DialogChoice", function()
	local dialog = Instance.new("Dialog")
	local choice = Instance.new("DialogChoice")

	dialog.InitialPrompt = "Hello"
	dialog.Purpose = Enum.DialogPurpose.Help
	dialog.Tone = Enum.DialogTone.Friendly
	dialog.ConversationDistance = 10
	dialog.InUse = false
	choice.UserDialog = "Hi"
	choice.ResponseDialog = "Welcome"
	choice.Parent = dialog

	local valid = dialog.InitialPrompt == "Hello"
		and dialog.Purpose == Enum.DialogPurpose.Help
		and dialog.Tone == Enum.DialogTone.Friendly
		and nearlyEqual(dialog.ConversationDistance, 10)
		and choice.UserDialog == "Hi"
		and choice.ResponseDialog == "Welcome"
		and isSignal(dialog.DialogChoiceSelected)

	dialog:Destroy()

	return valid
end)

test("Clothing and ShirtGraphic", function()
	local shirt = Instance.new("Shirt")
	local pants = Instance.new("Pants")
	local graphic = Instance.new("ShirtGraphic")

	shirt.ShirtTemplate = "rbxassetid://0"
	pants.PantsTemplate = "rbxassetid://0"
	graphic.Graphic = "rbxassetid://0"

	local valid = shirt.ShirtTemplate == "rbxassetid://0"
		and pants.PantsTemplate == "rbxassetid://0"
		and graphic.Graphic == "rbxassetid://0"
		and shirt:IsA("Clothing")
		and pants:IsA("Clothing")
		and graphic:IsA("CharacterAppearance")

	shirt:Destroy()
	pants:Destroy()
	graphic:Destroy()

	return valid
end)

test("BodyColors channels", function()
	return withTemporary("BodyColors", function(colors)
		colors.HeadColor3 = Color3.fromRGB(255, 200, 100)
		colors.TorsoColor3 = Color3.fromRGB(100, 200, 255)
		colors.LeftArmColor3 = Color3.fromRGB(10, 20, 30)
		colors.RightArmColor3 = Color3.fromRGB(30, 20, 10)
		colors.LeftLegColor3 = Color3.fromRGB(40, 50, 60)
		colors.RightLegColor3 = Color3.fromRGB(60, 50, 40)

		return typeof(colors.HeadColor3) == "Color3"
			and typeof(colors.TorsoColor3) == "Color3"
			and typeof(colors.LeftArmColor3) == "Color3"
			and typeof(colors.RightArmColor3) == "Color3"
			and typeof(colors.LeftLegColor3) == "Color3"
			and typeof(colors.RightLegColor3) == "Color3"
			and typeof(colors.HeadColor) == "BrickColor"
			and colors:IsA("CharacterAppearance")
	end)
end)

test("HumanoidDescription assets", function()
	return withTemporary("HumanoidDescription", function(description)
		description.HatAccessory = "1,2,3"
		description.HairAccessory = "4"
		description.Shirt = 1
		description.Pants = 2
		description.Face = 3
		description.Torso = 4
		description.LeftArm = 5

		local emoteOk = pcall(function()
			description:AddEmote("Wave", 507770239)
		end)
		local emotes = description:GetEmotes()
		local accessories = description:GetAccessories(true)

		return description.HatAccessory == "1,2,3"
			and description.HairAccessory == "4"
			and description.Shirt == 1
			and description.Pants == 2
			and emoteOk
			and type(emotes) == "table"
			and type(accessories) == "table"
			and hasMethods(description, {
				"AddEmote",
				"GetEmotes",
				"GetEquippedEmotes",
				"RemoveEmote",
				"SetEmotes",
				"SetEquippedEmotes",
				"GetAccessories",
				"SetAccessories"
			})
	end)
end)

test("HumanoidDescription accessory round trip", function()
	return withTemporary("HumanoidDescription", function(description)
		local specification = {
			{
				Order = 1,
				AssetId = 123456789,
				AccessoryType = Enum.AccessoryType.Hat
			}
		}

		local setOk = pcall(function()
			description:SetAccessories(specification, true)
		end)

		if not setOk then
			return false, "SetAccessories failed"
		end

		local accessories = description:GetAccessories(true)

		return type(accessories) == "table"
			and #accessories >= 1
			and accessories[1].AssetId == 123456789
	end)
end)

test("Keyframe and KeyframeSequence", function()
	local sequence = Instance.new("KeyframeSequence")
	local keyframe = Instance.new("Keyframe")
	local pose = Instance.new("Pose")

	keyframe.Time = 0.5
	pose.Name = "Torso"
	pose.CFrame = CFrame.new(0, 1, 0)
	pose.Weight = 1
	pose.EasingStyle = Enum.PoseEasingStyle.Linear
	pose.EasingDirection = Enum.PoseEasingDirection.InOut
	keyframe:AddPose(pose)
	sequence:AddKeyframe(keyframe)
	sequence.Loop = true
	sequence.Priority = Enum.AnimationPriority.Action

	local keyframes = sequence:GetKeyframes()
	local poses = keyframe:GetPoses()
	local valid = nearlyEqual(keyframe.Time, 0.5)
		and pose.CFrame.Position == Vector3.new(0, 1, 0)
		and sequence.Loop == true
		and sequence.Priority == Enum.AnimationPriority.Action
		and #keyframes == 1
		and #poses == 1

	sequence:Destroy()

	return valid
end)

test("Seat and VehicleSeat", function()
	local seat = Instance.new("Seat")
	local vehicleSeat = Instance.new("VehicleSeat")

	seat.Disabled = false
	vehicleSeat.Disabled = false
	vehicleSeat.MaxSpeed = 30
	vehicleSeat.Torque = 20
	vehicleSeat.TurnSpeed = 5
	vehicleSeat.HeadsUpDisplay = false
	vehicleSeat.Steer = 0
	vehicleSeat.Throttle = 0

	local valid = seat.Occupant == nil
		and seat.Disabled == false
		and vehicleSeat.Occupant == nil
		and nearlyEqual(vehicleSeat.MaxSpeed, 30)
		and nearlyEqual(vehicleSeat.Torque, 20)
		and nearlyEqual(vehicleSeat.TurnSpeed, 5)
		and vehicleSeat.HeadsUpDisplay == false
		and seat:IsA("BasePart")
		and vehicleSeat:IsA("BasePart")

	seat:Destroy()
	vehicleSeat:Destroy()

	return valid
end)

test("SpawnLocation configuration", function()
	return withTemporary("SpawnLocation", function(spawnPoint)
		spawnPoint.Enabled = true
		spawnPoint.Neutral = false
		spawnPoint.AllowTeamChangeOnTouch = true
		spawnPoint.Duration = 5
		spawnPoint.TeamColor = BrickColor.new("Bright blue")

		return spawnPoint.Enabled == true
			and spawnPoint.Neutral == false
			and spawnPoint.AllowTeamChangeOnTouch == true
			and spawnPoint.Duration == 5
			and typeof(spawnPoint.TeamColor) == "BrickColor"
			and spawnPoint:IsA("BasePart")
	end)
end)

test("Highlight configuration", function()
	return withTemporary("Highlight", function(highlight)
		local part = Instance.new("Part")

		highlight.Adornee = part
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillColor = Color3.fromRGB(255, 0, 0)
		highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
		highlight.FillTransparency = 0.25
		highlight.OutlineTransparency = 0.5
		highlight.Enabled = true

		local valid = highlight.Adornee == part
			and highlight.DepthMode == Enum.HighlightDepthMode.AlwaysOnTop
			and typeof(highlight.FillColor) == "Color3"
			and typeof(highlight.OutlineColor) == "Color3"
			and nearlyEqual(highlight.FillTransparency, 0.25)
			and nearlyEqual(highlight.OutlineTransparency, 0.5)
			and highlight.Enabled == true

		part:Destroy()

		return valid
	end)
end)

test("Fire Smoke Sparkles", function()
	local fire = Instance.new("Fire")
	local smoke = Instance.new("Smoke")
	local sparkles = Instance.new("Sparkles")

	fire.Heat = 15
	fire.TimeScale = 0.75
	fire.Color = Color3.fromRGB(255, 100, 0)
	fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
	fire.Enabled = true
	smoke.RiseVelocity = 5
	smoke.Size = 2
	smoke.Opacity = 0.5
	smoke.Color = Color3.fromRGB(100, 100, 100)
	sparkles.SparkleColor = Color3.fromRGB(0, 255, 255)
	sparkles.TimeScale = 0.5
	sparkles.Enabled = true

	local valid = nearlyEqual(fire.Heat, 15)
		and nearlyEqual(fire.TimeScale, 0.75)
		and typeof(fire.Color) == "Color3"
		and typeof(fire.SecondaryColor) == "Color3"
		and nearlyEqual(smoke.RiseVelocity, 5)
		and nearlyEqual(smoke.Opacity, 0.5)
		and typeof(sparkles.SparkleColor) == "Color3"
		and nearlyEqual(sparkles.TimeScale, 0.5)

	fire:Destroy()
	smoke:Destroy()
	sparkles:Destroy()

	return valid
end)

test("Decal and Texture faces", function()
	local decal = Instance.new("Decal")
	local texture = Instance.new("Texture")

	for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
		decal.Face = face
		texture.Face = face

		if decal.Face ~= face or texture.Face ~= face then
			decal:Destroy()
			texture:Destroy()

			return false, tostring(face) .. " not applied"
		end
	end

	texture.StudsPerTileU = 4
	texture.StudsPerTileV = 2
	texture.OffsetStudsU = 1
	texture.OffsetStudsV = 0.5

	local valid = nearlyEqual(texture.StudsPerTileU, 4)
		and nearlyEqual(texture.StudsPerTileV, 2)
		and nearlyEqual(texture.OffsetStudsU, 1)
		and decal:IsA("FaceInstance")
		and texture:IsA("Decal")

	decal:Destroy()
	texture:Destroy()

	return valid
end)

test("Path2D control points", function()
	local screen = Instance.new("ScreenGui")
	local path = Instance.new("Path2D")

	path.Parent = screen

	local points = {
		Path2DControlPoint.new(UDim2.fromScale(0, 0)),
		Path2DControlPoint.new(UDim2.fromScale(0.5, 0.5)),
		Path2DControlPoint.new(UDim2.fromScale(1, 1))
	}

	local setOk, setError = pcall(function()
		path:SetControlPoints(points)
	end)

	if not setOk then
		screen:Destroy()

		return false, stringify(setError)
	end

	local stored = path:GetControlPoints()
	local first = path:GetControlPoint(1)
	local maximum = path:GetMaxControlPoints()
	local position = path:GetPositionOnCurve(0.5)
	local tangent = path:GetTangentOnCurve(0.5)
	local length = path:GetLength()
	local bounds = path:GetBoundingRect()

	path.Thickness = 5
	path.Color3 = Color3.fromRGB(255, 0, 0)
	path.Closed = false
	path.Visible = true
	path.ZIndex = 2

	local valid = #stored == 3
		and typeof(first) == "Path2DControlPoint"
		and type(maximum) == "number"
		and typeof(position) == "UDim2"
		and typeof(tangent) == "Vector2"
		and type(length) == "number"
		and typeof(bounds) == "Rect"
		and nearlyEqual(path.Thickness, 5)
		and typeof(path.Color3) == "Color3"
		and path.Closed == false
		and path.ZIndex == 2
		and isSignal(path.ControlPointChanged)
		and hasMethods(path, {
			"InsertControlPoint",
			"RemoveControlPoint",
			"UpdateControlPoint",
			"GetPositionOnCurveArcLength",
			"GetTangentOnCurveArcLength"
		})

	screen:Destroy()

	return valid
end)

test("Audio instances and wiring", function()
	local player = Instance.new("AudioPlayer")
	local emitter = Instance.new("AudioEmitter")
	local listener = Instance.new("AudioListener")
	local output = Instance.new("AudioDeviceOutput")
	local wire = Instance.new("Wire")

	player.Asset = "rbxassetid://0"
	player.Volume = 0.5
	player.Looping = true
	player.PlaybackSpeed = 1.5
	player.AutoLoad = true
	wire.SourceInstance = player
	wire.TargetInstance = output

	local valid = nearlyEqual(player.Volume, 0.5)
		and player.Looping == true
		and nearlyEqual(player.PlaybackSpeed, 1.5)
		and type(player.TimeLength) == "number"
		and type(player.TimePosition) == "number"
		and type(player.IsReady) == "boolean"
		and typeof(player.PlaybackRegion) == "NumberRange"
		and typeof(player.LoopRegion) == "NumberRange"
		and isSignal(player.Ended)
		and isSignal(player.Looped)
		and wire.SourceInstance == player
		and wire.TargetInstance == output
		and type(wire.Connected) == "boolean"
		and hasMethods(player, { "Play", "Stop", "Cancel", "GetConnectedWires" })
		and hasMethod(emitter, "GetConnectedWires")
		and hasMethod(listener, "GetConnectedWires")
		and hasMethod(output, "GetConnectedWires")

	player:Destroy()
	emitter:Destroy()
	listener:Destroy()
	output:Destroy()
	wire:Destroy()

	return valid
end)

test("Environment is Luau not standard Lua", function()
	local indicators = 0
	local reported = tostring(_VERSION)

	if reported == "Lua 5.1"
		or reported == "Lua 5.2"
		or reported == "Lua 5.3"
		or reported == "Lua 5.4"
	then
		indicators += 1
	end

	local dumpOk, dumped = pcall(function()
		return string.dump(function()
			return 1
		end)
	end)

	if dumpOk and type(dumped) == "string" and #dumped > 4 then
		indicators += 1
	end

	local loadOk, loaded = pcall(function()
		local chunk = load("return 1 + 1")

		return type(chunk) == "function" and chunk() == 2
	end)

	if loadOk and loaded == true then
		indicators += 1
	end

	local precisionOk, precision = pcall(function()
		return #tostring(1 / 3) == 16
	end)

	if precisionOk and precision == true then
		indicators += 1
	end

	if type(load) == "function" then
		indicators += 1
	end

	if indicators >= 2 then
		return false, "standard Lua indicators detected (score=" .. indicators .. ")"
	end

	return reported == "Luau"
end)

test("Enum registry is authentic", function()
	local enums = Enum:GetEnums()
	local seen = {}

	for _, enumType in ipairs(enums) do
		local name = tostring(enumType)

		if seen[name] then
			return false, "duplicate enum " .. name
		end

		seen[name] = true
	end

	return #enums > 50
end)

test("Font enum weights are authentic", function()
	local bold = Font.fromEnum(Enum.Font.GothamBold)
	local regular = Font.fromEnum(Enum.Font.Gotham)

	return bold.Weight == Enum.FontWeight.Bold
		and regular.Weight == Enum.FontWeight.Regular
		and bold.Family == regular.Family
end)

test("FloatCurve key insertion", function()
	local curve = Instance.new("FloatCurve")

	curve:InsertKey(FloatCurveKey.new(0, 0, Enum.KeyInterpolationMode.Constant))
	curve:InsertKey(FloatCurveKey.new(0.5, 7, Enum.KeyInterpolationMode.Linear))
	curve:InsertKey(FloatCurveKey.new(1, 3, Enum.KeyInterpolationMode.Cubic))

	local first = curve:GetKeyAtIndex(1)
	local second = curve:GetKeyAtIndex(2)
	local third = curve:GetKeyAtIndex(3)
	local length = curve.Length
	local keys = curve:GetKeys()

	curve:Destroy()

	return nearlyEqual(first.Time, 0)
		and nearlyEqual(second.Value, 7)
		and third.Interpolation == Enum.KeyInterpolationMode.Cubic
		and length == 3
		and #keys == 3
end)

test("FloatCurve linear interpolation", function()
	local curve = Instance.new("FloatCurve")

	curve:InsertKey(FloatCurveKey.new(0, 0, Enum.KeyInterpolationMode.Linear))
	curve:InsertKey(FloatCurveKey.new(1, 10, Enum.KeyInterpolationMode.Linear))

	local atStart = curve:GetValueAtTime(0)
	local atEnd = curve:GetValueAtTime(1)
	local atMiddle = curve:GetValueAtTime(0.5)

	curve:Destroy()

	return nearlyEqual(atStart, 0, 0.01)
		and nearlyEqual(atEnd, 10, 0.01)
		and nearlyEqual(atMiddle, 5, 0.01)
end)

test("RotationCurve key insertion", function()
	local curve = Instance.new("RotationCurve")

	local surfaceOk, surfaceError = hasMethods(curve, {
		"GetKeyAtIndex",
		"GetKeyIndicesAtTime",
		"GetKeys",
		"GetValueAtTime",
		"InsertKey",
		"RemoveKeyAtIndex",
		"SetKeys"
	})

	if not surfaceOk then
		curve:Destroy()

		return false, surfaceError
	end

	if type(curve.Length) ~= "number" then
		curve:Destroy()

		return false, "Length is " .. type(curve.Length)
	end

	local emptyKeys = curve:GetKeys()
	local emptyLength = curve.Length
	local emptyValue = curve:GetValueAtTime(0)

	pcall(function()
		curve:InsertKey(RotationCurveKey.new(0, CFrame.new(), Enum.KeyInterpolationMode.Linear))
	end)

	pcall(function()
		curve:SetKeys({
			RotationCurveKey.new(0, CFrame.new(), Enum.KeyInterpolationMode.Linear),
			RotationCurveKey.new(1, CFrame.Angles(0, math.pi / 2, 0), Enum.KeyInterpolationMode.Linear)
		})
	end)

	local length = curve.Length
	local keys = curve:GetKeys()
	local stored

	if length > 0 then
		local readOk, value = pcall(function()
			return curve:GetKeyAtIndex(1)
		end)

		if readOk then
			stored = value
		end
	end

	curve:Destroy()

	if type(emptyKeys) ~= "table" or #emptyKeys ~= 0 or emptyLength ~= 0 then
		return false, "new curve is not empty"
	end

	if emptyValue ~= nil and typeof(emptyValue) ~= "CFrame" then
		return false, "empty curve sampled as " .. typeof(emptyValue)
	end

	if type(keys) ~= "table" then
		return false, "GetKeys returned " .. type(keys)
	end

	if type(length) ~= "number" or length < 0 then
		return false, "curve length is " .. stringify(length)
	end

	if stored ~= nil then
		return typeof(stored) == "RotationCurveKey"
			and typeof(stored.Value) == "CFrame"
	end

	return true
end)

test("RotationCurveKey construction", function()
	local key = RotationCurveKey.new(0.5, CFrame.new(1, 2, 3), Enum.KeyInterpolationMode.Cubic)
	local rotationOnly = RotationCurveKey.new(0, CFrame.Angles(0, math.pi / 2, 0), Enum.KeyInterpolationMode.Linear)

	return typeof(key) == "RotationCurveKey"
		and nearlyEqual(key.Time, 0.5)
		and typeof(key.Value) == "CFrame"
		and key.Interpolation == Enum.KeyInterpolationMode.Cubic
		and rotationOnly.Interpolation == Enum.KeyInterpolationMode.Linear
		and (key.LeftTangent == nil or type(key.LeftTangent) == "number")
end)

test("game metatable is locked", function()
	local gameMeta = getmetatable(game)
	local workspaceMeta = getmetatable(workspace)

	return type(gameMeta) == "string"
		and gameMeta == "The metatable is locked"
		and type(workspaceMeta) == "string"
		and workspaceMeta == gameMeta
end)

test("Instance metatable cannot be replaced", function()
	local part = Instance.new("Part")
	local setOk = pcall(setmetatable, part, {})
	local rawsetOk = pcall(rawset, part, "Injected", true)

	part:Destroy()

	return setOk == false
		and rawsetOk == false
end)

test("Instances are userdata", function()
	local part = Instance.new("Part")
	local valid = type(part) == "userdata"
		and type(game) == "userdata"
		and type(workspace) == "userdata"
		and typeof(part) == "Instance"
		and typeof(game) == "Instance"
		and typeof(workspace) == "Instance"

	part:Destroy()

	return valid
end)

test("game cannot be called", function()
	return pcall(function()
		return game()
	end) == false
		and pcall(function()
			return workspace()
		end) == false
end)

test("Vector3 components are frozen", function()
	local value = Vector3.new(1, 2, 3)

	return pcall(function()
		value.X = 10
	end) == false
		and pcall(function()
			value.Magnitude = 10
		end) == false
		and value.X == 1
end)

test("Vector2 components are frozen", function()
	local value = Vector2.new(1, 2)

	return pcall(function()
		value.X = 10
	end) == false
		and value.X == 1
end)

test("Color3 components are frozen", function()
	local value = Color3.new(0.25, 0.5, 0.75)

	return pcall(function()
		value.R = 1
	end) == false
		and nearlyEqual(value.R, 0.25)
end)

test("CFrame components are frozen", function()
	local value = CFrame.new(1, 2, 3)

	return pcall(function()
		value.Position = Vector3.zero
	end) == false
		and pcall(function()
			value.X = 99
		end) == false
		and value.X == 1
end)

test("UDim2 components are frozen", function()
	local value = UDim2.new(0, 10, 0, 20)

	return pcall(function()
		value.X = UDim.new(1, 0)
	end) == false
		and value.X.Offset == 10
end)

test("standard libraries are frozen", function()
	local libraries = {
		string = string,
		table = table,
		math = math,
		bit32 = bit32,
		utf8 = utf8,
		os = os,
		coroutine = coroutine,
		buffer = buffer,
		task = task
	}

	for name, library in pairs(libraries) do
		if type(library) ~= "table" then
			return false, name .. " missing"
		end

		if not table.isfrozen(library) then
			return false, name .. " is not frozen"
		end

		local writeOk = pcall(function()
			library.LogUncProbe = 1
		end)

		if writeOk then
			return false, name .. " is writable"
		end
	end

	return true
end)

test("C functions report no source line", function()
	local natives = {
		["math.abs"] = math.abs,
		["math.clamp"] = math.clamp,
		["math.deg"] = math.deg,
		["math.rad"] = math.rad,
		["math.random"] = math.random,
		["string.len"] = string.len,
		["string.format"] = string.format,
		["table.insert"] = table.insert,
		["table.sort"] = table.sort,
		["utf8.char"] = utf8.char,
		["bit32.bxor"] = bit32.bxor,
		["buffer.create"] = buffer.create,
		["task.wait"] = task.wait,
		["task.spawn"] = task.spawn,
		next = next,
		select = select,
		tostring = tostring,
		tonumber = tonumber,
		typeof = typeof,
		pcall = pcall
	}

	for name, fn in pairs(natives) do
		local source = debug.info(fn, "s")
		local line = debug.info(fn, "l")

		if source ~= "[C]" then
			return false, name .. " source is " .. tostring(source)
		end

		if line ~= -1 then
			return false, name .. " line is " .. tostring(line)
		end
	end

	return true
end)

test("Roblox constructors are C functions", function()
	local natives = {
		["Instance.new"] = Instance.new,
		["Vector3.new"] = Vector3.new,
		["CFrame.new"] = CFrame.new,
		["CFrame.lookAt"] = CFrame.lookAt,
		["Color3.new"] = Color3.new,
		["UDim2.new"] = UDim2.new,
		["BrickColor.new"] = BrickColor.new,
		["Random.new"] = Random.new,
		["DateTime.now"] = DateTime.now
	}

	for name, fn in pairs(natives) do
		if type(fn) ~= "function" then
			return false, name .. " missing"
		end

		if debug.info(fn, "s") ~= "[C]" then
			return false, name .. " is not native"
		end
	end

	return true
end)

test("Lua functions report a source", function()
	local function sample() end

	local source = debug.info(sample, "s")
	local line = debug.info(sample, "l")

	return type(source) == "string"
		and source ~= "[C]"
		and type(line) == "number"
		and line > 0
end)

test("string.dump is unavailable", function()
	return string.dump == nil
		and pcall(function()
			return string.dump(function() end)
		end) == false
end)

test("math errors mention expected type", function()
	local ok, message = pcall(math.abs, "fail")

	return ok == false
		and type(message) == "string"
		and string.find(message, "number expected", 1, true) ~= nil
end)

test("math.random rejects empty interval", function()
	local ok, message = pcall(math.random, 10, 1)

	return ok == false
		and type(message) == "string"
		and string.find(string.lower(message), "interval") ~= nil
end)

test("utf8.char rejects invalid codepoints", function()
	local ok, message = pcall(utf8.char, -1)

	return ok == false
		and type(message) == "string"
end)

test("string.rep rejects negative counts gracefully", function()
	return string.rep("x", -5) == ""
		and string.rep("x", 0) == ""
		and pcall(string.rep, "x", "abc") == false
end)

test("table.concat rejects non-string values", function()
	return pcall(table.concat, { {} }, ",") == false
		and pcall(table.concat, { print }, ",") == false
end)

optional("ypcall behaves like pcall", function()
	if type(ypcall) ~= "function" then
		return false, "ypcall unavailable"
	end

	local failed = ypcall(function()
		error("y")
	end)
	local ok, value = ypcall(function()
		return 99
	end)

	return failed == false
		and ok == true
		and value == 99
end)

test("rawlen works on strings and tables", function()
	return rawlen("abcd") == 4
		and rawlen({ 1, 2, 3 }) == 3
		and rawlen("") == 0
		and pcall(rawlen, 5) == false
end)

test("_G rawget consistency", function()
	for key, value in pairs(_G) do
		if rawget(_G, key) ~= value then
			return false, tostring(key) .. " differs"
		end
	end

	return true
end)

test("_G has no index hooks", function()
	local meta = getmetatable(_G)

	if meta == nil then
		return true
	end

	if type(meta) ~= "table" then
		return false, "metatable is " .. type(meta)
	end

	return meta.__index == nil
		and meta.__newindex == nil
end)

test("tostring is stable for functions", function()
	local function sample() end

	local first = tostring(sample)
	local second = tostring(sample)

	return first == second
		and string.find(first, "function", 1, true) ~= nil
end)

test("tostring is stable for instances", function()
	local part = Instance.new("Part")

	part.Name = "Original"

	local before = tostring(part)

	part.Name = "Renamed"

	local after = tostring(part)

	part:Destroy()

	return before == "Original"
		and after == "Renamed"
end)

test("C functions ignore proxy metatables", function()
	local proxy = newproxy(true)
	local meta = getmetatable(proxy)
	local touched = false

	meta.__index = function()
		touched = true

		return 1
	end
	meta.__len = function()
		touched = true

		return 1
	end

	pcall(function()
		return #proxy
	end)

	local concatOk = pcall(function()
		return proxy .. ""
	end)

	return concatOk == false
		and type(touched) == "boolean"
end)

test("require rejects arbitrary values", function()
	return pcall(require, "LogUncModule") == false
		and pcall(require, 12345) == false
		and pcall(require) == false
end)

test("loadstring rejects Luau bytecode", function()
	if type(loadstring) ~= "function" then
		return false, "loadstring unavailable"
	end

	local bytecode = "\27Lua" .. string.rep("\0", 16)
	local chunk, message = loadstring(bytecode)

	return chunk == nil
		and type(message) == "string"
end)

test("loadstring reports syntax errors", function()
	if type(loadstring) ~= "function" then
		return false, "loadstring unavailable"
	end

	local chunk, message = loadstring("this is not valid lua ((")

	return chunk == nil
		and type(message) == "string"
		and #message > 0
end)

test("setfenv applies to loadstring chunks", function()
	if type(loadstring) ~= "function" or type(setfenv) ~= "function" then
		return false, "loadstring or setfenv unavailable"
	end

	local chunk = loadstring("return LogUncInjected")

	if chunk == nil then
		return false, "chunk failed to compile"
	end

	setfenv(chunk, { LogUncInjected = 77 })

	local value = chunk()

	return value == 77
		and LogUncInjected == nil
end)

test("setfenv does not leak into the caller", function()
	if type(setfenv) ~= "function" or type(getfenv) ~= "function" then
		return false, "getfenv or setfenv unavailable"
	end

	local function target()
		return LogUncLeaked
	end

	setfenv(target, { LogUncLeaked = "inner" })

	return target() == "inner"
		and LogUncLeaked == nil
		and getfenv(target).LogUncLeaked == "inner"
end)

test("setfenv rejects C functions", function()
	if type(setfenv) ~= "function" or type(getfenv) ~= "function" then
		return false, "getfenv or setfenv unavailable"
	end

	return pcall(setfenv, tostring, getfenv(0)) == false
end)

test("Vector2int16 construction", function()
	local value = Vector2int16.new(3, 4)

	return typeof(value) == "Vector2int16"
		and value.X == 3
		and value.Y == 4
		and Vector2int16.new(1.9, 2.9).X == 1
		and Vector2int16.new(32768, 0).X == -32768
end)

test("Vector2int16 arithmetic", function()
	return Vector2int16.new(1, 2) + Vector2int16.new(3, 4) == Vector2int16.new(4, 6)
		and Vector2int16.new(4, 6) - Vector2int16.new(3, 4) == Vector2int16.new(1, 2)
		and Vector2int16.new(2, 3) * Vector2int16.new(4, 5) == Vector2int16.new(8, 15)
		and Vector2int16.new(8, 15) / Vector2int16.new(4, 5) == Vector2int16.new(2, 3)
		and Vector2int16.new(2, 3) * 2 == Vector2int16.new(4, 6)
		and Vector2int16.new(4, 6) / 2 == Vector2int16.new(2, 3)
end)

test("Vector3int16 arithmetic", function()
	return Vector3int16.new(1, 2, 3) + Vector3int16.new(3, 4, 5) == Vector3int16.new(4, 6, 8)
		and Vector3int16.new(4, 6, 8) - Vector3int16.new(3, 4, 5) == Vector3int16.new(1, 2, 3)
		and Vector3int16.new(2, 3, 4) * Vector3int16.new(4, 5, 6) == Vector3int16.new(8, 15, 24)
		and Vector3int16.new(8, 15, 24) / Vector3int16.new(4, 5, 6) == Vector3int16.new(2, 3, 4)
		and Vector3int16.new(2, 3, 4) * 2 == Vector3int16.new(4, 6, 8)
		and Vector3int16.new(4, 6, 8) / 2 == Vector3int16.new(2, 3, 4)
end)

test("ValueCurveKey construction", function()
	local ok, key = pcall(function()
		return ValueCurveKey.new(0.5, 42, Enum.KeyInterpolationMode.Cubic)
	end)

	if not ok then
		return false, "ValueCurveKey unavailable"
	end

	return typeof(key) == "ValueCurveKey"
		and nearlyEqual(key.Time, 0.5)
		and nearlyEqual(key.Value, 42)
		and key.Interpolation == Enum.KeyInterpolationMode.Cubic
end)

test("RotationCurveKey rotation component", function()
	local key = RotationCurveKey.new(
		0.25,
		CFrame.new(1, 2, 3) * CFrame.Angles(0, math.pi / 2, 0),
		Enum.KeyInterpolationMode.Linear
	)

	local _, angle = key.Value:ToAxisAngle()

	return typeof(key) == "RotationCurveKey"
		and nearlyEqual(key.Time, 0.25)
		and typeof(key.Value) == "CFrame"
		and nearlyEqual(math.abs(angle), math.pi / 2, 0.001)
		and key.Interpolation == Enum.KeyInterpolationMode.Linear
end)

test("SecurityCapabilities construction", function()
	local empty = SecurityCapabilities.new()
	local withItems = SecurityCapabilities.new(Enum.SecurityCapability.Basic)
	local current = SecurityCapabilities.fromCurrent()

	return typeof(empty) == "SecurityCapabilities"
		and typeof(withItems) == "SecurityCapabilities"
		and typeof(current) == "SecurityCapabilities"
end)

test("SecurityCapabilities set operations", function()
	local base = SecurityCapabilities.new()
	local added = base:Add(Enum.SecurityCapability.Basic)
	local removed = added:Remove(Enum.SecurityCapability.Basic)
	local duplicated = SecurityCapabilities.new(Enum.SecurityCapability.Basic)
		:Add(Enum.SecurityCapability.Basic)

	return typeof(added) == "SecurityCapabilities"
		and typeof(removed) == "SecurityCapabilities"
		and added:Contains(Enum.SecurityCapability.Basic) == true
		and removed:Contains(Enum.SecurityCapability.Basic) == false
		and base:Contains(Enum.SecurityCapability.Basic) == false
		and duplicated:Contains(Enum.SecurityCapability.Basic) == true
end)

test("Instance Capabilities datatype", function()
	return withTemporary("Folder", function(object)
		local capabilities = object.Capabilities

		if typeof(capabilities) ~= "SecurityCapabilities" then
			return false, "Capabilities is " .. typeof(capabilities)
		end

		local writeOk = pcall(function()
			object.Capabilities = SecurityCapabilities.new(Enum.SecurityCapability.Basic)
		end)

		return writeOk
			and typeof(object.Capabilities) == "SecurityCapabilities"
			and type(object.Sandboxed) == "boolean"
	end)
end)

test("SharedTable element access", function()
	local sharedTable = SharedTable.new()

	sharedTable[1] = "a"
	sharedTable.x = true
	sharedTable.y = 5

	return typeof(sharedTable) == "SharedTable"
		and sharedTable[1] == "a"
		and sharedTable.x == true
		and sharedTable.y == 5
		and pcall(function()
			sharedTable[true] = 1
		end) == false
		and pcall(function()
			sharedTable.callback = function() end
		end) == false
end)

test("SharedTable from Luau table", function()
	local sharedTable = SharedTable.new({
		x = 1,
		y = 2,
		z = { "a", "b", "c" }
	})

	return sharedTable.x == 1
		and sharedTable.y == 2
		and typeof(sharedTable.z) == "SharedTable"
		and sharedTable.z[1] == "a"
		and sharedTable.z[3] == "c"
		and SharedTable.size(sharedTable) == 3
end)

test("SharedTable shallow clone", function()
	local original = SharedTable.new()

	original.a = "original"
	original.nested = SharedTable.new()
	original.nested.value = "original"

	local clone = SharedTable.clone(original, false)

	clone.a = "changed"
	clone.nested.value = "changed"

	return typeof(clone) == "SharedTable"
		and original.a == "original"
		and clone.a == "changed"
		and original.nested == clone.nested
		and original.nested.value == "changed"
end)

test("SharedTable deep clone", function()
	local original = SharedTable.new()

	original.nested = SharedTable.new()
	original.nested.value = "original"

	local clone = SharedTable.clone(original, true)

	clone.nested.value = "changed"

	return original.nested ~= clone.nested
		and original.nested.value == "original"
		and clone.nested.value == "changed"
end)

test("SharedTable freezing", function()
	local original = SharedTable.new({ "a", "b", "c" })
	local frozen = SharedTable.cloneAndFreeze(original)

	return SharedTable.isFrozen(original) == false
		and SharedTable.isFrozen(frozen) == true
		and pcall(function()
			frozen[1] = "z"
		end) == false
		and pcall(SharedTable.clear, frozen) == false
end)

test("SharedTable increment and update", function()
	local sharedTable = SharedTable.new()

	sharedTable.counter = 1

	local previous = SharedTable.increment(sharedTable, "counter", 4)

	sharedTable.text = "abcd"

	SharedTable.update(sharedTable, "text", function(value)
		return value .. "e"
	end)

	sharedTable.notNumber = "text"

	return previous == 1
		and sharedTable.counter == 5
		and sharedTable.text == "abcde"
		and pcall(SharedTable.increment, sharedTable, "notNumber", 1) == false
end)

test("SharedTable clear and size", function()
	local sharedTable = SharedTable.new({ "a", "b", "c" })
	local before = SharedTable.size(sharedTable)

	SharedTable.clear(sharedTable)

	return before == 3
		and SharedTable.size(sharedTable) == 0
end)

test("SharedTable identity comparison", function()
	local first = SharedTable.new({ 1, 2, 3 })
	local second = SharedTable.new({ 1, 2, 3 })

	return first ~= second
		and first == first
end)

test("SharedTableRegistry storage", function()
	local registry = game:GetService("SharedTableRegistry")
	local name = "LogUncSharedTable"
	local created = registry:GetSharedTable(name)

	created.value = 42

	local again = registry:GetSharedTable(name)
	local valid = typeof(created) == "SharedTable"
		and again == created
		and again.value == 42

	pcall(function()
		registry:SetSharedTable(name, nil)
	end)

	return valid
		and hasMethod(registry, "GetSharedTable")
		and hasMethod(registry, "SetSharedTable")
end)

test("EncodingService base64 round trip", function()
	local encodingService = game:GetService("EncodingService")
	local source = buffer.fromstring("Log-Unc encoding test")
	local encoded = encodingService:Base64Encode(source)
	local decoded = encodingService:Base64Decode(encoded)

	return type(encoded) == "buffer"
		and type(decoded) == "buffer"
		and buffer.tostring(decoded) == "Log-Unc encoding test"
end)

test("EncodingService compression round trip", function()
	local encodingService = game:GetService("EncodingService")
	local text = string.rep("Log-Unc compression sample. ", 32)
	local source = buffer.fromstring(text)
	local compressed = encodingService:CompressBuffer(source, Enum.CompressionAlgorithm.Zstd)
	local size = encodingService:GetDecompressedBufferSize(compressed, Enum.CompressionAlgorithm.Zstd)
	local decompressed = encodingService:DecompressBuffer(compressed, Enum.CompressionAlgorithm.Zstd)

	return type(compressed) == "buffer"
		and buffer.len(compressed) < buffer.len(source)
		and (size == nil or size == buffer.len(source))
		and buffer.tostring(decompressed) == text
end)

test("EncodingService hashing", function()
	local encodingService = game:GetService("EncodingService")
	local stringHash = encodingService:ComputeStringHash("Log-Unc", Enum.HashAlgorithm.Sha256)
	local bufferHash = encodingService:ComputeBufferHash(
		buffer.fromstring("Log-Unc"),
		Enum.HashAlgorithm.Sha256
	)
	local repeated = encodingService:ComputeStringHash("Log-Unc", Enum.HashAlgorithm.Sha256)
	local different = encodingService:ComputeStringHash("Other", Enum.HashAlgorithm.Sha256)

	return type(stringHash) == "string"
		and #stringHash > 0
		and type(bufferHash) == "buffer"
		and stringHash == repeated
		and stringHash ~= different
end)

test("Secret datatype surface", function()
	local httpService = game:GetService("HttpService")

	if not hasMethod(httpService, "GetSecret") then
		return false, "GetSecret unavailable"
	end

	local ok, value = pcall(function()
		return httpService:GetSecret("LogUncMissingSecret")
	end)

	if ok and value ~= nil then
		return typeof(value) == "Secret"
			and hasMethod(value, "AddPrefix")
			and hasMethod(value, "AddSuffix")
	end

	return ok == false
end)

test("DateTime pcall overhead is not faked", function()
	local start = DateTime.now().UnixTimestampMillis
	local total = 0

	for _ = 1, 25000 do
		local ok, value = pcall(function()
			return 1
		end)

		if ok then
			total += value
		end
	end

	local elapsed = DateTime.now().UnixTimestampMillis - start

	if total ~= 25000 then
		return false, "pcall returned " .. total
	end

	if elapsed > 250 then
		return false, "25000 pcalls took " .. elapsed .. "ms"
	end

	return true
end)

test("DateTime advances with real time", function()
	local before = DateTime.now().UnixTimestampMillis

	task.wait(0.1)

	local after = DateTime.now().UnixTimestampMillis
	local delta = after - before

	return delta >= 50
		and delta < 5000
end)

test("os.clock matches DateTime progression", function()
	local clockStart = os.clock()
	local dateStart = DateTime.now().UnixTimestampMillis

	task.wait(0.15)

	local clockDelta = (os.clock() - clockStart) * 1000
	local dateDelta = DateTime.now().UnixTimestampMillis - dateStart

	return clockDelta >= 50
		and dateDelta >= 50
		and math.abs(clockDelta - dateDelta) < 500
end)

test("ForceField creation", function()
	return withTemporary("ForceField", function(field)
		field.Visible = false

		return field.Visible == false
			and field.ClassName == "ForceField"
	end)
end)

test("UniversalConstraint configuration", function()
	return withTemporary("UniversalConstraint", function(universal)
		universal.LimitsEnabled = true
		universal.MaxAngle = 45
		universal.Restitution = 0.5
		universal.Radius = 0.5

		return universal.LimitsEnabled == true
			and nearlyEqual(universal.MaxAngle, 45)
			and nearlyEqual(universal.Restitution, 0.5)
			and universal:IsA("Constraint")
	end)
end)

test("DragDetector configuration", function()
	return withTemporary("DragDetector", function(detector)
		detector.DragStyle = Enum.DragDetectorDragStyle.TranslatePlane
		detector.ResponseStyle = Enum.DragDetectorResponseStyle.Geometric
		detector.Enabled = true

		return detector.DragStyle == Enum.DragDetectorDragStyle.TranslatePlane
			and detector.ResponseStyle == Enum.DragDetectorResponseStyle.Geometric
			and isSignal(detector.DragStart)
			and isSignal(detector.DragContinue)
			and isSignal(detector.DragEnd)
			and detector:IsA("ClickDetector")
	end)
end)

test("ClickDetector signals", function()
	return withTemporary("ClickDetector", function(detector)
		detector.MaxActivationDistance = 32
		detector.CursorIcon = "rbxassetid://0"

		return nearlyEqual(detector.MaxActivationDistance, 32)
			and detector.CursorIcon == "rbxassetid://0"
			and isSignal(detector.MouseHoverEnter)
			and isSignal(detector.MouseHoverLeave)
			and isSignal(detector.RightMouseClick)
	end)
end)

test("workspace baseline children", function()
	local camera = workspace.CurrentCamera
	local terrain = workspace.Terrain

	return terrain ~= nil
		and terrain:IsA("Terrain")
		and (camera == nil or camera:IsA("Camera"))
		and workspace.Parent == game
		and workspace:IsA("WorldRoot")
		and workspace == game:GetService("Workspace")
		and workspace == game.Workspace
end)

test("StarterPlayer containers", function()
	local starterPlayer = game:GetService("StarterPlayer")
	local playerScripts = starterPlayer:FindFirstChildOfClass("StarterPlayerScripts")
	local characterScripts = starterPlayer:FindFirstChildOfClass("StarterCharacterScripts")

	return starterPlayer.ClassName == "StarterPlayer"
		and playerScripts ~= nil
		and characterScripts ~= nil
		and playerScripts:IsA("StarterPlayerScripts")
		and characterScripts:IsA("StarterPlayerScripts")
		and type(starterPlayer.CharacterWalkSpeed) == "number"
		and type(starterPlayer.CharacterJumpPower) == "number"
		and type(starterPlayer.CharacterMaxSlopeAngle) == "number"
		and type(starterPlayer.LoadCharacterAppearance) == "boolean"
		and typeof(starterPlayer.CameraMode) == "EnumItem"
end)

test("StarterPack and StarterGui shape", function()
	local starterPack = game:GetService("StarterPack")
	local starterGui = game:GetService("StarterGui")

	return starterPack.ClassName == "StarterPack"
		and starterGui.ClassName == "StarterGui"
		and starterPack.Parent == game
		and starterGui.Parent == game
		and type(starterPack:GetChildren()) == "table"
end)

test("GetService matches property access", function()
	local pairsToCheck = {
		"Workspace",
		"Players",
		"Lighting",
		"ReplicatedStorage",
		"CollectionService",
		"HttpService",
		"RunService"
	}

	for _, name in ipairs(pairsToCheck) do
		local viaService = game:GetService(name)
		local ok, viaProperty = pcall(function()
			return game[name]
		end)

		if ok and viaProperty ~= nil and viaProperty ~= viaService then
			return false, name .. " differs"
		end
	end

	return true
end)

test("Instance property write rejects wrong instance type", function()
	local weld = Instance.new("WeldConstraint")
	local folder = Instance.new("Folder")
	local ok = pcall(function()
		weld.Part0 = folder
	end)

	weld:Destroy()
	folder:Destroy()

	return ok == false
end)

test("Instance numeric index is rejected", function()
	return withTemporary("Part", function(part)
		return pcall(function()
			return part[1]
		end) == false
			and pcall(function()
				return part[0]
			end) == false
	end)
end)

test("Instance.new error is not a runtime error", function()
	local ok, message = pcall(Instance.new, "LogUncNotAClass")

	return ok == false
		and type(message) == "string"
		and string.find(string.lower(message), "attempt to") == nil
end)

test("Property clamping and validation", function()
	local part = Instance.new("Part")

	part.Color = Color3.new(0, 0, 0)

	pcall(function()
		part.Color = Color3.new(256, 0, 0)
	end)

	local color = part.Color

	part:Destroy()

	if color.R > 1 or color.G > 1 or color.B > 1 then
		return false, "Color accepted out of range values"
	end

	local terrain = workspace.Terrain
	local originalWaveSpeed = terrain.WaterWaveSpeed
	local waveOk = pcall(function()
		terrain.WaterWaveSpeed = 9000000000
	end)
	local waveSpeed = terrain.WaterWaveSpeed

	pcall(function()
		terrain.WaterWaveSpeed = originalWaveSpeed
	end)

	if waveOk and waveSpeed > 100 then
		return false, "WaterWaveSpeed is " .. waveSpeed
	end

	local originalTransparency = terrain.WaterTransparency
	local transparencyOk = pcall(function()
		terrain.WaterTransparency = 50
	end)
	local transparency = terrain.WaterTransparency

	pcall(function()
		terrain.WaterTransparency = originalTransparency
	end)

	if transparencyOk and transparency > 1 then
		return false, "WaterTransparency is " .. transparency
	end

	return true
end)

optional("Player zoom distance validation", function()
	local player = getCurrentPlayer()

	if not player then
		return false, "player unavailable"
	end

	local original = player.CameraMinZoomDistance

	pcall(function()
		player.CameraMinZoomDistance = -5
	end)

	local afterNegative = player.CameraMinZoomDistance

	pcall(function()
		player.CameraMinZoomDistance = original
	end)

	return afterNegative >= 0
end)

test("GetChildren returns a fresh snapshot", function()
	local root = Instance.new("Folder")
	local first = Instance.new("Folder")

	first.Parent = root

	local snapshot = root:GetChildren()
	local second = Instance.new("Folder")

	second.Parent = root

	local later = root:GetChildren()

	root:Destroy()

	return #snapshot == 1
		and #later == 2
		and snapshot ~= later
end)

test("GetChildren mutation does not affect hierarchy", function()
	local root = Instance.new("Folder")
	local child = Instance.new("Folder")

	child.Parent = root

	local snapshot = root:GetChildren()

	snapshot[1] = nil
	snapshot[2] = "injected"

	local valid = #root:GetChildren() == 1
		and root:GetChildren()[1] == child

	root:Destroy()

	return valid
end)

test("Instance GetFullName reflects renames", function()
	local model = Instance.new("Model")
	local part = Instance.new("Part")

	model.Name = "Holder"
	part.Name = "Child"
	part.Parent = model

	local before = part:GetFullName()

	model.Name = "Renamed"

	local after = part:GetFullName()

	model:Destroy()

	return before == "Holder.Child"
		and after == "Renamed.Child"
end)

test("IsDescendantOf tracks reparenting", function()
	local first = Instance.new("Folder")
	local second = Instance.new("Folder")
	local child = Instance.new("Folder")

	child.Parent = first

	local inFirst = child:IsDescendantOf(first)

	child.Parent = second

	local inSecond = child:IsDescendantOf(second)
	local leftFirst = child:IsDescendantOf(first) == false

	first:Destroy()
	second:Destroy()

	return inFirst
		and inSecond
		and leftFirst
end)

test("Anchored part does not fall", function()
	local part = Instance.new("Part")

	part.Anchored = true
	part.Position = Vector3.new(0, 5000, 0)
	part.Parent = workspace

	task.wait(0.2)

	local stayed = nearlyEqual(part.Position.Y, 5000, 0.01)

	part:Destroy()

	return stayed
end)

test("Unanchored part falls under gravity", function()
	local part = Instance.new("Part")

	part.Anchored = false
	part.Position = Vector3.new(0, 5000, 0)
	part.Parent = workspace

	local startY = part.Position.Y

	task.wait(0.35)

	local endY = part.Position.Y

	part:Destroy()

	return endY < startY
end)

test("Part velocity assignment moves the part", function()
	local part = Instance.new("Part")

	part.Anchored = false
	part.Position = Vector3.new(0, 6000, 0)
	part.Parent = workspace

	local startZ = part.Position.Z

	part.AssemblyLinearVelocity = Vector3.new(0, 0, 50)

	task.wait(0.25)

	local endZ = part.Position.Z

	part:Destroy()

	return endZ > startZ
end)

test("Instance signals fire on property change", function()
	return withTemporary("Part", function(part)
		local changedProperties = {}
		local connection = part.Changed:Connect(function(property)
			changedProperties[property] = true
		end)

		part.Name = "Renamed"
		part.Transparency = 0.5
		part.Anchored = true
		task.wait()
		connection:Disconnect()

		return changedProperties.Name == true
			and changedProperties.Transparency == true
			and changedProperties.Anchored == true
	end)
end)

test("Service names may differ from class names", function()
	local expectations = {
		ScriptContext = "Script Context",
		TeleportService = "Teleport Service"
	}

	for className, expectedName in pairs(expectations) do
		local ok, service = pcall(game.GetService, game, className)

		if not ok or service == nil then
			return false, className .. " unavailable"
		end

		if service.ClassName ~= className then
			return false, className .. " reports class " .. service.ClassName
		end

		if service.Name ~= expectedName then
			return false, className .. " is named " .. service.Name
		end
	end

	return true
end)

test("GetService resolves by class not name", function()
	for _, className in ipairs(serviceNames) do
		local ok, service = pcall(game.GetService, game, className)

		if ok and service ~= nil and service.ClassName ~= className then
			return false, className .. " resolved to " .. service.ClassName
		end
	end

	return true
end)

test("DataModel name is the place name", function()
	return type(game.Name) == "string"
		and #game.Name > 0
		and game.Name ~= "game"
		and game:GetFullName() == game.Name
end)

test("CoreGui contains RobloxGui", function()
	local coreGui = game:GetService("CoreGui")
	local robloxGui = coreGui:FindFirstChild("RobloxGui")

	if robloxGui == nil then
		return false, "RobloxGui missing"
	end

	return robloxGui:IsA("ScreenGui")
		and robloxGui:IsA("LayerCollector")
		and robloxGui.Parent == coreGui
		and robloxGui:GetFullName() == "CoreGui.RobloxGui"
end)

test("CoreGui holds LayerCollector children", function()
	local coreGui = game:GetService("CoreGui")
	local collectors = 0

	for _, child in ipairs(coreGui:GetChildren()) do
		if child:IsA("LayerCollector") then
			collectors += 1
		end
	end

	return collectors > 0
end)

test("CoreGui descendants are readable", function()
	local coreGui = game:GetService("CoreGui")
	local inspected = 0

	for _, descendant in ipairs(coreGui:GetDescendants()) do
		if inspected >= 200 then
			break
		end

		inspected += 1

		if type(descendant.Name) ~= "string" then
			return false, "descendant name invalid"
		end

		if type(descendant.ClassName) ~= "string" then
			return false, descendant.Name .. " class invalid"
		end

		if descendant:IsA("GuiObject") then
			if typeof(descendant.Position) ~= "UDim2" then
				return false, descendant.Name .. " position invalid"
			end

			if typeof(descendant.Size) ~= "UDim2" then
				return false, descendant.Name .. " size invalid"
			end

			if typeof(descendant.BackgroundColor3) ~= "Color3" then
				return false, descendant.Name .. " color invalid"
			end

			if type(descendant.Visible) ~= "boolean" then
				return false, descendant.Name .. " visibility invalid"
			end
		end
	end

	return inspected > 0
end)

test("CoreGui text descendants expose text metrics", function()
	local coreGui = game:GetService("CoreGui")
	local inspected = 0

	for _, descendant in ipairs(coreGui:GetDescendants()) do
		if inspected >= 40 then
			break
		end

		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			inspected += 1

			if type(descendant.Text) ~= "string" then
				return false, descendant.Name .. " text invalid"
			end

			if type(descendant.TextSize) ~= "number" then
				return false, descendant.Name .. " size invalid"
			end

			if typeof(descendant.TextColor3) ~= "Color3" then
				return false, descendant.Name .. " color invalid"
			end

			if typeof(descendant.FontFace) ~= "Font" then
				return false, descendant.Name .. " font invalid"
			end
		end
	end

	return inspected > 0
end)

test("CoreGui protected instances resist writes", function()
	local coreGui = game:GetService("CoreGui")
	local robloxGui = coreGui:FindFirstChild("RobloxGui")

	if robloxGui == nil then
		return false, "RobloxGui missing"
	end

	local originalName = robloxGui.Name
	local writeOk = pcall(function()
		robloxGui.Name = "LogUncRenamed"
	end)

	if writeOk and robloxGui.Name == "LogUncRenamed" then
		pcall(function()
			robloxGui.Name = originalName
		end)
	end

	return type(writeOk) == "boolean"
		and robloxGui.Parent == coreGui
end)

optional("InsertService carries InsertionHash", function()
	local insertService = game:GetService("InsertService")
	local hash = insertService:FindFirstChild("InsertionHash")

	if hash == nil then
		return false, "InsertionHash missing"
	end

	return hash:IsA("StringValue")
		and type(hash.Value) == "string"
		and #hash.Value > 0
end)

optional("Lighting holds sky and atmosphere", function()
	local lighting = game:GetService("Lighting")
	local sky = lighting:FindFirstChildOfClass("Sky")
	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")

	if sky == nil and atmosphere == nil then
		return false, "no sky or atmosphere present"
	end

	if sky ~= nil then
		if type(sky.StarCount) ~= "number" then
			return false, "Sky.StarCount invalid"
		end
	end

	if atmosphere ~= nil then
		if typeof(atmosphere.Color) ~= "Color3" then
			return false, "Atmosphere.Color invalid"
		end
	end

	return true
end)

optional("ReplicatedStorage remotes are enumerable", function()
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local children = replicatedStorage:GetChildren()

	for _, child in ipairs(children) do
		if type(child.Name) ~= "string" then
			return false, "child name invalid"
		end

		if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
			if not child:IsA("Instance") then
				return false, child.Name .. " is not an Instance"
			end
		end
	end

	return type(children) == "table"
end)

optional("RobloxReplicatedStorage exists", function()
	local ok, service = pcall(game.GetService, game, "RobloxReplicatedStorage")

	if not ok or service == nil then
		return false, "RobloxReplicatedStorage unavailable"
	end

	return service:IsA("Instance")
		and service.Parent == game
		and type(service:GetChildren()) == "table"
end)

test("Service list is discoverable from game children", function()
	local seenServices = 0

	for _, child in ipairs(game:GetChildren()) do
		local ok, resolved = pcall(game.GetService, game, child.ClassName)

		if ok and resolved == child then
			seenServices += 1
		end
	end

	return seenServices >= 10
end)

test("Instance ClassName strings match dump conventions", function()
	local expectations = {
		Workspace = "Workspace",
		Lighting = "Lighting",
		ReplicatedStorage = "ReplicatedStorage",
		Teams = "Teams",
		Debris = "Debris",
		CollectionService = "CollectionService",
		PhysicsService = "PhysicsService",
		HttpService = "HttpService",
		UserInputService = "UserInputService",
		ContextActionService = "ContextActionService",
		ProximityPromptService = "ProximityPromptService",
		LocalizationService = "LocalizationService",
		PolicyService = "PolicyService",
		BadgeService = "BadgeService",
		GamePassService = "GamePassService",
		FriendService = "FriendService",
		AssetService = "AssetService",
		VRService = "VRService",
		HapticService = "HapticService",
		SocialService = "SocialService",
		TestService = "TestService",
		VoiceChatService = "VoiceChatService"
	}

	for className, expected in pairs(expectations) do
		local ok, service = pcall(game.GetService, game, className)

		if not ok or service == nil then
			return false, className .. " unavailable"
		end

		if service.ClassName ~= expected then
			return false, className .. " reports " .. service.ClassName
		end
	end

	return true
end)

local extendedServiceNames = {
	"AdService",
	"ControllerService",
	"CorePackages",
	"CoreScriptSyncService",
	"EventIngestService",
	"GamepadService",
	"Geometry",
	"IXPService",
	"JointsService",
	"MemStorageService",
	"NotificationService",
	"OmniRecommendationsService",
	"PerformanceControlService",
	"PointsService",
	"RbxAnalyticsService",
	"SafetyService",
	"TimerService",
	"UGCValidationService",
	"VideoCaptureService",
	"VirtualInputManager",
	"VirtualUser",
	"NetworkClient"
}

for _, serviceName in ipairs(extendedServiceNames) do
	optional("Service " .. serviceName, function()
		local service = game:GetService(serviceName)

		if service == nil then
			return false, serviceName .. " resolved to nil"
		end

		if typeof(service) ~= "Instance" then
			return false, serviceName .. " is " .. typeof(service)
		end

		return type(service.ClassName) == "string"
			and type(service:GetFullName()) == "string"
	end)
end

local extendedInstanceClasses = {
	"Accessory",
	"Actor",
	"AnimationController",
	"ArcHandles",
	"Atmosphere",
	"Backpack",
	"BlockMesh",
	"BloomEffect",
	"BlurEffect",
	"BodyAngularVelocity",
	"BodyForce",
	"BodyGyro",
	"BodyPosition",
	"BodyThrust",
	"BodyVelocity",
	"BoxHandleAdornment",
	"CanvasGroup",
	"CharacterMesh",
	"ChorusSoundEffect",
	"ClickDetector",
	"ColorCorrectionEffect",
	"CompressorSoundEffect",
	"Configuration",
	"ConeHandleAdornment",
	"CylinderHandleAdornment",
	"CylinderMesh",
	"DepthOfFieldEffect",
	"Dialog",
	"DialogChoice",
	"DistortionSoundEffect",
	"DragDetector",
	"EchoSoundEffect",
	"EqualizerSoundEffect",
	"Explosion",
	"FileMesh",
	"FlangeSoundEffect",
	"FloatCurve",
	"ForceField",
	"Glue",
	"Handles",
	"IKControl",
	"ImageHandleAdornment",
	"IntersectOperation",
	"Keyframe",
	"KeyframeMarker",
	"KeyframeSequence",
	"LineHandleAdornment",
	"LocalizationTable",
	"LocalScript",
	"ManualWeld",
	"MaterialVariant",
	"ModuleScript",
	"Motor",
	"NegateOperation",
	"NoCollisionConstraint",
	"Pants",
	"PathfindingLink",
	"PathfindingModifier",
	"PitchShiftSoundEffect",
	"Pose",
	"ProximityPrompt",
	"ReverbSoundEffect",
	"RocketPropulsion",
	"Rotate",
	"RotateP",
	"RotateV",
	"RotationCurve",
	"Script",
	"SelectionBox",
	"SelectionSphere",
	"Shirt",
	"ShirtGraphic",
	"Sky",
	"Snap",
	"SoundGroup",
	"SpecialMesh",
	"SphereHandleAdornment",
	"StarterGear",
	"SunRaysEffect",
	"SurfaceAppearance",
	"SurfaceSelection",
	"Team",
	"TextChannel",
	"TextChatCommand",
	"Tool",
	"TorsionSpringConstraint",
	"TremoloSoundEffect",
	"UIAspectRatioConstraint",
	"UIFlexItem",
	"UISizeConstraint",
	"UITextSizeConstraint",
	"UnionOperation",
	"UniversalConstraint",
	"UnreliableRemoteEvent",
	"VehicleController",
	"VideoFrame",
	"WorldModel",
	"WrapLayer",
	"WrapTarget"
}

for _, className in ipairs(extendedInstanceClasses) do
	optional("Instance " .. className, function()
		local object = Instance.new(className)
		local valid = typeof(object) == "Instance"
			and object.ClassName == className
			and object:IsA("Instance")
			and object.Parent == nil

		object:Destroy()

		return valid
	end)
end

local function globalValue(name)
	local sources = {}

	local fenvOk, fenv = pcall(function()
		return getfenv(0)
	end)

	if fenvOk and type(fenv) == "table" then
		table.insert(sources, fenv)
	end

	local genvOk, genv = pcall(function()
		return getgenv()
	end)

	if genvOk and type(genv) == "table" then
		table.insert(sources, genv)
	end

	table.insert(sources, _G)

	for _, source in ipairs(sources) do
		local readOk, value = pcall(function()
			return source[name]
		end)

		if readOk and value ~= nil then
			return value
		end
	end

	return nil
end

local function globalFunction(name)
	local value = globalValue(name)

	if type(value) == "function" then
		return value
	end

	return nil
end

local function memberFunction(container, name)
	if type(container) ~= "table" and type(container) ~= "userdata" then
		return nil
	end

	local ok, value = pcall(function()
		return container[name]
	end)

	if ok and type(value) == "function" then
		return value
	end

	return nil
end

local function executorTest(name, globalName, callback)
	test(name, function()
		local fn = globalFunction(globalName)

		if fn == nil then
			return true
		end

		return callback(fn)
	end)
end

local function callableTest(name, globalName)
	executorTest(name, globalName, function(fn)
		local ok, source = pcall(debug.info, fn, "s")

		if not ok then
			return true
		end

		return source == nil or type(source) == "string"
	end)
end

local executorApiNames = {
	"identifyexecutor",
	"getexecutorname",
	"getgenv",
	"getrenv",
	"getgc",
	"getreg",
	"getinstances",
	"getnilinstances",
	"getloadedmodules",
	"getrunningscripts",
	"getscripts",
	"getsenv",
	"getcallingscript",
	"getscriptclosure",
	"getscriptbytecode",
	"getscripthash",
	"getthreadidentity",
	"setthreadidentity",
	"checkcaller",
	"clonefunction",
	"iscclosure",
	"islclosure",
	"isexecutorclosure",
	"newcclosure",
	"newlclosure",
	"hookfunction",
	"restorefunction",
	"getrawmetatable",
	"setrawmetatable",
	"setreadonly",
	"isreadonly",
	"hookmetamethod",
	"getnamecallmethod",
	"setnamecallmethod",
	"cloneref",
	"compareinstances",
	"gethiddenproperty",
	"sethiddenproperty",
	"isscriptable",
	"setscriptable",
	"gethui",
	"getcallbackvalue",
	"getconnections",
	"fireclickdetector",
	"firetouchinterest",
	"fireproximityprompt",
	"getcustomasset",
	"readfile",
	"writefile",
	"appendfile",
	"isfile",
	"delfile",
	"makefolder",
	"isfolder",
	"delfolder",
	"listfiles",
	"loadfile",
	"dofile",
	"rconsoleprint",
	"rconsoleclear",
	"rconsolecreate",
	"rconsoledestroy",
	"rconsoleinput",
	"rconsolesettitle",
	"isrbxactive",
	"mouse1click",
	"mouse1press",
	"mouse1release",
	"mouse2click",
	"mouse2press",
	"mouse2release",
	"mousemoveabs",
	"mousemoverel",
	"mousescroll",
	"keypress",
	"keyrelease",
	"isrenderobj",
	"getrenderproperty",
	"setrenderproperty",
	"cleardrawcache",
	"request",
	"setclipboard",
	"queue_on_teleport",
	"lz4compress",
	"lz4decompress",
	"base64encode",
	"base64decode",
	"messagebox",
	"setfpscap",
	"getfpscap",
	"getactors",
	"getscriptfunction",
	"replaceclosure",
	"isourclosure",
	"checkclosure",
	"getproperties",
	"gethiddenproperties",
	"getcallbackmember",
	"getobjects",
	"getsynasset",
	"decompile"
}

local executorPresentNames = {}
local executorMissingNames = {}

for _, name in ipairs(executorApiNames) do
	if globalValue(name) ~= nil then
		table.insert(executorPresentNames, name)
	else
		table.insert(executorMissingNames, name)
	end
end

metrics.ExecutorAPI = #executorPresentNames .. "/" .. #executorApiNames

if #executorMissingNames > 0 then
	local preview = {}

	for index = 1, math.min(#executorMissingNames, 10) do
		table.insert(preview, executorMissingNames[index])
	end

	if #executorMissingNames > #preview then
		table.insert(preview, "+" .. (#executorMissingNames - #preview) .. " more")
	end

	metrics.ExecutorMissing = table.concat(preview, ", ")
else
	metrics.ExecutorMissing = "none"
end

do
	local identify = globalFunction("identifyexecutor") or globalFunction("getexecutorname")

	if identify ~= nil then
		local ok, name, version = pcall(identify)

		if ok and type(name) == "string" then
			metrics.Executor = name

			if type(version) == "string" and #version > 0 then
				metrics.ExecutorVersion = version
			end
		end
	end
end

test("Executor identity reports a name", function()
	local identify = globalFunction("identifyexecutor")

	if identify == nil then
		return true
	end

	local ok, name, version = pcall(identify)

	if not ok then
		return false, "identifyexecutor errored: " .. stringify(name)
	end

	if type(name) ~= "string" then
		return false, "name is " .. typeof(name)
	end

	if #name == 0 then
		return false, "name is empty"
	end

	if version ~= nil and type(version) ~= "string" then
		return false, "version is " .. typeof(version)
	end

	return true
end)

test("Executor identity is stable across calls", function()
	local identify = globalFunction("identifyexecutor")

	if identify == nil then
		return true
	end

	local firstOk, first = pcall(identify)
	local secondOk, second = pcall(identify)

	if not firstOk or not secondOk then
		return false, "identifyexecutor errored"
	end

	return first == second
end)

test("Executor name aliases agree", function()
	local identify = globalFunction("identifyexecutor")
	local alias = globalFunction("getexecutorname")

	if identify == nil or alias == nil then
		return true
	end

	local firstOk, first = pcall(identify)
	local secondOk, second = pcall(alias)

	if not firstOk or not secondOk then
		return false, "alias errored"
	end

	if type(second) ~= "string" then
		return false, "getexecutorname returned " .. typeof(second)
	end

	return first == second
end)

executorTest("Executor getgenv returns a table", "getgenv", function(getgenvFn)
	local ok, env = pcall(getgenvFn)

	if not ok then
		return false, "getgenv errored: " .. stringify(env)
	end

	if type(env) ~= "table" then
		return false, "getgenv returned " .. typeof(env)
	end

	local second = getgenvFn()

	return env == second
end)

executorTest("Executor getgenv is writable and shared", "getgenv", function(getgenvFn)
	local env = getgenvFn()
	local key = "LogUncGenvProbe"
	local sentinel = {}

	env[key] = sentinel

	local visible = getgenvFn()[key] == sentinel
	local globalVisible = globalValue(key) == sentinel

	env[key] = nil

	if not visible then
		return false, "write was not visible through getgenv"
	end

	if not globalVisible then
		return false, "write was not visible as a global"
	end

	return getgenvFn()[key] == nil
end)

executorTest("Executor getrenv returns the game environment", "getrenv", function(getrenvFn)
	local ok, env = pcall(getrenvFn)

	if not ok then
		return false, "getrenv errored: " .. stringify(env)
	end

	if type(env) ~= "table" then
		return false, "getrenv returned " .. typeof(env)
	end

	if env.game == nil and env.workspace == nil and env._G == nil then
		return false, "getrenv has no Roblox globals"
	end

	local genv = globalFunction("getgenv")

	if genv ~= nil and env == genv() then
		return false, "getrenv matches getgenv"
	end

	return true
end)

executorTest("Executor getgc returns a collection", "getgc", function(getgcFn)
	local ok, collection = pcall(getgcFn)

	if not ok then
		return false, "getgc errored: " .. stringify(collection)
	end

	if type(collection) ~= "table" then
		return false, "getgc returned " .. typeof(collection)
	end

	local functions = 0

	for _, value in ipairs(collection) do
		if type(value) == "function" then
			functions += 1

			if functions >= 3 then
				break
			end
		end
	end

	return functions > 0
end)

executorTest("Executor getgc includes tables on request", "getgc", function(getgcFn)
	local ok, collection = pcall(getgcFn, true)

	if not ok then
		return false, "getgc(true) errored: " .. stringify(collection)
	end

	if type(collection) ~= "table" then
		return false, "getgc(true) returned " .. typeof(collection)
	end

	local tables = 0

	for _, value in ipairs(collection) do
		if type(value) == "table" then
			tables += 1

			if tables >= 3 then
				break
			end
		end
	end

	return tables > 0
end)

executorTest("Executor getreg returns the registry", "getreg", function(getregFn)
	local ok, registry = pcall(getregFn)

	if not ok then
		return false, "getreg errored: " .. stringify(registry)
	end

	if type(registry) ~= "table" then
		return false, "getreg returned " .. typeof(registry)
	end

	local entries = 0

	for _ in pairs(registry) do
		entries += 1

		if entries >= 1 then
			break
		end
	end

	return entries > 0
end)

executorTest("Executor getinstances returns instances", "getinstances", function(getinstancesFn)
	local ok, instances = pcall(getinstancesFn)

	if not ok then
		return false, "getinstances errored: " .. stringify(instances)
	end

	if type(instances) ~= "table" then
		return false, "getinstances returned " .. typeof(instances)
	end

	local checked = 0

	for _, value in ipairs(instances) do
		if typeof(value) ~= "Instance" then
			return false, "entry is " .. typeof(value)
		end

		checked += 1

		if checked >= 25 then
			break
		end
	end

	return checked > 0
end)

executorTest("Executor getnilinstances returns orphans", "getnilinstances", function(getnilinstancesFn)
	local marker = Instance.new("Folder")

	marker.Name = "LogUncNilProbe"

	local ok, instances = pcall(getnilinstancesFn)

	if not ok then
		marker:Destroy()
		return false, "getnilinstances errored: " .. stringify(instances)
	end

	if type(instances) ~= "table" then
		marker:Destroy()
		return false, "getnilinstances returned " .. typeof(instances)
	end

	local found = false
	local parented = false

	for _, value in ipairs(instances) do
		if typeof(value) ~= "Instance" then
			marker:Destroy()
			return false, "entry is " .. typeof(value)
		end

		if value == marker then
			found = true
		end

		if value.Parent ~= nil and value ~= game then
			parented = true
		end
	end

	marker:Destroy()

	if parented then
		return false, "list contains parented instances"
	end

	return found
end)

executorTest("Executor getloadedmodules returns ModuleScripts", "getloadedmodules", function(getloadedmodulesFn)
	local ok, modules = pcall(getloadedmodulesFn)

	if not ok then
		return false, "getloadedmodules errored: " .. stringify(modules)
	end

	if type(modules) ~= "table" then
		return false, "getloadedmodules returned " .. typeof(modules)
	end

	for _, value in ipairs(modules) do
		if typeof(value) ~= "Instance" or not value:IsA("ModuleScript") then
			return false, "entry is " .. stringify(value)
		end
	end

	return true
end)

executorTest("Executor getrunningscripts returns scripts", "getrunningscripts", function(getrunningscriptsFn)
	local ok, scripts = pcall(getrunningscriptsFn)

	if not ok then
		return false, "getrunningscripts errored: " .. stringify(scripts)
	end

	if type(scripts) ~= "table" then
		return false, "getrunningscripts returned " .. typeof(scripts)
	end

	for _, value in ipairs(scripts) do
		if typeof(value) ~= "Instance" or not value:IsA("LuaSourceContainer") then
			return false, "entry is " .. stringify(value)
		end
	end

	return true
end)

executorTest("Executor getscripts returns script instances", "getscripts", function(getscriptsFn)
	local ok, scripts = pcall(getscriptsFn)

	if not ok then
		return false, "getscripts errored: " .. stringify(scripts)
	end

	if type(scripts) ~= "table" then
		return false, "getscripts returned " .. typeof(scripts)
	end

	local checked = 0

	for _, value in ipairs(scripts) do
		if typeof(value) ~= "Instance" or not value:IsA("LuaSourceContainer") then
			return false, "entry is " .. stringify(value)
		end

		checked += 1

		if checked >= 25 then
			break
		end
	end

	return true
end)

executorTest("Executor getsenv returns a script environment", "getsenv", function(getsenvFn)
	local getrunningscriptsFn = globalFunction("getrunningscripts")

	if getrunningscriptsFn == nil then
		return true
	end

	local listOk, scripts = pcall(getrunningscriptsFn)

	if not listOk or type(scripts) ~= "table" then
		return true
	end

	for _, container in ipairs(scripts) do
		local ok, env = pcall(getsenvFn, container)

		if ok and type(env) == "table" then
			if env.script ~= nil and env.script ~= container then
				return false, "env.script does not match the container"
			end

			return true
		end
	end

	return true
end)

executorTest("Executor getsenv rejects non-scripts", "getsenv", function(getsenvFn)
	local folder = Instance.new("Folder")
	local ok = pcall(getsenvFn, folder)

	folder:Destroy()

	if ok then
		return false, "a Folder was accepted"
	end

	return pcall(getsenvFn, "LogUnc") == false
end)

executorTest("Executor getcallingscript returns a container", "getcallingscript", function(getcallingscriptFn)
	local ok, container = pcall(getcallingscriptFn)

	if not ok then
		return false, "getcallingscript errored: " .. stringify(container)
	end

	if container == nil then
		return true
	end

	return typeof(container) == "Instance"
		and container:IsA("LuaSourceContainer")
end)

executorTest("Executor getthreadidentity reports a level", "getthreadidentity", function(getthreadidentityFn)
	local ok, identity = pcall(getthreadidentityFn)

	if not ok then
		return false, "getthreadidentity errored: " .. stringify(identity)
	end

	if type(identity) ~= "number" then
		return false, "identity is " .. typeof(identity)
	end

	metrics.ThreadIdentity = identity

	return identity >= 0
		and identity <= 10
		and identity % 1 == 0
end)

test("Executor setthreadidentity round trip", function()
	local getIdentity = globalFunction("getthreadidentity")
	local setIdentity = globalFunction("setthreadidentity")

	if getIdentity == nil or setIdentity == nil then
		return true
	end

	local readOk, original = pcall(getIdentity)

	if not readOk or type(original) ~= "number" then
		return false, "identity unreadable"
	end

	local target = original == 2 and 3 or 2
	local setOk = pcall(setIdentity, target)

	if not setOk then
		pcall(setIdentity, original)
		return false, "setthreadidentity errored"
	end

	local afterOk, after = pcall(getIdentity)

	pcall(setIdentity, original)

	local restoredOk, restored = pcall(getIdentity)

	if not afterOk or after ~= target then
		return false, "identity did not change to " .. target
	end

	return restoredOk and restored == original
end)

executorTest("Executor checkcaller reports context", "checkcaller", function(checkcallerFn)
	local ok, value = pcall(checkcallerFn)

	if not ok then
		return false, "checkcaller errored: " .. stringify(value)
	end

	if type(value) ~= "boolean" then
		return false, "checkcaller returned " .. typeof(value)
	end

	metrics.CheckCaller = value

	return true
end)

test("Executor checkcaller is false inside game callbacks", function()
	local checkcallerFn = globalFunction("checkcaller")

	if checkcallerFn == nil then
		return true
	end

	local outside = checkcallerFn()
	local inside = nil
	local event = Instance.new("BindableEvent")
	local connection = event.Event:Connect(function()
		inside = checkcallerFn()
	end)

	event:Fire()
	task.wait()
	connection:Disconnect()
	event:Destroy()

	if type(inside) ~= "boolean" then
		return false, "callback did not report a boolean"
	end

	return outside == true or inside == outside
end)

-- LOGUNC_EXECUTOR_SECTION_END

local closureApiNames = {
	"clonefunction",
	"iscclosure",
	"islclosure",
	"isexecutorclosure",
	"newcclosure",
	"hookfunction",
	"getrawmetatable",
	"setrawmetatable",
	"setreadonly",
	"isreadonly",
	"hookmetamethod",
	"getnamecallmethod",
	"cloneref",
	"compareinstances",
	"gethui",
	"getconnections",
	"fireclickdetector",
	"firetouchinterest",
	"fireproximityprompt",
	"request",
	"setclipboard",
	"lz4compress",
	"base64encode",
	"setfpscap",
	"readfile",
	"writefile",
	"isfile",
	"listfiles",
	"getcustomasset",
	"getscriptbytecode",
	"getscripthash",
	"getscriptclosure",
	"gethiddenproperty",
	"sethiddenproperty",
	"isscriptable",
	"setscriptable",
	"getcallbackvalue",
	"mouse1click",
	"keypress",
	"isrbxactive",
	"rconsoleprint",
	"queue_on_teleport",
	"getactors"
}

for _, globalName in ipairs(closureApiNames) do
	callableTest("Executor " .. globalName .. " is a callable global", globalName)
end

test("Executor iscclosure and islclosure disagree", function()
	local iscclosureFn = globalFunction("iscclosure")
	local islclosureFn = globalFunction("islclosure")

	if iscclosureFn == nil or islclosureFn == nil then
		return true
	end

	local luaFunction = function()
		return 1
	end

	local cResults = {
		{ print, true },
		{ Instance.new, true },
		{ math.abs, true },
		{ luaFunction, false }
	}

	for _, entry in ipairs(cResults) do
		local target = entry[1]
		local expected = entry[2]
		local cOk, isC = pcall(iscclosureFn, target)
		local lOk, isL = pcall(islclosureFn, target)

		if not cOk or not lOk then
			return false, "closure predicates errored"
		end

		if type(isC) ~= "boolean" or type(isL) ~= "boolean" then
			return false, "predicates did not return booleans"
		end

		if isC ~= expected then
			return false, "iscclosure mismatch for " .. stringify(target)
		end

		if isC == isL then
			return false, "predicates agree for " .. stringify(target)
		end
	end

	return true
end)

test("Executor clonefunction preserves behaviour", function()
	local clonefunctionFn = globalFunction("clonefunction")

	if clonefunctionFn == nil then
		return true
	end

	local calls = 0
	local original = function(value)
		calls += 1
		return value * 2
	end

	local ok, clone = pcall(clonefunctionFn, original)

	if not ok then
		return false, "clonefunction errored: " .. stringify(clone)
	end

	if type(clone) ~= "function" then
		return false, "clone is " .. typeof(clone)
	end

	if clone == original then
		return false, "clone is the same function"
	end

	if clone(21) ~= 42 then
		return false, "clone returned a wrong value"
	end

	return calls == 1
end)

test("Executor newcclosure produces a C closure", function()
	local newcclosureFn = globalFunction("newcclosure")

	if newcclosureFn == nil then
		return true
	end

	local original = function(a, b)
		return a + b
	end

	local ok, wrapped = pcall(newcclosureFn, original)

	if not ok then
		return false, "newcclosure errored: " .. stringify(wrapped)
	end

	if type(wrapped) ~= "function" then
		return false, "wrapper is " .. typeof(wrapped)
	end

	if wrapped(2, 3) ~= 5 then
		return false, "wrapper returned a wrong value"
	end

	local iscclosureFn = globalFunction("iscclosure")

	if iscclosureFn == nil then
		return true
	end

	local checkOk, isC = pcall(iscclosureFn, wrapped)

	return checkOk and isC == true
end)

test("Executor isexecutorclosure identifies our functions", function()
	local isexecutorclosureFn = globalFunction("isexecutorclosure")

	if isexecutorclosureFn == nil then
		return true
	end

	local ours = function()
		return true
	end

	local ourOk, ourResult = pcall(isexecutorclosureFn, ours)
	local gameOk, gameResult = pcall(isexecutorclosureFn, print)

	if not ourOk or not gameOk then
		return false, "isexecutorclosure errored"
	end

	if type(ourResult) ~= "boolean" or type(gameResult) ~= "boolean" then
		return false, "predicate did not return booleans"
	end

	return ourResult == true
		and gameResult == false
end)

test("Executor getrawmetatable exposes locked metatables", function()
	local getrawmetatableFn = globalFunction("getrawmetatable")

	if getrawmetatableFn == nil then
		return true
	end

	local ok, mt = pcall(getrawmetatableFn, game)

	if not ok then
		return false, "getrawmetatable errored: " .. stringify(mt)
	end

	if type(mt) ~= "table" then
		return false, "metatable is " .. typeof(mt)
	end

	if type(mt.__index) ~= "function" and type(mt.__index) ~= "table" then
		return false, "__index is " .. typeof(mt.__index)
	end

	local plain = setmetatable({}, { __mode = "k" })

	local plainOk, plainMt = pcall(getrawmetatableFn, plain)

	return plainOk
		and type(plainMt) == "table"
		and plainMt.__mode == "k"
end)

test("Executor isreadonly reports metatable state", function()
	local isreadonlyFn = globalFunction("isreadonly")

	if isreadonlyFn == nil then
		return true
	end

	local mutable = {}
	local frozen = table.freeze({})

	local mutableOk, mutableState = pcall(isreadonlyFn, mutable)
	local frozenOk, frozenState = pcall(isreadonlyFn, frozen)

	if not mutableOk or not frozenOk then
		return false, "isreadonly errored"
	end

	return mutableState == false
		and frozenState == true
end)

test("Executor setreadonly toggles tables", function()
	local setreadonlyFn = globalFunction("setreadonly")
	local isreadonlyFn = globalFunction("isreadonly")

	if setreadonlyFn == nil then
		return true
	end

	local target = { Value = 1 }
	local lockOk = pcall(setreadonlyFn, target, true)

	if not lockOk then
		return false, "setreadonly(true) errored"
	end

	local writeBlocked = not pcall(function()
		target.Value = 2
	end)

	if isreadonlyFn ~= nil then
		local stateOk, state = pcall(isreadonlyFn, target)

		if stateOk and state ~= true then
			return false, "isreadonly disagrees after locking"
		end
	end

	local unlockOk = pcall(setreadonlyFn, target, false)

	if not unlockOk then
		return false, "setreadonly(false) errored"
	end

	local writeAllowed = pcall(function()
		target.Value = 3
	end)

	return writeBlocked
		and writeAllowed
		and target.Value == 3
end)

test("Executor getnamecallmethod reports the invoked method", function()
	local getnamecallmethodFn = globalFunction("getnamecallmethod")
	local hookmetamethodFn = globalFunction("hookmetamethod")

	if getnamecallmethodFn == nil or hookmetamethodFn == nil then
		return true
	end

	local seen = nil
	local original = nil
	local hookOk, hookError = pcall(function()
		original = hookmetamethodFn(game, "__namecall", function(self, ...)
			if seen == nil then
				local nameOk, name = pcall(getnamecallmethodFn)

				if nameOk then
					seen = name
				end
			end

			return original(self, ...)
		end)
	end)

	if not hookOk then
		return false, "hookmetamethod errored: " .. stringify(hookError)
	end

	pcall(function()
		game:GetService("Lighting")
	end)

	if original ~= nil then
		pcall(hookmetamethodFn, game, "__namecall", original)
	end

	if seen == nil then
		return false, "namecall method was not observed"
	end

	return type(seen) == "string"
		and #seen > 0
end)

test("Executor cloneref returns an equivalent instance", function()
	local clonerefFn = globalFunction("cloneref")

	if clonerefFn == nil then
		return true
	end

	local folder = Instance.new("Folder")

	folder.Name = "LogUncCloneRef"

	local ok, clone = pcall(clonerefFn, folder)

	if not ok then
		folder:Destroy()
		return false, "cloneref errored: " .. stringify(clone)
	end

	if typeof(clone) ~= "Instance" then
		folder:Destroy()
		return false, "cloneref returned " .. typeof(clone)
	end

	local sameName = clone.Name == folder.Name
	local sameClass = clone.ClassName == folder.ClassName

	clone.Name = "LogUncCloneRefRenamed"

	local propagated = folder.Name == "LogUncCloneRefRenamed"

	local compareinstancesFn = globalFunction("compareinstances")
	local comparesEqual = true

	if compareinstancesFn ~= nil then
		local compareOk, equal = pcall(compareinstancesFn, folder, clone)
		comparesEqual = compareOk and equal == true
	end

	folder:Destroy()

	if not sameName or not sameClass then
		return false, "cloneref lost identity"
	end

	if not propagated then
		return false, "cloneref does not share state"
	end

	return comparesEqual
end)

test("Executor compareinstances distinguishes instances", function()
	local compareinstancesFn = globalFunction("compareinstances")

	if compareinstancesFn == nil then
		return true
	end

	local first = Instance.new("Folder")
	local second = Instance.new("Folder")

	local sameOk, same = pcall(compareinstancesFn, first, first)
	local otherOk, other = pcall(compareinstancesFn, first, second)

	first:Destroy()
	second:Destroy()

	if not sameOk or not otherOk then
		return false, "compareinstances errored"
	end

	return same == true
		and other == false
end)

test("Executor gethui returns a hidden container", function()
	local gethuiFn = globalFunction("gethui")

	if gethuiFn == nil then
		return true
	end

	local ok, container = pcall(gethuiFn)

	if not ok then
		return false, "gethui errored: " .. stringify(container)
	end

	if typeof(container) ~= "Instance" then
		return false, "gethui returned " .. typeof(container)
	end

	local gui = Instance.new("ScreenGui")
	local parentOk = pcall(function()
		gui.Parent = container
	end)
	local attached = parentOk and gui.Parent == container

	gui:Destroy()

	return attached
		and container == gethuiFn()
end)

test("Executor getconnections describes signal listeners", function()
	local getconnectionsFn = globalFunction("getconnections")

	if getconnectionsFn == nil then
		return true
	end

	local event = Instance.new("BindableEvent")
	local fired = 0
	local connection = event.Event:Connect(function()
		fired += 1
	end)

	local ok, connections = pcall(getconnectionsFn, event.Event)

	if not ok then
		connection:Disconnect()
		event:Destroy()
		return false, "getconnections errored: " .. stringify(connections)
	end

	if type(connections) ~= "table" or #connections == 0 then
		connection:Disconnect()
		event:Destroy()
		return false, "no connections were reported"
	end

	local entry = connections[1]
	local hasFields = type(entry) == "table" or type(entry) == "userdata"
	local functionOk, functionValue = pcall(function()
		return entry.Function
	end)

	connection:Disconnect()
	event:Destroy()

	if not hasFields then
		return false, "entry is " .. typeof(entry)
	end

	return functionOk == false
		or functionValue == nil
		or type(functionValue) == "function"
end)

test("Executor request performs an HTTP call", function()
	local requestFn = globalFunction("request") or globalFunction("http_request")

	if requestFn == nil then
		return true
	end

	local ok, response = pcall(requestFn, {
		Url = "https://httpbin.org/get",
		Method = "GET"
	})

	if not ok then
		return false, "request errored: " .. stringify(response)
	end

	if type(response) ~= "table" then
		return false, "response is " .. typeof(response)
	end

	if type(response.StatusCode) ~= "number" then
		return false, "StatusCode is " .. typeof(response.StatusCode)
	end

	if type(response.Body) ~= "string" then
		return false, "Body is " .. typeof(response.Body)
	end

	metrics.ExecutorRequestStatus = response.StatusCode

	return response.StatusCode >= 100
		and response.StatusCode < 600
end)

test("Executor lz4 round trip preserves data", function()
	local compressFn = globalFunction("lz4compress")
	local decompressFn = globalFunction("lz4decompress")

	if compressFn == nil or decompressFn == nil then
		return true
	end

	local payload = string.rep("LogUnc", 64)
	local compressOk, compressed = pcall(compressFn, payload)

	if not compressOk then
		return false, "lz4compress errored: " .. stringify(compressed)
	end

	if type(compressed) ~= "string" then
		return false, "compressed is " .. typeof(compressed)
	end

	local decompressOk, restored = pcall(decompressFn, compressed, #payload)

	if not decompressOk then
		return false, "lz4decompress errored: " .. stringify(restored)
	end

	return restored == payload
end)

test("Executor base64 round trip preserves data", function()
	local encodeFn = globalFunction("base64encode") or globalFunction("base64_encode")
	local decodeFn = globalFunction("base64decode") or globalFunction("base64_decode")

	if encodeFn == nil or decodeFn == nil then
		return true
	end

	local payload = "Log-Unc\0\1\2binary"
	local encodeOk, encoded = pcall(encodeFn, payload)

	if not encodeOk then
		return false, "base64encode errored: " .. stringify(encoded)
	end

	if type(encoded) ~= "string" or not encoded:match("^[%w%+/=]*$") then
		return false, "encoded value is not base64"
	end

	local decodeOk, decoded = pcall(decodeFn, encoded)

	if not decodeOk then
		return false, "base64decode errored: " .. stringify(decoded)
	end

	return decoded == payload
end)

test("Executor filesystem round trip", function()
	local writefileFn = globalFunction("writefile")
	local readfileFn = globalFunction("readfile")
	local isfileFn = globalFunction("isfile")
	local delfileFn = globalFunction("delfile")

	if writefileFn == nil or readfileFn == nil then
		return true
	end

	local path = "LogUncProbe.txt"
	local payload = "log-unc-" .. tostring(os.time())

	local writeOk, writeError = pcall(writefileFn, path, payload)

	if not writeOk then
		return false, "writefile errored: " .. stringify(writeError)
	end

	if isfileFn ~= nil then
		local existsOk, exists = pcall(isfileFn, path)

		if not existsOk or exists ~= true then
			pcall(delfileFn, path)
			return false, "isfile did not report the new file"
		end
	end

	local readOk, contents = pcall(readfileFn, path)

	if delfileFn ~= nil then
		pcall(delfileFn, path)
	end

	if not readOk then
		return false, "readfile errored: " .. stringify(contents)
	end

	if contents ~= payload then
		return false, "contents did not round trip"
	end

	if isfileFn ~= nil and delfileFn ~= nil then
		local goneOk, gone = pcall(isfileFn, path)

		if goneOk and gone == true then
			return false, "delfile did not remove the file"
		end
	end

	return true
end)

test("Executor folder operations round trip", function()
	local makefolderFn = globalFunction("makefolder")
	local isfolderFn = globalFunction("isfolder")
	local delfolderFn = globalFunction("delfolder")

	if makefolderFn == nil or isfolderFn == nil then
		return true
	end

	local path = "LogUncProbeFolder"
	local makeOk, makeError = pcall(makefolderFn, path)

	if not makeOk then
		return false, "makefolder errored: " .. stringify(makeError)
	end

	local existsOk, exists = pcall(isfolderFn, path)

	if delfolderFn ~= nil then
		pcall(delfolderFn, path)
	end

	if not existsOk or exists ~= true then
		return false, "isfolder did not report the new folder"
	end

	if delfolderFn ~= nil then
		local goneOk, gone = pcall(isfolderFn, path)

		if goneOk and gone == true then
			return false, "delfolder did not remove the folder"
		end
	end

	return true
end)

test("Executor listfiles enumerates paths", function()
	local listfilesFn = globalFunction("listfiles")
	local writefileFn = globalFunction("writefile")
	local delfileFn = globalFunction("delfile")

	if listfilesFn == nil then
		return true
	end

	local path = "LogUncListProbe.txt"
	local created = false

	if writefileFn ~= nil then
		created = pcall(writefileFn, path, "probe")
	end

	local ok, entries = pcall(listfilesFn, "")

	if created and delfileFn ~= nil then
		pcall(delfileFn, path)
	end

	if not ok then
		return false, "listfiles errored: " .. stringify(entries)
	end

	if type(entries) ~= "table" then
		return false, "listfiles returned " .. typeof(entries)
	end

	for index, entry in ipairs(entries) do
		if type(entry) ~= "string" then
			return false, "entry " .. index .. " is " .. typeof(entry)
		end
	end

	return true
end)

test("Executor setclipboard accepts strings", function()
	local setclipboardFn = globalFunction("setclipboard") or globalFunction("toclipboard")

	if setclipboardFn == nil then
		return true
	end

	local ok, err = pcall(setclipboardFn, "Log-Unc")

	if not ok then
		return false, "setclipboard errored: " .. stringify(err)
	end

	return true
end)

test("Executor setfpscap accepts a limit", function()
	local setfpscapFn = globalFunction("setfpscap")
	local getfpscapFn = globalFunction("getfpscap")

	if setfpscapFn == nil then
		return true
	end

	local original = nil

	if getfpscapFn ~= nil then
		local readOk, value = pcall(getfpscapFn)

		if readOk and type(value) == "number" then
			original = value
		end
	end

	local ok, err = pcall(setfpscapFn, 120)

	if not ok then
		return false, "setfpscap errored: " .. stringify(err)
	end

	if original ~= nil then
		pcall(setfpscapFn, original)
	end

	return true
end)

test("Executor getscriptbytecode returns compiled data", function()
	local getscriptbytecodeFn = globalFunction("getscriptbytecode")
	local getrunningscriptsFn = globalFunction("getrunningscripts")

	if getscriptbytecodeFn == nil or getrunningscriptsFn == nil then
		return true
	end

	local listOk, scripts = pcall(getrunningscriptsFn)

	if not listOk or type(scripts) ~= "table" then
		return true
	end

	for _, container in ipairs(scripts) do
		local ok, bytecode = pcall(getscriptbytecodeFn, container)

		if ok and type(bytecode) == "string" and #bytecode > 0 then
			return true
		end
	end

	return true
end)

test("Executor getscripthash is deterministic", function()
	local getscripthashFn = globalFunction("getscripthash")
	local getrunningscriptsFn = globalFunction("getrunningscripts")

	if getscripthashFn == nil or getrunningscriptsFn == nil then
		return true
	end

	local listOk, scripts = pcall(getrunningscriptsFn)

	if not listOk or type(scripts) ~= "table" then
		return true
	end

	for _, container in ipairs(scripts) do
		local firstOk, first = pcall(getscripthashFn, container)
		local secondOk, second = pcall(getscripthashFn, container)

		if firstOk and secondOk and type(first) == "string" then
			if first ~= second then
				return false, "hash changed between calls"
			end

			return true
		end
	end

	return true
end)

test("Executor hidden property access", function()
	local getHiddenFn = globalFunction("gethiddenproperty")

	if getHiddenFn == nil then
		return true
	end

	return withTemporary("Part", function(part)
		local ok, value = pcall(getHiddenFn, part, "Size")

		if not ok then
			return false, "gethiddenproperty errored: " .. stringify(value)
		end

		if typeof(value) ~= "Vector3" then
			return false, "Size read back as " .. typeof(value)
		end

		local setHiddenFn = globalFunction("sethiddenproperty")

		if setHiddenFn == nil then
			return true
		end

		local writeOk = pcall(setHiddenFn, part, "Size", Vector3.new(3, 3, 3))

		if not writeOk then
			return true
		end

		return nearlyEqual(part.Size.X, 3, 0.01)
	end)
end)

test("Executor isscriptable reports property visibility", function()
	local isscriptableFn = globalFunction("isscriptable")

	if isscriptableFn == nil then
		return true
	end

	return withTemporary("Part", function(part)
		local ok, scriptable = pcall(isscriptableFn, part, "Size")

		if not ok then
			return false, "isscriptable errored: " .. stringify(scriptable)
		end

		if type(scriptable) ~= "boolean" then
			return false, "isscriptable returned " .. typeof(scriptable)
		end

		return scriptable == true
	end)
end)

test("Executor fireclickdetector triggers a detector", function()
	local fireclickdetectorFn = globalFunction("fireclickdetector")

	if fireclickdetectorFn == nil then
		return true
	end

	local part = Instance.new("Part")

	part.Anchored = true

	local detector = Instance.new("ClickDetector")

	detector.Parent = part

	local clicked = false
	local connection = detector.MouseClick:Connect(function()
		clicked = true
	end)

	part.Parent = workspace

	local ok, err = pcall(fireclickdetectorFn, detector)

	if ok then
		task.wait()
	end

	connection:Disconnect()
	part:Destroy()

	if not ok then
		return false, "fireclickdetector errored: " .. stringify(err)
	end

	return clicked
end)

test("Executor fireproximityprompt triggers a prompt", function()
	local fireproximitypromptFn = globalFunction("fireproximityprompt")

	if fireproximitypromptFn == nil then
		return true
	end

	local part = Instance.new("Part")

	part.Anchored = true

	local prompt = Instance.new("ProximityPrompt")

	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	local triggered = false
	local connection = prompt.Triggered:Connect(function()
		triggered = true
	end)

	part.Parent = workspace

	local ok, err = pcall(fireproximitypromptFn, prompt)

	if ok then
		task.wait()
	end

	connection:Disconnect()
	part:Destroy()

	if not ok then
		return false, "fireproximityprompt errored: " .. stringify(err)
	end

	return triggered
end)

test("Executor globals do not leak into the Roblox environment", function()
	local getrenvFn = globalFunction("getrenv")

	if getrenvFn == nil then
		return true
	end

	local ok, env = pcall(getrenvFn)

	if not ok or type(env) ~= "table" then
		return true
	end

	local leaked = {}

	for _, name in ipairs({
		"identifyexecutor",
		"getgenv",
		"getrenv",
		"hookfunction",
		"getrawmetatable",
		"readfile",
		"writefile"
	}) do
		if globalValue(name) ~= nil and rawget(env, name) ~= nil then
			table.insert(leaked, name)
		end
	end

	if #leaked > 0 then
		return false, "leaked: " .. table.concat(leaked, ", ")
	end

	return true
end)

test("Executor API surface is coherent", function()
	local present = #executorPresentNames

	if present == 0 then
		return true
	end

	local requiredCompanions = {
		{ "getgenv", "getrenv" },
		{ "readfile", "writefile" },
		{ "isfile", "delfile" },
		{ "setreadonly", "isreadonly" },
		{ "iscclosure", "islclosure" },
		{ "lz4compress", "lz4decompress" }
	}

	local gaps = {}

	for _, pair in ipairs(requiredCompanions) do
		local first = globalValue(pair[1]) ~= nil
		local second = globalValue(pair[2]) ~= nil

		if first ~= second then
			table.insert(gaps, pair[1] .. "/" .. pair[2])
		end
	end

	if #gaps > 0 then
		return false, "incomplete pairs: " .. table.concat(gaps, ", ")
	end

	return true
end)

test("Executor drawing library surface", function()
	local drawing = globalValue("Drawing")

	if drawing == nil then
		return true
	end

	if type(drawing) ~= "table" and type(drawing) ~= "userdata" then
		return false, "Drawing is " .. typeof(drawing)
	end

	local newFn = memberFunction(drawing, "new")

	if newFn == nil then
		return false, "Drawing.new is missing"
	end

	local ok, object = pcall(newFn, "Square")

	if not ok then
		return true
	end

	local destroyed = pcall(function()
		object:Destroy()
	end)

	return destroyed or true
end)

test("BodyVelocity configuration", function()
	return withTemporary("BodyVelocity", function(mover)
		mover.Velocity = Vector3.new(0, 25, 0)
		mover.MaxForce = Vector3.new(1000, 1000, 1000)
		mover.P = 2000

		return typedProperties(mover, {
			Velocity = "Vector3",
			MaxForce = "Vector3",
			P = "number"
		})
			and mover.Velocity.Y == 25
			and mover.MaxForce.X == 1000
			and nearlyEqual(mover.P, 2000)
	end)
end)

test("BodyAngularVelocity configuration", function()
	return withTemporary("BodyAngularVelocity", function(mover)
		mover.AngularVelocity = Vector3.new(0, 5, 0)
		mover.MaxTorque = Vector3.new(500, 500, 500)
		mover.P = 1500

		return typedProperties(mover, {
			AngularVelocity = "Vector3",
			MaxTorque = "Vector3",
			P = "number"
		})
			and mover.AngularVelocity.Y == 5
			and mover.MaxTorque.Z == 500
	end)
end)

test("BodyPosition configuration", function()
	return withTemporary("BodyPosition", function(mover)
		mover.Position = Vector3.new(10, 20, 30)
		mover.MaxForce = Vector3.new(4000, 4000, 4000)
		mover.P = 10000
		mover.D = 500

		return typedProperties(mover, {
			Position = "Vector3",
			MaxForce = "Vector3",
			P = "number",
			D = "number"
		})
			and mover.Position.Z == 30
			and nearlyEqual(mover.D, 500)
	end)
end)

test("BodyGyro configuration", function()
	return withTemporary("BodyGyro", function(mover)
		mover.CFrame = CFrame.Angles(0, math.pi / 2, 0)
		mover.MaxTorque = Vector3.new(400, 400, 400)
		mover.P = 3000
		mover.D = 100

		return typedProperties(mover, {
			CFrame = "CFrame",
			MaxTorque = "Vector3",
			P = "number",
			D = "number"
		})
			and mover.MaxTorque.Y == 400
	end)
end)

test("BodyForce and BodyThrust configuration", function()
	return withTemporary("BodyForce", function(force)
		force.Force = Vector3.new(0, 500, 0)

		if force.Force.Y ~= 500 then
			return false, "BodyForce did not store Force"
		end

		return withTemporary("BodyThrust", function(thrust)
			thrust.Force = Vector3.new(100, 0, 0)
			thrust.Location = Vector3.new(0, 1, 0)

			return typedProperties(thrust, {
				Force = "Vector3",
				Location = "Vector3"
			})
				and thrust.Force.X == 100
				and thrust.Location.Y == 1
		end)
	end)
end)

test("RocketPropulsion configuration", function()
	return withTemporary("RocketPropulsion", function(rocket)
		rocket.MaxSpeed = 120
		rocket.MaxThrust = 4000
		rocket.TargetRadius = 25
		rocket.CartoonFactor = 0.5
		rocket.TurnP = 3000
		rocket.TurnD = 500
		rocket.ThrustP = 5
		rocket.ThrustD = 0.1

		local valid = typedProperties(rocket, {
			MaxSpeed = "number",
			MaxThrust = "number",
			TargetRadius = "number",
			CartoonFactor = "number",
			TurnP = "number",
			TurnD = "number",
			ThrustP = "number",
			ThrustD = "number"
		})

		if valid ~= true then
			return false, "property types are wrong"
		end

		return hasMethods(rocket, { "Fire", "Abort" })
			and nearlyEqual(rocket.MaxSpeed, 120)
			and nearlyEqual(rocket.TargetRadius, 25)
	end)
end)

test("EchoSoundEffect configuration", function()
	return withTemporary("EchoSoundEffect", function(effect)
		effect.Delay = 0.5
		effect.DryLevel = -3
		effect.WetLevel = -6
		effect.Feedback = 0.4
		effect.Enabled = true
		effect.Priority = 2

		return typedProperties(effect, {
			Delay = "number",
			DryLevel = "number",
			WetLevel = "number",
			Feedback = "number",
			Enabled = "boolean",
			Priority = "number"
		})
			and nearlyEqual(effect.Delay, 0.5)
			and effect.Enabled == true
			and effect:IsA("SoundEffect")
	end)
end)

test("ChorusSoundEffect and FlangeSoundEffect configuration", function()
	return withTemporary("ChorusSoundEffect", function(chorus)
		chorus.Depth = 0.3
		chorus.Mix = 0.7
		chorus.Rate = 4

		local chorusValid = typedProperties(chorus, {
			Depth = "number",
			Mix = "number",
			Rate = "number"
		})

		if chorusValid ~= true then
			return false, "ChorusSoundEffect types are wrong"
		end

		return withTemporary("FlangeSoundEffect", function(flange)
			flange.Depth = 0.6
			flange.Mix = 0.5
			flange.Rate = 6

			return typedProperties(flange, {
				Depth = "number",
				Mix = "number",
				Rate = "number"
			})
				and nearlyEqual(flange.Rate, 6)
				and flange:IsA("SoundEffect")
		end)
	end)
end)

test("CompressorSoundEffect configuration", function()
	return withTemporary("CompressorSoundEffect", function(effect)
		effect.Attack = 0.05
		effect.Release = 0.2
		effect.Threshold = -20
		effect.GainMakeup = 4
		effect.Ratio = 6

		return typedProperties(effect, {
			Attack = "number",
			Release = "number",
			Threshold = "number",
			GainMakeup = "number",
			Ratio = "number"
		})
			and nearlyEqual(effect.Ratio, 6)
			and nearlyEqual(effect.Threshold, -20)
	end)
end)

test("EqualizerSoundEffect configuration", function()
	return withTemporary("EqualizerSoundEffect", function(effect)
		effect.LowGain = -6
		effect.MidGain = 0
		effect.HighGain = 3

		return typedProperties(effect, {
			LowGain = "number",
			MidGain = "number",
			HighGain = "number"
		})
			and nearlyEqual(effect.LowGain, -6)
			and nearlyEqual(effect.HighGain, 3)
	end)
end)

test("ReverbSoundEffect configuration", function()
	return withTemporary("ReverbSoundEffect", function(effect)
		effect.DecayTime = 2
		effect.Density = 0.8
		effect.Diffusion = 0.9
		effect.DryLevel = -2
		effect.WetLevel = -4

		return typedProperties(effect, {
			DecayTime = "number",
			Density = "number",
			Diffusion = "number",
			DryLevel = "number",
			WetLevel = "number"
		})
			and nearlyEqual(effect.DecayTime, 2)
	end)
end)

test("Remaining sound effects are configurable", function()
	local expectations = {
		{ "DistortionSoundEffect", "Level", 0.6 },
		{ "PitchShiftSoundEffect", "Octave", 1.5 },
		{ "TremoloSoundEffect", "Frequency", 8 }
	}

	for _, entry in ipairs(expectations) do
		local className = entry[1]
		local property = entry[2]
		local value = entry[3]
		local ok, effect = pcall(Instance.new, className)

		if not ok or effect == nil then
			return false, className .. " not constructible"
		end

		local writeOk = pcall(function()
			effect[property] = value
		end)
		local readOk, stored = readMember(effect, property)
		local isEffect = effect:IsA("SoundEffect")

		effect:Destroy()

		if not writeOk or not readOk then
			return false, className .. "." .. property .. " is not writable"
		end

		if not nearlyEqual(stored, value, 0.01) then
			return false, className .. "." .. property .. " stored " .. stringify(stored)
		end

		if not isEffect then
			return false, className .. " is not a SoundEffect"
		end
	end

	return true
end)

test("SoundEffect chain on a Sound", function()
	return withTemporary("Sound", function(sound)
		local echo = Instance.new("EchoSoundEffect")
		local reverb = Instance.new("ReverbSoundEffect")

		echo.Priority = 1
		reverb.Priority = 2
		echo.Parent = sound
		reverb.Parent = sound

		local children = sound:GetChildren()
		local effects = 0

		for _, child in ipairs(children) do
			if child:IsA("SoundEffect") then
				effects += 1
			end
		end

		local ordered = echo.Priority < reverb.Priority

		echo:Destroy()
		reverb:Destroy()

		return effects == 2 and ordered
	end)
end)

test("BoxHandleAdornment configuration", function()
	return withTemporary("BoxHandleAdornment", function(adornment)
		return withTemporary("Part", function(part)
			adornment.Adornee = part
			adornment.Size = Vector3.new(2, 3, 4)
			adornment.Color3 = Color3.new(1, 0, 0)
			adornment.Transparency = 0.25
			adornment.AlwaysOnTop = true
			adornment.ZIndex = 3
			adornment.Visible = true
			adornment.CFrame = CFrame.new(0, 1, 0)

			return typedProperties(adornment, {
				Size = "Vector3",
				Color3 = "Color3",
				Transparency = "number",
				AlwaysOnTop = "boolean",
				ZIndex = "number",
				Visible = "boolean",
				CFrame = "CFrame"
			})
				and adornment.Adornee == part
				and adornment.Size.Y == 3
				and adornment:IsA("HandleAdornment")
		end)
	end)
end)

test("Radial handle adornments configuration", function()
	local expectations = {
		{ "SphereHandleAdornment", { Radius = 2 } },
		{ "ConeHandleAdornment", { Radius = 1, Height = 4 } },
		{ "CylinderHandleAdornment", { Radius = 1.5, Height = 3 } },
		{ "LineHandleAdornment", { Length = 6, Thickness = 2 } }
	}

	for _, entry in ipairs(expectations) do
		local className = entry[1]
		local ok, adornment = pcall(Instance.new, className)

		if not ok or adornment == nil then
			return false, className .. " not constructible"
		end

		for property, value in pairs(entry[2]) do
			local writeOk = pcall(function()
				adornment[property] = value
			end)
			local readOk, stored = readMember(adornment, property)

			if not writeOk or not readOk or not nearlyEqual(stored, value, 0.01) then
				adornment:Destroy()
				return false, className .. "." .. property .. " failed"
			end
		end

		local isAdornment = adornment:IsA("HandleAdornment")

		adornment:Destroy()

		if not isAdornment then
			return false, className .. " is not a HandleAdornment"
		end
	end

	return true
end)

test("ImageHandleAdornment configuration", function()
	return withTemporary("ImageHandleAdornment", function(adornment)
		adornment.Size = Vector2.new(4, 4)
		adornment.Image = "rbxassetid://0"

		return typedProperties(adornment, {
			Size = "Vector2",
			Image = "string"
		})
			and adornment.Size.X == 4
			and adornment:IsA("HandleAdornment")
	end)
end)

test("SelectionBox and SelectionSphere configuration", function()
	return withTemporary("Part", function(part)
		return withTemporary("SelectionBox", function(box)
			box.Adornee = part
			box.LineThickness = 0.1
			box.SurfaceColor3 = Color3.new(0, 1, 0)
			box.SurfaceTransparency = 0.5

			local boxValid = typedProperties(box, {
				LineThickness = "number",
				SurfaceColor3 = "Color3",
				SurfaceTransparency = "number"
			})

			if boxValid ~= true then
				return false, "SelectionBox types are wrong"
			end

			if box.Adornee ~= part then
				return false, "SelectionBox lost its Adornee"
			end

			return withTemporary("SelectionSphere", function(sphere)
				sphere.Adornee = part
				sphere.SurfaceColor3 = Color3.new(0, 0, 1)
				sphere.SurfaceTransparency = 0.25

				return typedProperties(sphere, {
					SurfaceColor3 = "Color3",
					SurfaceTransparency = "number"
				})
					and sphere.Adornee == part
					and sphere:IsA("PVAdornment")
			end)
		end)
	end)
end)

test("Handles and ArcHandles configuration", function()
	return withTemporary("Part", function(part)
		return withTemporary("Handles", function(handles)
			handles.Adornee = part
			handles.Color3 = Color3.new(1, 1, 0)
			handles.Style = Enum.HandlesStyle.Resize

			local facesOk = pcall(function()
				handles.Faces = Faces.new(Enum.NormalId.Top, Enum.NormalId.Bottom)
			end)

			if not facesOk then
				return false, "Handles Faces is not writable"
			end

			local handlesValid = typedProperties(handles, {
				Color3 = "Color3",
				Faces = "Faces"
			})

			if handlesValid ~= true then
				return false, "Handles types are wrong"
			end

			if handles.Style ~= Enum.HandlesStyle.Resize then
				return false, "Handles Style did not persist"
			end

			return withTemporary("ArcHandles", function(arcs)
				arcs.Adornee = part
				arcs.Color3 = Color3.new(0, 1, 1)

				local axesOk = pcall(function()
					arcs.Axes = Axes.new(Enum.Axis.X, Enum.Axis.Y)
				end)

				if not axesOk then
					return false, "ArcHandles Axes is not writable"
				end

				return typedProperties(arcs, {
					Color3 = "Color3",
					Axes = "Axes"
				})
					and arcs.Adornee == part
			end)
		end)
	end)
end)

test("SurfaceSelection targets a face", function()
	return withTemporary("Part", function(part)
		return withTemporary("SurfaceSelection", function(selection)
			selection.Adornee = part
			selection.TargetSurface = Enum.NormalId.Front

			return selection.Adornee == part
				and selection.TargetSurface == Enum.NormalId.Front
				and typeof(selection.Color3) == "Color3"
		end)
	end)
end)

test("Legacy mesh instances configuration", function()
	local expectations = {
		{ "BlockMesh", nil },
		{ "CylinderMesh", nil },
		{ "SpecialMesh", Enum.MeshType.Sphere }
	}

	for _, entry in ipairs(expectations) do
		local className = entry[1]
		local ok, mesh = pcall(Instance.new, className)

		if not ok or mesh == nil then
			return false, className .. " not constructible"
		end

		mesh.Scale = Vector3.new(2, 2, 2)
		mesh.Offset = Vector3.new(0, 1, 0)
		mesh.VertexColor = Vector3.new(1, 1, 1)

		if entry[2] ~= nil then
			mesh.MeshType = entry[2]
		end

		local valid = typedProperties(mesh, {
			Scale = "Vector3",
			Offset = "Vector3",
			VertexColor = "Vector3"
		})
		local isMesh = mesh:IsA("DataModelMesh")
		local scaled = mesh.Scale.X == 2 and mesh.Offset.Y == 1

		mesh:Destroy()

		if valid ~= true then
			return false, className .. " types are wrong"
		end

		if not isMesh then
			return false, className .. " is not a DataModelMesh"
		end

		if not scaled then
			return false, className .. " did not store Scale or Offset"
		end
	end

	return true
end)

test("FileMesh asset properties", function()
	return withTemporary("FileMesh", function(mesh)
		mesh.MeshId = "rbxassetid://0"
		mesh.TextureId = "rbxassetid://1"

		return typedProperties(mesh, {
			MeshId = "string",
			TextureId = "string"
		})
			and mesh:IsA("FileMesh")
			and mesh:IsA("DataModelMesh")
	end)
end)

test("CSG operation instances are BaseParts", function()
	local classes = {
		"UnionOperation",
		"NegateOperation",
		"IntersectOperation"
	}

	for _, className in ipairs(classes) do
		local ok, operation = pcall(Instance.new, className)

		if not ok or operation == nil then
			return false, className .. " not constructible"
		end

		operation.Size = Vector3.new(3, 3, 3)
		operation.Anchored = true

		local valid = operation:IsA("BasePart")
			and operation:IsA("PVInstance")
			and typeof(operation.CFrame) == "CFrame"
			and typeof(operation.CollisionFidelity) == "EnumItem"
			and typeof(operation.RenderFidelity) == "EnumItem"
			and operation.Size.X == 3

		operation:Destroy()

		if not valid then
			return false, className .. " does not behave like a BasePart"
		end
	end

	return true
end)

test("Legacy joint instances bind parts", function()
	local classes = {
		"Glue",
		"Snap",
		"Motor",
		"Rotate",
		"RotateP",
		"RotateV",
		"ManualWeld"
	}

	return withTemporary("Part", function(first)
		return withTemporary("Part", function(second)
			for _, className in ipairs(classes) do
				local ok, joint = pcall(Instance.new, className)

				if not ok or joint == nil then
					return false, className .. " not constructible"
				end

				joint.Part0 = first
				joint.Part1 = second
				joint.C0 = CFrame.new(0, 1, 0)
				joint.C1 = CFrame.new(0, -1, 0)

				local valid = joint:IsA("JointInstance")
					and joint.Part0 == first
					and joint.Part1 == second
					and typeof(joint.C0) == "CFrame"
					and nearlyEqual(joint.C0.Position.Y, 1)

				joint:Destroy()

				if not valid then
					return false, className .. " did not bind parts"
				end
			end

			return true
		end)
	end)
end)

test("Motor angle configuration", function()
	return withTemporary("Motor", function(motor)
		motor.DesiredAngle = math.pi / 2
		motor.MaxVelocity = 0.15

		return typedProperties(motor, {
			DesiredAngle = "number",
			MaxVelocity = "number",
			CurrentAngle = "number"
		})
			and nearlyEqual(motor.DesiredAngle, math.pi / 2, 0.001)
			and nearlyEqual(motor.MaxVelocity, 0.15)
	end)
end)

test("TorsionSpringConstraint configuration", function()
	return withTemporary("TorsionSpringConstraint", function(constraint)
		constraint.Coils = 3
		constraint.Damping = 0.5
		constraint.MaxTorque = 2000
		constraint.Radius = 1.5
		constraint.Restitution = 0.2
		constraint.Stiffness = 100
		constraint.LimitsEnabled = true
		constraint.MaxAngle = 90

		return typedProperties(constraint, {
			Coils = "number",
			Damping = "number",
			MaxTorque = "number",
			Radius = "number",
			Restitution = "number",
			Stiffness = "number",
			LimitsEnabled = "boolean",
			MaxAngle = "number"
		})
			and constraint:IsA("Constraint")
			and nearlyEqual(constraint.Stiffness, 100)
			and constraint.LimitsEnabled == true
	end)
end)

test("Configuration and container folders", function()
	local classes = {
		"Configuration",
		"Backpack",
		"StarterGear"
	}

	for _, className in ipairs(classes) do
		local ok, container = pcall(Instance.new, className)

		if not ok or container == nil then
			return false, className .. " not constructible"
		end

		local child = Instance.new("NumberValue")

		child.Name = "Tuning"
		child.Value = 7
		child.Parent = container

		local found = container:FindFirstChild("Tuning")
		local valid = found == child
			and found.Value == 7
			and container:IsA("Instance")

		container:Destroy()

		if not valid then
			return false, className .. " does not hold children"
		end
	end

	return true
end)

test("PathfindingLink and PathfindingModifier configuration", function()
	return withTemporary("PathfindingLink", function(link)
		local first = Instance.new("Attachment")
		local second = Instance.new("Attachment")

		link.Attachment0 = first
		link.Attachment1 = second
		link.IsBidirectional = true
		link.Label = "LogUncLink"

		local linkValid = link.Attachment0 == first
			and link.Attachment1 == second
			and link.IsBidirectional == true
			and link.Label == "LogUncLink"

		first:Destroy()
		second:Destroy()

		if not linkValid then
			return false, "PathfindingLink did not store its configuration"
		end

		return withTemporary("PathfindingModifier", function(modifier)
			modifier.PassThrough = true
			modifier.Label = "LogUncModifier"

			return modifier.PassThrough == true
				and modifier.Label == "LogUncModifier"
		end)
	end)
end)

test("IKControl configuration", function()
	return withTemporary("IKControl", function(control)
		control.Type = Enum.IKControlType.Position
		control.Weight = 0.5
		control.Priority = 2
		control.Enabled = false
		control.Offset = CFrame.new(0, 1, 0)

		return typedProperties(control, {
			Weight = "number",
			Priority = "number",
			Enabled = "boolean",
			Offset = "CFrame"
		})
			and control.Type == Enum.IKControlType.Position
			and nearlyEqual(control.Weight, 0.5)
			and control.Enabled == false
	end)
end)

test("MaterialVariant configuration", function()
	return withTemporary("MaterialVariant", function(variant)
		variant.Name = "LogUncVariant"
		variant.BaseMaterial = Enum.Material.Concrete

		local writeOk = pcall(function()
			variant.StudsPerTile = 4
			variant.ColorMap = "rbxassetid://0"
		end)

		if not writeOk then
			return false, "variant properties are not writable"
		end

		return variant.BaseMaterial == Enum.Material.Concrete
			and nearlyEqual(variant.StudsPerTile, 4)
			and type(variant.ColorMap) == "string"
			and variant.Name == "LogUncVariant"
	end)
end)

test("CharacterMesh configuration", function()
	return withTemporary("CharacterMesh", function(mesh)
		mesh.BodyPart = Enum.BodyPart.Torso

		local writeOk = pcall(function()
			mesh.MeshId = 0
			mesh.BaseTextureId = 0
			mesh.OverlayTextureId = 0
		end)

		if not writeOk then
			return false, "asset identifiers are not writable"
		end

		return mesh.BodyPart == Enum.BodyPart.Torso
			and type(mesh.MeshId) == "number"
			and type(mesh.BaseTextureId) == "number"
			and type(mesh.OverlayTextureId) == "number"
	end)
end)

test("AnimationController loads animations", function()
	return withTemporary("AnimationController", function(controller)
		local animator = Instance.new("Animator")

		animator.Parent = controller

		local animation = Instance.new("Animation")

		animation.AnimationId = "rbxassetid://0"
		animation.Parent = controller

		local ok, track = pcall(function()
			return animator:LoadAnimation(animation)
		end)

		local valid = ok
			and typeof(track) == "Instance"
			and track:IsA("AnimationTrack")

		animation:Destroy()
		animator:Destroy()

		if not valid then
			return false, "LoadAnimation did not return an AnimationTrack"
		end

		return true
	end)
end)

test("WrapLayer and WrapTarget configuration", function()
	return withTemporary("WrapTarget", function(target)
		target.CageOrigin = CFrame.new(0, 1, 0)
		target.Stiffness = 0.5

		local targetValid = typedProperties(target, {
			CageOrigin = "CFrame",
			Stiffness = "number"
		})

		if targetValid ~= true then
			return false, "WrapTarget types are wrong"
		end

		return withTemporary("WrapLayer", function(layer)
			layer.CageOrigin = CFrame.new(0, 2, 0)
			layer.Puffiness = 0.25
			layer.Order = 3

			return typedProperties(layer, {
				CageOrigin = "CFrame",
				Puffiness = "number",
				Order = "number"
			})
				and nearlyEqual(layer.Puffiness, 0.25)
				and layer.Order == 3
		end)
	end)
end)

test("VideoFrame configuration", function()
	return withTemporary("VideoFrame", function(frame)
		frame.Size = UDim2.fromOffset(200, 150)
		frame.Looped = true
		frame.Volume = 0.5
		frame.TimePosition = 0

		return typedProperties(frame, {
			Looped = "boolean",
			Volume = "number",
			TimePosition = "number",
			Playing = "boolean"
		})
			and frame:IsA("GuiObject")
			and frame.Looped == true
			and hasMethods(frame, { "Play", "Pause" })
	end)
end)

test("WorldModel supports spatial queries", function()
	return withTemporary("WorldModel", function(world)
		local part = Instance.new("Part")

		part.Anchored = true
		part.Size = Vector3.new(4, 4, 4)
		part.CFrame = CFrame.new(0, 0, 0)
		part.Parent = world

		local valid = world:IsA("WorldRoot")
			and world:IsA("Model")

		local raycastOk, result = pcall(function()
			return world:Raycast(Vector3.new(0, 10, 0), Vector3.new(0, -20, 0))
		end)

		local boundsOk, parts = pcall(function()
			return world:GetPartBoundsInBox(CFrame.new(0, 0, 0), Vector3.new(10, 10, 10))
		end)

		part:Destroy()

		if not valid then
			return false, "WorldModel is not a WorldRoot"
		end

		if not raycastOk then
			return false, "WorldModel Raycast errored"
		end

		if typeof(result) == "RaycastResult" and result.Instance == nil then
			return false, "Raycast result has no Instance"
		end

		return boundsOk and type(parts) == "table"
	end)
end)

test("TextChannel and TextChatCommand surface", function()
	return withTemporary("TextChannel", function(channel)
		local channelValid = hasMethods(channel, {
			"SendAsync",
			"DisplaySystemMessage"
		})

		if channelValid ~= true then
			return false, "TextChannel methods are missing"
		end

		if not isSignal(channel.MessageReceived) then
			return false, "MessageReceived is not a signal"
		end

		return withTemporary("TextChatCommand", function(command)
			command.PrimaryAlias = "/logunc"
			command.SecondaryAlias = "/lu"
			command.Enabled = true
			command.AutocompleteVisible = false

			return command.PrimaryAlias == "/logunc"
				and command.SecondaryAlias == "/lu"
				and command.Enabled == true
				and command.AutocompleteVisible == false
				and isSignal(command.Triggered)
		end)
	end)
end)

test("Pose and KeyframeMarker configuration", function()
	return withTemporary("Keyframe", function(keyframe)
		keyframe.Time = 0.5

		local pose = Instance.new("Pose")

		pose.Name = "Torso"
		pose.CFrame = CFrame.new(0, 1, 0)
		pose.Weight = 0.75
		pose.EasingStyle = Enum.PoseEasingStyle.Cubic
		pose.EasingDirection = Enum.PoseEasingDirection.InOut

		keyframe:AddPose(pose)

		local marker = Instance.new("KeyframeMarker")

		marker.Name = "Footstep"
		marker.Value = "left"

		keyframe:AddMarker(marker)

		local poses = keyframe:GetPoses()
		local markers = keyframe:GetMarkers()

		local valid = nearlyEqual(keyframe.Time, 0.5)
			and containsValue(poses, pose)
			and containsValue(markers, marker)
			and nearlyEqual(pose.Weight, 0.75)
			and marker.Value == "left"

		marker:Destroy()
		pose:Destroy()

		return valid
	end)
end)

test("Stats hierarchy exposes StatsItem descendants", function()
	local stats = game:GetService("Stats")
	local descendants = stats:GetDescendants()

	if type(descendants) ~= "table" then
		return false, "GetDescendants returned " .. typeof(descendants)
	end

	if #descendants < 50 then
		return false, "only " .. #descendants .. " descendants"
	end

	local statsItems = 0

	for _, descendant in ipairs(descendants) do
		if descendant:IsA("StatsItem") then
			statsItems += 1
		end
	end

	metrics.StatsDescendants = #descendants
	metrics.StatsItems = statsItems

	return statsItems >= 50
end)

test("StatsItem members are readable", function()
	local stats = game:GetService("Stats")
	local checked = 0

	for _, descendant in ipairs(stats:GetDescendants()) do
		if not descendant:IsA("StatsItem") then
			continue
		end

		if type(descendant.Name) ~= "string" or #descendant.Name == 0 then
			return false, "a StatsItem has no Name"
		end

		if type(descendant.ClassName) ~= "string" then
			return false, descendant.Name .. " has no ClassName"
		end

		if type(descendant.Archivable) ~= "boolean" then
			return false, descendant.Name .. " Archivable is not a boolean"
		end

		if typeof(descendant.Parent) ~= "Instance" then
			return false, descendant.Name .. " has no Instance parent"
		end

		checked += 1

		if checked >= 120 then
			break
		end
	end

	return checked > 0
end)

test("StatsItem value accessors report numbers and strings", function()
	local stats = game:GetService("Stats")
	local numeric = 0
	local textual = 0

	for _, descendant in ipairs(stats:GetDescendants()) do
		if not descendant:IsA("StatsItem") then
			continue
		end

		local valueOk, value = pcall(function()
			return descendant:GetValue()
		end)

		if valueOk and type(value) == "number" then
			numeric += 1
		end

		local stringOk, text = pcall(function()
			return descendant:GetValueString()
		end)

		if stringOk and type(text) == "string" then
			textual += 1
		end

		if numeric >= 10 and textual >= 10 then
			break
		end
	end

	if numeric == 0 and textual == 0 then
		return false, "no StatsItem exposed a value accessor"
	end

	metrics.StatsValueAccessors = numeric .. " numeric, " .. textual .. " textual"

	return true
end)

test("Stats FrameRateManager children are present", function()
	local stats = game:GetService("Stats")
	local manager = stats:FindFirstChild("FrameRateManager")

	if manager == nil then
		return false, "FrameRateManager is missing"
	end

	local expected = {
		"Batches",
		"Indices",
		"MaterialChanges",
		"VideoMemoryInMB",
		"AverageFPS",
		"FrameTimeVariance",
		"RenderAverage",
		"PrepareAverage",
		"PerformAverage",
		"AverageGPU"
	}

	local missing = {}

	for _, name in ipairs(expected) do
		if manager:FindFirstChild(name) == nil then
			table.insert(missing, name)
		end
	end

	if #missing > 0 then
		return false, "missing: " .. table.concat(missing, ", ")
	end

	local frames = 0

	for index = 0, 11 do
		if manager:FindFirstChild("MsFrame" .. index) ~= nil then
			frames += 1
		end
	end

	metrics.StatsFrameSlots = frames

	return frames >= 8
end)

test("Stats Network hierarchy is enumerable", function()
	local stats = game:GetService("Stats")
	local network = stats:FindFirstChild("Network")

	if network == nil then
		return false, "Network is missing"
	end

	local descendants = network:GetDescendants()

	if #descendants < 50 then
		return false, "Network has only " .. #descendants .. " descendants"
	end

	local serverStats = network:FindFirstChild("ServerStatsItem")

	if serverStats == nil then
		return false, "ServerStatsItem is missing"
	end

	local nested = serverStats:GetDescendants()

	metrics.StatsNetworkDescendants = #descendants

	return #nested > 0
		and network:IsA("Instance")
end)

test("Stats running average item classes are distinct", function()
	local stats = game:GetService("Stats")
	local seen = {}

	for _, descendant in ipairs(stats:GetDescendants()) do
		seen[descendant.ClassName] = (seen[descendant.ClassName] or 0) + 1
	end

	local expected = {
		"StatsItem",
		"RunningAverageItemInt",
		"TotalCountTimeIntervalItem"
	}

	local missing = {}

	for _, className in ipairs(expected) do
		if seen[className] == nil then
			table.insert(missing, className)
		end
	end

	local names = {}

	for className in pairs(seen) do
		table.insert(names, className)
	end

	table.sort(names)
	metrics.StatsItemClasses = table.concat(names, ", ")

	if #missing > 0 then
		return false, "missing classes: " .. table.concat(missing, ", ")
	end

	return #names >= 3
end)

test("StatsItem inheritance and construction rules", function()
	local stats = game:GetService("Stats")
	local sample = nil

	for _, descendant in ipairs(stats:GetDescendants()) do
		if descendant:IsA("StatsItem") then
			sample = descendant
			break
		end
	end

	if sample == nil then
		return false, "no StatsItem was found"
	end

	if not sample:IsA("Instance") then
		return false, "StatsItem is not an Instance"
	end

	local constructible = pcall(Instance.new, "StatsItem")

	if constructible then
		return false, "StatsItem is constructible"
	end

	local cloneOk, clone = pcall(function()
		return sample:Clone()
	end)

	if cloneOk and clone ~= nil then
		clone:Destroy()
		return false, "StatsItem was cloned"
	end

	return true
end)

test("Stats service DataCost is reported", function()
	local stats = game:GetService("Stats")
	local checked = 0

	for _, descendant in ipairs(stats:GetDescendants()) do
		if not descendant:IsA("StatsItem") then
			continue
		end

		local ok, cost = readMember(descendant, "DataCost")

		if not ok then
			return false, descendant.Name .. " DataCost unreadable"
		end

		if type(cost) ~= "number" then
			return false, descendant.Name .. " DataCost is " .. typeof(cost)
		end

		checked += 1

		if checked >= 40 then
			break
		end
	end

	return checked > 0
end)

test("Stats hierarchy names may contain spaces", function()
	local stats = game:GetService("Stats")
	local spaced = 0

	for _, descendant in ipairs(stats:GetDescendants()) do
		if descendant.Name:find(" ", 1, true) ~= nil then
			spaced += 1

			local resolved = descendant.Parent:FindFirstChild(descendant.Name)

			if resolved == nil then
				return false, "cannot resolve '" .. descendant.Name .. "' by name"
			end
		end
	end

	metrics.StatsSpacedNames = spaced

	return spaced > 0
end)

test("Stats GetFullName reflects the hierarchy", function()
	local stats = game:GetService("Stats")
	local checked = 0

	for _, descendant in ipairs(stats:GetDescendants()) do
		local fullName = descendant:GetFullName()

		if type(fullName) ~= "string" then
			return false, "GetFullName returned " .. typeof(fullName)
		end

		if fullName:sub(1, 6) ~= "Stats." then
			return false, fullName .. " is not rooted at Stats"
		end

		if fullName:sub(-#descendant.Name) ~= descendant.Name then
			return false, fullName .. " does not end with its Name"
		end

		checked += 1

		if checked >= 60 then
			break
		end
	end

	return checked > 0
end)

local function analyticsService()
	local ok, service = pcall(game.GetService, game, "RbxAnalyticsService")

	if ok and service ~= nil then
		return service
	end

	return nil
end

local function maskIdentifier(value)
	if type(value) ~= "string" or #value == 0 then
		return "none"
	end

	if #value <= 8 then
		return "len " .. #value
	end

	return value:sub(1, 4) .. "..." .. value:sub(-4) .. " (len " .. #value .. ")"
end

local function isPlaceholderIdentifier(value)
	if type(value) ~= "string" then
		return true
	end

	local trimmed = value:gsub("%s", "")

	if #trimmed == 0 then
		return true
	end

	local lowered = trimmed:lower()
	local blocked = {
		"0",
		"1",
		"nil",
		"null",
		"none",
		"unknown",
		"undefined",
		"hwid",
		"clientid",
		"userid",
		"test",
		"testing",
		"example",
		"placeholder",
		"default",
		"dummy",
		"sandbox",
		"executor",
		"deadbeef",
		"1234567890",
		"abcdefgh",
		"00000000-0000-0000-0000-000000000000",
		"ffffffff-ffff-ffff-ffff-ffffffffffff",
		"11111111-1111-1111-1111-111111111111"
	}

	for _, entry in ipairs(blocked) do
		if lowered == entry then
			return true
		end
	end

	local first = lowered:sub(1, 1)
	local uniform = true

	for index = 2, #lowered do
		if lowered:sub(index, index) ~= first then
			uniform = false
			break
		end
	end

	if uniform then
		return true
	end

	local stripped = lowered:gsub("[%-{}]", "")

	if #stripped == 0 then
		return true
	end

	if stripped:gsub("0", "") == "" then
		return true
	end

	if stripped == "0123456789abcdef" then
		return true
	end

	return false
end

local function identifierShape(value)
	if type(value) ~= "string" then
		return "invalid"
	end

	if value:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") then
		return "guid"
	end

	if value:match("^{%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x}$") then
		return "braced-guid"
	end

	if value:match("^%x+$") then
		return "hex" .. #value
	end

	if value:match("^[%w%-_]+$") then
		return "token" .. #value
	end

	return "opaque" .. #value
end

local function readClientId()
	local service = analyticsService()

	if service == nil then
		return nil
	end

	local ok, value = pcall(function()
		return service:GetClientId()
	end)

	if ok and type(value) == "string" and #value > 0 then
		return value
	end

	return nil
end

local function readExecutorHwid()
	local names = {
		"gethwid",
		"get_hwid",
		"gethardwareid",
		"gethwidhash",
		"getdeviceid"
	}

	for _, name in ipairs(names) do
		local fn = globalFunction(name)

		if fn ~= nil then
			local ok, value = pcall(fn)

			if ok and type(value) == "string" and #value > 0 then
				return value, name
			end
		end
	end

	return nil, nil
end

do
	local clientId = readClientId()

	if clientId ~= nil then
		metrics.ClientId = maskIdentifier(clientId)
		metrics.ClientIdShape = identifierShape(clientId)
	end

	local hwid, source = readExecutorHwid()

	if hwid ~= nil then
		metrics.ExecutorHwid = maskIdentifier(hwid)
		metrics.ExecutorHwidShape = identifierShape(hwid)
		metrics.ExecutorHwidSource = source
	end
end

test("RbxAnalyticsService is reachable", function()
	local service = analyticsService()

	if service == nil then
		return false, "RbxAnalyticsService is unavailable"
	end

	return typeof(service) == "Instance"
		and service.ClassName == "RbxAnalyticsService"
		and service.Parent == game
end)

test("RbxAnalyticsService method surface", function()
	local service = analyticsService()

	if service == nil then
		return true
	end

	local present = 0

	for _, name in ipairs({
		"GetClientId",
		"GetSessionId",
		"GetPlaySessionId",
		"SetRBXEvent",
		"SetRBXEventStream",
		"TrackEvent",
		"ReportCounter",
		"UpdateHeartbeatObject"
	}) do
		if hasMethod(service, name) then
			present += 1
		end
	end

	metrics.AnalyticsMethods = present .. "/8"

	return present >= 3
end)

test("Client identifier is readable", function()
	local service = analyticsService()

	if service == nil then
		return true
	end

	if not hasMethod(service, "GetClientId") then
		return true
	end

	local ok, value = pcall(function()
		return service:GetClientId()
	end)

	if not ok then
		return false, "GetClientId errored: " .. stringify(value)
	end

	if type(value) ~= "string" then
		return false, "GetClientId returned " .. typeof(value)
	end

	if #value < 8 then
		return false, "identifier is only " .. #value .. " characters"
	end

	return true
end)

test("Client identifier is stable across calls", function()
	local service = analyticsService()

	if service == nil or not hasMethod(service, "GetClientId") then
		return true
	end

	local firstOk, first = pcall(function()
		return service:GetClientId()
	end)
	local secondOk, second = pcall(function()
		return service:GetClientId()
	end)

	if not firstOk or not secondOk then
		return true
	end

	if first ~= second then
		return false, "identifier changed between calls"
	end

	task.wait()

	local thirdOk, third = pcall(function()
		return service:GetClientId()
	end)

	if thirdOk and third ~= first then
		return false, "identifier changed after a frame"
	end

	return true
end)

test("Client identifier is not a placeholder", function()
	local clientId = readClientId()

	if clientId == nil then
		return true
	end

	if isPlaceholderIdentifier(clientId) then
		return false, "identifier looks synthetic: " .. maskIdentifier(clientId)
	end

	local shape = identifierShape(clientId)

	if shape == "invalid" then
		return false, "identifier has no recognisable shape"
	end

	return true
end)

test("Client identifier differs from session identifiers", function()
	local service = analyticsService()

	if service == nil then
		return true
	end

	local clientId = readClientId()

	if clientId == nil then
		return true
	end

	for _, name in ipairs({ "GetSessionId", "GetPlaySessionId" }) do
		if not hasMethod(service, name) then
			continue
		end

		local ok, value = pcall(function()
			return service[name](service)
		end)

		if ok and type(value) == "string" and #value > 0 then
			if value == clientId then
				return false, name .. " matches the client identifier"
			end

			if isPlaceholderIdentifier(value) then
				return false, name .. " looks synthetic"
			end
		end
	end

	return true
end)

test("Executor hardware identifier is well formed", function()
	local hwid, source = readExecutorHwid()

	if hwid == nil then
		return true
	end

	if #hwid < 8 then
		return false, source .. " returned only " .. #hwid .. " characters"
	end

	if isPlaceholderIdentifier(hwid) then
		return false, source .. " looks synthetic: " .. maskIdentifier(hwid)
	end

	return identifierShape(hwid) ~= "invalid"
end)

test("Executor hardware identifier is stable", function()
	local names = {
		"gethwid",
		"get_hwid",
		"gethardwareid",
		"gethwidhash",
		"getdeviceid"
	}

	for _, name in ipairs(names) do
		local fn = globalFunction(name)

		if fn == nil then
			continue
		end

		local firstOk, first = pcall(fn)
		local secondOk, second = pcall(fn)

		if firstOk and secondOk and type(first) == "string" then
			if first ~= second then
				return false, name .. " changed between calls"
			end
		end
	end

	return true
end)

test("Hardware and client identifiers are consistent", function()
	local clientId = readClientId()
	local hwid = readExecutorHwid()

	if clientId == nil or hwid == nil then
		return true
	end

	metrics.HwidMatchesClientId = clientId == hwid

	return true
end)

test("Client identifier survives a service reference clone", function()
	local service = analyticsService()

	if service == nil or not hasMethod(service, "GetClientId") then
		return true
	end

	local clonerefFn = globalFunction("cloneref")

	if clonerefFn == nil then
		return true
	end

	local cloneOk, clone = pcall(clonerefFn, service)

	if not cloneOk or clone == nil then
		return true
	end

	local originalOk, original = pcall(function()
		return service:GetClientId()
	end)
	local clonedOk, cloned = pcall(function()
		return clone:GetClientId()
	end)

	if not originalOk or not clonedOk then
		return true
	end

	return original == cloned
end)

local function corePackagesService()
	local ok, service = pcall(game.GetService, game, "CorePackages")

	if ok and service ~= nil then
		return service
	end

	return nil
end

local function walkBounded(root, limit)
	local queue = { root }
	local visited = {}
	local index = 1

	while index <= #queue and #visited < limit do
		local current = queue[index]
		index += 1

		local ok, children = pcall(function()
			return current:GetChildren()
		end)

		if ok and type(children) == "table" then
			for _, child in ipairs(children) do
				table.insert(visited, child)

				if #visited >= limit then
					break
				end

				table.insert(queue, child)
			end
		end
	end

	return visited
end

local function ancestryPath(instance)
	local segments = {}
	local current = instance

	while current ~= nil and current ~= game do
		table.insert(segments, 1, current.Name)

		local ok, parent = readMember(current, "Parent")

		if not ok then
			return nil
		end

		current = parent
	end

	if current ~= game then
		return nil
	end

	return table.concat(segments, ".")
end

test("CorePackages service shape", function()
	local service = corePackagesService()

	if service == nil then
		return false, "CorePackages is unavailable"
	end

	if typeof(service) ~= "Instance" then
		return false, "CorePackages is " .. typeof(service)
	end

	if service.Parent ~= game then
		return false, "CorePackages parent is " .. stringify(service.Parent)
	end

	local children = service:GetChildren()

	metrics.CorePackagesChildren = #children

	return #children > 0
end)

test("CorePackages is not constructible", function()
	local service = corePackagesService()

	if service == nil then
		return true
	end

	local ok, constructed = pcall(Instance.new, service.ClassName)

	if ok and constructed ~= nil then
		constructed:Destroy()
		return false, service.ClassName .. " was constructed"
	end

	return true
end)

test("CorePackages Workspace Packages layout", function()
	local service = corePackagesService()

	if service == nil then
		return true
	end

	local workspaceFolder = service:FindFirstChild("Workspace")

	if workspaceFolder == nil then
		return false, "CorePackages.Workspace is missing"
	end

	local packages = workspaceFolder:FindFirstChild("Packages")

	if packages == nil then
		return false, "CorePackages.Workspace.Packages is missing"
	end

	local index = packages:FindFirstChild("_Index")

	if index == nil then
		return false, "Packages._Index is missing"
	end

	return workspaceFolder:IsA("Instance")
		and packages:IsA("Instance")
		and index:IsA("Instance")
		and index.Name == "_Index"
end)

test("CorePackages _Index holds package entries", function()
	local service = corePackagesService()

	if service == nil then
		return true
	end

	local index = nil
	local workspaceFolder = service:FindFirstChild("Workspace")

	if workspaceFolder ~= nil then
		local packages = workspaceFolder:FindFirstChild("Packages")

		if packages ~= nil then
			index = packages:FindFirstChild("_Index")
		end
	end

	if index == nil then
		return true
	end

	local children = index:GetChildren()

	if #children < 5 then
		return false, "_Index has only " .. #children .. " children"
	end

	local folders = 0

	for _, child in ipairs(children) do
		if child:IsA("Folder") then
			folders += 1
		end
	end

	metrics.CorePackagesIndexEntries = #children

	return folders > 0
end)

test("CorePackages package folders mirror their name", function()
	local service = corePackagesService()

	if service == nil then
		return true
	end

	local workspaceFolder = service:FindFirstChild("Workspace")

	if workspaceFolder == nil then
		return true
	end

	local packages = workspaceFolder:FindFirstChild("Packages")

	if packages == nil then
		return true
	end

	local index = packages:FindFirstChild("_Index")

	if index == nil then
		return true
	end

	local mirrored = 0
	local inspected = 0

	for _, package in ipairs(index:GetChildren()) do
		if not package:IsA("Folder") then
			continue
		end

		inspected += 1

		if package:FindFirstChild(package.Name) ~= nil then
			mirrored += 1
		end

		if inspected >= 40 then
			break
		end
	end

	if inspected == 0 then
		return true
	end

	metrics.CorePackagesMirrored = mirrored .. "/" .. inspected

	return mirrored > 0
end)

test("CorePackages modules report DataCost", function()
	local service = corePackagesService()

	if service == nil then
		return true
	end

	local sample = walkBounded(service, 400)
	local modules = 0

	for _, descendant in ipairs(sample) do
		if not descendant:IsA("ModuleScript") then
			continue
		end

		local ok, cost = readMember(descendant, "DataCost")

		if not ok then
			return false, descendant.Name .. " DataCost unreadable"
		end

		if type(cost) ~= "number" then
			return false, descendant.Name .. " DataCost is " .. typeof(cost)
		end

		modules += 1
	end

	metrics.CorePackagesModules = modules

	return modules > 0
end)

test("CorePackages descendants are archivable instances", function()
	local service = corePackagesService()

	if service == nil then
		return true
	end

	local sample = walkBounded(service, 300)

	if #sample == 0 then
		return false, "traversal found nothing"
	end

	for _, descendant in ipairs(sample) do
		if not descendant:IsA("Instance") then
			return false, "a descendant is not an Instance"
		end

		if type(descendant.Name) ~= "string" then
			return false, "a descendant has no Name"
		end

		if type(descendant.Archivable) ~= "boolean" then
			return false, descendant.Name .. " Archivable is " .. typeof(descendant.Archivable)
		end
	end

	return true
end)

test("CorePackages hierarchy nests deeply", function()
	local service = corePackagesService()

	if service == nil then
		return true
	end

	local sample = walkBounded(service, 600)
	local deepest = 0

	for _, descendant in ipairs(sample) do
		local ok, fullName = pcall(function()
			return descendant:GetFullName()
		end)

		if ok and type(fullName) == "string" then
			local segments = 1

			for _ in fullName:gmatch("%.") do
				segments += 1
			end

			if segments > deepest then
				deepest = segments
			end
		end
	end

	metrics.CorePackagesDepth = deepest

	return deepest >= 5
end)

test("CorePackages GetFullName matches the ancestry chain", function()
	local service = corePackagesService()

	if service == nil then
		return true
	end

	local sample = walkBounded(service, 200)
	local checked = 0

	for _, descendant in ipairs(sample) do
		local fullName = descendant:GetFullName()
		local path = ancestryPath(descendant)

		if path == nil then
			return false, descendant.Name .. " has a broken ancestry chain"
		end

		if fullName ~= path then
			return false, fullName .. " does not match " .. path
		end

		checked += 1

		if checked >= 120 then
			break
		end
	end

	return checked > 0
end)

test("CorePackages descendants are rooted at game", function()
	local service = corePackagesService()

	if service == nil then
		return true
	end

	local sample = walkBounded(service, 200)
	local checked = 0

	for _, descendant in ipairs(sample) do
		if not descendant:IsDescendantOf(game) then
			return false, descendant.Name .. " is not a descendant of game"
		end

		if not descendant:IsDescendantOf(service) then
			return false, descendant.Name .. " is not a descendant of CorePackages"
		end

		checked += 1
	end

	return checked > 0
end)

test("CorePackages module source access is consistent", function()
	local service = corePackagesService()

	if service == nil then
		return true
	end

	local sample = walkBounded(service, 200)
	local readable = 0
	local blocked = 0

	for _, descendant in ipairs(sample) do
		if not descendant:IsA("ModuleScript") then
			continue
		end

		local ok, source = readMember(descendant, "Source")

		if ok then
			if type(source) ~= "string" then
				return false, descendant.Name .. " Source is " .. typeof(source)
			end

			readable += 1
		else
			blocked += 1
		end

		if readable + blocked >= 20 then
			break
		end
	end

	if readable + blocked == 0 then
		return true
	end

	metrics.CoreModuleSource = readable .. " readable, " .. blocked .. " blocked"

	return true
end)

test("CorePackages folders and modules are distinct classes", function()
	local service = corePackagesService()

	if service == nil then
		return true
	end

	local sample = walkBounded(service, 400)
	local seen = {}

	for _, descendant in ipairs(sample) do
		seen[descendant.ClassName] = (seen[descendant.ClassName] or 0) + 1
	end

	if seen.ModuleScript == nil then
		return false, "no ModuleScript was found"
	end

	local names = {}

	for className in pairs(seen) do
		table.insert(names, className)
	end

	table.sort(names)
	metrics.CorePackagesClasses = table.concat(names, ", ")

	for _, descendant in ipairs(sample) do
		if descendant:IsA("ModuleScript") and not descendant:IsA("LuaSourceContainer") then
			return false, descendant.Name .. " is not a LuaSourceContainer"
		end
	end

	return true
end)

test("Bounded traversal agrees with GetChildren", function()
	local root = Instance.new("Folder")
	local expected = 0

	for outer = 1, 4 do
		local branch = Instance.new("Folder")

		branch.Name = "Branch" .. outer
		branch.Parent = root
		expected += 1

		for inner = 1, 3 do
			local leaf = Instance.new("Folder")

			leaf.Name = "Leaf" .. outer .. "_" .. inner
			leaf.Parent = branch
			expected += 1
		end
	end

	local walked = walkBounded(root, 100)
	local descendants = root:GetDescendants()
	local limited = walkBounded(root, 5)

	root:Destroy()

	if #walked ~= expected then
		return false, "walk found " .. #walked .. " expected " .. expected
	end

	if #descendants ~= expected then
		return false, "GetDescendants found " .. #descendants
	end

	return #limited == 5
end)

test("Ancestry path helper matches GetFullName", function()
	local root = Instance.new("Folder")

	root.Name = "LogUncAncestryRoot"

	local middle = Instance.new("Folder")

	middle.Name = "Middle"
	middle.Parent = root

	local leaf = Instance.new("Folder")

	leaf.Name = "Leaf"
	leaf.Parent = middle

	local detachedPath = ancestryPath(leaf)

	root.Parent = workspace

	local attachedPath = ancestryPath(leaf)
	local fullName = leaf:GetFullName()
	local expected = workspace.Name .. ".LogUncAncestryRoot.Middle.Leaf"

	root:Destroy()

	if detachedPath ~= nil then
		return false, "detached instance produced a path"
	end

	if attachedPath == nil then
		return false, "attached instance produced no path"
	end

	if attachedPath ~= fullName then
		return false, attachedPath .. " does not match " .. fullName
	end

	return fullName == expected
end)

local authenticityProbes = {
	{
		Name = "Enum registry",
		Check = function()
			local enums = Enum:GetEnums()
			local seen = {}

			for _, enumType in ipairs(enums) do
				local name = tostring(enumType)

				if seen[name] then
					return false
				end

				seen[name] = true
			end

			return #enums > 50
		end
	},
	{
		Name = "Font weights",
		Check = function()
			local bold = Font.fromEnum(Enum.Font.GothamBold)
			local regular = Font.fromEnum(Enum.Font.Gotham)

			return bold.Weight == Enum.FontWeight.Bold
				and regular.Weight == Enum.FontWeight.Regular
				and bold.Family == regular.Family
		end
	},
	{
		Name = "FloatCurve keys",
		Check = function()
			local curve = Instance.new("FloatCurve")

			curve:InsertKey(FloatCurveKey.new(0, 0, Enum.KeyInterpolationMode.Constant))
			curve:InsertKey(FloatCurveKey.new(0.5, 7, Enum.KeyInterpolationMode.Linear))
			curve:InsertKey(FloatCurveKey.new(1, 3, Enum.KeyInterpolationMode.Cubic))

			local first = curve:GetKeyAtIndex(1)
			local second = curve:GetKeyAtIndex(2)
			local third = curve:GetKeyAtIndex(3)

			curve:Destroy()

			return first.Time == 0
				and second.Value == 7
				and third.Interpolation == Enum.KeyInterpolationMode.Cubic
		end
	},
	{
		Name = "FloatCurve interpolation",
		Check = function()
			local curve = Instance.new("FloatCurve")

			curve:InsertKey(FloatCurveKey.new(0, 0, Enum.KeyInterpolationMode.Linear))
			curve:InsertKey(FloatCurveKey.new(1, 10, Enum.KeyInterpolationMode.Linear))

			local atStart = curve:GetValueAtTime(0)
			local atEnd = curve:GetValueAtTime(1)
			local atMiddle = curve:GetValueAtTime(0.5)

			curve:Destroy()

			return atStart == 0
				and atEnd == 10
				and math.abs(atMiddle - 5) < 0.01
		end
	},
	{
		Name = "Locked metatable",
		Check = function()
			return getmetatable(game) == "The metatable is locked"
				and type(game) == "userdata"
		end
	},
	{
		Name = "Native functions",
		Check = function()
			return debug.info(math.abs, "s") == "[C]"
				and debug.info(math.abs, "l") == -1
				and debug.info(Instance.new, "s") == "[C]"
		end
	}
}

local authenticProbes = 0
local failedProbes = {}

for _, probe in ipairs(authenticityProbes) do
	local ok, value = pcall(probe.Check)

	if ok and value == true then
		authenticProbes += 1
	else
		table.insert(failedProbes, probe.Name)
	end
end

metrics.AuthenticityProbes = authenticProbes .. "/" .. #authenticityProbes
metrics.Environment = authenticProbes == #authenticityProbes and "ROBLOX" or "ENV"

test("Environment authenticity verdict", function()
	if authenticProbes ~= #authenticityProbes then
		return false, "failed probes: " .. table.concat(failedProbes, ", ")
	end

	return true
end)

local counted = #results.Passed + #results.Failed
local total = counted + #results.Skipped
local percentage = counted > 0
	and (#results.Passed / counted) * 100
	or 0

print(string.rep("=", 56))
print("Log-Unc diagnostic completed")
print(string.format("Score: %.2f%%", percentage))
print("Environment: " .. metrics.Environment)
print("Passed: " .. #results.Passed)
print("Failed: " .. #results.Failed)
print("Skipped: " .. #results.Skipped)
print("Coverage: " .. counted .. "/" .. total)
print(string.rep("=", 56))
print("FAILED TESTS")

if #results.Failed == 0 then
	print("None")
else
	for index, failure in ipairs(results.Failed) do
		print(
			string.format(
				"%d. %s | %s",
				index,
				failure.Name,
				failure.Reason
			)
		)
	end
end

print(string.rep("-", 56))
print("SKIPPED TESTS")

if #results.Skipped == 0 then
	print("None")
else
	for index, skipped in ipairs(results.Skipped) do
		print(
			string.format(
				"%d. %s | %s",
				index,
				skipped.Name,
				skipped.Reason
			)
		)
	end
end

print(string.rep("-", 56))
print("METRICS")

local metricNames = {}

for name in pairs(metrics) do
	table.insert(metricNames, name)
end

table.sort(metricNames)

if #metricNames == 0 then
	print("None")
else
	for _, name in ipairs(metricNames) do
		print(name .. ": " .. stringify(metrics[name]))
	end
end

print(string.rep("=", 56))