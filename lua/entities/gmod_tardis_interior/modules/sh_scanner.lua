-- Scanner

local function UpdateScannerState(self)
    local state = false
    for k,_ in pairs(self.scanners) do
        if self:GetData("scanners_on_"..k, false) then
            state = true
            break
        end
    end
    local oldstate = self:GetData("scanners_on", false)
    self:SetData("scanners_on", state, true)
    if state ~= oldstate then
        self:CallHook("ScannersToggled", state)
        self:CallHook("PostScannersToggled", state)
    end
end

function ENT:GetScannersOn()
    return self:GetData("scanners_on", false)
end

function ENT:GetScannerOn(id)
    return self:GetData("scanners_on_"..id, false)
end

if SERVER then
    function ENT:SetScannersOn(on)
        if not on and self:CallHook("CanTurnOffScanners")==false then
            return false
        end
        if on and self:CallHook("CanTurnOnScanners")==false then
            return false
        end
        for k,_ in pairs(self.scanners) do
            self:SetData("scanners_on_"..k, on, true)
            self:CallHook("ScannerToggled", k, on)
        end
        UpdateScannerState(self)
        return true
    end

    function ENT:SetScannerOn(id, on)
        if not on and (self:CallHook("CanTurnOffScanners")==false or self:CallHook("CanTurnOffScanner", id)==false) then
            return false
        end
        if on and (self:CallHook("CanTurnOnScanners")==false or self:CallHook("CanTurnOnScanner", id)==false) then
            return false
        end
        self:SetData("scanners_on_"..id, on, true)
        self:CallHook("ScannerToggled", id, on)
        UpdateScannerState(self)
        return true
    end

    function ENT:ToggleScanners()
        return self:SetScannersOn(not self:GetScannersOn())
    end

    function ENT:ToggleScanner(id)
        return self:SetScannerOn(id, not self:GetScannerOn(id))
    end

    ENT:AddHook("ScannerToggled", "scanner", function(self, id, on)
        local scanner = self.scanners[id]
        if scanner and scanner.submatid then
            scanner.ent:SetSubMaterial(scanner.submatid, on and "!"..scanner.uid or "")
        end
    end)

    ENT:AddHook("PowerToggled", "scanner", function(self, on)
        if on and self:GetData("power-lastscanners",false)==true then
            self:SetScannersOn(true)
        else
            self:SetData("power-lastscanners",self:GetScannersOn())
            self:SetScannersOn(false)
        end
    end)

    ENT:AddHook("CanTurnOnScanners", "scanner", function(self)
        if not self:GetPower() then
            return false
        end
    end)
end

ENT:AddHook("Initialize", "scanner", function(self)
    self.scanners = {}
    if self.metadata.Interior.Scanners then
        for k,v in pairs(self.metadata.Interior.Scanners) do
            local scanner = {}
            scanner.uid = "tardisi_scanner_"..self:GetCreationID().."_"..k.."_"..v.width.."_"..v.height.."_"..v.fov

            if SERVER then
                local ent = self
                if v.part then
                    local part = self:GetPart(v.part)
                    if IsValid(part) then
                        ent = part
                    end
                end
                scanner.ent = ent

                local found=false
                for i,mat in ipairs(ent:GetMaterials()) do
                    if mat==v.mat then
                        scanner.submatid = i-1
                        found=true
                        break
                    end
                end
                if not found then
                    ErrorNoHalt("Could not find material "..v.mat.." for scanner on "..ent:GetModel())
                end
            else
                scanner.mat=CreateMaterial(
                    scanner.uid,
                    "UnlitGeneric",
                    {
                        ["$model"] = "1",
                        ["$receiveflashlight"] = "1",
                        ["$nodecal"] = "1"
                    }
                )
                scanner.rt = GetRenderTarget(scanner.uid, v.width, v.height)
                scanner.mat:SetTexture("$basetexture",scanner.rt)
            end
            scanner.ang = v.ang
            scanner.width = v.width
            scanner.height = v.height
            scanner.fov = v.fov
            self.scanners[k] = scanner
        end
    end
end)

if SERVER then return end

ENT:AddHook("ShouldDrawScanners", "scanner", function(self)
    if LocalPlayer():GetTardisData("outside") then
        return false
    end
end)

ENT:AddHook("ShouldDrawScanner", "scanner", function(self, id)
    if not self:GetScannerOn(id) then
        return false
    end
    return true
end)

ENT:AddHook("ShouldDraw", "scanner", function(self)
    if self.scannerrender then
        return false
    end
end)

ENT:AddHook("ShouldNotRenderPortal","scanner",function(self,parent,portal,exit)
    if self.scannerrender and portal==self.portals.interior then
        return true
    end
end)

ENT:AddHook("PreScannerRender", "scanner", function(self)
    for k,_ in pairs(self.props) do
        if IsValid(k) then
            k.olddrawscanner=k:GetNoDraw()
            k:SetNoDraw(true)
        end
    end
end)

ENT:AddHook("PostScannerRender", "scanner", function(self)
    for k,_ in pairs(self.props) do
        if IsValid(k) and k.olddrawscanner~=nil then
            k:SetNoDraw(false)
            k.olddrawscanner=nil
        end
    end
end)
