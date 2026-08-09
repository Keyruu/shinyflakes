local interval = noctalia.getConfig("interval") or 60

local NEXT_CMD = "next-event"
local LIST_CMD = 'khal list "$(date \'+%Y-%m-%d %H:%M\')" 7d'
    .. ' --day-format "DAY:{name}, {date}"'
    .. ' -f "{start-time}-{end-time} {title} | {location}"'
    .. " | grep -Ev '↦|↔ |⇥' | grep -v '^ '"

local function buildTooltip(raw)
    if raw == "" then return "No upcoming events" end

    local lines = {}
    for line in raw:gmatch("[^\n]+") do
        local day = line:match("^DAY:(.+)$")
        if day then
            -- Add spacing between day groups
            if #lines > 0 then
                table.insert(lines, "")
            end
            table.insert(lines, "── " .. day .. " ──")
        else
            local time_title, location = line:match("^(.-)%s*|%s*(.*)$")
            if time_title then
                if location and location ~= "" then
                    table.insert(lines, time_title .. "  📍 " .. location)
                else
                    table.insert(lines, time_title)
                end
            else
                table.insert(lines, line)
            end
        end
    end

    return table.concat(lines, "\n")
end

local function fetchEvents()
    noctalia.runAsync(NEXT_CMD, function(result)
        local text = (result.stdout or ""):gsub("\n$", "")
        noctalia.state.set("next_event", text)
    end)

    noctalia.runAsync(LIST_CMD, function(result)
        noctalia.state.set("tooltip", buildTooltip(result.stdout or ""))
    end)
end

function update()
    noctalia.setUpdateInterval(interval * 1000)
    fetchEvents()
end
