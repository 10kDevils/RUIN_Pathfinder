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

local PIN, EDGE_ARROW, EDGE_INSET = 34, 22, 36
local RUN_SPEED = 7            -- yards per second on foot
local FAR = 600                -- shrink a little beyond this
local OBJ_LINES = 5
local GOLD = { 0.90, 0.72, 0.38 }
local GAME_PARTS = { "Icon", "Arrow", "DistanceText", "IconBorder" }

local pin, navFrame, hidGame
local events = CreateFrame("Frame")

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
    if secs < 60 then return ("~%ds"):format(secs) end
    return ("~%dm %02ds"):format(math.floor(secs / 60), secs % 60)
end

-- What's being navigated to, as a title, a small line, and a quest id.
local function target()
    local types = Enum and Enum.SuperTrackingType
    local kind = C_SuperTrack.GetHighestPrioritySuperTrackingType and C_SuperTrack.GetHighestPrioritySuperTrackingType()
    local info = M.PinInfo and M.PinInfo()
    if types and kind == types.Quest then
        local qid = C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()
        local title = qid and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(qid) or "Quest"
        local sub = (info and info.quest == qid) and ("Pathfinder · " .. info.act) or "Tracked quest"
        return title, sub, qid
    end
    if info and info.title then return info.title, "Pathfinder · " .. info.act, nil end
    if types and kind == types.UserWaypoint then return "Waypoint", "Map pin", nil end
    return "Destination", nil, nil
end

local function objectives(qid)
    if not (qid and C_QuestLog.GetQuestObjectives) then return "" end
    local list = C_QuestLog.GetQuestObjectives(qid)
    if type(list) ~= "table" then return "" end
    local out = {}
    for _, o in ipairs(list) do
        if o.text and o.text ~= "" then
            out[#out + 1] = (o.finished and (C.good .. "|TInterface\\RaidFrame\\ReadyCheck-Ready:12|t ") or (C.white .. "- ")) .. o.text .. "|r"
            if #out >= OBJ_LINES then break end
        end
    end
    if #out == 0 and C_QuestLog.IsComplete and C_QuestLog.IsComplete(qid) then out[1] = C.good .. "Ready to turn in|r" end
    return table.concat(out, "\n")
end

local function build()
    pin = CreateFrame("Frame", "RUIN_PathfinderPin", UIParent)
    pin:SetSize(PIN, PIN)
    pin:SetFrameStrata("LOW")
    pin:EnableMouse(false)
    pin:Hide()

    -- the marker: a gold ring around the Pathfinder map
    pin.glow = pin:CreateTexture(nil, "BACKGROUND")
    pin.glow:SetTexture("Interface\\GLUES\\Models\\UI_Draenei\\GenericGlow64")
    pin.glow:SetPoint("CENTER"); pin.glow:SetSize(PIN * 1.9, PIN * 1.9)
    pin.glow:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.55)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    pin.icon:SetPoint("CENTER"); pin.icon:SetSize(PIN - 10, PIN - 10)
    if pin.icon.SetMask then pin.icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask") end
    pin.ring = pin:CreateTexture(nil, "OVERLAY")
    pin.ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    pin.ring:SetSize(PIN * 1.75, PIN * 1.75)
    pin.ring:SetPoint("TOPLEFT", pin, "TOPLEFT", -2, 2)
    pin.ring:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
    pin.check = pin:CreateTexture(nil, "OVERLAY", nil, 2)
    pin.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    pin.check:SetPoint("CENTER"); pin.check:SetSize(PIN - 8, PIN - 8)
    pin.check:Hide()

    -- a beam down to the ground under the marker
    pin.beam = pin:CreateTexture(nil, "BACKGROUND")
    pin.beam:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.45)
    pin.beam:SetSize(2, 46)
    pin.beam:SetPoint("TOP", pin, "BOTTOM", 0, 2)

    -- the edge arrow, when the spot is off screen
    pin.arrow = pin:CreateTexture(nil, "OVERLAY")
    if not (pin.arrow.SetAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("Navigation-Tracked-Arrow")
            and pin.arrow:SetAtlas("Navigation-Tracked-Arrow") ~= false) then
        pin.arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
    end
    pin.arrow:SetSize(EDGE_ARROW, EDGE_ARROW)
    pin.arrow:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
    pin.arrow:Hide()

    -- the card: title, small line, distance and time, objectives
    pin.title = W.Label(pin, "", "GameFontNormal")
    pin.title:SetPoint("BOTTOM", pin, "TOP", 0, 4)
    pin.title:SetJustifyH("CENTER")
    pin.title:SetShadowOffset(1, -1)
    pin.sub = W.Label(pin, "", "GameFontHighlightSmall")
    pin.sub:SetPoint("BOTTOM", pin.title, "TOP", 0, 1)
    pin.sub:SetJustifyH("CENTER")
    pin.dist = W.Label(pin, "", "GameFontHighlightLarge")
    pin.dist:SetJustifyH("CENTER")
    pin.dist:SetShadowOffset(1, -1)
    pin.obj = W.Label(pin, "", "GameFontHighlightSmall")
    pin.obj:SetJustifyH("LEFT")
    pin.obj:SetWidth(220)
    pin.obj:SetPoint("TOP", pin.dist, "BOTTOM", 0, -4)
end

local function setGameMarker(hide)
    if hide == hidGame or not SuperTrackedFrame then return end
    hidGame = hide
    for _, key in ipairs(GAME_PARTS) do
        local part = SuperTrackedFrame[key]
        if part and part.SetAlpha then part:SetAlpha(hide and 0 or 1) end
    end
end

local lastQuest, objTick = nil, 0
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

    pin:ClearAllPoints()
    pin.dist:ClearAllPoints()
    if clamped then
        -- at the edge: pull the marker in from the border and point the arrow at the spot
        local w, h = UIParent:GetWidth(), UIParent:GetHeight()
        local cx, cy = w / 2, h / 2
        local dx, dy = nx - cx, ny - cy
        local angle = math.atan2(dy, dx)
        local ex = math.max(EDGE_INSET, math.min(w - EDGE_INSET, nx))
        local ey = math.max(EDGE_INSET, math.min(h - EDGE_INSET, ny))
        pin:SetPoint("CENTER", UIParent, "BOTTOMLEFT", ex, ey)
        pin.arrow:ClearAllPoints()
        pin.arrow:SetPoint("CENTER", pin, "CENTER", math.cos(angle) * (PIN * 0.85), math.sin(angle) * (PIN * 0.85))
        pin.arrow:SetRotation(angle - math.pi / 2)
        pin.arrow:Show()
        pin.beam:Hide()
        pin.obj:Hide()
        pin:SetScale(0.8)
        pin.dist:SetPoint("TOP", pin, "BOTTOM", 0, -2)
    else
        pin:SetPoint("CENTER", UIParent, "BOTTOMLEFT", nx, ny + 30)
        pin.arrow:Hide()
        pin.beam:Show()
        pin:SetScale(yards > FAR and 0.85 or 1)
        pin.dist:SetPoint("TOP", pin.beam, "BOTTOM", 0, -2)
        pin.obj:SetShown(qid ~= nil)
    end

    pin.title:SetText(title or "")
    pin.sub:SetText(sub and (C.dim .. sub .. "|r") or "")
    local walk = walkText(yards)
    pin.dist:SetText(yardsText(yards) .. (walk and ("  " .. C.dim .. walk .. "|r") or ""))
    objTick = objTick + (elapsed or 0)
    if qid ~= lastQuest or objTick > 1 then
        objTick, lastQuest = 0, qid
        pin.obj:SetText(objectives(qid))
    end
    pin:Show()
end

local function detach()
    navFrame = nil
    if pin then pin:Hide(); pin:SetScript("OnUpdate", nil) end
    setGameMarker(false)
end

local function attach()
    if not on() then return detach() end
    navFrame = C_Navigation.GetFrame()
    if not navFrame then return detach() end
    if not pin then build() end
    pin.check:Hide()
    pin.icon:SetAlpha(1)
    setGameMarker(true)
    pin:SetScript("OnUpdate", update)
end

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
    if C_Navigation and C_Navigation.GetFrame and C_Navigation.GetFrame() then attach() else detach() end
end

M.Pin = { Update = function() if pin and navFrame then update(nil, 0) end end, Frame = function() return pin end }
