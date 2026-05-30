local PART={}
PART.ID = "intdoor"
PART.Name = "Interior Doors"
PART.Model = "models/drmatt/tardis/exterior/door.mdl"
PART.AutoSetup = true
PART.AutoPosition = true
PART.ClientThinkOverride = true
PART.Collision = true
PART.NoStrictUse = true
PART.ShouldTakeDamage = true
PART.BypassIsomorphic = true


if SERVER then
    function PART:Use(a)

        if self:GetData("locked") then
            if IsValid(a) and a:IsPlayer() then
                if self.exterior:CallHook("LockedUse",a)==nil then
                    TARDIS:Message(a, "Parts.Door.Locked")
                end
            end
        else
            if a:KeyDown(IN_WALK) or self:GetData("legacy_door_type") then
                self.exterior:PlayerExit(a)
            end
        end
    end
else

    function PART:Initialize()
        self.IntDoorPos=0
        self.IntDoorTarget=0

        -- door open animation may go beyond render bounds of the model
        -- increase bounds by the maximum distance the door can move
        -- calculated by the width of the door (y axis)
        local mins, maxs = self:OBBMins(), self:OBBMaxs()
        local reach = maxs.y - mins.y
        self:SetRenderBounds(
            Vector(mins.x - reach, mins.y - reach, mins.z),
            Vector(maxs.x + reach, maxs.y + reach, maxs.z)
        )
    end

    function PART:Think()
        self.IntDoorTarget=self.exterior.IntDoorOverride or (self:GetData("doorstatereal",false) and 1 or 0)
        local animtime = self.exterior.metadata.Interior.IntDoorAnimationTime
            or self.exterior.metadata.Exterior.DoorAnimationTime

        -- Always ease toward IntDoorTarget (which already folds in IntDoorOverride,
        -- set above). Never hard-set IntDoorPos straight from the override: mirrors
        -- the door part fix -- hard-setting renders any single-frame override spike
        -- (e.g. from a high-ping predicted exit) as an instant snap instead of a
        -- smooth move. IntDoorOverride currently has no writer, so this is parity
        -- with door.lua / future-proofing rather than a live bug on this part.
        -- Have to spam it otherwise it glitches out (http://facepunch.com/showthread.php?t=1414695)
        self.IntDoorPos = math.Approach(self.IntDoorPos, self.IntDoorTarget, FrameTime() * (1 / animtime))

        self:SetPoseParameter("switch", self.IntDoorPos)
        self:InvalidateBoneCache()

    end
end

TARDIS:AddPart(PART)