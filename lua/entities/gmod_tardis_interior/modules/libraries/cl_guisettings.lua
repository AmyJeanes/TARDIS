-- GUI Settings

ENT.GUISettings={}
---@param name string
---@param func function
function ENT:AddGUISetting(name,func)
    self.GUISettings[name]=func
end