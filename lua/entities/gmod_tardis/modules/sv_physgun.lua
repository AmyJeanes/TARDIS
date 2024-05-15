hook.Add("OnPhysgunPickup", "tardis-hads", function(ply,ent)
    if ent:GetClass() ~= "gmod_tardis" then return end

    if ent:TriggerHADS() then
        ent:ForcePlayerDrop()
    end
end)

hook.Add("PhysgunPickup", "tardis-teleport", function(ply,ent)
    if ent:GetClass() ~= "gmod_tardis" then return end

    if ent:GetData("teleport") or ent:GetData("vortex") or ent:GetData("hads-triggered") then
        return false
    end
end)

hook.Add("PlayerUnfrozeObject", "tardis-physlock", function(ply,ent,phys)
    if ent:GetClass() ~= "gmod_tardis" then return end

    if ent:GetPhyslock() == true then
        phys:EnableMotion(false)
    end
end)

hook.Add("PhysgunDrop", "tardis-physlock", function(ply,ent)
    if ent:GetClass() ~= "gmod_tardis" then return end

    if ent:GetPhyslock() == true then
        ent:GetPhysicsObject():EnableMotion(false)
    end
end)