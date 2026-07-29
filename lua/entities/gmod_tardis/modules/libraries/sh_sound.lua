-- Sound

---@api
---@param opts doors_sound_opts
---@return doors_managed_sound?
function ENT:PlaySound(opts)
    opts.owner = opts.owner or self
    if opts.ent == nil and opts.pos == nil then opts.ent = self end
    return Doors:PlaySound(opts)
end

---@api
---@param tag string?
function ENT:StopSounds(tag)
    Doors:StopSounds(self, tag)
end
