-- Parts

ENT:AddHook("Initialize","parts",function(self)
    if SERVER then
        TARDIS:SetupParts(self)
    elseif self.partqueue then
        for k,v in pairs(self.partqueue) do
            TARDIS:SetupPart(k,v,self.exterior,self,self)
        end
    end
end)

ENT:AddHook("Cordon","parts",function(self,class,ent)
    if ent.TardisPart and not ent.AllowThroughPortals then return false end
end)

function ENT:GetPart(id)
    return self.parts and self.parts[id] or NULL
end

function ENT:GetParts()
    return self.parts
end

if SERVER then
    function ENT:SetPartInvisible(id, invisible, nofade)
        local invisible_parts = self:GetData("invisible_int_parts", {})
        invisible_parts[id] = {
            invisible = invisible or false,
            nofade = nofade or false
        }
        self:SetData("invisible_int_parts", invisible_parts, true)
        local part = self:GetPart(id)
        if IsValid(part) then
            if part.Motion then
                local phys = part:GetPhysicsObject()
                if IsValid(phys) then
                    if invisible then
                        phys:EnableMotion(false)
                    elseif not part.StartFrozen then
                        phys:EnableMotion(true)
                        phys:Wake()
                    end
                end
            end

            if part.InvisibleCollision == false then
                if invisible then
                    part:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
                elseif part.Collision then
                    part:SetCollisionGroup(COLLISION_GROUP_NONE)
                elseif part.CollisionUse then
                    part:SetCollisionGroup(COLLISION_GROUP_WORLD)
                end
            end
        end
    end

    function ENT:ResetPartPositions()
        for _,part in pairs(self:GetParts()) do
            if IsValid(part) and part.Motion and part.init_pos and part.init_ang then
                local phys = part:GetPhysicsObject()
                part:SetPos(part.init_pos)
                part:SetAngles(part.init_ang)
                if part.StartFrozen and IsValid(phys) then
                    phys:EnableMotion(false)
                    part.unfrozen=nil
                    part.unfreezehint=nil
                end
            end
        end
    end

    function ENT:RemoveAllPartDecals()
        for _,part in pairs(self:GetParts()) do
            if IsValid(part) then
                part:RemoveAllDecals()
            end
        end
    end
else
    -- Special rendering for transparent parts

    ENT:AddHook("PostDrawTranslucentRenderables","parts",function(self)
        if self.parts then
            for _,part in pairs(self.parts) do
                if IsValid(part) and part.UseTransparencyFix then
                    TARDIS.DrawOverride(part,true)
                end
            end
        end
    end)

    ENT:OnMessage("part_use", function(self,data,ply)
        local part = data[1]

        if IsValid(part) and part.Use then
            part:Use(unpack(data, 2))
        end
    end)
end
