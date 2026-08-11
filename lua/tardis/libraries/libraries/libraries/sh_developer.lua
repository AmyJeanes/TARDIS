-- Developer

local cv = CreateConVar("tardis2_developer", "0", FCVAR_ARCHIVE, "TARDIS - Log developer messages to console")

TARDIS.DevMode = cv:GetBool()

cvars.AddChangeCallback("tardis2_developer", function()
    TARDIS.DevMode = cv:GetBool()
end, "tardis_devmode")

---@param fmt string
---@param ... any
function TARDIS:DevInfo(fmt, ...)
    if not self.DevMode then return end
    MsgC(Color(120, 180, 255), "[TARDIS] " .. string.format(fmt, ...) .. "\n")
end

---@param fmt string
---@param ... any
function TARDIS:DevWarning(fmt, ...)
    if not self.DevMode then return end
    MsgC(Color(255, 190, 90), "[TARDIS] " .. string.format(fmt, ...) .. "\n")
end

local deprecation_seen = {}

-- Logs once per session per key so it doesn't spam in hot paths
---@param key string
---@param fmt string
---@param ... any
function TARDIS:DevDeprecation(key, fmt, ...)
    if not self.DevMode then return end
    if deprecation_seen[key] then return end
    deprecation_seen[key] = true
    MsgC(Color(255, 190, 90), "[TARDIS] Deprecated: " .. string.format(fmt, ...) .. "\n")
end
