-- Version

---@class tardis_version
---@field Major number
---@field Minor number
---@field Patch number

---@class tardis_migration
---@field date string
---@field func fun(self: TARDIS)
---@field source string

---@type table<string, tardis_migration>
TARDIS.Migrations = TARDIS.Migrations or {}

---@param str string
local function get_version_from_string(str)
    local major, minor, patch = string.match(str, "^(%d+)%.(%d+)%.(%d+)$")
    if not major then return false end
    return true, {
        Major = tonumber(major),
        Minor = tonumber(minor),
        Patch = tonumber(patch)
    }
end

---@param versionFile string
---@return tardis_version
local function get_version_from_file(versionFile)
    local version, success
    if file.Exists(versionFile, "DATA") then
        local versionStr = file.Read(versionFile, "DATA")
        success, version = get_version_from_string(versionStr)
        if success then
            return version
        else
            ErrorNoHalt("Invalid version in ".. versionFile .. ": " .. versionStr)
        end
    end
    
    version = {
        Major = 0,
        Minor = 0,
        Patch = 0
    }

    return version
end

local VERSION_FILE = "tardis/version" .. (SERVER and "_sv" or "_cl") .. ".txt"
local VERSION_LAST_USED_FILE = "tardis/version_lastused" .. (SERVER and "_sv" or "_cl") .. ".txt"
local MIGRATIONS_FILE = "tardis/migrations" .. (SERVER and "_sv" or "_cl") .. ".txt"

---@type tardis_version
TARDIS.PreviousVersion = TARDIS.PreviousVersion or get_version_from_file(VERSION_FILE)
---@type tardis_version
TARDIS.LastUsedVersion = TARDIS.LastUsedVersion or get_version_from_file(VERSION_LAST_USED_FILE)

---@api
---@return tardis_version
function TARDIS:GetVersion()
    return self.Version
end

function TARDIS:GetPreviousVersion()
    return self.PreviousVersion
end

function TARDIS:GetLastUsedVersion()
    return self.LastUsedVersion
end

function TARDIS:SetLastUsedVersion()
    if self:IsVersionEqualTo(self:GetVersion(), self.LastUsedVersion) then
        return
    end
    file.Write(VERSION_LAST_USED_FILE, self:GetVersionString())
    self.LastUsedVersion = self:GetVersion()
end

function TARDIS:IsNewVersion()
    if self.LastUsedVersion.Major == 0
        and self.LastUsedVersion.Minor == 0
        and self.LastUsedVersion.Patch == 0
    then
        return false
    end
    return self:IsVersionHigherThan(self.LastUsedVersion)
end

function TARDIS:IsNewInstall()
    return self.PreviousVersion.Major == 0
        and self.PreviousVersion.Minor == 0
        and self.PreviousVersion.Patch == 0
end

---@api
---@param version tardis_version?
function TARDIS:GetVersionString(version)
    version = version or self.Version
    return string.format("%d.%d.%d", version.Major, version.Minor, version.Patch)
end

-- Typed `any` because istable narrowing can't drop the class from a string|table union, cascading false nil-flags into callers.
---@param versionStrOrTbl any
---@param compareVersionStrOrTbl any
---@return tardis_version version
---@return tardis_version compareVersion
local function get_versions(versionStrOrTbl, compareVersionStrOrTbl)
    local version, compareVersion, success

    if istable(versionStrOrTbl) then
        version = versionStrOrTbl
    else
        success, version = get_version_from_string(versionStrOrTbl)
        if not success then
            error("Invalid version string: " .. versionStrOrTbl)
        end
    end

    if istable(compareVersionStrOrTbl) then
        compareVersion = compareVersionStrOrTbl
    elseif compareVersionStrOrTbl then
        success, compareVersion = get_version_from_string(compareVersionStrOrTbl)
        if not success then
            error("Invalid version string: " .. compareVersionStrOrTbl)
        end
    else
        compareVersion = TARDIS.Version
    end

    return version, compareVersion
end

---@param versionStrOrTbl string|table
---@param compareVersionStrOrTbl string|table?
function TARDIS:IsVersionHigherOrEqualTo(versionStrOrTbl, compareVersionStrOrTbl)
    local version, compareVersion = get_versions(versionStrOrTbl, compareVersionStrOrTbl)

    if compareVersion.Major > version.Major then return true end
    if compareVersion.Major < version.Major then return false end

    if compareVersion.Minor > version.Minor then return true end
    if compareVersion.Minor < version.Minor then return false end

    if compareVersion.Patch >= version.Patch then return true end

    return false
end

---@param versionStrOrTbl string|table
---@param compareVersionStrOrTbl string|table?
function TARDIS:IsVersionHigherThan(versionStrOrTbl, compareVersionStrOrTbl)
    local version, compareVersion = get_versions(versionStrOrTbl, compareVersionStrOrTbl)

    if compareVersion.Major > version.Major then return true end
    if compareVersion.Major < version.Major then return false end

    if compareVersion.Minor > version.Minor then return true end
    if compareVersion.Minor < version.Minor then return false end

    if compareVersion.Patch > version.Patch then return true end

    return false
end

---@param versionStrOrTbl string|table
---@param compareVersionStrOrTbl string|table?
function TARDIS:IsVersionEqualTo(versionStrOrTbl, compareVersionStrOrTbl)
    local version, compareVersion = get_versions(versionStrOrTbl, compareVersionStrOrTbl)

    if compareVersion.Major ~= version.Major then return false end
    if compareVersion.Minor ~= version.Minor then return false end
    if compareVersion.Patch ~= version.Patch then return false end

    return true
end

---@api
---@param name string
---@param date string
---@param func fun(self: TARDIS)
function TARDIS:AddMigration(name, date, func)
    local source = debug.getinfo(2).short_src

    if not string.match(date, "^%d%d%d%d%-%d%d%-%d%d$") then
        error("Invalid date in migration '" .. name .. "': " .. date .. " (expected YYYY-MM-DD)")
    end

    local existing = self.Migrations[name]
    if existing and existing.source ~= source then
        error("Duplicate migration registered: " .. name .. " (exists in both " .. existing.source .. " and " .. source .. ")")
    end

    self.Migrations[name] = {
        date = date,
        func = func,
        source = source
    }
end

local LEGACY_MIGRATION_VERSIONS = {
    ["health-changed"]  = "2023.8.0",
    ["binds-move"]      = "2025.2.0",
    ["settings-move"]   = "2025.2.0",
    ["locations-move"]  = "2025.2.0",
    ["music-move"]      = "2025.2.0",
}

---@return table<string, number>? applied nil when the addon has not run under this scheme yet
local function read_applied()
    if not file.Exists(MIGRATIONS_FILE, "DATA") then return nil end
    local data = TARDIS.von.deserialize(file.Read(MIGRATIONS_FILE, "DATA") or "")
    return istable(data) and data or {}
end

---@param applied table<string, number>
local function write_applied(applied)
    file.Write(MIGRATIONS_FILE, TARDIS.von.serialize(applied))
end

function TARDIS:RunMigrations()
    local applied = read_applied()

    if applied == nil then
        applied = {}
        local newInstall = self:IsNewInstall()
        for name in pairs(self.Migrations) do
            local legacy = LEGACY_MIGRATION_VERSIONS[name]
            if newInstall or (legacy and not self:IsVersionHigherThan(self.PreviousVersion, legacy)) then
                applied[name] = os.time()
            end
        end
        write_applied(applied)
    end

    local pending = {}
    for name in pairs(self.Migrations) do
        if not applied[name] then
            table.insert(pending, name)
        end
    end

    table.sort(pending, function(a, b)
        local dateA, dateB = self.Migrations[a].date, self.Migrations[b].date
        if dateA ~= dateB then return dateA < dateB end
        return a < b
    end)

    for _, name in ipairs(pending) do
        local migration = self.Migrations[name]
        print("[TARDIS] Running migration " .. name .. " (" .. migration.date .. ")")

        local success, err = pcall(migration.func, self)
        if success then
            applied[name] = os.time()
            write_applied(applied)
        else
            -- Deliberately left unrecorded so it retries next load rather than being skipped forever.
            ErrorNoHalt("[TARDIS] Migration " .. name .. " failed: " .. tostring(err) .. "\n")
        end
    end
end

hook.Add("InitPostEntity", "TARDIS_Migrations", function()
    TARDIS:RunMigrations()
end)
