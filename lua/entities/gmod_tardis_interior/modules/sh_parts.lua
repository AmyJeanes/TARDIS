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
    if ent.TardisPart then return false end
end)

function ENT:GetPart(id)
    return self.parts and self.parts[id] or NULL
end

function ENT:GetParts()
    return self.parts
end

function ENT:SetPartInvisible(id, invisible)
    local invisible_parts = self:GetData("invisible_int_parts", {})
    invisible_parts[id] = invisible or false
    self:SetData("invisible_int_parts", invisible_parts, true)
end

if CLIENT then
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
