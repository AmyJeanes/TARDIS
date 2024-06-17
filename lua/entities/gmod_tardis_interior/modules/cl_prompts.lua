--Prompts

ENT:AddHook("PlayerEnter", "lod_prompt", function(self)
    if self.metadata.Interior.RequireHighModelDetail ~= false and GetConVarNumber("r_rootlod")>0 then
            Derma_Query(
            TARDIS:GetPhrase("Prompts.LOD"),
            TARDIS:GetPhrase("Common.TARDIS"),
            TARDIS:GetPhrase("Common.Yes"),
            function()
                RunConsoleCommand("r_rootlod", 0)
            end,
            TARDIS:GetPhrase("Common.No"),
            nil
        )
    end
end)