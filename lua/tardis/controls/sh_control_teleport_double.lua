TARDIS:AddControl({
    id = "teleport_double",
    ext_func=function(self,ply,part)
        if not IsValid(part) then
            return TARDIS:Control("teleport", ply, nil)
        end

        local on = part:GetOn()
        local tp = self:GetData("teleport")
        local vx = self:GetData("vortex")

        if (tp and on) or (vx and on) or (not on and not tp and not vx) then
            TARDIS:Control("teleport", ply, part)
        end
    end,
    serveronly=true,
    power_independent = false,
    screen_button = false,
    tip_text = "Controls.Teleport.Tip",
})
