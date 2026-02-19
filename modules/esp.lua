return function(ESP, Utils, Overrides)

    local RunService       = game:GetService("RunService")
    local PlayerService    = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local Workspace        = game:GetService("Workspace")

    repeat task.wait() until PlayerService.LocalPlayer
    local LocalPlayer = PlayerService.LocalPlayer

    -- Shorthand aliases -----------------------------------------------------
    local GetFlag        = Utils.GetFlag
    local GetDistance    = Utils.GetDistance
    local WorldToScreen  = Utils.WorldToScreen
    local IsWithinReach  = Utils.IsWithinReach
    local GetScaleFactor = Utils.GetScaleFactor
    local AntiXY         = Utils.AntiAliasingXY
    local CalcBoxSize    = Utils.CalculateBoxSize
    local GetRelative    = Utils.GetRelative
    local RotateVec      = Utils.RotateVec
    local RelCenter      = Utils.RelativeToCenter
    local EvalHealth     = Utils.EvalHealth

    local GetCharacter   = Overrides.GetCharacter
    local GetHealth      = Overrides.GetHealth
    local GetTeam        = Overrides.GetTeam
    local GetWeapon      = Overrides.GetWeapon

    local FindFirstChild = Workspace.FindFirstChild
    local V2New          = Vector2.new
    local Rad            = math.rad
    local Floor          = math.floor

    -- Helper: write colour / thickness / alpha / endpoints onto a Line pair -
    local function SetLine(Pair, Color, Thick, Alpha, Fm, FmO, To, ToO)
        Pair.Main.Color            = Color
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
        local D    = E.Drawing
        local TB   = D.Textboxes
        local Flag = E.Flag
        local Flags= E.Flags

        -- 1. Gather world state ---------------------------------------------
        local Character, RootPart = GetCharacter(Target, E.Mode)

        local ScreenPos, OnScreen = Vector2.zero, false
        local Distance            = 0
        local InRange             = false
        local Health, MaxHealth   = 100, 100
        local IsAlive             = false
        local InEnemy, TeamColor  = true, Utils.WhiteColor
        local Color               = Utils.WhiteColor

        if Character and RootPart then
            ScreenPos, OnScreen        = WorldToScreen(RootPart.Position)
            Distance                   = GetDistance(RootPart.Position)
            InRange                    = IsWithinReach(GetFlag(Flags, Flag, "/DistanceCheck"),
                                                       GetFlag(Flags, Flag, "/Distance"), Distance)
            Health, MaxHealth, IsAlive = GetHealth(Target, Character, E.Mode)
            InEnemy, TeamColor         = GetTeam(Target, Character, E.Mode)
            Color = GetFlag(Flags, Flag, "/TeamColor") and TeamColor
                or (InEnemy and GetFlag(Flags, Flag, "/Enemy")[6]
                or               GetFlag(Flags, Flag, "/Ally")[6])
        end

        -- 2. Compute all visibility flags up front --------------------------
        local TeamOK = (not GetFlag(Flags, Flag, "/TeamCheck") and not InEnemy) or InEnemy
        local Vis    = Character and RootPart and OnScreen       and InRange and IsAlive and TeamOK
        local ArrVis = Character and RootPart and (not OnScreen) and InRange and IsAlive and TeamOK

        local BoxOn   = Vis    and GetFlag(Flags, Flag, "/Box/Enabled")      or false
        local OutOn   = BoxOn  and GetFlag(Flags, Flag, "/Box/Outline")      or false
        local HBOn    = false  -- resolved below after BoxSize check
        local TracOn  = Vis    and GetFlag(Flags, Flag, "/Tracer/Enabled")   or false
        local DotOn   = Vis    and GetFlag(Flags, Flag, "/HeadDot/Enabled")  or false
        local ArrOn   = ArrVis and GetFlag(Flags, Flag, "/Arrow/Enabled")    or false
        local NameOn  = Vis    and GetFlag(Flags, Flag, "/Name/Enabled")     or false
        local HpTxtOn = Vis    and GetFlag(Flags, Flag, "/Health/Enabled")   or false
        local DistOn  = Vis    and GetFlag(Flags, Flag, "/Distance/Enabled") or false
        local WepOn   = Vis    and GetFlag(Flags, Flag, "/Weapon/Enabled")   or false

        -- 3. Drawing updates (gated by flags computed above) ----------------

        if Vis then
            local SX, SY = ScreenPos.X, ScreenPos.Y

            -- Tracer
            if TracOn then
                local Head = FindFirstChild(Character, "Head", true)
                if Head then
                    local HP    = WorldToScreen(Head.Position)
                    local Mode_ = GetFlag(Flags, Flag, "/Tracer/Mode")
                    local Thick = GetFlag(Flags, Flag, "/Tracer/Thickness")
                    local Alpha = 1 - GetFlag(Flags, Flag, "/Tracer/Transparency")
                    local Cam   = Utils.GetCamera()
                    local From  = (Mode_[1] == "From Mouse" and UserInputService:GetMouseLocation())
                               or V2New(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y)
                    SetLine(D.Tracer, Color, Thick, Alpha, From, From, HP, HP)
                end
            end

            -- Head dot
            if DotOn then
                local Head = FindFirstChild(Character, "Head", true)
                if Head then
                    local HP       = WorldToScreen(Head.Position)
                    local Filled   = GetFlag(Flags, Flag, "/HeadDot/Filled")
                    local Radius   = GetScaleFactor(GetFlag(Flags, Flag, "/HeadDot/Autoscale"),
                                                    GetFlag(Flags, Flag, "/HeadDot/Radius"), Distance)
                    local NumSides = GetFlag(Flags, Flag, "/HeadDot/NumSides")
                    local Thick    = GetFlag(Flags, Flag, "/HeadDot/Thickness")
                    local Alpha    = 1 - GetFlag(Flags, Flag, "/HeadDot/Transparency")
                    local HD       = D.HeadDot

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

            -- Corner box + health bar + text labels
            if BoxOn then
                local BoxSize   = CalcBoxSize(Character, Distance)
                local HPct      = Health / MaxHealth
                local Alpha     = 1 - GetFlag(Flags, Flag, "/Box/Transparency")
                local Thick     = GetFlag(Flags, Flag, "/Box/Thickness")
                local TAdj      = Floor(Thick / 2)
                local CornerPct = GetFlag(Flags, Flag, "/Box/CornerSize")
                local Corner    = V2New(
                    (BoxSize.X / 2) * (CornerPct / 100),
                    (BoxSize.Y / 2) * (CornerPct / 100))
                local HX, HY   = BoxSize.X / 2, BoxSize.Y / 2
                local B        = D.Box

                -- Corner segments (8 lines, 2 per corner)
                local F, T
                F = AntiXY(SX-HX, SY-HY); T = AntiXY(SX-HX, SY-HY+Corner.Y)
                SetLine(B.LineLT, Color, Thick, Alpha, F-V2New(0,TAdj),   F-V2New(0,TAdj+1), T,            T+V2New(0,1))

                F = AntiXY(SX-HX, SY-HY); T = AntiXY(SX-HX+Corner.X, SY-HY)
                SetLine(B.LineTL, Color, Thick, Alpha, F-V2New(TAdj,0),   F-V2New(TAdj+1,0), T,            T+V2New(1,0))

                F = AntiXY(SX-HX, SY+HY); T = AntiXY(SX-HX, SY+HY-Corner.Y)
                SetLine(B.LineLB, Color, Thick, Alpha, F+V2New(0,TAdj),   F+V2New(0,TAdj+1), T,            T-V2New(0,1))

                F = AntiXY(SX-HX, SY+HY); T = AntiXY(SX-HX+Corner.X, SY+HY)
                SetLine(B.LineBL, Color, Thick, Alpha, F-V2New(TAdj,1),   F-V2New(TAdj+1,1), T-V2New(0,1), T-V2New(-1,1))

                F = AntiXY(SX+HX, SY-HY); T = AntiXY(SX+HX, SY-HY+Corner.Y)
                SetLine(B.LineRT, Color, Thick, Alpha, F-V2New(1,TAdj),   F-V2New(1,TAdj+1), T-V2New(1,0), T+V2New(-1,1))

                F = AntiXY(SX+HX, SY-HY); T = AntiXY(SX+HX-Corner.X, SY-HY)
                SetLine(B.LineTR, Color, Thick, Alpha, F+V2New(TAdj,0),   F+V2New(TAdj+1,0), T,            T-V2New(1,0))

                F = AntiXY(SX+HX, SY+HY); T = AntiXY(SX+HX, SY+HY-Corner.Y)
                SetLine(B.LineRB, Color, Thick, Alpha, F+V2New(-1,TAdj),  F+V2New(-1,TAdj+1),T-V2New(1,0), T-V2New(1,1))

                F = AntiXY(SX+HX, SY+HY); T = AntiXY(SX+HX-Corner.X, SY+HY)
                SetLine(B.LineBR, Color, Thick, Alpha, F+V2New(TAdj,-1),  F+V2New(TAdj+1,-1),T-V2New(0,1), T-V2New(1,1))

                -- Health bar (finalize HBOn now that we have BoxSize)
                HBOn = GetFlag(Flags, Flag, "/Box/HealthBar") and BoxSize.Y >= 18 or false
                if HBOn then
                    local HB = D.HealthBar
                    HB.Main.Color           = EvalHealth(HPct)
                    HB.Main.Transparency    = Alpha
                    HB.Outline.Transparency = Alpha
                    HB.Outline.Size         = AntiXY(Thick + 2, BoxSize.Y + (Thick + 1))
                    HB.Outline.Position     = AntiXY(
                        (SX - HX) - Thick - TAdj - 4, SY - HY - TAdj - 1)
                    HB.Main.Size     = V2New(HB.Outline.Size.X - 2,
                                          -HPct * (HB.Outline.Size.Y - 2))
                    HB.Main.Position = HB.Outline.Position + V2New(1, HB.Outline.Size.Y - 1)
                end

                -- Text labels
                if NameOn or HpTxtOn or DistOn or WepOn then
                    local TxtSize  = Floor(GetScaleFactor(
                        GetFlag(Flags, Flag, "/Name/Autoscale"),
                        GetFlag(Flags, Flag, "/Name/Size"), Distance))
                    local TxtAlpha = 1 - GetFlag(Flags, Flag, "/Name/Transparency")
                    local Outline  = GetFlag(Flags, Flag, "/Name/Outline")

                    if NameOn then
                        TB.Name.Outline      = Outline
                        TB.Name.Transparency = TxtAlpha
                        TB.Name.Size         = TxtSize
                        TB.Name.Text         = E.Mode == "Player" and Target.Name
                                              or (InEnemy and "Enemy NPC" or "Ally NPC")
                        TB.Name.Position     = AntiXY(
                            SX, SY - HY - TB.Name.TextBounds.Y - TAdj - 2)
                    end
                    if HpTxtOn then
                        local Hx_off = HBOn
                            and (SX-HX) - TB.Health.TextBounds.X - (Thick+TAdj+5)
                            or  (SX-HX) - TB.Health.TextBounds.X - TAdj - 2
                        TB.Health.Outline      = Outline
                        TB.Health.Transparency = TxtAlpha
                        TB.Health.Size         = TxtSize
                        TB.Health.Text         = tostring(math.floor(HPct * 100)) .. "%"
                        TB.Health.Position     = AntiXY(Hx_off, SY - HY - TAdj - 1)
                    end
                    if DistOn then
                        TB.Distance.Outline      = Outline
                        TB.Distance.Transparency = TxtAlpha
                        TB.Distance.Size         = TxtSize
                        TB.Distance.Text         = tostring(math.floor(Distance)) .. " studs"
                        TB.Distance.Position     = AntiXY(SX, SY + HY + TAdj + 2)
                    end
                    if WepOn then
                        TB.Weapon.Outline      = Outline
                        TB.Weapon.Transparency = TxtAlpha
                        TB.Weapon.Size         = TxtSize
                        TB.Weapon.Text         = GetWeapon(Target, Character, E.Mode)
                        TB.Weapon.Position     = AntiXY(SX + HX + TAdj + 2, SY - HY - TAdj - 1)
                    end
                end
            end -- BoxOn
        end -- Vis

        -- Offscreen arrow (separate from Vis block since it needs RootPart not OnScreen)
        if ArrOn then
            local Dir     = GetRelative(RootPart.Position).Unit
            local R90     = Rad(90)
            local ArrRad  = GetFlag(Flags, Flag, "/Arrow/Radius")
            local SideLen = GetFlag(Flags, Flag, "/Arrow/Width") / 2
            local Base    = Dir * ArrRad

            local PA = RelCenter(Base + RotateVec(Dir,  R90) * SideLen)
            local PB = RelCenter(Dir * (ArrRad + GetFlag(Flags, Flag, "/Arrow/Height")))
            local PC = RelCenter(Base + RotateVec(Dir, -R90) * SideLen)

            local Filled = GetFlag(Flags, Flag, "/Arrow/Filled")
            local Thick  = GetFlag(Flags, Flag, "/Arrow/Thickness")
            local Alpha  = 1 - GetFlag(Flags, Flag, "/Arrow/Transparency")
            local AR     = D.Arrow

            AR.Main.Color           = Color
            AR.Main.Filled          = Filled
            AR.Main.Thickness       = Thick
            AR.Outline.Thickness    = Thick + 2
            AR.Main.Transparency    = Alpha
            AR.Outline.Transparency = Alpha
            AR.Main.PointA    = PA; AR.Outline.PointA = PA
            AR.Main.PointB    = PB; AR.Outline.PointB = PB
            AR.Main.PointC    = PC; AR.Outline.PointC = PC
        end

        -- 4. Apply visibility to all drawing objects ------------------------
        D.Box.Visible        = BoxOn
        D.Box.OutlineVisible = OutOn
        for _, Line in pairs(D.Box) do
            if type(Line) ~= "table" then continue end
            Line.Main.Visible    = BoxOn
            Line.Outline.Visible = OutOn
        end

        D.HealthBar.Main.Visible    = HBOn
        D.HealthBar.Outline.Visible = HBOn and OutOn or false

        D.Arrow.Main.Visible    = ArrOn
        D.Arrow.Outline.Visible = ArrOn and GetFlag(Flags, Flag, "/Arrow/Outline") or false

        D.HeadDot.Main.Visible    = DotOn
        D.HeadDot.Outline.Visible = DotOn and GetFlag(Flags, Flag, "/HeadDot/Outline") or false

        D.Tracer.Main.Visible    = TracOn
        D.Tracer.Outline.Visible = TracOn and GetFlag(Flags, Flag, "/Tracer/Outline") or false

        TB.Name.Visible     = NameOn
        TB.Health.Visible   = HpTxtOn
        TB.Distance.Visible = DistOn
        TB.Weapon.Visible   = WepOn
    end

    -- Render loop -----------------------------------------------------------
    ESP.Connection = RunService.RenderStepped:Connect(function()
        debug.profilebegin("ESP_RENDER")

        for Target, E in pairs(ESP.ESP) do
            Update(E, Target)
        end

        for _, E in pairs(ESP.ObjectESP) do
            if not GetFlag(E.Flags, E.GlobalFlag, "/Enabled")
            or not GetFlag(E.Flags, E.Flag,       "/Enabled") then
                E.Name.Visible = false
                continue
            end

            if E.IsBasePart then
                E.Target.Position = E.Target.RootPart.Position
            end

            local SP, On = WorldToScreen(E.Target.Position)
            local Dist   = GetDistance(E.Target.Position)
            local InRng  = IsWithinReach(
                GetFlag(E.Flags, E.GlobalFlag, "/DistanceCheck"),
                GetFlag(E.Flags, E.GlobalFlag, "/Distance"), Dist)

            E.Name.Visible = On and InRng or false

            if E.Name.Visible then
                local C = GetFlag(E.Flags, E.Flag, "/Color")
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
