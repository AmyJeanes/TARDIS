-- Artron Inhibitor by Nova Astral, an edit of the Time Distortion Generator by parar020100 and JEREDEK

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "#TARDIS.ArtronInhibitor"
ENT.Spawnable = true

ENT.Instructions= "#TARDIS.ArtronInhibitor.Instructions"
ENT.AdminOnly = false
ENT.Category = "#TARDIS.Spawnmenu.CategoryTools"
ENT.IconOverride = "materials/entities/time_distortion_generator.png"


function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 1, "Enabled" )
end