-- Message

if SERVER then
    util.AddNetworkString("TARDIS-MessageInt")
end

---@api
---@param name string
---@param data table?
---@param ply Player?
function ENT:SendMessage(name,data,ply)
    net.Start("TARDIS-MessageInt")
    net.WriteEntity(self)
    net.WriteString(name)

    if data then
        net.WriteBool(true)
        net.WriteString(TARDIS.von.serialize(data))
    else
        net.WriteBool(false)
    end

    if SERVER then
        if IsValid(ply) and ply:IsPlayer() then
            net.Send(ply)
        else
            net.Broadcast()
        end
    else
        net.SendToServer()
    end
end

---@type table<string, function>
local messagehandlers={}
---@api
---@param func fun(self: gmod_tardis_interior, data: any, ply: Player)
---@param name string
function ENT:OnMessage(name,func)
    messagehandlers[name]=func
end

net.Receive("TARDIS-MessageInt", function(len,ply)
    local ent = net.ReadEntity()
    local name = net.ReadString()
    local data_exists = net.ReadBool()
    local data

    if data_exists then
        data = TARDIS.von.deserialize(net.ReadString())
    end

    if not IsValid(ent) then return end

    if messagehandlers[name] and (ent._init or SERVER) then
        messagehandlers[name](ent,data,ply)
    elseif ent.metadata and ent.metadata.CustomMessages and ent.metadata.CustomMessages[name] and (ent._init or SERVER) then
        ent.metadata.CustomMessages[name](ent,data,ply)
    else
        if not ent.msg_queue then ent.msg_queue = {} end
        ent.msg_queue[#ent.msg_queue + 1] = { name = name, data = data, ply = ply }
    end
end)

if CLIENT then
    ENT:AddHook("Initialize","messages",function(self)
        if not self.msg_queue then return end

        for _,v in ipairs(self.msg_queue) do
            if messagehandlers[v.name] then
                messagehandlers[v.name](self, v.data, v.ply)
            elseif self.metadata and self.metadata.CustomMessages and self.metadata.CustomMessages[v.name] then
                self.metadata.CustomMessages[v.name](self, v.data, v.ply)
            end
        end
    end)
end
