-- Sound

-- The owner is what scopes a counterpart pair and what a group stop matches, and it is the TARDIS for
-- every sound this addon plays - including the ones emitted from the interior or a part, which is where
-- naming it by hand goes wrong silently: a mismatched owner puts the two halves of a pair in different
-- groups, so they sum instead of blending.

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
