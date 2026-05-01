-- Cloak


TARDIS:AddKeyBind("cloak-toggle",{
    name="ToggleCloak",
    section="ThirdPerson",
    func=function(self,down,ply)
        if ply == self.pilot and down then
            TARDIS:Control("cloak", ply)
        end
    end,
    key=KEY_L,
    serveronly=true,
    exterior=true
})

ENT:AddHook("Initialize", "cloak", function(self)
    self:SetData("cloak", false)

    self:SetData("modelmins", self:OBBMins())
    local maxs = self:OBBMaxs()
    maxs.z = maxs.z + 25
    self:SetData("modelmaxs", maxs)
    self:SetData("modelheight", (self:GetData("modelmaxs").z - self:GetData("modelmins").z))

    self:SetData("phase-percent",1)
end)

function ENT:GetCloak()
    return self:GetData("cloak",false)
end

if SERVER then
    function ENT:SetCloak(on)
        if self:CallHook("CanToggleCloak")==false then return false end
        self:SetData("cloak", on)
        self:SendMessage("cloak", { on })

        self:UpdateShadow()
        self:CallHook("CloakToggled", on)
        return true
    end

    function ENT:ToggleCloak()
        local on = not self:GetData("cloak", false)
        return self:SetCloak(on)
    end

    ENT:AddHook("HandleE2", "cloak", function(self, name, e2, ...)
        local args = {...}
        if name == "Phase" and TARDIS:CheckPP(e2.player, self) then
            return (self:GetPower() and self:ToggleCloak()) and 1 or 0
        elseif name == "GetVisible" then
            return self:GetCloak() and 0 or 1
        elseif name == "SetPhase" and TARDIS:CheckPP(e2.player, self) then
            local on = args[1]
            local cloak = self:GetCloak()
            if on == 1 then
                if (not cloak) and self:SetCloak(true) then
                    return 1
                end
            else
                if cloak and self:SetCloak(false) then
                    return 1
                end
            end
            return 0
        end
    end)

    ENT:AddHook("ShouldTurnOffRotorwash", "cloak", function(self)
        if self:GetData("cloak") then
            return true
        end
    end)

    ENT:AddHook("OnHealthDepleted", "cloak", function(self)
        if self:GetCloak() then
            self:SetCloak(false)
        end
    end)

    ENT:AddHook("PowerToggled", "cloak", function(self,on)
        if on and self:GetData("power_last_cloak", false) then
            self:SetCloak(true)
        elseif not on then
            self:SetData("power_last_cloak", self:GetCloak())
            if self:GetCloak() then
                self:SetCloak(false)
            end
        end
    end)

    function ENT:UpdateShadow()
        local should_draw = (self:CallHook("ShouldDrawShadow") ~= false)
        self:DrawShadow(should_draw)

        for _,v in pairs(self.parts) do
            if IsValid(v) then
                v:DrawShadow(not v.NoShadow and should_draw)
            end
        end
    end

    ENT:AddHook("ShouldDrawShadow", "cloak", function(self)
        if self:GetData("cloak") then
            return false
        end
    end)
else
    ENT:AddHook("ShouldThinkFast", "cloak", function(self)
        if self:GetData("cloak-animating",false) then return true end
    end)

    ENT:AddHook("ShouldAllowThickPortal", "cloak", function(self, portal)
        if self.interior and portal==self.interior.portals.exterior then
            if self:GetCloak() or self:GetData("cloak-animating") then
                return false
            end
        end
    end)

    ENT:AddHook("Think", "cloak", function(self)
        local target = self:GetData("cloak",false) and -0.5 or 1
        local animating = self:GetData("cloak-animating",false)
        local percent = self:GetData("phase-percent",1)

        if percent == target then
            if animating then
                self:SetData("cloak-animating", false)
                self:CallHook("CloakAnimationFinished")
                self:SetData("phase-lastTick", nil)
            end
            return
        elseif not animating then
            self:SetData("cloak-animating", true)
            self:CallHook("CloakAnimationStarted")
        end

        local timepassed = CurTime() - self:GetData("phase-lastTick",CurTime())
        self:SetData("phase-lastTick", CurTime())

        local new_percent = math.Approach(percent, target, 0.5 * timepassed)
        local high_percent = math.Clamp(self:GetData("phase-percent",1) + 0.5, 0, 1)
        self:SetData("phase-percent", new_percent)
        self:SetData("phase-highPercent", high_percent)

        local modelmaxs = self:GetData("modelmaxs")
        local modelheight = self:GetData("modelheight")
        local pos = self:GetPos() + self:GetUp() * (modelmaxs.z - (modelheight * high_percent))
        local pos2 = self:GetPos() + self:GetUp() * (modelmaxs.z - (modelheight * new_percent))

        self:SetData("phase-highPos", pos)
        self:SetData("phase-pos", pos2)
    end)

    ENT:AddHook("ShouldDrawPhaseAnimation", "cloak", function(self)
        if self:GetData("cloak-animating",false) then
            return true
        end
    end)

    ENT:AddHook("ShouldTurnOffLight", "cloak", function(self)
        if self:GetData("cloak",false) then return true end
    end)

    ENT:AddHook("ShouldTurnOffFlightSound", "cloak", function(self)
        if self:GetData("cloak",false) then return true end
    end)

    ENT:AddHook("ShouldPlayDematSound", "cloak", function(self,interior)
        if self:GetData("cloak",false) and not interior then return false end
    end)

    ENT:AddHook("ShouldPlayMatSound", "cloak", function(self,interior)
        if self:GetData("cloak",false) and not interior then return false end
    end)

    ENT:AddHook("ShouldDraw", "cloak", function(self)
        if self:GetData("cloak",false) and not self:GetData("cloak-animating",false) then return false end
    end)

    ENT:OnMessage("cloak", function(self, data, ply)
        local on = data[1]
        self:SetData("cloak", on)
        local snd
        if on then
            snd = self.metadata.Exterior.Sounds.Cloak
        else
            snd = self.metadata.Exterior.Sounds.CloakOff
        end

        if TARDIS:GetSetting("cloaksound-enabled") and TARDIS:GetSetting("sound") then
            self:EmitSound(snd)

            if IsValid(self.interior) then
                self.interior:EmitSound(snd)
            end
        end
    end)
end