if SERVER then
    local convar = CreateConVar("tardis2_enteronmat", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "TARDIS - Move players inside when materialized on top of", 0, 1)

    ENT:AddHook("StopMat", "player-enterontp", function(self)
        if not IsValid(self.interior) then return end
        if not convar:GetBool() then return end
        local classes = {
            ["prop_physics"] = true,
        }
        local min, max = self:GetCollisionBounds()
        local width, height, thickness = max.x - min.x, max.y - min.y, max.z - min.z
        min = self:LocalToWorld(min)
        max = self:LocalToWorld(max)
        local pos = self.interior:LocalToWorld(self.interior.Fallback.pos)
        local entities = ents.FindInBox(min, max)
        if #entities ~= 0 then
            for k,v in pairs(entities) do
                if v:IsPlayer() and v:GetTardisData("exterior")~=self then
                    self:PlayerEnter(v)
                    v:ScreenFade(SCREENFADE.IN, Color(255,255,255,200), 1, 0.1)
                elseif v:IsNPC() or v:IsNextBot() then
                    local npos = self:WorldToLocal(v:GetPos())
                    v:SetPos(pos + npos)
                elseif classes[v:GetClass()] and not constraint.HasConstraints(v) then
                    local entmin, entmax = v:GetCollisionBounds()
                    local entwidth, entheight, entthickness = entmax.x - entmin.x, entmax.y - entmin.y, entmax.z - entmin.z
                    if entwidth <= width and entheight <= height and entthickness <= thickness then
                        local npos = self:WorldToLocal(v:GetPos())
                        v:SetPos(pos + npos)
                    end
                end
            end
        end
    end)

    ENT:AddHook("Think", "player-enterontp", function(self)
        if not convar:GetBool() then return end
        if not self:GetData("mat") then return end

        local min, max = self:GetCollisionBounds()
        min = self:LocalToWorld(min)
        max = self:LocalToWorld(max)
        local entities = ents.FindInBox(min, max)

        if #entities ~= 0 then
            for k,v in pairs(entities) do
                if v:IsPlayer() and v:GetTardisData("exterior")~=self then
                    v:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, math.max(self:GetData("alpha", 255) - 30, 0)), 0.1, 0.1)
                end
            end
        end
    end)
end
