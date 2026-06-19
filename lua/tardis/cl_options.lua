-- Options

function TARDIS:CreateOptionInterface(id, data)

    local section = "Settings.Sections."..(data.section or "Other")
    local subsection = data.subsection and section .. "." .. data.subsection or section
    local name = subsection .. "." .. (data.name or id)
    local desc = name .. ".Description"
    local text = TARDIS:GetPhrase(name)
    local tooltip = TARDIS:GetPhraseIfExists(desc) or ""
    if data.value ~= nil then
        tooltip = tooltip .. "\n\n".. TARDIS:GetPhrase("Common.Default") .. ": " .. tostring(data.value)
    end

    local elem
    local elem2 = nil

    if data.type == "bool" then
        elem = vgui.Create("DCheckBoxLabel")
        function elem:OnChange(val)
            TARDIS:SetSetting(id, val)
            self.lastchange = CurTime()
        end
        elem.Think = function(self)
            if self.lastchange and CurTime() - self.lastchange > 0.2 then
                self.lastchange = nil
                self:SetChecked(TARDIS:GetSetting(id))
            end
        end

        elem.RefreshVal = function(self)
            local setting = TARDIS:GetSetting(id)
            elem:SetChecked(setting)
        end



    elseif data.type == "number" or data.type == "integer" then
        elem = vgui.Create("DLabel")

        elem2 = vgui.Create("DNumSlider")
        elem2:SetMinMax(data.min, data.max)
        elem2.Label:SetVisible(false)

        elem.Scratch = elem:Add( "DNumberScratch" )
        elem.Scratch:SetImageVisible( false )
        elem.Scratch:Dock( FILL )
        elem.Scratch:SetMin(data.min)
        elem.Scratch:SetMax(data.max)
        elem.Scratch.OnValueChanged = function()
            elem2:ValueChanged(elem.Scratch:GetFloatValue())
        end

        if data.type == "integer" then
            elem2:SetDecimals(0)
            elem.Scratch:SetDecimals(0)
        end

        elem2.OnValueChanged = function(self, val)
            self.lastchange = CurTime()
            self.lastchange_val = val
        end
        elem2.Think = function(self)
            if self.lastchange_val and CurTime() - self.lastchange > 0.1 then
                TARDIS:SetSetting(id, self.lastchange_val)
                self.lastchange_val = nil
            end
            if self.lastchange and CurTime() - self.lastchange > 0.3 then
                self.lastchange = nil
                self:SetValue(TARDIS:GetSetting(id))
                self:GetTextArea():SetText(tostring(TARDIS:GetSetting(id)))
            end
        end

        elem.RefreshVal = function(self)
            local setting = TARDIS:GetSetting(id)
            elem2:SetValue(setting)
            elem.Scratch:SetValue(setting)
            elem2:GetTextArea():SetText(tostring(setting))
        end



    elseif data.type=="color" then
        elem = vgui.Create("DForm")
        elem:SetLabel(text)
        elem:SetExpanded(true)

        local mixer = vgui.Create("DColorMixer")
        mixer:SetText(text)
        mixer:SetPalette(false)
        mixer:SetAlphaBar(false)
        mixer:SetWangs(true)

        mixer.ValueChanged = function(self, val)
            TARDIS:SetSetting(id, val)
            self.lastchange = CurTime()
        end
        elem.Think = function(self)
            if self.lastchange and CurTime() - self.lastchange > 0.2 then
                self.lastchange = nil
                self:SetColor(TARDIS:GetSetting(id))
            end
        end

        elem:AddItem(mixer)

        local spacer = vgui.Create("DPanel")
        spacer:SetTall(2)
        elem:AddItem(spacer)

        elem.RefreshVal = function(self)
            local setting = TARDIS:GetSetting(id)
            mixer:SetColor(setting)
        end



    elseif data.type=="list" then
        elem = vgui.Create("DLabel")

        elem2 = vgui.Create("DComboBox")

        if data.sort ~= nil then
            elem2:SetSortItems(data.sort)
        end

        if data.get_values_func ~= nil then
            for _,v in pairs(data.get_values_func()) do
                elem2:AddChoice(TARDIS:GetPhrase(v[1]), v[2])
            end
        end

        tooltip = tooltip .. " (\"" .. elem2:GetOptionTextByData(data.value) .. "\")"

        elem2.OnSelect = function(self, index, value, selected_data)
            TARDIS:SetSetting(id, selected_data)
            self.lastchange = CurTime()
        end
        elem2.Think = function(self)
            if self.lastchange and CurTime() - self.lastchange > 0.2 then
                self.lastchange = nil
                local setting = TARDIS:GetSetting(id)
                self:SetText(self:GetOptionTextByData(setting))
            end
        end

        elem.RefreshVal = function(self)
            local setting = TARDIS:GetSetting(id)
            elem2:SetText(elem2:GetOptionTextByData(setting))
        end

    elseif data.type=="button" then
        elem = vgui.Create("DButton")
        elem:SetText(text)
        elem.DoClick = function(self)
            if data.func then
                data.func(TARDIS)
            end
        end
        elem.RefreshVal = function(self) end
    else
        elem = vgui.Create("DLabel")
        elem.RefreshVal = function(self) end
    end

    if elem.SetText then elem:SetText(text) end
    if elem.SetDark then elem:SetDark(true) end
    if elem2 and elem2.SetDark then elem2:SetDark(true) end

    elem:SetTooltip(tooltip)
    if elem2 then
        elem2:SetTooltip(tooltip)
    end

    elem:RefreshVal()

    return elem, elem2
end
