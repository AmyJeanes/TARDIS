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

    function meta:SetTardisData(k,v,network)
        if not self.tardis then self.tardis = {} end
        self.tardis[k]=v

        if network then
            net.Start("TARDIS-PlayerData")
                net.WriteType(k)
                net.WriteType(v)
            net.Send(self)
        end
    end

    function meta:GetTardisData(k,default)
        return (self.tardis and self.tardis[k]~=nil) and self.tardis[k] or default
    end

    function meta:ClearTardisData()
        self.tardis=nil
        net.Start("TARDIS-PlayerDataClear")
        net.Send(self)
    end

    hook.Add("DoPlayerDeath", "TARDIS_PlayerDeath", function(ply)
        local ext=ply:GetTardisData("exterior")
        if IsValid(ext) and ply:GetTardisData("intfallback") then
            ext:PlayerExit(ply, true)
        end
    end)
else
    ---@class Player
    local meta=FindMetaTable("Player")

    function meta:SetTardisData(k,v)
        if not self.tardis then self.tardis = {} end
        self.tardis[k]=v
    end

    function meta:GetTardisData(k,default)
        return (self.tardis and self.tardis[k]~=nil) and self.tardis[k] or default
    end

    function meta:ClearTardisData()
        self.tardis=nil
    end

    net.Receive("TARDIS-PlayerData", function()
        local k=net.ReadType()
        local v=net.ReadType()
        LocalPlayer():SetTardisData(k,v)
    end)

    net.Receive("TARDIS-PlayerDataClear", function()
        LocalPlayer():ClearTardisData()
    end)

    ENT:AddHook("PlayerExit", "players", function(self)
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

ENT:AddHook("Initialize", "creatorID", function(self)
    self.CreatorID = self:GetCreator():UserID()
    self.CreatorNick = self:GetCreator():Nick()
    self.CreatorSteamID = self:GetCreator():SteamID64()
end)