-- RUIN Pathfinder: the minimap's look, and the tracker docked to it.
--   Style: the game's own look (Blizzard / WoW Forever), or Pathfinder's:
--          a slim ring in Pathfinder's color with a soft shadow, an N where
--          north is, mouse-wheel zoom in place of the + and - buttons, and a
--          flat bar above the map holding the tracking button, the zone, the
--          clock, the calendar and the addon list, so nothing sits on the map.
--   Tracker dock: the tracker sits against the minimap on the side you pick
--          and grows away from it: up from the top (on the bar, in
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
local bar           -- Pathfinder's bar above the map
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

local function dim(r, off)
    if type(r) ~= "table" or not r.SetAlpha then return end
    keepDim[r] = off or nil
    if off then
        if saved[r] == nil then saved[r] = (r.GetAlpha and r:GetAlpha()) or 1 end
        hookAlpha(r)
        r.ruinSetting = true; r:SetAlpha(0); r.ruinSetting = nil
        if r.EnableMouse and r.IsMouseEnabled and r:GetObjectType() ~= "Texture" then
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
    deco.ring:SetVertexColor(c[1], c[2], c[3], 0.95)
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
-- Pathfinder's bar: a flat strip above the map. The game's tracking button,
-- clock, calendar and addon list move onto it, shrink to fit, and lose their
-- round frames; the zone name sits in the middle. The tracker docks on top.
---------------------------------------------------------------------------
local BAR_H, SLOT = 24, 20
local moved = {}     -- frame -> { parent, points, scale, slot }

-- The game's pieces that move onto the bar: which frame, which side, and
-- which of its textures are frame dressing to hide (the rest is the icon).
local function barPieces()
    local cl = rawget(_G, "MinimapCluster")
    local function first(...)
        for i = 1, select("#", ...) do
            local f = select(i, ...)
            if type(f) == "table" and f.SetPoint and f.GetObjectType then return f end
        end
    end
    return {
        { key = "tracking", side = "left", frame = first(type(cl) == "table" and cl.Tracking or nil, rawget(_G, "MiniMapTracking"), rawget(_G, "MiniMapTrackingButton")), dress = "frame" },
        { key = "addons", side = "right", frame = first(rawget(_G, "AddonCompartmentFrame")), dress = "all" },
        { key = "calendar", side = "right", frame = first(rawget(_G, "GameTimeFrame")), dress = "frame" },
        { key = "clock", side = "right", frame = first(rawget(_G, "TimeManagerClockButton")), dress = "all", wide = true },
    }
end
MM.BarPieces = barPieces

-- Its textures that are frame dressing: borders, backgrounds, rings (or, for
-- "all", every texture: the clock and addon count are text).
local function dressing(frame, mode, out)
    out = out or {}
    if type(frame) ~= "table" or not frame.GetRegions then return out end
    for _, r in ipairs({ frame:GetRegions() }) do
        if type(r) == "table" and r.GetObjectType and r:GetObjectType() == "Texture" then
            local text = (tostring((r.GetName and r:GetName()) or "") .. " " .. tostring((r.GetTexture and r:GetTexture()) or "")
                .. " " .. tostring((r.GetAtlas and r:GetAtlas()) or "")):lower()
            if mode == "all" or text:find("border") or text:find("background") or text:find("ring") or text:find("backdrop") then out[#out + 1] = r end
        end
    end
    -- a frame that is only a holder (the retail tracking frame): its background child too
    if type(frame.Background) == "table" then out[#out + 1] = frame.Background end
    return out
end

local function buildBar(m)
    bar = CreateFrame("Frame", "RUIN_PathfinderMinimapBar", m:GetParent() or UIParent)
    bar:SetFrameStrata(m.GetFrameStrata and m:GetFrameStrata() or "LOW")
    bar:SetFrameLevel((m:GetFrameLevel() or 1) + 5)
    bar:SetHeight(BAR_H)
    if W.Skin then W.Skin(bar, "bg", 0.92, "border") end
    local c = accent()
    bar.band = bar:CreateTexture(nil, "ARTWORK")
    bar.band:SetColorTexture(c[1], c[2], c[3], 0.9)
    bar.band:SetHeight(1)
    bar.band:SetPoint("BOTTOMLEFT", 4, 0)
    bar.band:SetPoint("BOTTOMRIGHT", -4, 0)
    bar.zone = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.zone:SetWordWrap(false)
    bar.slots = {}
    bar:RegisterEvent("ZONE_CHANGED")
    bar:RegisterEvent("ZONE_CHANGED_INDOORS")
    bar:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    bar:RegisterEvent("PLAYER_ENTERING_WORLD")
    bar:SetScript("OnEvent", function() MM.UpdateZone() end)
end

local function slotFor(key, wide)
    local s = bar.slots[key]
    if not s then
        s = CreateFrame("Frame", nil, bar)
        s:SetSize(wide and 40 or SLOT, SLOT)
        bar.slots[key] = s
    end
    return s
end

-- Put a game piece in a slot: in the middle, scaled to the slot's height.
local function place(f, s)
    f.ruinPlacing = true
    f:ClearAllPoints()
    f:SetPoint("CENTER", s, "CENTER", 0, 0)
    f.ruinPlacing = nil
end

local function movePiece(p)
    local f = p.frame
    if not f or moved[f] then return end
    local rec = { parent = f:GetParent(), scale = f.GetScale and f:GetScale() or 1, points = {}, slot = slotFor(p.key, p.wide), dress = dressing(f, p.dress) }
    for i = 1, (f.GetNumPoints and f:GetNumPoints() or 0) do rec.points[i] = { f:GetPoint(i) } end
    moved[f] = rec
    f:SetParent(rec.slot)
    local h = (f.GetHeight and f:GetHeight()) or SLOT
    if h and h > 0 and f.SetScale then f:SetScale(math.min(1, SLOT / h)) end
    for _, r in ipairs(rec.dress) do dim(r, true) end
    if p.key == "clock" then
        local t = rawget(_G, "TimeManagerClockTicker")
        if type(t) == "table" and t.SetFontObject then t:SetFontObject(GameFontHighlightSmall) end
    end
    place(f, rec.slot)
    -- the game lays some of these out again on its own: put them back on the bar
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
    for _, r in ipairs(rec.dress) do dim(r, false) end
    f.ruinPlacing = true
    f:ClearAllPoints()
    for _, pt in ipairs(rec.points) do f:SetPoint(unpack(pt)) end
    f.ruinPlacing = nil
end

local function layoutBar(m)
    local size = m:GetWidth() or 140
    bar:ClearAllPoints()
    bar:SetPoint("BOTTOM", m, "TOP", 0, 8)
    bar:SetWidth(size + 8)
    -- left to right: tracking | zone | clock, calendar, addons
    local left, right = 3, 3
    local leftEdge, rightEdge
    for _, p in ipairs(barPieces()) do
        if p.frame then
            movePiece(p)
            local s = bar.slots[p.key]
            s:ClearAllPoints()
            if p.side == "left" then
                s:SetPoint("LEFT", bar, "LEFT", left, 0)
                left = left + s:GetWidth() + 2
                leftEdge = s
            else
                s:SetPoint("RIGHT", bar, "RIGHT", -right, 0)
                right = right + s:GetWidth() + 2
                rightEdge = s
            end
            s:Show()
        elseif bar.slots[p.key] then
            bar.slots[p.key]:Hide()
        end
    end
    bar.zone:ClearAllPoints()
    bar.zone:SetPoint("LEFT", bar, "LEFT", left + 2, 0)
    bar.zone:SetPoint("RIGHT", bar, "RIGHT", -right - 2, 0)
    bar.zone:SetJustifyH(leftEdge and "LEFT" or "CENTER")
    MM.UpdateZone()
end

function MM.UpdateZone()
    if not (bar and bar.zone) then return end
    local text = (GetMinimapZoneText and GetMinimapZoneText()) or (GetZoneText and GetZoneText()) or ""
    bar.zone:SetText(text)
    local pvp = GetZonePVPInfo and GetZonePVPInfo()
    local col = ({ sanctuary = { 0.41, 0.8, 0.94 }, friendly = { 0.1, 1, 0.1 }, hostile = { 1, 0.1, 0.1 }, contested = { 1, 0.7, 0 } })[pvp or ""]
    if col then bar.zone:SetTextColor(col[1], col[2], col[3]) else bar.zone:SetTextColor(1, 0.82, 0) end
end

-- The bar above the map (Pathfinder's style), or nil.
function MM.Bar() return (bar and bar:IsShown()) and bar or nil end

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
        if not deco then buildDeco(m) end
        deco:Show()
        layoutDeco(m)
        if not bar then buildBar(m) end
        bar:Show()
        layoutBar(m)
    else
        if deco then deco:Hide() end
        for f in pairs(moved) do restorePiece(f) end
        if bar then bar:Hide() end
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
    if d.grow == "down" then return modern and 26 or 28 end     -- room for the tracker's tabs above it
    return modern and 8 or 18
end

-- Anchor the tracker to the minimap; true when it's docked. Above the map
-- in Pathfinder's style, it sits on the bar, as wide as it.
function MM.AnchorTracker(tracker)
    local spot = MM.Dock()
    local m = minimap()
    if not (spot and m and tracker) then return false end
    local d, g = DOCKS[spot], gap(spot)
    local dx = (d.grow == "left" and -g) or (d.grow == "right" and g) or 0
    local dy = (d.grow == "up" and g) or (d.grow == "down" and -g) or 0
    tracker:ClearAllPoints()
    local onBar = spot == "top" and MM.Bar()
    tracker:SetPoint(d.pt, onBar or m, d.rel, dx, dy)
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
end
