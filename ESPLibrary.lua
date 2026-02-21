--[[
  Made completely by deproxies <3
]]
local functions = {
    -- player settings
    enabled = true,
    showskeleton = false,
    showdistance = true,
    boxcolor = Color3.fromRGB(255, 255, 255),
    useteamcolor = false,
    showhealth = true,
    showname = true,
    usedisplayname = false,
    
    -- npc settings
    npcenabled = true,
    npcshowskeleton = true,
    npcshowdistance = true,
    npcpath = workspace,
    npccolor = Color3.fromRGB(255, 255, 0),
    npcshowhealth = true,
    npcshowname = true,

    -- item settings
    itemsenabled = true,
    itemshowdistance = true,
    itemcolor = Color3.new(0, 1, 1),
    showitemname = true,
    useitemfilter = true,
    targetitems = {},
}

local skeleton_parts = {
    -- R15
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
    -- R6
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

local function draw_esp(obj, hum, isnpc, config)
    local rs = game:GetService("RunService")
    local cam = workspace.CurrentCamera
    
    local box = Drawing.new("Square")
    local name = Drawing.new("Text")
    
    box.Visible = false
    box.Thickness = 1
    name.Visible = false
    name.Size = 16
    name.Center = true
    name.Outline = true

    local skeleton_lines = {}
    for i = 1, #skeleton_parts do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1
        skeleton_lines[i] = line
    end

    rs.RenderStepped:Connect(function()
        local master_on = isnpc and config.npcenabled or config.enabled
        local hrp = obj:FindFirstChild("HumanoidRootPart")

        if master_on and obj and obj.Parent and hum and hrp and hum.Health > 0 then
            local top, on1 = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
            local bottom, on2 = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, -3.5, 0))
            
            local dist = (cam.CFrame.Position - hrp.Position).Magnitude
            
            local current_color = config.boxcolor
            if isnpc then
                current_color = config.npccolor
            else
                local p = game.Players:GetPlayerFromCharacter(obj)
                current_color = (config.useteamcolor and p and p.TeamColor) and p.TeamColor.Color or config.boxcolor
            end

            if on1 or on2 then
                local h = math.abs(top.Y - bottom.Y)
                local w = h / 1.5
                box.Size = Vector2.new(w, h)
                box.Position = Vector2.new(top.X - w / 2, top.Y)
                box.Color = current_color
                box.Visible = true

                local show_n = isnpc and config.npcshowname or config.showname
                local show_h = isnpc and config.npcshowhealth or config.showhealth
                local show_d = isnpc and config.npcshowdistance or config.showdistance
                
                local label = ""
                if show_n then
                    if isnpc then label = obj.Name else
                        local p = game.Players:GetPlayerFromCharacter(obj)
                        label = config.usedisplayname and p.DisplayName or p.Name
                    end
                end
                
                if show_h then
                    label = label .. " [" .. math.floor(hum.Health) .. " health]"
                end
                
                if show_d then
                    label = label .. " [" .. math.floor(dist) .. " studs]"
                end

                if label ~= "" then
                    name.Text = label
                    name.Position = Vector2.new(top.X, bottom.Y + 5)
                    name.Color = Color3.new(1, 1, 1)
                    name.Visible = true
                else
                    name.Visible = false
                end
            else
                box.Visible = false
                name.Visible = false
            end
            
            local show_skeleton = isnpc and config.npcshowskeleton or config.showskeleton
            if show_skeleton then
                for i, conn in ipairs(skeleton_parts) do
                    local part1 = obj:FindFirstChild(conn[1])
                    local part2 = obj:FindFirstChild(conn[2])
                    
                    if part1 and part2 then
                        local pos1, on1_s = cam:WorldToViewportPoint(part1.Position)
                        local pos2, on2_s = cam:WorldToViewportPoint(part2.Position)
                    
                        if pos1.Z > 0 and pos2.Z > 0 then
                            skeleton_lines[i].From = Vector2.new(pos1.X, pos1.Y)
                            skeleton_lines[i].To = Vector2.new(pos2.X, pos2.Y)
                            skeleton_lines[i].Color = current_color
                            skeleton_lines[i].Visible = true
                        else
                            skeleton_lines[i].Visible = false
                        end
                    else
                        skeleton_lines[i].Visible = false
                    end
                end
            else
                for _, line in ipairs(skeleton_lines) do line.Visible = false end
            end
        else
            box.Visible = false
            name.Visible = false
            for _, line in ipairs(skeleton_lines) do line.Visible = false end
            
            if not obj or not obj.Parent then
                box:Remove()
                name:Remove()
                for _, line in ipairs(skeleton_lines) do line:Remove() end
            end
        end
    end)
end

function functions:item_esp(obj, custom_name)
    local rs = game:GetService("RunService")
    local cam = workspace.CurrentCamera
    local name = Drawing.new("Text")
    name.Visible = false
    name.Size = 14
    name.Center = true
    name.Outline = true

    rs.RenderStepped:Connect(function()
        if self.itemsenabled and obj and obj.Parent then
            local pos, on = cam:WorldToViewportPoint(obj.Position)
            local dist = (cam.CFrame.Position - obj.Position).Magnitude
            
            if on then
                local label = self.showitemname and (custom_name or obj.Name) or ""
                if self.itemshowdistance then
                    label = label .. " [" .. math.floor(dist) .. " studs]"
                end
                
                name.Color = self.itemcolor
                name.Text = label
                name.Position = Vector2.new(pos.X, pos.Y)
                name.Visible = true
            else
                name.Visible = false
            end
        else
            name.Visible = false
            if not obj or not obj.Parent then name:Remove() end
        end
    end)
end

function functions:esp(p)
    p.CharacterAdded:Connect(function(c)
        draw_esp(c, c:WaitForChild("Humanoid"), false, self)
    end)
    if p.Character then
        draw_esp(p.Character, p.Character:FindFirstChild("Humanoid"), false, self)
    end
end

function functions:npc_esp(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        draw_esp(model, hum, true, self)
    end
end

function functions:track_items(folder, specific_names)
    if type(specific_names) == "table" then
        self.useitemfilter = true
        self.targetitems = specific_names
    end

    local function check_item(obj)
        task.spawn(function()
            task.wait(0.1)
            local obj_name = obj.Name
            
            if self.useitemfilter and not table.find(self.targetitems, obj_name) then 
                return 
            end
            
            local target_part = obj
            if obj:IsA("Model") then
                target_part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            end
            
            if target_part and target_part:IsA("BasePart") then
                self:item_esp(target_part, obj_name)
            end
        end)
    end

    for _, v in pairs(folder:GetChildren()) do check_item(v) end
    folder.ChildAdded:Connect(function(v) check_item(v) end)
end

return functions

--[[
================================================================================
                                USAGE EXAMPLES
================================================================================

1. INITIALIZING THE LIBRARY:
   local functionlib = loadstring(game:HttpGet("https://raw.githubusercontent.com/deproxies/Main/refs/heads/main/ESPLibrary.lua"))()

2. SETTING UP PLAYER ESP:
   for _, v in pairs(game.Players:GetPlayers()) do
       if v ~= game.Players.LocalPlayer then functionlib:esp(v) end
   end
   game.Players.PlayerAdded:Connect(function(v) functionlib:esp(v) end)

3. SETTING UP NPC ESP:
   functionlib.npcpath = workspace.Enemies 
   for _, v in pairs(functionlib.npcpath:GetChildren()) do functionlib:npc_esp(v) end
   functionlib.npcpath.ChildAdded:Connect(function(v) functionlib:npc_esp(v) end)

4. SETTING UP ITEM ESP:
   functionlib:track_items(workspace.Drops, {"Keycard", "Medkit", "Secret Weapon"})

5. GUI TOGGLE EXAMPLES:
   functionlib.enabled = true/false         -- toggle players
   functionlib.showskeleton = true/false    -- toggle player skeletons
   functionlib.npcenabled = true/false      -- toggle npcs
   functionlib.npcshowskeleton = true/false -- toggle npc skeletons
   functionlib.itemsenabled = true/false    -- toggle items
   functionlib.useitemfilter = true/false   -- toggle filtering items by name
   functionlib.showhealth = true/false      -- show player health
   functionlib.showname = true/false        -- show player names
   functionlib.useteamcolor = true/false    -- use team color
   functionlib.boxcolor = Color3.fromRGB(255, 255, 255)
================================================================================


ps: if anyone knows how to do skeleton better please inform me this shit was tedious
]]
