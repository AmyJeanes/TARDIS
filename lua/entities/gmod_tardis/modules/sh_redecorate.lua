local saved_data_names = {
    "cloak",
    "floatfirst",
    "hads",
    "spindir",
    "spindir_prev",
    "spindir_before_door",
    "handbrake",
    "physlock",
    "demat-fast",
    "fastreturn-pos",
    "fastreturn-ang",
    "artron-val",
    "security",
    "chameleon_active",
    "chameleon_current_exterior",
    "chameleon_exterior_last_selector",
}

if SERVER then
    function ENT:SetRedecoration(on)
        if self:CallCommonHook("CanToggleRedecoration", on) == false
            or self:CallHook("CanRepair", true) == false
        then
            return false
        end

        if not on then
            self:SetData("redecorate", false, true)
            if self:GetRepairPrimed() then
                self:SetRepair(false)
                return true
            end
            return false
        end

        local chosen_int = TARDIS:GetSetting("redecorate-interior", self)
        local random_int = false
        if not chosen_int then
            random_int = true
            chosen_int = TARDIS:SelectNewRandomInterior(self.metadata.ID, self)
        end

        self:SetData("redecorate-interior", chosen_int)
        self:SetData("redecorate", true, true)
        self:SendMessage("redecorate-selection-reset")

        self:CallHook("RedecorateToggled", on)

        if not self:GetRepairPrimed() and not self:SetRepair(true) then
            return false
        end
        if random_int then
            TARDIS:Message(self:GetCreator(), "Controls.Redecorate.RandomInteriorWarning")
        end
        return true
    end

    function ENT:ToggleRedecoration()
        local on = self:GetData("redecorate", false)
        return self:SetRedecoration(not on)
    end

    function ENT:Redecorate()

        local ply = self:GetCreator()

        self:SetData("repairing", false, true)
        self:ChangeHealth(self:GetHealthMax())
        self:SetPower(true)

        -- save tardis state
        local saved_data = {}
        for k,v in ipairs(saved_data_names) do
            saved_data[v] = self:GetData(v)
        end

        local child = TARDIS:SpawnTARDIS(ply, {
            pos = self:GetPos(),
            metadataID = self:GetData("redecorate-interior") or "default",
            redecorate_parent = self,
            saved_data = saved_data,
        })

        if not IsValid(child) then
            ErrorNoHalt(TARDIS:GetPhrase("Redecorate.Failed"))
        end
        return IsValid(child) -- if gone wrong, finish repair
    end

    ENT:AddHook("StopDemat", "redecorate_remove_parent", function(self)
        if self:GetData("redecorate") then
            if self:GetData("redecorate_pending_remove") then
                local child = self:GetData("redecorate_child")
                if IsValid(child) then
                    child:SetData("redecorate_parent", nil, true)
                end
                self:Remove()
            else
                self:SetData("redecorate_pending_remove", true)
            end
        end
    end)

    ENT:AddHook("MatStart", "redecorate_sync", function(self)
        local parent = self:GetData("redecorate_parent")
        if not IsValid(parent) then return end

        parent:ForcePlayerDrop()
        self:SetCollisionGroup(COLLISION_GROUP_WORLD)
        self:SetPos(parent:GetPos())
        self:SetAngles(parent:GetAngles())
        parent:SetParent(self)
        self:SetData("is_redecorate_child", true, true)
        if parent:GetData("redecorate_pending_remove") then
            parent:Remove()
            self:SetData("redecorate_parent", nil, true)
        else
            parent:SetData("redecorate_pending_remove", true)
        end
    end)

    ENT:AddHook("CanMat", "redecorate", function(self)
        if self:GetData("redecorate") then
            return false
        end
    end)

    ENT:AddHook("StopMat", "redecorate_sync", function(self)
        local parent_vortex = self:GetData("redecorate_parent_vortex")

        if parent_vortex then
            self:SetFastRemat(false)
            self:SetData("redecorate_parent_vortex", nil, true)
        end

        self:SetData("is_redecorate_child", nil, true)
    end)

    ENT:AddHook("CustomData", "redecorate_child", function(self, customdata)
        local parent = customdata.redecorate_parent
        if parent then
            self:SetData("redecorate_parent", parent, true)
            parent:SetData("redecorate_child", self)

            self:SetPos(parent:GetPos())
            self:SetAngles(parent:GetAngles())

            self:SetData("redecorate_parent_data", customdata.saved_data, true)

            local vortex = (not parent:GetFastRemat())
            self:SetData("redecorate_parent_vortex", vortex, true)
        end
    end)

    ENT:AddHook("Initialize", "redecorate_child", function(self)
        local parent = self:GetData("redecorate_parent")
        if not parent then return end

        local phys = self:GetPhysicsObject()
        phys:Sleep()

        self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    end)

    ENT:AddHook("PostInitialize", "redecorate_child", function(self)
        local parent = self:GetData("redecorate_parent")
        if not parent then return end

        self:ForceDematState()

        local saved_data = self:GetData("redecorate_parent_data")
        if saved_data then
            for name,value in pairs(saved_data) do
                self:SetData(name, value, true)
            end
        end
        self:CallHook("MigrateData", parent, saved_data)
        self:SetData("redecorate_parent_data", nil, true)

        local phys = self:GetPhysicsObject()

        constraint.RemoveAll(parent) -- drop everything attached
        parent:SetFastRemat(true, true)

        parent:SetPhyslock(true)
        parent:ForcePlayerDrop()
        parent:Demat(nil, nil, nil, false)
        parent:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

        self:Timer("redecorate_materialise", 1, function()
            if IsValid(parent) then
                parent:ForcePlayerDrop()
                parent:SetData("redecorate_mat_started", true)
            end

            phys:Wake()
            self:SetFastRemat(true, true)
            self:Mat()

            local ply = self:GetCreator()
            if IsValid(ply) and ply.linked_tardis == parent then
                ply.linked_tardis = self
                net.Start("Sonic-SetLinkedTARDIS")
                    net.WriteEntity(self)
                net.Send(ply)
            end
        end)

    end)

    ENT:AddHook("ShouldTeleportPortal", "redecorate", function(self,portal,ent)
        if self:GetData("redecorate") or ent == self:GetData("redecorate_next") then
            return false
        end
    end)

    ENT:AddHook("RepairCancelled", "redecorate", function(self,portal,ent)
        if self:GetData("redecorate") then
            self:SetData("redecorate", false)
        end
    end)

    ENT:AddHook("ShouldUpdateArtron", "redecorate", function(self)
        if self:GetData("redecorate")
            or self:GetData("redecorate_parent")
            or self:GetData("redecorate_child")
            or self:GetData("is_redecorate_child")
        then
            return false
        end
    end)

    ENT:AddHook("ShouldTakeDamage", "redecorate", function(self, dmginfo)
        if self:GetData("redecorate") then return false end
        if IsValid(self:GetData("redecorate_parent")) then return false end -- while parent exists
    end)

    hook.Add("AllowPlayerPickup", "tardis_redecorate", function(ply, ent)
        if ent.TardisExterior and (ent:GetData("redecorate_parent") or ent:GetData("redecorate_mat_started")) then
            return false
        end
    end)

else -- CLIENT
    ENT:AddHook("DataLoaded", "redecorate", function(self)
        local parent = self:GetData("redecorate_parent")
        if parent then
            self:CallHook("MigrateData", parent)
        end
    end)

    ENT:OnMessage("redecorate-selection-reset", function(self, data, ply)
        if not IsValid(self) or (not LocalPlayer() == self:GetCreator()) then return end
        TARDIS:SetSetting("redecorate-interior", false)
    end)
end