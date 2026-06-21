-- Rendering override

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

local function postdraw_o(self)
    if not TARDIS:GetSetting("lightoverride-enabled") then return end
    if not self.metadata.Interior.LightOverride then return end
    render.SuppressEngineLighting(false)
end

local function predraw_ply(ply, ent)
    local int = ply:GetTardisInterior()
    if int then predraw_o(int, ent) end
end

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
