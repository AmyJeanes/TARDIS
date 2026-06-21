---@class tardis_sequence
---@field ID string
---@field [string] tardis_sequence_step

---@class tardis_sequence_step
---@field Controls string[]
---@field OnFinish fun(int: gmod_tardis_interior, ply: Player, step: integer, part: gmod_tardis_part)
---@field OnFail (fun(int: gmod_tardis_interior, ply: Player, step: integer, part: gmod_tardis_part))?
---@field Condition (fun(self: gmod_tardis_interior): boolean)?

---@type table<string, tardis_sequence>
TARDIS.CSequences = {}

-- Functionally identical to {} but gives proper type checking for control sequences
---@return tardis_sequence
function TARDIS:NewControlSequence()
    return {}
end

function TARDIS:AddControlSequence(cseq)
    self.CSequences[cseq.ID] = cseq
end

---@return tardis_sequence?
function TARDIS:GetControlSequence(id)
    if self.CSequences[id] ~= nil then
        return self.CSequences[id]
    end
end

TARDIS:LoadFolder("interiors/sequences",nil,true)