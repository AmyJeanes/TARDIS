-- Parts

ENT:AddHook("Initialize","parts",function(self)
    if SERVER then
        TARDIS:SetupParts(self)
    elseif self.partqueue then
        for k,v in pairs(self.partqueue) do
            TARDIS:SetupPart(k,v,self,self.interior,self)
        end
    end
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
else
    ENT:OnMessage("part_use", function(self,data,ply)
        local part = data[1]

        if IsValid(part) and part.Use then
            part:Use(unpack(data, 2))
        end
    end)
end