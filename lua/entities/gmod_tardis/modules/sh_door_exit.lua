-- Door Exit

-- This module checks if the TARDIS doorway is clear for a player to step out of the TARDIS.

local CHECK_INTERVAL = 0.5 -- how often we check for obstructions (or lack thereof) in seconds
local TRACE_DIST = 28 -- units a player needs clear to step out
local GRID_COLS = 3 -- amount of sample rays across the doorway width
local GRID_ROWS = 3 -- amount of sample rays up the doorway height
local EDGE_INSET = 0.15 -- fraction inset from the doorway edges, so a corner gap doesn't count as clear

if SERVER then
    local angle_zero = Angle(0, 0, 0)

    -- Every sample ray across the doorway must be obstructed to count as blocked: one clear
    -- ray means a player could still step out, so a single prop or a partial gap never blocks.
    ---@param self gmod_tardis
    ---@return boolean
    local function doorway_blocked(self)
        local portal = self.metadata.Exterior.Portal
        ---@type Entity[]
        local filter = { self }
        for _, part in pairs(self.parts) do
            if IsValid(part) then filter[#filter + 1] = part end
        end

        local half_w, half_h = portal.width * 0.5, portal.height * 0.5
        local dir = self:LocalToWorldAngles(portal.ang):Forward()
        local span = 1 - 2 * EDGE_INSET

        for col = 0, GRID_COLS - 1 do
            local fy = GRID_COLS == 1 and 0 or -1 + 2 * (EDGE_INSET + span * col / (GRID_COLS - 1))
            for row = 0, GRID_ROWS - 1 do
                local fz = GRID_ROWS == 1 and 0 or -1 + 2 * (EDGE_INSET + span * row / (GRID_ROWS - 1))
                local doorway = LocalToWorld(Vector(0, fy * half_w, fz * half_h), angle_zero, portal.pos, portal.ang)
                local start = self:LocalToWorld(doorway)
                local tr = util.TraceLine({
                    start = start,
                    endpos = start + dir * TRACE_DIST,
                    filter = filter,
                    mask = MASK_PLAYERSOLID,
                } --[[@as Trace]])
                if not (tr.Hit or tr.StartSolid) then
                    return false
                end
            end
        end
        return true
    end

    ---@param self gmod_tardis
    ---@return boolean
    local function should_check(self)
        if next(self.occupants) == nil then return false end
        if self:GetData("teleport") or self:GetData("vortex") then return false end
        return self:DoorOpen(true)
    end

    ENT:AddHook("Think", "door_exit", function(self)
        if not should_check(self) then
            if self:GetData("door_exit_blocked") then
                self:SetData("door_exit_blocked", false, true)
                self:UpdateDoorCollision()
            end
            return
        end

        if CurTime() < self:GetData("door_exit_nextcheck", 0) then return end
        self:SetData("door_exit_nextcheck", CurTime() + CHECK_INTERVAL)

        local blocked = doorway_blocked(self)
        if blocked ~= self:GetData("door_exit_blocked", false) then
            self:SetData("door_exit_blocked", blocked, true)
            self:UpdateDoorCollision()
        end
    end)
end

ENT:AddHook("CanPlayerExit", "door_exit", function(self)
    if self:GetData("door_exit_blocked") then
        return false
    end
end)
