-- Music

if SERVER then
    ---@api
    ---@param ply Player?
    function ENT:PlayMusic(url, ply)
        if url then
            if ply and (not self:CheckSecurity(ply)) then
                TARDIS:Message(ply, "Security.ControlUseDenied")
                return false
            end
            for occupant, _ in pairs(self.occupants) do
                self:SendMessage("play-music", {url}, occupant)
            end

            self.music = url

            return true
        end
    end

    ---@api
    function ENT:StopMusic()
        if self.music then
            for ply, _ in pairs(self.occupants) do
                self:SendMessage("stop-music", nil, ply)
            end
            self.music = nil
        end
    end

    ENT:OnMessage("play-music", function(self, data, ply)
        self:PlayMusic(data[1], ply)
    end)

    ENT:OnMessage("stop-music", function(self, data, ply)
        self:StopMusic()
    end)

    return
end

---@api
---@param network boolean
function ENT:StopMusic(network)
    if IsValid(self.music) then
        if self.music:GetState() == GMOD_CHANNEL_PLAYING then
            TARDIS:Message(LocalPlayer(), "Music.Stopped")
        end
        self.music:Stop()
        self.music = nil
        if network then
            self:SendMessage("stop-music")
        end
    end
end

---@param url string
function ENT:ResolveMusicURL(url)
    if url:find("youtu.be") or url:find("youtube.com") then
        TARDIS:ErrorMessage(LocalPlayer(), "Music.YouTubeNotSupported")
        return nil
    else
        return url
    end
end

---@api
---@param resolved boolean?
function ENT:PlayMusic(url,resolved)
    if not resolved then
        TARDIS:Message(LocalPlayer(), "Music.Loading")
        url=self:ResolveMusicURL(url)
    end
    if url and TARDIS:GetSetting("music-enabled") and TARDIS:GetSetting("sound") then
        self:SendMessage("play-music", {url})
    end
end

ENT:OnMessage("play-music", function(self, data, ply)
    local url = data[1]

    self:StopMusic(false)

    sound.PlayURL(url, "", function(station,errorid,errorname)
        if station then
            station:SetVolume(1)
            station:Play()
            self.music=station
        else
            TARDIS:ErrorMessage(LocalPlayer(), "Music.LoadFailedBass", errorid, errorname)
        end
    end)
end)

ENT:OnMessage("stop-music", function(self, data, ply)
    if self.music then
        self.music:Stop()
        self.music=nil
    end
end)

ENT:AddHook("Think", "music", function(self)
    if IsValid(self.music) then
        self.music:SetVolume(TARDIS:GetSetting("music-volume")/100)
        if not (TARDIS:GetSetting("music-enabled") and TARDIS:GetSetting("sound")) then
            self:StopMusic(false)
        end
    end
end)

ENT:AddHook("OnRemove", "music", function(self)
    if not self:GetData("redecorate", false) then
        self:StopMusic(false)
    end
end)

ENT:AddHook("PlayerExit", "stop-music-on-exit", function(self)
    if self.music and TARDIS:GetSetting("music-exit") then
        self:StopMusic(false)
    end
end)


ENT:AddHook("MigrateData", "music", function(self, parent, parent_data)
    self.music = parent.music
end)
