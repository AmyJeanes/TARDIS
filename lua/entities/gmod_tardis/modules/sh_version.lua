-- Version

ENT:AddHook("Initialize", "version", function(self)
    if CLIENT and LocalPlayer()~=self:GetCreator() then return end

    if TARDIS:IsNewVersion() then
        local newVersion = TARDIS:GetVersion()
        local newVersionStr = TARDIS:GetVersionString(newVersion)

        local oldVersion = TARDIS:GetLastUsedVersion()
        local oldVersionStr = TARDIS:GetVersionString(oldVersion)
        
        self:CallCommonHook("NewVersion", newVersion, newVersionStr, oldVersion, oldVersionStr)
    end

    TARDIS:SetLastUsedVersion()
end)

if SERVER then return end

local function get_release_notes(version, newVersion)
    local show = TARDIS:GetSetting("show_release_notes")
    if not show then return end
    local headers = {
        ["X-GitHub-Api-Version"] = "2022-11-28"
    }
    local function onsuccess(body, size, headers, code)
        if code ~= 200 then
            print("Failed to retrieve TARDIS release notes for " .. version .. ", code: " .. code .. ", body: " .. body)
            return
        end
        local data = util.JSONToTable(body)
        local release_notes = data.body
        local json = string.match(release_notes, "<!%-%-(.-)%-%->")
        if not json then return end
        local releaseMetadata = util.JSONToTable(json)
        if releaseMetadata.showPopup and releaseMetadata.summary then
            local notes = releaseMetadata.summary
            if releaseMetadata.changes then
                notes = notes .. "\n"
                for k,v in ipairs(releaseMetadata.changes) do
                    notes = notes .. "\n" .. "• ".. v
                end
            end
            Derma_Query(
                TARDIS:GetPhrase("Update.Updated", newVersion) .. "\n\n" .. notes .. "\n\n" .. TARDIS:GetPhrase("Update.ShowReleaseNotes"),
                "TARDIS Update",
                TARDIS:GetPhrase("Common.Yes"),
                function()
                    gui.OpenURL(data.html_url)
                end,
                TARDIS:GetPhrase("Common.No"),
                function() end,
                TARDIS:GetPhrase("Update.NeverShow"),
                function()
                    TARDIS:SetSetting("show_release_notes", false)
                end
            )
        end
    end
    local function onfailure(reason)
        print("Failed to retrieve TARDIS release notes for " .. version .. ": " .. reason)
    end
    http.Fetch("https://api.github.com/repos/MattJeanes/TARDIS/releases/tags/" .. version, onsuccess, onfailure, headers)
end

ENT:AddHook("NewVersion", "version", function(self, newVersion, newVersionStr, oldVersion, oldVersionStr)
    if oldVersion.Major == newVersion.Major and oldVersion.Minor == newVersion.Minor then
        return -- only show release notes for major/minor version changes
    end

    -- always show release notes for the first update of a new major/minor version

    -- this ensures users see the new changes and not the subsequent bug fixes to them
    -- improvements added in patch versions will be retroactively added to the release notes
    -- for the first update of a new major/minor version so users see them, however
    -- this should be relatively uncommon as patch versions are usually just bug fixes
    
    local version = table.Copy(newVersion)
    version.Patch = 0 
    local versionStr = TARDIS:GetVersionString(version)
    get_release_notes(versionStr, newVersionStr)
end)
