-- Reads the status files published by the tool-guardian herd.ts module
-- (same source as the pi-herd fzf picker). Bar shows "waiting/total",
-- tooltip lists every instance sorted waiting > question > working > rest.

local interval = noctalia.getConfig("interval") or 10

local cacheHome = noctalia.getenv("XDG_CACHE_HOME") or noctalia.expandPath("~/.cache")
local DIR = cacheHome .. "/pi-herd"

local SORT = { waiting = 0, question = 1, working = 2 }
local ICON = { waiting = "●", question = "?", working = "◐" }

local function formatAge(seconds)
    if seconds < 60 then return seconds .. "s" end
    if seconds < 3600 then return math.floor(seconds / 60) .. "m" end
    return math.floor(seconds / 3600) .. "h"
end

local function scan()
    local rows = {}
    local now = tonumber(noctalia.formatTime("%s")) or 0
    for _, name in ipairs(noctalia.listDir(DIR) or {}) do
        if name:match("%.json$") then
            local raw = noctalia.readFile(DIR .. "/" .. name)
            local entry = raw and noctalia.json.decode(raw)
            -- skip entries from crashed/killed pi processes (picker GCs the files)
            if entry and entry.pid and noctalia.fileExists("/proc/" .. entry.pid) then
                table.insert(rows, entry)
            end
        end
    end
    return rows, now
end

local function home()
    return noctalia.getenv("HOME") or ""
end

local function render(rows, now)
    if #rows == 0 then
        barWidget.setVisible(false)
        return
    end
    barWidget.setVisible(true)

    table.sort(rows, function(a, b)
        local sa, sb = SORT[a.status] or 3, SORT[b.status] or 3
        if sa ~= sb then return sa < sb end
        return (a.cwd or "") < (b.cwd or "")
    end)

    local attention = 0
    local working = 0
    local lines = {}
    local h = home()
    for _, e in ipairs(rows) do
        if e.status == "waiting" or e.status == "question" then attention += 1 end
        if e.status == "working" then working += 1 end
        local cwd = (e.cwd or "?"):gsub("^" .. h, "~")
        local loc = e.zellijTab or "-"
        if e.zellijSession then loc = e.zellijSession .. " · " .. loc end
        local age = e.updatedAt and formatAge(math.max(now - e.updatedAt, 0)) or "?"
        table.insert(lines, string.format("%s %-7s %s  (%s, %s)",
            ICON[e.status] or "○", e.status or "?", cwd, loc, age))
    end

    local color = attention > 0 and "error" or "on_surface"
    barWidget.setColor(color)
    barWidget.setGlyphColor(color)
    barWidget.setText(working .. "/" .. #rows)
    barWidget.setTooltip(table.concat(lines, "\n"))
end

barWidget.setGlyph("robot")

function update()
    noctalia.setUpdateInterval(interval * 1000)
    render(scan())
end
