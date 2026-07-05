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

---@api
function ENT:GetScannersOn()
    return self:GetData("scanners_on", false)
end

---@api
---@param id integer
function ENT:GetScannerOn(id)
    return self:GetData("scanners_on_"..id, false)
end

if SERVER then
    ---@api
    ---@param on boolean
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

    ---@api
    ---@param id integer
    ---@param on boolean
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

    ---@api
    function ENT:ToggleScanners()
        return self:SetScannersOn(not self:GetScannersOn())
    end

    ---@api
    ---@param id integer
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
                local part = v.part and self:GetPart(v.part)
                local ent = IsValid(part) and part or self
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
    -- The scanner shows the outside world, so none of the interior's own portals
    -- (interior door, false worlds, custom portals) belong in its view.
    if self.scannerrender and portal:GetParent()==self then
        return true
    end
end)

-- The scanner shows the outside world, so hide the interior's props for its render
ENT:AddHook("PreScannerRender", "scanner", function(self)
    self.cordonhidden = true
end)

ENT:AddHook("PostScannerRender", "scanner", function(self)
    self.cordonhidden = false
end)
