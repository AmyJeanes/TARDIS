-- Security System (Isomorphic)

---@api
function ENT:GetSecurity()
    return self:GetData("security", false)
end

---@api
---@param ply Player
---@return boolean
function ENT:CheckSecurity(ply)
    return (not self:GetSecurity()) or (ply==self:GetCreator()) or (TARDIS:GetSetting("admin_security_bypass") and ply:IsAdmin())
end

if SERVER then
    ---@api
    ---@param on boolean
    function ENT:SetSecurity(on)
        self:CallHook("SecurityToggled", on)
        self:SetData("security", on, true)
        return true
    end

    ---@api
    function ENT:ToggleSecurity()
        self:SetSecurity(not self:GetSecurity())
        return true
    end
end

-- Hooks

ENT:AddHook("Initialize","security", function(self)
    if not self:GetData("security") then
        self:SetData("security", TARDIS:GetSetting("security", self), true)
    end
end)

ENT:AddHook("CanUsePart","security",function(self,part,ply)
    if (not part.BypassIsomorphic) and (not self:CheckSecurity(ply)) then
        TARDIS:Message(ply, "Security.ControlUseDenied")
        return false,false
    end
end)

ENT:AddHook("CanUseTardisControl", "security", function(self, control, ply)
    if (not control.bypass_isomorphic) and (not self:CheckSecurity(ply)) then
        TARDIS:Message(ply, "Security.ControlUseDenied")
        return false
    end
end)

ENT:AddHook("CanChangePilot", "flight", function(self, ply)
    if not self:CheckSecurity(ply) then
        return false
    end
end)

ENT:AddHook("HandleE2", "security", function(self, name, e2, ...)
    local args = {...}
    if name == "Isomorph" and TARDIS:CheckPP(e2.player, self) then
        return self:ToggleSecurity() and 1 or 0
    elseif name == "GetIsomorphic" then
        return self:GetSecurity() and 1 or 0
    elseif name == "SetIsomorph" and TARDIS:CheckPP(e2.player, self) then
        local on = args[1]
        local security = self:GetSecurity()
        if on == 1 then
            if (not security) and self:SetSecurity(true) then
                return 1
            end
        else
            if security and self:SetSecurity(false) then
                return 1
            end
        end
        return 0
    end
end)
