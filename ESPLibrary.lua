--[[
  Made completely by deproxies <3
  had to re optimize i didnt realize i forgot to disconnect the loop LOL
  enjoy
]]
local functions = {
    enabled = true,
    showskeleton = false,
    showdistance = true,
    boxcolor = Color3.fromRGB(255, 255, 255),
    useteamcolor = false,
    showhealth = true,
    showname = true,
    usedisplayname = false,
    
    textTopColor = Color3.fromRGB(255, 255, 255),
    textBottomColor = Color3.fromRGB(255, 255, 255),
    useTeamColorForText = false,
    
    namePosition = "Top",
    healthPosition = "Bottom",
    distancePosition = "Bottom",
    
    npcenabled = true,
    npcshowskeleton = true,
    npcshowdistance = true,
    npcpath = workspace,
    npccolor = Color3.fromRGB(255, 255, 0),
    npcshowhealth = true,
    npcshowname = true,
    
    itemsenabled = true,
    itemshowdistance = true,
    itemcolor = Color3.new(0, 1, 1),
    showitemname = true,
    useitemfilter = true,
    targetitems = {},
}

local active_conns = {}
local drawing_cache = {}

local skeleton_parts = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

function functions:unload()
    for _, conn in pairs(active_conns) do
        if conn.Disconnect then pcall(function() conn:Disconnect() end) end
    end
    active_conns = {}
    destroy_drawings(drawing_cache)
end

local function destroy_drawings(t)
    for k, v in pairs(t) do
        if type(v) == "table" then destroy_drawings(v)
        elseif v.Remove then pcall(function() v:Remove() end) end
        t[k] = nil
    end
end

local function draw_esp(obj, hum, isnpc, config, custom_player)
    local id = obj:GetDebugId()
    if drawing_cache[id] then destroy_drawings(drawing_cache[id]) end

    local drawings = {
        box = Drawing.new("Square"),
        text_top = Drawing.new("Text"),
        text_bottom = Drawing.new("Text"),
        head_circle = Drawing.new("Circle"),
        skeleton = {}
    }
    
    drawings.text_top.Size, drawings.text_top.Center, drawings.text_top.Outline = 16, true, true
    drawings.text_bottom.Size, drawings.text_bottom.Center, drawings.text_bottom.Outline = 16, true, true
    for i = 1, #skeleton_parts do drawings.skeleton[i] = Drawing.new("Line") end

    drawing_cache[id] = drawings
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not obj or not obj.Parent or not hum or hum.Health <= 0 then
            destroy_drawings(drawings); drawing_cache[id] = nil
            if conn then conn:Disconnect() end return
        end

        local master_on = isnpc and config.npcenabled or config.enabled
        if not master_on then
            drawings.box.Visible = false; drawings.text_top.Visible = false; drawings.text_bottom.Visible = false
            return
        end

        local hrp = obj:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local top_pos, on_screen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
        if on_screen then
            local bottom_pos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, -3.5, 0))
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            local h, w = math.abs(top_pos.Y - bottom_pos.Y), math.abs(top_pos.Y - bottom_pos.Y) / 1.5
            
            local current_color = config.boxcolor
            if not isnpc then
                local p = custom_player or Players:GetPlayerFromCharacter(obj)
                current_color = (config.useteamcolor and p and p.TeamColor) and p.TeamColor.Color or config.boxcolor
            else
                current_color = config.npccolor
            end

            drawings.box.Size, drawings.box.Position, drawings.box.Color, drawings.box.Visible = Vector2.new(w, h), Vector2.new(top_pos.X - w / 2, top_pos.Y), current_color, true

            local t_label, b_label = "", ""
            local show_n = isnpc and config.npcshowname or config.showname
            if show_n then
                local name = isnpc and obj.Name or (config.usedisplayname and custom_player.DisplayName or custom_player.Name)
                if (isnpc and config.npcnamePosition or config.namePosition) == "Top" then t_label = name else b_label = name end
            end

            local topColor = config.useTeamColorForText and current_color or config.textTopColor
            local botColor = config.useTeamColorForText and current_color or config.textBottomColor

            drawings.text_top.Text, drawings.text_top.Position, drawings.text_top.Color, drawings.text_top.Visible = t_label, Vector2.new(top_pos.X, top_pos.Y - 18), topColor, (t_label ~= "")
            drawings.text_bottom.Text, drawings.text_bottom.Position, drawings.text_bottom.Color, drawings.text_bottom.Visible = b_label, Vector2.new(top_pos.X, bottom_pos.Y + 2), botColor, (b_label ~= "")
        else
            drawings.box.Visible = false; drawings.text_top.Visible = false; drawings.text_bottom.Visible = false
        end
    end)
    table.insert(active_conns, conn)
end

function functions:item_esp(obj, custom_name)
    local rs = game:GetService("RunService")
    local cam = workspace.CurrentCamera
    local name = Drawing.new("Text")
    name.Size = 14
    name.Center = true
    name.Outline = true

    local conn
    conn = rs.RenderStepped:Connect(function()
        if not obj or not obj.Parent or not self.itemsenabled then
            name:Remove()
            if conn then conn:Disconnect() end
            return
        end

        local pos, on = cam:WorldToViewportPoint(obj.Position)
        if on then
            local label = self.showitemname and (custom_name or obj.Name) or ""
            if self.itemshowdistance then
                local dist = (cam.CFrame.Position - obj.Position).Magnitude
                label = label .. " [" .. math.floor(dist) .. "s]"
            end
            name.Text = label
            name.Position = Vector2.new(pos.X, pos.Y)
            name.Color = self.itemcolor
            name.Visible = true
        else
            name.Visible = false
        end
    end)
    table.insert(active_conns, conn)
end

function functions:esp(p, char)
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then draw_esp(char, hum, false, self, p) end
        return
    end

    p.CharacterAdded:Connect(function(c)
        local hum = c:WaitForChild("Humanoid", 10)
        if hum then draw_esp(c, hum, false, self, p) end
    end)
    if p.Character then
        local hum = p.Character:FindFirstChild("Humanoid")
        if hum then draw_esp(p.Character, hum, false, self, p) end
    end
end

function functions:npc_esp(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then draw_esp(model, hum, true, self) end
end

function functions:track_items(folder, filter)
    if filter then self.targetitems = filter end
    
    local function process(v)
        if self.useitemfilter and not table.find(self.targetitems, v.Name) then return end
        local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
        if part then self:item_esp(part, v.Name) end
    end

    for _, v in pairs(folder:GetChildren()) do process(v) end
    folder.ChildAdded:Connect(process)
end

return functions
--[[
================================================================================
                                USAGE EXAMPLES
================================================================================

1. INITIALIZING THE LIBRARY:
   local functionlib = loadstring(game:HttpGet("https://raw.githubusercontent.com/deproxies/Main/refs/heads/main/ESPLibrary.lua"))()

2. SETTING UP PLAYER ESP:
   for _, v in pairs(game:GetService("Players"):GetPlayers()) do
       if v ~= game:GetService("Players").LocalPlayer then functionlib:esp(v) end
   end
   game:GetService("Players").PlayerAdded:Connect(function(v) functionlib:esp(v) end)

3. SETTING UP CUSTOM CHARACTER ESP:
   -- If a game uses a separate model for the player instead of their real Character:
   -- functionlib:esp(PlayerInstance, CustomModelInstance)
   local target_player = game:GetService("Players"):FindFirstChild("deproxies")
   local custom_model = workspace.CustomCharacters:FindFirstChild("deproxies_model")
   functionlib:esp(target_player, custom_model)

4. SETTING UP NPC ESP:
   functionlib.npcpath = workspace.Enemies 
   for _, v in pairs(functionlib.npcpath:GetChildren()) do functionlib:npc_esp(v) end
   functionlib.npcpath.ChildAdded:Connect(function(v) functionlib:npc_esp(v) end)

5. SETTING UP ITEM ESP:
   functionlib:track_items(workspace.Drops, {"Keycard", "Medkit", "Secret Weapon"})

6. GUI TOGGLE EXAMPLES:
   functionlib.enabled = true/false         -- toggle players
   functionlib.showskeleton = true/false    -- toggle player skeletons
   functionlib.namePosition = "Top"         -- put name on "Top" or "Bottom"
   functionlib.npcenabled = true/false      -- toggle npcs
   functionlib.npcshowskeleton = true/false -- toggle npc skeletons
   functionlib.itemsenabled = true/false    -- toggle items
   functionlib.useitemfilter = true/false   -- toggle filtering items by name
   functionlib.showhealth = true/false      -- show player health
   functionlib.showname = true/false        -- show player names
   functionlib.useteamcolor = true/false    -- use team color
   functionlib.boxcolor = Color3.fromRGB(255, 255, 255)
================================================================================
]]
