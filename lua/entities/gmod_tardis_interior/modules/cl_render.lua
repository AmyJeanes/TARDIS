-- Rendering override

local function predraw_o(self, part)
    if not TARDIS:GetSetting("lightoverride-enabled") then return end
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
    local light = self.light_data.main

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
    if self.light_data.main == nil then return end
    render.SuppressEngineLighting(false)
end

ENT:AddHook("PreDraw", "customlighting", predraw_o)

ENT:AddHook("Draw", "customlighting", postdraw_o)

ENT:AddHook("PreDrawPart", "customlighting", predraw_o)

ENT:AddHook("PostDrawPart", "customlighting", postdraw_o)