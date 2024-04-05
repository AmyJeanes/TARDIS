-- Rendering override

local function predraw_o(self, part)
    if not TARDIS:GetSetting("lightoverride-enabled") then return end

    local smooth = TARDIS:GetSetting("smooth-light-transitions")

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

    local function ltcmp(lt1, lt2)
        if lt1 == lt2 then return true end
        if ltempty(lt1) and ltempty(lt2) then return true end
        if ltempty(lt1) or ltempty(lt2) then return false end
        return (lt1.color == lt2.color) and (lt1.pos == lt2.pos)
    end

    local function GetLightRenderTable(lt)
        local sel = SelectLightRenderTable(lt)
        if not smooth then return sel end

        if ltempty(sel) then
            sel.color = sel.color or Vector(0,0,0)
            sel.pos = sel.pos or (lt.current and lt.current.pos) or Vector(0,0,0)
            sel.empty = true
            sel.type = sel.type or MATERIAL_LIGHT_POINT
            sel.quadraticFalloff = sel.quadraticFalloff or lt.quadraticFalloff or 20
        end

        if not lt.selected or not lt.current then
            lt.current = sel
            lt.prev = lt.selected
            lt.selected = sel
            lt.select_time = CurTime()
            lt.should_move = false
            return sel
        end

        if not ltcmp(lt.selected, sel) then
            lt.prev = lt.current
            lt.selected = sel
            lt.select_time = CurTime()
            lt.should_move = (lt.prev.pos ~= lt.selected.pos)
        end

        if ltcmp(sel, lt.current) then
            return sel
        end

        local dt = (CurTime() - lt.select_time) / 2

        if not lt.should_move then
            -- same positions but different colors, light transition

            local approach = math.Clamp(dt,0,1)
            local newc = lt.prev.color * (1 - approach) + sel.color * approach

            lt.current = {
                type = sel.type,
                quadraticFalloff = sel.quadraticFalloff,
                pos = sel.pos,
                color = newc,
            }

            if newc == Vector(0,0,0) then return {} end
            return lt.current
        end

        -- fading out
        if dt < 0.5 or sel.empty then
            local approach = math.Clamp(2 * dt,0,1)
            if sel.empty then approach = math.Clamp(dt,0,1) end
            local newc = lt.prev.color * (1 - approach)

            lt.current = {
                type = sel.type,
                quadraticFalloff = sel.quadraticFalloff,
                color = newc,
                pos = lt.prev.pos
            }

            if newc == Vector(0,0,0) then return {} end
            return lt.current
        end

        -- dt >= 0.5, fading in
        local approach = math.Clamp((dt - 0.5) * 2,0,1)
        local newc = sel.color * approach

        lt.current = {
            type = sel.type,
            quadraticFalloff = sel.quadraticFalloff,
            color = newc,
            pos = sel.pos
        }

        if newc == Vector(0,0,0) then return {} end
        return lt.current
    end

    local function GetLOBrightness(br)
        if not smooth then return br end

        self.lo_model_brightness_data = self.lo_model_brightness_data or {}
        local d = self.lo_model_brightness_data

        if not d.aim or not d.now then
            d.aim = d.aim or br
            d.now = d.now or d.aim
            d.change_time = CurTime()
        end

        if d.aim ~= br then
            d.old = d.now
            d.aim = br
            d.change_time = CurTime()
        end

        if d.now == br then
            return br
        end

        local dt = (CurTime() - d.change_time) / 2
        local approach = math.Clamp(dt,0,1)
        local k2 = 1 - approach

        d.now = d.old * k2 + d.aim * approach

        return d.now
    end

    render.SuppressEngineLighting(true)

    local br = power and lo.basebrightness or lo.nopowerbrightness
    local col = power and lo.basebrightnessRGB or lo.nopowerbrightnessRGB

    local parts_table = power and lo.parts or lo.parts_nopower

    if part and parts_table and parts_table[part.ID] then
        local part_br = parts_table[part.ID]
        if istable(part_br) then
            -- todo: GetLOBrightness(br) for colors
            render.ResetModelLighting(part_br[1], part_br[2], part_br[3])
        else
            part_br = GetLOBrightness(part_br)
            render.ResetModelLighting(part_br, part_br, part_br)
        end
    elseif col then
        -- todo: GetLOBrightness(br) for colors
        render.ResetModelLighting(col[1], col[2], col[3])
    else
        br = GetLOBrightness(br)
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