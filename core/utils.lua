local Workspace   = game:GetService("Workspace")
local Camera      = Workspace.CurrentCamera

-- Keep camera ref fresh if it ever changes
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)


-- Shortcuts ---------------------------------------------------------------------
local Cos, Rad, Sin, Tan, Max, Floor =
    math.cos, math.rad, math.sin, math.tan, math.max, math.floor

local WTVP               = Camera.WorldToViewportPoint
local PointToObjectSpace = CFrame.identity.PointToObjectSpace

local V2New    = Vector2.new
local ColorNew = Color3.new

-- Color constants ---------------------------------------------------------------
local Utils = {
    RedColor    = ColorNew(1, 0, 0),
    GreenColor  = ColorNew(0, 1, 0),
    YellowColor = ColorNew(1, 1, 0),
    WhiteColor  = ColorNew(1, 1, 1),

    -- Expose Camera so other modules can read it without re-fetching (saves like 2 fps but shitsploits like xeno exist)
    GetCamera = function() return Camera end,
}

-- Screen helpers ----------------------------------------------------------------

function Utils.WorldToScreen(WorldPos)
    local S, On = WTVP(Camera, WorldPos)
    return V2New(S.X, S.Y), On
end

function Utils.GetDistance(Pos)
    return (Pos - Camera.CFrame.Position).Magnitude
end

function Utils.AntiAliasingXY(X, Y)
    return V2New(Floor(X), Floor(Y))
end

-- Range / scale helpers ---------------------------------------------------------

function Utils.IsWithinReach(Enabled, Limit, Distance)
    return (not Enabled) or Distance < Limit
end

function Utils.GetScaleFactor(Enabled, Size, Distance)
    if not Enabled then return Size end
    return Max(1, Size / (Distance * Tan(Rad(Camera.FieldOfView / 2)) * 10) * 1000)
end

function Utils.CalculateBoxSize(Model, Distance)
    local Size     = Model:GetExtentsSize()
    local FrustumH = Tan(Rad(Camera.FieldOfView / 2)) * 2 * Distance
    return Utils.AntiAliasingXY(
        Camera.ViewportSize.Y / FrustumH * Size.X,
        Camera.ViewportSize.Y / FrustumH * Size.Y
    )
end

-- Vector helpers ---------------------------------------------------------------

function Utils.GetRelative(Pos)
    local R = PointToObjectSpace(Camera.CFrame, Pos)
    return V2New(-R.X, -R.Z)
end

function Utils.RotateVec(Vec, Rad_)
    local C, S = Cos(Rad_), Sin(Rad_)
    return V2New(Vec.X * C - Vec.Y * S, Vec.X * S + Vec.Y * C)
end

function Utils.RelativeToCenter(Size)
    return Camera.ViewportSize / 2 - Size
end

-- Flag accessor-----------------------------------------------------------------

function Utils.GetFlag(Flags, Flag, Option)
    return Flags[Flag .. Option]
end

-- Health color shit ------------------------------------------------------------

local CS = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   ColorNew(1, 0, 0)),
    ColorSequenceKeypoint.new(0.5, ColorNew(1, 1, 0)),
    ColorSequenceKeypoint.new(1,   ColorNew(0, 1, 0)),
})
Utils.HealthGradient = CS

function Utils.EvalHealth(Pct)
    if Pct == 0 then return CS.Keypoints[1].Value end
    if Pct == 1 then return CS.Keypoints[#CS.Keypoints].Value end
    for i = 1, #CS.Keypoints - 1 do
        local K, N = CS.Keypoints[i], CS.Keypoints[i + 1]
        if Pct >= K.Time and Pct < N.Time then
            return K.Value:Lerp(N.Value, (Pct - K.Time) / (N.Time - K.Time))
        end
    end
end

return Utils
