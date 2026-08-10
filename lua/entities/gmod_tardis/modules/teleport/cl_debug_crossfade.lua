-- Debug crossfade

local SLIDERS = {
    { key = "MatStart",   label = "Mat start",   lead = true, help = "When the mat (arrival) sound starts fading in - right = closer to the jump" },
    { key = "MatFade",    label = "Mat fade",    help = "How long the mat (arrival) sound takes to fade in" },
    { key = "DematStart", label = "Demat start", lead = true, help = "When the demat (departure) sound starts fading out - right = closer to the jump" },
    { key = "DematFade",  label = "Demat fade",  help = "How long the demat (departure) sound takes to fade out" },
}

local function load_from_interior()
    local ext = LocalPlayer():GetTardisExterior()
    if not IsValid(ext) then return end
    local cf = ext.metadata.Exterior.Teleport.Crossfade
    local o = TARDIS.TeleportCrossfadeOverride
    for _, k in ipairs(SLIDERS) do
        o[k.key] = cf[k.key]
    end
    o.dirty = false
end

local function copy_metadata()
    local o = TARDIS.TeleportCrossfadeOverride
    local block = string.format(
        "Crossfade = {\n    MatStart = %d,\n    MatFade = %d,\n    DematStart = %d,\n    DematFade = %d,\n},",
        o.MatStart, o.MatFade, o.DematStart, o.DematFade)
    SetClipboardText(block)
    MsgN("\n" .. block .. "\n")
    notification.AddLegacy("Crossfade block copied to clipboard and console", NOTIFY_GENERIC, 4)
end

---@param ext gmod_tardis
local function play_demat(ext)
    local extsnd = ext.metadata.Exterior.Sounds.Teleport
    local intsnd = ext.metadata.Interior.Sounds.Teleport
    local int_h, ext_h = ext:PlayTeleportSound(extsnd.demat, intsnd.demat or extsnd.demat, true, true)
    local stored = {}
    if int_h then stored[#stored + 1] = int_h end
    if ext_h then stored[#stored + 1] = ext_h end
    ext.tp_crossfade_demat_sounds = stored
end

---@param ext gmod_tardis
---@param jump_at number
---@param seek number?
local function play_mat(ext, jump_at, seek)
    local extsnd = ext.metadata.Exterior.Sounds.Teleport
    local intsnd = ext.metadata.Interior.Sounds.Teleport
    local mat_int, mat_ext = ext:PlayTeleportSound(extsnd.mat, intsnd.mat or extsnd.mat, true, true, seek)
    ext:StartTeleportCrossfade(mat_int, mat_ext, jump_at)
end

-- Replays the real no-vortex timeline (demat, then mat, then the jump) without actually teleporting
local function preview()
    local ext = LocalPlayer():GetTardisExterior()
    if not IsValid(ext) then
        notification.AddLegacy("Get inside a TARDIS to preview the crossfade", NOTIFY_ERROR, 4)
        return
    end
    ext:StopSounds("teleport")
    ext:ClearTeleportCrossfade()

    local premat = ext.metadata.Exterior.Teleport.PrematDelay
    local demat_dur = ext:GetDematDuration()
    local lead = math.min(premat, demat_dur)
    local seek = premat - lead
    local mat_at = CurTime() + math.max(0, demat_dur - premat)
    local jump_at = CurTime() + demat_dur

    play_demat(ext)
    ext.tp_crossfade_jump = jump_at
    hook.Add("Think", "tardis_crossfade_preview", function()
        if not IsValid(ext) then hook.Remove("Think", "tardis_crossfade_preview") return end
        if CurTime() < mat_at then return end
        hook.Remove("Think", "tardis_crossfade_preview")
        play_mat(ext, jump_at, seek > 0 and seek or nil)
    end)
end

concommand.Add("tardis2_debug_crossfade", function()
    local cmenu = g_ContextMenu
    if not IsValid(cmenu) then return end

    for _, c in ipairs(cmenu:GetChildren()) do
        if IsValid(c) and c.tardis_crossfade_settings then c:Remove() end
    end

    local ctxkey = string.upper(input.LookupBinding("+menu_context") or "C")
    print("[TARDIS] Crossfade settings opened - hold " .. ctxkey .. " to show")

    -- Load current interior settings unless the sliders have been modified by the player
    if not TARDIS.TeleportCrossfadeOverride.dirty then load_from_interior() end
    TARDIS.TeleportCrossfadeOverride.active = false

    local f = cmenu:Add("DFrame")
    f.tardis_crossfade_settings = true
    f:SetMouseInputEnabled(true)
    f:SetKeyboardInputEnabled(true)
    f:SetSize(545, 542)
    f:SetSizable(true)
    f:SetMinWidth(300)
    f:SetMinHeight(400)
    f:SetPos(60, 60)
    f:SetTitle("TARDIS: Crossfade Settings")

    -- Reload settings if the player enters a different TARDIS while the menu is open
    local autoload_ext = LocalPlayer():GetTardisExterior()
    hook.Add("Think", "tardis_crossfade_autoload", function()
        if not IsValid(f) then hook.Remove("Think", "tardis_crossfade_autoload") return end
        local ext = LocalPlayer():GetTardisExterior()
        if ext == autoload_ext then return end
        autoload_ext = ext
        -- Only reload settings if the player hasn't modified the sliders already
        if IsValid(ext) and not TARDIS.TeleportCrossfadeOverride.dirty then load_from_interior() end
    end)

    function f:OnClose()
        TARDIS.TeleportCrossfadeOverride.active = false
        hook.Remove("Think", "tardis_crossfade_autoload")
        hook.Remove("Think", "tardis_crossfade_preview")
    end

    local scroll = f:Add("DScrollPanel")
    scroll:Dock(BOTTOM)
    scroll:SetTall(218)
    scroll:DockMargin(2, 2, 2, 4)

    local graph = f:Add("DPanel")
    graph:Dock(FILL)
    graph:DockMargin(6, 6, 6, 4)
    ---@param w number
    ---@param h number
    function graph:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(26, 28, 34))
        local ext = LocalPlayer():GetTardisExterior()
        if not IsValid(ext) then
            draw.SimpleText("get inside a TARDIS", "DermaDefault", w / 2, h / 2, Color(150, 120, 120),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        -- ttj = time-to-jump (negative is past the teleport jump)
        local total = ext:GetTeleportDuration()
        local mat_lead, mat_fade, demat_lead, demat_fade = ext:GetTeleportCrossfadeTimings()
        mat_fade = math.max(mat_fade, 0.01)
        demat_fade = math.max(demat_fade, 0.01)
        local demat_start = ext:GetDematDuration() -- ttj the demat sound begins (window left); jump lands at demat end
        local lead = math.min(ext.metadata.Exterior.Teleport.PrematDelay, demat_start) -- ttj the mat sound (seeked) starts
        local mat_end = ext:GetMatDuration() -- the mat sequence ends at ttj = -mat_end (window right)

        local gx, gy = 30, 8
        local gw, gh = w - gx - 10, h - gy - 18
        surface.SetDrawColor(38, 41, 50)
        surface.DrawRect(gx, gy, gw, gh)

        local left_ttj = math.max(demat_start, lead)
        local right_ttj = -mat_end
        local span = left_ttj - right_ttj
        ---@param ttj number
        ---@return number
        local function xpos(ttj) return gx + gw * (left_ttj - ttj) / span end
        ---@param level number 0-1 gain
        ---@return number
        local function ypos(level) return gy + gh * (1 - math.Clamp(level, 0, 1)) end

        for i = 0, 4 do
            local frac = i / 4
            local y = gy + gh * (1 - frac)
            surface.SetDrawColor(52, 56, 66)
            surface.DrawRect(gx, y, gw, 1)
            draw.SimpleText(math.Round(frac * 100) .. "", "DermaDefault", gx - 3, y, Color(110, 115, 130),
                TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        local dsx = xpos(demat_start)
        draw.SimpleText("demat start", "DermaDefault", dsx + 3, gy + 1, Color(120, 150, 220, 190))

        local msx = xpos(lead)
        draw.SimpleText("mat sound start", "DermaDefault", msx + 3, gy + gh - 13, Color(110, 210, 130, 190))

        local mex = xpos(-mat_end)
        draw.SimpleText("mat end", "DermaDefault", mex - 3, gy + 1, Color(110, 210, 130, 190), TEXT_ALIGN_RIGHT)

        local jx = xpos(0)
        surface.SetDrawColor(230, 190, 80, 200)
        surface.DrawRect(jx - 1, gy, 2, gh)
        draw.SimpleText("jump", "DermaDefault", jx + 3, gy + gh - 13, Color(230, 190, 80))

        ---@param which number 1 = mat, 2 = demat
        ---@param col table
        ---@param hi number ttj to start drawing at
        ---@param lo number ttj to stop at
        local function curve(which, col, hi, lo)
            if hi <= lo then return end
            surface.SetDrawColor(col)
            local px, py
            for s = 0, 120 do
                local ttj = hi - (hi - lo) * s / 120
                ---@type number
                local level
                if which == 1 then
                    level = math.Clamp((mat_lead - ttj) / mat_fade, 0, 1)
                else
                    level = 1 - math.Clamp((demat_lead - ttj) / demat_fade, 0, 1)
                end
                local x, y = xpos(ttj), ypos(level)
                if px then surface.DrawLine(px, py, x, y) end
                px, py = x, y
            end
        end
        curve(2, Color(110, 150, 220), left_ttj, right_ttj) -- demat: whole window
        curve(1, Color(110, 210, 130), lead, right_ttj) -- mat: from the mat sound start

        local pj = ext.tp_crossfade_jump
        if pj then
            local ttj = pj - CurTime()
            if ttj <= left_ttj and ttj >= right_ttj then
                surface.SetDrawColor(255, 255, 255, 220)
                surface.DrawRect(xpos(ttj) - 1, gy, 2, gh)
            end
        end

        -- Legend
        local ly = (gy + gh + h) / 2
        surface.SetFont("DermaDefault")
        local matw = surface.GetTextSize("mat sound")
        draw.SimpleText("mat sound", "DermaDefault", gx + 2, ly, Color(110, 210, 130),
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("demat sound", "DermaDefault", gx + 2 + matw + 12, ly, Color(110, 150, 220),
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("teleport %.1fs", total), "DermaDefault", w - 10, ly,
            Color(150, 155, 170), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local trow = scroll:Add("DPanel")
    trow:Dock(TOP) trow:DockMargin(2, 4, 2, 4) trow:SetTall(18)
    trow:SetPaintBackground(false)

    local override = trow:Add("DCheckBoxLabel")
    override:SetText("Live override:")
    override:SizeToContents()
    override:SetChecked(TARDIS.TeleportCrossfadeOverride.active)
    ---@param v boolean
    function override:OnChange(v) TARDIS.TeleportCrossfadeOverride.active = v end

    local note = trow:Add("DLabel")
    note:SetContentAlignment(4)
    note:SetMouseInputEnabled(true)
    function note:DoClick() override:Toggle() end
    function note:Think()
        if TARDIS.TeleportCrossfadeOverride.active then
            self:SetText("On - Using slider settings")
            self:SetTextColor(Color(150, 200, 160))
        else
            self:SetText("Off - Using interior's saved settings")
            self:SetTextColor(Color(170, 160, 130))
        end
    end

    ---@param w number
    ---@param h number
    function trow:PerformLayout(w, h)
        override:SetPos(0, math.max(0, (h - override:GetTall()) / 2))
        local nx = override:GetWide() + 4 -- one space, so the status hugs the label
        note:SetPos(nx, 0)
        note:SetSize(math.max(0, w - nx), h)
    end

    -- Warn the player if vortex flight is on, since the crossfade is not used in that case
    local vortex_warn = scroll:Add("DLabel")
    vortex_warn:Dock(TOP) vortex_warn:DockMargin(2, 0, 2, 4)
    vortex_warn:SetTall(16) vortex_warn:SetContentAlignment(4)
    function vortex_warn:Think()
        local ext = LocalPlayer():GetTardisExterior()
        if not IsValid(ext) then
            self:SetText("")
        elseif ext:GetFastRemat() then
            self:SetText("Vortex flight is off: Dematerialise or press 'Preview' to test the crossfade")
            self:SetTextColor(Color(150, 200, 160))
        else
            self:SetText("Vortex flight is on: Disable it or press 'Preview' to test the crossfade")
            self:SetTextColor(Color(235, 145, 120))
        end
    end

    for i, k in ipairs(SLIDERS) do
        local key, label = k.key, k.label
        local syncing = false
        local s = scroll:Add("DNumSlider")
        s:Dock(TOP) s:DockMargin(2, 2, 2, 0)
        s:SetMinMax(0, 100) s:SetDecimals(0)
        s:SetValue(TARDIS.TeleportCrossfadeOverride[key])
        s.Label:SetMouseInputEnabled(true) s.Label:SetTooltip(k.help)
        -- Fixed label + compact value box so the track fills the middle; the stock DNumSlider proportions
        -- both to the width, leaving dead space.
        ---@param w number
        ---@param h number
        function s:PerformLayout(w, h)
            local lw, nw = 130, 26
            self.Label:SetPos(0, 0) self.Label:SetSize(lw, h)
            self.TextArea:SetPos(w - nw, 0) self.TextArea:SetSize(nw, h)
            self.Slider:SetPos(lw, 0) self.Slider:SetSize(w - lw - nw - 4, h)
        end
        ---@param v number
        function s:OnValueChanged(v)
            -- Only real player slider changes should update, ignore managed syncs
            if syncing or not TARDIS.TeleportCrossfadeOverride.active then return end
            TARDIS.TeleportCrossfadeOverride[key] = math.Round(v)
            TARDIS.TeleportCrossfadeOverride.dirty = true
        end
        function s:Think()
            local o = TARDIS.TeleportCrossfadeOverride
            self:SetEnabled(o.active)
            local ext = LocalPlayer():GetTardisExterior()

            local target = o[key]
            -- If the override is off, use the interior's saved settings instead of the override values
            if not o.active and IsValid(ext) then
                target = ext.metadata.Exterior.Teleport.Crossfade[key]
            end
            if target and math.Round(self:GetValue()) ~= target then
                syncing = true
                self:SetValue(target)
                syncing = false
            end

            if IsValid(ext) then
                local secs = ({ ext:GetTeleportCrossfadeTimings() })[i]
                if k.lead and secs ~= 0 then secs = -secs end -- starts sit before the teleport
                self:SetText(string.format("%s  =  %.2fs", label, secs))
            else
                self:SetText(label)
            end
        end
    end

    local brow = scroll:Add("DPanel")
    brow:Dock(TOP) brow:DockMargin(2, 6, 2, 0) brow:SetTall(26)
    brow:SetPaintBackground(false)
    local btns = {}
    ---@param text string
    ---@param tip string
    ---@param fn function
    local function button(text, tip, fn)
        local b = brow:Add("DButton")
        b:SetText(text)
        b:SetTooltip(tip)
        b.DoClick = fn
        btns[#btns + 1] = b
    end
    button("Preview", "Play the crossfade now, without teleporting", preview)
    button("Reset", "Reset the sliders to this interior's saved settings", load_from_interior)
    button("Copy", "Copy the current settings to paste into the interior metadata", copy_metadata)
    ---@param w number
    ---@param h number
    function brow:PerformLayout(w, h)
        local gap, n = 6, #btns
        local bw = (w - gap * (n - 1)) / n
        for i, b in ipairs(btns) do
            b:SetPos((i - 1) * (bw + gap), 0)
            b:SetSize(bw, h)
        end
    end
end)
