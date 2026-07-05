-- GUI Settings

TARDIS.GUISettings={}
---@param name string
---@param func function
function TARDIS:AddGUISetting(name,func)
    self.GUISettings[name]=func
end