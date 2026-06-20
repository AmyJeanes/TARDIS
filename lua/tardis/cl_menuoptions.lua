TARDIS.SpawnmenuOptionsSectionElements = TARDIS.SpawnmenuOptionsSectionElements or {}

function TARDIS:ReloadSpawnmenuOptionElements(section)
    if not section then
        for k,_ in pairs(self.SpawnmenuOptionsSectionElements) do
            self:ReloadSpawnmenuOptionElements(k)
        end
        return true
    else
        if self.SpawnmenuOptionsSectionElements[section] then
            for _,v in ipairs(self.SpawnmenuOptionsSectionElements[section]) do
                if v.RefreshVal then
                    v:RefreshVal()
                end
            end
            return true
        else
            return false
        end
    end
end

---@class tardis_option_entry
---@field id string
---@field data tardis_setting
---@field sort string

hook.Add("PopulateToolMenu", "TARDIS2-PopulateToolMenu", function()
    -- Options
    ---@type tardis_option_entry[]
    local options={}
    local sections={}
    local subsections={}
    for _,v in pairs(TARDIS:GetSettingsData()) do
        if v.option then
            table.insert(options,{id=v.id, data=v, sort=(v.subsection or " ") .. v.name})
            if v.section and not table.HasValue(sections,v.section) then
                table.insert(sections, v.section)
            end
            if v.section and v.subsection then
                local sub = subsections[v.section] or {}
                subsections[v.section] = sub
                sub[v.subsection] = true
            end
        end
    end

    for _,v in pairs(TARDIS:GetButtonOptions()) do
        table.insert(options,{id=v.id, data=v, sort=(v.subsection or " ") .. v.name})
        if v.section and not table.HasValue(sections,v.section) then
            table.insert(sections, v.section)
        end
        if v.section and v.subsection then
            local sub = subsections[v.section] or {}
            subsections[v.section] = sub
            sub[v.subsection] = true
        end
    end

    table.SortByMember(options, "sort", true)
    table.SortByMember(sections, 1, true)

    TARDIS.SpawnmenuOptionsSectionElements = {}

    for _,section in ipairs(sections) do
        local section_id = "TARDIS2_Options_" .. section
        local section_text = " " .. TARDIS:GetPhrase("Settings.Sections."..section)

        local section_elements = {}
        TARDIS.SpawnmenuOptionsSectionElements[section] = section_elements

        spawnmenu.AddToolMenuOption("Options", TARDIS:GetPhrase("Common.TARDIS"), section_id, section_text, "", "", function(panel)
            for _,b in ipairs(options) do
                ---@cast b tardis_option_entry -- glua_ls reads ipairs loop-var fields as nilable
                local id,data=b.id,b.data
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

                        subsection.OnToggle = function(self, is_expanded)
                            local unfolded_setting = TARDIS:GetSetting("options-unfolded-subsections")
                            unfolded_setting[section] = unfolded_setting[section] or {}
                            unfolded_setting[section][data.subsection] = is_expanded
                            TARDIS:SetSetting("options-unfolded-subsections", unfolded_setting)
                        end

                        for _,b2 in ipairs(options) do
                            ---@cast b2 tardis_option_entry -- glua_ls reads ipairs loop-var fields as nilable
                            local id2,data2 = b2.id,b2.data
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

                        for _,v in ipairs(section_elements) do
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
    for _,b in ipairs(options) do
        if not b.data.section then
            others_exist = true
            break
        end
    end

    if others_exist then
        spawnmenu.AddToolMenuOption("Options", TARDIS:GetPhrase("Common.TARDIS"), "TARDIS2_Options_Other", " ".. TARDIS:GetPhrase("Settings.Sections.Other"), "", "", function(panel)
            for _,b in ipairs(options) do
                ---@cast b tardis_option_entry -- glua_ls reads ipairs loop-var fields as nilable
                local id,data=b.id,b.data
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
        local bind_sections={}
        for k,v in pairs(TARDIS:GetBinds()) do
            table.insert(keybinds,{k,v})
            if v.section and not table.HasValue(bind_sections,v.section) then
                table.insert(bind_sections,v.section)
            end
        end
        table.SortByMember(keybinds,1,true)
        table.SortByMember(bind_sections,1,true)

        for _,v in ipairs(bind_sections) do
            local category = vgui.Create("DForm")
            panel:AddItem(category)

            category:SetLabel(TARDIS:GetPhrase("Binds.Sections."..v))
            category:SetExpanded(false)

            for _,b in ipairs(keybinds) do
                ---@cast b tardis_option_entry -- glua_ls reads ipairs loop-var fields as nilable
                local id,data=b.id,b.data
                if data.section == v then
                    local keybind_changer = TARDIS:CreateBindOptionInterface(id, data)
                    category:AddItem(keybind_changer)
                end
            end
        end

        local other_exist = false

        for _,b in ipairs(keybinds) do
            if not b.data.section then
                other_exist = true
                break
            end
        end

        if other_exist then
            local other_category = vgui.Create("DForm")
            panel:AddItem(other_category)
            other_category:SetLabel(TARDIS:GetPhrase("Binds.Sections.Other"))
            other_category:SetExpanded(false)

            for _,b in ipairs(keybinds) do
                ---@cast b tardis_option_entry -- glua_ls reads ipairs loop-var fields as nilable
                local id,data=b.id,b.data
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
        button.DoClick = function()
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
