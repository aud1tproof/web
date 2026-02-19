return function(Utils, Draw, Config, Overrides)

    local ESP = {
        ESP       = {},
        ObjectESP = {},

        Flags = Config(),

        Overrides = Overrides,
        Utils     = Utils,
        Draw      = Draw,
    }

    -- Player / NPC ESP -----------------------------------------------------

    function ESP:AddESP(Target, Mode, Flag, Flags)
        if self.ESP[Target] then return end
        self.ESP[Target] = {
            Mode    = Mode,
            Flag    = Flag,
            Flags   = Flags,
            Drawing = Draw.NewTargetDrawings(),
        }
    end

    function ESP:RemoveESP(Target)
        local e = self.ESP[Target]
        if not e then return end
        Draw.Clear(e.Drawing)
        self.ESP[Target] = nil
    end

    -- Object (world-label) ESP ---------------------------------------------

    function ESP:AddObject(Object, Name, Position, GlobalFlag, Flag, Flags)
        if self.ObjectESP[Object] then return end
        local IsBasePart = typeof(Position) ~= "Vector3"
        self.ObjectESP[Object] = {
            Target = {
                Name     = Name,
                Position = IsBasePart and Position.Position or Position,
                RootPart = IsBasePart and Position or nil,
            },
            GlobalFlag = GlobalFlag,
            Flag       = Flag,
            Flags      = Flags,
            IsBasePart = IsBasePart,
            Name       = Draw.Text(true),
        }
    end

    function ESP:RemoveObject(Object)
        local e = self.ObjectESP[Object]
        if not e then return end
        e.Name:Destroy()
        self.ObjectESP[Object] = nil
    end

    return ESP
end
