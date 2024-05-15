-- Support for time distortion generator by parar020100 and JEREDEK

local search_radius = 2048
local explode_radius = 300

local function TimeDistortionsPresent(pos, outside, int_radius)
    for i,v in ipairs(ents.FindInSphere(pos, search_radius)) do
        if v:GetClass() == "gmod_time_distortion_generator" and v:GetEnabled() then
            if outside then
                if v:GetPos():Distance(pos) <= v:GetRadius() then
                    return true
                end
            elseif v:GetPos():Distance(pos) <= int_radius then
                return true
            end
        end
    end
    return false
end

local function DistortionsInside(ent)
    if not IsValid(ent) or not IsValid(ent.interior) then return end
    local size = ent.interior.metadata.Interior.Size
    if size.Min and size.Max then
        local min = ent.interior:LocalToWorld(size.Min)
        local max = ent.interior:LocalToWorld(size.Max)
        for i,v in ipairs(ents.FindInBox(min, max)) do
            if v:GetClass() == "gmod_time_distortion_generator" and v:GetEnabled() then
                return true
            end
        end
        return false
    end
    local center,radius = ent.interior:GetSphere()
    return TimeDistortionsPresent(ent.interior:LocalToWorld(center), false, radius)
end

local function DistortionsOutside(ent)
    return TimeDistortionsPresent(ent:GetPos(), true)
end

if SERVER then
    ENT:AddHook("PlayerEnter", "time_distortions_inside", function(self, ply, notp)
        if DistortionsInside(self) then
            self:Timer("time_dist_inside_warning", 0, function() -- fix for the hook working when player exits
                if ply:GetTardisData("interior") == self.interior then
                    TARDIS:ErrorMessage(ply, "TimeDistortionGenerator.Distortions")
                end
            end)
        end
    end)

    ENT:AddHook("ForceDematStart", "time_distortion_generators_outside", function(self)
        for i,v in ipairs(ents.FindInSphere(self:GetPos(), explode_radius)) do
            if v:GetClass() == "gmod_time_distortion_generator" and v:GetEnabled() then
                v:Break()
            end
        end
    end)

    ENT:AddHook("ShouldFailDemat", "time_distortions", function(self, force)
        if DistortionsOutside(self) and (DistortionsInside(self) or not force) then
            return true
        end
    end)

    ENT:AddHook("CanDemat", "time_distortions_only_inside", function(self, force)
        if not force and not self:GetData("redecorate") and DistortionsInside(self) and not DistortionsOutside(self) then
            return false
        end
    end)

    ENT:AddHook("ShouldForceDemat", "time_distortions", function(self, pos, ang)
        if DistortionsInside(self) and not DistortionsOutside(self) then
            return true
        end
    end)

    ENT:AddHook("ShouldFailMat", "time_distortions_destination", function(self, dest_pos, dest_ang)
        if dest_pos ~= nil and dest_pos ~= self:GetPos() and TimeDistortionsPresent(dest_pos, search_radius)
        then
            return true
        end
    end)

    ENT:AddHook("StopDemat", "time_distortions_inside", function(self, force)
        if DistortionsInside(self) then
            self:SetRandomDestination(self:GetData("flight", false))
        end
    end)

else

    ENT:AddHook("RandomizeTips", "time_distortions_inside", function(self)
        if DistortionsInside(self) then
            return true
        end
    end)
end
