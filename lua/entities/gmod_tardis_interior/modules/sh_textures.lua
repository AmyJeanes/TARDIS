function ENT:ApplyTextureSet(set_id)
    if not self.metadata or not self.metadata.Interior.TextureSets then return end

    local texture_set = self.metadata.Interior.TextureSets[set_id]
    if not texture_set then return end

    local prefix = texture_set.prefix or ""

    for _,v in ipairs(texture_set) do
        self:ChangeTexture(v[1], v[2], v[3], prefix)
    end

end

--[[
    Usage examples:
        self:ChangeTexture(id, <submaterial_no>, <material>)
        self:ChangeTexture(id, <material>)
        self:ChangeTexture(id, <skin_no>)
]]
function ENT:ChangeTexture(part_id, a, b, prefix)
    local ent = (part_id == "self") and self or self:GetPart(part_id)
    if not IsValid(ent) then return end

    if not prefix then prefix = "" end

    if isnumber(a) and b ~= nil then
        ent:SetSubMaterial(a, prefix .. b)
    elseif isstring(a) then
        ent:SetMaterial(prefix .. a)
    elseif isnumber(a) then
        ent:SetSkin(a)
    else
        ErrorNoHaltWithStack("Wrong texture parameter format: " .. a)
    end
end

if SERVER then
    ENT:AddHook("Initialize", "debug_textures", function(self)
        if not TARDIS.debug_textures then return end
        print("Interior textures:")
        print()
        for k,v in pairs(self:GetMaterials()) do
            print("{\"self" .. "\", " .. k - 1 .. ", \"" .. v .. "\"},")
        end
        print()
    end)

    ENT:AddHook("PostInitialize", "debug_textures_parts", function(self)
        if not TARDIS.debug_textures then return end
        local parts = self:GetParts()
        if not parts then return end

        print("Interior part textures:")
        print()
        for _,v in pairs(parts) do
            for k1,v1 in pairs(v:GetMaterials()) do
                print("{\"" .. v.ID .. "\", " .. k1 - 1 .. ", \"" .. v1 .. "\"},")
            end
        end
        print()
    end)
end
