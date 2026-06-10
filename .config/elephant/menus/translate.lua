Name = "translate"
NamePretty = "Translate"
Description = "翻譯文字"
Icon = "accessories-dictionary"
HideFromProviderlist = false

Actions = {
    translate = "lua:Translate",
}

function Translate(value, args, query)
    local text = value ~= "" and value or query
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        return
    end
    local quoted = "'" .. text:gsub("'", "'\\''") .. "'"
    os.execute("dialect --text " .. quoted .. " --dest zh-TW >/dev/null 2>&1 &")
end

-- Walker fuzzy-filters menu entries against the query, so the entry's Text must
-- contain the query itself to stay visible. Only offer the entry for input that
-- looks like text to translate (contains whitespace or CJK), so single-word app
-- searches stay noise-free — add a trailing space to force it for a single word.
local function is_translatable(query)
    if query:find("%s") then
        return true
    end
    -- UTF-8 bytes E3 80 80 – E9 BF BF ≈ U+3000–U+9FFF (CJK punctuation, kana, ideographs)
    if query:find("[\227-\233][\128-\191][\128-\191]") then
        return true
    end
    return false
end

function GetEntries(query)
    if query == nil or query == "" or not is_translatable(query) then
        return {}
    end
    return {
        {
            Text = query,
            Subtext = "翻譯文字",
            Value = query,
            Icon = "accessories-dictionary",
        },
    }
end
