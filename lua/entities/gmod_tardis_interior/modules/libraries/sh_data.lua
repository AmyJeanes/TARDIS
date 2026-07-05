-- Data

if SERVER then
    ---@param ply Player? nil broadcasts to all players
    function ENT:SendData(ply)
        self.exterior:SendData(ply)
    end
end

---@api
---@generic T
---@param key string
---@param value T
---@param network? boolean
---@return T|false
function ENT:SetData(key,value,network)
    return IsValid(self.exterior) and self.exterior:SetData(key, value, network)
end

---@api
---@generic T
---@param key string
---@param default? T
---@return T
function ENT:GetData(key,default)
    if IsValid(self.exterior) then
        return self.exterior:GetData(key, default)
    else
        return default
    end
end

function ENT:ClearData()
    self.exterior:ClearData()
end