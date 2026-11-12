-- RUIN Pathfinder: the waypoint pin.
--
-- A RUIN-styled marker over whatever the game is navigating to: the quest
-- you've selected in the objective tracker, a map waypoint, or Pathfinder's
-- own step. It rides the game's navigation frame (C_Navigation), so it sits
-- on the spot in the world; when the spot is off screen it waits at the edge
-- with an arrow pointing the way. Under it: what it is, how far, and roughly
-- how long on foot. A tracked quest also lists its objectives.

local R = RUIN_API
if not R then return end
local M = R:GetModule("Pathfinder")
if not M then return end
local W = R.Widgets
local C = W.COLORS

local PIN, EDGE_ARROW, EDGE_INSET = 38, 18, 44
local RUN_SPEED = 7            -- yards per second on foot
local FAR = 600                -- shrink a little beyond this
local STEM = 26               -- the stem from the marker down to the dot
local FOOT_LIFT = 4            -- the dot sits this far above the spot
local FADE = 0.5              -- seconds to fade out in the quest's area
local NEAR = 12                -- fade the card when you're on top of it
local OBJ_LINES = 5
local CARD_MIN, CARD_MAX, PAD = 40, 250, 10   -- the card hugs its text, up to the max
local GOLD = { 0.90, 0.72, 0.38 }
local INK = { 0.035, 0.045, 0.075 }
local MEDIA = "Interface\\AddOns\\RUIN_Core\\Media\\"
local GAME_PARTS = { "Icon", "Arrow", "DistanceText", "IconBorder" }

local pin, navFrame, hidGame
local events = CreateFrame("Frame")

local function opt(key, default)
    local v = M.PinSetting and M.PinSetting(key)
    if v == nil then return default end
    return v
end

-- In the area: the game says you're there (in range), or you're nearer than
-- the chosen distance.
local function inArea(yards, qid)
    -- in the tracked quest's objective area: always out of the way
    if qid and M.InQuestArea and M.InQuestArea(qid) then return true end
    if not opt("pinHideInArea", true) then return false end
    local states = Enum and Enum.NavigationState
    if states and states.InRange and C_Navigation.GetTargetState and C_Navigation.GetTargetState() == states.InRange then return true end
    local near = opt("pinHideYards", 15) or 0
    return near > 0 and yards <= near
end
M.PinInArea = inArea

local function on()
    return M.PinOn and M.PinOn() and C_Navigation and C_Navigation.GetFrame and C_SuperTrack ~= nil
end

local function yardsText(y)
    if y >= 1000 then return ("%.1fk yd"):format(y / 1000) end
    return ("%d yd"):format(y)
end

local function walkText(y)
    local secs = math.floor(y / RUN_SPEED + 0.5)
    if secs < 5 then return nil end
    if secs < 60 then return ("%d sec"):format(secs) end
    return ("%d min %02d"):format(math.floor(secs / 60), secs % 60)
end

-- What's being navigated to, as a small label, a title, and a quest id.
local function target()
    local types = Enum and Enum.SuperTrackingType
    local kind = C_SuperTrack.GetHighestPrioritySuperTrackingType and C_SuperTrack.GetHighestPrioritySuperTrackingType()
    local info = M.PinInfo and M.PinInfo()
    if types and kind == types.Quest then
        local qid = C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()
        local title = qid and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(qid) or "Quest"
        local sub = (info and info.quest == qid) and ("PATHFINDER  ·  " .. info.act:upper()) or "TRACKED QUEST"
        return title, sub, qid
    end
    if info and info.title then return info.title, "PATHFINDER  ·  " .. info.act:upper(), nil end
    if types and kind == types.UserWaypoint then return "Map pin", "WAYPOINT", nil end
    return "Destination", "WAYPOINT", nil
end

local function objectives(qid)
    if not (qid and M.ObjectiveLines) then return "" end
    return M.ObjectiveLines(qid, OBJ_LINES)
end

local function fill(frame, layer, r, g, b, a)
    local t = frame:CreateTexture(nil, layer)
    t:SetColorTexture(r, g, b, a)
    return t
end

-- Show or hide (one call, so it works the same everywhere).
local function vis(r, on) if on then r:Show() else r:Hide() end end

local DISC = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local TITLE_FONTS = { small = "GameFontHighlightSmall", normal = "GameFontHighlight", large = "GameFontHighlightLarge" }

-- The look, from the Waypoint Editor's settings (all on to start).
local function look()
    return {
        card = opt("pinShowCard", true), label = opt("pinShowLabel", true), title = opt("pinShowTitle", true),
        objectives = opt("pinObjectives", true), marker = opt("pinShowMarker", true), stem = opt("pinShowStem", true),
        distance = opt("pinShowDistance", true), walk = opt("pinWalk", true), edge = opt("pinEdge", true), edgeCard = opt("pinEdgeCard", true),
        markerStyle = opt("pinMarkerStyle", "emblem"), textSize = opt("pinTextSize", "normal"),
        cardAlpha = opt("pinCardAlpha", 0.86), size = opt("pinScale", 1) or 1,
    }
end
M.PinLook = look

-- One pin's frames. The live pin sits on UIParent; the Waypoint Editor
-- builds another as its preview.
local function build(parent, name)
    local p = CreateFrame("Frame", name, parent)
    p:SetSize(PIN, PIN)
    if parent == UIParent then p:SetFrameStrata("LOW") end
    p:EnableMouse(false)
    p:Hide()

    -- the marker: the RUIN emblem (or a plain gold dot) on a soft shadow
    p.shadow = p:CreateTexture(nil, "BACKGROUND")
    p.shadow:SetTexture(DISC)
    p.shadow:SetVertexColor(0, 0, 0, 0.55)
    p.icon = p:CreateTexture(nil, "ARTWORK")
    p.check = p:CreateTexture(nil, "OVERLAY")
    p.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    p.check:SetPoint("CENTER"); p.check:SetSize(PIN - 12, PIN - 12)
    p.check:Hide()

    -- a fine stem down to a small dot on the ground
    p.beam = p:CreateTexture(nil, "BACKGROUND")
    p.beam:SetColorTexture(1, 1, 1, 1)
    if p.beam.SetGradient and CreateColor then
        p.beam:SetGradient("VERTICAL", CreateColor(GOLD[1], GOLD[2], GOLD[3], 0.15), CreateColor(GOLD[1], GOLD[2], GOLD[3], 0.85))
    else
        p.beam:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.5)
    end
    p.beam:SetSize(1, STEM)
    p.beam:SetPoint("TOP", p, "BOTTOM", 0, 0)
    p.foot = p:CreateTexture(nil, "BACKGROUND")
    p.foot:SetTexture(DISC)
    p.foot:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.9)
    p.foot:SetSize(5, 5)
    p.foot:SetPoint("CENTER", p.beam, "BOTTOM", 0, 0)

    -- the edge arrow, when the spot is off screen
    p.arrow = p:CreateTexture(nil, "OVERLAY")
    if not (p.arrow.SetAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("Navigation-Tracked-Arrow")
            and p.arrow:SetAtlas("Navigation-Tracked-Arrow") ~= false) then
        p.arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
    end
    p.arrow:SetSize(EDGE_ARROW, EDGE_ARROW)
    p.arrow:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
    p.arrow:Hide()

    -- the card above the marker: a dark panel with a gold rule along the top
    local card = CreateFrame("Frame", nil, p)
    p.card = card
    card:SetPoint("BOTTOM", p, "TOP", 0, 7)
    card:SetSize(CARD_MIN, 40)
    card.bg = fill(card, "BACKGROUND", INK[1], INK[2], INK[3], 0.86); card.bg:SetAllPoints()
    card.top = fill(card, "BORDER", GOLD[1], GOLD[2], GOLD[3], 0.95)
    card.top:SetPoint("TOPLEFT"); card.top:SetPoint("TOPRIGHT"); card.top:SetHeight(2)
    for _, side in ipairs({ "BOTTOM", "LEFT", "RIGHT" }) do
        local e = fill(card, "BORDER", GOLD[1], GOLD[2], GOLD[3], 0.28)
        if side == "BOTTOM" then e:SetPoint("BOTTOMLEFT"); e:SetPoint("BOTTOMRIGHT"); e:SetHeight(1)
        else e:SetPoint("TOP" .. side); e:SetPoint("BOTTOM" .. side); e:SetWidth(1) end
    end
    p.sub = W.Label(card, "", "GameFontNormalSmall")
    p.sub:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    p.sub:SetWordWrap(false)
    p.title = W.Label(card, "", "GameFontHighlight")
    p.title:SetWordWrap(false)
    p.rule = fill(card, "ARTWORK", 1, 1, 1, 0.10)
    p.rule:SetHeight(1)
    p.obj = W.Label(card, "", "GameFontHighlightSmall")
    p.obj:SetJustifyV("TOP")
    p.obj:SetSpacing(3)

    -- the distance, in a small pill under the dot
    local tag = CreateFrame("Frame", nil, p)
    p.tag = tag
    tag:SetSize(80, 18)
    tag.bg = fill(tag, "BACKGROUND", INK[1], INK[2], INK[3], 0.80); tag.bg:SetAllPoints()
    tag.edge = fill(tag, "BORDER", GOLD[1], GOLD[2], GOLD[3], 0.30)
    tag.edge:SetPoint("BOTTOMLEFT"); tag.edge:SetPoint("BOTTOMRIGHT"); tag.edge:SetHeight(1)
    p.dist = W.Label(tag, "", "GameFontHighlightSmall")
    p.dist:SetPoint("CENTER", 0, 1)
    p.dist:SetJustifyH("CENTER")
    return p
end

-- The marker's style: the emblem, or a small gold dot.
local function paintMarker(p, lk)
    if p.markerStyle ~= lk.markerStyle then
        p.markerStyle = lk.markerStyle
        p.icon:ClearAllPoints(); p.shadow:ClearAllPoints()
        if lk.markerStyle == "dot" then
            p.icon:SetTexture(DISC); p.icon:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
            p.icon:SetPoint("CENTER"); p.icon:SetSize(14, 14)
            p.shadow:SetPoint("CENTER", 0, -1); p.shadow:SetSize(20, 20)
        else
            p.icon:SetTexture(MEDIA .. "EmblemIcon"); p.icon:SetVertexColor(1, 1, 1, 1)
            p.icon:SetAllPoints()
            p.shadow:SetPoint("CENTER", 0, -1); p.shadow:SetSize(PIN + 8, PIN + 8)
        end
    end
    vis(p.icon, lk.marker); vis(p.shadow, lk.marker)
end

-- Stacks the card's parts that are on (label, title, objectives) and sizes
-- the card to its text, within limits. Returns false when nothing is on.
local function layoutCard(p, lk, hasObj)
    local card = p.card
    local showSub, showTitle = lk.label and (p.sub:GetText() or "") ~= "", lk.title and (p.title:GetText() or "") ~= ""
    hasObj = hasObj and lk.objectives
    vis(p.sub, showSub); vis(p.title, showTitle); vis(p.obj, hasObj)
    vis(p.rule, hasObj and (showSub or showTitle))
    if not (showSub or showTitle or hasObj) then return false end
    if p.titleFont ~= lk.textSize and p.title.SetFontObject then
        p.titleFont = lk.textSize
        p.title:SetFontObject(TITLE_FONTS[lk.textSize] or TITLE_FONTS.normal)
    end
    card.bg:SetColorTexture(INK[1], INK[2], INK[3], lk.cardAlpha or 0.86)
    local function w(fs) return (fs.GetStringWidth and fs:GetStringWidth()) or 0 end
    local function h(fs) return (fs.GetStringHeight and fs:GetStringHeight()) or 12 end
    local width = math.max(showSub and w(p.sub) or 0, showTitle and w(p.title) or 0)
    p.obj:SetWidth(CARD_MAX - PAD * 2)
    if hasObj then width = math.max(width, math.min(w(p.obj), CARD_MAX - PAD * 2)) end
    width = math.max(CARD_MIN, math.min(CARD_MAX, math.ceil(width) + 2 + PAD * 2))
    p.title:SetWidth(width - PAD * 2)
    p.obj:SetWidth(width - PAD * 2)
    local y = PAD - 1
    local function place(fs, gap)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", card, "TOPLEFT", PAD, -y)
        y = y + h(fs) + gap
    end
    if showSub then place(p.sub, 3) end
    if showTitle then place(p.title, 6) end
    if hasObj then
        if showSub or showTitle then
            p.rule:ClearAllPoints()
            p.rule:SetPoint("TOPLEFT", card, "TOPLEFT", PAD, -y)
            p.rule:SetPoint("RIGHT", card, "RIGHT", -PAD, 0)
            y = y + 1 + 6
        end
        place(p.obj, 0)
    end
    card:SetSize(width, y + PAD - 2)
    return true
end

-- What a pin shows, for a target: d = { title, sub, obj (text), yards,
-- clamped, angle }. Positioning is the caller's; this sets what's visible.
local function paint(p, d, lk, relayout)
    paintMarker(p, lk)
    p.tag:ClearAllPoints()
    if d.clamped then
        p.arrow:ClearAllPoints()
        p.arrow:SetPoint("CENTER", p, "CENTER", math.cos(d.angle or 0) * (PIN * 0.82), math.sin(d.angle or 0) * (PIN * 0.82))
        p.arrow:SetRotation((d.angle or 0) - math.pi / 2)
        p.arrow:Show()
        p.beam:Hide(); p.foot:Hide()
        p.tag:SetPoint("TOP", p, "BOTTOM", 0, -6)
        -- the card at the edge too: beside the marker, on the side toward the
        -- middle of the screen, so it stays on screen
        if relayout then
            p.sub:SetText(d.sub or "")
            p.title:SetText(d.title or "")
            p.obj:SetText(d.obj or "")
            p.hasCard = layoutCard(p, lk, (d.obj or "") ~= "")
        end
        vis(p.card, lk.edgeCard and lk.card and p.hasCard and true or false)
        p.card:SetAlpha(1)
    else
        p.arrow:Hide()
        vis(p.beam, lk.stem); vis(p.foot, lk.stem)
        p.tag:SetPoint("TOP", p.foot, "BOTTOM", 0, -4)
        -- the card sits on the marker; without it, on top of the stem; without
        -- both, right where the ground dot would be
        p.card:ClearAllPoints()
        if lk.marker then p.card:SetPoint("BOTTOM", p, "TOP", 0, 7)
        elseif lk.stem then p.card:SetPoint("BOTTOM", p.beam, "TOP", 0, 4)
        else p.card:SetPoint("BOTTOM", p.beam, "BOTTOM", 0, 2) end
        if relayout then
            p.sub:SetText(d.sub or "")
            p.title:SetText(d.title or "")
            p.obj:SetText(d.obj or "")
            p.hasCard = layoutCard(p, lk, (d.obj or "") ~= "")
        end
        vis(p.card, lk.card and p.hasCard and true or false)
        p.card:SetAlpha((d.yards or 999) < NEAR and 0.35 or 1)
    end
    local yards = d.yards or 0
    local walk = lk.walk and walkText(yards) or nil
    p.dist:SetText(C.white .. yardsText(yards) .. "|r" .. (walk and ("   " .. C.dim .. walk .. "|r") or ""))
    local tagW = math.max(56, ((p.dist.GetStringWidth and p.dist:GetStringWidth()) or 60) + 18)
    p.tag:SetWidth(tagW)
    vis(p.tag, lk.distance)
    if d.clamped then
        -- beside the marker (clear of the arrow and the distance tag), on the
        -- side toward the middle of the screen, so it stays on screen
        local gap = math.max(EDGE_ARROW, (lk.distance and (tagW / 2 - PIN / 2) or 0) + 6)
        p.card:ClearAllPoints()
        if d.side == "right" then p.card:SetPoint("RIGHT", p, "LEFT", -gap, 0)
        elseif d.side == "left" then p.card:SetPoint("LEFT", p, "RIGHT", gap, 0)
        elseif d.side == "top" then p.card:SetPoint("TOP", lk.distance and p.tag or p, "BOTTOM", 0, -6)
        else p.card:SetPoint("BOTTOM", p, "TOP", 0, 7) end
    end
end

local function setGameMarker(hide)
    if hide == hidGame or not SuperTrackedFrame then return end
    hidGame = hide
    for _, key in ipairs(GAME_PARTS) do
        local part = SuperTrackedFrame[key]
        if part and part.SetAlpha then part:SetAlpha(hide and 0 or 1) end
    end
end

-- The rectangle the pin stays inside: each side's boundary is a share of the
-- screen (Options: pinEdgeTop/Bottom/Left/Right, in percent), never closer to
-- the border than the edge pin needs.
local function pct(key)
    local v = tonumber(opt(key, 0)) or 0
    return math.max(0, math.min(45, v)) / 100
end
function M.EdgeBounds(w, h)
    return { left = math.max(EDGE_INSET, w * pct("pinEdgeLeft")), right = math.min(w - EDGE_INSET, w * (1 - pct("pinEdgeRight"))),
             bottom = math.max(EDGE_INSET, h * pct("pinEdgeBottom")), top = math.min(h - EDGE_INSET, h * (1 - pct("pinEdgeTop"))) }
end
-- which boundary the edge pin sits on (where its card goes)
function M.EdgeSide(x, y, b)
    if x >= b.right - 1 then return "right" end
    if x <= b.left + 1 then return "left" end
    if y >= b.top - 1 then return "top" end
    return "bottom"
end

local lastQuest, objTick, lastText = nil, 0, nil
local function update(_, elapsed)
    if not (navFrame and C_Navigation.HasValidScreenPosition and C_Navigation.HasValidScreenPosition()) then
        pin:Hide(); return
    end
    local scale = (navFrame:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
    local nx, ny = navFrame:GetCenter()
    if not nx then pin:Hide(); return end
    nx, ny = nx * scale, ny * scale
    local yards = C_Navigation.GetDistance and C_Navigation.GetDistance() or 0
    local clamped = C_Navigation.WasClampedToScreen and C_Navigation.WasClampedToScreen()
    local title, sub, qid = target()
    local lk = look()
    -- the edge boundaries (Options): a spot this close to a side of the screen
    -- already counts as off screen, and the edge pin waits at that line
    local w, h = UIParent:GetWidth(), UIParent:GetHeight()
    local b = M.EdgeBounds(w, h)
    if not clamped and (nx < b.left or nx > b.right or ny < b.bottom or ny > b.top) then clamped = true end
    if clamped and not lk.edge then pin:Hide(); return end
    -- inside the quest's area the pin fades away over half a second (and back when you leave)
    local want = inArea(yards, qid) and 0 or 1
    local f = pin.fade or 0
    if f ~= want then
        local step = (elapsed or 0) / FADE
        f = want > f and math.min(want, f + step) or math.max(want, f - step)
        pin.fade = f
    end
    if f <= 0 then pin:Hide(); return end
    pin:SetAlpha(f)

    pin:ClearAllPoints()
    local d = { title = title, sub = sub, yards = yards, clamped = clamped }
    if clamped then
        -- at the edge: pull the marker in from the border and point the arrow at the spot
        d.angle = math.atan2(ny - h / 2, nx - w / 2)
        local ex = math.max(b.left, math.min(b.right, nx))
        local ey = math.max(b.bottom, math.min(b.top, ny))
        d.side = M.EdgeSide(ex, ey, b)
        local sc = 0.8 * lk.size
        pin:SetScale(sc)
        -- offsets are in the pin's own (scaled) units
        pin:SetPoint("CENTER", UIParent, "BOTTOMLEFT", ex / sc, ey / sc)
    else
        -- the dot at the stem's foot sits on the spot, a touch above rather than below,
        -- plus the nudge from the options (screen pixels)
        local sc = (yards > FAR and 0.85 or 1) * lk.size
        pin:SetScale(sc)
        local fx = nx + (opt("pinOffsetX", 0) or 0)
        local fy = ny + FOOT_LIFT + (opt("pinOffsetY", 0) or 0)
        pin:SetPoint("CENTER", UIParent, "BOTTOMLEFT", fx / sc, fy / sc + STEM + PIN / 2)
    end

    objTick = objTick + (elapsed or 0)
    local relayout = qid ~= lastQuest or objTick > 1 or title ~= lastText or M.pinDirty
    if relayout then
        M.pinDirty = nil
        objTick, lastQuest, lastText = 0, qid, title
        d.obj = objectives(qid)
    end
    paint(pin, d, lk, relayout)
    pin:Show()
end

-- The pin hides itself when there's nothing to show, and a hidden frame gets
-- no OnUpdate, so an always-visible driver runs it. The driver also looks
-- for the game's navigation frame twice a second, in case an event is missed.
local driver = CreateFrame("Frame", nil, UIParent)
local lookTick = 0

local function detach()
    navFrame = nil
    if pin then pin:Hide() end
    setGameMarker(false)
end

local function attach()
    if not on() then return detach() end
    local f = C_Navigation.GetFrame()
    if not f then return detach() end
    if f ~= navFrame then
        navFrame = f
        if not pin then pin = build(UIParent, "RUIN_PathfinderPin") end
        pin.check:Hide()
        pin.icon:SetAlpha(1)
    end
    setGameMarker(true)
end

driver:SetScript("OnUpdate", function(_, elapsed)
    lookTick = lookTick + (elapsed or 0)
    if lookTick > 0.5 then
        lookTick = 0
        local f = on() and C_Navigation.GetFrame() or nil
        if f ~= navFrame then if f then attach() else detach() end end
    end
    if navFrame and pin then update(nil, elapsed) end
end)

-- reached: a moment's check mark, then the game moves on (or Pathfinder does)
local function reached()
    if not pin or not pin:IsShown() then return end
    pin.check:Show()
    pin.icon:SetAlpha(0.35)
    C_Timer.After(3, function() if pin then pin.check:Hide(); pin.icon:SetAlpha(1) end end)
end

events:SetScript("OnEvent", function(_, event)
    if event == "NAVIGATION_FRAME_CREATED" then attach()
    elseif event == "NAVIGATION_FRAME_DESTROYED" then detach()
    elseif event == "NAVIGATION_DESTINATION_REACHED" then reached()
    elseif event == "PLAYER_LOGIN" or event == "SUPER_TRACKING_CHANGED" then
        if C_Navigation and C_Navigation.GetFrame and C_Navigation.GetFrame() then attach() else detach() end
    end
end)
for _, e in ipairs({ "NAVIGATION_FRAME_CREATED", "NAVIGATION_FRAME_DESTROYED", "NAVIGATION_DESTINATION_REACHED",
                     "PLAYER_LOGIN", "SUPER_TRACKING_CHANGED" }) do
    pcall(events.RegisterEvent, events, e)
end

function M.RefreshPin()
    M.pinDirty = true
    if C_Navigation and C_Navigation.GetFrame and C_Navigation.GetFrame() then attach() else detach() end
end

M.Pin = { Update = function() if pin and navFrame then update(nil, 0) end end, Frame = function() return pin end,
    Driver = driver,
    State = function()
        return ("pin %s, attached %s, shown %s, nav frame %s, on screen %s, clamped %s, distance %s, nav state %s (2 = in range), tracking type %s"):format(
            tostring(M.PinOn and M.PinOn()), tostring(navFrame ~= nil), tostring(pin and pin:IsShown() or false),
            tostring(C_Navigation and C_Navigation.GetFrame and C_Navigation.GetFrame() ~= nil),
            tostring(C_Navigation and C_Navigation.HasValidScreenPosition and C_Navigation.HasValidScreenPosition()),
            tostring(C_Navigation and C_Navigation.WasClampedToScreen and C_Navigation.WasClampedToScreen()),
            tostring(C_Navigation and C_Navigation.GetDistance and C_Navigation.GetDistance()),
            tostring(C_Navigation and C_Navigation.GetTargetState and C_Navigation.GetTargetState()),
            tostring(C_SuperTrack and C_SuperTrack.GetHighestPrioritySuperTrackingType and C_SuperTrack.GetHighestPrioritySuperTrackingType()))
    end }

---------------------------------------------------------------------------
-- Waypoint Editor: choose what the pin shows and how it looks, with a live
-- preview of it on screen and at the screen edge. /path editor
---------------------------------------------------------------------------
local editor
local SAMPLE = {
    title = "Soothing Turtle Bisque", sub = "TRACKED QUEST", yards = 97,
    obj = C.white .. "- 6/10 Turtle Meat|r\n" .. C.white .. "- 0/1 Soothing Spices|r",
}
-- the look's settings and their defaults (Reset puts these back)
local LOOK_KEYS = { pinShowCard = true, pinShowLabel = true, pinShowTitle = true, pinObjectives = true,
    pinShowMarker = true, pinShowStem = true, pinShowDistance = true, pinWalk = true, pinEdge = true, pinEdgeCard = true,
    pinMarkerStyle = "emblem", pinTextSize = "normal", pinCardAlpha = 0.86, pinScale = 1 }

local function refreshEditor()
    if not (editor and editor:IsShown()) then return end
    local lk = look()
    -- on screen: the dot near the bottom of the preview, as it would sit on the spot
    local p = editor.preview
    p:SetScale(lk.size)
    p:ClearAllPoints()
    p:SetPoint("CENTER", editor.area, "BOTTOM", 0, (64 / lk.size) + STEM + PIN / 2)
    paint(p, SAMPLE, lk, true)
    vis(p, true)
    -- at the edge: the marker with the arrow pointing off to the right
    local e = editor.edgePreview
    e:SetScale(0.8 * lk.size)
    e:ClearAllPoints()
    e:SetPoint("RIGHT", editor.edgeArea, "RIGHT", -34 / (0.8 * lk.size), -8 / (0.8 * lk.size))
    paint(e, { yards = 420, clamped = true, angle = 0, side = "right", title = SAMPLE.title, sub = SAMPLE.sub, obj = SAMPLE.obj }, lk, true)
    vis(e, lk.edge)
    editor.edgeOff:SetText(lk.edge and "" or (C.dim .. "Off: the pin hides when the spot is off screen.|r"))
    for _, c in ipairs(editor.checks) do c:Refresh() end
    for _, row in ipairs(editor.choices) do row.sync() end
end

local function setLook(key, v)
    if M.SetPinSetting then M.SetPinSetting(key, v) end
    if M.RefreshPin then M.RefreshPin() end
    refreshEditor()
end

local function buildEditor()
    local f = CreateFrame("Frame", "RUIN_PathfinderWaypointEditor", UIParent)
    editor = f
    f:SetSize(660, 456)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    W.Skin(f, "bg", 0.96, "border")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetScript("OnShow", refreshEditor)
    if UISpecialFrames then table.insert(UISpecialFrames, "RUIN_PathfinderWaypointEditor") end   -- Esc closes it
    f:Hide()

    local h = W.Header(f, "Waypoint Editor")
    h:SetPoint("TOPLEFT", 14, -12)
    local hint = W.Label(f, C.dim .. "What the RUIN pin shows, and how it looks.|r", "GameFontHighlightSmall")
    hint:SetPoint("LEFT", h, "RIGHT", 10, 0)
    local close = W.Button(f, "x", 22, function() f:Hide() end)
    close:SetPoint("TOPRIGHT", -8, -8)
    close.tip = "Close"

    -- preview: a patch of "world" with the pin on it, and one at the screen edge
    local area = CreateFrame("Frame", nil, f)
    f.area = area
    area:SetPoint("TOPLEFT", 14, -40)
    area:SetSize(300, 230)
    local sky = area:CreateTexture(nil, "BACKGROUND")
    sky:SetAllPoints()
    sky:SetColorTexture(1, 1, 1, 1)
    if sky.SetGradient and CreateColor then
        sky:SetGradient("VERTICAL", CreateColor(0.10, 0.14, 0.09, 1), CreateColor(0.13, 0.17, 0.22, 1))
    else
        sky:SetColorTexture(0.11, 0.15, 0.14, 1)
    end
    local spot = area:CreateTexture(nil, "BORDER")
    spot:SetTexture(DISC)
    spot:SetVertexColor(0, 0, 0, 0.35)
    spot:SetSize(46, 14)
    spot:SetPoint("CENTER", area, "BOTTOM", 0, 64)
    local lbl = W.Label(area, C.dim .. "On screen|r", "GameFontHighlightSmall")
    lbl:SetPoint("TOPLEFT", 6, -5)
    f.preview = build(area)

    local edgeArea = CreateFrame("Frame", nil, f)
    f.edgeArea = edgeArea
    edgeArea:SetPoint("TOPLEFT", area, "BOTTOMLEFT", 0, -6)
    edgeArea:SetSize(300, 124)
    local esky = edgeArea:CreateTexture(nil, "BACKGROUND")
    esky:SetAllPoints()
    esky:SetColorTexture(0.10, 0.12, 0.15, 1)
    local elbl = W.Label(edgeArea, C.dim .. "Off screen (at the edge)|r", "GameFontHighlightSmall")
    elbl:SetPoint("TOPLEFT", 6, -5)
    f.edgeOff = W.Label(edgeArea, "", "GameFontHighlightSmall")
    f.edgeOff:SetPoint("CENTER", 0, -6)
    f.edgePreview = build(edgeArea)

    -- the settings
    f.checks, f.choices = {}, {}
    local X0, y = 334, -44
    local function section(text)
        local s = W.Label(f, C.gold .. text .. "|r", "GameFontNormal")
        s:SetPoint("TOPLEFT", X0, y)
        y = y - 20
    end
    local function check(label, key, tip, indent)
        local c = W.Check(f, label, function() return opt(key, LOOK_KEYS[key]) ~= false end, function(v) setLook(key, v) end)
        c:SetPoint("TOPLEFT", X0 + (indent and 18 or 0), y)
        c.tip = tip
        f.checks[#f.checks + 1] = c
        y = y - 22
        return c
    end
    local function choice(label, key, options)
        local l = W.Label(f, label, "GameFontHighlight")
        l:SetPoint("TOPLEFT", X0 + 2, y - 4)
        local btns = {}
        local row = { sync = function()
            local cur = opt(key, LOOK_KEYS[key])
            for _, b in ipairs(btns) do
                local on = (type(cur) == "number" and math.abs(cur - b.value) < 0.01) or cur == b.value
                b:SetText(on and (C.gold .. b.name .. "|r") or b.name)
            end
        end }
        for i, o in ipairs(options) do
            local b = W.Button(f, o[2], 62, function() setLook(key, o[1]) end)
            b.value, b.name = o[1], o[2]
            b:SetPoint("TOPLEFT", X0 + 104 + (i - 1) * 66, y)
            btns[i] = b
        end
        f.choices[#f.choices + 1] = row
        y = y - 26
        return row
    end

    section("Card")
    check("Card above the marker", "pinShowCard", "The dark card with what you're heading to.")
    check("Label (TRACKED QUEST, PATHFINDER...)", "pinShowLabel", "The small gold line saying what kind of target it is.", true)
    check("Name", "pinShowTitle", "The quest's or step's name.", true)
    check("Quest objectives", "pinObjectives", "A tracked quest's objectives, like the quest log.", true)
    section("Marker")
    check("Marker", "pinShowMarker", "The emblem (or dot) over the spot.")
    check("Stem and ground dot", "pinShowStem", "The fine line down to the dot on the spot.")
    check("Distance", "pinShowDistance", "How far it is, in the small tag under the dot.")
    check("Walking time", "pinWalk", "Roughly how long the walk is, beside the distance.", true)
    check("Show at the screen edge when off screen", "pinEdge", "When the spot is behind you or off screen, the pin waits at the edge with an arrow pointing the way.")
    check("Card at the edge too", "pinEdgeCard", "The card (with the parts ticked above) beside the pin while it waits at the screen edge.", true)
    y = y - 4
    choice("Marker style", "pinMarkerStyle", { { "emblem", "Emblem" }, { "dot", "Dot" } })
    choice("Name size", "pinTextSize", { { "small", "Small" }, { "normal", "Normal" }, { "large", "Large" } })
    choice("Card", "pinCardAlpha", { { 0.55, "Light" }, { 0.86, "Normal" }, { 1, "Solid" } })
    choice("Pin size", "pinScale", { { 0.8, "Small" }, { 1, "Normal" }, { 1.25, "Large" } })

    local reset = W.Button(f, "Reset", 80, function()
        for k in pairs(LOOK_KEYS) do if M.SetPinSetting then M.SetPinSetting(k, nil) end end
        if M.RefreshPin then M.RefreshPin() end
        refreshEditor()
    end)
    reset:SetPoint("BOTTOMLEFT", 14, 12)
    reset.tip = "Everything back to how the pin first looked."
    local done = W.Button(f, "Done", 80, function() f:Hide() end)
    done:SetPoint("BOTTOMRIGHT", -14, 12)
    local where = W.Label(f, C.dim .. "Where it sits, when it moves to the edge, and when it hides: Pathfinder > Options.|r", "GameFontHighlightSmall")
    where:SetPoint("BOTTOM", 0, 18)
end

function M.OpenWaypointEditor()
    if not editor then buildEditor() end
    editor:Show()
    refreshEditor()
end
M.WaypointEditor = function() return editor end
