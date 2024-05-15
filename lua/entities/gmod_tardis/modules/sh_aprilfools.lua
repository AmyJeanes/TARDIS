-- April Fools

if SERVER then
    ENT:AddHook("PreTeleportPositionChange", "april_fools", function(self)
        if not TARDIS:IsAprilFools() then return end

        for ply, v in pairs(self.occupants) do
            if v and IsValid(ply) then
                ply:ScreenFade(SCREENFADE.IN, color_black, 1, 0)
                timer.Simple(1, function()
                    if not IsValid(ply) then return end
                    if not ply.tardis_aprilfools then
                        ply.tardis_aprilfools = true
                        ply:ChatPrint("April fools! :) (tardis2_aprilfools_2023 0 in console to disable)")
                    end
                end)
            end
        end

        self:Remove()
        return false
    end)
else
    ENT:AddHook("DematStart", "april_fools", function(self)
        if not TARDIS:IsAprilFools() then
            return
        end
        if not IsValid(self.interior) then
            return
        end

        for k, v in pairs(self.interior:GetParts()) do
            if IsValid(v) then
                v.RenderGroup = RENDERGROUP_BOTH
            end
        end
        self.interior.tips = {}
    end)
end

ENT:AddHook("Think", "april_fools", function(self,delta)
    if not TARDIS:IsAprilFools() then return end
    if IsValid(self.interior) then
        local alpha = self:GetData("alpha",255)
        self.interior:SetColor(ColorAlpha(self.interior:GetColor(),alpha))
        local parts = self.interior:GetParts()
        if not parts then return end
        for k,v in pairs(parts) do
            if IsValid(v) then
                v:SetColor(ColorAlpha(v:GetColor(),alpha))
            end
        end
    end
end)

local mat = Material("models/drmatt/tardis/exterior/black")
hook.Add("PostDrawOpaqueRenderables", "tardis-aprilfools", function()
    if not TARDIS:IsAprilFools() or wp.drawing then return end
    local ext=TARDIS:GetExteriorEnt()
    if IsValid(ext) and IsValid(ext.interior) and (ext:GetData("teleport",false) or ext:GetData("vortex",false)) and (not ext.interior.scannerrender) and (not LocalPlayer():GetTardisData("outside")) then
        render.SetMaterial(mat)
        local center,radius=ext.interior:GetSphere()
        render.DrawSphere(ext.interior:LocalToWorld(center), -radius * 1.5, 50, 50)
    end
end)
