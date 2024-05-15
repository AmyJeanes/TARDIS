-- View

if SERVER then
    function ENT:SetOutsideView(ply, enabled)
        if IsValid(ply) and ply:IsPlayer() and self.occupants[ply] and CurTime()>ply:GetTardisData("outsidecool", 0) then
            if enabled then
                if IsValid(ply:GetActiveWeapon()) and (ply:GetActiveWeapon():GetClass()~="tardis_hands") then
                    ply:SetTardisData("activewep", ply:GetActiveWeapon():GetClass())
                end
                ply:Give("tardis_hands")
                ply:SetActiveWeapon(ply:GetWeapon("tardis_hands"))
                ply:SetTardisData("outside",true,true)
                ply:SetTardisData("outsideang",ply:EyeAngles(),true)
                ply:SetTardisData("outsidecool", CurTime()+0.5)
                ply:SetEyeAngles(self:LocalToWorldAngles(Angle(10,180,0)))
                self:CallHook("Outside", ply, enabled)
            else
                if ply:GetTardisData("activewep") then
                    ply:SetActiveWeapon(ply:GetWeapon(ply:GetTardisData("activewep")))
                end
                ply:SetTardisData("activewep")
                ply:StripWeapon("tardis_hands")
                ply:SetTardisData("outside",false,true)
                ply:SetEyeAngles(ply:GetTardisData("outsideang"))
                ply:SetTardisData("outsideang")
                ply:SetTardisData("outsidecool", CurTime()+0.5)
                self:CallHook("Outside", ply, enabled)
                self:SendMessage("Outside", {ply, enabled})
            end
            return true
        end
        return false
    end

    ENT:AddHook("PlayerExit", "outside", function(self,ply)
        if ply:GetTardisData("outside") then
            self:SetOutsideView(ply,false)
        end
    end)

    hook.Add("SetupPlayerVisibility", "tardis-outside", function(ply)
        if ply:GetTardisData("outside") and IsValid(ply:GetTardisData("exterior")) then
            AddOriginToPVS(ply:GetTardisData("exterior"):GetPos())
        end
    end)

    hook.Add("StartCommand", "tardis-outside", function(ply, cmd)
        if ply:GetTardisData("outside") then
            local ext=ply:GetTardisData("exterior")
            if not IsValid(ext) then return end
            if not ply:Alive() then ext:SetOutsideView(ply,false) return end
            local ang=cmd:GetViewAngles()
            ang.r=0
            ply:SetTardisData("viewang",ang)
            cmd:ClearMovement()
            cmd:SetViewAngles(ply:GetTardisData("outsideang"))
            if cmd:KeyDown(IN_USE) then -- user wants out
                ext:SetOutsideView(ply,false)
            end
            cmd:ClearButtons()
        end
    end)
else
    hook.Add("StartCommand", "tardis-outside", function(ply, cmd)
        if ply:GetTardisData("outside") then
            ply:GetTardisData("exterior"):CallHook("Outside-StartCommand", ply, cmd)
            cmd:ClearMovement()
        end
    end)

    hook.Add("SetupMove", "tardis-outside", function(ply, mv, cmd)
        if ply:GetTardisData("outside") then
            mv:SetButtons(0)
            mv:SetMoveAngles(ply:GetTardisData("outsideang", Angle(0,0,0)))
        end
    end)

    ENT:AddHook("Initialize", "outside", function(self)
        self.thpprop=ents.CreateClientProp("models/props_junk/PopCan01a.mdl")
        self.thpprop:SetNoDraw(true)
        self.thpprop:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
        self.thpprop:SetMoveType(MOVETYPE_NONE)
    end)

    ENT:AddHook("OnRemove", "outside", function(self)
        if IsValid(self.thpprop) then
            self.thpprop:Remove()
            self.thpprop=nil
        end
    end)

    ENT:OnMessage("Outside", function(self, data, ply)
        local ply = data[1]
        local enabled = data[2]
        self:CallHook("Outside",ply,enabled)
    end)

    ENT:AddHook("ShouldVortexIgnoreZ", "outside", function(self)
        if LocalPlayer():GetTardisData("outside") then
            return true
        end
    end)

    oldgetviewentity=oldgetviewentity or GetViewEntity
    function GetViewEntity(...)
        if LocalPlayer():GetTardisData("outside") then
            local ext=LocalPlayer():GetTardisData("exterior")
            if IsValid(ext.thpprop) then
                return ext.thpprop
            end
        end
        return oldgetviewentity(...)
    end

    local meta=FindMetaTable("Player")
    oldgetviewentity2=oldgetviewentity2 or meta.GetViewEntity
    function meta:GetViewEntity(...)
        if self:GetTardisData("outside") then
            local ext=self:GetTardisData("exterior")
            if IsValid(ext.thpprop) then
                return ext.thpprop
            end
        end
        return oldgetviewentity2(self,...)
    end
    hook.Add("CalcView", "tardis-outside", function(ply, pos, ang)
        if ply:GetTardisData("outside") then
            local ext=ply:GetTardisData("exterior")
            if IsValid(ext) then
                local newPos, newAng = ext:CallHook("Outside-PosAng", ply, pos, ang)
                if newPos then
                    pos = newPos
                end
                if newAng then
                    ang = newAng
                end
                local view = {}
                view.origin = pos
                view.angles = ang
                view.fov = fov

                if IsValid(ext.thpprop) then
                    ext.thpprop:SetPos(view.origin)
                    ext.thpprop:SetAngles(view.angles)
                end

                return view
            end
        end
    end)

    local hudblock={
        CHudAmmo = true,
        CHudBattery = true,
        CHudCrosshair = true,
        CHudHealth = true,
        CHudSecondaryAmmo = true,
        CHudWeaponSelection = true
    }
    hook.Add("HUDShouldDraw", "tardis-outside", function(name)
        local ply=LocalPlayer()
        if ply.GetTardisData and ply:GetTardisData("outside") and hudblock[name] then
            return false
        end
    end)

    hook.Add("Initialize", "tardis-outside", function(name)
        oldtargetid=oldtargetid or GAMEMODE.HUDDrawTargetID
        GAMEMODE.HUDDrawTargetID = function(...)
            if LocalPlayer():GetTardisData("outside") then return end
            oldtargetid(...)
        end
    end)

    hook.Add("PrePlayerDraw", "tardis-outside", function(ply)
        if ply:GetTardisData("outside") then
            ply.angtemp=ply:EyeAngles()
            ply:SetRenderAngles(Angle(0,ply:GetTardisData("outsideang",0).y,0))
        end
    end)

    hook.Add("ShouldDrawLocalPlayer", "tardis-outside", function(ply)
        if ply:GetTardisData("outside") then
            return true
        end
    end)
end