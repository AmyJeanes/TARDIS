local found=false
local f=file.Find('entities/gmod_door_exterior/*.lua', "LUA")
for _,v in pairs(f) do
    if (SERVER and v=="init.lua") or (CLIENT and v=="cl_init.lua") then
        found=true
    end
end
TARDIS.DoorsFound=found

if CLIENT then
    function TARDIS:ShowDoorsPopup()
        local DoorsFrame=vgui.Create('DFrame')
        DoorsFrame:SetTitle(TARDIS:GetPhrase("Common.DoorsNotInstalled"))
        DoorsFrame:SetSize(ScrW()*0.95, ScrH()*0.95)
        DoorsFrame:SetPos((ScrW() - DoorsFrame:GetWide()) / 2, (ScrH() - DoorsFrame:GetTall()) / 2)
        DoorsFrame:MakePopup()

        local h=vgui.Create('DHTML')
        h:SetParent(DoorsFrame)
        h:SetPos(DoorsFrame:GetWide()*0.005, DoorsFrame:GetTall()*0.03)
        local x,y = DoorsFrame:GetSize()
        h:SetSize(x*0.99,y*0.96)
        h:SetAllowLua(true)
        h:OpenURL('https://amyjeanes.com/abyss/doors-warning.html')
        TARDIS.DoorsFrame=DoorsFrame
    end
end

timer.Simple(5,function()
    if not found and not TARDIS.DoorsFrame then
        if CLIENT then
            TARDIS:ShowDoorsPopup()
        elseif SERVER then
            timer.Create("Doors-NotInstalled", 10, 0, function() print(TARDIS:GetPhrase("Common.DoorsNotInstalled")) end)
        end
    end
end)