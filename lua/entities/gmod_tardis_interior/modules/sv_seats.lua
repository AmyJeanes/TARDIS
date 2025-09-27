-- Add seats

ENT:AddHook("Initialize","seats",function(self)
    local seats=self.metadata.Interior.Seats
    if seats then
        self.seats={}
        local vname="Seat_Airboat"
        local chair=list.Get("Vehicles")[vname]
        for k,v in pairs(seats) do
            table.insert(self.seats,self:MakeVehicle(self:LocalToWorld(v.pos), self:LocalToWorldAngles(v.ang), chair.Model, chair.Class, vname, chair))
        end
    end
end)

function ENT:MakeVehicle( Pos, Ang, Model, Class, VName, VTable )
    local ent = ents.Create( Class )
    if not ent then return NULL end

    ent:SetModel( Model )

    -- Fill in the keyvalues if we have them
    if VTable and VTable.KeyValues then
        for k, v in pairs( VTable.KeyValues ) do
            ent:SetKeyValue( k, v )
        end
    end

    ent:SetPos( Pos )
    ent:SetAngles( Ang )

    ent:Spawn()
    ent:Activate()

    ent.VehicleName     = VName
    ent.VehicleTable    = VTable

    -- We need to override the class in the case of the Jeep, because it
    -- actually uses a different class than is reported by GetClass
    ent.ClassOverride   = Class

    ent.TardisPart=true
    ent:GetPhysicsObject():EnableMotion(false)
    ent:SetNoDraw(true)
    self:DeleteOnRemove(ent)

    constraint.Weld(self,ent,0,0)
    if IsValid(self.owner) then
        if SPropProtection then
            SPropProtection.PlayerMakePropOwner(self.owner, ent)
        else
            gamemode.Call("CPPIAssignOwnership", self.owner, ent)
        end
    end

    return ent
end

ENT:AddHook("PreOnRemove","seats",function(self)
    if self.seats then
        for k,_ in pairs(self.exterior.occupants) do
            local veh = k:GetVehicle()
            if IsValid(veh) and veh.TardisPart then
                k:ExitVehicle()
            end
        end
    end
end)
