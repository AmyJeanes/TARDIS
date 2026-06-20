-- Button Options

---@type table<string, tardis_setting>
TARDIS.ButtonOptions = TARDIS.ButtonOptions or {}

function TARDIS:GetButtonOptions()
    return self.ButtonOptions
end

function TARDIS:AddButtonOption(data)
    data.type = "button"
    self.ButtonOptions[data.id] = data
end
