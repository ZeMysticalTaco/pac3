local pac = pac
local part_count = 0 -- unique id thing
local pairs = pairs

pac.registered_parts = {}

local function initialize(part, owner)
	if part.PreInitialize then
		part:PreInitialize()
	end

	pac.AddPart(part)

	if owner then
		part:SetPlayerOwner(owner)
	end

	part:Initialize()
end

function pac.CreatePart(name, owner)
	name = name or "base"
	owner = owner or pac.LocalPlayer

	local META = pac.registered_parts[name]
	if not META then
		pac.Message("Tried to create unknown part: " .. name .. '!')
		META = pac.registered_parts.base
	end
	local part = pac.CopyValue(META)
	setmetatable(part, part)

	part.Id = part_count
	part_count = part_count + 1

	part:SetUniqueID(util.CRC(os.time() + pac.RealTime + part_count))

	part.DefaultVars = {}

	for key in pairs(part.StorableVars) do
		if key == "UniqueID" then
			part.DefaultVars[key] = ""
		else
			part.DefaultVars[key] = pac.CopyValue(part[key])
		end
	end

	local ok, err = xpcall(initialize, ErrorNoHalt, part, owner)

	if not ok then
		part:Remove()
		if part.ClassName ~= "base" then
			return pac.CreatePart("base", owner)
		end
	end

	pac.dprint("creating %s part owned by %s", part.ClassName, tostring(owner))

	timer.Simple(0.1, function()
		if part:IsValid() and part.show_in_editor ~= false and owner == pac.LocalPlayer then
			pac.CallHook("OnPartCreated", part)
		end
	end)

	return part
end

function pac.RegisterPart(META)

	if META.Group == "experimental" then
		-- something is up with the lua cache
		-- file.Find("pac3/core/client/parts/*.lua", "LUA") will find the experimental parts as well
		-- maybe because pac3 mounts the workshop version on server?
		return
	end

	do
		local enabled = pac.CreateClientConVarFast("pac_enable_" .. META.ClassName, "1", true, "boolean")
		function META:IsEnabled()
			return enabled()
		end
	end

	pac.registered_parts[META.ClassName] = META

	if pac.UpdatePartsWithMetatable then
		pac.UpdatePartsWithMetatable(META, name)
	end
end

function pac.LoadParts()
	local files = file.Find("pac3/core/client/parts/*.lua", "LUA")
	for _, name in pairs(files) do
		if name:EndsWith("2.lua") then continue end
		include("pac3/core/client/parts/" .. name)
	end

	local files = file.Find("pac3/core/client/parts/legacy/*.lua", "LUA")
	for _, name in pairs(files) do
		include("pac3/core/client/parts/legacy/" .. name)
	end
end

function pac.GetRegisteredParts()
	return pac.registered_parts
end


include("base_part.lua")