-- Scanner

hook.Add("RenderScene", "TARDISI_Scanner", function(pos,ang)
    local int=LocalPlayer():GetTardisData("interior")
    local ext=LocalPlayer():GetTardisData("exterior")
    if IsValid(ext) then
        local scanners = {}
        local screens=TARDIS:ScreenActive("Scanner")
        if screens then
            for _,v in pairs(screens) do
                table.insert(scanners, {rt=v.scanner, ang=v.scannerang, fov=v.scannerfov, width=v.width*v.res, height=v.height*v.res})
            end
        end
        if IsValid(int) and int.scanners then
            local enabled = int:CallHook("ShouldDrawScanners")~=false
            if enabled then
                for k,v in pairs(int.scanners) do
                    local scanner_enabled = int:CallHook("ShouldDrawScanner", k)~=false
                    if scanner_enabled then
                        table.insert(scanners, {rt=v.rt, ang=v.ang, fov=v.fov, width=v.width, height=v.height})
                    end
                end
            end
        end
        for _,v in pairs(scanners) do
            render.PushRenderTarget( v.rt )
                render.Clear( 0, 0, 0, 255, true, true )

                local offset = ext.metadata.Exterior.ScannerOffset
                local vec=Vector(offset.x, offset.y, offset.z)
                vec:Rotate(v.ang)
                local camOrigin = ext:LocalToWorld(vec)
                local camAngle = ext:LocalToWorldAngles(v.ang)
                if IsValid(int) then
                    int.scannerrender=true
                    int:CallHook("PreScannerRender")
                end
                render.RenderView({
                    x = 0,
                    y = 0,
                    w = v.width,
                    h = v.height,
                    fov = v.fov,
                    origin = camOrigin,
                    angles = camAngle,
                    drawpostprocess = true,
                    drawhud = false,
                    drawmonitors = false,
                    drawviewmodel = false,
                    --zfar = 1500
                })
                if IsValid(int) then
                    int.scannerrender=false
                    int:CallHook("PostScannerRender")
                end
            render.PopRenderTarget()
        end
    end
end)
