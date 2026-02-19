local REPO = "https://raw.githubusercontent.com/aud1tproof/web/main/"

local function Fetch(path)
    return loadstring(game:HttpGet(REPO .. path))
end

local Utils     = Fetch("core/utils.lua")()
local Drawing_  = Fetch("core/drawing.lua")(Utils)
local Config    = Fetch("core/config.lua")()
local Overrides = Fetch("modules/overrides.lua")(Utils)
local ESP       = Fetch("modules/esp.lua")(Utils, Drawing_, Config, Overrides)

Fetch("modules/players.lua")(ESP, Utils, Overrides)

return ESP
