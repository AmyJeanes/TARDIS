-- Alpha

function ENT:GetAlpha()
    local alpha = self:GetData("alpha",255)/255
    if self:GetData("vortexalpha",0)>alpha and TARDIS:GetExteriorEnt()==self then
        return self:GetData("vortexalpha",0),true
    end
    if self:GetData("vortex") then
        return 0
    elseif self:GetData("teleport") then
        return alpha
    elseif self:GetData("teleport-trace") or self:GetData("tracking-trace") then
        return 20/255
    end
    return 1
end

local function shouldapply(self,part)
    local target,override = self:GetAlpha()
    if (target ~= 1 or override) and ((not part) or (part and (not part.CustomAlpha))) then
        return target
    end
end

local function dopredraw(self,part)
    local target = shouldapply(self,part)
    if target~=nil then
        render.SetBlend(target)
        if self:CallHook("ShouldVortexIgnoreZ") then
            cam.IgnoreZ(true)
        end
    end
end

local function dopostdraw(self,part)
    if shouldapply(self,part)~=nil then
        render.SetBlend(1)
        cam.IgnoreZ(false)
    end
end

ENT:AddHook("PreDraw","teleport",dopredraw)
ENT:AddHook("PreDrawPart","teleport",dopredraw)
ENT:AddHook("Draw","teleport",dopostdraw)
ENT:AddHook("PostDrawPart","teleport",dopostdraw)
ENT:AddHook("PreDrawPortal","vortex",dopredraw)
ENT:AddHook("PostDrawPortal","vortex",dopostdraw)
