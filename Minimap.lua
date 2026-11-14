-- RUIN Pathfinder: the minimap's look, and the tracker docked to it.
--   Style: the game's own look (Blizzard / WoW Forever), or Pathfinder's:
--          a slim ring in Pathfinder's color with a soft shadow, an N where
--          north is, mouse-wheel zoom in place of the + and - buttons, and a
--          flat frame hugging the ring (cap above, foot below),
--          holding the tracking button, zone, calendar, addon list, mail,
--          coordinates and clock, drawn flat, so nothing sits on the map.
--   Tracker dock: the tracker sits against the minimap on the side you pick
--          and grows away from it: up from the top (on the cap, in
--          Pathfinder's style), down from the bottom, sideways from a side.
local ADDON, ns = ...
local R = RUIN_API
if not R then return end
local W = R.Widgets

local MM = {}
ns.Minimap = MM

local MEDIA = "Interface\\AddOns\\RUIN_Pathfinder\\Media\\"

MM.STYLES = { "blizzard", "pathfinder" }
MM.STYLE_LABEL = { blizzard = "Blizzard / WoW Forever", pathfinder = "Pathfinder (modern)" }

-- Where the tracker can sit: the tracker's point, the minimap's point, which
-- way it grows.
local DOCKS = {
    top    = { label = "Above",      pt = "BOTTOM", rel = "TOP",    grow = "up" },
    bottom = { label = "Below",      pt = "TOP",    rel = "BOTTOM", grow = "down" },
    left   = { label = "Left side",  pt = "RIGHT",  rel = "LEFT",   grow = "left" },
    right  = { label = "Right side", pt = "LEFT",   rel = "RIGHT",  grow = "right" },
}
MM.DOCKS = DOCKS
local DOCK_ORDER = { "top", "bottom", "left", "right" }

local db
local deco          -- Pathfinder's ring, shadow and N
local bar           -- Pathfinder's cap above the map
local saved = {}    -- the game's own regions we dimmed: region -> alpha

local function minimap() return rawget(_G, "Minimap") end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
function MM.Style() return (db and db.mmStyle == "pathfinder") and "pathfinder" or "blizzard" end
function MM.Dock()
    local d = db and db.trackerDock
    if type(d) ~= "string" then return nil end
    if DOCKS[d] then return d end
    -- a spot saved by an older Pathfinder ("topleft", "righttop"...): its side
    local side = d:match("^(top)") or d:match("^(bottom)") or d:match("^(left)") or d:match("^(right)")
    return side
end

function MM.DockChoices()
    local out = { "off" }
    for _, k in ipairs(DOCK_ORDER) do out[#out + 1] = k end
    return out
end
function MM.DockLabel(k)
    if k == nil or k == "off" then return "Off (free to move)" end
    return DOCKS[k] and DOCKS[k].label or k
end
function MM.Grow(k) local d = DOCKS[k or MM.Dock() or ""]; return d and d.grow end

local function rotating()
    local v = GetCVar and GetCVar("rotateMinimap")
    return v == "1" or v == 1 or v == true
end
MM.Rotating = rotating

---------------------------------------------------------------------------
-- The game's own pieces around the minimap (names differ between clients)
---------------------------------------------------------------------------
local function blizzardBits()
    local list, seen = {}, {}
    local function add(r) if type(r) == "table" and r.SetAlpha and not seen[r] then seen[r] = true; list[#list + 1] = r end end
    for _, n in ipairs({ "MinimapBorder", "MinimapBorderTop", "MinimapNorthTag", "MinimapCompassTexture" }) do add(rawget(_G, n)) end
    local cl = rawget(_G, "MinimapCluster")
    if type(cl) == "table" then add(cl.BorderTop) end
    -- whatever else draws the round border: a texture around the map, at
    -- least as big as it, named or drawn as a border, frame, ring or compass
    local m = minimap()
    local mw = m and m.GetWidth and m:GetWidth() or 0
    local function scan(frame)
        if type(frame) ~= "table" or not frame.GetRegions then return end
        for _, r in ipairs({ frame:GetRegions() }) do
            if type(r) == "table" and r.GetObjectType and r:GetObjectType() == "Texture" and r ~= (deco and deco.ring) then
                local text = (tostring((r.GetName and r:GetName()) or "") .. " " .. tostring((r.GetTexture and r:GetTexture()) or "")
                    .. " " .. tostring((r.GetAtlas and r:GetAtlas()) or "")):lower()
                local w = r.GetWidth and r:GetWidth() or 0
                local named = text:find("border") or text:find("ring") or text:find("compass") or text:find("minimap%-frame") or text:find("hud%-minimap")
                if named and (w == 0 or w >= mw * 0.9) and not text:find("ruin") then add(r) end
            end
        end
    end
    scan(m); scan(rawget(_G, "MinimapBackdrop")); scan(cl)
    if type(cl) == "table" then scan(cl.MinimapContainer) end
    return list
end
MM.BlizzardBits = blizzardBits
local function zoomButtons()
    local list, m = {}, minimap()
    for _, n in ipairs({ "MinimapZoomIn", "MinimapZoomOut" }) do local b = rawget(_G, n); if type(b) == "table" then list[#list + 1] = b end end
    if m and type(m.ZoomIn) == "table" then list[#list + 1] = m.ZoomIn end
    if m and type(m.ZoomOut) == "table" then list[#list + 1] = m.ZoomOut end
    return list
end
local function zoneText()
    local z = rawget(_G, "MinimapZoneTextButton")
    local cl = rawget(_G, "MinimapCluster")
    local b = z or (type(cl) == "table" and cl.ZoneTextButton) or nil
    return type(b) == "table" and b or nil
end

-- Something (the game, another addon) may show a dimmed piece again: keep it dimmed.
local keepDim = {}
local function hookAlpha(r)
    if r.ruinAlphaHook or not hooksecurefunc then return end
    r.ruinAlphaHook = true
    hooksecurefunc(r, "SetAlpha", function(self, a)
        if keepDim[self] and a and a > 0 and not self.ruinSetting then
            self.ruinSetting = true; self:SetAlpha(0); self.ruinSetting = nil
        end
    end)
end

local function dim(r, off, keepMouse)
    if type(r) ~= "table" or not r.SetAlpha then return end
    keepDim[r] = off or nil
    if off then
        if saved[r] == nil then saved[r] = (r.GetAlpha and r:GetAlpha()) or 1 end
        hookAlpha(r)
        r.ruinSetting = true; r:SetAlpha(0); r.ruinSetting = nil
        if not keepMouse and r.EnableMouse and r.IsMouseEnabled and r:GetObjectType() ~= "Texture" then
            if r.ruinMouse == nil then r.ruinMouse = r:IsMouseEnabled() end
            r:EnableMouse(false)
        end
    elseif saved[r] ~= nil then
        r.ruinSetting = true; r:SetAlpha(saved[r]); r.ruinSetting = nil
        saved[r] = nil
        if r.EnableMouse and r.ruinMouse ~= nil then r:EnableMouse(r.ruinMouse); r.ruinMouse = nil end
    end
end

---------------------------------------------------------------------------
-- Pathfinder's ring
---------------------------------------------------------------------------
-- Pathfinder's color, as its tracker wears it
local function accent()
    local f = rawget(_G, "RUIN_PathfinderTracker")
    return (f and f.themeColor) or { 0.48, 0.70, 0.41 }
end
-- Pathfinder's theme and colors, as its tracker and pages wear them
local THEME = { color = { 0.31, 0.60, 0.23 } }
local function theme()
    local f = rawget(_G, "RUIN_PathfinderTracker")
    return (f and f.ruinTheme) or THEME
end
local function scheme() return W.SchemeFor and W.SchemeFor(theme()) or { accent = accent(), edge = { 0.2, 0.3, 0.2 }, bg = { 0.05, 0.06, 0.08 } } end
local function mixed(a, b, t) return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t } end
MM.Scheme = scheme

local function buildDeco(m)
    deco = CreateFrame("Frame", "RUIN_PathfinderMinimapDeco", m)
    deco:SetAllPoints(m)
    deco:SetFrameLevel((m:GetFrameLevel() or 1) + 2)
    if deco.EnableMouse then deco:EnableMouse(false) end
    local c = accent()
    deco.shadow = deco:CreateTexture(nil, "BACKGROUND")
    deco.shadow:SetTexture(MEDIA .. "MinimapShadow")
    deco.shadow:SetVertexColor(0, 0, 0, 0.75)
    deco.ring = deco:CreateTexture(nil, "OVERLAY")
    deco.ring:SetTexture(MEDIA .. "MinimapRing")
    -- the ring in the suite's edge color, warmed toward the accent: a frame, not a highlight
    local sc = scheme()
    local rc = mixed(sc.edge, sc.accent, 0.55)
    deco.ring:SetVertexColor(rc[1], rc[2], rc[3], 1)
    deco.inner = deco:CreateTexture(nil, "OVERLAY")
    deco.inner:SetTexture(MEDIA .. "MinimapRing")
    deco.inner:SetVertexColor(0, 0, 0, 0.6)
    -- N where north is, on a dark dot
    deco.north = deco:CreateTexture(nil, "OVERLAY")
    deco.north:SetTexture(MEDIA .. "MinimapShadow")
    deco.north:SetVertexColor(0, 0, 0, 1)
    deco.north:SetSize(26, 26)
    deco.n = deco:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deco.n:SetText("N")
    deco.n:SetTextColor(c[1], c[2], c[3])
    deco.n:SetPoint("CENTER", deco.north, "CENTER", 0, 0)
end

local function layoutDeco(m)
    local size = m:GetWidth() or 140
    deco.shadow:ClearAllPoints(); deco.shadow:SetPoint("CENTER", m, "CENTER", 0, 0); deco.shadow:SetSize(size * 1.24, size * 1.24)
    deco.ring:ClearAllPoints(); deco.ring:SetPoint("CENTER", m, "CENTER", 0, 0); deco.ring:SetSize(size + 6, size + 6)
    deco.inner:ClearAllPoints(); deco.inner:SetPoint("CENTER", m, "CENTER", 0, 0); deco.inner:SetSize(size + 1, size + 1)
    MM.PlaceNorth()
end

-- The N sits where north is: on top, or, on a rotating map, wherever north
-- has turned to, on the ring.
function MM.PlaceNorth()
    if not (deco and deco:IsShown() and deco.north) then return end
    local m = minimap()
    local half = ((m and m:GetWidth()) or 140) / 2
    local a = rotating() and GetPlayerFacing and GetPlayerFacing() or 0
    if type(a) ~= "number" then a = 0 end
    deco.north:ClearAllPoints()
    deco.north:SetPoint("CENTER", m, "CENTER", math.sin(a) * (half + 1), math.cos(a) * (half + 1))
end

---------------------------------------------------------------------------
-- Pathfinder's housing: a flat frame around the ring (the cap its top half,
-- the foot its bottom half), drawn behind the map so the ring sits on it,
-- edged in the ring's color. Nothing covers the map: the icons sit in the strips
-- outside the circle.
--   Cap:  tracking, addons | zone | (sun / moon,) calendar   (the tracker docks on top)
--   Foot: mail | coordinates | clock
-- The tracking button, calendar and mail keep working but are drawn flat by
-- Pathfinder; the clock and addon count are text and keep theirs.
---------------------------------------------------------------------------
local BAR_H, FOOT_H, SLOT, EXT = 16, 16, 16, 19     -- EXT: how far the housing reaches past the map, top and bottom
local moved = {}        -- frame -> { parent, points, scale, slot, dress, ghost }
local foot              -- the housing below the map
local rows = {}         -- top / bottom: the strips the pieces sit in
local strayCoords = {}  -- coordinate text another addon drew by the map, hidden

local STRATA = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }

local function first(...)
    for i = 1, select("#", ...) do
        local f = select(i, ...)
        if type(f) == "table" and f.SetPoint and f.GetObjectType then return f end
    end
end

local function texText(r)
    return (tostring((r.GetName and r:GetName()) or "") .. " " .. tostring((r.GetTexture and r:GetTexture()) or "")
        .. " " .. tostring((r.GetAtlas and r:GetAtlas()) or "")):lower()
end

-- A day / night indicator some clients put on the ring (a sun or moon).
local function dayNight()
    local cl = rawget(_G, "MinimapCluster")
    for _, holder in ipairs({ minimap(), rawget(_G, "MinimapBackdrop"), cl }) do
        if type(holder) == "table" and holder.GetChildren then
            for _, c in ipairs({ holder:GetChildren() }) do
                local name = tostring((c.GetName and c:GetName()) or ""):lower()
                local hit = name:find("daynight") or name:find("moon") or name:find("sun") or name:find("timeofday")
                if not hit and c.GetRegions and not name:find("ruin") then
                    for _, r in ipairs({ c:GetRegions() }) do
                        if r.GetObjectType and r:GetObjectType() == "Texture" then
                            local t = texText(r)
                            if t:find("moon") or t:find("daynight") or t:find("sun_") or t:find("timeofday") then hit = true; break end
                        end
                    end
                end
                if hit and not name:find("ruin") then return c end
            end
        end
    end
end

-- The game's pieces that move into the housing. ghost: Pathfinder draws it
-- (the game's frame stays, unseen, to take the clicks); dress: which of its
-- textures to hide otherwise ("all": it's text).
local function barPieces()
    local cl = rawget(_G, "MinimapCluster")
    local ind = type(cl) == "table" and cl.IndicatorFrame or nil
    return {
        { key = "tracking", tab = "top", side = "left", ghost = "tracking",
          frame = first(type(cl) == "table" and cl.Tracking or nil, rawget(_G, "MiniMapTracking"), rawget(_G, "MiniMapTrackingButton")) },
        { key = "addons", tab = "top", side = "left", dress = "all", frame = first(rawget(_G, "AddonCompartmentFrame")) },
        { key = "calendar", tab = "top", side = "right", ghost = "calendar", frame = first(rawget(_G, "GameTimeFrame")) },
        { key = "daynight", tab = "top", side = "right", dress = "frame", frame = dayNight() },
        { key = "mail", tab = "bottom", side = "left", ghost = "mail",
          frame = first(rawget(_G, "MiniMapMailFrame"), type(ind) == "table" and ind.MailFrame or nil) },
        { key = "clock", tab = "bottom", side = "right", dress = "all", wide = true, frame = first(rawget(_G, "TimeManagerClockButton")) },
    }
end
MM.BarPieces = barPieces

local function dressing(frame, mode, out)
    out = out or {}
    if not mode or type(frame) ~= "table" or not frame.GetRegions then return out end
    for _, r in ipairs({ frame:GetRegions() }) do
        if type(r) == "table" and r.GetObjectType and r:GetObjectType() == "Texture" then
            local text = texText(r)
            if mode == "all" or text:find("border") or text:find("background") or text:find("ring") or text:find("backdrop") then out[#out + 1] = r end
        end
    end
    if type(frame.Background) == "table" then out[#out + 1] = frame.Background end
    return out
end

-- One housing (cap or foot): its background behind the map, in a lower
-- strata, edged in Pathfinder's color on the three sides that show.
local function housing(m, name, openSide)
    local h = CreateFrame("Frame", name, m:GetParent() or UIParent)
    local strata = m.GetFrameStrata and m:GetFrameStrata() or "LOW"
    local below
    for i, s in ipairs(STRATA) do if s == strata and i > 1 then below = STRATA[i - 1] end end
    if below and h.SetFrameStrata then
        h:SetFrameStrata(below)
    elseif h.SetFrameLevel then
        h:SetFrameLevel(math.max(0, (m:GetFrameLevel() or 1) - 1))
    end
    if h.EnableMouse then h:EnableMouse(false) end
    -- the suite's HUD look: its panel, its 1-pixel edges, a faint sheen and
    -- the accent band along the top
    h.ruinTheme = theme()
    if W.Skin then W.Skin(h, "bg", 0.94, "border") end
    if h.skinEdges and h.skinEdges[openSide] then h.skinEdges[openSide]:SetColorTexture(0, 0, 0, 0) end
    if openSide == "BOTTOM" then
        if W.Sheen then h.sheen = W.Sheen(h, 0.04) end
        local c = scheme().accent
        h.band = h:CreateTexture(nil, "ARTWORK")
        h.band:SetColorTexture(c[1], c[2], c[3], 0.9)
        h.band:SetHeight(2)
        h.band:SetPoint("TOPLEFT", 0, 0)
        h.band:SetPoint("TOPRIGHT", 0, 0)
    end
    -- a hairline under (or over) the strip, so the icons read as one row
    h.rule = h:CreateTexture(nil, "ARTWORK")
    h.rule:SetColorTexture(1, 1, 1, 0.05)
    h.rule:SetHeight(1)
    return h
end

-- The strip the pieces sit in: above the map, at the map's own strata.
local function row(m, key, height)
    local r = CreateFrame("Frame", nil, m:GetParent() or UIParent)
    if r.SetFrameStrata and m.GetFrameStrata then r:SetFrameStrata(m:GetFrameStrata() or "LOW") end
    if r.SetFrameLevel then r:SetFrameLevel((m:GetFrameLevel() or 1) + 5) end
    r:SetHeight(height)
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.text:SetWordWrap(false)
    r.slots = {}
    rows[key] = r
    return r
end

-- Pathfinder's flat drawing of a ghosted piece.
local function drawGhost(s, kind)
    if s.drawn then return end
    s.drawn = true
    if kind == "calendar" then
        local c = accent()
        s.page = s:CreateTexture(nil, "ARTWORK")
        s.page:SetColorTexture(0.42, 0.46, 0.5, 1)
        s.page:SetSize(14, 13)
        s.page:SetPoint("CENTER", 0, -1)
        s.inside = s:CreateTexture(nil, "ARTWORK", nil, 1)
        do local b = scheme().bg; s.inside:SetColorTexture(b[1], b[2], b[3], 1) end
        s.inside:SetPoint("TOPLEFT", s.page, "TOPLEFT", 1, -3)
        s.inside:SetPoint("BOTTOMRIGHT", s.page, "BOTTOMRIGHT", -1, 1)
        s.top = s:CreateTexture(nil, "ARTWORK", nil, 2)
        s.top:SetColorTexture(c[1], c[2], c[3], 1)
        s.top:SetPoint("TOPLEFT", s.page, "TOPLEFT", 0, 0)
        s.top:SetPoint("TOPRIGHT", s.page, "TOPRIGHT", 0, 0)
        s.top:SetHeight(3)
        s.day = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        s.day:SetPoint("CENTER", s.inside, "CENTER", 0, 0)
        local font, _, flags = s.day:GetFont()
        if font and s.day.SetFont then s.day:SetFont(font, 8, flags) end
        s.dot = s:CreateTexture(nil, "OVERLAY")
        s.dot:SetColorTexture(1, 0.82, 0, 1)
        s.dot:SetSize(4, 4)
        s.dot:SetPoint("TOPRIGHT", s.page, "TOPRIGHT", 2, 2)
        s.dot:Hide()
    else
        s.icon = s:CreateTexture(nil, "ARTWORK")
        if kind == "tracking" then
            s.icon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
            s.icon:SetSize(13, 13)
        else
            s.icon:SetTexture("Interface\\Minimap\\Tracking\\Mailbox")
            s.icon:SetSize(15, 15)
            if s.icon.SetDesaturated then s.icon:SetDesaturated(true) end
        end
        s.icon:SetPoint("CENTER", 0, 0)
        s.icon:SetVertexColor(0.82, 0.84, 0.88)
    end
end

local function buildBar(m)
    bar = housing(m, "RUIN_PathfinderMinimapBar", "BOTTOM")
    foot = housing(m, "RUIN_PathfinderMinimapFoot", "TOP")
    local top = row(m, "top", BAR_H)
    if top.text.SetFontObject and rawget(_G, "GameFontNormalSmall") then top.text:SetFontObject(GameFontNormalSmall) end
    row(m, "bottom", FOOT_H)
    bar.zone = top.text
    bar.slots = top.slots
    bar.row = top
    bar.coords = rows.bottom.text
    bar:RegisterEvent("ZONE_CHANGED")
    bar:RegisterEvent("ZONE_CHANGED_INDOORS")
    bar:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    bar:RegisterEvent("PLAYER_ENTERING_WORLD")
    bar:SetScript("OnEvent", function() MM.UpdateZone() end)
end

local function slotFor(p)
    local r = rows[p.tab]
    local s = r.slots[p.key]
    if not s then
        s = CreateFrame("Frame", nil, r)
        s:SetSize(p.wide and 32 or SLOT, SLOT)
        r.slots[p.key] = s
    end
    return s
end

local function place(f, s)
    f.ruinPlacing = true
    f:ClearAllPoints()
    f:SetPoint("CENTER", s, "CENTER", 0, 0)
    f.ruinPlacing = nil
end

local function movePiece(p)
    local f = p.frame
    if not f or moved[f] then return end
    local s = slotFor(p)
    local rec = { parent = f:GetParent(), scale = f.GetScale and f:GetScale() or 1, points = {}, slot = s, dress = dressing(f, p.dress), ghost = p.ghost }
    for i = 1, (f.GetNumPoints and f:GetNumPoints() or 0) do rec.points[i] = { f:GetPoint(i) } end
    moved[f] = rec
    f:SetParent(s)
    local h = (f.GetHeight and f:GetHeight()) or SLOT
    if h and h > 0 and f.SetScale then f:SetScale(math.min(1, SLOT / h)) end
    if p.ghost then
        drawGhost(s, p.ghost)
        dim(f, true, true)          -- unseen, but still takes the clicks
    end
    for _, r in ipairs(rec.dress) do dim(r, true) end
    if p.key == "clock" then
        local t = rawget(_G, "TimeManagerClockTicker")
        if type(t) == "table" and t.SetFontObject then t:SetFontObject(GameFontHighlightSmall) end
    end
    place(f, s)
    if not f.ruinPointHook and hooksecurefunc then
        f.ruinPointHook = true
        hooksecurefunc(f, "SetPoint", function(self)
            local r = moved[self]
            if r and not self.ruinPlacing then place(self, r.slot) end
        end)
    end
end

local function restorePiece(f)
    local rec = moved[f]
    if not rec then return end
    moved[f] = nil
    f:SetParent(rec.parent)
    if f.SetScale then f:SetScale(rec.scale or 1) end
    if rec.ghost then dim(f, false) end
    for _, r in ipairs(rec.dress) do dim(r, false) end
    f.ruinPlacing = true
    f:ClearAllPoints()
    for _, pt in ipairs(rec.points) do f:SetPoint(unpack(pt)) end
    f.ruinPlacing = nil
end

-- Coordinates another addon (or the client) prints by the map: Pathfinder's
-- foot shows them now.
local COORD = "^%s*%d+%.?%d*%s*,%s*%d+%.?%d*%s*$"
local function hideStrayCoords(off)
    if not off then
        for r in pairs(strayCoords) do dim(r, false) end
        strayCoords = {}
        return
    end
    local m, cl = minimap(), rawget(_G, "MinimapCluster")
    local near = { [m or 0] = true, [cl or 0] = true }
    local function fonts(frame, depth)
        if type(frame) ~= "table" or not frame.GetRegions or frame == bar or frame == foot then return end
        for _, r in ipairs({ frame:GetRegions() }) do
            if r.GetObjectType and r:GetObjectType() == "FontString" and r ~= (rows.bottom and rows.bottom.text) then
                local t = r.GetText and r:GetText()
                if type(t) == "string" and t:match(COORD) then strayCoords[r] = true; dim(r, true) end
            end
        end
        if depth > 0 and frame.GetChildren then
            for _, c in ipairs({ frame:GetChildren() }) do fonts(c, depth - 1) end
        end
    end
    fonts(m, 2); fonts(cl, 2); fonts(rawget(_G, "MinimapBackdrop"), 1)
    -- small frames of their own, pinned to the map
    local ui = rawget(_G, "UIParent")
    if ui and ui.GetChildren then
        for _, c in ipairs({ ui:GetChildren() }) do
            local _, rel = c.GetPoint and c:GetPoint(1)
            if rel and near[rel] then fonts(c, 1) end
        end
    end
end

local function layoutRow(r)
    local left, right = 1, 1
    for _, p in ipairs(barPieces()) do
        local s = r.slots[p.key]
        if rows[p.tab] == r then
            if p.frame then
                movePiece(p)
                s = r.slots[p.key]
                s:ClearAllPoints()
                if p.side == "left" then
                    s:SetPoint("LEFT", r, "LEFT", left, 0)
                    left = left + s:GetWidth() + 1
                else
                    s:SetPoint("RIGHT", r, "RIGHT", -right, 0)
                    right = right + s:GetWidth() + 1
                end
                s:Show()
            elseif s then
                s:Hide()
            end
        end
    end
    -- the text between the corners, centered on the map
    local pad = math.max(left, right) + 1
    r.text:ClearAllPoints()
    r.text:SetPoint("LEFT", r, "LEFT", pad, 0)
    r.text:SetPoint("RIGHT", r, "RIGHT", -pad, 0)
    r.text:SetJustifyH("CENTER")
end

-- Fill the minimap's Edit Mode box: the map grows (or shrinks) so the square
-- housing around it is as big as the box allows, centered in it. Edit Mode
-- still moves and sizes the box; the map follows.
local mapHome           -- the map's own scale and points, to give back
local function fitMap(m, on)
    local cl = rawget(_G, "MinimapCluster")
    if not on then
        if mapHome then
            m.ruinPlacing = true
            if m.SetScale then m:SetScale(mapHome.scale or 1) end
            m:ClearAllPoints()
            for _, pt in ipairs(mapHome.points) do m:SetPoint(unpack(pt)) end
            m.ruinPlacing = nil
            mapHome = nil
        end
        return
    end
    if type(cl) ~= "table" or not (cl.GetWidth and cl.GetEffectiveScale and m.GetEffectiveScale and m.SetScale) then return end
    local parent = m:GetParent()
    local pes = parent and parent.GetEffectiveScale and parent:GetEffectiveScale()
    local ces = cl:GetEffectiveScale()
    local cw, ch, w = cl:GetWidth(), cl:GetHeight(), m:GetWidth()
    if not (pes and ces and cw and ch and w and pes > 0 and w > 0 and cw > 0 and ch > 0) then return end
    if not mapHome then
        mapHome = { scale = m:GetScale() or 1, points = {} }
        for i = 1, (m:GetNumPoints() or 0) do mapHome.points[i] = { m:GetPoint(i) } end
    end
    -- the box's shorter side, in the map's parent's units
    local side = math.min(cw, ch) * ces / pes
    local d = math.max(80, side - EXT * 2)
    m.ruinPlacing = true
    m:SetScale(d / w)
    m:ClearAllPoints()
    m:SetPoint("CENTER", cl, "CENTER", 0, 0)
    m.ruinPlacing = nil
    -- the game lays the map out again now and then: keep it in the box
    if not m.ruinFitHook and hooksecurefunc then
        m.ruinFitHook = true
        hooksecurefunc(m, "SetPoint", function(self)
            if mapHome and not self.ruinPlacing and MM.Style() == "pathfinder" then
                self.ruinPlacing = true
                self:ClearAllPoints()
                self:SetPoint("CENTER", cl, "CENTER", 0, 0)
                self.ruinPlacing = nil
            end
        end)
    end
end

-- The map's size in its parent's units (it may be scaled to fit its box).
local function mapSize(m) return (m:GetWidth() or 140) * ((m.GetScale and m:GetScale()) or 1) end

local function layoutBar(m)
    local size = mapSize(m)
    local w = size + EXT * 2                -- square: as wide as it is tall
    -- the cap is the housing's top half, the foot its bottom half: together a
    -- square frame around the ring, room above for the zone and below for
    -- the coordinates; the icons sit in its corners, outside the circle
    bar:ClearAllPoints()
    bar:SetPoint("TOP", m, "TOP", 0, EXT)
    bar:SetSize(w, size / 2 + EXT)
    foot:ClearAllPoints()
    foot:SetPoint("BOTTOM", m, "BOTTOM", 0, -EXT)
    foot:SetSize(w, size / 2 + EXT)
    bar.rule:Hide(); foot.rule:Hide()
    rows.top:ClearAllPoints()
    rows.top:SetPoint("TOP", bar, "TOP", 0, -2)
    rows.top:SetWidth(w - 2)
    rows.bottom:ClearAllPoints()
    rows.bottom:SetPoint("BOTTOM", foot, "BOTTOM", 0, 1)
    rows.bottom:SetWidth(w - 2)
    layoutRow(rows.top)
    layoutRow(rows.bottom)
    MM.UpdateZone()
    MM.Tick(true)
end

function MM.UpdateZone()
    if not (bar and bar.zone) then return end
    local text = (GetMinimapZoneText and GetMinimapZoneText()) or (GetZoneText and GetZoneText()) or ""
    bar.zone:SetText(text)
    local c = scheme().accent       -- titled like the suite's panels
    bar.zone:SetTextColor(c[1], c[2], c[3])
end

-- Where you stand, as the foot shows it ("" where the game won't say).
function MM.Coords()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return "" end
    local id = C_Map.GetBestMapForUnit("player")
    local pos = id and C_Map.GetPlayerMapPosition(id, "player")
    if not pos then return "" end
    local x, y
    if pos.GetXY then x, y = pos:GetXY() else x, y = pos.x, pos.y end
    if not x or (x == 0 and y == 0) then return "" end
    return ("%.1f, %.1f"):format(x * 100, y * 100)
end

-- Keep the housing current: coordinates, the day on the calendar, the mail
-- icon showing when the game's would, and a hover light on the flat icons.
local tickCoords, tickDay = 0, 0
function MM.Tick(now, elapsed)
    if not (bar and bar:IsShown()) then return end
    tickCoords = tickCoords + (elapsed or 0)
    tickDay = tickDay + (elapsed or 0)
    if now or tickCoords >= 0.1 then
        tickCoords = 0
        bar.coords:SetText(MM.Coords())
        bar.coords:SetTextColor(0.82, 0.84, 0.88)
    end
    local c = accent()
    for f, rec in pairs(moved) do
        local s = rec.slot
        if rec.ghost then
            local over = f.IsMouseOver and f:IsMouseOver() or false
            if s.icon then
                s.icon:SetShown(f.IsShown == nil or f:IsShown())
                if over then s.icon:SetVertexColor(c[1], c[2], c[3]) else s.icon:SetVertexColor(0.82, 0.84, 0.88) end
            elseif s.day then
                if now or tickDay >= 1 then
                    s.day:SetText(date and date("%d"):gsub("^0", "") or "")
                    local inv = C_Calendar and C_Calendar.GetNumPendingInvites and C_Calendar.GetNumPendingInvites() or 0
                    s.dot:SetShown((inv or 0) > 0)
                end
                s.top:SetColorTexture(c[1], c[2], c[3], 1)
                if over then s.page:SetColorTexture(c[1], c[2], c[3], 1) else s.page:SetColorTexture(0.42, 0.46, 0.5, 1) end
            end
        end
    end
    if now or tickDay >= 1 then tickDay = 0 end
end

-- The cap above the map (Pathfinder's style), or nil: the tracker docks on it.
function MM.Bar() return (bar and bar:IsShown()) and bar or nil end
function MM.Foot() return (foot and foot:IsShown()) and foot or nil end

-- Mouse-wheel zoom, where the + and - buttons are hidden.
local function wheelZoom(m, on)
    if not m.EnableMouseWheel then return end
    if on then
        m:EnableMouseWheel(true)
        if not m:GetScript("OnMouseWheel") then
            m.ruinWheel = true
            m:SetScript("OnMouseWheel", function(self, delta)
                local z, max = self:GetZoom() or 0, (self.GetZoomLevels and self:GetZoomLevels() or 6) - 1
                self:SetZoom(math.max(0, math.min(max, z + (delta > 0 and 1 or -1))))
            end)
        end
    elseif m.ruinWheel then
        m:SetScript("OnMouseWheel", nil)
        m.ruinWheel = nil
    end
end

---------------------------------------------------------------------------
-- Apply the style
---------------------------------------------------------------------------
function MM.Apply()
    local m = minimap()
    if not (db and m) then return end
    local modern = MM.Style() == "pathfinder"
    for _, r in ipairs(blizzardBits()) do dim(r, modern) end
    for _, b in ipairs(zoomButtons()) do dim(b, modern) end
    dim(zoneText(), modern)
    wheelZoom(m, modern)
    if modern then
        fitMap(m, true)
        if not deco then buildDeco(m) end
        deco:Show()
        layoutDeco(m)
        if not bar then buildBar(m) end
        bar:Show(); foot:Show(); rows.top:Show(); rows.bottom:Show()
        layoutBar(m)
        hideStrayCoords(true)
    else
        if deco then deco:Hide() end
        fitMap(m, false)
        for f in pairs(moved) do restorePiece(f) end
        hideStrayCoords(false)
        if bar then bar:Hide(); foot:Hide(); rows.top:Hide(); rows.bottom:Hide() end
    end
end

---------------------------------------------------------------------------
-- Docking the tracker
---------------------------------------------------------------------------
-- How far the tracker sits from the map's edge: past the game's ring and
-- zone text, or past Pathfinder's slimmer ring.
local function gap(spot)
    local modern = MM.Style() == "pathfinder"
    local d = DOCKS[spot]
    if d.grow == "up" then return modern and 2 or 34 end
    if d.grow == "down" then return modern and 22 or 28 end     -- room for the tracker's tabs above it
    return modern and 8 or 18
end

-- Anchor the tracker to the minimap; true when it's docked. Above the map
-- in Pathfinder's style it sits on the cap, below it under the foot.
function MM.AnchorTracker(tracker)
    local spot = MM.Dock()
    local m = minimap()
    if not (spot and m and tracker) then return false end
    local d, g = DOCKS[spot], gap(spot)
    local dx = (d.grow == "left" and -g) or (d.grow == "right" and g) or 0
    local dy = (d.grow == "up" and g) or (d.grow == "down" and -g) or 0
    tracker:ClearAllPoints()
    local on = (spot == "top" and MM.Bar()) or (spot == "bottom" and MM.Foot()) or m
    tracker:SetPoint(d.pt, on, d.rel, dx, dy)
    return true
end

function MM.SetDock(spot)
    if spot == "off" then spot = nil end
    if spot ~= nil and not DOCKS[spot] then return false end
    db.trackerDock = spot
    if MM.OnDockChanged then MM.OnDockChanged() end
    return true
end

function MM.SetStyle(style)
    if style ~= "blizzard" and style ~= "pathfinder" then return false end
    db.mmStyle = style
    MM.Apply()
    if MM.OnDockChanged then MM.OnDockChanged() end
    return true
end

-- /path minimap debug: what's around the minimap, to find a piece RUIN missed.
function MM.Debug(print)
    local m = minimap()
    print(("Minimap: %s, %dx%d, style %s, rotating: %s"):format(tostring(m and m:GetName()), m and m:GetWidth() or 0, m and m:GetHeight() or 0,
        MM.Style(), tostring(rotating())))
    local function list(label, frame)
        if type(frame) ~= "table" or not frame.GetRegions then return print(label .. ": none") end
        for _, r in ipairs({ frame:GetRegions() }) do
            if r.GetObjectType and r:GetObjectType() == "Texture" then
                print(("%s: %s tex=%s atlas=%s %dx%d alpha=%.1f %s"):format(label, tostring(r:GetName()), tostring(r:GetTexture()), tostring(r.GetAtlas and r:GetAtlas()),
                    r:GetWidth() or 0, r:GetHeight() or 0, r:GetAlpha() or 0, r:IsShown() and "shown" or "hidden"))
            end
        end
        for _, c in ipairs({ frame:GetChildren() }) do
            print(("%s child: %s (%s) %dx%d"):format(label, tostring(c:GetName()), c:GetObjectType(), c:GetWidth() or 0, c:GetHeight() or 0))
        end
    end
    list("Minimap", m)
    list("MinimapBackdrop", rawget(_G, "MinimapBackdrop"))
    list("MinimapCluster", rawget(_G, "MinimapCluster"))
    local dimmed, onBar = 0, {}
    for _ in pairs(keepDim) do dimmed = dimmed + 1 end
    for _, p in ipairs(barPieces()) do onBar[#onBar + 1] = p.key .. "=" .. (p.frame and tostring(p.frame:GetName() or "found") or "missing") end
    print("RUIN is hiding " .. dimmed .. " of the game's minimap pieces. Bar: " .. table.concat(onBar, ", "))
end

-- Turn the N as you turn (on a rotating map).
local watcher, since = nil, 0
local function watch(_, elapsed)
    since = since + (elapsed or 0)
    if since < 0.03 then return end
    since = 0
    if rotating() then MM.PlaceNorth() end
    MM.Tick(false, 0.03)
end

function MM.Init(cdb)
    db = cdb
    db.mmShape = nil      -- an old setting, no longer used
    if db.mmStyle == nil then db.mmStyle = "blizzard" end
    -- the game's own look needs nothing; Pathfinder's is applied once the UI
    -- is up, and again when you change zones (the game rebuilds parts of the
    -- minimap then)
    watcher = watcher or CreateFrame("Frame")
    watcher:SetScript("OnUpdate", watch)
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:SetScript("OnEvent", function()
        if db.mmStyle ~= "blizzard" then C_Timer.After(1, MM.Apply) end
    end)
    if db.mmStyle ~= "blizzard" then C_Timer.After(1, MM.Apply) end
    -- Edit Mode resizes and moves the box: fit to it again when it closes
    local em = rawget(_G, "EditModeManagerFrame")
    if type(em) == "table" and em.HookScript then
        em:HookScript("OnHide", function() if db.mmStyle ~= "blizzard" then MM.Apply() end end)
    end
    local cl = rawget(_G, "MinimapCluster")
    if type(cl) == "table" and cl.HookScript then
        cl:HookScript("OnSizeChanged", function() if db.mmStyle ~= "blizzard" and C_Timer then C_Timer.After(0, MM.Apply) end end)
    end
end
