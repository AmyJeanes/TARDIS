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
    return IsValid(self.exterior) and self.exterior:GetData(k, default) or default
end

function ENT:ClearData()
    self.exterior:ClearData()
end