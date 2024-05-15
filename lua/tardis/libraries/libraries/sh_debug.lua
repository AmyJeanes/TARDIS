-- I often need to run custom code in the TARDIS, this is a template for that
TARDIS.DebugFunction = function(ext,int,ply,cmd,args)
    TARDIS:Debug("Debug function")
    TARDIS:Debug("Exterior:", ext, "")
    TARDIS:Debug("Interior:", int, "")

    if IsValid(ext) then
        -- paste code here
    end

    if IsValid(int) then
        -- paste code here
    end

    if IsValid(ext) and IsValid(int) then
        -- paste code here
    end

    local lext, lint

    if ply.linked_tardis then
        lext = ply.linked_tardis
        lint = lext.interior
    end

    if IsValid(lext) then
        -- paste code here
    end

    if IsValid(lint) then
        -- paste code here
    end

    if IsValid(lext) and IsValid(lint) then
        -- paste code here
    end
end

concommand.Add("tardis2_debug_func", function(ply,cmd,args)
    if not ply:IsAdmin() then return end
    local ext = ply:GetTardisData("exterior")
    local int = ply:GetTardisData("interior")

    TARDIS.DebugFunction(ext,int,ply,cmd,args)
end)

if SERVER then
    util.AddNetworkString("TARDIS_Debug_Convar")
end

local convar_update_funcs = {}

local function CreateBoolDebugConVar(name, desc)
    local id = "tardis2_" .. name
    CreateConVar(id, 0, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, desc)

    local function convar_update()
        TARDIS[name] = GetConVar(id):GetBool()
    end

    cvars.AddChangeCallback(id, function()
        convar_update()

        -- fixing https://github.com/Facepunch/garrysmod-issues/issues/3740
        net.Start("TARDIS_Debug_Convar")
            net.WriteString(id)
        net.Broadcast()
    end)

    convar_update()

    convar_update_funcs[id] = convar_update
end

net.Receive("TARDIS_Debug_Convar", function(name, len, ply)
    local id = net.ReadString()
    if convar_update_funcs[id] then
        convar_update_funcs[id]()
    end
end)

CreateBoolDebugConVar("debug", "TARDIS - debug enabled")
CreateBoolDebugConVar("debug_chat", "TARDIS - print debug to chat as well")
CreateBoolDebugConVar("debug_textures", "TARDIS - print the texture list in TextureSet format")
CreateBoolDebugConVar("debug_tips", "TARDIS - generate tip code when using the part")
CreateBoolDebugConVar("debug_tips_show_all", "TARDIS - show all existing tips (not depending on their text)")

concommand.Add("tardis2_debug_tips_print", function(ply,cmd,args)
    local int = ply:GetTardisData("interior")
    if not IsValid(int) then return end

    print(int.debug_tips_text or "NO TIPS DEBUG TEXT GENERATED")
end)

concommand.Add("tardis2_debug_tips_reset", function(ply,cmd,args)
    local int = ply:GetTardisData("interior")
    if not IsValid(int) then return end

    int.debug_tips_text = nil
end)

TARDIS.DebugTipsFunction = function(self, ply, ...)
    local int = self.interior

    local trace = {
        start = ply:EyePos(),
        endpos = ply:EyePos() + (ply:GetAimVector() * 4096),
        filter = { ply, },
    }

    local trace_res = util.TraceLine(trace)

    if not trace_res.Hit then return end

    int.debug_tips_text = int.debug_tips_text or ""

    local tip_pos = int:WorldToLocal(trace_res.HitPos)
    tip_pos.z = tip_pos.z - 1

    local ent = trace_res.Entity
    local id = ent.TardisPart and ent.ID or nil

    local function sm(x) return math.Round(x,2) end

    local function add_tip_text(pos)
        local tip_string = "{ pos = Vector(" .. sm(pos.x) .. ", " .. sm(pos.y) .. ", " .. sm(pos.z)
        tip_string = tip_string .. "), right = true, down = true, },"

        if id then
            tip_string = id .. " = " .. tip_string
        end

        int.debug_tips_text = int.debug_tips_text .. "    " .. tip_string .. "\n"
    end

    TARDIS:Debug(id or ent, sm(tip_pos.x), sm(tip_pos.y), sm(tip_pos.z))

    local p_pos = int:LocalToWorld(tip_pos)
    if IsValid(int.tip_debug_pointer) then

        if ply:KeyDown(IN_WALK) then
            p_pos = int.tip_debug_pointer:GetPos()
        end

        int.tip_debug_pointer:Remove()
    end

    local p = ents.Create("gmod_tardis_debug_pointer")
    p:SetCreator(ply)
    p:SetPos(p_pos)
    p.Use = function(ptr)
        add_tip_text(int:WorldToLocal(ptr:GetPos()))
        ply:ChatPrint("Added. Use tardis2_debug_tips_print to get the list.")
    end
    p:Spawn()
    p:Activate()
    int:DeleteOnRemove(p)
    int.tip_debug_pointer = p

end

concommand.Add("tardis2_debug_warning", function(ply,cmd,args)
    local ext = ply:GetTardisData("exterior")
    if not IsValid(ext) or not ply:IsAdmin() then return end

    local max = ext:GetHealthMax()

    local dead = ext:IsDead()
    local broken = ext:IsBroken()
    local damaged = ext:IsDamaged()

    if dead then
        ext:ChangeHealth(max)
        ext:SetShieldsLevel(ext:GetShieldsMax(), true)
        ext:SetArtron(TARDIS:GetSetting("artron_energy_max"))
        ext:TogglePower()
        return
    end

    if broken then
        return ext:ChangeHealth(0)
    end

    if damaged and math.abs(ext:GetHealthPercent() - ext.HEALTH_PERCENT_DAMAGED + 1) < 2 then
        return ext:ChangeHealth(max * (ext.HEALTH_PERCENT_BROKEN + 2) / 100)
    end


    if damaged then
        return ext:ChangeHealth(max * (ext.HEALTH_PERCENT_BROKEN - 1) / 100)
    end

    ext:ChangeHealth(max * (ext.HEALTH_PERCENT_DAMAGED - 1) / 100)
end)

concommand.Add("tardis2_debug_health", function(ply,cmd,args)
    local ext = ply:GetTardisData("exterior")
    if not IsValid(ext) or not ply:IsAdmin() then return end
    if not args[1] or not tonumber(args[1]) then return end

    ext:ChangeHealth(tonumber(args[1]))
end)

concommand.Add("tardis2_debug_shields", function(ply,cmd,args)
    local ext = ply:GetTardisData("exterior")
    if not IsValid(ext) or not ply:IsAdmin() then return end
    if not args[1] or not tonumber(args[1]) then return end

    ext:SetShieldsLevel(tonumber(args[1]),true)
end)

concommand.Add("tardis2_debug_power", function(ply,cmd,args)
    local ext = ply:GetTardisData("exterior")
    if not IsValid(ext) or not ply:IsAdmin() then return end

    ext:TogglePower()
end)

concommand.Add("tardis2_debug_ply_pos", function(ply,cmd,args)
    local int = ply:GetTardisData("interior")
    if not IsValid(int) then return end

    print(tostring(int:WorldToLocal(ply:GetPos())))
end)

concommand.Add("tardis2_debug_minmax", function(ply,cmd,args)
    local int = ply:GetTardisData("interior")
    if not IsValid(int) or not ply:IsAdmin() then return end

    int.ExitBox = {
        Min = Vector(-16384, -16384, -16384),
        Max = Vector(16384, 16384, 16384),
    }
    ply:ChatPrint("ExitDistance/Box disabled")

    local function create_pointer(pos)
        local p = ents.Create("gmod_tardis_debug_pointer")
        p:SetCreator(ply)
        p:SetPos(int:LocalToWorld(pos))
        int:DeleteOnRemove(p)
        return p
    end

    local min, max
    if args[1] == "exit" and int.metadata.Interior.ExitBox.Min and int.metadata.Interior.ExitBox.Max then
        min = int.metadata.Interior.ExitBox.Min
        max = int.metadata.Interior.ExitBox.Max
        ply:ChatPrint("Created pointers for T.Interior.ExitBox")
    elseif (args[1] == "size" or not args[1]) and int.metadata.Interior.Size.Min and int.metadata.Interior.Size.Max then
        min = int.metadata.Interior.Size.Min
        max = int.metadata.Interior.Size.Max
        ply:ChatPrint("Created pointers for T.Interior.Size")
    else
        ply:ChatPrint("Min/Max not found, creating two default pointers")
        local hitPos = ply:GetEyeTraceNoCursor().HitPos
        min = int:WorldToLocal(hitPos)
        max = int:WorldToLocal(hitPos + Vector(0,0,100))
    end

    local min_pointer = create_pointer(min)
    local max_pointer = create_pointer(max)
    
    min_pointer:SetOther(max_pointer)
    min_pointer:SetDrawAABox(true)
    min_pointer:Spawn()
    min_pointer:Activate()
    
    max_pointer:Spawn()
    max_pointer:Activate()
end)

if SERVER then
    util.AddNetworkString("TARDIS-Debug")
end

local function chat_print(text)
    if SERVER then
        net.Start("TARDIS-Debug")
            net.WriteString(text)
        net.Broadcast()
    else
        if LocalPlayer() and LocalPlayer().ChatPrint then
            -- this function doesn't exist yet when the game is loading
            LocalPlayer():ChatPrint(text)
        else
            print(text)
        end
    end
end

if CLIENT then
    net.Receive("TARDIS-Debug", function()
        local text=net.ReadString()
        chat_print(text)
    end)
end

function TARDIS:Debug(...)
    if not self.debug then return end

    local args = {...}

    -- nil values are being ignored, so we add them as strings
    for i = 1,table.maxn(args) do
        if args[i] == nil then
            args[i] = "<nil>"
        end
    end

    local SOURCE = (SERVER and "SERVER" or "CLIENT")
    local debug_prefix = "[TARDIS DEBUG] (" .. SOURCE .. ")  :  "
    local debug_table_prefix = "[TARDIS DEBUG :: TABLE OUTPUT] (" .. SOURCE .. ")  :  "

    local tables_to_print = {}

    local full_text = debug_prefix

    if ... == nil or args == nil then
        full_text = full_text .. "<nil>"
    else
        for k,arg in pairs(args) do
            local text
            if istable(arg) then
                table.insert(tables_to_print, arg)
                full_text = full_text .. "<" .. tostring(arg) .. ">  "
            else
                full_text = full_text .. tostring(arg) .. "  "
            end
        end
    end
    print("\n")
    if self.debug_chat then
        if SERVER then print(full_text) end
        chat_print(full_text)
    else
        print(full_text)
    end

    for i,v in ipairs(tables_to_print) do
        print("\n\n" .. debug_table_prefix .. tostring(v) .. ":")
        print("―――――――――――――――――――――――――――――――――――――――――――――――――――")
        PrintTable(v, 1)
        print("―――――――――――――――――――――――――――――――――――――――――――――――――――")
        print("\n")
    end

end

-- shortcut alias
function tardisdebug(...) TARDIS:Debug(...) end