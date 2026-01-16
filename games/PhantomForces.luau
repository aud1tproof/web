-- placeholder for now (until i actually start working on the actual script. enjoy the esp for now)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local moduleCache
for _, v in getgc(true) do
    if type(v) == "table" and rawget(v, "ScreenCull") and rawget(v, "NetworkClient") then
        moduleCache = v
        break
    end
end

local modules = {}
for name, data in moduleCache do
    if data then
        modules[name] = type(data) == "table" and data.module or data
    end
end

local ReplicationInterface = modules.ReplicationInterface

local TargetMeshIds = {
    ["rbxassetid://6179256256"] = "Head",
    ["rbxassetid://4049240078"] = "Torso"
}

local Settings = {
    enabled       = true,
    boxColor      = Color3.fromRGB(255, 255, 255),
    outlineColor  = Color3.fromRGB(0, 0, 0),
    nameColor     = Color3.fromRGB(255, 255, 255),
    healthColor   = Color3.fromRGB(0, 255, 0),
    lowHealthColor= Color3.fromRGB(255, 0, 0),
    distanceColor = Color3.fromRGB(200, 200, 200),
    weaponColor   = Color3.fromRGB(255, 200, 100),
}

local espCache = {}

local function NewDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in props do d[k] = v end
    return d
end

local function CreateESP(player)
    local esp = {
        boxOutline = NewDrawing("Square", {
            Thickness = 3, Filled = false,
            Color = Settings.outlineColor, Visible = false, Transparency = 1
        }),
        box = NewDrawing("Square", {
            Thickness = 1, Filled = false,
            Color = Settings.boxColor, Visible = false, Transparency = 1
        }),
        healthBarBg = NewDrawing("Square", {
            Thickness = 1, Filled = true,
            Color = Color3.fromRGB(0,0,0), Visible = false, Transparency = 0.5
        }),
        healthBarOutline = NewDrawing("Square", {
            Thickness = 1, Filled = false,
            Color = Settings.outlineColor, Visible = false, Transparency = 1
        }),
        healthBar = NewDrawing("Square", {
            Thickness = 1, Filled = true,
            Color = Settings.healthColor, Visible = false, Transparency = 1
        }),
        name = NewDrawing("Text", {
            Text = player.Name, Size = 13, Center = true, Outline = true,
            OutlineColor = Settings.outlineColor, Color = Settings.nameColor,
            Visible = false, Font = 2, Transparency = 1
        }),
        distance = NewDrawing("Text", {
            Text = "", Size = 12, Center = true, Outline = true,
            OutlineColor = Settings.outlineColor, Color = Settings.distanceColor,
            Visible = false, Font = 2, Transparency = 1
        }),
        weapon = NewDrawing("Text", {
            Text = "", Size = 12, Center = true, Outline = true,
            OutlineColor = Settings.outlineColor, Color = Settings.weaponColor,
            Visible = false, Font = 2, Transparency = 1
        }),
    }
    espCache[player] = esp
    return esp
end

local function DestroyESP(player)
    local esp = espCache[player]
    if not esp then return end

    for _, obj in esp do
        if typeof(obj) == "Instance" and obj.Remove then
            obj:Remove()
        end
    end
    espCache[player] = nil
end

local function FindBodyPart(character, partName)
    for _, obj in character:GetDescendants() do
        if obj:IsA("BasePart") then
            local mesh = obj:FindFirstChildOfClass("SpecialMesh")
            if mesh and TargetMeshIds[mesh.MeshId] == partName then
                return obj
            end
        end
    end
    return nil
end

local function UpdateESP()
    if not Settings.enabled then
        for _, esp in espCache do
            for _, d in esp do
                if d.Visible then d.Visible = false end
            end
        end
        return
    end

    ReplicationInterface.operateOnAllEntries(function(player, entry)
        if player == LocalPlayer then return end

        local esp = espCache[player] or CreateESP(player)
        local thirdPerson = entry:getThirdPersonObject()

        if not thirdPerson or not entry:isAlive() or not entry._isEnemy then
            for _, d in esp do if d.Visible then d.Visible = false end end
            return
        end

        local model = thirdPerson:getCharacterModel()
        local root  = thirdPerson:getRootPart()

        if not model or not root then
            for _, d in esp do if d.Visible then d.Visible = false end end
            return
        end

        local head  = FindBodyPart(model, "Head")
        local torso = FindBodyPart(model, "Torso")

        if not head or not torso then
            for _, d in esp do if d.Visible then d.Visible = false end end
            return
        end

        local headPos,  headVis  = Camera:WorldToViewportPoint(head.Position  + Vector3.new(0, 0.5, 0))
        local torsoPos, torsoVis = Camera:WorldToViewportPoint(torso.Position - Vector3.new(0, 3,   0))

        if not headVis and not torsoVis then
            for _, d in esp do if d.Visible then d.Visible = false end end
            return
        end

        local height   = math.abs(headPos.Y - torsoPos.Y)
        local width    = height / 2
        local boxPos   = Vector2.new(headPos.X - width/2, headPos.Y)
        local boxSize  = Vector2.new(width, height)

        -- Box
        esp.boxOutline.Size     = boxSize
        esp.boxOutline.Position = boxPos
        esp.boxOutline.Visible  = true

        esp.box.Size     = boxSize
        esp.box.Position = boxPos
        esp.box.Visible  = true

        -- Name
        esp.name.Text     = player.Name
        esp.name.Position = Vector2.new(headPos.X, boxPos.Y - 16)
        esp.name.Visible  = true

        -- Health bar (left side)
        local health    = entry:getHealth()
        local maxHealth = 100
        local pct       = math.clamp(health / maxHealth, 0, 1)

        local barW   = 2
        local barGap = 2
        local barX   = boxPos.X - barW - barGap

        esp.healthBarBg.Size     = Vector2.new(barW, height)
        esp.healthBarBg.Position = Vector2.new(barX, boxPos.Y)
        esp.healthBarBg.Visible  = true

        esp.healthBarOutline.Size     = Vector2.new(barW, height)
        esp.healthBarOutline.Position = Vector2.new(barX, boxPos.Y)
        esp.healthBarOutline.Visible  = true

        local fillH = height * pct
        esp.healthBar.Size     = Vector2.new(barW, fillH)
        esp.healthBar.Position = Vector2.new(barX, boxPos.Y + height - fillH)
        esp.healthBar.Color    = Settings.healthColor:Lerp(Settings.lowHealthColor, 1 - pct)
        esp.healthBar.Visible  = true

        -- Distance
        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        esp.distance.Text     = math.floor(dist) .. "m"
        esp.distance.Position = Vector2.new(headPos.X, boxPos.Y + height + 2)
        esp.distance.Visible  = true

        -- Weapon
        local wpnObj = entry:getWeaponObject()
        local wpnName = wpnObj and wpnObj.weaponName or "Unknown"
        esp.weapon.Text     = wpnName
        esp.weapon.Position = Vector2.new(headPos.X, boxPos.Y + height + 16)
        esp.weapon.Visible  = true
    end)
end

Players.PlayerRemoving:Connect(DestroyESP)
RunService.RenderStepped:Connect(UpdateESP)
