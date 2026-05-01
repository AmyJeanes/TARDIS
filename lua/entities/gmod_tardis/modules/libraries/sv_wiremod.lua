--Wiremod support

--Vars

local inputs = {}
local outputs = {}

--Methods

function ENT:AddWireInput(name, desc, type)
    if not WireLib then return end
    local input = {
        name = name,
        desc = desc,
        datatype = type
    }
    table.insert(inputs, input)
end

function ENT:AddWireOutput(name, desc, type)
    if not WireLib then return end
    local output = {
        name = name,
        desc = desc,
        datatype = type
    }
    table.insert(outputs, output)
end

function ENT:HandleE2(cmd, ...)
    local ret=self:CallHook("HandleE2", cmd, ...)
    if ret==nil then ret=0 end
    return ret
end

function ENT:TriggerWireOutput(name, value)
    if not WireLib then return end
    WireLib.TriggerOutput(self, name, value)
end

--Hooks

function ENT:TriggerInput(name, value)
    if not WireLib then return end
    self:CallHook("OnWireInput", name, value)
end


ENT:AddHook("Initialize", "wiremod", function(self)
    if not WireLib then return end
    local ins = {}
    local indescs = {}
    local intypes = {}
    for k,v in ipairs(inputs) do
        ins[k] = v.name
        indescs[k] = v.desc and TARDIS:GetPhrase(v.desc) or nil
        intypes[k] = v.datatype or nil
    end
    WireLib.CreateSpecialInputs(self, ins, intypes, indescs)
    local outs = {}
    local outdescs = {}
    local outtypes = {}
    for k,v in ipairs(outputs) do
        outs[k] = v.name
        outdescs[k] = v.desc and TARDIS:GetPhrase(v.desc) or nil
        outtypes[k] = v.datatype or nil
    end
    WireLib.CreateSpecialOutputs(self, outs, outtypes, outdescs)
end)