-- Rendering override

---@param self gmod_tardis_interior
local function predraw_o(self, part)
    if not TARDIS:GetSetting("lightoverride-enabled") then return end
    if part and part.AllowThroughPortals and not self.props[part] then return end
    local lo = self.metadata.Interior.LightOverride
    if not lo then return end

    local power = self:GetPower()

    render.SuppressEngineLighting(true)

    local colvec = self:GetBaseLightColorVector()

    local parts_table = power and lo.parts or lo.parts_nopower

    if part and parts_table and parts_table[part.ID] then
        local part_br = parts_table[part.ID]
        if istable(part_br) then
            render.ResetModelLighting(part_br[1], part_br[2], part_br[3])
        else
            render.ResetModelLighting(part_br, part_br, part_br)
        end
    else
        render.ResetModelLighting(colvec[1], colvec[2], colvec[3])
    end

    --render.SetLightingMode(1)
    local light = self.light_data and self.light_data.main

    if light == nil then return end
    --because for some reason SOMEONE OUT THERE didn't define a light.

    local lights = self.light_data.extra
    local warning = self:GetData("warning", false)

    local tab={}

    local function SelectLightRenderTable(lt)
        if self:CallHook("ShouldDrawLight",nil,lt) == false then
            return {}
        end

        if (not power) and warning then
            return lt.off_warn_render_table
        elseif not power then
            return lt.off_render_table
        elseif warning then
            return lt.warn_render_table
        end
        -- power and no warning
        return lt.render_table

    end

    table.insert(tab, SelectLightRenderTable(light))

    if lights then
        for _,l in pairs(lights) do
            if not TARDIS:GetSetting("extra-lights") then
                table.insert(tab, {})
            else
                table.insert(tab, SelectLightRenderTable(l) or {})
            end
        end
    end

    if #tab==0 then
        render.SetLocalModelLights()
    else
        render.SetLocalModelLights(tab)
    end
end

---@param self gmod_tardis_interior
local function postdraw_o(self)
    if not TARDIS:GetSetting("lightoverride-enabled") then return end
    if not self.metadata.Interior.LightOverride then return end
    render.SuppressEngineLighting(false)
end

---@param ply Player
---@param ent Entity
local function predraw_ply(ply, ent)
    local int = ply:GetTardisInterior()
    if int then predraw_o(int, ent) end
end

---@param ply Player
local function postdraw_ply(ply)
    local int = ply:GetTardisInterior()
    if int then postdraw_o(int) end
end

ENT:AddHook("PreDraw", "customlighting", predraw_o)
ENT:AddHook("Draw", "customlighting", postdraw_o)

ENT:AddHook("PreDrawPart", "customlighting", predraw_o)
ENT:AddHook("PostDrawPart", "customlighting", postdraw_o)

ENT:AddHook("PreDrawCordonProp", "customlighting", predraw_o)
ENT:AddHook("PostDrawCordonProp", "customlighting", postdraw_o)

-- Player rendering hooks can be affected by other addons, so if another addon
-- blocks PreDraw then PostDraw will not fire and the lighting will remain
-- suppressed. We partially avoid this with players by using the Doors addon
-- hooks for Pre/PostDrawPlayer to resolve the issue internally for when we
-- block player draws e.g. in the sky, but other addons could break this.
-- 
-- A potential fix is to call its own hook inside the Pre hooks to see what the
-- final result is and then call interior hooks, but it will double fire all the
-- Pre hooks and could cause other issues, so for now leaving it as is as seems to
-- be working fine in practice. Can revisit if it becomes a problem in the future.

ENT:AddHook("PreDrawPlayer", "customlighting", predraw_o)
ENT:AddHook("PostDrawPlayer", "customlighting", postdraw_o)

hook.Add("PreDrawViewModel", "tardis-customlighting", function(vm, ply) predraw_ply(ply, vm) end)
hook.Add("PostDrawViewModel", "tardis-customlighting", function(_, ply) postdraw_ply(ply) end)

hook.Add("PreDrawPlayerHands", "tardis-customlighting", function(hands, _, ply) predraw_ply(ply, hands) end)
hook.Add("PostDrawPlayerHands", "tardis-customlighting", function(_, _, ply) postdraw_ply(ply) end)

-- Player weapon world model has it's lighting baked during player bone setup and cannot
-- be relit during weapon drawing, so we hide the real weapon and draw a clone in its place
-- that we can apply lighting override to. Some weapons use dynamic models which means their
-- bone positions will not be accurate, so instead of copying the bone positions from the
-- real weapon, we create a second hidden clone that is bonemerged to the player using the
-- actual weapon model (from DrawWorldModel) and use that as the source for the bone positions.

local meta = assert(FindMetaTable("Entity"))

-- Use a weak table (__mode = "k") so that when the weapon is removed, the clone is automatically garbage collected.
local weaponClones = setmetatable({}, { __mode = "k" }) -- [weapon] = { draw, pose, override, base, interior, ply, model, skin }

---@param wep Entity
local function releaseWeaponClone(wep)
    local rec = weaponClones[wep]
    if not rec then return end
    if IsValid(wep) and wep.RenderOverride == rec.override then
        wep.RenderOverride = rec.base
    end
    if IsValid(rec.draw) then rec.draw:Remove() end
    if IsValid(rec.pose) then rec.pose:Remove() end
    weaponClones[wep] = nil
end

-- Attempt to resolve the actual world model that a weapon will draw, which may be different
-- from the model returned by GetWeaponWorldModel if the weapon overrides DrawWorldModel.
-- This is hacky but necessary as some weapons e.g. the Sonic Screwdriver use a placeholder
-- model and then draw the actual model dynamically in DrawWorldModel.
---@param wep Entity
local function resolveWeaponWorldModel(wep)
    if not isfunction(wep.DrawWorldModel) then
        return wep:GetModel(), wep:GetSkin()
    end
    local model, skin
    local oSet, oSkin, oDraw = meta.SetModel, meta.SetSkin, meta.DrawModel
    meta.SetModel = function(s, m) if s == wep then model = m return end return oSet(s, m) end
    meta.SetSkin = function(s, k) if s == wep then skin = k return end return oSkin(s, k) end
    meta.DrawModel = function(s, ...) if s == wep then return end return oDraw(s, ...) end
    pcall(wep.DrawWorldModel, wep)
    meta.SetModel, meta.SetSkin, meta.DrawModel = oSet, oSkin, oDraw
    return model or wep:GetModel(), skin or wep:GetSkin()
end

-- Attempt to sync the skin, owner and bodygroups of the draw clone to the real weapon, so
-- it matches the real weapon as closely as possible. The owner is important for some weapons
-- that use the owner to determine how to draw themselves, e.g. the Physgun for player weapon
-- colour or the Sonic Screwdriver to show the lighting effects when the player is holding it.
---@param wep Entity
local function syncWeaponDrawClone(rec, wep)
    local draw = rec.draw
    if draw:GetModel() ~= rec.model then draw:SetModel(rec.model) end
    draw:SetSkin(rec.skin or 0)
    draw:SetOwner(wep:GetOwner())
    if wep:GetModel() == rec.model then
        for i = 0, draw:GetNumBodyGroups() - 1 do
            draw:SetBodygroup(i, wep:GetBodygroup(i))
        end
    end
end

local function makeWeaponOverride(rec)
    return function(self, flags)
        local int = rec.interior
        local draw, pose = rec.draw, rec.pose
        -- Fallback if the interior is gone or the clones are invalid, so the weapon still draws.
        if not (IsValid(int) and IsValid(draw) and IsValid(pose)) then
            if rec.base then rec.base(self, flags) else self:DrawModel(flags) end
            return
        end
        syncWeaponDrawClone(rec, self)
        -- Pose the drawn clone from the posed clone, and render the drawn clone
        pose:SetupBones()
        draw:SetupBones()
        for i = 0, draw:GetBoneCount() - 1 do
            local m = pose:GetBoneMatrix(i)
            if m then draw:SetBoneMatrix(i, m) end
        end
        predraw_o(int, nil)
        draw:DrawModel(flags)
        postdraw_o(int)
    end
end

---@param model string
local function makeWeaponClone(model)
    local c = ClientsideModel(model)
    if not IsValid(c) then return end
    c:Spawn()
    c:SetNoDraw(true) -- not auto-drawn by the engine, the override draws the draw clone
    return c
end

---@param ply Player
---@param int gmod_tardis_interior
local function ensureWeaponClone(ply, int)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    local model, skin = resolveWeaponWorldModel(wep)
    if not model or model == "" then return end
    local rec = weaponClones[wep]
    if not rec then
        local draw = makeWeaponClone(model)
        if not draw then return end
        -- The clone pos is technically 0,0,0 but the bones are shifted to the correct world positions
        -- this can cause it to render with a low LOD so force the highest LOD on the drawn clone
        draw:SetLOD(0)
        local pose = makeWeaponClone(model)
        if not pose then draw:Remove() return end
        pose:SetParent(ply)
        pose:AddEffects(EF_BONEMERGE)
        rec = { draw = draw, pose = pose, interior = int, ply = ply, model = model, skin = skin }
        rec.override = makeWeaponOverride(rec)
        rec.base = wep.RenderOverride
        wep.RenderOverride = rec.override
        weaponClones[wep] = rec
    else
        rec.interior = int
        rec.ply = ply
        rec.skin = skin
        if rec.model ~= model then
            rec.model = model
            if IsValid(rec.pose) then rec.pose:SetModel(model) end
        end
        -- Re-take the slot if a foreign override displaced us, chaining any existing override
        -- so we can layer over it rather than replacing it entirely.
        if wep.RenderOverride ~= rec.override then
            rec.base = wep.RenderOverride
            wep.RenderOverride = rec.override
        end
    end
end

ENT:AddHook("Think", "weaponworldmodel", function(self)
    local occupants = self.occupants
    if not occupants then return end
    local active = TARDIS:GetSetting("lightoverride-enabled") and self.metadata.Interior.LightOverride
    if active then
        for ply in pairs(occupants) do
            -- Yield the override while world-portals is ghosting the weapon
            if IsValid(ply) and not wp.IsGhosting(ply) then
                ensureWeaponClone(ply, self)
            end
        end
    end
    -- Release the clone when the player has left the interior, weapon no longer exists etc
    for wep, rec in pairs(weaponClones) do
        if rec.interior == self and (not active or not IsValid(wep) or not IsValid(rec.ply)
            or rec.ply:GetActiveWeapon() ~= wep or not occupants[rec.ply]) then
            releaseWeaponClone(wep)
        end
    end
end)

ENT:AddHook("OnRemove", "weaponworldmodel", function(self)
    for wep, rec in pairs(weaponClones) do
        if rec.interior == self then releaseWeaponClone(wep) end
    end
end)
