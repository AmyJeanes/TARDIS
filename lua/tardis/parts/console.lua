-- The console

local PART = TARDIS:NewPart()
PART.ID = "console"
PART.Name = "The Console"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = true

if SERVER then
    ---@param ply Player
    function PART:Use(ply)
        if ply:IsPlayer() and (not ply:GetTardisData("thirdperson")) and CurTime()>ply:GetTardisData("outsidecool", 0) then
            TARDIS:Control("thirdperson_careful", ply)
        end
    end
end

TARDIS:AddPart(PART)
