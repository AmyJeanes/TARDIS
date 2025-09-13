-- Material proxies

ENT:AddHook("OnRemove", "matproxy_cleanup", function(self)
    if TARDIS.DynamicProxyVars then
        TARDIS.DynamicProxyVars[self] = nil
    end
end)
