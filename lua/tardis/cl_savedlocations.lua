TARDIS.Locations = TARDIS.Locations or {}

local LOCATIONS_FILE = "tardis2_locations.txt"

--[[ TODO: Add back in before release
TARDIS:AddMigration("locations-move", "2023.8.0", function(self)
    if file.Exists("tardis2_locations.txt", "DATA") then
        if file.Exists(LOCATIONS_FILE, "DATA") then
            file.Delete(LOCATIONS_FILE)
        end
        file.Rename("tardis2_locations.txt", LOCATIONS_FILE)

        self:LoadLocations()
    elseif file.Exists("tardis_locations.txt", "DATA") and not file.Exists(LOCATIONS_FILE, "DATA") then
        TARDIS.Locations = TARDIS.von.deserialize(file.Read("tardis_locations.txt", "DATA"))
        TARDIS:SaveLocations()
    end
end)
]]

function TARDIS:LoadLocations()
    if file.Exists(LOCATIONS_FILE, "DATA") then
        TARDIS.Locations = TARDIS.von.deserialize(file.Read(LOCATIONS_FILE,"DATA"))
    end
end

function TARDIS:SaveLocations()
    file.Write(LOCATIONS_FILE, TARDIS.von.serialize(TARDIS.Locations))
end

function TARDIS:AddLocation(pos,ang,name,map)
    if TARDIS.Locations and TARDIS.Locations[map] then

        local function location_exists(l_name)
            for k,v in ipairs(TARDIS.Locations[map]) do
                if v.name == l_name then
                    return true
                end
            end
            return false
        end
        local function name_copy(l_name, number)
            return name .. "(" .. number .. ")"
        end

        if location_exists(name) then
            local i = 1
            while(location_exists(name_copy(name,i))) do
                i = i + 1
            end
            name = name_copy(name,i)
        end

        TARDIS.Locations[map][table.Count(TARDIS.Locations[map])+1] = {
            ["name"] = name,
            ["pos"] = pos,
            ["ang"] = ang
        }
    elseif not TARDIS.Locations[map] then
        TARDIS.Locations[map] = {
            {
                ["name"] = name,
                ["pos"] = pos,
                ["ang"] = ang
            }
        }
    end
    TARDIS:SaveLocations()
end

function TARDIS:UpdateLocation(pos,ang,name,map,index)
    if TARDIS.Locations and TARDIS.Locations[map] then
        TARDIS.Locations[map][index] = {
            ["name"] = name,
            ["pos"] = pos,
            ["ang"] = ang
        }
    end
end

function TARDIS:RemoveLocation(map,index)
    table.remove(TARDIS.Locations[map],index)
    TARDIS:SaveLocations()
end

TARDIS:LoadLocations()