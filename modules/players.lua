return function(ESP, Utils, Overrides)

    local RunService    = game:GetService("RunService")
    local PlayerService = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")

    repeat task.wait() until PlayerService.LocalPlayer
    local LocalPlayer = PlayerService.LocalPlayer

    -- Shorthand aliases -----------------------------------------------------
    local GetFlag       = Utils.GetFlag
    local GetDistance   = Utils.GetDistance
    local WorldToScreen = Utils.WorldToScreen
    local IsWithinReach = Utils.IsWithinReach
    local GetScaleFactor= Utils.GetScaleFactor
    local AntiXY        = Utils.AntiAliasingXY
    local CalcBoxSize   = Utils.CalculateBoxSize
    local GetRelative   = Utils.GetRelative
    local RotateVec     = Utils.RotateVec
    local RelCenter     = Utils.RelativeToCenter
    local EvalHealth    = Utils.EvalHealth

    local GetCharacter  = Overrides.GetCharacter
    local GetHealth     = Overrides.GetHealth
    local GetTeam       = Overrides.GetTeam
    local GetWeapon     = Overrides.GetWeapon

    local Workspace     = game:GetService("Workspace")
    local FindFirstChild = Workspace.FindFirstChild
    local V2New          = Vector2.new
    local Rad            = math.rad
    local Floor          = math.floor

    -- Helper: apply colour + thickness + from/to on a Line pair ------------
    local function SetLine(Pair, Color, Thick, Alpha, Fm, FmO, To, ToO)
        Pair.Main.Color           = Color
        Pair.Main.Thickness        = Thick
        Pair.Outline.Thickness     = Thick + 2
        Pair.Main.Transparency     = Alpha
        Pair.Outline.Transparency  = Alpha
        Pair.Main.From             = Fm
        Pair.Outline.From          = FmO
        Pair.Main.To               = To
        Pair.Outline.To            = ToO
    end

    -- Per-target Update -----------------------------------------------------
    local function Update(E, Target)
        local TB   = E.Drawing.Textboxes
        local Flag = E.Flag
        local Flags= E.Flags

        local Character, RootPart        = nil, nil
        local ScreenPos, OnScreen        = Vector2.zero, false
        local Distance, InRange          = 0, false
        local BoxTooSmall                = false
        local Health, MaxHealth, IsAlive = 100, 100, false
        local InEnemy, TeamColor         = true, Utils.WhiteColor
        local Color                      = Utils.WhiteColor

        Character, RootPart = GetCharacter(Target, E.Mode)

        if Character and RootPart then
            ScreenPos, OnScreen = WorldToScreen(RootPart.Position)

            if OnScreen then
                Distance = GetDistance(RootPart.Position)
                InRange  = IsWithinReach(GetFlag(Flags, Flag, "/DistanceCheck"),
                                          GetFlag(Flags, Flag, "/Distance"), Distance)
                if InRange then
                    Health, MaxHealth, IsAlive = GetHealth(Target, Character, E.Mode)
                    InEnemy, TeamColor         = GetTeam(Target, Character, E.Mode)
                    Color = GetFlag(Flags, Flag, "/TeamColor") and TeamColor
                        or (InEnemy and GetFlag(Flags, Flag, "/Enemy")[6]
                        or               GetFlag(Flags, Flag, "/Ally")[6])

                    -- Tracer --------------------------------------------
                    if E.Drawing.Tracer.Main.Visible then
                        local Head = FindFirstChild(Character, "Head", true)
                        if Head then
                            local HP    = WorldToScreen(Head.Position)
                            local Mode_ = GetFlag(Flags, Flag, "/Tracer/Mode")
                            local Thick = GetFlag(Flags, Flag, "/Tracer/Thickness")
                            local Alpha = 1 - GetFlag(Flags, Flag, "/Tracer/Transparency")
                            local From  = (Mode_[1] == "From Mouse" and UserInputService:GetMouseLocation())
                                       or V2New(Utils.GetCamera().ViewportSize.X / 2,
                                                Utils.GetCamera().ViewportSize.Y)
                            SetLine(E.Drawing.Tracer, Color, Thick, Alpha, From, From, HP, HP)
                        end
                    end

                    -- Head Dot ------------------------------------------
                    if E.Drawing.HeadDot.Main.Visible then
                        local Head = FindFirstChild(Character, "Head", true)
                        if Head then
                            local HP       = WorldToScreen(Head.Position)
                            local Filled   = GetFlag(Flags, Flag, "/HeadDot/Filled")
                            local Radius   = GetScaleFactor(GetFlag(Flags, Flag, "/HeadDot/Autoscale"),
                                                            GetFlag(Flags, Flag, "/HeadDot/Radius"), Distance)
                            local NumSides = GetFlag(Flags, Flag, "/HeadDot/NumSides")
                            local Thick    = GetFlag(Flags, Flag, "/HeadDot/Thickness")
                            local Alpha    = 1 - GetFlag(Flags, Flag, "/HeadDot/Transparency")
                            local HD       = E.Drawing.HeadDot

                            HD.Main.Color           = Color
                            HD.Main.Transparency    = Alpha
                            HD.Outline.Transparency = Alpha
                            HD.Main.NumSides        = NumSides
                            HD.Outline.NumSides     = NumSides
                            HD.Main.Radius          = Radius
                            HD.Outline.Radius       = Radius
                            HD.Main.Thickness       = Thick
                            HD.Outline.Thickness    = Thick + 2
                            HD.Main.Filled          = Filled
                            HD.Main.Position        = HP
                            HD.Outline.Position     = HP
                        end
                    end

                    -- Corner Box ----------------------------------------
                    if E.Drawing.Box.Visible then
                        local BoxSize   = CalcBoxSize(Character, Distance)
                        local HPct      = Health / MaxHealth
                        BoxTooSmall     = BoxSize.Y < 18
                        local Alpha     = 1 - GetFlag(Flags, Flag, "/Box/Transparency")
                        local Thick     = GetFlag(Flags, Flag, "/Box/Thickness")
                        local TAdj      = Floor(Thick / 2)
                        local CornerPct = GetFlag(Flags, Flag, "/Box/CornerSize")
                        local Corner    = V2New(
                            (BoxSize.X / 2) * (CornerPct / 100),
                            (BoxSize.Y / 2) * (CornerPct / 100))

                        local SX, SY = ScreenPos.X, ScreenPos.Y
                        local HX, HY = BoxSize.X / 2, BoxSize.Y / 2
                        local B      = E.Drawing.Box

                        -- Corner segments
                        local F, T
                        F = AntiXY(SX-HX, SY-HY); T = AntiXY(SX-HX, SY-HY+Corner.Y)
                        SetLine(B.LineLT, Color, Thick, Alpha, F-V2New(0,TAdj), F-V2New(0,TAdj+1), T, T+V2New(0,1))

                        F = AntiXY(SX-HX, SY-HY); T = AntiXY(SX-HX+Corner.X, SY-HY)
                        SetLine(B.LineTL, Color, Thick, Alpha, F-V2New(TAdj,0), F-V2New(TAdj+1,0), T, T+V2New(1,0))

                        F = AntiXY(SX-HX, SY+HY); T = AntiXY(SX-HX, SY+HY-Corner.Y)
                        SetLine(B.LineLB, Color, Thick, Alpha, F+V2New(0,TAdj), F+V2New(0,TAdj+1), T, T-V2New(0,1))

                        F = AntiXY(SX-HX, SY+HY); T = AntiXY(SX-HX+Corner.X, SY+HY)
                        SetLine(B.LineBL, Color, Thick, Alpha, F-V2New(TAdj,1), F-V2New(TAdj+1,1), T-V2New(0,1), T-V2New(-1,1))

                        F = AntiXY(SX+HX, SY-HY); T = AntiXY(SX+HX, SY-HY+Corner.Y)
                        SetLine(B.LineRT, Color, Thick, Alpha, F-V2New(1,TAdj), F-V2New(1,TAdj+1), T-V2New(1,0), T+V2New(-1,1))

                        F = AntiXY(SX+HX, SY-HY); T = AntiXY(SX+HX-Corner.X, SY-HY)
                        SetLine(B.LineTR, Color, Thick, Alpha, F+V2New(TAdj,0), F+V2New(TAdj+1,0), T, T-V2New(1,0))

                        F = AntiXY(SX+HX, SY+HY); T = AntiXY(SX+HX, SY+HY-Corner.Y)
                        SetLine(B.LineRB, Color, Thick, Alpha, F+V2New(-1,TAdj), F+V2New(-1,TAdj+1), T-V2New(1,0), T-V2New(1,1))

                        F = AntiXY(SX+HX, SY+HY); T = AntiXY(SX+HX-Corner.X, SY+HY)
                        SetLine(B.LineBR, Color, Thick, Alpha, F+V2New(TAdj,-1), F+V2New(TAdj+1,-1), T-V2New(0,1), T-V2New(1,1))

                        -- Health bar
                        if E.Drawing.HealthBar.Main.Visible then
                            local HB = E.Drawing.HealthBar
                            HB.Main.Color           = EvalHealth(HPct)
                            HB.Main.Transparency    = Alpha
                            HB.Outline.Transparency = Alpha
                            HB.Outline.Size         = AntiXY(Thick + 2, BoxSize.Y + (Thick + 1))
                            HB.Outline.Position     = AntiXY(
                                (SX - HX) - Thick - TAdj - 4, SY - HY - TAdj - 1)
                            HB.Main.Size     = V2New(HB.Outline.Size.X - 2,
                                                  -HPct * (HB.Outline.Size.Y - 2))
                            HB.Main.Position = HB.Outline.Position
                                + V2New(1, HB.Outline.Size.Y - 1)
                        end

                        -- Text labels
                        if TB.Name.Visible or TB.Health.Visible
                        or TB.Distance.Visible or TB.Weapon.Visible then
                            local TxtSize  = Floor(GetScaleFactor(
                                GetFlag(Flags, Flag, "/Name/Autoscale"),
                                GetFlag(Flags, Flag, "/Name/Size"), Distance))
                            local TxtAlpha = 1 - GetFlag(Flags, Flag, "/Name/Transparency")
                            local Outline  = GetFlag(Flags, Flag, "/Name/Outline")

                            if TB.Name.Visible then
                                TB.Name.Outline      = Outline
                                TB.Name.Transparency = TxtAlpha
                                TB.Name.Size         = TxtSize
                                TB.Name.Text         = E.Mode == "Player" and Target.Name
                                                      or (InEnemy and "Enemy NPC" or "Ally NPC")
                                TB.Name.Position     = AntiXY(
                                    SX, SY - HY - TB.Name.TextBounds.Y - TAdj - 2)
                            end
                            if TB.Health.Visible then
                                local HBVis  = E.Drawing.HealthBar.Main.Visible
                                local Hx_off = HBVis
                                    and (SX-HX) - TB.Health.TextBounds.X - (Thick+TAdj+5)
                                    or  (SX-HX) - TB.Health.TextBounds.X - TAdj - 2
                                TB.Health.Outline      = Outline
                                TB.Health.Transparency = TxtAlpha
                                TB.Health.Size         = TxtSize
                                TB.Health.Text         = tostring(math.floor(HPct * 100)) .. "%"
                                TB.Health.Position     = AntiXY(Hx_off, SY - HY - TAdj - 1)
                            end
                            if TB.Distance.Visible then
                                TB.Distance.Outline      = Outline
                                TB.Distance.Transparency = TxtAlpha
                                TB.Distance.Size         = TxtSize
                                TB.Distance.Text         = tostring(math.floor(Distance)) .. " studs"
                                TB.Distance.Position     = AntiXY(SX, SY + HY + TAdj + 2)
                            end
                            if TB.Weapon.Visible then
                                TB.Weapon.Outline      = Outline
                                TB.Weapon.Transparency = TxtAlpha
                                TB.Weapon.Size         = TxtSize
                                TB.Weapon.Text         = GetWeapon(Target, Character, E.Mode)
                                TB.Weapon.Position     = AntiXY(SX + HX + TAdj + 2, SY - HY - TAdj - 1)
                            end
                        end
                    end -- box
                end -- in range
            else
                -- Offscreen Arrow ---------------------------------------
                if E.Drawing.Arrow.Main.Visible then
                    Distance = GetDistance(RootPart.Position)
                    InRange  = IsWithinReach(GetFlag(Flags, Flag, "/DistanceCheck"),
                                              GetFlag(Flags, Flag, "/Distance"), Distance)
                    Health, MaxHealth, IsAlive = GetHealth(Target, Character, E.Mode)
                    InEnemy, TeamColor         = GetTeam(Target, Character, E.Mode)
                    Color = GetFlag(Flags, Flag, "/TeamColor") and TeamColor
                        or (InEnemy and GetFlag(Flags, Flag, "/Enemy")[6]
                        or               GetFlag(Flags, Flag, "/Ally")[6])

                    local Camera   = Utils.GetCamera()
                    local Dir      = GetRelative(RootPart.Position).Unit
                    local R90      = Rad(90)
                    local ArrRad   = GetFlag(Flags, Flag, "/Arrow/Radius")
                    local SideLen  = GetFlag(Flags, Flag, "/Arrow/Width") / 2
                    local Base     = Dir * ArrRad

                    local PA = RelCenter(Base + RotateVec(Dir,  R90) * SideLen)
                    local PB = RelCenter(Dir * (ArrRad + GetFlag(Flags, Flag, "/Arrow/Height")))
                    local PC = RelCenter(Base + RotateVec(Dir, -R90) * SideLen)

                    local Filled = GetFlag(Flags, Flag, "/Arrow/Filled")
                    local Thick  = GetFlag(Flags, Flag, "/Arrow/Thickness")
                    local Alpha  = 1 - GetFlag(Flags, Flag, "/Arrow/Transparency")
                    local AR     = E.Drawing.Arrow

                    AR.Main.Color           = Color
                    AR.Main.Filled          = Filled
                    AR.Main.Thickness        = Thick
                    AR.Outline.Thickness     = Thick + 2
                    AR.Main.Transparency     = Alpha
                    AR.Outline.Transparency  = Alpha
                    AR.Main.PointA    = PA; AR.Outline.PointA = PA
                    AR.Main.PointB    = PB; AR.Outline.PointB = PB
                    AR.Main.PointC    = PC; AR.Outline.PointC = PC
                end
            end
        end

        -- Visibility pass ---------------------------------------------------
        local TeamOK = (not GetFlag(Flags, Flag, "/TeamCheck") and not InEnemy) or InEnemy
        local Vis    = RootPart and OnScreen       and InRange and IsAlive and TeamOK
        local ArrVis = RootPart and (not OnScreen) and InRange and IsAlive and TeamOK

        local BoxOn = Vis    and GetFlag(Flags, Flag, "/Box/Enabled")  or false
        local OutOn = BoxOn  and GetFlag(Flags, Flag, "/Box/Outline")  or false

        E.Drawing.Box.Visible        = BoxOn
        E.Drawing.Box.OutlineVisible = OutOn

        for _, Line in pairs(E.Drawing.Box) do
            if type(Line) ~= "table" then continue end
            Line.Main.Visible    = BoxOn
            Line.Outline.Visible = OutOn
        end

        E.Drawing.HealthBar.Main.Visible    = BoxOn and GetFlag(Flags, Flag, "/Box/HealthBar") and not BoxTooSmall or false
        E.Drawing.HealthBar.Outline.Visible = E.Drawing.HealthBar.Main.Visible and OutOn or false

        E.Drawing.Arrow.Main.Visible    = ArrVis and GetFlag(Flags, Flag, "/Arrow/Enabled")  or false
        E.Drawing.Arrow.Outline.Visible = GetFlag(Flags, Flag, "/Arrow/Outline") and E.Drawing.Arrow.Main.Visible or false

        E.Drawing.HeadDot.Main.Visible    = Vis and GetFlag(Flags, Flag, "/HeadDot/Enabled") or false
        E.Drawing.HeadDot.Outline.Visible = GetFlag(Flags, Flag, "/HeadDot/Outline") and E.Drawing.HeadDot.Main.Visible or false

        E.Drawing.Tracer.Main.Visible    = Vis and GetFlag(Flags, Flag, "/Tracer/Enabled") or false
        E.Drawing.Tracer.Outline.Visible = GetFlag(Flags, Flag, "/Tracer/Outline") and E.Drawing.Tracer.Main.Visible or false

        TB.Name.Visible     = Vis and GetFlag(Flags, Flag, "/Name/Enabled")     or false
        TB.Health.Visible   = Vis and GetFlag(Flags, Flag, "/Health/Enabled")   or false
        TB.Distance.Visible = Vis and GetFlag(Flags, Flag, "/Distance/Enabled") or false
        TB.Weapon.Visible   = Vis and GetFlag(Flags, Flag, "/Weapon/Enabled")   or false
    end

    -- Render loop -----------------------------------------------------------
    ESP.Connection = RunService.RenderStepped:Connect(function()
        debug.profilebegin("ESP_RENDER")

        -- Player / NPC ESP
        for Target, E in pairs(ESP.ESP) do
            Update(E, Target)
        end

        -- Object label ESP
        for _, E in pairs(ESP.ObjectESP) do
            local GetFlag_ = Utils.GetFlag
            if not GetFlag_(E.Flags, E.GlobalFlag, "/Enabled")
            or not GetFlag_(E.Flags, E.Flag,       "/Enabled") then
                E.Name.Visible = false
                continue
            end

            if E.IsBasePart then
                E.Target.Position = E.Target.RootPart.Position
            end

            local SP, On = WorldToScreen(E.Target.Position)
            local Dist   = GetDistance(E.Target.Position)
            local InRng  = IsWithinReach(
                GetFlag_(E.Flags, E.GlobalFlag, "/DistanceCheck"),
                GetFlag_(E.Flags, E.GlobalFlag, "/Distance"), Dist)

            E.Name.Visible = On and InRng or false

            if E.Name.Visible then
                local C = GetFlag_(E.Flags, E.Flag, "/Color")
                E.Name.Transparency = 1 - C[4]
                E.Name.Color        = C[6]
                E.Name.Position     = SP
                E.Name.Text         = string.format("%s\n%i studs", E.Target.Name, Dist)
            end
        end

        debug.profileend()
    end)

    -- Auto-track all players ------------------------------------------------
    local function OnPlayerAdded(Player)
        if Player == LocalPlayer then return end
        ESP:AddESP(Player, "Player", "Players", ESP.Flags)
    end

    PlayerService.PlayerAdded:Connect(OnPlayerAdded)
    PlayerService.PlayerRemoving:Connect(function(Player)
        ESP:RemoveESP(Player)
    end)

    for _, Player in ipairs(PlayerService:GetPlayers()) do
        OnPlayerAdded(Player)
    end
end
