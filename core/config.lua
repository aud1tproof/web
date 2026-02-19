return function()
    local C = Color3.new

    return {
        -- Global ----------------------------------------------------------
        ["Players/Enabled"]       = true,
        ["Players/TeamCheck"]     = true,
        ["Players/TeamColor"]     = false,
        ["Players/DistanceCheck"] = false,
        ["Players/Distance"]      = 5000,
        ["Players/Enemy"] = { 0,0,0,0,false, C(1,   0.2, 0.2) },
        ["Players/Ally"]  = { 0,0,0,0,false, C(0.2, 1,   0.2) },

        -- Corner Box ------------------------------------------------------
        ["Players/Box/Enabled"]      = true,
        ["Players/Box/HealthBar"]    = true,
        ["Players/Box/Filled"]       = false,
        ["Players/Box/Outline"]      = true,
        ["Players/Box/Thickness"]    = 1,
        ["Players/Box/Transparency"] = 0,
        ["Players/Box/CornerSize"]   = 50,   -- % of half-width / half-height

        -- Text Labels -----------------------------------------------------
        ["Players/Name/Enabled"]      = true,
        ["Players/Health/Enabled"]    = true,
        ["Players/Distance/Enabled"]  = true,
        ["Players/Weapon/Enabled"]    = false,
        ["Players/Name/Outline"]      = true,
        ["Players/Name/Autoscale"]    = true,
        ["Players/Name/Size"]         = 8,
        ["Players/Name/Transparency"] = 0.25,

        -- Head Dot --------------------------------------------------------
        ["Players/HeadDot/Enabled"]      = false,
        ["Players/HeadDot/Filled"]       = true,
        ["Players/HeadDot/Outline"]      = true,
        ["Players/HeadDot/Autoscale"]    = true,
        ["Players/HeadDot/Radius"]       = 4,
        ["Players/HeadDot/NumSides"]     = 4,
        ["Players/HeadDot/Thickness"]    = 1,
        ["Players/HeadDot/Transparency"] = 0,

        -- Tracer ----------------------------------------------------------
        ["Players/Tracer/Enabled"]      = false,
        ["Players/Tracer/Outline"]      = true,
        ["Players/Tracer/Mode"]         = { [1] = "From Bottom" },
        ["Players/Tracer/Thickness"]    = 1,
        ["Players/Tracer/Transparency"] = 0,

        -- Offscreen Arrow -------------------------------------------------
        ["Players/Arrow/Enabled"]      = false,
        ["Players/Arrow/Filled"]       = true,
        ["Players/Arrow/Outline"]      = true,
        ["Players/Arrow/Width"]        = 14,
        ["Players/Arrow/Height"]       = 28,
        ["Players/Arrow/Radius"]       = 150,
        ["Players/Arrow/Thickness"]    = 1,
        ["Players/Arrow/Transparency"] = 0,
    }
end
