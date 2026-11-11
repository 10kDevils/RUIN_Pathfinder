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
local NEAR = 12                -- fade the card when you're on top of it
local OBJ_LINES = 5
local CARD_MIN, CARD_MAX, PAD = 150, 250, 10
local GOLD = { 0.90, 0.72, 0.38 }
local INK = { 0.035, 0.045, 0.075 }
local MEDIA = "Interface\\AddOns\\RUIN_Core\\Media\\"
local DOT = "|T" .. MEDIA .. "Pip:9:9:0:0:64:32:0:32:0:32|t"       -- filled pip
local RING = "|T" .. MEDIA .. "Pip:9:9:0:0:64:32:32:64:0:32|t"      -- hollow pip
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
    if not (qid and C_QuestLog.GetQuestObjectives and opt("pinObjectives", true)) then return "" end
    local list = C_QuestLog.GetQuestObjectives(qid)
    if type(list) ~= "table" then return "" end
    local out = {}
    for _, o in ipairs(list) do
        if o.text and o.text ~= "" then
            out[#out + 1] = o.finished and (DOT .. "  " .. C.good .. o.text .. "|r") or (RING .. "  " .. C.white .. o.text .. "|r")
            if #out >= OBJ_LINES then break end
        end
    end
    if #out == 0 and C_QuestLog.IsComplete and C_QuestLog.IsComplete(qid) then out[1] = DOT .. "  " .. C.good .. "Ready to turn in|r" end
    return table.concat(out, "\n")
end

local function fill(frame, layer, r, g, b, a)
    local t = frame:CreateTexture(nil, layer)
    t:SetColorTexture(r, g, b, a)
    return t
end

local function build()
    pin = CreateFrame("Frame", "RUIN_PathfinderPin", UIParent)
    pin:SetSize(PIN, PIN)
    pin:SetFrameStrata("LOW")
    pin:EnableMouse(false)
    pin:Hide()

    -- the marker: the RUIN emblem on a soft shadow
    pin.shadow = pin:CreateTexture(nil, "BACKGROUND")
    pin.shadow:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    pin.shadow:SetVertexColor(0, 0, 0, 0.55)
    pin.shadow:SetPoint("CENTER", 0, -1); pin.shadow:SetSize(PIN + 8, PIN + 8)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetTexture(MEDIA .. "EmblemIcon")
    pin.icon:SetAllPoints()
    pin.check = pin:CreateTexture(nil, "OVERLAY")
    pin.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    pin.check:SetPoint("CENTER"); pin.check:SetSize(PIN - 12, PIN - 12)
    pin.check:Hide()

    -- a fine stem down to a small dot on the ground
    pin.beam = pin:CreateTexture(nil, "BACKGROUND")
    pin.beam:SetColorTexture(1, 1, 1, 1)
    if pin.beam.SetGradient and CreateColor then
        pin.beam:SetGradient("VERTICAL", CreateColor(GOLD[1], GOLD[2], GOLD[3], 0.15), CreateColor(GOLD[1], GOLD[2], GOLD[3], 0.85))
    else
        pin.beam:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.5)
    end
    pin.beam:SetSize(1, 26)
    pin.beam:SetPoint("TOP", pin, "BOTTOM", 0, 0)
    pin.foot = pin:CreateTexture(nil, "BACKGROUND")
    pin.foot:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    pin.foot:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.9)
    pin.foot:SetSize(5, 5)
    pin.foot:SetPoint("CENTER", pin.beam, "BOTTOM", 0, 0)

    -- the edge arrow, when the spot is off screen
    pin.arrow = pin:CreateTexture(nil, "OVERLAY")
    if not (pin.arrow.SetAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("Navigation-Tracked-Arrow")
            and pin.arrow:SetAtlas("Navigation-Tracked-Arrow") ~= false) then
        pin.arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
    end
    pin.arrow:SetSize(EDGE_ARROW, EDGE_ARROW)
    pin.arrow:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
    pin.arrow:Hide()

    -- the card above the marker: a dark panel with a gold rule along the top
    local card = CreateFrame("Frame", nil, pin)
    pin.card = card
    card:SetPoint("BOTTOM", pin, "TOP", 0, 7)
    card:SetSize(CARD_MIN, 40)
    card.bg = fill(card, "BACKGROUND", INK[1], INK[2], INK[3], 0.86); card.bg:SetAllPoints()
    card.top = fill(card, "BORDER", GOLD[1], GOLD[2], GOLD[3], 0.95)
    card.top:SetPoint("TOPLEFT"); card.top:SetPoint("TOPRIGHT"); card.top:SetHeight(2)
    for _, side in ipairs({ "BOTTOM", "LEFT", "RIGHT" }) do
        local e = fill(card, "BORDER", GOLD[1], GOLD[2], GOLD[3], 0.28)
        if side == "BOTTOM" then e:SetPoint("BOTTOMLEFT"); e:SetPoint("BOTTOMRIGHT"); e:SetHeight(1)
        else e:SetPoint("TOP" .. side); e:SetPoint("BOTTOM" .. side); e:SetWidth(1) end
    end
    pin.sub = W.Label(card, "", "GameFontNormalSmall")
    pin.sub:SetPoint("TOPLEFT", PAD, -PAD + 1)
    pin.sub:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    pin.sub:SetWordWrap(false)
    pin.title = W.Label(card, "", "GameFontHighlight")
    pin.title:SetPoint("TOPLEFT", pin.sub, "BOTTOMLEFT", 0, -3)
    pin.title:SetWordWrap(false)
    pin.rule = fill(card, "ARTWORK", 1, 1, 1, 0.10)
    pin.rule:SetHeight(1)
    pin.rule:SetPoint("TOPLEFT", pin.title, "BOTTOMLEFT", 0, -6)
    pin.rule:SetPoint("RIGHT", card, "RIGHT", -PAD, 0)
    pin.obj = W.Label(card, "", "GameFontHighlightSmall")
    pin.obj:SetPoint("TOPLEFT", pin.rule, "BOTTOMLEFT", 0, -6)
    pin.obj:SetJustifyV("TOP")
    pin.obj:SetSpacing(3)

    -- the distance, in a small pill under the dot
    local tag = CreateFrame("Frame", nil, pin)
    pin.tag = tag
    tag:SetSize(80, 18)
    tag.bg = fill(tag, "BACKGROUND", INK[1], INK[2], INK[3], 0.80); tag.bg:SetAllPoints()
    tag.edge = fill(tag, "BORDER", GOLD[1], GOLD[2], GOLD[3], 0.30)
    tag.edge:SetPoint("BOTTOMLEFT"); tag.edge:SetPoint("BOTTOMRIGHT"); tag.edge:SetHeight(1)
    pin.dist = W.Label(tag, "", "GameFontHighlightSmall")
    pin.dist:SetPoint("CENTER", 0, 1)
    pin.dist:SetJustifyH("CENTER")
end

-- Sizes the card to its text, within limits.
local function layoutCard(hasObj)
    local card = pin.card
    local function w(fs) return (fs.GetStringWidth and fs:GetStringWidth()) or 0 end
    local width = math.max(w(pin.sub), w(pin.title))
    pin.obj:SetWidth(CARD_MAX - PAD * 2)
    if hasObj then width = math.max(width, math.min(w(pin.obj), CARD_MAX - PAD * 2)) end
    width = math.max(CARD_MIN, math.min(CARD_MAX, width + PAD * 2))
    pin.title:SetWidth(width - PAD * 2)
    pin.obj:SetWidth(width - PAD * 2)
    local function h(fs) return (fs.GetStringHeight and fs:GetStringHeight()) or 12 end
    local height = PAD - 1 + h(pin.sub) + 3 + h(pin.title) + PAD
    if hasObj then height = height - PAD + 6 + 1 + 6 + h(pin.obj) + PAD end
    card:SetSize(width, height)
    pin.rule:SetShown(hasObj)
    pin.obj:SetShown(hasObj)
end

local function setGameMarker(hide)
    if hide == hidGame or not SuperTrackedFrame then return end
    hidGame = hide
    for _, key in ipairs(GAME_PARTS) do
        local part = SuperTrackedFrame[key]
        if part and part.SetAlpha then part:SetAlpha(hide and 0 or 1) end
    end
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
    if inArea(yards, qid) or (clamped and not opt("pinEdge", true)) then pin:Hide(); return end
    local size = opt("pinScale", 1) or 1

    pin:ClearAllPoints()
    pin.tag:ClearAllPoints()
    if clamped then
        -- at the edge: pull the marker in from the border and point the arrow at the spot
        local w, h = UIParent:GetWidth(), UIParent:GetHeight()
        local angle = math.atan2(ny - h / 2, nx - w / 2)
        local ex = math.max(EDGE_INSET, math.min(w - EDGE_INSET, nx))
        local ey = math.max(EDGE_INSET, math.min(h - EDGE_INSET, ny))
        pin:SetPoint("CENTER", UIParent, "BOTTOMLEFT", ex, ey)
        pin.arrow:ClearAllPoints()
        pin.arrow:SetPoint("CENTER", pin, "CENTER", math.cos(angle) * (PIN * 0.82), math.sin(angle) * (PIN * 0.82))
        pin.arrow:SetRotation(angle - math.pi / 2)
        pin.arrow:Show()
        pin.beam:Hide(); pin.foot:Hide(); pin.card:Hide()
        pin:SetScale(0.8 * size)
        pin.tag:SetPoint("TOP", pin, "BOTTOM", 0, -6)
    else
        pin:SetPoint("CENTER", UIParent, "BOTTOMLEFT", nx, ny + 32)
        pin.arrow:Hide()
        pin.beam:Show(); pin.foot:Show(); pin.card:Show()
        pin:SetScale((yards > FAR and 0.85 or 1) * size)
        pin.card:SetAlpha(yards < NEAR and 0.35 or 1)
        pin.tag:SetPoint("TOP", pin.foot, "BOTTOM", 0, -4)
    end

    local walk = opt("pinWalk", true) and walkText(yards) or nil
    pin.dist:SetText(C.white .. yardsText(yards) .. "|r" .. (walk and ("   " .. C.dim .. walk .. "|r") or ""))
    pin.tag:SetWidth(math.max(56, ((pin.dist.GetStringWidth and pin.dist:GetStringWidth()) or 60) + 18))

    objTick = objTick + (elapsed or 0)
    if qid ~= lastQuest or objTick > 1 or title ~= lastText or M.pinDirty then
        M.pinDirty = nil
        objTick, lastQuest, lastText = 0, qid, title
        pin.sub:SetText(sub or "")
        pin.title:SetText(title or "")
        local text = objectives(qid)
        pin.obj:SetText(text)
        layoutCard(text ~= "")
    end
    pin:Show()
end

-- The pin hides itself when there's nothing to show, and a hidden frame gets
-- no OnUpdate, so an always-visible driver runs it. The driver also looks
-- for the game's navigation frame twice a second, in case an event is missed.
local driver = CreateFrame("Frame", nil, UIParent)
local look = 0

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
        if not pin then build() end
        pin.check:Hide()
        pin.icon:SetAlpha(1)
    end
    setGameMarker(true)
end

driver:SetScript("OnUpdate", function(_, elapsed)
    look = look + (elapsed or 0)
    if look > 0.5 then
        look = 0
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
