
-- Base light

---@api
function ENT:GetCustomBaseLightEnabled()
    return self:GetData("interior_custom_base_light_enabled", false)
end

---@api
---@return Color?
function ENT:GetCustomBaseLightColor()
    return self:GetData("interior_custom_base_light_color")
end

function ENT:GetGetBaseLightColorVector()
    return self:GetData("interior_base_light_color_vec")
end

---@api
---@return number?
function ENT:GetCustomBaseLightBrightness()
    return self:GetData("interior_custom_base_light_brightness")
end


if SERVER then
    ---@api
    ---@param enabled boolean
    function ENT:SetCustomBaseLightEnabled(enabled)
        self:SetData("interior_custom_base_light_enabled", enabled or false, true)
    end

    ---@api
    function ENT:ToggleCustomBaseLightEnabled()
        self:SetCustomBaseLightEnabled(not self:GetCustomBaseLightEnabled())
    end

    ---@api
    ---@param color Color
    function ENT:SetCustomBaseLightColor(color)
        self:SetData("interior_custom_base_light_color", color, true)
    end

    ---@api
    ---@param brightness number
    function ENT:SetCustomBaseLightBrightness(brightness)
        self:SetData("interior_custom_base_light_brightness", brightness, true)
    end
else
    ---@return Vector
    function ENT:GetBaseLightColorVector()
        return self:GetData("interior_base_light_color_vec", TARDIS.color_white_vector)
    end

    ---@api
    ---@return Color
    function ENT:GetBaseLightColor()
        return self:GetBaseLightColorVector():ToColor()
    end
    
    ENT:AddHook("Think", "baselight", function(self)
        local lo = self.metadata.Interior.LightOverride
        if not lo then return end

        local power = self:GetPower()

        local normalbr = power and lo.basebrightness or lo.nopowerbrightness
        local normalcolvec = power and lo.basebrightnessRGB or lo.nopowerbrightnessRGB or TARDIS.color_white_vector

        local customcol = self:GetData("interior_custom_base_light_color")
        local custombr = self:GetData("interior_custom_base_light_brightness", normalbr)

        local currentcolvec = self:GetData("interior_base_light_color_vec")
        local targetcolvec
        if self:GetData("interior_custom_base_light_enabled") and customcol then
            targetcolvec = customcol:ToVector() * (custombr or normalbr)
        else
            targetcolvec = normalcolvec * normalbr
        end

        if currentcolvec == targetcolvec then
            return
        elseif not currentcolvec then
            self:SetData("interior_base_light_color_vec", targetcolvec)
            return
        end

        local savedtargetcolvec = self:GetData("interior_base_light_target_color_vec")

        if savedtargetcolvec ~= targetcolvec then
            self:SetData("interior_base_light_target_color_vec", targetcolvec)
            self:SetData("interior_base_light_previous_color_vec", currentcolvec)
            self:SetData("interior_base_light_transition_fraction", 0)
        end

        local prevcolvec = self:GetData("interior_base_light_previous_color_vec", currentcolvec)
        local fraction = self:GetData("interior_base_light_transition_fraction", 0)
        fraction = math.min(fraction + (FrameTime() * lo.transitionspeed), 1)
        
        local colvec = LerpVector(fraction, prevcolvec, targetcolvec)
        
        self:SetData("interior_base_light_color_vec", colvec)
        self:SetData("interior_base_light_transition_fraction", fraction)
    end)
end