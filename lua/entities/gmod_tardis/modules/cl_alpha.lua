-- Alpha

local use_enhanced_fade_cache = {}

---@api
---@return number
function ENT:GetAlpha()
    local alpha = self:GetData("alpha",255)/255
    if self:GetData("vortexalpha",0)>alpha and TARDIS:GetExteriorEnt()==self and LocalPlayer():GetTardisData("outside") then
        return self:GetData("vortexalpha",0),true
    end
    if self:GetData("vortex") then
        return 0
    elseif self:GetData("teleport") or self:GetData("teleport-interrupt-fade") then
        return alpha
    elseif self:GetData("teleport-trace") or self:GetData("tracking-trace") then
        return 20/255
    end
    return 1
end

local function shouldapply(self,part)
    local target,override = self:GetAlpha()
    if (target ~= 1 or override) and ((not part) or (part and (not part.CustomAlpha))) then
        if use_enhanced_fade_cache[self:EntIndex()] then
            target = (2 * target * target) / (1 + target * target)
        end
        return target
    end
end

local function shouldUseEnhancedFade(self)
    if not TARDIS:GetSetting("enhanced-fading-enabled") then
        return false
    end
    
    if self:GetData("redecorate") or self:GetData("redecorate_parent") then
        return false
    end

    return true
end

local function dopredraw(self,part)
    local target = shouldapply(self,part)
    if target~=nil then
        local useEnhanced = use_enhanced_fade_cache[self:EntIndex()] or false
        
        if useEnhanced then
            render.OverrideColorWriteEnable(true, false)
            self:DrawModel()
            render.OverrideColorWriteEnable(false, false)

            render.OverrideColorWriteEnable(true, false)
            for _,v in pairs(self.parts) do
                if v.ExteriorPart then
                    v:DrawModel()
                end
            end
            render.OverrideColorWriteEnable(false, false)
        end
        
        render.SetBlend(target)
        if self:CallHook("ShouldVortexIgnoreZ") then
            -- cam.IgnoreZ(true)
        end
    end
end

local function dopostdraw(self,part)
    if shouldapply(self,part)~=nil then
        cam.IgnoreZ(false)
    end
end

ENT:AddHook("AlphaTranslucentChanged", "enhanced_fade_cache", function(self,transparent)
    if transparent then
        use_enhanced_fade_cache[self:EntIndex()] = shouldUseEnhancedFade(self)
    end
end)

ENT:AddHook("AlphaTranslucentChanged", "rendergroup", function(self,transparent)
    local rendergroup
    if transparent then
        rendergroup = RENDERGROUP_TRANSLUCENT
        rendermode = RENDERMODE_TRANSALPHA
    else
        rendergroup = RENDERGROUP_OPAQUE
        rendermode = RENDERMODE_NORMAL
    end
    self.RenderGroup = rendergroup
    self:SetRenderMode(rendermode)
    for _,v in pairs(self.parts) do
        if v.ExteriorPart then
            v.RenderGroup = rendergroup
            v:SetRenderMode(rendermode)
        end
    end
end)

ENT:AddHook("Think", "enhanced_fade_cache", function(self)
    local alpha = self:GetAlpha()
    local alpha_translucent = self:GetData("alpha_translucent", false)
    if alpha < 1 then
        if alpha_translucent ~= true then
            self:SetData("alpha_translucent", true)
            self:CallHook("AlphaTranslucentChanged", true)
        end
    elseif alpha_translucent then
        self:SetData("alpha_translucent", false)
        self:CallHook("AlphaTranslucentChanged", false)
    end
end)

ENT:AddHook("OnRemove", "enhanced_fade_cache", function(self)
    use_enhanced_fade_cache[self:EntIndex()] = nil
end)

ENT:AddHook("PreDraw","teleport",dopredraw)
ENT:AddHook("PreDrawPart","teleport",dopredraw)
ENT:AddHook("Draw","teleport",dopostdraw)
ENT:AddHook("PostDrawPart","teleport",dopostdraw)
ENT:AddHook("PreDrawPortal","vortex",dopredraw)
ENT:AddHook("PostDrawPortal","vortex",dopostdraw)
