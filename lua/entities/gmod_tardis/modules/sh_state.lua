-- TARDIS State

-- A list of supported states
TARDIS.States = {
  ["dead"] = true,

  ["off"] = true,
  ["idle"] = true,
  ["handbrake"] = true,
  ["travel"] = true,
  ["demat_abort"] = true,
  ["demat_fail"] = true,
  ["mat_fail"] = true,
  ["takeoff"] = true,
  ["parking"] = true,

  ["off_warning"] = true,
  ["idle_warning"] = true,
  ["handbrake_warning"] = true,
  ["travel_warning"] = true,
  ["demat_abort_warning"] = true,
  ["demat_fail_warning"] = true,
  ["mat_fail_warning"] = true,
  ["takeoff_warning"] = true,
  ["parking_warning"] = true,
}

-- We add all the hooks here to ensure the integrity of state logic
TARDIS.StateUpdateHooks = {
  ["PostInitialize"] = true,

  ["OnHealthDepleted"] = true,
  ["OnHealthChange"] = true,

  ["WarningToggled"] = true,
  ["PowerToggled"] = true,
  ["HandbrakeToggled"] = true,

  ["DematStart"] = true,
  ["MatStart"] = true,
  ["PreMatStart"] = true,
  ["StopDemat"] = true,
  ["StopMat"] = true,
  ["InterruptTeleport"] = true,
  ["DematInterrupted"] = true,
  ["DematFailed"] = true,
  ["DematFailStopped"] = true,
  ["MatFailed"] = true,
  ["MatFailStopped"] = true,

  ["TakeoffStateToggled"] = true,
  ["ParkingStateToggled"] = true,
  ["DematAbortStateToggled"] = true,

  ["FlightToggled"] = true,
}

-- Adding the hooks
for hook_name, _ in pairs(TARDIS.StateUpdateHooks) do
  ENT:AddHook(hook_name, "state_update", function(self)
    self:UpdateState()
  end)
end

--

function ENT:SetState(state)
  if not TARDIS.States[state] then
    error("Attempted to apply unsupported state " .. state)
  end
  return self:SetData("state", state, true)
end

---@api
---@return string?
function ENT:GetState()
  return self:GetData("state")
end

function ENT:SelectState()
  local function select_warning(state)
    return self:GetWarning() and (state .. "_warning") or state
  end

  if self:IsDead() then
    return "dead", false
  end

  if not self:GetPower() then
    return select_warning("off")
  end

  if self:IsTravelling() then
    if self:GetData("failing-mat") then
      return select_warning("mat_fail")
    end
    if self:GetData("state_takeoff") then
      return select_warning("takeoff")
    end
    return select_warning("travel")
  end

  if self:GetData("failing-demat") then
    return select_warning("demat_fail")
  end

  if self:GetData("state_demat_abort") then
    return select_warning("demat_abort")
  end

  if self:GetHandbrake() then
    return select_warning("handbrake")
  end

  if self:GetData("state_parking") then
    return select_warning("parking")
  end

  return select_warning("idle")
end

function ENT:UpdateState()
  return self:SetState(self:SelectState())
end

--
-- "Travelling" generalisation
--

---@api
---@return boolean?
function ENT:IsTravelling()
    return self:CallHook("IsTravelling")
end

--
-- Custom states for visual effects with no functionality
--

local function ProcessTemporaryState(self, time, data_id, hook_name)
  if time ~= 0 then
    self:SetData(data_id, true)
    self:CallHook(hook_name, true)
    self:Timer(data_id .. "reset", time, function()
      self:SetData(data_id, nil)
      self:CallHook(hook_name, false)
    end)
  end
end

ENT:AddHook("DematStart", "state_takeoff", function(self)
  ProcessTemporaryState(self, self.metadata.Timings.TakeOffState, "state_takeoff", "TakeoffStateToggled")
  self:UpdateState()
end)

ENT:AddHook("StopMat", "state_parking", function(self)
  ProcessTemporaryState(self, self.metadata.Timings.ParkingState, "state_parking", "ParkingStateToggled")
  self:UpdateState()
end)

ENT:AddHook("DematInterrupted", "state_demat_abort", function(self)
  ProcessTemporaryState(self, self.metadata.Timings.DematAbortState, "state_demat_abort", "DematAbortStateToggled")
  self:UpdateState()
end)

-- fixing handbrake + stopmat conflict
ENT:AddHook("HandbrakeToggled", "state_parking", function(self, on)
  if on and self:GetData("state_parking") then
    self:SetData("state_parking", nil)
    self:CancelTimer("state_parking_reset")
  end
end)
