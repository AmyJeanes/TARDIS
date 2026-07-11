-- Handles players

if SERVER then
    util.AddNetworkString("TARDIS-PlayerData")
    util.AddNetworkString("TARDIS-PlayerDataClear")

    ENT:AddHook("PlayerEnter", "players", function(self,ply,notp)
        ply:SetTardisData("exterior", self, true)
        ply:SetTardisData("interior", self.interior, true)
        if not IsValid(self.interior) then
            ply:SetTardisData("intfallback", true)
            self:PlayerThirdPerson(ply,true)
        end
    end)

    ENT:AddHook("Outside", "players", function(self,ply,enabled)
        if (not enabled) and (ply:GetTardisData("intfallback")) then
            self:PlayerExit(ply, true)
        end
    end)

    ENT:AddHook("PlayerExit", "players", function(self,ply,forced,notp)
        ply:ClearTardisData()
    end)

    ---@class Player
    local meta=FindMetaTable("Player")

    ---@param key string
    ---@param value any
    ---@param network boolean?
    function meta:SetTardisData(key,value,network)
        if not self.tardis then self.tardis = {} end
        self.tardis[key]=value

        if network then
            net.Start("TARDIS-PlayerData")
                net.WriteType(key)
                net.WriteType(value)
            net.Send(self)
        end
    end

    ---@generic T
    ---@param key string
    ---@param default? T
    ---@return T
    function meta:GetTardisData(key,default)
        return (self.tardis and self.tardis[key]~=nil) and self.tardis[key] or default
    end

    function meta:ClearTardisData()
        self.tardis=nil
        net.Start("TARDIS-PlayerDataClear")
        net.Send(self)
    end

    hook.Add("DoPlayerDeath", "TARDIS_PlayerDeath", function(ply)
        local ext=ply:GetTardisExterior()
        if IsValid(ext) and ply:GetTardisData("intfallback") then
            ext:PlayerExit(ply, true)
        end
    end)
else
    ---@class Player
    local meta=FindMetaTable("Player")

    ---@param key string
    ---@param value any
    function meta:SetTardisData(key,value)
        if not self.tardis then self.tardis = {} end
        self.tardis[key]=value
    end

    ---@generic T
    ---@param key string
    ---@param default? T
    ---@return T
    function meta:GetTardisData(key,default)
        return (self.tardis and self.tardis[key]~=nil) and self.tardis[key] or default
    end

    function meta:ClearTardisData()
        self.tardis=nil
    end

    net.Receive("TARDIS-PlayerData", function()
        local key=net.ReadType()
        local value=net.ReadType()
        LocalPlayer():SetTardisData(key,value)
    end)

    net.Receive("TARDIS-PlayerDataClear", function()
        LocalPlayer():ClearTardisData()
    end)

    ENT:AddHook("PlayerExit", "players", function(self, ply)
        if ply ~= LocalPlayer() then return end
        TARDIS:RemoveHUDScreen() -- force close hud screen if exit tardis
    end)

    -- Predicted entry: set the TARDIS tardis-data client-side too. The interior's
    -- ShouldDraw keys off GetTardisData("interior"), not ply.doori, so the Doors
    -- predict isn't enough; without it the interior stays hidden until the server's
    -- TARDIS-PlayerData broadcast re-sets it.
    ENT:AddHook("PostTeleportPortal", "predict-tardisdata", function(self, portal, ent)
        if ent ~= LocalPlayer() then return end
        ent:SetTardisData("exterior", self)
        ent:SetTardisData("interior", self.interior)
    end)
end

---@class Player
---@field tardis table<string, any>? internal per-player data store backing Get/SetTardisData
local meta = FindMetaTable("Player")

---@return gmod_tardis_interior?
function meta:GetTardisInterior()
    local int = self.doori
    if not IsValid(int) then return end
    ---@cast int gmod_tardis_interior
    if not int.TardisInterior then return end
    return int
end

---@return gmod_tardis?
function meta:GetTardisExterior()
    local ext = self.door
    if not IsValid(ext) then return end
    ---@cast ext gmod_tardis
    if not ext.TardisExterior then return end
    return ext
end

ENT:AddHook("Initialize", "creatorID", function(self)
    self.CreatorID = self:GetCreator():UserID()
    self.CreatorNick = self:GetCreator():Nick()
    self.CreatorSteamID = self:GetCreator():SteamID64()
end)