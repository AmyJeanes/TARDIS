-- Settings

TARDIS.SettingsData = TARDIS.SettingsData or {}

TARDIS.GlobalSettings = TARDIS.GlobalSettings or {}
TARDIS.ClientSettings = TARDIS.ClientSettings or {}

if CLIENT then
    TARDIS.LocalSettings = TARDIS.LocalSettings or {}
    TARDIS.NetworkedSettings = TARDIS.NetworkedSettings or {}
end

--------------------------------------------------------------------------------
-- Setup

function TARDIS:AddSetting(data)
    self.SettingsData[data.id]=data
    if data.class == "global" and data.convar then
        local convar = data.convar
        local convar_default_value = data.value

        CreateConVar(convar.name, tostring(convar_default_value), convar.flags, convar.desc, data.min, data.max)

        cvars.AddChangeCallback(convar.name, function(cvname, oldvalue, newvalue)
            if CLIENT and not LocalPlayer():IsAdmin() then return end
            if data.type == "integer" or data.type == "number" then
                local value = tonumber(newvalue)

                local current_setting = TARDIS:GetSetting(data.id)
                if current_setting == value then return end

                local set_value = TARDIS:SetSetting(data.id, value, true)

                if set_value ~= value then
                    if data.type == "integer" then
                        GetConVar(convar.name):SetInt(set_value)
                    else
                        GetConVar(convar.name):SetFloat(set_value)
                    end
                end
            elseif data.type == "bool" then
                TARDIS:SetSetting(data.id, tobool(newvalue))
            else
                TARDIS:SetSetting(data.id, tostring(newvalue))
            end
        end, "UpdateOnChange")
    end
end

function TARDIS:GetSettingData(id)
    return self.SettingsData[id]
end

function TARDIS:GetSettingsData()
    return self.SettingsData
end

--------------------------------------------------------------------------------
-- Accessing

function TARDIS:SetSetting(id, value, ignore_convar)
    local data = self.SettingsData[id]
    if not data then error("Requested setting " .. id .. " does not exist") end

    if value ~= nil and data.type == "integer" then
        value = math.Round(value)
    end

    if value ~= nil and (data.type == "number" or data.type == "integer") then
        if data.min and data.max then
            value = math.Clamp(value, data.min, data.max)
        end
        if data.round_func then
            value = data.round_func(value)
        end
    end

    if value == nil and data.class == "global" then
        value = data.value
    end

    if SERVER then
        if data.class == "global" then
            self.GlobalSettings[id]=value

            if data.convar and not ignore_convar then
                local convar = GetConVar(data.convar.name)
                if data.type == "integer" then
                    convar:SetInt(value)
                elseif data.type == "number" then
                    convar:SetFloat(value)
                elseif data.type == "bool" then
                    convar:SetBool(value)
                else
                    convar:SetString(tostring(value))
                end
            end
        else
            error("Setting " .. id .. " is being set serverside, but is not global")
        end
    else
        if data.class == "networked" then
            self.NetworkedSettings[id]=value
        elseif data.class == "local" then
            self.LocalSettings[id]=value
        elseif data.class == "global" then
            TARDIS:GlobalSettingChange(id, value)
        else
            error("Setting " .. id .. " is being set clientside, but has unsupported class")
        end
    end

    self:SaveSettings()

    if (SERVER and data.class == "global") or (CLIENT and data.class == "networked") then
        self:SendSetting(id, value)
    end

    self:OnSettingChanged(id, value)

    return value
end

function TARDIS:GetSetting(id, src, no_default)
    local ply
    if IsValid(src) and not src:IsPlayer() and not src.TardisExterior then
        src = src.exterior
    end
    if IsValid(src) and IsEntity(src) then
        ply = (src:IsPlayer() and src) or src:GetCreator()
    end

    if not id then error("Requested setting with no id") end
    local data = self.SettingsData[id]
    if not data then error("Requested setting " .. id .. " does not exist") end

    local function select_return_val(table_value)
        if table_value ~= nil then
            return table_value
        end
        if no_default then
            return nil
        end
        return data.value
    end

    if data.class == "global" then
        return select_return_val(self.GlobalSettings[id])
    end

    if data.class == "local" then
        if SERVER then
            error("Local setting " .. id .. " is being requested serverside")
        end
        return select_return_val(self.LocalSettings[id])
    end

    if data.class == "networked" then

        if CLIENT and (ply == nil or ply == LocalPlayer()) then
            return select_return_val(self.NetworkedSettings[id])
        end

        local user_id = (IsValid(ply) and ply:UserID()) or src.CreatorID

        if not user_id then
            print("[TARDIS] WARNING: Networked setting " .. id .. " was requested for invalid source " .. tostring(src))
        end

        if not user_id or not self.ClientSettings[user_id] then
            return select_return_val(nil)
        end

        return select_return_val(self.ClientSettings[user_id][id])
    end

    error("Requested setting " .. id .. " either doesn't exist or has no defined class")
    return
end

--------------------------------------------------------------------------------
-- Saving

local LOCAL_SETTINGS_FILE = "tardis_settings_cl.txt"
local NETWORKED_SETTINGS_FILE = "tardis_settings_cl_nw.txt"
local GLOBAL_SETTINGS_FILE = "tardis_settings_sv.txt"

--[[ TODO: Add back in before release
TARDIS:AddMigration("settings-move", "2023.8.0", function(self)
    if SERVER then
        if file.Exists("tardis_settings_sv.txt", "DATA") then
            if file.Exists(GLOBAL_SETTINGS_FILE, "DATA") then
                file.Delete(GLOBAL_SETTINGS_FILE)
            end
            file.Rename("tardis_settings_sv.txt", GLOBAL_SETTINGS_FILE)
        end
    else
        if file.Exists("tardis_settings_cl.txt", "DATA") then
            if file.Exists(LOCAL_SETTINGS_FILE, "DATA") then
                file.Delete(LOCAL_SETTINGS_FILE)
            end
            file.Rename("tardis_settings_cl.txt", LOCAL_SETTINGS_FILE)
        end
        if file.Exists("tardis_settings_cl_nw.txt", "DATA") then
            if file.Exists(NETWORKED_SETTINGS_FILE, "DATA") then
                file.Delete(NETWORKED_SETTINGS_FILE)
            end
            file.Rename("tardis_settings_cl_nw.txt", NETWORKED_SETTINGS_FILE)
        end
    end

    self:LoadSettings()
end)
]]

function TARDIS:SaveSettings()

    local function SaveSettingsToFile(settings_table, settings_file)
        local settings={}
        for k,v in pairs(settings_table) do
            local data = self.SettingsData[k]
            if data and data.value ~= v then
                settings[k] = v
            end
        end
        file.Write(settings_file, self.von.serialize(settings))
    end

    if SERVER then
        SaveSettingsToFile(self.GlobalSettings, GLOBAL_SETTINGS_FILE)
    else
        SaveSettingsToFile(self.LocalSettings, LOCAL_SETTINGS_FILE)
        SaveSettingsToFile(self.NetworkedSettings, NETWORKED_SETTINGS_FILE)
    end
end

function TARDIS:LoadSettings()

    local function LoadSettingsFromFile(settings_table, settings_file)
        if file.Exists(settings_file, "DATA") then
            local file_contents = file.Read(settings_file, "DATA")
            local loaded_settings = self.von.deserialize(file_contents)

            table.Merge(settings_table, loaded_settings)
        end
    end

    if SERVER then
        LoadSettingsFromFile(self.GlobalSettings, GLOBAL_SETTINGS_FILE)
    else
        LoadSettingsFromFile(self.LocalSettings, LOCAL_SETTINGS_FILE)
        LoadSettingsFromFile(self.NetworkedSettings, NETWORKED_SETTINGS_FILE)
    end

    self:SaveSettings()
    self:SendSettings()
end

function TARDIS:ResetSettings()
    if SERVER then
        self.GlobalSettings={}
    else
        self.LocalSettings={}
        self.NetworkedSettings={}
    end
    self:SaveSettings()
    self:SendSettings()
end

function TARDIS:ResetSectionSettings(section)
    for k,v in pairs(self.SettingsData) do
        if (section ~= nil and v.section == section) or (section == nil and v.option ~= nil) then
            if SERVER then
                self.GlobalSettings[k] = nil
            elseif v.class == "global" then
                TARDIS:GlobalSettingChange(k, nil)
            else
                self.NetworkedSettings[k] = nil
                self.LocalSettings[k] = nil
            end
        end
    end
    self:SaveSettings()
    self:SendSettings()
end

--------------------------------------------------------------------------------
-- Networking

if SERVER then
    util.AddNetworkString("TARDIS-Settings")
    util.AddNetworkString("TARDIS-RequestSettings")
    util.AddNetworkString("TARDIS-ClientSettings")
    util.AddNetworkString("TARDIS-GlobalSettingChange")

    net.Receive("TARDIS-ClientSettings",function(len,ply)
        local userID = ply:UserID()
        if not TARDIS.ClientSettings[userID] then TARDIS.ClientSettings[userID]={} end
        local mode=net.ReadBool()
        if mode then
            local key=net.ReadString()
            local value=net.ReadType()
            TARDIS.ClientSettings[userID][key]=value
            net.Start("TARDIS-ClientSettings")
                net.WriteInt(userID,8)
                net.WriteBool(mode)
                net.WriteType(key)
                net.WriteType(value)
            net.Broadcast()
        else
            local str=net.ReadString()
            TARDIS.ClientSettings[userID]=TARDIS.von.deserialize(str)
            net.Start("TARDIS-ClientSettings")
                net.WriteInt(userID,8)
                net.WriteBool(mode)
                net.WriteString(str)
            net.Broadcast()
        end
    end)

    function TARDIS:RequestSettings(ply)
        net.Start("TARDIS-RequestSettings")
        if IsValid(ply) then
            net.Send(ply)
        else
            net.Broadcast()
        end
    end

    function TARDIS:SendPlayerSettings(ply)
        for k,v in pairs(self.ClientSettings) do
            net.Start("TARDIS-ClientSettings")
                net.WriteInt(k,8)
                net.WriteBool(false)
                net.WriteString(self.von.serialize(v))
            if IsValid(ply) then
                net.Send(ply)
            else
                net.Broadcast()
            end
        end
    end

    hook.Add("PlayerInitialSpawn", "TARDIS-Settings", function(ply)
        TARDIS:SendSettings(ply)
        TARDIS:SendPlayerSettings(ply)
        TARDIS:RequestSettings(ply)
    end)

    net.Receive("TARDIS-GlobalSettingChange", function(len,ply)
        if not ply:IsAdmin() then return end
        local id = net.ReadString()
        local val = net.ReadType()
        TARDIS:SetSetting(id, val)
    end)
else
    function TARDIS:GlobalSettingChange(id, value)
        local ply = LocalPlayer()
        if not ply:IsAdmin() then
            TARDIS:ErrorMessage(ply, "Settings.NoPermissionGlobalSettings")
            return
        end
        net.Start("TARDIS-GlobalSettingChange")
            net.WriteString(id)
            net.WriteType(value)
        net.SendToServer()
    end

    net.Receive("TARDIS-RequestSettings",function(len)
        TARDIS:SendSettings()
    end)

    net.Receive("TARDIS-ClientSettings",function(len)
        local ply=net.ReadInt(8)
        if not TARDIS.ClientSettings[ply] then TARDIS.ClientSettings[ply]={} end
        local mode=net.ReadBool()
        if mode then
            local id = net.ReadString()
            local value = net.ReadType()
            TARDIS.ClientSettings[ply][id]=value
            TARDIS:OnSettingChanged(id, value, ply)
        else
            TARDIS.ClientSettings[ply]=TARDIS.von.deserialize(net.ReadString())
        end
    end)

    net.Receive("TARDIS-Settings",function(len)
        local mode=net.ReadBool()
        if mode then
            local id = net.ReadString()
            local value = net.ReadType()
            TARDIS.GlobalSettings[id]=value
            TARDIS:OnSettingChanged(id, value)
        else
            table.Merge(TARDIS.GlobalSettings,TARDIS.von.deserialize(net.ReadString()))
        end
    end)
end

function TARDIS:SendSetting(id,value,ply)
    net.Start(SERVER and "TARDIS-Settings" or "TARDIS-ClientSettings")
        net.WriteBool(true)
        net.WriteString(id)
        net.WriteType(value)
    if SERVER then
        if IsValid(ply) then
            net.Send(ply)
        else
            net.Broadcast()
        end
    else
        net.SendToServer()
    end
end

function TARDIS:SendSettings(ply)
    net.Start(SERVER and "TARDIS-Settings" or "TARDIS-ClientSettings")
        net.WriteBool(false)
        net.WriteString(self.von.serialize(SERVER and self.GlobalSettings or self.NetworkedSettings))
    if SERVER then
        if IsValid(ply) then
            net.Send(ply)
        else
            net.Broadcast()
        end
    else
        net.SendToServer()
    end
end

function TARDIS:OnSettingChanged(id,value,ply)
    hook.Call("TARDIS_SettingChanged", GAMEMODE, id, value, ply)
    for k,v in pairs(ents.FindByClass("gmod_tardis")) do
        if v.CallCommonHook then
            v:CallCommonHook("SettingChanged", id, value)
        end
    end
end

TARDIS:LoadFolder("settings")
TARDIS:LoadSettings()
