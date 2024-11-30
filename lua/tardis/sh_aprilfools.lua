CreateConVar("tardis2_aprilfools_2023", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "0: off, 1: on if april 1st, 2: always on", 0, 2)

function TARDIS:IsAprilFools()
    local aprilFools = cvars.Number("tardis2_aprilfools_2023")

    if aprilFools ~= self.aprilFoolsLast then
        self.aprilFoolsLast = aprilFools
        self.aprilFoolsCache = nil
        if CLIENT then
            RunConsoleCommand("spawnmenu_reload")
        end
    end

    if self.aprilFoolsCache ~= nil then
        return self.aprilFoolsCache
    end

    self.aprilFoolsCache = self:IsAprilFoolsInternal(aprilFools)
end

function TARDIS:IsAprilFoolsInternal(aprilFools)
    if aprilFools == 1 and os.date("%d/%m") == "01/04" then
        return true
    elseif aprilFools == 2 then
        return true
    else
        return false
    end
end
