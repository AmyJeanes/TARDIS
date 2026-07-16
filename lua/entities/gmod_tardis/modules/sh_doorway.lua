-- Doorway

-- This module checks if the TARDIS doorway is clear for a player to step through it, in either direction.

local CHECK_INTERVAL = 0.5 -- how often we check for obstructions (or lack thereof) in seconds
local TRACE_DIST = 28 -- units a player needs clear to step through
local GRID_COLS = 3 -- amount of sample rays across the doorway width
local GRID_ROWS = 3 -- amount of sample rays up the doorway height
local EDGE_INSET = 0.15 -- fraction inset from the doorway edges, so a corner gap doesn't count as clear

if SERVER then
    local angle_zero = Angle(0, 0, 0)

    -- Every sample ray across the doorway must be obstructed to count as blocked: one clear
    -- ray means a player could still step through, so a single prop or a partial gap never blocks.
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

    ENT:AddHook("Think", "doorway", function(self)
        -- Alt+E works through a closed door and an empty TARDIS can still be entered, so the
        -- check can't gate on occupancy or door state - only on teleport/vortex, where the
        -- doorway leads nowhere and the teleport hooks own the vetoes.
        if self:GetData("teleport") or self:GetData("vortex") then
            if self:GetData("doorway_blocked") then
                self:SetData("doorway_blocked", false, true)
                self:UpdateDoorCollision()
            end
            return
        end

        if CurTime() < self:GetData("doorway_nextcheck", 0) then return end
        self:SetData("doorway_nextcheck", CurTime() + CHECK_INTERVAL)

        local blocked = doorway_blocked(self)
        if blocked ~= self:GetData("doorway_blocked", false) then
            self:SetData("doorway_blocked", blocked, true)
            self:UpdateDoorCollision()
        end
    end)
end

-- Noclip is exempt: the solid door can't stop it anyway, so the portal stays
-- crossable for it rather than acting as an invisible wall.
---@param ply Player
---@return boolean
function ENT:IsDoorwayBlocked(ply)
    if not self:GetData("doorway_blocked") then return false end
    return not (IsValid(ply) and ply:GetMoveType() == MOVETYPE_NOCLIP)
end

-- The Alt+E layer: the door Use sites consult these and show the reason on a veto.
ENT:AddHook("CanPlayerEnterDoor", "doorway",
    ---@param ply Player
    function(self, ply)
        if self:IsDoorwayBlocked(ply) then
            return false, "Parts.Door.EntranceBlocked"
        end
    end)

ENT:AddHook("CanPlayerExitDoor", "doorway",
    ---@param ply Player
    function(self, ply)
        if self:IsDoorwayBlocked(ply) then
            return false, "Parts.Door.ExitBlocked"
        end
    end)

-- The enforcement backstop: portal crossings (predicted) and non-Use callers.
ENT:AddHook("CanPlayerExit", "doorway",
    ---@param ply Player
    function(self, ply)
        if self:IsDoorwayBlocked(ply) then
            return false
        end
    end)

-- false,true vetoes the portal crossing but leaves programmatic PlayerEnter working:
-- materializing on top of a player must still pull them inside, not entomb them.
ENT:AddHook("CanPlayerEnter", "doorway",
    ---@param ply Player
    function(self, ply)
        if self:IsDoorwayBlocked(ply) then
            return false, true
        end
    end)
