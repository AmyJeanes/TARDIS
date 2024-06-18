-- Rendering override

local function predraw_o(self, part)
    local lo = self.metadata.Interior.LightOverride
    if not lo then return end

    render.SuppressEngineLighting(true)

    local power = self:GetPower()
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



    local light = self.light_data and self.light_data.main

    if light == nil then return end
    --because for some reason SOMEONE OUT THERE didn't define a light.

    local lights = self.light_data.extra
    local state = self.exterior:GetState()
    local render_tables = {}

    local function SelectLightRenderTable(lt)
        if self:CallHook("ShouldDrawLight",nil,lt) == false then
            return {}
        end

        return (lt.render_tables and lt.render_tables[state]) or {}
    end



    table.insert(render_tables, SelectLightRenderTable(light))

    if lights then
        for _,l in pairs(lights) do
            if not TARDIS:GetSetting("extra-lights") then
                table.insert(render_tables, {})
            else
                table.insert(render_tables, SelectLightRenderTable(l) or {})
            end
        end
    end

    if #render_tables==0 then
        render.SetLocalModelLights()
    else
        render.SetLocalModelLights(render_tables)
    end
end

local function postdraw_o(self)
    if (self.light_data and self.light_data.main) == nil then return end
    render.SuppressEngineLighting(false)
end

ENT:AddHook("PreDraw", "customlighting", predraw_o)

ENT:AddHook("Draw", "customlighting", postdraw_o)

ENT:AddHook("PreDrawPart", "customlighting", predraw_o)

ENT:AddHook("PostDrawPart", "customlighting", postdraw_o)