ENT:AddHook("Initialize", "timers", function(self)
    self.timers = {}
end)

---@api
function ENT:Timer(id, delay, action)
    self.timers[id] = { CurTime() + delay, action }
end

---@api
function ENT:CancelTimer(id)
    self.timers[id] = nil
end

---@api
function ENT:GetTimer(id)
    return self.timers[id]
end

ENT:AddHook("Think", "timers", function(self)
    if not self.timers then return end
    for k,v in pairs(self.timers)
    do
        if CurTime() > v[1] then
            self:CancelTimer(k)
            local func = v[2]
            func()
        end
    end
end)

