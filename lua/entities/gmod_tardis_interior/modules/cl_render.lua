-- Rendering override

local function predraw_o(self, part)
    if not TARDIS:GetSetting("lightoverride-enabled") then return end
    local lo = self.metadata.Interior.LightOverride
    if not lo then return end

    local power = self:GetPower()

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

    local function ltempty(lt1)
        return table.IsEmpty(lt1) or (not lt1.color) or (not lt1.pos)
    end

    local function ltcmp(lt1, lt2, only_pos)
        if lt1 == lt2 then return true end
        if ltempty(lt1) and ltempty(lt2) then return true end
        if ltempty(lt1) or ltempty(lt2) then return false end

        local color_ok = (lt1.color == lt2.color)
        local pos_ok = (lt1.pos == lt2.pos)

        return (only_pos or color_ok) and pos_ok
    end

    local function GetLightRenderTable(lt)
        local sel = SelectLightRenderTable(lt)

        if ltempty(sel) then
            sel.color = sel.color or Vector(0,0,0)
            sel.pos = sel.pos or (lt.current and lt.current.pos) or Vector(0,0,0)
            sel.empty = true
            sel.type = sel.type or MATERIAL_LIGHT_POINT
            sel.quadraticFalloff = sel.quadraticFalloff or lt.quadraticFalloff or 20
        end

        if not lt.selected or not lt.current then
            lt.current = sel
            lt.prevsel = lt.selected
            lt.selected = sel
            lt.select_time = CurTime()
            return sel
        end

        if not ltcmp(lt.selected, sel) then
            lt.prevsel = lt.selected
            lt.selected = sel
            lt.select_time = CurTime()
        end

        if ltcmp(sel, lt.current) then
            return sel
        end

        local dt = (CurTime() - lt.select_time) / 2

        if ltcmp(sel, lt.current, true) then
            -- same positions but different colors

            local col_approach = math.Clamp(dt,0,1)
            local ap2 = 1 - col_approach

            local newc = lt.prevsel.color * ap2 + sel.color * col_approach

            lt.current = {
                type = sel.type,
                quadraticFalloff = sel.quadraticFalloff,
                pos = sel.pos,
                color = newc,
            }

            if newc == Vector(0,0,0) then
                return {}
            end

            return lt.current
        end

        if dt < 0.5 then
            local col_approach = math.Clamp(2 * dt,0,1)
            local ap2 = 1 - col_approach

            --local nc = lt.prevsel.color:ToColor()
            --local newcol2 = Color(nc.r * ap2, nc.g * ap2, nc.b * ap2)
            --local newc = newcol2:ToVector() --lt.prevsel.color * ap2

            local newc = lt.prevsel.color * ap2

            lt.current = {
                type = sel.type,
                quadraticFalloff = sel.quadraticFalloff,
                color = newc,
                pos = lt.prevsel.pos
            }
            return lt.current
        end

        if sel.empty then
            lt.current = sel
            return {}
        end

        -- dt > 0.5

        local col_approach = math.Clamp((dt - 0.5) * 2,0,1)
        local ap2 = 1 - col_approach

        local newc = sel.color * col_approach

        lt.current = {
            type = sel.type,
            quadraticFalloff = sel.quadraticFalloff,
            color = newc,
            pos = sel.pos
        }
        return lt.current

    end

    render.SuppressEngineLighting(true)

    local br = power and lo.basebrightness or lo.nopowerbrightness
    local col = power and lo.basebrightnessRGB or lo.nopowerbrightnessRGB

    local parts_table = power and lo.parts or lo.parts_nopower

    if part and parts_table and parts_table[part.ID] then
        local part_br = parts_table[part.ID]
        if istable(part_br) then
            render.ResetModelLighting(part_br[1], part_br[2], part_br[3])
        else
            render.ResetModelLighting(part_br, part_br, part_br)
        end
    elseif col then
        render.ResetModelLighting(col[1], col[2], col[3])
    else
        render.ResetModelLighting(br, br, br)
    end

    table.insert(tab, GetLightRenderTable(light))

    if lights then
        for _,l in pairs(lights) do
            if not TARDIS:GetSetting("extra-lights") then
                table.insert(tab, {})
            else
                table.insert(tab, GetLightRenderTable(l) or {})
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