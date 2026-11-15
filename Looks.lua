-- RUIN Pathfinder: the looks Pathfinder can give the game's own frames (the
-- minimap, the objective tracker, the world map and quest log) and its
-- waypoint: the game's own (Blizzard), or the suite's modern style in one of
-- its colors. RUIN wears the core app's gold on ink, as the waypoint always
-- has; the others wear their module's color, as the module's pages do.
local ADDON, ns = ...
local R = RUIN_API
if not R then return end
local W = R.Widgets

local L = {}
ns.Looks = L

L.KEYS = { "blizzard", "ruin", "pathfinder", "finder", "muster", "codex", "exchange" }
L.MODERN = { "ruin", "pathfinder", "finder", "muster", "codex", "exchange" }      -- the waypoint's (it has no Blizzard look)
L.LABEL = { blizzard = "Blizzard", ruin = "RUIN", pathfinder = "Pathfinder", finder = "Finder",
            muster = "Muster", codex = "Codex", exchange = "Exchange" }

local GOLD = { 0.90, 0.72, 0.38 }
local INK = { 0.035, 0.045, 0.075 }
L.GOLD, L.INK = GOLD, INK
local COLOR = {
    ruin = GOLD,
    pathfinder = { 0.31, 0.60, 0.23 },
    finder = { 0.82, 0.31, 0.54 },
    muster = { 0.85, 0.38, 0.17 },
    codex = { 0.54, 0.32, 0.84 },
    exchange = { 0.84, 0.60, 0.16 },
}

local function mix(a, b, t) return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t } end
L.Mix = mix

function L.Valid(key) return COLOR[key] ~= nil or key == "blizzard" end
function L.Modern(key) return COLOR[key] ~= nil end

-- A look's theme (what a frame's ruinTheme is set to, so the suite's skins
-- color it) and its scheme (accent, edge, bg...).
local themes, schemes = {}, {}
function L.Theme(key)
    key = COLOR[key] and key or "pathfinder"
    themes[key] = themes[key] or { color = COLOR[key], core = (key == "ruin") or nil }
    return themes[key]
end

function L.Scheme(key)
    key = COLOR[key] and key or "pathfinder"
    if schemes[key] then return schemes[key] end
    local base = W.SchemeFor and W.SchemeFor(L.Theme(key)) or { accent = COLOR[key], edge = { 0.2, 0.25, 0.3 }, bg = INK }
    local s = {}
    for k, v in pairs(base) do s[k] = v end
    s.color = COLOR[key]
    if key == "ruin" then
        -- the waypoint's own: plain gold on ink
        s.accent = GOLD
        s.bg = INK
        s.edge = mix(base.edge or { 0.2, 0.25, 0.3 }, GOLD, 0.35)
    end
    -- the waypoint's card: ink, tinted faintly in the look's color
    s.ink = key == "ruin" and INK or mix(INK, COLOR[key], 0.10)
    schemes[key] = s
    return s
end
