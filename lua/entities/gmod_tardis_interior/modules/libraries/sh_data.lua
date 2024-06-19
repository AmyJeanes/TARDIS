-- Data

if SERVER then
    function ENT:SendData(ply)
        self.exterior:SendData(ply)
    end
end

function ENT:SetData(k,v,network)
    return IsValid(self.exterior) and self.exterior:SetData(k, v, network)
end

function ENT:GetData(k,default)
    if IsValid(self.exterior) then
        return self.exterior:GetData(k, default)
    else
        return default
    end
end

function ENT:ClearData()
    self.exterior:ClearData()
end