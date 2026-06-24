local maxLen = barWidget.getConfig("max_length") or 43

barWidget.setGlyph("calendar")

local function truncate(text, len)
    if #text > len then
        return string.sub(text, 1, len - 1) .. "…"
    end
    return text
end

noctalia.state.watch("next_event", function(text)
    if not text or text == "" or text == "No events" then
        barWidget.setText("")
    else
        barWidget.setText(truncate(text, maxLen))
    end
end)

noctalia.state.watch("tooltip", function(tip)
    if tip and tip ~= "" then
        barWidget.setTooltip(tip)
    else
        barWidget.setTooltip("No upcoming events")
    end
end)

function update()
    noctalia.setUpdateInterval(60000)
end
