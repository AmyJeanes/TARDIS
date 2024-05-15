function TARDIS:GetExteriorIcon(id)

    local icon = nil

    local function try_ext_icon(filename)
        if icon ~= nil then return end
        if file.Exists("materials/vgui/entities/tardis/exteriors/" .. filename, "GAME") then
            icon = "vgui/entities/tardis/exteriors/" .. filename
        end
    end

    try_ext_icon("" .. id .. ".vmt")
    try_ext_icon("" .. id .. ".vtf")
    try_ext_icon("" .. id .. ".png")
    try_ext_icon("" .. id .. ".jpg")

    -- we don't have default icons in the main addon, but I want them supported for the future
    try_ext_icon("default/" .. id .. ".vmt")
    try_ext_icon("default/" .. id .. ".vtf")
    try_ext_icon("default/" .. id .. ".png")
    try_ext_icon("default/" .. id .. ".jpg")

    return icon
end

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

    local midX = 3 * gap + 2 * listW

    local background=vgui.Create("DImage", frame)
    local theme = TARDIS:GetScreenGUITheme(screen)
    local background_img = TARDIS:GetGUIThemeElement(theme, "backgrounds", "music")
    background:SetImage(background_img)
    background:SetSize(frW, frT)
    local bgcolor = TARDIS:GetScreenGUIColor(screen)

    local list_exteriors
    local list_custom

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
    for k,v in ipairs(categories) do
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
        for i,v in ipairs(exteriors) do
            list_exteriors:AddLine(TARDIS:GetPhrase(v[2]))
        end
    end

    refresh_exteriors_list()

    local function select_exterior(id)
        change_id = id
        local icon = TARDIS:GetExteriorIcon(id)

        preview:SetVisible(icon ~= nil)
        if icon then
            preview:SetImage(icon)
        end
    end
    local function unselect_exterior()
        change_id = nil
        preview:SetVisible(false)
    end

    function list_categories:OnRowSelected(rowIndex, row)
        refresh_exteriors_list()
    end

    function list_categories:OnRowSelectionRemoved(rowIndex, row)
        list_exteriors:Clear()
        unselect_exterior()
    end

    function list_exteriors:OnRowSelected(rowIndex, row)
        select_exterior(exteriors[rowIndex][1])
    end

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