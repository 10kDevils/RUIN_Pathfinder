-- RUIN Pathfinder: the minimap's shape and look, and the tracker docked to it.
--   Shape: round (the game's) or square.
--   Style: the game's own look (Blizzard / WoW Forever), or Pathfinder's:
--          a slim ring (or square edge) in Pathfinder's color with a soft
--          shadow, an N at the top, the zone name in a pill, and mouse-wheel
--          zoom in place of the + and - buttons.
--   Tracker dock: the tracker sits against the minimap on the side you pick
--          (the spots follow the shape) and grows away from it: up from the
--          top, down from the bottom, left or right from the sides.
local ADDON, ns = ...
local R = RUIN_API
if not R then return end
local W = R.Widgets

local MM = {}
ns.Minimap = MM

local MEDIA = "Interface\\AddOns\\RUIN_Pathfinder\\Media\\"
-- The round mask: Pathfinder's own (the game's mask files differ between
-- clients, and WoW Forever's has neither the classic nor the modern one by
-- those names). RUIN only touches the mask once you pick square, so the
-- game's own round map stays as it is until then.
local ROUND_MASK = MEDIA .. "MinimapMask"
local SQUARE_MASK = "Interface\\BUTTONS\\WHITE8X8"
local maskSet = false   -- RUIN has put the square mask on

MM.SHAPES = { "round", "square" }
MM.STYLES = { "blizzard", "pathfinder" }
MM.SHAPE_LABEL = { round = "Round", square = "Square" }
MM.STYLE_LABEL = { blizzard = "Blizzard / WoW Forever", pathfinder = "Pathfinder (modern)" }

-- Where the tracker can sit: a round minimap has a top, a bottom and two
-- sides; a square one also has the ends of each edge. Each spot: the
-- tracker's point, the minimap's point, which way it grows.
local DOCKS = {
    top         = { label = "Above",              pt = "BOTTOM",      rel = "TOP",         grow = "up" },
    topleft     = { label = "Above, left edge",   pt = "BOTTOMLEFT",  rel = "TOPLEFT",     grow = "up" },
    topright    = { label = "Above, right edge",  pt = "BOTTOMRIGHT", rel = "TOPRIGHT",    grow = "up" },
    bottom      = { label = "Below",              pt = "TOP",         rel = "BOTTOM",      grow = "down" },
    bottomleft  = { label = "Below, left edge",   pt = "TOPLEFT",     rel = "BOTTOMLEFT",  grow = "down" },
    bottomright = { label = "Below, right edge",  pt = "TOPRIGHT",    rel = "BOTTOMRIGHT", grow = "down" },
    left        = { label = "Left side",          pt = "RIGHT",       rel = "LEFT",        grow = "left" },
    lefttop     = { label = "Left side, top",     pt = "TOPRIGHT",    rel = "TOPLEFT",     grow = "left" },
    leftbottom  = { label = "Left side, bottom",  pt = "BOTTOMRIGHT", rel = "BOTTOMLEFT",  grow = "left" },
    right       = { label = "Right side",         pt = "LEFT",        rel = "RIGHT",       grow = "right" },
    righttop    = { label = "Right side, top",    pt = "TOPLEFT",     rel = "TOPRIGHT",    grow = "right" },
    rightbottom = { label = "Right side, bottom", pt = "BOTTOMLEFT",  rel = "BOTTOMRIGHT", grow = "right" },
}
MM.DOCKS = DOCKS
local DOCK_ORDER = {
    round = { "top", "bottom", "left", "right" },
    square = { "topleft", "top", "topright", "bottomleft", "bottom", "bottomright",
               "lefttop", "left", "leftbottom", "righttop", "right", "rightbottom" },
}
-- the nearest spot on the other shape
local ROUND_OF = { topleft = "top", topright = "top", bottomleft = "bottom", bottomright = "bottom",
                   lefttop = "left", leftbottom = "left", righttop = "right", rightbottom = "right" }

local db
local deco          -- Pathfinder's ring, shadow, N, zone pill
local blizzBox      -- the Blizzard-style square border
local saved = {}    -- the game's own regions we dimmed: region -> alpha
local origShape     -- GetMinimapShape before RUIN set it

local function minimap() return rawget(_G, "Minimap") end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
function MM.Shape() return (db and db.mmShape == "square") and "square" or "round" end
function MM.Style() return (db and db.mmStyle == "pathfinder") and "pathfinder" or "blizzard" end
function MM.Dock()
    local d = db and db.trackerDock
    if not (d and DOCKS[d]) then return nil end
    if MM.Shape() == "round" and ROUND_OF[d] then return ROUND_OF[d] end
    return d
end

-- The spots for the current shape: { "off", "top", ... }
function MM.DockChoices()
    local out = { "off" }
    for _, k in ipairs(DOCK_ORDER[MM.Shape()]) do out[#out + 1] = k end
    return out
end
function MM.DockLabel(k)
    if k == nil or k == "off" then return "Off (free to move)" end
    return DOCKS[k] and DOCKS[k].label or k
end
function MM.Grow(k) local d = DOCKS[k or MM.Dock() or ""]; return d and d.grow end

---------------------------------------------------------------------------
-- The game's own regions around the minimap (names differ between clients)
---------------------------------------------------------------------------
local function blizzardBits()
    local list = {}
    local function add(r) if type(r) == "table" and r.SetAlpha then list[#list + 1] = r end end
    local seen = {}
    local function addOnce(r) if type(r) == "table" and not seen[r] then seen[r] = true; add(r) end end
    for _, n in ipairs({ "MinimapBorder", "MinimapBorderTop", "MinimapNorthTag", "MinimapCompassTexture" }) do addOnce(rawget(_G, n)) end
    local cl = rawget(_G, "MinimapCluster")
    if type(cl) == "table" then addOnce(cl.BorderTop) end
    -- whatever else draws the round border: a texture around the map, at
    -- least as big as it, named or drawn as a border, frame, ring or compass
    local m = minimap()
    local mw = m and m.GetWidth and m:GetWidth() or 0
    local function scan(frame)
        if type(frame) ~= "table" or not frame.GetRegions then return end
        for _, r in ipairs({ frame:GetRegions() }) do
            if type(r) == "table" and r.GetObjectType and r:GetObjectType() == "Texture" and r ~= (deco and deco.ring) then
                local name = (r.GetName and r:GetName()) or ""
                local tex = r.GetTexture and r:GetTexture()
                local atlas = r.GetAtlas and r:GetAtlas()
                local text = (tostring(name) .. " " .. tostring(tex or "") .. " " .. tostring(atlas or "")):lower()
                local w = r.GetWidth and r:GetWidth() or 0
                local named = text:find("border") or text:find("ring") or text:find("compass") or text:find("minimap%-frame") or text:find("hud%-minimap")
                if named and (w == 0 or w >= mw * 0.9) and not text:find("ruin") then addOnce(r) end
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
        if r.EnableMouse and r.IsMouseEnabled then r.ruinMouse = r.ruinMouse == nil and r:IsMouseEnabled() or r.ruinMouse; r:EnableMouse(false) end
    elseif saved[r] ~= nil then
        r.ruinSetting = true; r:SetAlpha(saved[r]); r.ruinSetting = nil
        saved[r] = nil
        if r.EnableMouse and r.ruinMouse ~= nil then r:EnableMouse(r.ruinMouse); r.ruinMouse = nil end
    end
end

---------------------------------------------------------------------------
-- Pathfinder's look
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
    -- round: a shadow outside, a ring on the edge
    deco.shadow = deco:CreateTexture(nil, "BACKGROUND")
    deco.shadow:SetTexture(MEDIA .. "MinimapShadow")
    deco.shadow:SetVertexColor(0, 0, 0, 0.75)
    deco.ring = deco:CreateTexture(nil, "OVERLAY")
    deco.ring:SetTexture(MEDIA .. "MinimapRing")
    deco.ring:SetVertexColor(c[1], c[2], c[3], 0.95)
    deco.inner = deco:CreateTexture(nil, "OVERLAY")
    deco.inner:SetTexture(MEDIA .. "MinimapRing")
    deco.inner:SetVertexColor(0, 0, 0, 0.6)
    -- square: four edges in the color, a dark line outside them, a shadow
    deco.edges, deco.outer = {}, {}
    local function edge(list, layer, r, g, b, a)
        for i = 1, 4 do
            local t = deco:CreateTexture(nil, layer)
            t:SetColorTexture(r, g, b, a)
            list[i] = t
        end
    end
    edge(deco.edges, "OVERLAY", c[1], c[2], c[3], 0.95)
    edge(deco.outer, "BORDER", 0, 0, 0, 0.85)
    deco.sqShadow = deco:CreateTexture(nil, "BACKGROUND")
    deco.sqShadow:SetColorTexture(0, 0, 0, 0.45)
    -- N at the top, on a dark dot
    deco.north = deco:CreateTexture(nil, "OVERLAY")
    deco.north:SetTexture(MEDIA .. "MinimapShadow")
    deco.north:SetVertexColor(0, 0, 0, 1)
    deco.north:SetSize(26, 26)
    deco.n = deco:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deco.n:SetText("N")
    deco.n:SetTextColor(c[1], c[2], c[3])
    -- the zone name, in a pill above the map
    deco.zone = CreateFrame("Frame", nil, deco)
    deco.zone:SetHeight(18)
    if W.Skin then W.Skin(deco.zone, "bg", 0.9, "border") end
    deco.zone.text = deco.zone:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    deco.zone.text:SetPoint("CENTER", 0, 0)
    deco.zone.band = deco.zone:CreateTexture(nil, "ARTWORK")
    deco.zone.band:SetColorTexture(c[1], c[2], c[3], 0.9)
    deco.zone.band:SetHeight(1)
    deco.zone.band:SetPoint("BOTTOMLEFT", 6, 0)
    deco.zone.band:SetPoint("BOTTOMRIGHT", -6, 0)
    deco:RegisterEvent("ZONE_CHANGED")
    deco:RegisterEvent("ZONE_CHANGED_INDOORS")
    deco:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    deco:RegisterEvent("PLAYER_ENTERING_WORLD")
    deco:SetScript("OnEvent", function() MM.UpdateZone() end)
end

function MM.UpdateZone()
    if not (deco and deco.zone) then return end
    local text = (GetMinimapZoneText and GetMinimapZoneText()) or (GetZoneText and GetZoneText()) or ""
    deco.zone.text:SetText(text)
    local pvp = GetZonePVPInfo and GetZonePVPInfo()
    local col = ({ sanctuary = { 0.41, 0.8, 0.94 }, friendly = { 0.1, 1, 0.1 }, hostile = { 1, 0.1, 0.1 }, contested = { 1, 0.7, 0 } })[pvp or ""]
    if col then deco.zone.text:SetTextColor(col[1], col[2], col[3]) else deco.zone.text:SetTextColor(1, 0.82, 0) end
    local w = (deco.zone.text.GetStringWidth and deco.zone.text:GetStringWidth()) or 80
    deco.zone:SetWidth(math.min(220, math.max(60, w + 20)))
end

local function layoutDeco(m, square)
    local size = m:GetWidth() or 140
    deco.shadow:ClearAllPoints(); deco.shadow:SetPoint("CENTER", m, "CENTER", 0, 0); deco.shadow:SetSize(size * 1.24, size * 1.24)
    deco.ring:ClearAllPoints(); deco.ring:SetPoint("CENTER", m, "CENTER", 0, 0); deco.ring:SetSize(size + 6, size + 6)
    deco.inner:ClearAllPoints(); deco.inner:SetPoint("CENTER", m, "CENTER", 0, 0); deco.inner:SetSize(size + 1, size + 1)
    for _, t in ipairs({ deco.shadow, deco.ring, deco.inner }) do t:SetShown(not square) end
    -- square edges: top, bottom, left, right
    local function place(list, out, thick)
        local t, b, l, r = list[1], list[2], list[3], list[4]
        t:ClearAllPoints(); t:SetPoint("BOTTOMLEFT", m, "TOPLEFT", -out - thick, out); t:SetPoint("BOTTOMRIGHT", m, "TOPRIGHT", out + thick, out); t:SetHeight(thick)
        b:ClearAllPoints(); b:SetPoint("TOPLEFT", m, "BOTTOMLEFT", -out - thick, -out); b:SetPoint("TOPRIGHT", m, "BOTTOMRIGHT", out + thick, -out); b:SetHeight(thick)
        l:ClearAllPoints(); l:SetPoint("TOPRIGHT", m, "TOPLEFT", -out, out); l:SetPoint("BOTTOMRIGHT", m, "BOTTOMLEFT", -out, -out); l:SetWidth(thick)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", m, "TOPRIGHT", out, out); r:SetPoint("BOTTOMLEFT", m, "BOTTOMRIGHT", out, -out); r:SetWidth(thick)
        for _, x in ipairs(list) do x:SetShown(square) end
    end
    place(deco.edges, 0, 2)
    place(deco.outer, 2, 1)
    deco.sqShadow:ClearAllPoints()
    deco.sqShadow:SetPoint("TOPLEFT", m, "TOPLEFT", -6, 6)
    deco.sqShadow:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", 6, -6)
    deco.sqShadow:SetShown(square)
    deco.north:ClearAllPoints(); deco.north:SetPoint("CENTER", m, "TOP", 0, square and 0 or -1)
    deco.n:ClearAllPoints(); deco.n:SetPoint("CENTER", deco.north, "CENTER", 0, 0)
    deco.zone:ClearAllPoints(); deco.zone:SetPoint("BOTTOM", m, "TOP", 0, square and 12 or 14)
    MM.UpdateZone()
end

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
-- Apply the shape and style
---------------------------------------------------------------------------
function MM.Apply()
    local m = minimap()
    if not (db and m) then return end
    local square, modern = MM.Shape() == "square", MM.Style() == "pathfinder"
    -- shape: the mask, and what other addons ask (minimap buttons follow it)
    if m.SetMaskTexture then
        -- the game (or WoW Forever's own UI) may put its round mask back:
        -- while the map is square, put the square one back over it
        if not m.ruinMaskHook and hooksecurefunc then
            m.ruinMaskHook = true
            hooksecurefunc(m, "SetMaskTexture", function(self, t)
                if MM.Shape() == "square" and not self.ruinMasking and t ~= SQUARE_MASK then
                    self.ruinMasking = true; self:SetMaskTexture(SQUARE_MASK); self.ruinMasking = nil
                end
            end)
        end
        m.ruinMasking = true
        if square then
            m:SetMaskTexture(SQUARE_MASK)
            maskSet = true
        elseif maskSet then
            m:SetMaskTexture(ROUND_MASK)
            maskSet = false
        end
        m.ruinMasking = nil
        -- quest and dig-site blobs draw a round ring of their own
        if m.SetArchBlobRingScalar then pcall(m.SetArchBlobRingScalar, m, square and 0 or 1) end
        if m.SetQuestBlobRingScalar then pcall(m.SetQuestBlobRingScalar, m, square and 0 or 1) end
    end
    if square then
        if origShape == nil then origShape = rawget(_G, "GetMinimapShape") or false end
        _G.GetMinimapShape = function() return "SQUARE" end
    elseif origShape ~= nil then
        _G.GetMinimapShape = origShape or nil
        origShape = nil
    end
    -- the game's border: dimmed when Pathfinder draws its own, or when the map is square
    for _, r in ipairs(blizzardBits()) do dim(r, modern or square) end
    for _, b in ipairs(zoomButtons()) do dim(b, modern) end
    dim(zoneText(), modern)
    wheelZoom(m, modern)
    -- Pathfinder's look
    if modern then
        if not deco then buildDeco(m) end
        deco:Show()
        layoutDeco(m, square)
    elseif deco then
        deco:Hide()
    end
    -- Blizzard's look on a square map: a classic tooltip-style frame around it
    if square and not modern then
        if not blizzBox then
            blizzBox = CreateFrame("Frame", nil, m, BackdropTemplateMixin and "BackdropTemplate" or nil)
            blizzBox:SetPoint("TOPLEFT", m, "TOPLEFT", -5, 5)
            blizzBox:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", 5, -5)
            blizzBox:SetFrameLevel((m:GetFrameLevel() or 1) + 2)
            if blizzBox.SetBackdrop then
                blizzBox:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
                if blizzBox.SetBackdropBorderColor then blizzBox:SetBackdropBorderColor(0.85, 0.85, 0.85, 1) end
            end
            if blizzBox.EnableMouse then blizzBox:EnableMouse(false) end
        end
        blizzBox:Show()
    elseif blizzBox then
        blizzBox:Hide()
    end
    if MM.OnShapeChanged then MM.OnShapeChanged() end
end

---------------------------------------------------------------------------
-- Docking the tracker
---------------------------------------------------------------------------
-- How far the tracker sits from the map's edge: past the game's ring and
-- zone text, or past Pathfinder's slimmer edge.
local function gap(spot)
    local modern, square = MM.Style() == "pathfinder", MM.Shape() == "square"
    local d = DOCKS[spot]
    if d.grow == "up" then return modern and 36 or (square and 30 or 34) end
    if d.grow == "down" then return modern and 26 or 28 end     -- room for the tracker's tabs above it
    if modern then return 8 end
    return square and 8 or 18
end

-- Anchor the tracker to the minimap; true when it's docked.
function MM.AnchorTracker(tracker)
    local spot = MM.Dock()
    local m = minimap()
    if not (spot and m and tracker) then return false end
    local d, g = DOCKS[spot], gap(spot)
    local dx = (d.grow == "left" and -g) or (d.grow == "right" and g) or 0
    local dy = (d.grow == "up" and g) or (d.grow == "down" and -g) or 0
    tracker:ClearAllPoints()
    tracker:SetPoint(d.pt, m, d.rel, dx, dy)
    return true
end

function MM.SetDock(spot)
    if spot == "off" then spot = nil end
    if spot ~= nil and not DOCKS[spot] then return false end
    db.trackerDock = spot
    if MM.OnDockChanged then MM.OnDockChanged() end
    return true
end

function MM.SetShape(shape)
    if shape ~= "round" and shape ~= "square" then return false end
    db.mmShape = shape
    -- a square-only spot moves to the nearest round one
    if shape == "round" and db.trackerDock and ROUND_OF[db.trackerDock] then db.trackerDock = ROUND_OF[db.trackerDock] end
    MM.Apply()
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

-- /path minimap debug: what's around the minimap, to find a border RUIN missed.
function MM.Debug(print)
    local m = minimap()
    print(("Minimap: %s, %dx%d, shape %s, style %s, square mask set: %s"):format(tostring(m and m:GetName()), m and m:GetWidth() or 0, m and m:GetHeight() or 0,
        MM.Shape(), MM.Style(), tostring(maskSet)))
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
    local dimmed = 0
    for _ in pairs(keepDim) do dimmed = dimmed + 1 end
    print("RUIN is hiding " .. dimmed .. " of the game's minimap pieces.")
end

function MM.Init(cdb)
    db = cdb
    if db.mmShape == nil then db.mmShape = "round" end
    if db.mmStyle == nil then db.mmStyle = "blizzard" end
    -- the game's own look on a round map needs nothing; anything else is
    -- applied once the UI is up, and again when you change zones (the game
    -- rebuilds parts of the minimap then)
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:SetScript("OnEvent", function()
        if db.mmShape ~= "round" or db.mmStyle ~= "blizzard" then C_Timer.After(1, MM.Apply) end
    end)
    if db.mmShape ~= "round" or db.mmStyle ~= "blizzard" then
        C_Timer.After(1, MM.Apply)
    end
end
