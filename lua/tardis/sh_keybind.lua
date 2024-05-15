-- Key bind system (inspired by WAC)

if SERVER then
    util.AddNetworkString("TARDIS-KeyBind")

    TARDIS.binds=TARDIS.binds or {}

    net.Receive("TARDIS-KeyBind", function(_,ply)
        local ext=ply:GetTardisData("exterior")
        local int=ply:GetTardisData("interior")
        if IsValid(ext) then
            local id=net.ReadString()
            if TARDIS.binds[id] then
                local bind=TARDIS.binds[id]
                local b=net.ReadBool()
                bind.b[ply]=b
                if bind.func then
                    if bind.exterior then
                        bind.func(ext,b,ply)
                    end
                    if IsValid(int) and bind.interior then
                        bind.func(int,b,ply)
                    end
                end
            end
        end
    end)

    function TARDIS:AddKeyBind(id,data)
        if not data.clientonly then
            self.binds[id]=table.Copy(data)
            self.binds[id].b={}
        end
    end

    function TARDIS:IsBindDown(ply,id)
        if self.binds[id] then
            return self.binds[id].b[ply]
        end
    end

    function TARDIS:RemoveKeyBind(id)
        self.binds[id]=nil
    end
else
    local keys = {
        [KEY_NONE]={n=""},
        [KEY_0]={n="0"},
        [KEY_1]={n="1"},
        [KEY_2]={n="2"},
        [KEY_3]={n="3"},
        [KEY_4]={n="4"},
        [KEY_5]={n="5"},
        [KEY_6]={n="6"},
        [KEY_7]={n="7"},
        [KEY_8]={n="8"},
        [KEY_9]={n="9"},
        [KEY_A]={n="A"},
        [KEY_B]={n="B"},
        [KEY_C]={n="C"},
        [KEY_D]={n="D"},
        [KEY_E]={n="E"},
        [KEY_F]={n="F"},
        [KEY_G]={n="G"},
        [KEY_H]={n="H"},
        [KEY_I]={n="I"},
        [KEY_J]={n="J"},
        [KEY_K]={n="K"},
        [KEY_L]={n="L"},
        [KEY_M]={n="M"},
        [KEY_N]={n="N"},
        [KEY_O]={n="O"},
        [KEY_P]={n="P"},
        [KEY_Q]={n="Q"},
        [KEY_R]={n="R"},
        [KEY_S]={n="S"},
        [KEY_T]={n="T"},
        [KEY_U]={n="U"},
        [KEY_V]={n="V"},
        [KEY_W]={n="W"},
        [KEY_X]={n="X"},
        [KEY_Y]={n="Y"},
        [KEY_Z]={n="Z"},
        [KEY_PAD_0]={n="Keypad 0"},
        [KEY_PAD_1]={n="Keypad 1"},
        [KEY_PAD_2]={n="Keypad 2"},
        [KEY_PAD_3]={n="Keypad 3"},
        [KEY_PAD_4]={n="Keypad 4"},
        [KEY_PAD_5]={n="Keypad 5"},
        [KEY_PAD_6]={n="Keypad 6"},
        [KEY_PAD_7]={n="Keypad 7"},
        [KEY_PAD_8]={n="Keypad 8"},
        [KEY_PAD_9]={n="Keypad 9"},
        [KEY_PAD_DIVIDE]={n="Keypad /"},
        [KEY_PAD_MULTIPLY]={n="Keypad *"},
        [KEY_PAD_MINUS]={n="Keypad -"},
        [KEY_PAD_PLUS]={n="Keypad +"},
        [KEY_PAD_ENTER]={n="Keypad Enter"},
        [KEY_PAD_DECIMAL]={n="Keypad Del"},
        [KEY_LBRACKET]={n="["},
        [KEY_RBRACKET]={n="]"},
        [KEY_SEMICOLON]={n=";"},
        [KEY_APOSTROPHE]={n='"'},
        [KEY_BACKQUOTE]={n="`"},
        [KEY_COMMA]={n=","},
        [KEY_PERIOD]={n="."},
        [KEY_SLASH]={n="/"},
        [KEY_BACKSLASH]={n="\\"},
        [KEY_MINUS]={n="-"},
        [KEY_EQUAL]={n="="},
        [KEY_ENTER]={n="Enter"},
        [KEY_SPACE]={n="Space"},
        [KEY_BACKSPACE]={n="Backspace"},
        [KEY_TAB]={n="Tab"},
        [KEY_CAPSLOCK]={n="Caps Lock"},
        [KEY_NUMLOCK]={n="Num Lock"},
        [KEY_SCROLLLOCK]={n="Scroll Lock"},
        [KEY_INSERT]={n="Insert"},
        [KEY_DELETE]={n="Delete"},
        [KEY_HOME]={n="Home"},
        [KEY_END]={n="End"},
        [KEY_PAGEUP]={n="Page Up"},
        [KEY_PAGEDOWN]={n="Page Down"},
        [KEY_BREAK]={n="Break"},
        [KEY_LSHIFT]={n="Shift"},
        [KEY_RSHIFT]={n="Shift Right"},
        [KEY_LALT]={n="Alt"},
        [KEY_RALT]={n="Alt Right"},
        [KEY_LCONTROL]={n="Control"},
        [KEY_RCONTROL]={n="Control Right"},
        [KEY_UP]={n="Arrow Up"},
        [KEY_LEFT]={n="Arrow Left"},
        [KEY_DOWN]={n="Arrow Down"},
        [KEY_RIGHT]={n="Arrow Right"},
        [KEY_F1]={n="F1"},
        [KEY_F2]={n="F2"},
        [KEY_F3]={n="F3"},
        [KEY_F4]={n="F4"},
        [KEY_F5]={n="F5"},
        [KEY_F6]={n="F6"},
        [KEY_F7]={n="F7"},
        [KEY_F8]={n="F8"},
        [KEY_F9]={n="F9"},
        [KEY_F10]={n="F10"},
        [KEY_F11]={n="F11"},
        [KEY_F12]={n="F12"},
        [MOUSE_LEFT]={n="Mouse Left"},
        [MOUSE_RIGHT]={n="Mouse Right"},
        [MOUSE_MIDDLE]={n="Mouse 3"},
        [MOUSE_4]={n="Mouse 4"},
        [MOUSE_5]={n="Mouse 5"},
        [MOUSE_WHEEL_UP]={n="Mouse Wheel Up"},
        [MOUSE_WHEEL_DOWN]={n="Mouse Wheel Down"},
    }

    function TARDIS:GetKeyName(key)
        if keys[key] then
            return keys[key].n
        end
    end

    hook.Add("Think", "TARDIS-KeyBind", function()
        if gui.IsConsoleVisible() or gui.IsGameUIVisible() or vgui.GetHoveredPanel() then return end
        local ext=LocalPlayer():GetTardisData("exterior")
        local int=LocalPlayer():GetTardisData("interior")
        if IsValid(ext) then
            for key, info in pairs(keys) do
                local b = info.b
                info.b = key >= MOUSE_LEFT and input.IsMouseDown(key) or input.IsKeyDown(key)
                if info.b ~= b then
                    TARDIS:HandleKey(ext,int,key,info.b)
                end
            end
        end
    end)

    TARDIS.bindkeys=TARDIS.bindkeys or {}
    TARDIS.binds=TARDIS.binds or {}

    function TARDIS:GetBindKey(id)
        if self.bindkeys[id] then
            return self.bindkeys[id]
        end
    end

    function TARDIS:AddKeyBind(id,data)
        if self.bindkeys[id]==nil then
            self.bindkeys[id]=data.key
        end
        self.binds[id]=table.Copy(data)
    end

    function TARDIS:RemoveKeyBind(id)
        self.bindkeys[id]=nil
        self.binds[id]=nil
    end

    function TARDIS:SetKeyBind(id,key)
        if self.bindkeys[id] then
            self.bindkeys[id]=key
        end
        self:SaveKeyBinds()
    end

    function TARDIS:GetBinds()
        return self.binds
    end

    function TARDIS:GetBind(id)
        if self.binds[id] then
            return self.binds[id]
        end
    end

    local BINDS_FILE = "tardis_binds.txt"

    function TARDIS:SaveKeyBinds()
        local keys={}
        for k,v in pairs(self.binds) do
            if self.bindkeys[k] and self.bindkeys[k]~=v.key then
                keys[k]=self.bindkeys[k]
            end
        end
        file.Write(BINDS_FILE, self.von.serialize(keys))
    end

    function TARDIS:LoadKeyBinds()
        local keys=file.Read(BINDS_FILE,"DATA")
        if keys then
            table.Merge(self.bindkeys,self.von.deserialize(keys))
        end
    end
    TARDIS:LoadKeyBinds()

    --[[ TODO: Add back in before release
    TARDIS:AddMigration("binds-move", "2023.8.0", function(self)
        if file.Exists("tardis_binds.txt", "DATA") then
            if file.Exists(BINDS_FILE, "DATA") then
                file.Delete(BINDS_FILE)
            end
            file.Rename("tardis_binds.txt", BINDS_FILE)

            self:LoadKeyBinds()
        end
    end)
    ]]

    function TARDIS:IsBindDown(id)
        if self.bindkeys[id] then
            return keys[self.bindkeys[id]].b
        end
    end

    function TARDIS:HandleKey(ext,int,key,down)
        for k,v in pairs(self.bindkeys) do
            if v==key then
                local bind=self.binds[k]
                if bind then
                    local res,res2
                    if (bind.clientonly or (not (bind.clientonly and bind.serveronly))) and (not bind.serveronly) and bind.func then
                        if bind.exterior then
                            res=bind.func(ext,down,LocalPlayer())
                        end
                        if bind.interior and IsValid(int) then
                            res2=bind.func(int,down,LocalPlayer())
                        end
                    end
                    if (res~=false) and (res2~=false) and (not bind.clientonly) then
                        net.Start("TARDIS-KeyBind")
                            net.WriteString(k)
                            net.WriteBool(down)
                        net.SendToServer()
                    end
                end
            end
        end
    end

end

--[[
TARDIS:AddKeyBind("test",{
    func=function(self,down,ply)
        if CLIENT then
            LocalPlayer():ChatPrint("CLIENT "..tostring(down))
        else
            ply:ChatPrint("SERVER "..tostring(down))
        end
    end,
    key=KEY_SPACE,
    exterior=true
})
]]