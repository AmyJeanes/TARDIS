-- Attached / constrained entities behaviour during teleport

if SERVER then
    ENT:AddHook("DematStart", "attached", function(self)
        if self:GetData("redecorate") then return end
        local constrained = constraint.GetAllConstrainedEntities(self)
        local attached
        if constrained then
            for k,v in pairs(constrained) do
                if not (k.TardisPart or k==self) then
                    local a=k:GetColor().a
                    if not attached then attached = {} end
                    attached[k] = a
                end
            end
        end
        self:SetData("demat-attached",attached,true)
    end)

    ENT:AddHook("StopDemat", "attached", function(self)
        local attached=self:GetData("demat-attached")
        if attached then
            for k,v in pairs(attached) do
                if IsValid(k) and not IsValid(k:GetParent()) then
                    local phys=k:GetPhysicsObject()
                    if phys and IsValid(phys) then
                        k:SetSolid(SOLID_NONE)
                        k.gravity = phys:IsGravityEnabled()
                        phys:EnableGravity(false)
                    end
                end
            end
        end
    end)

    ENT:AddHook("StopMat", "attached", function(self)
        local attached=self:GetData("demat-attached")
        if attached then
            for k,v in pairs(attached) do
                if IsValid(k) then
                    k:SetColor(ColorAlpha(k:GetColor(),v))
                end
            end
        end
        self:SetData("demat-attached",nil,true)
    end)

    ENT:AddHook("PreTeleportPositionChange", "attached_hoverballs", function(self, pos, ang, phys_enable)
        local attached=self:GetData("demat-attached")
        if attached then
            for k,v in pairs(attached) do
                if IsValid(k) and not IsValid(k:GetParent()) then
                    k.telepos=k:GetPos()-self:GetPos()
                    if k:GetClass()=="gmod_hoverball" then -- fixes hoverballs spazzing out
                        k:SetTargetZ( (pos-self:GetPos()).z+k:GetTargetZ() )
                    end
                end
            end
        end
    end)

    ENT:AddHook("TeleportPositionChanged", "attached", function(self, pos, ang, phys_enable)
        local attached=self:GetData("demat-attached")
        if not attached then return end

        for k,v in pairs(attached) do
            if IsValid(k) and not IsValid(k:GetParent()) then
                if k:IsRagdoll() then
                    for i=0,k:GetPhysicsObjectCount() do
                        local bone=k:GetPhysicsObjectNum(i)
                        if IsValid(bone) then
                            bone:SetPos(self:GetPos()+k.telepos)
                        end
                    end
                end
                k:SetPos(self:GetPos()+k.telepos)
                k.telepos=nil

                if phys_enable == true then
                    local phys=k:GetPhysicsObject()
                    if phys and IsValid(phys) then
                        k:SetSolid(SOLID_VPHYSICS)
                        if k.gravity~=nil then
                            phys:EnableGravity(k.gravity)
                            k.gravity = nil
                        end
                    end
                    k.nocollide=nil
                end
            end
        end
    end)
end

function ENT:SetAttachedTransparency(alpha)
    local attached=self:GetData("demat-attached")

    if attached then
        for k,v in pairs(attached) do
            if IsValid(k) and not (v==0) then
                if k:GetRenderMode() ~= RENDERMODE_TRANSALPHA then
                    k:SetRenderMode(RENDERMODE_TRANSALPHA)
                end
                k:SetColor(ColorAlpha(k:GetColor(),alpha))
            end
        end
    end
end