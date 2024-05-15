-- Wiremod-related teleport functions

ENT:AddWireInput("Demat", "Wiremod.Inputs.Demat")
ENT:AddWireInput("Mat", "Wiremod.Inputs.Mat")
ENT:AddWireInput("Pos", "Wiremod.Inputs.Pos", "VECTOR")
ENT:AddWireInput("Ang", "Wiremod.Inputs.Ang", "ANGLE")

ENT:AddHook("OnWireInput","teleport",function (self, name, value)
    if name == "Demat" and value >= 1 then
        self:Demat()
    elseif name == "Mat" and value >= 1 then
        self:Mat()
    elseif name == "Pos" then
        if not isvector(value) then return end
        self:SetDestinationPos(value)
    elseif name == "Ang" then
        if not isangle(value) then return end
        self:SetDestinationAng(value)
    end
end)

ENT:AddHook("HandleE2", "teleport_args", function(self, name, e2, pos, ang)
    if name == "Demat" and TARDIS:CheckPP(e2.player, self) then
        local success = self:CallHook("CanDemat")~=false
        if not success then return 0 end
        if not pos or not ang then
            self:Demat()
        else
            self:Demat(Vector(pos[1], pos[2], pos[3]), Angle(ang[1], ang[2], ang[3]))
        end
        return 1
    elseif name == "SetDestination" and TARDIS:CheckPP(e2.player, self) then
        local pos2 = Vector(pos[1], pos[2], pos[3])
        local ang2 = Angle(ang[1], ang[2], ang[3])
        return self:SetDestination(pos2,ang2) and 1 or 0
    end
end)

ENT:AddHook("HandleE2", "teleport", function(self, name, e2, ...)
    if TARDIS:CheckPP(e2.player, self) then
        local args = {...}
        if name == "Mat" then
            local success = self:GetData("vortex",false) and (self:CallHook("CanMat")~=false)
            if not success then return 0 end
            self:Mat()
            return 1
        elseif name == "Longflight" then
            return self:ToggleFastRemat() and 1 or 0
        elseif name == "FastReturn" then
            local success = self:CallHook("CanDemat")~=false
            if not success then return 0 end
            self:FastReturn()
            return 1
        elseif name == "FastDemat" then
            local success = self:CallHook("CanDemat")~=false
            if not success then return 0 end
            self:FastDemat()
            return 1
        elseif name == "SetLongflight" then
            local on = args[1]
            local fastremat = self:GetFastRemat()
            if on == 1 then
                if fastremat and self:SetFastRemat(false) then
                    return 1
                end
            else
                if (not fastremat) and self:SetFastRemat(true) then
                    return 1
                end
            end
            return 0
        end
    end
end)

ENT:AddHook("HandleE2", "teleport_gets", function(self, name, e2)
    if name == "GetMoving" then
        return self:GetData("teleport",false) and 1 or 0
    elseif name == "GetInVortex" then
        return self:GetData("vortex",false) and 1 or 0
    elseif name == "GetLongflight" then
        return self:GetFastRemat() and 0 or 1
    elseif name == "LastAng" then
        return self:GetData("fastreturn-ang", Angle(0,0,0))
    elseif name == "LastPos" then
        return self:GetData("fastreturn-pos", Vector(0,0,0))
    end
end)

