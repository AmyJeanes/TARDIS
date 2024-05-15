hook.Add("PopulateToolMenu", "TARDIS2-PopulateToolMenu", function()
    -- Options
    local options={}
    local sections={}
    local subsections={}
    for k,v in pairs(TARDIS:GetSettingsData()) do
        if v.option then
            table.insert(options,{v.id, v, (v.subsection or " ") .. v.name})
            if v.section and not table.HasValue(sections,v.section) then
                table.insert(sections, v.section)
            end
            if v.section and v.subsection then
                subsections[v.section] = subsections[v.section] or {}
                subsections[v.section][v.subsection] = true
            end
        end
    end

    table.SortByMember(options, 3, true)
    table.SortByMember(sections, 1, true)

    for k,section in ipairs(sections) do
        local section_id = "TARDIS2_Options_" .. section
        local section_text = " " .. TARDIS:GetPhrase("Settings.Sections."..section)

        local section_elements = {}

        spawnmenu.AddToolMenuOption("Options", TARDIS:GetPhrase("Common.TARDIS"), section_id, section_text, "", "", function(panel)
            for a,b in ipairs(options) do
                local id,data=b[1],b[2]
                if data.section == section then
                    if not data.subsection then
                        local el1,el2 = TARDIS:CreateOptionInterface(id, data)
                        panel:AddItem(el1)
                        table.insert(section_elements, el1)
                        if el2 then panel:AddItem(el2) end
                    end

                    if data.subsection and subsections[section]
                        and subsections[section][data.subsection]
                    then
                        local unfolded_subsections = TARDIS:GetSetting("options-unfolded-subsections")
                        local expanded = true
                        if unfolded_subsections[section] then
                            expanded = unfolded_subsections[section][data.subsection]
                        end

                        local subsection = vgui.Create("DForm")
                        subsection:SetLabel(TARDIS:GetPhrase("Settings.Sections."..section.."."..data.subsection))

                        -- save the subsection state for more convenience
                        subsection:SetExpanded(expanded)

                        subsection.OnToggle = function(self, expanded)
                            local unfolded_subsections = TARDIS:GetSetting("options-unfolded-subsections")
                            unfolded_subsections[section] = unfolded_subsections[section] or {}
                            unfolded_subsections[section][data.subsection] = expanded
                            TARDIS:SetSetting("options-unfolded-subsections", unfolded_subsections)
                        end

                        for a2,b2 in ipairs(options) do
                            local id2,data2 = b2[1],b2[2]
                            if data2.section == section and data2.subsection == data.subsection then
                                local el1,el2 = TARDIS:CreateOptionInterface(id2, data2)
                                subsection:AddItem(el1)
                                table.insert(section_elements, el1)
                                if el2 then subsection:AddItem(el2) end
                            end
                        end

                        panel:AddItem(subsection)

                        local spacer = vgui.Create("DPanel")
                        spacer:SetTall(2)
                        panel:AddItem(spacer)

                        subsections[section][data.subsection] = false
                    end
                end
            end

            local reset_button = vgui.Create("DButton")
            reset_button:SetText(TARDIS:GetPhrase("MenuOptions.SectionResetThisSection"))
            reset_button.DoClick = function(self)
                Derma_Query(
                    TARDIS:GetPhrase("MenuOptions.ConfirmSectionReset", "Settings.Sections."..section),
                    TARDIS:GetPhrase("Common.Interface"),
                    TARDIS:GetPhrase("Common.OK"), function()
                        TARDIS:ResetSectionSettings(section)
                        TARDIS:Message(LocalPlayer(), "MenuOptions.SectionReset", "Settings.Sections."..section)

                        for i,v in ipairs(section_elements) do
                            if v.RefreshVal then
                                v:RefreshVal()
                            end
                        end
                        RunConsoleCommand("spawnmenu_reload")
                    end,
                    TARDIS:GetPhrase("Common.Cancel"), nil
                ):SetSkin("TARDIS")
            end
            panel:AddItem(reset_button)
        end)
    end

    local others_exist = false
    for a,b in ipairs(options) do
        if not b[2].section then
            others_exist = true
            break
        end
    end

    if others_exist then
        spawnmenu.AddToolMenuOption("Options", TARDIS:GetPhrase("Common.TARDIS"), "TARDIS2_Options_Other", " ".. TARDIS:GetPhrase("Settings.Sections.Other"), "", "", function(panel)
            for a,b in ipairs(options) do
                local id,data=b[1],b[2]
                if not data.section then
                    local option_changer = TARDIS:CreateOptionInterface(id, data)
                    panel:AddItem(option_changer)
                end
            end

            local reset_button = vgui.Create("DButton")
            reset_button:SetText(TARDIS:GetPhrase("MenuOptions.SectionResetThisSection"))
            reset_button.DoClick = function(self)
                Derma_Query(
                    TARDIS:GetPhrase("MenuOptions.ConfirmSectionReset", "Settings.Sections.Other"),
                    TARDIS:GetPhrase("Common.Interface"),
                    TARDIS:GetPhrase("Common.OK"), function()
                        TARDIS:ResetSectionSettings(nil)
                        TARDIS:Message(LocalPlayer(), "MenuOptions.SectionReset", "Settings.Sections.Other")
                        RunConsoleCommand("spawnmenu_reload")
                    end,
                    TARDIS:GetPhrase("Common.Cancel"), nil
                ):SetSkin("TARDIS")
            end
            panel:AddItem(reset_button)
        end)
    end

    -- Binds
    spawnmenu.AddToolMenuOption("Options", TARDIS:GetPhrase("Common.TARDIS"), "TARDIS2_Binds", " "..TARDIS:GetPhrase("Settings.Sections.Binds"), "", "", function(panel)
        local keybinds={}
        local sections={}
        for k,v in pairs(TARDIS:GetBinds()) do
            table.insert(keybinds,{k,v})
            if v.section and not table.HasValue(sections,v.section) then
                table.insert(sections,v.section)
            end
        end
        table.SortByMember(keybinds,1,true)
        table.SortByMember(sections,1,true)

        for k,v in ipairs(sections) do
            local category = vgui.Create("DForm")
            panel:AddItem(category)

            category:SetLabel(TARDIS:GetPhrase("Binds.Sections."..v))
            category:SetExpanded(false)

            for a,b in ipairs(keybinds) do
                local id,data=b[1],b[2]
                if data.section == v then
                    local keybind_changer = TARDIS:CreateBindOptionInterface(id, data)
                    category:AddItem(keybind_changer)
                end
            end
        end

        local other_exist = false

        for a,b in ipairs(keybinds) do
            if not b[2].section then
                other_exist = true
                break
            end
        end

        if other_exist then
            local other_category = vgui.Create("DForm")
            panel:AddItem(other_category)
            other_category:SetLabel(TARDIS:GetPhrase("Binds.Sections.Other"))
            other_category:SetExpanded(false)

            for a,b in ipairs(keybinds) do
                local id,data=b[1],b[2]
                if not data.section then
                    local keybind_changer = TARDIS:CreateBindOptionInterface(id, data)
                    other_category:AddItem(keybind_changer)
                end
            end
        end
    end)

    -- Reset all
    spawnmenu.AddToolMenuOption("Options", TARDIS:GetPhrase("Common.TARDIS"), "TARDIS2_Reset_Settings", " "..TARDIS:GetPhrase("MenuOptions.ResetAllSettings"), "", "", function(panel)
        local button = vgui.Create("DButton")
        button:SetText(TARDIS:GetPhrase("MenuOptions.ResetClientsideSettings"))
        button.DoClick = function(button)
            Derma_Query(
                TARDIS:GetPhrase("MenuOptions.ConfirmResetSettings"),
                TARDIS:GetPhrase("Common.Interface"),
                TARDIS:GetPhrase("Common.OK"), function()
                    TARDIS:ResetSettings()
                    TARDIS:Message(LocalPlayer(), "MenuOptions.ResetSettingsConfirmation")
                    RunConsoleCommand("spawnmenu_reload")
                end,
                TARDIS:GetPhrase("Common.Cancel"), nil
            ):SetSkin("TARDIS")
        end
        panel:AddItem(button)
    end)
end)
