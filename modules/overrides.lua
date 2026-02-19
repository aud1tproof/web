return function(Utils)
    local WhiteColor = Utils.WhiteColor

    local PlayerService = game:GetService("Players")
    local Workspace     = game:GetService("Workspace")

    local FindFirstChild        = Workspace.FindFirstChild
    local FindFirstChildOfClass = Workspace.FindFirstChildOfClass

    repeat task.wait() until PlayerService.LocalPlayer
    local LocalPlayer = PlayerService.LocalPlayer

    -- Default implementations -----------------------------------------------

    local function GetCharacter(Target, Mode)
        if Mode == "Player" then
            local Char = Target.Character
            if not Char then return end
            return Char, FindFirstChild(Char, "HumanoidRootPart")
        end
        return Target, FindFirstChild(Target, "HumanoidRootPart")
    end

    local function GetHealth(Target, Character, Mode)
        local Hum = FindFirstChildOfClass(Character, "Humanoid")
        if not Hum then return 100, 100, true end
        return Hum.Health, Hum.MaxHealth, Hum.Health > 0
    end

    local function GetTeam(Target, Character, Mode)
        if Mode == "Player" then
            if Target.Neutral then return true, WhiteColor end
            return LocalPlayer.Team ~= Target.Team, Target.TeamColor.Color
        end
        return true, WhiteColor
    end

    local function GetWeapon(Target, Character, Mode)
        return "N/A"
    end

    -- Bad Business ---------------------------------------------------------
    if game.GameId == 1168263273 or game.GameId == 3360073263 then
        local Teams = game:GetService("Teams")
        local RS    = game:GetService("ReplicatedStorage")
        local Shell = getupvalue(require(RS.TS), 1)
        local Characters = getupvalue(Shell.Characters.GetCharacter, 1)

        local function GetPlayerTeam(p)
            for _, t in pairs(Teams:GetChildren()) do
                if FindFirstChild(t.Players, p.Name) then return t.Name end
            end
        end

        GetCharacter = function(T, M)
            local C = Characters[T]
            if not C or C.Parent == nil then return end
            return C, C.PrimaryPart
        end
        GetHealth = function(T, C, M)
            local H = C.Health
            return H.Value, H.MaxHealth.Value, H.Value > 0
        end
        GetTeam = function(T, C, M)
            local a, b = GetPlayerTeam(T), GetPlayerTeam(LocalPlayer)
            return b ~= a or a == "FFA", Shell.Teams.Colors[a]
        end
        GetWeapon = function(T, C, M)
            return tostring(C.Backpack.Equipped.Value or "Hands")
        end
    end

    -- Export ----------------------------------------------------------------
    return {
        GetCharacter = GetCharacter,
        GetHealth    = GetHealth,
        GetTeam      = GetTeam,
        GetWeapon    = GetWeapon,
    }
end
