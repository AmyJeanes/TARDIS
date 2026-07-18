if SERVER then
    -- how close the base must be to a surface to count as grounded, and how long
    -- after leaving the ground a contact still reads as a landing
    local LANDING_CLEARANCE = 16
    local LANDING_GRACE = 0.25

    ---@param collision_data CollisionData
    function ENT:IsVerticalLanding(collision_data)
        local ang = self:GetAngles()
        local angmax = math.max(math.abs(ang.p), math.abs(ang.r))

        local hit_normal_z = collision_data.HitNormal.z
        local vel = collision_data.OurOldVelocity
        local velh = Vector(vel.x, vel.y, 0):Length()
        local velv = math.abs(vel.z)

        return (angmax < 30 and hit_normal_z < -0.85 and vel.z < 0 and (velh <= 1500 or velv > 500))
    end

    ENT:AddHook("PhysicsCollide", "falling", function(self, data, collider)

        if not self:IsVerticalLanding(data) then return end

        -- a moving floor under a landed TARDIS re-collides every tick but never
        -- leaves the ground; only a contact soon after being airborne is a landing
        local last_airborne = self:GetData("last_airborne")
        if not last_airborne or (CurTime() - last_airborne) > LANDING_GRACE then return end

        if (self:CallHook("ShouldNotPlayLandingSound") ~= true or self:CallHook("ShouldPlayLandingSound")) and data.OurOldVelocity.z < -100 then
            self:SendMessage((data.OurOldVelocity.z < -1500) and "fall_crashing_sound" or "fall_landing_sound")
        end

        self:SetData("vertbrakes", true)
        self:Timer("vertbrakes", 0.3, function()
            self:SetData("vertbrakes", false)
        end)

    end)

    ENT:AddHook("PhysicsUpdate", "falling", function(self,ph)

        local free_movement = self:CallHook("ShouldNotAllowFalling") ~= true or self:CallHook("ShouldAllowFalling")
        free_movement = free_movement and ph:IsGravityEnabled() and self:IsAlive()

        self:SetData("free_movement", free_movement, true)

        if not free_movement then
            if self:GetData("vertbrakes") then
                self:SetData("vertbrakes", false)
            end
            return
        end

        if not self:IsAlive() then return end

        -- only look for ground contact when moving vertically: a resting or level-riding
        -- TARDIS isn't leaving the ground, so skip the trace. Trace the world-space
        -- underside so a tipped-over TARDIS still reads grounded.
        if math.abs(ph:GetVelocity().z) > 16 then
            local amin, amax = self:WorldSpaceAABB()
            local foot = Vector((amin.x + amax.x) * 0.5, (amin.y + amax.y) * 0.5, amin.z + 1)
            if not util.QuickTrace(foot, Vector(0, 0, -LANDING_CLEARANCE), self).Hit then
                self:SetData("last_airborne", CurTime())
            end
        end

        local phm=FrameTime()*66
        local up=self:GetUp()
        local ri2=self:GetRight()
        local fwd2=self:GetForward()
        local ang=self:GetAngles()
        local vel=ph:GetVelocity()
        local vell=ph:GetVelocity():Length()
        local cen=ph:GetMassCenter()
        local lev=ph:GetInertia():Length()
        local angv=ph:GetAngleVelocity()

        local function align_in_flight()
            local angmax = math.max(math.abs(ang.p), math.abs(ang.r))
            local angvmax = math.max(math.abs(angv.x), math.abs(angv.y))

            ph:SetAngleVelocityInstantaneous(Vector(angv.x * 0.95, angv.y * 0.95, angv.z))

            if angvmax <= 50 and angmax > 10 then
                ph:ApplyForceOffset( up * -ang.p * 10, cen - fwd2 * lev)
                ph:ApplyForceOffset(-up * -ang.p * 10, cen + fwd2 * lev)
                ph:ApplyForceOffset( up * -ang.r * 10, cen - ri2 * lev)
                ph:ApplyForceOffset(-up * -ang.r * 10, cen + ri2 * lev)
            end
        end


        local function reduce_movement()
            if math.abs(ang.p) <= 35 and math.abs(ang.r) <= 35 and vel.z > 0 then
                local newvel_x = math.Clamp(vel.x * 0.05,-30,30)
                local newvel_y = math.Clamp(vel.y * 0.05,-30,30)

                ph:SetVelocityInstantaneous(-up * 100 * phm)
                ph:AddVelocity(Vector(newvel_x,newvel_y,0))

                local newavel_x = math.Clamp(angv.x * 0.1,-300,300)
                local newavel_y = math.Clamp(angv.y * 0.1,-300,300)
                local newavel_z = math.Clamp(angv.z * 0.1,-300,300)
                ph:SetAngleVelocityInstantaneous(Vector(newavel_x,newavel_y,newavel_z))
            end
        end

        local pressing_down = IsValid(self.pilot) and TARDIS:IsBindDown(self.pilot,"flight-down")
        local vertbrakes = self:GetData("vertbrakes")
        local stopped = (vell < 1)

        local height = self:OBBMaxs().z - self:OBBMins().z
        local tr = util.QuickTrace(self:GetPos(), Vector(0,0,-height))

        if pressing_down and not vertbrakes and not tr.Hit then
            align_in_flight()
        end

        if vertbrakes then
            if stopped then
                self:SetData("vertbrakes", false)
                self:CancelTimer("vertbrakes")
            end
            reduce_movement()
        end
    end)

    ENT:AddHook("ShouldNotAllowFalling", "falling", function(self)
        if self:IsPlayerHolding() then
            return true
        end
    end)
else
    ENT:OnMessage("fall_landing_sound", function(self, data, ply)
        if not TARDIS:GetSetting("sound") then return end
        if CurTime() - self:GetData("fall_sound_last", 0) < 2 then return end
        self:SetData("fall_sound_last", CurTime())

        local snds = self.metadata.Exterior.Sounds

        if TARDIS:GetSetting("flight-externalsound") then
            TARDIS:PlaySound({ path = snds.FlightLand, owner = self, tag = "flight", ent = self, resumable = true })
        end

        if IsValid(self.interior) and TARDIS:GetSetting("flight-internalsound") then
            local snds_i = self.metadata.Interior.Sounds
            TARDIS:PlaySound({ path = snds_i.FlightLand or snds.FlightLand,
                owner = self, tag = "flight", ent = self.interior, resumable = true })
        end
    end)

    ENT:OnMessage("fall_crashing_sound", function(self, data, ply)
        if not TARDIS:GetSetting("sound") then return end
        local snds = self.metadata.Exterior.Sounds

        if TARDIS:GetSetting("flight-externalsound") then
            TARDIS:PlaySound({ path = snds.FlightFall, owner = self, tag = "flight", ent = self, resumable = true })
        end

        if IsValid(self.interior) and TARDIS:GetSetting("flight-internalsound") then
            local snds_i = self.metadata.Interior.Sounds
            TARDIS:PlaySound({ path = snds_i.FlightFall or snds.FlightFall,
                owner = self, tag = "flight", ent = self.interior, resumable = true })
        end
    end)
end