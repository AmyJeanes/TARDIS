-- Third person

TARDIS:AddKeyBind("tp-toggledoor",{
    name="ToggleDoor",
    section="ThirdPerson",
    func=function(self,down,ply)
        if ply==self.pilot and down then
            TARDIS:Control("door", ply)
        end
    end,
    key=KEY_F,
    serveronly=true,
    exterior=true
})

hook.Add("PlayerSwitchFlashlight", "tardis-thirdperson", function(ply,enabled)
    if ply:GetTardisData("thirdperson") then
        return false
    end
end)

local defaultdist=210

function ENT:GetThirdPersonPos(ply, ang)
    local pos=self:LocalToWorld(Vector(0,0,60))
    local tr = util.TraceLine({
        start=pos,
        endpos=pos-(ang:Forward()*ply:GetTardisData("thirdpersondist",defaultdist)),
        mask=MASK_NPCWORLDSTATIC,
        ignoreworld=self:GetData("vortex")
    })
    return tr.HitPos+(ang:Forward()*10), Angle(ang.p,ang.y,0)
end

function ENT:GetThirdPersonTrace(ply,ang)
    local pos,ang=self:GetThirdPersonPos(ply,ang)
    local trace=util.QuickTrace(pos,ang:Forward()*9999999999,{self,TARDIS:GetPart(self,"door")})
    local angle=trace.HitNormal:Angle()
    angle:RotateAroundAxis(angle:Right(),-90)
    return trace.HitPos,angle,trace.Entity
end

if SERVER then
    function ENT:PlayerThirdPerson(ply, enabled, careful)

        if careful and TARDIS:GetSetting("thirdperson_careful_enabled", ply) and not ply:KeyDown(IN_WALK) then
            self:SendMessage("thirdperson-careful-hint", nil, ply)
            return
        end

        if IsValid(ply) and ply:IsPlayer() and self.occupants[ply] then
            if self:SetOutsideView(ply, enabled) then
                ply:SetTardisData("thirdperson", enabled, true)
                self:CallHook("ThirdPerson", ply, enabled)
            end
        end
    end
    ENT:AddHook("Outside", "thirdperson", function(self, ply, enabled)
        if not enabled then
            ply:SetTardisData("thirdperson", enabled, true)
            self:CallHook("ThirdPerson", ply, enabled)
        end
    end)

    ENT:AddHook("ThirdPerson", "client", function(self, ply, enabled)
        self:SendMessage("third_person_hook", {ply, enabled})
    end)
else
    ENT:AddHook("Outside-StartCommand", "thirdperson", function(self, ply, cmd)
        if LocalPlayer():GetTardisData("thirdperson") and cmd:GetMouseWheel()~=0 then
            ply:SetTardisData("thirdpersondist",math.Clamp(ply:GetTardisData("thirdpersondist",defaultdist)-cmd:GetMouseWheel()*0.03*(1.1+ply:GetTardisData("thirdpersondist",defaultdist)),90,500))
        end
    end)
    ENT:AddHook("Outside-PosAng", "thirdperson", function(self, ply, pos, ang)
        if LocalPlayer():GetTardisData("thirdperson") then
            return self:GetThirdPersonPos(ply, ang)
        end
    end)

    ENT:OnMessage("third_person_hook", function(self, data, ply)
        self:CallHook("ThirdPerson", data[1], data[2])
    end)

    ENT:OnMessage("thirdperson-careful-hint", function(self, data, ply)
        local use_binding = input.LookupBinding("+use", true)
        local walk_binding = input.LookupBinding("+walk", true)
        local use = string.upper(use_binding or "USE")
        local walk = string.upper(walk_binding or "WALK")
        TARDIS:Message(LocalPlayer(), "ThirdPerson.KeyHint", walk, use)
    end)
end