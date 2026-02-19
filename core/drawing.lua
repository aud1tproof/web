return function(Utils)
    local WhiteColor = Utils.WhiteColor
    local Fonts      = Drawing.Fonts

    local Draw = {}

    -- Raw drawing constructor -----------------------------------------------

    function Draw.New(Type, Props)
        local obj = Drawing.new(Type)
        if Props then
            for k, v in pairs(Props) do obj[k] = v end
        end
        return obj
    end

    -- -- Recursive cleanup -----------------------------------------------------

    function Draw.Clear(tbl)
        for _, v in pairs(tbl) do
            if type(v) == "table" then
                Draw.Clear(v)
            else
                if isrenderobj and not isrenderobj(v) then continue end
                pcall(function() v:Destroy() end)
            end
        end
    end

    -- Paired drawing factories (Main + Outline) -----------------------------

    function Draw.Line()
        return {
            Outline = Draw.New("Line",   { Visible = false, ZIndex = 0 }),
            Main    = Draw.New("Line",   { Visible = false, ZIndex = 1 }),
        }
    end

    function Draw.Circle()
        return {
            Outline = Draw.New("Circle", { Visible = false, ZIndex = 0 }),
            Main    = Draw.New("Circle", { Visible = false, ZIndex = 1 }),
        }
    end

    function Draw.Triangle()
        return {
            Outline = Draw.New("Triangle", { Visible = false, ZIndex = 0 }),
            Main    = Draw.New("Triangle", { Visible = false, ZIndex = 1 }),
        }
    end

    function Draw.Square()
        return {
            Outline = Draw.New("Square", { Visible = false, ZIndex = 0, Filled = true }),
            Main    = Draw.New("Square", { Visible = false, ZIndex = 1, Filled = true }),
        }
    end

    function Draw.Text(Center)
        return Draw.New("Text", {
            Visible  = false,
            ZIndex   = 0,
            Center   = Center,
            Outline  = true,
            Color    = WhiteColor,
            Font     = Fonts.Plex,
        })
    end

    -- Full drawing table for one ESP target ---------------------------------
  
    function Draw.NewTargetDrawings()
        return {
            Box = {
                Visible        = false,
                OutlineVisible = false,
                LineLT = Draw.Line(), LineTL = Draw.Line(),
                LineLB = Draw.Line(), LineBL = Draw.Line(),
                LineRT = Draw.Line(), LineTR = Draw.Line(),
                LineRB = Draw.Line(), LineBR = Draw.Line(),
            },
            HealthBar = Draw.Square(),
            Tracer    = Draw.Line(),
            HeadDot   = Draw.Circle(),
            Arrow     = Draw.Triangle(),
            Textboxes = {
                Name     = Draw.Text(true),
                Distance = Draw.Text(true),
                Health   = Draw.Text(false),
                Weapon   = Draw.Text(false),
            },
        }
    end

    return Draw
end
