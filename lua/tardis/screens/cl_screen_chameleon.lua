TARDIS:AddScreen("Chameleon", {id="chameleon", text="Screens.Chameleon", menu=false, order=4, popuponly=false}, function(self,ext,int,frame,screen)
    local frW = frame:GetWide()
    local frT = frame:GetTall()

    local gap = math.min(frT, frW) * 0.06
    local gap2 = math.min(frT, frW) * 0.02

    local listW = (frW - 4 * gap) / 3
    local listT = frT - 2 * gap
    local bW = (listW - 4 * gap2) / 3
    local bT = frT * 0.1
    local imW = listW - 2 * gap2
    local imT = listT - 3 * gap2 - bT
    local imS = math.min(imW, imT)
    local gap3 = 0.5 * (listW - imS)

    local background=vgui.Create("DImage", frame)
    local theme = TARDIS:GetScreenGUITheme(screen)
    local background_img = TARDIS:GetGUIThemeElement(theme, "backgrounds", "music")
    background:SetImage(background_img)
    background:SetSize(frW, frT)
    local bgcolor = TARDIS:GetScreenGUIColor(screen)

    local list_exteriors

    if screen.is3D2D then
        list_categories = ListView3D:new(frame,screen,34,bgcolor)
        list_exteriors = ListView3D:new(frame,screen,34,bgcolor)
    else
        list_categories = vgui.Create("DListView",frame)
        list_exteriors = vgui.Create("DListView",frame)
    end

    list_categories:SetSize(listW, listT)
    list_categories:SetPos(gap, gap)
    list_categories:AddColumn(TARDIS:GetPhrase("Screens.Chameleon.Categories"))
    list_categories:SetMultiSelect(false)

    list_exteriors:SetSize(listW, listT)
    list_exteriors:SetPos(listW + 2 * gap, gap)
    list_exteriors:AddColumn(TARDIS:GetPhrase("Screens.Chameleon.Exteriors"))
    list_exteriors:SetMultiSelect(false)

    local panel = vgui.Create( "DPanel", frame )
    panel:SetSize(listW, listT)
    panel:SetPos(2 * listW + 3 * gap, gap)
    panel:SetBackgroundColor(bgcolor)

    local preview3D
    if screen.is3D2D then
        preview3D = vgui.Create("DModelPanel3D2D", panel)
    else
        preview3D = vgui.Create("DAdjustableModelPanel", panel)
    end
    preview3D:SetSize(imS, imS)
    preview3D:SetPos(gap3, gap2)

    local preview = vgui.Create("DImage", panel)
    preview:SetSize(imS, imS)
    preview:SetPos(gap3, gap2)

    local apply = vgui.Create("DButton", panel)
    apply:SetSize(bW, bT)
    apply:SetPos(gap2, listT - gap2 - bT)
    apply:SetText(TARDIS:GetPhrase("Screens.Chameleon.Apply"))
    apply:SetFont(TARDIS:GetScreenFont(screen, "Default"))

    local plan = vgui.Create("DButton", panel)
    plan:SetSize(bW, bT)
    plan:SetPos(2 * gap2 + bW, listT - gap2 - bT)
    plan:SetText(TARDIS:GetPhrase("Screens.Chameleon.Plan"))
    plan:SetFont(TARDIS:GetScreenFont(screen, "Default"))

    local reset = vgui.Create("DButton", panel)
    reset:SetSize(bW, bT)
    reset:SetPos(3 * gap2 + 2 * bW, listT - gap2 - bT)
    reset:SetText(TARDIS:GetPhrase("Screens.Chameleon.Reset"))
    reset:SetFont(TARDIS:GetScreenFont(screen, "Default"))

    local categories = {}
    local exteriors, change_id

    for k,v in pairs(TARDIS:GetExteriorCategories()) do
        if not table.IsEmpty(v) then
            table.insert(categories, k)
        end
    end
    table.sort(categories)

    list_categories:Clear()
    for _,v in ipairs(categories) do
        list_categories:AddLine(TARDIS:GetPhrase(v))
    end

    list_categories:SelectFirstItem()

    local function refresh_exteriors_list()
        exteriors = {}
        local cat_i = list_categories:GetSelectedLine()
        if not cat_i then
            list_exteriors:Clear()
            return
        end
        local cat = categories[cat_i]

        for k,v in pairs(TARDIS:GetExteriors()) do
            if v.Base ~= true and v.Hide ~= true and v.Category == cat then
                table.insert(exteriors, {k, v.Name or v.ID})
            end
        end

        table.SortByMember(exteriors, 2, true)
        list_exteriors:Clear()
        for _,v in ipairs(exteriors) do
            list_exteriors:AddLine(TARDIS:GetPhrase(v[2]))
        end
    end

    refresh_exteriors_list()

    ---@param id string
    local function select_exterior(id)
        change_id = id
        local icon = TARDIS:GetExteriorIcon(id) or TARDIS:GetMissingIcon(TARDIS.IconCategory.Exterior)
        local ext_data = TARDIS:CreateExteriorMetadata(id)

        if not TARDIS:GetSetting("gui_chameleon_3d_preview") then
            preview:SetVisible(icon ~= nil)
            preview3D:SetVisible(false)
            if icon then
                preview:SetImage(icon)
            end
        else
            preview3D:SetVisible(ext_data ~= nil)
            preview:SetVisible(false)
            if ext_data then
                local basemodel = ext_data.Model
                local doorpart = ext_data.Parts.door
                -- the door part is required for a valid exterior, so it is never `false`;
                -- the shaped cast types the fields we read off it
                ---@cast doorpart { model: string?, Model: string?, posoffset: Vector? }
                local doormodel = doorpart.model or doorpart.Model
                local doorpos = ext_data.Portal.pos + (doorpart.posoffset or Vector(0,0,0))
                local textures
                if ext_data.TextureSets then
                    textures = ext_data.TextureSets.normal
                end

                preview3D:SetModel(basemodel)

                modelent = preview3D:GetEntity()

                local mn, mx = modelent:GetModelBounds()
                local size = 0
                size = math.max( size, math.abs(mn.x) + math.abs(mx.x) )
                size = math.max( size, math.abs(mn.y) + math.abs(mx.y) )
                size = math.max( size, math.abs(mn.z) + math.abs(mx.z) )

                preview3D:SetFOV( 30 ) -- these are set here so the camera resets when switching to a new exterior
                preview3D:SetLookAng( Angle(5,193,0) )
                preview3D:SetCamPos( Vector( size*2.2, size/2, size/1.5 ) )

                if textures then -- Apply texturesets if they exist
                    local prefix = textures.prefix or ""
                    for _,v in ipairs(textures) do
                        if v[1] == "self" then
                            modelent:SetSubMaterial(v[2],prefix .. v[3])
                        end
                    end
                end

                if doormodel then
                    local door = preview3D.door
                    if IsValid(door) then
                        door:SetModel(doormodel)
                    else
                        door = ClientsideModel(doormodel)
                        preview3D.door = door
                        if IsValid(door) then door:SetNoDraw(true) end
                    end
                    if IsValid(door) then
                        for i,_ in ipairs(door:GetMaterials()) do
                            door:SetSubMaterial(i-1)
                        end
                        if textures then
                            local prefix = textures.prefix or ""
                            for _,v in ipairs(textures) do
                                if v[1] == "door" then
                                    door:SetSubMaterial(v[2],prefix .. v[3])
                                end
                            end
                        end
                    end
                elseif IsValid(preview3D.door) then
                    preview3D.door:Remove()
                    preview3D.door = nil
                end

                ---@param ent Entity
                function preview3D:PostDrawModel( ent )
                    if not self then return end
                    if not IsValid(self.door) then return end
                    self.door:SetPos(doorpos)
                    self.door:DrawModel()
                end

                function preview3D:OnRemove()
                    if not self then return end
                    if IsValid(self.door) then
                        self.door:Remove()
                        self.door = nil
                    end
                end

                ---@param ent Entity
                function preview3D:LayoutEntity( ent )
                    -- overrides the model constantly spinning
                end
            end
        end

    end
    local function unselect_exterior()
        change_id = nil
        if screen.is3D2D then
            preview:SetVisible(false)
        else
            preview3D:SetVisible(false)
        end
    end

    function list_categories:OnRowSelected(rowIndex, row)
        refresh_exteriors_list()
    end

    function list_categories:OnRowSelectionRemoved(rowIndex, row)
        list_exteriors:Clear()
        unselect_exterior()
    end

    ---@param rowIndex integer
    ---@param row Panel
    function list_exteriors:OnRowSelected(rowIndex, row)
        select_exterior(exteriors[rowIndex][1])
    end

    ---@param rowIndex integer
    ---@param row Panel
    function list_exteriors:OnRowSelectionRemoved(rowIndex, row)
        unselect_exterior()
    end

    function apply:DoClick()
        if change_id ~= nil then
            ext:ChangeExterior(change_id, true, LocalPlayer())
        end
    end

    function plan:DoClick()
        if change_id ~= nil then
            ext:SetData("chameleon_planned_exterior", change_id, true)
            TARDIS:Message(LocalPlayer(), "Chameleon.ExteriorPlanned")
        end
    end

    function reset:DoClick()
        ext:ChangeExterior(nil, true, LocalPlayer())
    end

end)
