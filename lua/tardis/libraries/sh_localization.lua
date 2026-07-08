-- Localization

---@class tardis_language
---@field Code string
---@field Name string
---@field Phrases table<string, string>
---@field Base string?
---@field Extends string?

---@class tardis_language_extension
---@field Code string
---@field Extends string
---@field Phrases table<string, string>

TARDIS.Languages = TARDIS.Languages or {}
TARDIS.LanguageExtensions = TARDIS.LanguageExtensions or {}
---@type table<string, table<string, string>>
TARDIS.LanguageCache = TARDIS.LanguageCache or {}
TARDIS.CurrentLanguage = TARDIS.CurrentLanguage
TARDIS.DefaultLanguage = "en"

---@api
---@param phrase string?
---@param ... any
---@return string
function TARDIS:GetPhrase(phrase, ...)
    if not phrase then
        return ""
    end
    local cache = self.LanguageCache[self.CurrentLanguage]
    local str = cache[phrase]
    if not str then
        if ... then
            return self:FormatString(phrase, ...)
        else
            return phrase
        end
    end
    if not ... then
        return str
    end
    return self:FormatString(str, ...)
end

---@param str string
function TARDIS:FormatString(str, ...)
    local args = {...}
    local cache = self.LanguageCache[self.CurrentLanguage]
    for k, v in ipairs(args) do
        args[k] = cache[v] or v
    end
    return string.format(str, unpack(args))
end

---@api
---@param phrase string?
---@return boolean
function TARDIS:PhraseExists(phrase)
    local cache = self.LanguageCache[self.CurrentLanguage]
    return cache[phrase] ~= nil
end

---@api
---@param phrase string?
---@param ... any
---@return string?
function TARDIS:GetPhraseIfExists(phrase, ...)
    if not phrase then
        return nil
    end
    local cache = self.LanguageCache[self.CurrentLanguage]
    local str = cache[phrase]
    if not str then
        return nil
    end
    if not ... then
        return str
    end
    return string.format(str, ...)
end

---@api
---@param language tardis_language
function TARDIS:AddLanguage(language)
    if not (language.Code and language.Phrases and language.Name) then
        error("TARDIS:AddLanguage: Invalid language configuration")
    end
    local lang = {}
    lang.Name = language.Name
    lang.Base = language.Base
    lang.Extends = language.Extends
    lang.Phrases = language.Phrases

    self.Languages[language.Code] = lang

    self:CompileLanguage(language.Code)
    self:UpdateLanguage()
end

---@api
---@param extension tardis_language_extension
function TARDIS:AddLanguageExtension(extension)
    if not (extension.Code and extension.Phrases and extension.Extends) then
        error("TARDIS:AddLanguageExtension: Invalid language extension configuration")
    end

    local langExtension = {}
    langExtension.Phrases = extension.Phrases

    local extensions = self.LanguageExtensions[extension.Extends] or {}
    self.LanguageExtensions[extension.Extends] = extensions
    extensions[extension.Code] = langExtension

    if self.Languages[extension.Extends] then
        self:CompileLanguage(extension.Extends)
    end
end

---@param code string
function TARDIS:CompileLanguage(code)
    ---@type table<string, string>
    local phrases = {}

    local lang = self.Languages[code]
    if not lang then
        return
    end

    for k, v in pairs(lang.Phrases) do
        phrases[k] = v
        if not phrases[k..".Lower"] then
            phrases[k..".Lower"] = string.lower(v)
        end
    end

    local extensions = self.LanguageExtensions[code]
    if extensions then
        for _, extension in pairs(extensions) do
            for phrase_id, phrase_text in pairs(extension.Phrases) do
                if phrases[phrase_id] then
                    ErrorNoHalt("Extension " .. extension.Code .. " attempted to override existing language phrase " .. phrase_id)
                else
                    phrases[phrase_id] = phrase_text
                end
            end
        end
    end

    local base = lang.Base or self.DefaultLanguage
    if code ~= base then
        local basePhrases = self.LanguageCache[base]
        if basePhrases then
            for k,v in pairs(basePhrases) do
                if not phrases[k] then
                    phrases[k] = v
                end
            end
        end
    end

    self.LanguageCache[code] = phrases

    for k, v in pairs(self.Languages) do
        if k ~= code then
            local current_base = v.Base or self.DefaultLanguage
            local current_base_lang
            repeat
                current_base_lang = self.Languages[current_base]
                if not current_base_lang then
                    break
                end
                if current_base == code then
                    self:CompileLanguage(k)
                    break
                end
                current_base = current_base_lang.Base or self.DefaultLanguage
            until current_base == self.DefaultLanguage
        end
    end

    return phrases
end

---@api
---@return string
function TARDIS:GetLanguage()
    if not TARDIS.CurrentLanguage then
        self:UpdateLanguage()
    end
    return TARDIS.CurrentLanguage
end

---@api
function TARDIS:UpdateLanguage()
    local langCode
    if SERVER then
        langCode = "default"
    else
        langCode = self:GetSetting("language")
    end

    if langCode == "default" then
        langCode = cvars.String("gmod_language", "en")
    end

    if not self.Languages[langCode] then
        if self.Languages[self.DefaultLanguage] then
            langCode = self.DefaultLanguage
        else
            return
        end
    end

    ---@type string
    local oldLangCode = self.CurrentLanguage
    self.CurrentLanguage = langCode

    if not self.LanguageCache[langCode] then
        self:CompileLanguage(langCode)
    end

    if language then
        for k,v in pairs(self.LanguageCache[langCode]) do
            language.Add("TARDIS."..k, v)
        end
    end

    if oldLangCode == langCode then return end

    hook.Call("TARDIS_LanguageChanged", GAMEMODE, langCode, oldLangCode)
    for _,ent in ipairs(TARDIS:GetExteriorEnts()) do
        ent:CallCommonHook("LanguageChanged", langCode, oldLangCode)
    end
end

hook.Add("TARDIS_SettingChanged", "TARDIS_LanguageSettingChanged", function(id, value, old_value, ply)
    if id == "language" then
        TARDIS:UpdateLanguage()
    end
end)

hook.Add("InitPostEntity", "TARDIS_Language", function()
    TARDIS:UpdateLanguage()
end)

cvars.AddChangeCallback("gmod_language", function()
    TARDIS:UpdateLanguage()
end)

---@api
function TARDIS:GetLanguages()
    return self.Languages
end

TARDIS:LoadFolder("languages", false, true)
TARDIS:LoadFolder("languages/extensions", false, true)
