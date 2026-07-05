-- Round things (light sprites for old default interior)

if CLIENT then
    ---@param pos Vector
    function ENT:AddRoundThing(pos)
        self.roundthings[pos]=util.GetPixelVisibleHandle()
    end

    ENT:AddHook("Initialize", "lights-roundthings", function(self)
        if self.metadata.Interior.RoundThings then
            self.roundthingmat=Material("sprites/light_ignorez")
            self.roundthings={}
            for _,v in pairs(self.metadata.Interior.RoundThings) do
                self:AddRoundThing(v)
            end
        end
    end)

    local size=32
    ENT:AddHook("Draw", "lights-roundthings", function(self)
        if self.roundthings then
            if self:CallHook("ShouldDrawLight")==false then return end
            for k,v in pairs(self.roundthings) do
                local pos = self:LocalToWorld(k)
                local vis = util.PixelVisible(pos, 3, v)*255
                if vis > 0 then
                    render.SetMaterial(self.roundthingmat)
                    render.DrawSprite(pos, size, size, Color(255,153,0, vis))
                end
            end
        end
    end)
end
