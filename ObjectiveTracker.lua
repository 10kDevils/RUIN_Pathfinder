-- RUIN Pathfinder: the game's objective tracker, in the game's own look or
-- in Pathfinder's, the minimap's design language: a panel behind it in the
-- suite's HUD look (its edges, the accent band along the top, a slight green
-- to black gradient at the opacity you pick), headers in Pathfinder's color
-- with a short rule beneath, quest titles in the suite's white, objectives in
-- its quieter grey with an accent dash, finished ones in green.
-- Only colors and the panel change: the game still lays the tracker out,
-- sizes its text and handles its buttons.
local ADDON, ns = ...
local R = RUIN_API
if not R then return end
local W = R.Widgets
local MM = ns.Minimap

local OT = {}
ns.Objectives = OT

OT.STYLES = { "blizzard", "pathfinder" }
OT.STYLE_LABEL = { blizzard = "Blizzard / WoW Forever", pathfinder = "Pathfinder (modern)" }

local PAD = 8
local TITLE = { 0.95, 0.96, 0.98 }
local LINE = { 0.74, 0.78, 0.84 }
local DONE = { 0.52, 0.84, 0.48 }

local db
local back             -- the panel behind the tracker
local styled = {}      -- fontstring -> true: colored by Pathfinder
local rules = {}       -- module header -> its accent rule

local function tracker() return rawget(_G, "ObjectiveTrackerFrame") end

function OT.Style() return (db and db.otStyle == "pathfinder") and "pathfinder" or "blizzard" end
function OT.Alpha() return (db and db.otAlpha) or 0.85 end

local function accent() return MM.Scheme().accent end

local function color(fs, c)
    if type(fs) ~= "table" or not fs.SetTextColor then return end
    styled[fs] = true
    fs:SetTextColor(c[1], c[2], c[3])
end

local function shown(f) return type(f) == "table" and (f.IsShown == nil or f:IsShown()) end

-- A header (the tracker's or a section's): accent text, the game's backdrop
-- hidden, a short accent rule under the text.
local function styleHeader(h)
    if type(h) ~= "table" then return end
    color(h.Text, accent())
    if h.Background then MM.Dim(h.Background, true) end
    local rule = rules[h]
    if not rule and h.CreateTexture then
        rule = h:CreateTexture(nil, "ARTWORK")
        rule:SetHeight(1)
        rules[h] = rule
        if h.Text and h.Text.GetObjectType then
            rule:SetPoint("TOPLEFT", h.Text, "BOTTOMLEFT", 0, -3)
        else
            rule:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", 0, 0)
        end
        rule:SetWidth(28)
    end
    if rule then
        local c = accent()
        rule:SetColorTexture(c[1], c[2], c[3], 0.8)
        rule:Show()
    end
end

-- A quest line: its finished check (or color) decides.
local function finished(line)
    local icon = line.Icon or line.Check
    return type(icon) == "table" and icon.IsShown and icon:IsShown() or line.state == "COMPLETED" or line.completed == true
end

-- Walk a section: quest blocks (HeaderText) and their lines (Text + Dash).
local function styleTree(f, depth)
    if type(f) ~= "table" or depth > 5 or not shown(f) then return end
    if f.HeaderText and not (f.IsMouseOver and f:IsMouseOver()) then color(f.HeaderText, TITLE) end
    if f.Text and f.Dash then
        color(f.Text, finished(f) and DONE or LINE)
        color(f.Dash, accent())
    end
    if f.Header and f ~= tracker() then styleHeader(f.Header) end
    if f.GetChildren then
        for _, c in ipairs({ f:GetChildren() }) do styleTree(c, depth + 1) end
    end
end

-- The box around everything the tracker shows: its text and its buttons
-- (the quest markers on the left, item buttons on the right, the collapse
-- buttons), in the tracker's own units. Container frames don't count: the
-- tracker itself is as tall as its Edit Mode box, not its contents.
local function visible(x)
    if type(x) ~= "table" then return false end
    if x.IsVisible then return x:IsVisible() end
    return x.IsShown == nil or x:IsShown()
end

local function contentBounds(f)
    local fes = (f.GetEffectiveScale and f:GetEffectiveScale()) or 1
    local l, r, t, b
    local function add(x)
        if not (x.GetLeft and x:GetLeft()) then return end
        local es = (x.GetEffectiveScale and x:GetEffectiveScale()) or fes
        local k = es / fes
        local xl, xr, xt, xb = x:GetLeft() * k, x:GetRight() * k, x:GetTop() * k, x:GetBottom() * k
        if xr - xl < 1 or xt - xb < 1 then return end
        l = (l and math.min(l, xl)) or xl
        r = (r and math.max(r, xr)) or xr
        t = (t and math.max(t, xt)) or xt
        b = (b and math.min(b, xb)) or xb
    end
    local function walk(x, depth)
        if depth > 7 or not visible(x) or x == back then return end
        local kind = x.GetObjectType and x:GetObjectType()
        if x ~= f and (kind == "Button" or kind == "CheckButton") then add(x) end
        if x.GetRegions then
            for _, reg in ipairs({ x:GetRegions() }) do
                if reg.GetObjectType and reg:GetObjectType() == "FontString" and visible(reg) then
                    local text = reg.GetText and reg:GetText()
                    if type(text) == "string" and text ~= "" then add(reg) end
                end
            end
        end
        if x.GetChildren then
            for _, c in ipairs({ x:GetChildren() }) do walk(c, depth + 1) end
        end
    end
    walk(f, 1)
    return l, r, t, b
end

local function buildBack(f)
    back = CreateFrame("Frame", "RUIN_PathfinderObjectivesBack", f)
    if back.SetFrameStrata then back:SetFrameStrata("BACKGROUND") end
    if back.EnableMouse then back:EnableMouse(false) end
    back.ruinTheme = { color = (MM.Scheme().color) or { 0.31, 0.60, 0.23 } }
    if W.Skin then W.Skin(back, "bg", 0.9, "border") end
    if W.Sheen then back.sheen = W.Sheen(back, 0.04) end
    back.band = back:CreateTexture(nil, "ARTWORK")
    back.band:SetHeight(2)
    back.band:SetPoint("TOPLEFT", 0, 0)
    back.band:SetPoint("TOPRIGHT", 0, 0)
end

local function layoutBack(f)
    local l, r, t, b = contentBounds(f)
    back:ClearAllPoints()
    if l and f.GetLeft and f:GetLeft() then
        -- room around it all: a little more at the top for the accent band
        local fl, fb = f:GetLeft(), f:GetBottom()
        back:SetPoint("TOPLEFT", f, "BOTTOMLEFT", l - fl - PAD, t - fb + PAD + 2)
        back:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", r - fl + PAD, b - fb - PAD)
    else
        back:SetPoint("TOPLEFT", f, "TOPLEFT", -PAD, PAD)
        back:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", PAD, -PAD)
    end
    local c = accent()
    back.band:SetColorTexture(c[1], c[2], c[3], 0.9)
    MM.Paint(back, OT.Alpha(), 0.14, -0.6)
    back:SetShown(shown(f))
end

-- One pass over the tracker: the panel's size, the colors.
function OT.Refresh()
    local f = tracker()
    if not (db and f) or OT.Style() ~= "pathfinder" then return end
    if not back then buildBack(f) end
    layoutBack(f)
    styleHeader(f.Header)
    if type(f.modules) == "table" then
        for _, mod in ipairs(f.modules) do styleTree(mod, 1) end
    else
        styleTree(f, 1)
    end
end

-- Hand the tracker back to the game: its colors, its header backdrops.
local function restore()
    local f = tracker()
    if back then back:Hide() end
    for h, rule in pairs(rules) do
        rule:Hide()
        if h.Background then MM.Dim(h.Background, false) end
    end
    styled = {}
    -- the game repaints its own colors on its next update: ask for one now
    local mgr = rawget(_G, "ObjectiveTrackerManager")
    if type(mgr) == "table" and mgr.UpdateAll then pcall(mgr.UpdateAll, mgr)
    elseif type(f) == "table" and f.Update then pcall(f.Update, f)
    elseif ObjectiveTracker_Update then pcall(ObjectiveTracker_Update) end
end

function OT.Apply()
    if not db then return end
    if OT.Style() == "pathfinder" then OT.Refresh() else restore() end
end

function OT.SetStyle(style)
    if style ~= "blizzard" and style ~= "pathfinder" then return false end
    local was = db.otStyle
    db.otStyle = style
    if was ~= style or style == "pathfinder" then OT.Apply() end
    return true
end

function OT.SetAlpha(a)
    if type(a) ~= "number" then return false end
    db.otAlpha = math.max(0, math.min(1, a))
    if back and back:IsShown() then MM.Paint(back, db.otAlpha, 0.14, -0.6) end
    return true
end

-- The game rebuilds the tracker as quests change: keep it styled.
local ticker, since = nil, 0
local function tick(_, elapsed)
    since = since + (elapsed or 0)
    if since < 0.25 then return end
    since = 0
    if OT.Style() == "pathfinder" then OT.Refresh() end
end

function OT.Init(cdb)
    db = cdb
    if db.otStyle == nil then db.otStyle = "blizzard" end
    if type(db.otAlpha) ~= "number" then db.otAlpha = 0.85 end
    ticker = ticker or CreateFrame("Frame")
    ticker:SetScript("OnUpdate", tick)
    local f = tracker()
    if type(f) == "table" and hooksecurefunc and type(f.Update) == "function" then
        hooksecurefunc(f, "Update", function() if OT.Style() == "pathfinder" then OT.Refresh() end end)
    end
    if db.otStyle ~= "blizzard" and C_Timer then C_Timer.After(1, OT.Apply) end
end
