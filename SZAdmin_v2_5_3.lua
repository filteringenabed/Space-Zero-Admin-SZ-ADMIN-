if not game:IsLoaded() then
	game.Loaded:Wait()
end

export type options_table = {
	binds_autosave: boolean?
}

local options: options_table = #{...} > 0 and ({...})[1] or {}
options.binds_autosave = options.binds_autosave or true

identifyexecutor = identifyexecutor or function() return "CommandBar" end
setfpscap = setfpscap or function() end
setfps = setfps or function() end
fireproximityprompt = fireproximityprompt or function() end
firetouchinterest = firetouchinterest or function() end
setclipboard = setclipboard or function() end
saveinstance = saveinstance or function() end
hookmetamethod = hookmetamethod or nil
getloadedmodules = getloadedmodules or function() return {} end
decompile = decompile or function() return '' end
getnamecallmethod = getnamecallmethod or nil
checkcaller = checkcaller or function() return false end
syn = syn or {}
sethiddenproperty = sethiddenproperty or function() end
set_hidden_property = sethiddenproperty or function() end
set_hidden_prop = sethiddenproperty or function() end
hookfunction = hookfunction or nil
getrawmetatable = getrawmetatable or function() return {} end
mouse1click = mouse1click or function() end
writefile = writefile or function() end
isfile = isfile or function() return false end
readfile = readfile or function() return '' end
getgenv = getgenv or function() return {} end
getrenv = getrenv or function() return {} end
cloneref = cloneref or function(v) return v end
gethui = gethui or function() return cloneref(game:GetService('CoreGui')) end
setreadonly = setreadonly or function() end
getgc = getgc or (debug and debug.getgc)
newcclosure = newcclosure or function(f)
	return coroutine.wrap(function(...)
		local args = {...}
		while true do
			args = {coroutine.yield(f(unpack(args)))}
		end
	end)
end
debug_info = (getrenv().debug and getrenv().debug.info) or (debug and debug.info)
Drawing = Drawing or {}


local env = getgenv() or shared or _G

-- ░██████╗███████╗░█████╗░██████╗░███╗░░░███╗██╗███╗░░██╗
-- ██╔════╝╚════██║██╔══██╗██╔══██╗████╗░████║██║████╗░██║
-- ╚█████╗░░░███╔═╝███████║██║░░██║██╔████╔██║██║██╔██╗██║
-- ░╚═══██╗██╔══╝░░██╔══██║██║░░██║██║╚██╔╝██║██║██║╚████║
-- ██████╔╝███████╗██║░░██║██████╔╝██║░╚═╝░██║██║██║░╚███║
-- ╚═════╝░╚══════╝╚═╝░░╚═╝╚═════╝░╚═╝░░░░░╚═╝╚═╝╚═╝░░╚══╝
-- v2.5.3 | rebrand of opadmin

env['szadmin'] = env['szadmin'] or {}
if env['szadmin'].i then return end
env['szadmin'].i = true

local SZADMIN_NAME    = "SZAdmin"
local SZADMIN_VERSION = "v2.5.3"
local SZADMIN_TAG     = SZADMIN_NAME .. " " .. SZADMIN_VERSION

local services = {
	core_gui = gethui(),
	debris = cloneref(game:GetService('Debris')),
	tween_service = cloneref(game:GetService('TweenService')),
	players = cloneref(game:GetService('Players')),
	run_service = cloneref(game:GetService('RunService')),
	starter_player = cloneref(game:GetService('StarterPlayer')),
	teleport_service = cloneref(game:GetService('TeleportService')),
	text_chat_service = cloneref(game:GetService('TextChatService')),
	lighting = cloneref(game:GetService('Lighting')),
	user_input_service = cloneref(game:GetService('UserInputService')),
	replicated_storage = cloneref(game:GetService('ReplicatedStorage')),
	http = cloneref(game:GetService('HttpService')),
	gui_service = cloneref(game:GetService('GuiService')),
	marketplace_service = cloneref(game:GetService('MarketplaceService')),
	network_client = cloneref(game:GetService('NetworkClient')),
	sound_service = cloneref(game:GetService('SoundService')),
	chat = cloneref(game:GetService('Chat')),
}

local stuff = {
	ver = '2.5.3',
	empty_function = function() end,
	destroy = game.Destroy,
	clone = game.Clone,
	connect = game.Changed.Connect,
	disconnect = nil,
	server_endpoint = nil,

	owner = services.players.LocalPlayer,
	owner_char = nil,

	ui = nil,
	open_keybind = nil,
	chat_prefix = nil,
	sim_range_reset = false,
	last_command = nil,

	rawrbxget = nil,
	rawrbxset = nil,

	default_ws = 16,
	default_jp = 50,

	is_mobile = services.user_input_service.TouchEnabled and not services.user_input_service.KeyboardEnabled,
	is_console = services.gui_service:IsTenFootInterface(),

	highlights = {},
	target = nil,
	active_notifications = {},
	max_notifications = 10,
	velocity_history = {},
	ping_samples = {},

	ui_notifications_template = nil,
	ui_notifications_main_container = nil,
	ui_cmdlist = nil,
	ui_cmdlist_template = nil,
	ui_cmdlist_commandlist = nil,
	update_keybinds = nil,

	frame_times = {},
	last_frame_time = 0,
	avg_fps = 60,
	avg_ping = 0
}

stuff.owner_char = stuff.owner.Character or stuff.owner.CharacterAdded:Wait()

local function get_plrs(exclude)
	local plrs = {}
	for _, plr in services.players:GetPlayers() do
		if plr ~= exclude then
			table.insert(plrs, plr)
		end
	end
	return plrs
end
local parts_frozen = {}
local function add_part_to_freeze(part)
	table.insert(parts_frozen,{Part = part,CFrame = part.CFrame})
end
local function remove_part_from_freeze(part)
	for i,v in pairs(parts_frozen) do
		if v.Part == part then
			table.remove(parts_frozen,i)
		end
	end
end
local function get_plr(name)
	if not name then return {} end

	local lower_name = name:lower()
	local all_plrs = get_plrs()

	local special_selectors;special_selectors = {
		['@random'] = function() return #all_plrs > 0 and {all_plrs[math.random(#all_plrs)]} or {} end,
		['@rand'] = function() return special_selectors['@random']() end,
		['@r'] = function() return special_selectors['@random']() end,

		['@self'] = function() return {stuff.owner} end,
		['@me'] = function() return {stuff.owner} end,
		['@s'] = function() return {stuff.owner} end,
		['@m'] = function() return {stuff.owner} end,

		['@everyone'] = function() return all_plrs end,
		['@all'] = function() return all_plrs end,
		['@e'] = function() return all_plrs end,
		['@a'] = function() return all_plrs end,

		['@others'] = function()
			local others = {}
			for _, plr in all_plrs do
				if plr ~= stuff.owner then
					table.insert(others, plr)
				end
			end
			return others
		end,
		['@other'] = function() return special_selectors['@others']() end,
		['@o'] = function() return special_selectors['@others']() end,

		['@view'] = function()
			local subject = workspace.CurrentCamera.CameraSubject
			if subject and subject.Parent then
				local plr = services.players:GetPlayerFromCharacter(subject.Parent)
				return plr and {plr} or {}
			end
			return {}
		end,
		['@v'] = function() return special_selectors['@view']() end,

		['@enemies'] = function()
			local enemies = {}
			for _, plr in all_plrs do
				if plr ~= stuff.owner then
					if not plr.Team or plr.Team ~= stuff.owner.Team then
						table.insert(enemies, plr)
					end
				end
			end
			return enemies
		end,
		['@enemy'] = function() return special_selectors['@enemies']() end,

		['@team'] = function()
			local teammates = {}
			for _, plr in all_plrs do
				if plr ~= stuff.owner and plr.Team and plr.Team == stuff.owner.Team then
					table.insert(teammates, plr)
				end
			end
			return teammates
		end,
		['@teammates'] = function() return special_selectors['@team']() end,
		['@allies'] = function() return special_selectors['@team']() end,
		['@t'] = function() return special_selectors['@team']() end,

		['@friends'] = function()
			local friends = {}
			for _, plr in all_plrs do
				if plr ~= stuff.owner then
					local success, is_friend = pcall(function()
						return stuff.owner:IsFriendsWith(plr.UserId)
					end)
					if success and is_friend then
						table.insert(friends, plr)
					end
				end
			end
			return friends
		end,
		['@friend'] = function() return special_selectors['@friends']() end,

		['@nonfriends'] = function()
			local non_friends = {}
			for _, plr in all_plrs do
				if plr ~= stuff.owner then
					local success, is_friend = pcall(function()
						return stuff.owner:IsFriendsWith(plr.UserId)
					end)
					if success and not is_friend then
						table.insert(non_friends, plr)
					elseif not success then
						table.insert(non_friends, plr)
					end
				end
			end
			return non_friends
		end,
		['@notfriends'] = function() return special_selectors['@nonfriends']() end,
		['@strangers'] = function() return special_selectors['@nonfriends']() end,

		['@armed'] = function()
			local armed = {}
			for _, plr in all_plrs do
				if plr.Character and plr.Character:FindFirstChildOfClass('Tool') then
					table.insert(armed, plr)
				end
			end
			return armed
		end,
		['@hastool'] = function() return special_selectors['@armed']() end,

		['@unarmed'] = function()
			local unarmed = {}
			for _, plr in all_plrs do
				if plr.Character and not plr.Character:FindFirstChildOfClass('Tool') then
					table.insert(unarmed, plr)
				end
			end
			return unarmed
		end,
		['@notool'] = function() return special_selectors['@unarmed']() end,

		['@grounded'] = function()
			local grounded = {}
			for _, plr in all_plrs do
				if plr.Character then
					local hum = plr.Character:FindFirstChildOfClass('Humanoid')
					if hum and hum.FloorMaterial ~= Enum.Material.Air then
						table.insert(grounded, plr)
					end
				end
			end
			return grounded
		end,
		['@onground'] = function() return special_selectors['@grounded']() end,

		['@moving'] = function()
			local moving = {}
			for _, plr in all_plrs do
				if plr.Character then
					local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
					if hrp then
						local vel = hrp.AssemblyLinearVelocity
						local h_speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
						if h_speed > 1 then
							table.insert(moving, plr)
						end
					end
				end
			end
			return moving
		end,

		['@onscreen'] = function()
			local on_screen = {}
			local camera = workspace.CurrentCamera

			for _, plr in all_plrs do
				if plr.Character then
					local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
					if hrp then
						local _, visible = camera:WorldToViewportPoint(hrp.Position)
						if visible then
							table.insert(on_screen, plr)
						end
					end
				end
			end
			return on_screen
		end,
		['@screen'] = function() return special_selectors['@onscreen']() end,

		['@offscreen'] = function()
			local off_screen = {}
			local camera = workspace.CurrentCamera

			for _, plr in all_plrs do
				if plr.Character then
					local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
					if hrp then
						local _, visible = camera:WorldToViewportPoint(hrp.Position)
						if not visible then
							table.insert(off_screen, plr)
						end
					end
				end
			end
			return off_screen
		end,

		['@lowhp'] = function()
			local low_hp = {}
			for _, plr in all_plrs do
				if plr.Character then
					local hum = plr.Character:FindFirstChildOfClass('Humanoid')
					if hum and hum.Health > 0 and hum.Health <= hum.MaxHealth * 0.3 then
						table.insert(low_hp, plr)
					end
				end
			end
			return low_hp
		end,
		['@lowhealth'] = function() return special_selectors['@lowhp']() end,
		['@weak'] = function() return special_selectors['@lowhp']() end,

		['@fullhp'] = function()
			local full_hp = {}
			for _, plr in all_plrs do
				if plr.Character then
					local hum = plr.Character:FindFirstChildOfClass('Humanoid')
					if hum and hum.Health >= hum.MaxHealth then
						table.insert(full_hp, plr)
					end
				end
			end
			return full_hp
		end,
		['@fullhealth'] = function() return special_selectors['@fullhp']() end,

		['@newest'] = function()
			local newest, newest_time = nil, 0
			for _, plr in all_plrs do
				if plr.AccountAge and plr.AccountAge < 365 then
					if not newest or plr.AccountAge < newest_time then
						newest = plr
						newest_time = plr.AccountAge
					end
				end
			end
			return newest and {newest} or {}
		end,
		['@new'] = function() return special_selectors['@newest']() end,

		['@oldest'] = function()
			local oldest, oldest_time = nil, 0
			for _, plr in all_plrs do
				if plr.AccountAge and plr.AccountAge > oldest_time then
					oldest = plr
					oldest_time = plr.AccountAge
				end
			end
			return oldest and {oldest} or {}
		end,
		['@old'] = function() return special_selectors['@oldest']() end,
		['@veteran'] = function() return special_selectors['@oldest']() end,

		['@facing'] = function()
			local facing = {}
			local owner_hrp = stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart')
			if not owner_hrp then return {} end

			for _, plr in all_plrs do
				if plr ~= stuff.owner and plr.Character then
					local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
					if hrp then
						local to_me = (owner_hrp.Position - hrp.Position).Unit
						local their_look = hrp.CFrame.LookVector
						if to_me:Dot(their_look) > 0.7 then
							table.insert(facing, plr)
						end
					end
				end
			end
			return facing
		end,
		['@lookingat'] = function() return special_selectors['@facing']() end
	}

	if special_selectors[lower_name] then
		return special_selectors[lower_name]()
	end

	if lower_name:sub(1, 1) == '#' then
		local team_name = lower_name:sub(2):gsub('%s', '')
		local matched_players = {}

		for _, team in services.teams:GetTeams() do
			local team_name_lower = team.Name:lower():gsub('%s', '')
			if team_name_lower:match('^' .. team_name) or team_name_lower:find(team_name, 1, true) then
				for _, plr in team:GetPlayers() do
					table.insert(matched_players, plr)
				end
				break
			end
		end

		if #matched_players == 0 then
			for _, team in services.teams:GetTeams() do
				local team_name_lower = team.Name:lower():gsub('%s', '')
				if team_name_lower:find(team_name, 1, true) then
					for _, plr in team:GetPlayers() do
						table.insert(matched_players, plr)
					end
					break
				end
			end
		end

		return #matched_players > 0 and matched_players or nil
	end

	if lower_name:match('^%%d+$') then
		local user_id = tonumber(lower_name:sub(2))
		if user_id then
			for _, plr in all_plrs do
				if plr.UserId == user_id then
					return {plr}
				end
			end
		end
		return nil
	end

	if lower_name:match('^%*') then
		local pattern = lower_name:sub(2)
		local matched = {}
		for _, plr in all_plrs do
			if plr.Name:lower():find(pattern) or plr.DisplayName:lower():find(pattern) then
				table.insert(matched, plr)
			end
		end
		return #matched > 0 and matched or nil
	end

	lower_name = lower_name:gsub('%s', '')
	for _, plr in all_plrs do
		if plr.Name:lower():match('^' .. lower_name) or plr.DisplayName:lower():match('^' .. lower_name) then
			return {plr}
		end
	end

	for _, plr in all_plrs do
		if plr.Name:lower():find(lower_name, 1, true) or plr.DisplayName:lower():find(lower_name, 1, true) then
			return {plr}
		end
	end

	return nil
end

local function hwait(sig)
	return services.run_service[sig and tostring(sig) or 'Heartbeat']:Wait()
end

local function protect_gui(gui)
	if syn and syn.protect_gui then
		syn.protect_gui(gui)
		stuff.rawrbxset(gui, 'Parent', services.core_gui)
	elseif services.core_gui:FindFirstChild('RobloxGui') then
		stuff.rawrbxset(gui, 'Parent', services.core_gui.RobloxGui)
	else
		stuff.rawrbxset(gui, 'Parent', services.core_gui)
	end
end

local function deep_copy(t)
	if type(t) ~= 'table' then return t end
	local copy = {}
	for k, v in t do
		copy[deep_copy(k)] = deep_copy(v)
	end
	return copy
end

local function update_performance_stats()
	local now = tick()
	local dt = now - stuff.last_frame_time
	stuff.last_frame_time = now

	table.insert(stuff.frame_times, dt)
	if #stuff.frame_times > 60 then
		table.remove(stuff.frame_times, 1)
	end

	local sum = 0
	for _, t in stuff.frame_times do
		sum = sum + t
	end
	stuff.avg_fps = #stuff.frame_times / sum

	local ping = stuff.owner:GetNetworkPing()
	table.insert(stuff.ping_samples, ping)
	if #stuff.ping_samples > 30 then
		table.remove(stuff.ping_samples, 1)
	end

	local ping_sum = 0
	for _, p in stuff.ping_samples do
		ping_sum = ping_sum + p
	end
	stuff.avg_ping = (ping_sum / #stuff.ping_samples) * 1000
end

local function quick_predict_position(player, future)
	local char = player.Character
	if not char then return end
	if future == nil  then
		future  = ((char:FindFirstChildOfClass("Humanoid").WalkSpeed * 68.75) / 100)
	end

	local hrp = char:FindFirstChild('HumanoidRootPart')
	local humanoid = char:FindFirstChild('Humanoid')
	if not (hrp and humanoid) then return end

	local move_dir = humanoid.MoveDirection
	if move_dir == Vector3.zero then
		return hrp.CFrame
	end

	return hrp.CFrame + move_dir * future
end

local function predict_position(target, options)
	options = options or {}

	local base_time = options.time or 0.1
	local use_velocity = options.velocity ~= false
	local use_movedir = options.movedir ~= false
	local use_ping = options.ping ~= false
	local use_acceleration = options.acceleration or false
	local fallback_speed = options.fallback_speed or 16

	local character, part

	if typeof(target) == 'Instance' then
		if target:IsA('Model') then
			character = target
			part = target:FindFirstChild('HumanoidRootPart') or target:FindFirstChild('Head')
		elseif target:IsA('BasePart') then
			part = target
			character = target:FindFirstAncestorOfClass('Model')
		end
	end

	if not part then return nil end

	local base_position = part.Position
	local prediction_time = base_time

	if use_ping then
		prediction_time = prediction_time + stuff.owner:GetNetworkPing()
	end

	if prediction_time <= 0 then return base_position end

	local velocity = Vector3.zero
	local weight_total = 0

	if use_velocity and character then
		local hrp = character:FindFirstChild('HumanoidRootPart')
		if hrp then
			local assembly_vel = hrp.AssemblyLinearVelocity
			local horizontal_vel = Vector3.new(assembly_vel.X, 0, assembly_vel.Z)

			if horizontal_vel.Magnitude > 0.5 then
				velocity = velocity + horizontal_vel * 2
				weight_total = weight_total + 2
			end
		end
	end

	if use_movedir and character then
		local humanoid = character:FindFirstChildOfClass('Humanoid')
		if humanoid then
			local move_dir = humanoid.MoveDirection
			if move_dir.Magnitude > 0.1 then
				local walk_speed = humanoid.WalkSpeed or fallback_speed
				velocity = velocity + move_dir.Unit * walk_speed
				weight_total = weight_total + 1
			end
		end
	end

	if use_acceleration and character then
		local hrp = character:FindFirstChild('HumanoidRootPart')
		if hrp then
			local storage_key = tostring(character:GetDebugId())
			local history = stuff.velocity_history[storage_key] or {}

			local current_vel = hrp.AssemblyLinearVelocity
			local current_time = tick()

			table.insert(history, {vel = current_vel, time = current_time})

			while #history > 10 do
				table.remove(history, 1)
			end

			stuff.velocity_history[storage_key] = history

			if #history >= 3 then
				local oldest = history[1]
				local newest = history[#history]
				local dt = newest.time - oldest.time

				if dt > 0.05 then
					local acceleration = (newest.vel - oldest.vel) / dt
					local accel_horizontal = Vector3.new(acceleration.X, 0, acceleration.Z)

					if accel_horizontal.Magnitude < 100 then
						velocity = velocity + accel_horizontal * prediction_time * 0.5
						weight_total = weight_total + 0.5
					end
				end
			end
		end
	end

	if weight_total > 0 then
		velocity = velocity / weight_total
	end

	local predicted = base_position + velocity * prediction_time

	local max_prediction_distance = options.max_offset or (fallback_speed * prediction_time * 2)
	local offset = predicted - base_position
	if offset.Magnitude > max_prediction_distance then
		predicted = base_position + offset.Unit * max_prediction_distance
	end

	return predicted, velocity, prediction_time
end

local function get_target_part(character, part_name)
	if not character then return nil end

	local part_lookup = {
		head = {'Head'},
		torso = {'UpperTorso', 'Torso', 'LowerTorso'},
		hrp = {'HumanoidRootPart'},
		chest = {'UpperTorso', 'Torso'},
		pelvis = {'LowerTorso', 'Torso'},
		legs = {'LeftUpperLeg', 'RightUpperLeg', 'Left Leg', 'Right Leg'},
		arms = {'LeftUpperArm', 'RightUpperArm', 'Left Arm', 'Right Arm'}
	}

	local names = part_lookup[part_name:lower()] or part_lookup.head
	for _, name in names do
		local part = character:FindFirstChild(name)
		if part then return part end
	end

	return character:FindFirstChild('Head') or character:FindFirstChild('HumanoidRootPart')
end

local function is_target(player, ignore_team)
	if not player or player == stuff.owner then return false end
	if not ignore_team and player.Team and player.Team == stuff.owner.Team then return false end

	local char = player.Character
	if not char then return false end

	local hum = char:FindFirstChildOfClass('Humanoid')
	if not hum or hum.Health <= 0 then return false end
	if char:FindFirstChildOfClass('ForceField') then return false end

	return true
end

local function has_line_of_sight(origin, target_pos, ignore_character)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {stuff.owner_char, ignore_character}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, target_pos - origin, params)
	return result == nil
end

local function network_check(part)
	return part.ReceiveAge == 0
end

local function get_closest_part()
	local best_part, smallest_mag
	local head = stuff.owner_char and stuff.owner_char:FindFirstChild('Head')
	if not head then return nil end

	local head_pos = head.Position

	for _, v in workspace:GetDescendants() do
		if v:IsA('BasePart') and not v.Anchored and #v:GetConnectedParts() < 2 then
			if not v.Parent:FindFirstChildOfClass('Humanoid') and 
				not v.Parent.Parent:FindFirstChildOfClass('Humanoid') and 
				not v:IsDescendantOf(stuff.owner_char) then
				local mag = (head_pos - v.Position).Magnitude
				if not smallest_mag or mag < smallest_mag then
					smallest_mag, best_part = mag, v
				end
			end
		end
	end

	return best_part
end

local function find_f3x()
	local function has_api(t)
		for _, c in t:GetChildren() do
			if c:IsA("BindableFunction") and c.Name:lower():find("syncapi", 1, true) then
				return true
			end
		end
		return false
	end

	local function get_ep(t)
		for _, d in t:GetDescendants() do
			if not d:IsA("RemoteFunction") then continue end
			local n = d.Name:lower()
			if n:find("serverendpoint", 1, true) or n:find("apifunction", 1, true) then
				return d
			end
		end
		return nil
	end

	for _, c in { stuff.owner:FindFirstChild("Backpack"), stuff.owner.Character } do
		if not c then continue end
		for _, t in c:GetChildren() do
			if not t:IsA("Tool") then continue end
			if not has_api(t) then continue end
			local ep = get_ep(t)
			if ep then return t, ep end
		end
	end
	return nil, nil
end

local function sync(action, ...)
	local args = {...}
	local success, result = pcall(function()
		return stuff.server_endpoint:InvokeServer(action, unpack(args))
	end)
	if not success then return nil end
	return result
end

local function fov_to_radius(fov)
	local viewport_size = workspace.CurrentCamera.ViewportSize
	return math.tan(math.rad(fov / 2)) * (viewport_size.Y / 2)
end

local function get_move_vector(speed)
	speed = speed or 1

	if stuff.is_mobile then
		local success, control_module = pcall(function()
			return require(stuff.owner.PlayerScripts:WaitForChild('PlayerModule'):WaitForChild('ControlModule'))
		end)
		if success and control_module then
			local direction = control_module:GetMoveVector()
			return direction * speed
		end
		return Vector3.zero
	else
		if services.user_input_service:GetFocusedTextBox() ~= nil then
			return Vector3.zero
		end

		local direction = Vector3.zero
		if services.user_input_service:IsKeyDown(Enum.KeyCode.W) then
			direction = direction + Vector3.new(0, 0, -1)
		end
		if services.user_input_service:IsKeyDown(Enum.KeyCode.A) then
			direction = direction + Vector3.new(-1, 0, 0)
		end
		if services.user_input_service:IsKeyDown(Enum.KeyCode.S) then
			direction = direction + Vector3.new(0, 0, 1)
		end
		if services.user_input_service:IsKeyDown(Enum.KeyCode.D) then
			direction = direction + Vector3.new(1, 0, 0)
		end

		return direction * speed
	end
end

local function remove_notification(notification_data)
	if notification_data.removing then return end
	notification_data.removing = true

	for i, notif in ipairs(stuff.active_notifications) do
		if notif == notification_data then
			table.remove(stuff.active_notifications, i)
			break
		end
	end

	local tween_info = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tween = services.tween_service:Create(notification_data.label, tween_info, {
		BackgroundTransparency = 1,
		TextTransparency = 1,
		Position = notification_data.label.Position + UDim2.new(0.1, 0, 0, 0)
	})

	tween:Play()
	tween.Completed:Connect(function()
		notification_data.label:Destroy()
	end)
end

local function notify(log, text, log_type)
	if #stuff.active_notifications >= stuff.max_notifications then
		remove_notification(stuff.active_notifications[1])
	end

	local text_label = stuff.ui_notifications_template:Clone()
	local tween_info = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	text_label.Parent = stuff.ui_notifications_main_container
	text_label.Visible = true

	local colors = {
		[1] = Color3.fromRGB(239, 225, 255),
		[2] = Color3.fromRGB(227, 112, 144),
		[3] = Color3.fromRGB(227, 212, 144),
		[4] = Color3.fromRGB(127, 212, 244),
	}

	text_label.TextColor3 = colors[log_type] or colors[1]
	text_label.Text = ` [{tostring(log) or '?'}] {text} `
	text_label.BackgroundTransparency = 1
	text_label.TextTransparency = 1
	text_label.Position = text_label.Position - UDim2.new(0.1, 0, 0, 0)

	services.tween_service:Create(text_label, tween_info, {
		BackgroundTransparency = 0.1,
		TextTransparency = 0,
		Position = text_label.Position + UDim2.new(0.1, 0, 0, 0)
	}):Play()

	local notification_data = {
		label = text_label,
		created_at = tick(),
		removing = false
	}

	table.insert(stuff.active_notifications, notification_data)

	task.delay(4, function()
		remove_notification(notification_data)
	end)
end

local function str_to_type(str, t)
	if not t then return str end

	local converters;converters = {
		number = function(s) return tonumber(s) end,

		boolean = function(s)
			local lower = s:lower()
			if lower == 'true' or lower == '1' or lower == 'yes' or lower == 'on' then
				return true
			elseif lower == 'false' or lower == '0' or lower == 'no' or lower == 'off' then
				return false
			end
			return nil
		end,

		bool = function(s) return converters.boolean(s) end,
		string = function(s) return tostring(s) end,
		player = function(s) return get_plr(s) end,

		vector3 = function(s)
			local parts = {}
			for num in s:gmatch('[^,]+') do
				local n = tonumber(num:match('^%s*(.-)%s*$'))
				if n then table.insert(parts, n) end
			end
			if #parts == 3 then
				return Vector3.new(parts[1], parts[2], parts[3])
			end
			return nil
		end,

		vec3 = function(s) return converters.vector3(s) end,

		color3 = function(s)
			if s == 'team' then return 'team' end
			if s == 'rainbow' then return 'rainbow' end

			local hex = s:match('^#?(%x+)$')
			if hex then
				if #hex == 3 then
					local r = tonumber(hex:sub(1, 1):rep(2), 16)
					local g = tonumber(hex:sub(2, 2):rep(2), 16)
					local b = tonumber(hex:sub(3, 3):rep(2), 16)
					return Color3.fromRGB(r, g, b)
				elseif #hex == 6 then
					local r = tonumber(hex:sub(1, 2), 16)
					local g = tonumber(hex:sub(3, 4), 16)
					local b = tonumber(hex:sub(5, 6), 16)
					return Color3.fromRGB(r, g, b)
				end
			end

			local parts = {}
			for num in s:gmatch('[^,]+') do
				local n = tonumber(num:match('^%s*(.-)%s*$'))
				if n then table.insert(parts, n) end
			end
			if #parts == 3 then
				if parts[1] <= 1 and parts[2] <= 1 and parts[3] <= 1 then
					return Color3.new(parts[1], parts[2], parts[3])
				else
					return Color3.fromRGB(parts[1], parts[2], parts[3])
				end
			end

			return nil
		end,

		color = function(s) return converters.color3(s) end,

		cframe = function(s)
			local parts = {}
			for num in s:gmatch('[^,]+') do
				local n = tonumber(num:match('^%s*(.-)%s*$'))
				if n then table.insert(parts, n) end
			end

			if #parts >= 3 then
				return CFrame.new(parts[1], parts[2], parts[3])
			elseif #parts >= 7 then
				return CFrame.new(parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7])
			elseif #parts >= 12 then
				return CFrame.new(parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9], parts[10], parts[11], parts[12])
			end

			return nil
		end,

		table = function(s)
			local result = {}
			for item in s:gmatch('[^,]+') do
				table.insert(result, item:match('^%s*(.-)%s*$'))
			end
			return result
		end,

		array = function(s) return converters.table(s) end
	}

	if converters[t] then
		return converters[t](str)
	end

	notify('args', `invalid type '{t}' for string '{str}'`, 2)
	return nil
end

local function esp_frame_(parent)
	local esp_frame = Instance.new('Frame')
	stuff.rawrbxset(esp_frame, 'BackgroundTransparency', 1)
	stuff.rawrbxset(esp_frame, 'BorderSizePixel', 0)
	stuff.rawrbxset(esp_frame, 'AnchorPoint', Vector2.new(0.5, 0.5))
	stuff.rawrbxset(esp_frame, 'Parent', parent)

	local top = Instance.new('Frame')
	stuff.rawrbxset(top, 'Name', 'top')
	stuff.rawrbxset(top, 'Size', UDim2.new(1, 0, 0, 1))
	stuff.rawrbxset(top, 'Position', UDim2.new(0, 0, 0, 0))
	stuff.rawrbxset(top, 'BorderSizePixel', 0)
	stuff.rawrbxset(top, 'Parent', esp_frame)

	local bottom = Instance.new('Frame')
	stuff.rawrbxset(bottom, 'Name', 'bottom')
	stuff.rawrbxset(bottom, 'Size', UDim2.new(1, 0, 0, 1))
	stuff.rawrbxset(bottom, 'Position', UDim2.new(0, 0, 1, -1))
	stuff.rawrbxset(bottom, 'BorderSizePixel', 0)
	stuff.rawrbxset(bottom, 'Parent', esp_frame)

	local left = Instance.new('Frame')
	stuff.rawrbxset(left, 'Name', 'left')
	stuff.rawrbxset(left, 'Size', UDim2.new(0, 1, 1, 0))
	stuff.rawrbxset(left, 'Position', UDim2.new(0, 0, 0, 0))
	stuff.rawrbxset(left, 'BorderSizePixel', 0)
	stuff.rawrbxset(left, 'Parent', esp_frame)

	local right = Instance.new('Frame')
	stuff.rawrbxset(right, 'Name', 'right')
	stuff.rawrbxset(right, 'Size', UDim2.new(0, 1, 1, 0))
	stuff.rawrbxset(right, 'Position', UDim2.new(1, -1, 0, 0))
	stuff.rawrbxset(right, 'BorderSizePixel', 0)
	stuff.rawrbxset(right, 'Parent', esp_frame)

	local name_label = Instance.new('TextLabel')
	stuff.rawrbxset(name_label, 'Name', 'name')
	stuff.rawrbxset(name_label, 'Size', UDim2.new(1, 0, 0, 18))
	stuff.rawrbxset(name_label, 'Position', UDim2.new(0, 0, 0, -20))
	stuff.rawrbxset(name_label, 'BackgroundTransparency', 1)
	stuff.rawrbxset(name_label, 'BorderSizePixel', 0)
	stuff.rawrbxset(name_label, 'TextSize', 14)
	stuff.rawrbxset(name_label, 'Font', Enum.Font.Code)
	stuff.rawrbxset(name_label, 'TextStrokeTransparency', 0.5)
	stuff.rawrbxset(name_label, 'TextStrokeColor3', Color3.new(0, 0, 0))
	stuff.rawrbxset(name_label, 'TextYAlignment', Enum.TextYAlignment.Bottom)
	stuff.rawrbxset(name_label, 'Parent', esp_frame)

	local distance_label = Instance.new('TextLabel')
	stuff.rawrbxset(distance_label, 'Name', 'distance')
	stuff.rawrbxset(distance_label, 'Size', UDim2.new(1, 0, 0, 14))
	stuff.rawrbxset(distance_label, 'Position', UDim2.new(0, 0, 1, 2))
	stuff.rawrbxset(distance_label, 'BackgroundTransparency', 1)
	stuff.rawrbxset(distance_label, 'BorderSizePixel', 0)
	stuff.rawrbxset(distance_label, 'TextSize', 12)
	stuff.rawrbxset(distance_label, 'Font', Enum.Font.Code)
	stuff.rawrbxset(distance_label, 'TextStrokeTransparency', 0.5)
	stuff.rawrbxset(distance_label, 'TextStrokeColor3', Color3.new(0, 0, 0))
	stuff.rawrbxset(distance_label, 'TextYAlignment', Enum.TextYAlignment.Top)
	stuff.rawrbxset(distance_label, 'Parent', esp_frame)

	local health_bg = Instance.new('Frame')
	stuff.rawrbxset(health_bg, 'Name', 'health_bg')
	stuff.rawrbxset(health_bg, 'Size', UDim2.new(0, 3, 1, 0))
	stuff.rawrbxset(health_bg, 'Position', UDim2.new(1, 4, 0, 0))
	stuff.rawrbxset(health_bg, 'BackgroundColor3', Color3.new(0.1, 0.1, 0.1))
	stuff.rawrbxset(health_bg, 'BorderSizePixel', 0)
	stuff.rawrbxset(health_bg, 'Parent', esp_frame)

	local health_bar = Instance.new('Frame')
	stuff.rawrbxset(health_bar, 'Name', 'health_bar')
	stuff.rawrbxset(health_bar, 'Size', UDim2.new(1, 0, 1, 0))
	stuff.rawrbxset(health_bar, 'Position', UDim2.new(0, 0, 1, 0))
	stuff.rawrbxset(health_bar, 'AnchorPoint', Vector2.new(0, 1))
	stuff.rawrbxset(health_bar, 'BackgroundColor3', Color3.fromRGB(0, 255, 0))
	stuff.rawrbxset(health_bar, 'BorderSizePixel', 0)
	stuff.rawrbxset(health_bar, 'Parent', health_bg)

	local health_text = Instance.new('TextLabel')
	stuff.rawrbxset(health_text, 'Name', 'health_text')
	stuff.rawrbxset(health_text, 'Size', UDim2.new(0, 30, 0, 14))
	stuff.rawrbxset(health_text, 'Position', UDim2.new(1, 5, 1, -14))
	stuff.rawrbxset(health_text, 'BackgroundTransparency', 1)
	stuff.rawrbxset(health_text, 'BorderSizePixel', 0)
	stuff.rawrbxset(health_text, 'TextSize', 12)
	stuff.rawrbxset(health_text, 'Font', Enum.Font.Code)
	stuff.rawrbxset(health_text, 'TextStrokeTransparency', 0.5)
	stuff.rawrbxset(health_text, 'TextStrokeColor3', Color3.new(0, 0, 0))
	stuff.rawrbxset(health_text, 'TextXAlignment', Enum.TextXAlignment.Left)
	stuff.rawrbxset(health_text, 'Parent', health_bg)

	local tool_label = Instance.new('TextLabel')
	stuff.rawrbxset(tool_label, 'Name', 'tool')
	stuff.rawrbxset(tool_label, 'Size', UDim2.new(0, 100, 0, 50))
	stuff.rawrbxset(tool_label, 'Position', UDim2.new(0, -104, 0, 0))
	stuff.rawrbxset(tool_label, 'BackgroundTransparency', 1)
	stuff.rawrbxset(tool_label, 'BorderSizePixel', 0)
	stuff.rawrbxset(tool_label, 'TextSize', 12)
	stuff.rawrbxset(tool_label, 'Font', Enum.Font.Code)
	stuff.rawrbxset(tool_label, 'TextStrokeTransparency', 0.5)
	stuff.rawrbxset(tool_label, 'TextStrokeColor3', Color3.new(0, 0, 0))
	stuff.rawrbxset(tool_label, 'TextXAlignment', Enum.TextXAlignment.Right)
	stuff.rawrbxset(tool_label, 'TextYAlignment', Enum.TextYAlignment.Top)
	stuff.rawrbxset(tool_label, 'TextWrapped', false)
	stuff.rawrbxset(tool_label, 'Parent', esp_frame)

	return esp_frame
end

local function esp_gui_()
	local gui = Instance.new('ScreenGui')
	stuff.rawrbxset(gui, 'ResetOnSpawn', false)
	stuff.rawrbxset(gui, 'IgnoreGuiInset', true)
	stuff.rawrbxset(gui, 'DisplayOrder', 2147483647)
	stuff.rawrbxset(gui, 'Parent', services.core_gui)
	return gui
end

local function update_esp_frame(esp_frame, box_width, box_height, box_center_x, box_center_y, esp_color, display_name, distance, health_data, tool_names, show_health)
	stuff.rawrbxset(esp_frame, 'Visible', true)
	stuff.rawrbxset(esp_frame, 'Size', UDim2.new(0, box_width, 0, box_height))
	stuff.rawrbxset(esp_frame, 'Position', UDim2.new(0, box_center_x, 0, box_center_y))

	local top = esp_frame:FindFirstChild('top')
	local bottom = esp_frame:FindFirstChild('bottom')
	local left = esp_frame:FindFirstChild('left')
	local right = esp_frame:FindFirstChild('right')
	local name_label = esp_frame:FindFirstChild('name')
	local distance_label = esp_frame:FindFirstChild('distance')
	local health_bg = esp_frame:FindFirstChild('health_bg')
	local tool_label = esp_frame:FindFirstChild('tool')

	stuff.rawrbxset(top, 'BackgroundColor3', esp_color)
	stuff.rawrbxset(bottom, 'BackgroundColor3', esp_color)
	stuff.rawrbxset(left, 'BackgroundColor3', esp_color)
	stuff.rawrbxset(right, 'BackgroundColor3', esp_color)

	stuff.rawrbxset(name_label, 'Text', display_name)
	stuff.rawrbxset(name_label, 'TextColor3', esp_color)

	stuff.rawrbxset(distance_label, 'Text', `[{distance}m]`)
	stuff.rawrbxset(distance_label, 'TextColor3', Color3.fromRGB(200, 200, 200))

	stuff.rawrbxset(health_bg, 'Visible', show_health)

	if show_health and health_data then
		local health_bar = health_bg:FindFirstChild('health_bar')
		local health_text = health_bg:FindFirstChild('health_text')

		stuff.rawrbxset(health_bar, 'Size', UDim2.new(1, 0, health_data.percent, 0))
		stuff.rawrbxset(health_bar, 'BackgroundColor3', health_data.color)
		stuff.rawrbxset(health_text, 'Text', health_data.text)
		stuff.rawrbxset(health_text, 'TextColor3', health_data.color)
	end

	stuff.rawrbxset(tool_label, 'Text', tool_names or '')
	stuff.rawrbxset(tool_label, 'TextColor3', Color3.fromRGB(200, 200, 200))
	stuff.rawrbxset(tool_label, 'Visible', tool_names and #tool_names > 0)
end

local function get_bounding_box_screen(camera, cf, size)
	local half_size = size / 1.8

	local corners = {
		(cf * CFrame.new(half_size.X, half_size.Y, half_size.Z)).Position,
		(cf * CFrame.new(-half_size.X, half_size.Y, half_size.Z)).Position,
		(cf * CFrame.new(half_size.X, -half_size.Y, half_size.Z)).Position,
		(cf * CFrame.new(-half_size.X, -half_size.Y, half_size.Z)).Position,
		(cf * CFrame.new(half_size.X, half_size.Y, -half_size.Z)).Position,
		(cf * CFrame.new(-half_size.X, half_size.Y, -half_size.Z)).Position,
		(cf * CFrame.new(half_size.X, -half_size.Y, -half_size.Z)).Position,
		(cf * CFrame.new(-half_size.X, -half_size.Y, -half_size.Z)).Position
	}

	local min_x, min_y = math.huge, math.huge
	local max_x, max_y = -math.huge, -math.huge

	for _, corner in corners do
		local screen_pos = camera:WorldToViewportPoint(corner)
		min_x = math.min(min_x, screen_pos.X)
		min_y = math.min(min_y, screen_pos.Y)
		max_x = math.max(max_x, screen_pos.X)
		max_y = math.max(max_y, screen_pos.Y)
	end

	return max_x - min_x, max_y - min_y, (min_x + max_x) / 2, (min_y + max_y) / 2
end

local function get_health_data(humanoid)
	local health = stuff.rawrbxget(humanoid, 'Health')
	local max_health = stuff.rawrbxget(humanoid, 'MaxHealth')
	local health_percent = math.clamp(health / max_health, 0, 1)
	local health_color = Color3.fromRGB(math.floor(255 * (1 - health_percent)), math.floor(255 * health_percent), 0)

	return {
		percent = health_percent,
		color = health_color,
		text = tostring(math.floor(health))
	}
end

local function highlight_(char, esp_color)
	local highlight = Instance.new('Highlight')
	stuff.rawrbxset(highlight, 'Adornee', char)
	stuff.rawrbxset(highlight, 'FillColor', esp_color)
	stuff.rawrbxset(highlight, 'FillTransparency', 0.75)
	stuff.rawrbxset(highlight, 'OutlineColor', esp_color)
	stuff.rawrbxset(highlight, 'OutlineTransparency', 0.5)
	stuff.rawrbxset(highlight, 'DepthMode', Enum.HighlightDepthMode.AlwaysOnTop)
	stuff.rawrbxset(highlight, 'Parent', services.core_gui)
	return highlight
end

local function update_highlight(highlight, char, esp_color)
	stuff.rawrbxset(highlight, 'Enabled', true)
	if stuff.rawrbxget(highlight, 'Adornee') ~= char then
		stuff.rawrbxset(highlight, 'Adornee', char)
	end
	stuff.rawrbxset(highlight, 'FillColor', esp_color)
	stuff.rawrbxset(highlight, 'OutlineColor', esp_color)
end

local function tracer_line_(parent)
	local line = Instance.new('Frame')
	stuff.rawrbxset(line, 'Name', 'tracer')
	stuff.rawrbxset(line, 'BorderSizePixel', 0)
	stuff.rawrbxset(line, 'AnchorPoint', Vector2.new(0.5, 0.5))
	stuff.rawrbxset(line, 'Parent', parent)

	local outline = Instance.new('UIStroke')
	stuff.rawrbxset(outline, 'Color', Color3.new(0, 0, 0))
	stuff.rawrbxset(outline, 'Thickness', 1)
	stuff.rawrbxset(outline, 'Transparency', 0.5)
	stuff.rawrbxset(outline, 'Parent', line)

	return line
end

local function tracer_arrow_(parent, arrow_size)
	local arrow = Instance.new('ImageLabel')
	stuff.rawrbxset(arrow, 'Name', 'arrow')
	stuff.rawrbxset(arrow, 'BackgroundTransparency', 1)
	stuff.rawrbxset(arrow, 'AnchorPoint', Vector2.new(0.5, 0.5))
	stuff.rawrbxset(arrow, 'Size', UDim2.new(0, arrow_size, 0, arrow_size))
	stuff.rawrbxset(arrow, 'Image', 'rbxassetid://3926305904')
	stuff.rawrbxset(arrow, 'ImageRectOffset', Vector2.new(524, 763))
	stuff.rawrbxset(arrow, 'ImageRectSize', Vector2.new(36, 36))
	stuff.rawrbxset(arrow, 'ResampleMode',Enum.ResamplerMode.Pixelated)
	stuff.rawrbxset(arrow, 'Parent', parent)

	local distance_label = Instance.new('TextLabel')
	stuff.rawrbxset(distance_label, 'Name', 'distance')
	stuff.rawrbxset(distance_label, 'BackgroundTransparency', 1)
	stuff.rawrbxset(distance_label, 'Size', UDim2.new(0, 50, 0, 14))
	stuff.rawrbxset(distance_label, 'Position', UDim2.new(0.5, 0, 1, 2))
	stuff.rawrbxset(distance_label, 'AnchorPoint', Vector2.new(0.5, 0))
	stuff.rawrbxset(distance_label, 'Font', Enum.Font.Code)
	stuff.rawrbxset(distance_label, 'TextSize', 10)
	stuff.rawrbxset(distance_label, 'TextStrokeTransparency', 0.5)
	stuff.rawrbxset(distance_label, 'TextStrokeColor3', Color3.new(0, 0, 0))
	stuff.rawrbxset(distance_label, 'Parent', arrow)

	return arrow
end

local function update_tracer_line(line, start_x, start_y, end_x, end_y, color, thickness, transparency)
	local dx = end_x - start_x
	local dy = end_y - start_y
	local distance = math.sqrt(dx * dx + dy * dy)
	local angle = math.deg(math.atan2(dy, dx))

	stuff.rawrbxset(line, 'BackgroundColor3', color)
	stuff.rawrbxset(line, 'BackgroundTransparency', transparency)
	stuff.rawrbxset(line, 'Size', UDim2.new(0, distance, 0, thickness))
	stuff.rawrbxset(line, 'Position', UDim2.new(0, (start_x + end_x) / 2, 0, (start_y + end_y) / 2))
	stuff.rawrbxset(line, 'Rotation', angle)
	stuff.rawrbxset(line, 'Visible', true)
end

local function update_tracer_arrow(arrow, camera, center_x, center_y, hrp_pos, owner_pos, color, arrow_distance)
	local direction = (hrp_pos - camera.CFrame.Position).Unit
	local screen_direction = Vector2.new(
		direction:Dot(camera.CFrame.RightVector),
		-direction:Dot(camera.CFrame.UpVector)
	).Unit

	local arrow_dist = math.min(center_x, center_y) - arrow_distance
	local arrow_x = center_x + screen_direction.X * arrow_dist
	local arrow_y = center_y + screen_direction.Y * arrow_dist
	local arrow_angle = math.deg(math.atan2(screen_direction.Y, screen_direction.X)) + 90

	local dist_text = ''
	if owner_pos then
		local dist = math.floor((owner_pos - hrp_pos).Magnitude)
		dist_text = `{dist}m`
	end

	local distance_label = arrow:FindFirstChild('distance')
	if distance_label then
		stuff.rawrbxset(distance_label, 'Text', dist_text)
		stuff.rawrbxset(distance_label, 'TextColor3', color)
		stuff.rawrbxset(distance_label, 'Rotation', -arrow_angle)
	end

	stuff.rawrbxset(arrow, 'ImageColor3', color)
	stuff.rawrbxset(arrow, 'Position', UDim2.new(0, arrow_x, 0, arrow_y))
	stuff.rawrbxset(arrow, 'Rotation', arrow_angle)
	stuff.rawrbxset(arrow, 'Visible', true)
end

local function get_tracer_start(mode, viewport, mouse_pos)
	local center_x = viewport.X / 2
	local center_y = viewport.Y / 2

	if mode == 'center' then
		return center_x, center_y
	elseif mode == 'mouse' then
		return mouse_pos.X, mouse_pos.Y
	else
		return center_x, viewport.Y
	end
end

local function is_npc(model)
	if not model:IsA('Model') then return false end

	local humanoid = model:FindFirstChildOfClass('Humanoid')
	local root = model:FindFirstChild('HumanoidRootPart')
	if not humanoid or not root then return false end

	for _, plr in services.players:GetPlayers() do
		if plr.Character == model then return false end
	end

	if model == stuff.owner_char then return false end

	return true
end

local function is_item(obj)
	if obj:IsA('Tool') and obj.Parent == workspace then
		return true
	end

	if obj:IsA('Model') and obj:FindFirstChild('Handle') and not obj:FindFirstChildOfClass('Humanoid') then
		return true
	end

	return false
end

local function cleanup_esp(vstorage, highlights_key)
	for _, frame in vstorage.frames or {} do
		pcall(stuff.destroy, frame)
	end

	for _, highlight in vstorage.highlights or {} do
		pcall(stuff.destroy, highlight)
	end

	if vstorage.screen_gui then
		pcall(stuff.destroy, vstorage.screen_gui)
		vstorage.screen_gui = nil
	end

	table.clear(vstorage.frames or {})
	table.clear(vstorage.highlights or {})
end

local function cleanup_tracers(vstorage)
	for _, line in vstorage.lines or {} do
		pcall(stuff.destroy, line)
	end

	for _, arrow in vstorage.arrows or {} do
		pcall(stuff.destroy, arrow)
	end

	if vstorage.gui then
		pcall(stuff.destroy, vstorage.gui)
		vstorage.gui = nil
	end

	table.clear(vstorage.lines or {})
	table.clear(vstorage.arrows or {})
end

local maid = {
	_tasks = {},
	_protected = {},
	_cleaner = nil
}

function maid.add(name, task_or_signal, fn, important)
	if maid._tasks[name] then
		maid.remove(name)
	elseif maid._protected[name] then
		if important then
			maid.remove_protected(name)
		else
			notify('maid', `tried to overwrite protected task {name}`, 3)
			return
		end
	end

	local task_obj, task_type

	if typeof(task_or_signal) == 'RBXScriptSignal' and fn then
		task_obj = stuff.connect(task_or_signal, fn)
		task_type = 'connection'
	elseif typeof(task_or_signal) == 'RBXScriptConnection' then
		task_obj = task_or_signal
		task_type = 'connection'
	elseif typeof(task_or_signal) == 'Instance' then
		task_obj = task_or_signal
		task_type = 'instance'
	elseif typeof(task_or_signal) == 'thread' then
		task_obj = task_or_signal
		task_type = 'thread'
	elseif typeof(task_or_signal) == 'function' then
		task_obj = task_or_signal
		task_type = 'function'
	else
		notify('maid', `tried to add task {name} with unknown type {typeof(task_or_signal)}`, 3)
		return
	end

	local storage = important == 1 and maid._protected or maid._tasks
	storage[name] = {task = task_obj, type = task_type}
end

function maid.remove(name)
	local task_data = maid._tasks[name]
	if task_data then
		maid._cleanup_task(task_data)
		maid._tasks[name] = nil
		return true
	end
	return false
end

function maid.remove_protected(name)
	local task_data = maid._protected[name]
	if task_data then
		maid._cleanup_task(task_data)
		maid._protected[name] = nil
		return true
	end
	return false
end

function maid._cleanup_task(task_data)
	if not task_data then return end

	pcall(function()
		if task_data.type == 'connection' then
			local conn = task_data.task
			if typeof(conn) == 'RBXScriptConnection' and conn.Connected then
				stuff.disconnect(conn)
			end
		elseif task_data.type == 'instance' then
			local inst = task_data.task
			if typeof(inst) == 'Instance' and inst.Parent then
				pcall(stuff.destroy, inst)
			end
		elseif task_data.type == 'thread' then
			local thread = task_data.task
			if coroutine.status(thread) ~= 'dead' then
				task.cancel(thread)
			end
		elseif task_data.type == 'function' then
			pcall(task_data.task)
		end
	end)
end

function maid.clean(keep_protected)
	for name, task_data in maid._tasks do
		maid._cleanup_task(task_data)
	end
	table.clear(maid._tasks)

	if not keep_protected then
		for name, task_data in maid._protected do
			maid._cleanup_task(task_data)
		end
		table.clear(maid._protected)
	end
end

function maid.get(name)
	local task_data = maid._tasks[name] or maid._protected[name]
	return task_data and task_data.task or nil
end

function maid.exists(name)
	return maid._tasks[name] ~= nil or maid._protected[name] ~= nil
end

do
	local con = stuff.connect(game.Changed, stuff.empty_function)
	stuff.disconnect = con.Disconnect
	pcall(stuff.disconnect, con)

	stuff.rawrbxset = function(obj, key, value)
		obj[key] = value
	end

	stuff.rawrbxget = function(obj, key)
		return obj[key]
	end

	local hum = stuff.owner_char:WaitForChild('Humanoid', 10)
	if hum then
		stuff.default_ws = hum.WalkSpeed or services.starter_player.CharacterWalkSpeed
		pcall(function()
			stuff.default_jp = hum.JumpPower or services.starter_player.CharacterJumpPower
		end)
	end

	maid._cleaner = stuff.connect(services.run_service.Heartbeat, function()
		update_performance_stats()

		for name, task_data in maid._tasks do
			if task_data.type == 'connection' then
				local conn = task_data.task
				if typeof(conn) == 'RBXScriptConnection' and not conn.Connected then
					maid._tasks[name] = nil
				end
			elseif task_data.type == 'instance' then
				local inst = task_data.task
				if typeof(inst) == 'Instance' and not inst.Parent then
					maid._tasks[name] = nil
				end
			end
		end
	end)

	maid.add('local_character_added', stuff.owner.CharacterAdded, function(character)
		stuff.owner_char = character

		local hum = character:WaitForChild('Humanoid', 10)
		if hum then
			stuff.default_ws = hum.WalkSpeed
			pcall(function()
				stuff.default_jp = hum.JumpPower
			end)
		end
	end, 1)

	maid.add('clean_highlights', services.run_service.Stepped, function()
		for plr, highlight in stuff.highlights do
			if highlight and not (highlight.Adornee and highlight.Adornee:IsDescendantOf(workspace)) then
				pcall(stuff.destroy, highlight)
				stuff.highlights[plr] = nil
			end
		end
	end, 1)
end

local cmd_library = {
	_commands = {},
	_command_map = {},
	_plugins = {},
	_on_command_added = nil,
	_on_command_removed = nil
}

maid.add("part_freeze_connection",services.run_service.Heartbeat,function()
	for inumber, v in pairs(parts_frozen) do
		if v.Part == nil or v.Part:IsDescendantOf(nil) == false then
			table.remove(parts_frozen,inumber)
			continue
		end
		v.Part.Velocity = Vector3.zero
		v.Part.CFrame = v.CFrame
	end
end,true)

function cmd_library.parse_command(input)
	if type(input) ~= 'string' then return {} end

	local commands = {}
	for raw_cmd in input:gmatch('[^;]+') do
		raw_cmd = raw_cmd:match('^%s*(.-)%s*$')
		if raw_cmd ~= '' then
			local parts = {}
			for part in raw_cmd:gmatch('%S+') do
				parts[#parts + 1] = part
			end
			if #parts > 0 then
				local cmd = parts[1]
				table.remove(parts, 1)
				commands[#commands + 1] = {cmd = cmd, args = parts}
			end
		end
	end

	return commands
end

function cmd_library.add(names, description, args, fn)
	local primary_name = names[1]:lower()

	if cmd_library._command_map[primary_name] then
		return warn(`command '{names[1]}' already exists`, 0)
	end

	local cmd_data = {
		names = names,
		description = description,
		args = args,
		fn = fn,
		variable_storage = {},
		plugin = nil,
		created_at = tick()
	}

	table.insert(cmd_library._commands, cmd_data)

	for _, name in names do
		cmd_library._command_map[name:lower()] = cmd_data
	end

	if cmd_library._on_command_added then
		cmd_library._on_command_added(cmd_data)
	end

	return cmd_data
end

function cmd_library.register_plugin(plugin_name, plugin_data)
	if cmd_library._plugins[plugin_name:lower()] then
		return nil, 'plugin already registered'
	end

	cmd_library._plugins[plugin_name:lower()] = {
		name = plugin_name,
		version = plugin_data.version or '1.0.0',
		author = plugin_data.author or 'unknown',
		description = plugin_data.description or '',
		commands = {},
		loaded = true,
		data = plugin_data.data or {}
	}

	return cmd_library._plugins[plugin_name:lower()]
end

function cmd_library.add_plugin_command(plugin_name, names, description, args, fn)
	local plugin = cmd_library._plugins[plugin_name:lower()]
	if not plugin then
		return nil, 'plugin not found'
	end

	local cmd_data = cmd_library.add(names, description, args, fn)
	if cmd_data then
		cmd_data.plugin = plugin_name
		table.insert(plugin.commands, {
			names = names,
			description = description,
			args = args
		})
	end

	return cmd_data
end

function cmd_library.get_plugins()
	local plugins = {}
	for name, plugin in cmd_library._plugins do
		table.insert(plugins, {
			name = plugin.name,
			version = plugin.version,
			author = plugin.author,
			description = plugin.description,
			command_count = #plugin.commands,
			loaded = plugin.loaded
		})
	end
	return plugins
end

function cmd_library.remove_plugin(plugin_name)
	local plugin = cmd_library._plugins[plugin_name:lower()]
	if not plugin then
		return false, 'plugin not found'
	end

	for i = #cmd_library._commands, 1, -1 do
		local cmd = cmd_library._commands[i]
		if cmd.plugin and cmd.plugin:lower() == plugin_name:lower() then
			for _, name in cmd.names do
				cmd_library._command_map[name:lower()] = nil
			end

			if cmd_library._on_command_removed then
				cmd_library._on_command_removed(cmd)
			end

			table.remove(cmd_library._commands, i)
		end
	end

	cmd_library._plugins[plugin_name:lower()] = nil
	return true
end

function cmd_library.find(name)
	return cmd_library._command_map[name:lower()]
end

function cmd_library.remove(name)
	local cmd_data = cmd_library._command_map[name:lower()]
	if not cmd_data then return false end

	for _, cmd_name in cmd_data.names do
		cmd_library._command_map[cmd_name:lower()] = nil
	end

	for i, cmd in cmd_library._commands do
		if cmd == cmd_data then
			if cmd_library._on_command_removed then
				cmd_library._on_command_removed(cmd_data)
			end

			table.remove(cmd_library._commands, i)
			break
		end
	end

	return true
end

function cmd_library.get_variable_storage(name)
	local cmd_data = cmd_library._command_map[name:lower()]
	return cmd_data and cmd_data.variable_storage
end

function cmd_library.find_similar(name)
	local similar = {}
	local search = name:lower()

	for cmd_name in cmd_library._command_map do
		if cmd_name:sub(1, #search) == search then
			table.insert(similar, cmd_name)
		elseif cmd_name:find(search, 1, true) then
			table.insert(similar, cmd_name)
		end
	end

	return similar
end

function cmd_library.execute(name, ...)
	if not name or name == '' then
		notify('cmd', 'no command specified', 2)
		return false
	end

	local cmd_data = cmd_library._command_map[name:lower()]

	if not cmd_data then
		local similar = cmd_library.find_similar(name)
		if #similar > 0 then
			notify('cmd', `couldn't find '{name}'. did you mean: {table.concat(similar, ', ')}?`, 2)
		else
			notify('cmd', `couldn't find command '{name}'`, 2)
		end
		return false
	end

	if name ~= 'lastcommand' and name ~= 'lcmd' then
		stuff.last_command = {
			name = name,
			args = {...}
		}
	end

	local vargs = {...}
	local fvargs = {}

	local has_varargs = false
	local vararg_type = nil
	local vararg_start_idx = 1

	for i, arg_def in cmd_data.args do
		if type(arg_def) == 'table' and arg_def['...'] then
			has_varargs = true
			vararg_type = arg_def['...']
			vararg_start_idx = i
			break
		end
	end

	if has_varargs then
		for i = 1, vararg_start_idx - 1 do
			if vargs[i] then
				local arg_type = cmd_data.args[i] and cmd_data.args[i][2] or nil
				local converted = str_to_type(vargs[i], arg_type)
				table.insert(fvargs, converted)
			end
		end

		for i = vararg_start_idx, #vargs do
			local converted = str_to_type(vargs[i], vararg_type)
			table.insert(fvargs, converted)
		end
	else
		for i, arg in vargs do
			local arg_type = cmd_data.args[i] and cmd_data.args[i][2] or nil
			local converted = str_to_type(arg, arg_type)
			table.insert(fvargs, converted)
		end
	end

	task.spawn(function()
		local success, err = xpcall(function()
			cmd_data.fn(cmd_data.variable_storage, unpack(fvargs))
		end, function(msg)
			return debug.traceback(msg, 2)
		end)

		if not success then
			notify('cmd', `error in '{name}': {tostring(err):match("[^\n]*")}`, 2)
			notify('szadmin error', 'report this to the developer, open console for the full error (F9)', 4)
			warn(`[SZAdmin] command '{name}' failed:`, err)
		end
	end)

	return true
end

function cmd_library.clear()
	cmd_library._commands = {}
	cmd_library._command_map = {}
	cmd_library._plugins = {}
end

function cmd_library.help(name)
	if name then
		local cmd_data = cmd_library._command_map[name:lower()]
		if cmd_data then
			return {
				names = cmd_data.names,
				description = cmd_data.description,
				args = cmd_data.args,
				plugin = cmd_data.plugin
			}
		end
	else
		local help_list = {}
		for _, cmd in cmd_library._commands do
			table.insert(help_list, {
				names = cmd.names,
				description = cmd.description,
				args = cmd.args,
				plugin = cmd.plugin
			})
		end
		return help_list
	end
end

local config = {
	file_name = 'szadmin_settings.json',
	current_game_id = tostring(game.PlaceId),
	default_settings = {
		open_keybind = env['szadmin'].szadmin_open_keybind and env['szadmin'].szadmin_open_keybind.Name or 'RightBracket',
		chat_prefix = '!',
		ui_asset = "rbxassetid://121800440973428",
		aliases = {},
		binds = {},
		saved_plugins = {}
	},
	current_settings = {}
}

function config.load()
	if readfile and isfile then
		if isfile(config.file_name) then
			local success, result = pcall(function()
				return services.http:JSONDecode(readfile(config.file_name))
			end)

			if success and result then
				config.current_settings = result

				for key, default_value in config.default_settings do
					if config.current_settings[key] == nil then
						config.current_settings[key] = default_value
					end
				end

				return true
			end
		end
	end

	config.current_settings = deep_copy(config.default_settings)
	return false
end

function config.save()
	if writefile then
		local success = pcall(function()
			writefile(config.file_name, services.http:JSONEncode(config.current_settings))
		end)

		return success
	end

	return false
end

function config.get(key)
	return config.current_settings[key]
end

function config.set(key, value)
	config.current_settings[key] = value
	return config.save()
end

function config.reset(key)
	if key then
		config.current_settings[key] = config.default_settings[key]
	else
		config.current_settings = deep_copy(config.default_settings)
	end
	return config.save()
end

function config.get_game_binds()
	local binds = config.get('binds') or {}
	if not binds[config.current_game_id] then
		binds[tostring(config.current_game_id)] = {}
	end
	return binds[config.current_game_id]
end

function config.set_game_binds(game_binds)
	local binds = config.get('binds') or {}
	binds[config.current_game_id] = game_binds
	return config.set('binds', binds)
end

function config.apply()
	local settings = config.current_settings

	if settings.open_keybind then
		if settings.open_keybind:len() == 1 then
			settings.open_keybind = settings.open_keybind:upper()
		end
		stuff.open_keybind = Enum.KeyCode[settings.open_keybind] or Enum.KeyCode.RightBracket
	end

	if settings.chat_prefix then
		stuff.chat_prefix = settings.chat_prefix
	end

	if settings.aliases then
		for alias, command in settings.aliases do
			local cmd_data = cmd_library._command_map[command:lower()]
			if cmd_data then
				table.insert(cmd_data.names, alias)
				cmd_library._command_map[alias:lower()] = cmd_data
			end
		end
	end

	local game_binds = config.get_game_binds()
	if game_binds and next(game_binds) then
		local bind_vs = cmd_library.get_variable_storage('bind')
		bind_vs.binds = bind_vs.binds or {}

		for bind_id, bind_data in pairs(game_binds) do
			local keycode = Enum.KeyCode[bind_data.key]
			if keycode and cmd_library._command_map[bind_data.command:lower()] then
				bind_vs.binds[bind_id] = {
					key = bind_data.key,
					command = bind_data.command,
					args = bind_data.args or {}
				}

				maid.add(bind_id, services.user_input_service.InputBegan, function(input, processed)
					if input.KeyCode == keycode and not processed then
						cmd_library.execute(bind_data.command, unpack(bind_data.args or {}))
					end
				end)
			end
		end
	end

	for plugin_name, url in settings.saved_plugins do
		cmd_library.execute('pluginload', url)
	end
end

local function load_ui()
	local ui_asset = config.get('ui_asset') or 'rbxassetid://121800440973428'

	local ui = workspace:FindFirstChild('szadmin_ui')
	if not ui then
		local success, result = pcall(function()
			return game:GetObjects(ui_asset)[1]
		end)

		if success and result then
			ui = result
		end
	end

	if ui then
		return ui:Clone()
	end

	return nil
end

stuff.ui = load_ui()
if not stuff.ui then
	return error('[SZAdmin] ui failed to load')
end

config.load()

local hook_lib = {
	active_hooks = {},
	presets = {}
}

function hook_lib.create_hook(name, hooks)
	if hook_lib.active_hooks[name] then
		hook_lib.destroy_hook(name)
	end

	local hook_data = {
		hooks = {},
		function_hooks = {},
		enabled = true
	}

	if hooks.namecall and hookmetamethod then
		pcall(function()
			hook_data.hooks.old_namecall = hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
				if hook_data.enabled and not checkcaller() then
					local result = hooks.namecall(self, ...)
					if result ~= nil then
						return result
					end
				end
				return hook_data.hooks.old_namecall(self, ...)
			end))
		end)
	end

	if hooks.index and hookmetamethod then
		pcall(function()
			hook_data.hooks.old_index = hookmetamethod(game, '__index', newcclosure(function(self, key)
				if hook_data.enabled and not checkcaller() then
					local result = hooks.index(self, key)
					if result ~= nil then
						return result
					end
				end
				return hook_data.hooks.old_index(self, key)
			end))
		end)
	end

	if hooks.newindex and hookmetamethod then
		pcall(function()
			hook_data.hooks.old_newindex = hookmetamethod(game, '__newindex', newcclosure(function(self, key, value)
				if hook_data.enabled and not checkcaller() then
					local result = hooks.newindex(self, key, value)
					if result == false then
						return
					end
				end
				return hook_data.hooks.old_newindex(self, key, value)
			end))
		end)
	end

	if hooks.functions and hookfunction then
		for original_func, handler in hooks.functions do
			pcall(function()
				local old_func
				old_func = hookfunction(original_func, newcclosure(function(...)
					if hook_data.enabled and not checkcaller() then
						local result = handler(old_func, ...)
						if result ~= nil then
							return result
						end
					end
					return old_func(...)
				end))
				hook_data.function_hooks[original_func] = old_func
			end)
		end
	end

	hook_lib.active_hooks[name] = hook_data
	return hook_data
end

function hook_lib.destroy_hook(name)
	local hook_data = hook_lib.active_hooks[name]
	if hook_data then
		hook_data.enabled = false

		if hookfunction then
			for original_func, old_func in hook_data.function_hooks do
				pcall(function()
					hookfunction(original_func, old_func)
				end)
			end
		end

		hook_lib.active_hooks[name] = nil
	end
end

function hook_lib.toggle_hook(name, enabled)
	local hook_data = hook_lib.active_hooks[name]
	if hook_data then
		hook_data.enabled = enabled
	end
end

hook_lib.presets.antikick = function(player)
	local functions = {}

	pcall(function()
		local teleport = services.teleport_service.Teleport
		if teleport then
			functions[teleport] = function(old, ...)
				notify('antikick', 'blocked direct teleport call', 3)
				return nil
			end
		end
	end)

	pcall(function()
		local teleport_async = services.teleport_service.TeleportAsync
		if teleport_async then
			functions[teleport_async] = function(old, ...)
				notify('antikick', 'blocked direct teleport async call', 3)
				return nil
			end
		end
	end)

	pcall(function()
		local teleport_place = services.teleport_service.TeleportToPlaceInstance
		if teleport_place then
			functions[teleport_place] = function(old, ...)
				notify('antikick', 'blocked direct teleport to place call', 3)
				return nil
			end
		end
	end)

	return {
		namecall = function(self, ...)
			local method = getnamecallmethod()

			if self == player and (method == 'Kick' or method == 'Destroy' or method == 'Remove') then
				notify('antikick', `blocked {method} attempt`, 3)
				return nil
			end

			if self == services.teleport_service and (method == 'Teleport' or method == 'TeleportAsync' or method == 'TeleportToPlaceInstance') then
				notify('antikick', `blocked {method} attempt`, 3)
				return nil
			end
		end,

		functions = functions
	}
end

hook_lib.presets.freegamepass = function()
	local functions = {}

	pcall(function()
		local user_owns = services.marketplace_service.UserOwnsGamePassAsync
		if user_owns then
			functions[user_owns] = function(old, ...)
				return true
			end
		end
	end)

	pcall(function()
		local player_owns = services.marketplace_service.PlayerOwnsAsset
		if player_owns then
			functions[player_owns] = function(old, ...)
				return true
			end
		end
	end)

	return {
		namecall = function(self, ...)
			local method = getnamecallmethod()

			if self == services.marketplace_service then
				if method == 'UserOwnsGamePassAsync' or method == 'PlayerOwnsAsset' or method == 'PlayerOwnsBundle' then
					return true
				elseif method == 'GetProductInfo' then
					local success, result = pcall(function(...)
						return self[method](self, ...)
					end, ...)

					if success and result then
						result.IsOwned = true
						result.IsForSale = true
						return result
					end
				end
			end

			if typeof(self) == 'Instance' and self:IsA('Player') then
				if method == 'IsInGroup' then
					return true
				elseif method == 'GetRankInGroup' then
					return 255
				elseif method == 'GetRoleInGroup' then
					return 'Owner'
				end
			end
		end,

		index = function(self, key)
			if typeof(self) == 'Instance' and self:IsA('Player') then
				if key == 'MembershipType' then
					return Enum.MembershipType.Premium
				end
			end
		end,

		functions = functions
	}
end

hook_lib.presets.property_spoof = function(instance, properties)
	local spoofed_values = {}

	for prop, value in properties do
		spoofed_values[prop] = value
	end

	local functions = {}

	return {
		index = function(self, key)
			if self == instance and spoofed_values[key] ~= nil then
				return spoofed_values[key]
			end
		end,

		namecall = function(self, ...)
			local method = getnamecallmethod()

			if self == instance then
				if method == 'GetPropertyChangedSignal' then
					local args = {...}
					if spoofed_values[args[1]] ~= nil then
						local signal = Instance.new('BindableEvent')
						return signal.Event
					end
				end
			end
		end,

		newindex = function(self, key, value)
			if self == instance and spoofed_values[key] ~= nil then
				spoofed_values[key] = value
				return false
			end
		end,

		functions = functions
	}
end

stuff.chat_prefix = config.get('chat_prefix') or '!'

-- ============================================================
--  COMMANDS (all original opadmin commands, rebrand intact)
-- ============================================================

cmd_library.add({'speed', 'walkspeed', 'ws'}, 'sets your walkspeed to [speed]', {
	{'speed', 'number'},
	{'bypass_mode', 'boolean'}
}, function(vstorage, speed, bypass)
	speed = speed or stuff.default_ws
	notify('walkspeed', `walkspeed set to {speed}`, 1)

	if bypass then
		local humanoid = stuff.owner_char.Humanoid
		hook_lib.create_hook('walkspeed_bypass', hook_lib.presets.property_spoof(humanoid, {WalkSpeed = humanoid.WalkSpeed}))
	end

	stuff.rawrbxset(stuff.owner_char.Humanoid, 'WalkSpeed', speed)
end)

cmd_library.add({'jumppower', 'jp'}, 'sets your jumppower to [power]', {
	{'power', 'number'},
	{'bypass_mode', 'boolean'}
}, function(vstorage, power, bypass)
	power = power or stuff.default_jp
	notify('jumppower', `jumppower set to {power}`, 1)

	local humanoid = stuff.owner_char.Humanoid

	if bypass then
		hook_lib.create_hook('jumppower_bypass', hook_lib.presets.property_spoof(humanoid, {
			JumpPower = humanoid.UseJumpPower and humanoid.JumpPower or 50,
			JumpHeight = not humanoid.UseJumpPower and humanoid.JumpHeight or 7.2,
			UseJumpPower = true
		}))
	end

	stuff.rawrbxset(humanoid, 'UseJumpPower', true)
	stuff.rawrbxset(humanoid, 'JumpPower', power)
end)

cmd_library.add({'loopjumppower', 'loopjp'}, 'sets your jumppower to [power] in a loop', {
	{'power', 'number'},
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, power, bypass, et)
	if et and vstorage.enabled then
		cmd_library.execute('unloopjp')
		return
	end

	power = power or stuff.default_jp
	notify('loopjumppower', `looping jumppower set to {power}`, 1)

	vstorage.enabled = true
	vstorage.old_power = stuff.rawrbxget(stuff.owner_char.Humanoid, 'JumpPower')

	if bypass then
		local humanoid = stuff.owner_char.Humanoid
		hook_lib.create_hook('loopjp_bypass', hook_lib.presets.property_spoof(humanoid, {
			JumpPower = humanoid.UseJumpPower and humanoid.JumpPower or 50,
			JumpHeight = not humanoid.UseJumpPower and humanoid.JumpHeight or 7.2,
			UseJumpPower = true
		}))
	end

	maid.add('loopjp', services.run_service.Heartbeat, function()
		local hum = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
		pcall(stuff.rawrbxset, hum, 'UseJumpPower', true)
		pcall(stuff.rawrbxset, hum, 'JumpPower', power)
	end)
end)

cmd_library.add({'unloopjumppower', 'unloopjp'}, 'disables loopjumppower', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('loopjumppower')

	if vstorage.enabled then
		vstorage.enabled = false
		maid.remove('loopjp')
		hook_lib.destroy_hook('loopjp_bypass')

		pcall(stuff.rawrbxset, stuff.owner_char.Humanoid, 'JumpPower', vstorage.old_power or stuff.default_jp)
		notify('loopjumppower', 'loop jumppower disabled', 1)
	else
		notify('loopjumppower', 'loop jumppower is already disabled', 2)
	end
end)

cmd_library.add({'loopwalkspeed', 'loopws'}, 'sets your walkspeed to [speed] in a loop', {
	{'speed', 'number'},
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, bypass, et)
	if et and vstorage.enabled then
		cmd_library.execute('unloopws')
		return
	end

	speed = speed or stuff.default_ws
	notify('loopwalkspeed', `looping walkspeed set to {speed}`, 1)

	vstorage.enabled = true
	vstorage.old_speed = stuff.rawrbxget(stuff.owner_char.Humanoid, 'WalkSpeed')

	if bypass then
		local humanoid = stuff.owner_char.Humanoid
		hook_lib.create_hook('loopws_bypass', hook_lib.presets.property_spoof(humanoid, {WalkSpeed = vstorage.old_speed}))
	end

	maid.add('loopws', services.run_service.Heartbeat, function()
		pcall(stuff.rawrbxset, stuff.rawrbxget(stuff.owner_char, 'Humanoid'), 'WalkSpeed', speed)
	end)
end)

cmd_library.add({'unloopwalkspeed', 'unloopws'}, 'disables loopwalkspeed', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('loopwalkspeed')

	if vstorage.enabled then
		vstorage.enabled = false
		maid.remove('loopws')
		hook_lib.destroy_hook('loopws_bypass')

		pcall(stuff.rawrbxset, stuff.owner_char.Humanoid, 'WalkSpeed', vstorage.old_speed or stuff.default_ws)
		notify('loopwalkspeed', 'loop walkspeed disabled', 1)
	else
		notify('loopwalkspeed', 'loop walkspeed is already disabled', 2)
	end
end)

cmd_library.add({'fly', 'cfly', 'cframefly'}, 'enable flight', {
	{'speed', 'number'},
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, bypass, et)
	if speed == nil then speed = 1 end

	if vstorage.enabled and vstorage.speed == speed then
		if et then
			cmd_library.execute('unfly')
			return
		else
			return notify('fly', 'already flying', 2)
		end
	end

	vstorage.enabled = true
	vstorage.speed = speed or 1
	notify('fly', `enabled flight{vstorage.speed ~= 1 and ` with speed {vstorage.speed}` or ''}`, 1)

	local flight_part = Instance.new('Part', workspace)
	vstorage.part = flight_part

	stuff.rawrbxset(flight_part, 'CFrame', stuff.owner_char:GetPivot())
	stuff.rawrbxset(flight_part, 'Anchored', true)
	stuff.rawrbxset(flight_part, 'Transparency', 1)
	stuff.rawrbxset(flight_part, 'CanCollide', false)

	maid.add('flight', services.run_service.Heartbeat, function()
		pcall(function()
			local old_pos = stuff.rawrbxget(flight_part, 'Position')
			local cam_cframe = stuff.rawrbxget(workspace.CurrentCamera, 'CFrame')
			stuff.rawrbxset(flight_part, 'CFrame', CFrame.lookAt(old_pos, cam_cframe * CFrame.new(0, 0, -250).Position))

			local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
			stuff.owner_char:PivotTo(stuff.rawrbxget(flight_part, 'CFrame'))

			local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
			stuff.rawrbxset(hrp, 'AssemblyLinearVelocity', Vector3.zero)

			local offset = get_move_vector(vstorage.speed)
			local current_cf = flight_part.CFrame
			stuff.rawrbxset(flight_part, 'CFrame', current_cf * CFrame.new(offset))
		end)
	end)
end)

cmd_library.add({'unfly', 'uncframefly', 'uncfly'}, 'disable flight', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('fly')

	if vstorage.enabled then
		vstorage.enabled = false
		maid.remove('flight')
		hook_lib.destroy_hook('fly_bypass')

		if vstorage.part then
			pcall(stuff.destroy, vstorage.part)
			vstorage.part = nil
		end

		notify('fly', 'disabled flight', 1)
	else
		notify('fly', 'flight is already disabled', 2)
	end
end)

-- ============================================================
--  SZAdmin COMMANDS GUI  (draggable, fling.lua gray style)
-- ============================================================

cmd_library.add({'cmds', 'commands', 'cmdlist'}, 'shows the SZAdmin commands GUI', {}, function(vstorage)
	local ts  = services.tween_service
	local uis = services.user_input_service
	local cg  = services.core_gui

	local old = cg:FindFirstChild("SZAdminCmdsGui")
	if old then old:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name = "SZAdminCmdsGui"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder = 2147483646
	sg.Parent = cg

	-- collect commands
	local all_cmds = cmd_library.help()

	-- sizes
	local panelW    = 260
	local panelHFull = 420
	local panelHMin  = 28
	local minimized  = false

	-- ── MAIN PANEL ──────────────────────────────────────────────
	local panel = Instance.new("Frame")
	panel.Name = "SZAdminCmdsPanel"
	panel.Size = UDim2.new(0, panelW, 0, panelHFull)
	panel.Position = UDim2.new(0.5, -panelW/2, 0.5, -panelHFull/2)
	panel.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	panel.Active = true
	panel.Parent = sg
	do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,5) c.Parent = panel end

	-- subtle border
	do
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(65, 65, 65)
		stroke.Thickness = 1
		stroke.Transparency = 0
		stroke.Parent = panel
	end

	-- ── HEADER ──────────────────────────────────────────────────
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 28)
	header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	header.BorderSizePixel = 0
	header.Parent = panel
	do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,5) c.Parent = header end
	-- cover bottom corners
	do
		local fix = Instance.new("Frame")
		fix.Size = UDim2.new(1, 0, 0, 8)
		fix.Position = UDim2.new(0, 0, 1, -8)
		fix.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		fix.BorderSizePixel = 0
		fix.Parent = header
	end

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -70, 1, 0)
	titleLabel.Position = UDim2.new(0, 8, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = SZADMIN_TAG .. " — cmds"
	titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = header

	local function makeBtn(text, xOff)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 26, 0, 22)
		btn.Position = UDim2.new(1, xOff, 0, 3)
		btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		btn.BorderSizePixel = 0
		btn.Text = text
		btn.TextColor3 = Color3.fromRGB(190, 190, 190)
		btn.Font = Enum.Font.SourceSansBold
		btn.TextSize = 14
		btn.Parent = header
		do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,4) c.Parent = btn end
		return btn
	end

	local minBtn   = makeBtn("–", -56)
	local closeBtn = makeBtn("×", -28)

	-- ── DIVIDER ─────────────────────────────────────────────────
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, -16, 0, 1)
	divider.Position = UDim2.new(0, 8, 0, 28)
	divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	divider.BorderSizePixel = 0
	divider.Parent = panel

	-- ── SEARCH BAR ──────────────────────────────────────────────
	local searchBg = Instance.new("Frame")
	searchBg.Size = UDim2.new(1, -16, 0, 26)
	searchBg.Position = UDim2.new(0, 8, 0, 35)
	searchBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	searchBg.BorderSizePixel = 0
	searchBg.Parent = panel
	do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,4) c.Parent = searchBg end

	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, -10, 1, 0)
	searchBox.Position = UDim2.new(0, 5, 0, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.BorderSizePixel = 0
	searchBox.PlaceholderText = "search commands..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	searchBox.Text = ""
	searchBox.TextColor3 = Color3.fromRGB(200, 200, 200)
	searchBox.Font = Enum.Font.SourceSans
	searchBox.TextSize = 13
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchBg

	-- ── SECTION LABEL ───────────────────────────────────────────
	local sectionLbl = Instance.new("TextLabel")
	sectionLbl.Size = UDim2.new(1, -16, 0, 14)
	sectionLbl.Position = UDim2.new(0, 8, 0, 67)
	sectionLbl.BackgroundTransparency = 1
	sectionLbl.Text = "COMMANDS"
	sectionLbl.TextColor3 = Color3.fromRGB(120, 120, 120)
	sectionLbl.Font = Enum.Font.SourceSansBold
	sectionLbl.TextSize = 11
	sectionLbl.TextXAlignment = Enum.TextXAlignment.Left
	sectionLbl.Parent = panel

	-- ── COMMAND LIST ─────────────────────────────────────────────
	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(1, -16, 1, -90)
	listFrame.Position = UDim2.new(0, 8, 0, 85)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 3
	listFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
	listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	listFrame.Parent = panel

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.Name
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = listFrame
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
	end)

	-- entry builder
	local entries = {}

	local function buildEntry(cmd)
		local primaryName = cmd.names[1]
		local aliasText = #cmd.names > 1 and ("/" .. table.concat(cmd.names, "/", 2)) or ""
		local argsText = ""
		if cmd.args and #cmd.args > 0 then
			local argNames = {}
			for _, a in ipairs(cmd.args) do
				if type(a) == 'table' and a[3] ~= 'hidden' then
					table.insert(argNames, "[" .. a[1] .. "]")
				end
			end
			argsText = table.concat(argNames, " ")
		end

		local entry = Instance.new("Frame")
		entry.Size = UDim2.new(1, 0, 0, 48)
		entry.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		entry.BorderSizePixel = 0
		entry.Name = primaryName
		entry.Parent = listFrame
		do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,4) c.Parent = entry end

		-- command name
		local nameL = Instance.new("TextLabel")
		nameL.Size = UDim2.new(1, -8, 0, 18)
		nameL.Position = UDim2.new(0, 8, 0, 4)
		nameL.BackgroundTransparency = 1
		nameL.Text = primaryName .. (argsText ~= "" and "  " .. argsText or "")
		nameL.TextColor3 = Color3.fromRGB(210, 210, 210)
		nameL.Font = Enum.Font.SourceSansBold
		nameL.TextSize = 13
		nameL.TextXAlignment = Enum.TextXAlignment.Left
		nameL.TextTruncate = Enum.TextTruncate.AtEnd
		nameL.Parent = entry

		-- description
		local descL = Instance.new("TextLabel")
		descL.Size = UDim2.new(1, -8, 0, 14)
		descL.Position = UDim2.new(0, 8, 0, 22)
		descL.BackgroundTransparency = 1
		descL.Text = cmd.description or ""
		descL.TextColor3 = Color3.fromRGB(130, 130, 130)
		descL.Font = Enum.Font.SourceSans
		descL.TextSize = 12
		descL.TextXAlignment = Enum.TextXAlignment.Left
		descL.TextTruncate = Enum.TextTruncate.AtEnd
		descL.Parent = entry

		-- alias tag
		if aliasText ~= "" then
			local aliasL = Instance.new("TextLabel")
			aliasL.Size = UDim2.new(0, 120, 0, 12)
			aliasL.Position = UDim2.new(1, -124, 0, 6)
			aliasL.BackgroundTransparency = 1
			aliasL.Text = aliasText
			aliasL.TextColor3 = Color3.fromRGB(90, 90, 90)
			aliasL.Font = Enum.Font.SourceSans
			aliasL.TextSize = 11
			aliasL.TextXAlignment = Enum.TextXAlignment.Right
			aliasL.TextTruncate = Enum.TextTruncate.AtEnd
			aliasL.Parent = entry
		end

		-- plugin badge
		if cmd.plugin then
			local badge = Instance.new("Frame")
			badge.Size = UDim2.new(0, 0, 0, 14)
			badge.AutomaticSize = Enum.AutomaticSize.X
			badge.Position = UDim2.new(0, 8, 1, -18)
			badge.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
			badge.BorderSizePixel = 0
			badge.Parent = entry
			do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,3) c.Parent = badge end
			local bL = Instance.new("TextLabel")
			bL.Size = UDim2.new(0, 0, 1, 0)
			bL.AutomaticSize = Enum.AutomaticSize.X
			bL.BackgroundTransparency = 1
			bL.Text = " plugin: " .. cmd.plugin .. " "
			bL.TextColor3 = Color3.fromRGB(140, 200, 140)
			bL.Font = Enum.Font.SourceSans
			bL.TextSize = 10
			bL.Parent = badge
		end

		-- hover
		local selBtn = Instance.new("TextButton")
		selBtn.Size = UDim2.new(1, 0, 1, 0)
		selBtn.BackgroundTransparency = 1
		selBtn.Text = ""
		selBtn.Parent = entry

		selBtn.MouseEnter:Connect(function()
			ts:Create(entry, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(62, 62, 62)}):Play()
		end)
		selBtn.MouseLeave:Connect(function()
			ts:Create(entry, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
		end)

		entries[primaryName] = {frame = entry, cmd = cmd}
		return entry
	end

	for _, cmd in ipairs(all_cmds) do
		buildEntry(cmd)
	end

	-- update count label
	local function updateSection()
		local visible = 0
		for _, e in pairs(entries) do
			if e.frame.Visible then visible = visible + 1 end
		end
		sectionLbl.Text = "COMMANDS (" .. visible .. ")"
	end
	updateSection()

	-- search filter
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = searchBox.Text:lower()
		for name, e in pairs(entries) do
			local cmd = e.cmd
			local match = name:find(q, 1, true)
				or (cmd.description and cmd.description:lower():find(q, 1, true))
			for _, alias in ipairs(cmd.names) do
				if alias:lower():find(q, 1, true) then match = true end
			end
			e.frame.Visible = q == "" or match
		end
		updateSection()
	end)

	-- live add new commands
	cmd_library._on_command_added = function(cmd_data)
		buildEntry(cmd_data)
		updateSection()
	end

	-- ── DRAGGABLE ────────────────────────────────────────────────
	local dragging, dragInput, dragStart, startPos

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = panel.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	uis.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local d = input.Position - dragStart
			panel.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)

	-- ── MINIMIZE / CLOSE ─────────────────────────────────────────
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		minBtn.Text = minimized and "+" or "–"
		ts:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = minimized
				and UDim2.new(0, panelW, 0, panelHMin)
				or  UDim2.new(0, panelW, 0, panelHFull)
		}):Play()
	end)

	closeBtn.MouseButton1Click:Connect(function()
		panel:Destroy()
		sg:Destroy()
		cmd_library._on_command_added = nil
	end)

	notify('szadmin', 'commands list opened', 4)
end)

-- ============================================================
--  SZADMIN INIT MSG
-- ============================================================

print(string.rep("=", 50))
print(string.format("  %s  |  loaded", SZADMIN_TAG))
print("  use !" .. "cmds  to view all commands")
print("  chat prefix: " .. (stuff.chat_prefix or "!"))
print(string.rep("=", 50))

warn("[SZAdmin] loaded successfully — " .. SZADMIN_VERSION)
