-- VGUI overrides

local function number_ok(pnl, text)
    return (not pnl:GetNumeric()) or (text == "") or (tonumber(text) ~= nil)
end

local textpnl
local function RequestInput( pnl )
    if not textpnl then
        textpnl=pnl
        local old_text = pnl:GetText()
        Derma_StringRequest(TARDIS:GetPhrase("Common.Interface"),
            pnl.sub3D2D or pnl.strTooltipText or TARDIS:GetPhrase("Common.EnterTextInput"),
            pnl:GetText(),
            function(text)
                if text ~= old_text and number_ok(pnl, text) then
                    pnl:SetText(text)
                    pnl:OnTextChanged()
                    pnl:OnChange()
                end
                pnl:SetCaretPos(0)
                pnl:OnEnter()
                textpnl=nil
            end,
            function()
                textpnl=nil
            end
        )
    end
end

local old=vgui.GetControlTable("DTextEntry")
local tbl={}
tbl.Init = function(self,...)
    old.Init(self,...)
    self.OldOnMousePressed = self.OnMousePressed
    self.OnMousePressed = function(self,key)
        if self.is3D2D and self:IsEnabled() then
            RequestInput(self)
        end
        self:OldOnMousePressed(key)
    end
end
vgui.Register( "DTextEntry3D2D", tbl, "DTextEntry" )

local dmodel=vgui.GetControlTable("DModelPanel")
local dmodel_tbl={}

local function ensure_rt(self, w, h)
    w = math.max(math.floor(w or 0), 1)
    h = math.max(math.floor(h or 0), 1)

    if self.rt and self.rt_w == w and self.rt_h == h then return end

    self.rt_w, self.rt_h = w, h
    local name = "tardis_dmodelpanel3d2d_rt_" .. util.CRC(tostring(self) .. "_" .. w .. "x" .. h)

    -- RT with a dedicated depth surface to ensure depth testing works inside 3D2D
    self.rt = GetRenderTargetEx(name, w, h, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_SEPARATE, 0, CREATERENDERTARGETFLAGS_UNFILTERABLE_OK, IMAGE_FORMAT_BGRA8888)

    if not self.rtmat then
        self.rtmat = CreateMaterial("tardis_dmodelpanel3d2d_mat_" .. util.CRC(name), "UnlitGeneric", {
            ["$vertexcolor"] = 1,
            ["$vertexalpha"] = 1,
        })
    end

    self.rtmat:SetTexture("$basetexture", self.rt)
end

dmodel_tbl.Init = function(self,...)
    dmodel.Init(self,...)
    self.rt = nil
    self.rtmat = nil
    self.rt_w = 0
    self.rt_h = 0
end

function dmodel_tbl:DrawModel()
    local ret = self:PreDrawModel(self.Entity)
    if ret ~= false then
        self.Entity:DrawModel()
        self:PostDrawModel(self.Entity)
    end
end

function dmodel_tbl:Paint( w, h )
    if not IsValid( self.Entity ) then return end

    ensure_rt(self, w, h)

    self:LayoutEntity( self.Entity )

    local ang = self.aLookAngle
    if ( not ang ) then
        ang = ( self.vLookatPos - self.vCamPos ):Angle()
    end

    -- GMod doesn't expose a getter for the current viewport, so restore to the full screen after drawing
    local vx, vy, vw, vh = 0, 0, ScrW(), ScrH()

    render.PushRenderTarget(self.rt)
        render.Clear(0, 0, 0, 0, true, true)
        render.SetViewPort(0, 0, self.rt_w, self.rt_h)

        render.SuppressEngineLighting( true )
        render.SetLightingOrigin( self.Entity:GetPos() )
        render.ResetModelLighting( self.colAmbientLight.r / 255, self.colAmbientLight.g / 255, self.colAmbientLight.b / 255 )
        render.SetColorModulation( self.colColor.r / 255, self.colColor.g / 255, self.colColor.b / 255 )
        render.SetBlend( ( self:GetAlpha() / 255 ) * ( self.colColor.a / 255 ) )

            render.ClearDepth() -- avoid stale depth causing odd ordering

            -- Use a nearer near-plane to reduce clipping on close-up previews
            local nearz = 1
            local farz = self.FarZ

            cam.Start3D( self.vCamPos, ang, self.fFOV, 0, 0, self.rt_w, self.rt_h, nearz, farz )
                for i = 0, 6 do
                    local col = self.DirectionalLight[ i ]
                    if ( col ) then
                        render.SetModelLighting( i --[[@as BOX]], col.r / 255, col.g / 255, col.b / 255 )
                    end
                end

                render.OverrideDepthEnable(false, false)
                cam.IgnoreZ(true)

                self:DrawModel()
            render.OverrideDepthEnable(false, false)
            cam.IgnoreZ(false)
            cam.End3D()

        render.SuppressEngineLighting( false )
    render.PopRenderTarget()

    render.SetViewPort(vx, vy, vw, vh)

    surface.SetMaterial(self.rtmat)
    surface.SetDrawColor(255,255,255,255)
    surface.DrawTexturedRect(0, 0, w, h)

    self.LastPaint = RealTime()
end

function dmodel_tbl:OnRemove()
    if dmodel.OnRemove then
        dmodel.OnRemove(self)
    end
    self.rt = nil
    self.rtmat = nil
end

vgui.Register( "DModelPanel3D2D", dmodel_tbl, "DModelPanel" )
