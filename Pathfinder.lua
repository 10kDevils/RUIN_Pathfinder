-- RUIN Pathfinder: the Leveling & Quest Guide
-- Pick a route; a small tracker shows the current step, points an arrow at
-- where to go, and ticks steps off as you accept, finish and hand in quests.
-- Steps read as a checklist with the brief's marker colors (quest, turn-in,
-- class quest, trainer, waypoint), and a class track reminds you of trainer
-- visits. RUIN members on the same step are counted, and you can follow a
-- leveling partner's route. Route authors record routes in game (the
-- recorder is how RUIN collects real WoW Forever routes) and share them with
-- RUIN or as copy-paste strings.
local ADDON, ns = ...
local R = RUIN_API
if not R or (R.apiLevel or 1) < 4 then
    print("|cff54b7d9[RUIN]|r Pathfinder needs a newer RUIN Core (0.3.7 or later).")
    return
end
local W = R.Widgets
local C = W.COLORS

local M = R:RegisterModule("Pathfinder", { version = "0.3.8" })

local SHARE_EVERY, PEER_TTL = 120, 300
local ACT_LABEL = { accept = "Accept", complete = "Do", turnin = "Turn in", go = "Go", note = "Note",
                    class = "Class quest", trainer = "Trainer" }
local ACTS = { "go", "note", "accept", "complete", "turnin", "class", "trainer" }
-- Marker color for each kind of step, shared with the map legend.
local ACT_MARKER = { accept = "quest", complete = "quest", turnin = "turnin", go = "waypoint", note = "waypoint",
                     class = "class", trainer = "trainer" }
local ACT_GLYPH = { accept = "!", complete = "!", turnin = "?", go = ">", note = "i", class = "!", trainer = "T" }
local DEFAULTS = { route = nil, step = 1, tracker = true, trackerPos = nil, follow = nil, arrow = true,
                   trainer = true, lastTrainer = 0, recBadgePos = nil }
local ACCOUNT_DEFAULTS = { custom = {}, inbox = {}, rec = { on = false, title = "", steps = {} } }
local MAX_STEPS = 200

local db           -- per character: route, step, tracker
local adb          -- account: custom routes, shared-route inbox, recorder
local peers = {}   -- GUID -> { name, guild, route, step, t }
local lastShare = -999
local ui = { tab = 1 }
local tracker
local warnedMissing = {}

---------------------------------------------------------------------------
-- Routes: built-in, recorded and shared
---------------------------------------------------------------------------
local function allRoutes()
    local list = {}
    for _, r in ipairs(ns.Routes) do list[#list + 1] = r end
    local custom = {}
    for _, r in pairs(adb.custom) do custom[#custom + 1] = r end
    table.sort(custom, function(a, b) return a.title < b.title end)
    for _, r in ipairs(custom) do list[#list + 1] = r end
    return list
end

local function routeById(id)
    if not id then return nil end
    for _, r in ipairs(ns.Routes) do if r.id == id then return r end end
    return adb and adb.custom[id]
end

local function currentRoute() return db.route and routeById(db.route) end
local function currentStep()
    local r = currentRoute()
    return r and r.steps[db.step], r
end

local function markerHex(act)
    local c = W.MARKERS[ACT_MARKER[act] or "waypoint"] or W.MARKERS.waypoint
    return ("|cff%02x%02x%02x"):format(c[1] * 255, c[2] * 255, c[3] * 255)
end

local function stepText(s)
    if not s then return "" end
    local label = markerHex(s.act) .. "[" .. (ACT_LABEL[s.act] or s.act) .. "]|r "
    local quest = s.quest and (C.white .. s.quest .. "|r  ") or ""
    return label .. quest .. C.dim .. (s.text or "") .. "|r"
end

-- Keep only well-formed steps from a route that came from someone else.
local function cleanRoute(r)
    if type(r) ~= "table" or type(r.title) ~= "string" or type(r.steps) ~= "table" then return nil end
    local out = { title = r.title:sub(1, 40), faction = type(r.faction) == "string" and r.faction:sub(1, 10) or "Any",
                  author = type(r.author) == "string" and r.author:sub(1, 40) or "?", steps = {} }
    for i, s in ipairs(r.steps) do
        if i > MAX_STEPS then break end
        if type(s) == "table" and ACT_LABEL[s.act] then
            local st = { act = s.act, quest = type(s.quest) == "string" and s.quest:sub(1, 60) or nil,
                         text = type(s.text) == "string" and s.text:sub(1, 120) or "",
                         qid = tonumber(s.qid) and math.floor(tonumber(s.qid)) or nil }
            if type(s.at) == "table" and type(s.at.zone) == "string" and tonumber(s.at.x) and tonumber(s.at.y) then
                st.at = { zone = s.at.zone:sub(1, 40), x = tonumber(s.at.x), y = tonumber(s.at.y) }
            end
            out.steps[#out.steps + 1] = st
        end
    end
    if #out.steps == 0 then return nil end
    return out
end

local function addCustom(r)
    r.id = "c" .. GetServerTime() .. math.random(100, 999)
    adb.custom[r.id] = r
    return r
end

---------------------------------------------------------------------------
-- Waypoints: where a step happens, and the arrow
---------------------------------------------------------------------------
-- Your current map, or a parent of it, whose name matches the step's zone.
local function resolveZone(zone)
    local map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local depth = 0
    while map and depth < 4 do
        local info = C_Map.GetMapInfo and C_Map.GetMapInfo(map)
        if not info then return nil end
        if info.name and info.name:lower() == zone:lower() then return map end
        map, depth = info.parentMapID, depth + 1
    end
    return nil
end

local function questIdByTitle(title)
    if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) then return nil end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.title and info.title:lower() == title:lower() then return info.questID end
    end
end

-- With Questie installed (RUIN uses it at runtime; nothing of its data is
-- copied into RUIN): where a quest starts or is handed in. Steps recorded
-- since Pathfinder 0.3.6 carry the quest ID; older steps fall back to
-- finding the quest in your log by title.
local questieCache = {}
local function questieNpcSpot(DB, ZoneDB, npcId)
    local okn, npc = pcall(DB.GetNPC, npcId)
    if not okn or type(npc) ~= "table" or type(npc.spawns) ~= "table" then return nil end
    for areaId, spots in pairs(npc.spawns) do
        local okm, map = pcall(ZoneDB.GetUiMapIdByAreaId, ZoneDB, areaId)
        local spot = type(spots) == "table" and spots[1]
        if okm and map and type(spot) == "table" and spot[1] then
            return { map = map, x = spot[1] / 100, y = spot[2] / 100 }
        end
    end
    return nil
end

-- which: "start" (quest giver) or "finish" (where it's handed in)
local function questieSpot(qid, which)
    if not QuestieLoader or not qid then return nil end
    local key = which .. ":" .. qid
    if questieCache[key] ~= nil then return questieCache[key] or nil end
    questieCache[key] = false
    local ok, DB = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieDB")
    local ok2, ZoneDB = pcall(QuestieLoader.ImportModule, QuestieLoader, "ZoneDB")
    if not (ok and DB and ok2 and ZoneDB) then return nil end
    local okq, q = pcall(DB.GetQuest, qid)
    if not okq or type(q) ~= "table" then return nil end
    local npcId
    if which == "finish" then
        npcId = (type(q.Finisher) == "table" and q.Finisher.Id)
            or (type(q.finishedBy) == "table" and type(q.finishedBy[1]) == "table" and q.finishedBy[1][1])
    else
        npcId = (type(q.Starts) == "table" and type(q.Starts.NPC) == "table" and q.Starts.NPC[1])
            or (type(q.startedBy) == "table" and type(q.startedBy[1]) == "table" and q.startedBy[1][1])
    end
    if not npcId then return nil end
    local spot = questieNpcSpot(DB, ZoneDB, npcId)
    questieCache[key] = spot or false
    return spot
end
M.QuestieSpot = questieSpot

-- map, x, y (0-1) for a step, or nil, plus the zone name when it's elsewhere.
local function stepPos(s)
    if not s then return nil end
    if s.at then
        local map = resolveZone(s.at.zone)
        if map then return map, s.at.x / 100, s.at.y / 100 end
        return nil, nil, nil, s.at.zone
    end
    local q
    if s.act == "turnin" then
        q = questieSpot(s.qid or (s.quest and questIdByTitle(s.quest)), "finish")
    elseif s.act == "accept" or s.act == "class" then
        q = questieSpot(s.qid, "start")
    end
    if q then return q.map, q.x, q.y end
    return nil
end

local function updateStepPin()
    local s = currentStep()
    local map, x, y = stepPos(s)
    if map and db.arrow then
        R.Map:SetPin("Pathfinder", "step", { map = map, x = x, y = y, icon = "Interface\\Icons\\INV_Misc_Map_01",
            color = W.MARKERS[ACT_MARKER[s.act] or "waypoint"], title = "Pathfinder: " .. (ACT_LABEL[s.act] or s.act) .. (s.quest and (" " .. s.quest) or ""),
            text = s.text or "" })
    else
        R.Map:RemovePin("Pathfinder", "step")
    end
end

---------------------------------------------------------------------------
-- Sharing your place on the route, and following someone else's
---------------------------------------------------------------------------
local function share()
    if not R:IsConnected() then return end
    lastShare = GetTime()
    M:Send("STEP", { g = R:GetPlayerGUID(), gu = R:GetPlayer().guild, r = db.route or "", s = db.step },
        "ORG", nil, R.PRIORITY.BULK)
end

local function sameStepPeers()
    local list, now = {}, GetTime()
    for _, p in pairs(peers) do
        if now - p.t <= PEER_TTL and p.route == db.route and p.step == db.step then list[#list + 1] = p end
    end
    return list
end

local function livePeers()
    local list, now = {}, GetTime()
    for g, p in pairs(peers) do
        if now - p.t <= PEER_TTL and p.route ~= "" then p.guid = g; list[#list + 1] = p end
    end
    table.sort(list, function(a, b)
        local am, bm = a.route == db.route, b.route == db.route
        if am ~= bm then return am end
        return (a.step or 0) > (b.step or 0)
    end)
    return list
end

local refreshPage = function() end
local updateTracker, flashTracker

function M:Follow(guid)
    db.follow = guid
    local p = guid and peers[guid]
    if p then
        self:Print("Following " .. R.Util.ShortName(p.name) .. "'s route. Your tracker moves when theirs does.")
        self:OnStep({ g = guid, gu = p.guild, r = p.route, s = p.step }, p.name)
    elseif not guid then
        self:Print("No longer following anyone.")
    end
    updateTracker()
    refreshPage()
end

function M:OnStep(d, sender)
    if type(d.g) ~= "string" or d.g == R:GetPlayerGUID() then return end
    peers[d.g] = { name = sender, guild = d.gu, route = d.r, step = tonumber(d.s) or 0, t = GetTime() }
    if db.follow == d.g and type(d.r) == "string" and d.r ~= "" then
        if routeById(d.r) then
            local moved = db.route ~= d.r or db.step ~= tonumber(d.s)
            db.route, db.step = d.r, tonumber(d.s) or 1
            if moved then updateTracker(); updateStepPin(); flashTracker(); refreshPage() end
        elseif not warnedMissing[d.r] then
            warnedMissing[d.r] = true
            self:Print(R.Util.ShortName(sender) .. " is on a route you don't have. Ask them to share it (Routes page, Share with RUIN).")
        end
    end
end

---------------------------------------------------------------------------
-- Tracker
---------------------------------------------------------------------------
local function arrowTick(nav, elapsed)
    nav.acc = (nav.acc or 0) + (elapsed or 0)
    if nav.acc < 0.05 then return end
    nav.acc = 0
    local s = currentStep()
    local map, x, y, elsewhere = stepPos(s)
    local arrow, dist = tracker.arrow, tracker.dist
    if not db.arrow or not s then arrow:Hide(); dist:SetText(""); return end
    if not map then
        arrow:Hide()
        dist:SetText(elsewhere and (C.dim .. elsewhere .. "|r") or "")
        return
    end
    local east, north, yards = R.Map:Offset(map, x, y)
    local facing = GetPlayerFacing and GetPlayerFacing()
    if not yards or not facing then arrow:Hide(); dist:SetText(""); return end
    arrow:SetRotation(math.atan2(-east, north) - facing)
    if yards < 15 then arrow:SetVertexColor(0.3, 1, 0.3) else arrow:SetVertexColor(1, 0.82, 0.2) end
    arrow:Show()
    dist:SetText(yards < 15 and (C.good .. "here|r") or ("%d yards"):format(yards))
end

updateTracker = function()
    if not db then return end
    local s, r = currentStep()
    if not db.tracker or not r then
        if tracker then tracker:Hide() end
        return
    end
    if not tracker then
        tracker = W.HudFrame("RUIN_PathfinderTracker", "Pathfinder", db, "trackerPos", { "RIGHT", UIParent, "RIGHT", -40, 140 })
        tracker:SetSize(310, 92)
        tracker.title = W.Label(tracker, "", "GameFontNormalSmall")
        tracker.title:SetPoint("TOPLEFT", 10, -9)
        tracker.title:SetPoint("RIGHT", tracker, "RIGHT", -52, 0)
        tracker.title:SetWordWrap(false)
        tracker.step = W.Label(tracker, "")
        tracker.step:SetPoint("TOPLEFT", 10, -25)
        tracker.step:SetWidth(242)
        tracker.step:SetJustifyV("TOP")
        tracker.peers = W.Label(tracker, "", "GameFontHighlightSmall")
        tracker.peers:SetPoint("BOTTOMLEFT", 10, 8)
        tracker.peers:SetPoint("RIGHT", tracker, "RIGHT", -64, 0)
        tracker.peers:SetWordWrap(false)
        tracker.next = W.Button(tracker, ">", 26, function() M:Advance(1) end)
        tracker.next:SetPoint("BOTTOMRIGHT", -6, 4)
        tracker.prev = W.Button(tracker, "<", 26, function() M:Advance(-1) end)
        tracker.prev:SetPoint("RIGHT", tracker.next, "LEFT", -2, 0)
        -- Waypoint arrow: points where the step happens and turns as you turn.
        tracker.arrow = tracker:CreateTexture(nil, "ARTWORK")
        tracker.arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
        tracker.arrow:SetSize(30, 30)
        tracker.arrow:SetPoint("TOPRIGHT", -12, -8)
        tracker.arrow:Hide()
        tracker.dist = W.Label(tracker, "", "GameFontHighlightSmall")
        tracker.dist:SetPoint("TOP", tracker.arrow, "BOTTOM", 0, 0)
        tracker.nav = CreateFrame("Frame", nil, tracker)
        tracker.nav:SetScript("OnUpdate", arrowTick)
    end
    tracker.title:SetText(("Pathfinder  ·  %s  %d/%d"):format(r.title, math.min(db.step, #r.steps), #r.steps))
    tracker.step:SetText(s and stepText(s) or (C.good .. "Route complete!|r"))
    local n = #sameStepPeers()
    local follow = db.follow and peers[db.follow]
    local line = follow and (C.gold .. "Following " .. R.Util.ShortName(follow.name) .. "|r  ") or ""
    if n > 0 then line = line .. C.good .. n .. " RUIN member" .. (n > 1 and "s" or "") .. " on this step|r" end
    tracker.peers:SetText(line)
    tracker:Show()
end

---------------------------------------------------------------------------
-- Step-change shimmer: the tracker's edge glows and a bright spark runs
-- once around the border, so you notice the new step at a glance.
---------------------------------------------------------------------------
local FLASH_SECONDS = 1.4

flashTracker = function()
    if not tracker or not tracker:IsShown() then return end
    if not tracker.edges then
        local function tex(r, g, b)
            local t = tracker:CreateTexture(nil, "OVERLAY")
            t:SetColorTexture(r, g, b, 1)
            t:SetBlendMode("ADD")
            t:Hide()
            return t
        end
        local e = { top = tex(0.55, 1, 0.4), bottom = tex(0.55, 1, 0.4), left = tex(0.55, 1, 0.4), right = tex(0.55, 1, 0.4) }
        e.top:SetPoint("TOPLEFT", 3, -3); e.top:SetPoint("TOPRIGHT", -3, -3); e.top:SetHeight(2)
        e.bottom:SetPoint("BOTTOMLEFT", 3, 3); e.bottom:SetPoint("BOTTOMRIGHT", -3, 3); e.bottom:SetHeight(2)
        e.left:SetPoint("TOPLEFT", 3, -3); e.left:SetPoint("BOTTOMLEFT", 3, 3); e.left:SetWidth(2)
        e.right:SetPoint("TOPRIGHT", -3, -3); e.right:SetPoint("BOTTOMRIGHT", -3, 3); e.right:SetWidth(2)
        tracker.edges = e
        tracker.sparks = {}
        for i = 1, 4 do
            local s = tex(1, 0.95, 0.65)
            s:SetSize(9 - i * 1.5, 9 - i * 1.5)
            tracker.sparks[i] = s
        end
    end
    tracker.flashStart = GetTime()
    tracker:SetScript("OnUpdate", function(self)
        local p = (GetTime() - self.flashStart) / FLASH_SECONDS
        if p >= 1 then
            for _, t in pairs(self.edges) do t:Hide() end
            for _, s in ipairs(self.sparks) do s:Hide() end
            self:SetScript("OnUpdate", nil)
            return
        end
        local glow = math.sin(p * math.pi)                 -- fade in, then out
        for _, t in pairs(self.edges) do t:SetAlpha(glow * 0.85); t:Show() end
        local w, h = self:GetWidth() - 6, self:GetHeight() - 6
        local perimeter = 2 * (w + h)
        for i, s in ipairs(self.sparks) do
            local d = ((p - (i - 1) * 0.018) % 1) * perimeter  -- trailing sparks
            local x, y
            if d < w then x, y = d, 0
            elseif d < w + h then x, y = w, -(d - w)
            elseif d < 2 * w + h then x, y = w - (d - w - h), -h
            else x, y = 0, -(h - (d - 2 * w - h)) end
            s:ClearAllPoints()
            s:SetPoint("CENTER", self, "TOPLEFT", x + 3, y - 3)
            s:SetAlpha(glow * (1 - (i - 1) * 0.22))
            s:Show()
        end
    end)
end

---------------------------------------------------------------------------
-- Advancing
---------------------------------------------------------------------------
-- "[RUIN] Pathfinder: Waypoint set: The Forgotten Heirloom (252 yards)"
local function announceWaypoint()
    local s = currentStep()
    if not (s and db.arrow) then return end
    local map, x, y = stepPos(s)
    if not map then return end
    local _, _, yards = R.Map:Offset(map, x, y)
    M:Print(("Waypoint set: %s%s"):format(s.quest or (s.text ~= "" and s.text) or ACT_LABEL[s.act] or "next step",
        yards and (" (%d yards)"):format(yards) or ""))
end

function M:Advance(delta)
    local r = currentRoute()
    if not r then return end
    local before = db.step
    db.step = math.max(1, math.min(#r.steps + 1, db.step + delta))
    share()
    updateTracker()
    updateStepPin()
    refreshPage()
    if db.step ~= before then flashTracker(); announceWaypoint() end
end

function M:StartRoute(id)
    if not routeById(id) then return end
    db.route, db.step = id, 1
    share()
    updateTracker()
    updateStepPin()
    refreshPage()
    announceWaypoint()
end

local function sameQuest(step, title)
    return step and step.quest and type(title) == "string" and step.quest:lower() == title:lower()
end

local function questTitle(questID, logIndex)
    if C_QuestLog and C_QuestLog.GetTitleForQuestID and questID then
        local t = C_QuestLog.GetTitleForQuestID(questID)
        if t then return t end
    end
    if GetQuestLogTitle and logIndex then return (GetQuestLogTitle(logIndex)) end
    return nil
end

-- Is the named quest in the log and complete?
local function questComplete(title)
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and info.title and info.title:lower() == title:lower() then
                return C_QuestLog.IsComplete and C_QuestLog.IsComplete(info.questID) or false
            end
        end
    elseif GetNumQuestLogEntries and GetQuestLogTitle then
        for i = 1, GetNumQuestLogEntries() do
            local qTitle, _, _, isHeader, _, isComplete = GetQuestLogTitle(i)
            if qTitle and not isHeader and qTitle:lower() == title:lower() then return isComplete == 1 or isComplete == true end
        end
    end
    return false
end

-- Quests in the log that are complete right now (for the recorder).
local function completeQuests()
    local set = {}
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and info.title and C_QuestLog.IsComplete and C_QuestLog.IsComplete(info.questID) then
                set[info.title] = true
            end
        end
    end
    return set
end

---------------------------------------------------------------------------
-- Recorder: route authors play the route once and Pathfinder writes it down
---------------------------------------------------------------------------
local wasComplete = {}

local function here()
    local zone = GetZoneText and GetZoneText() or nil
    local map, x, y = R.Map:PlayerPos()
    if not zone or zone == "" or not map then return nil end
    local info = C_Map.GetMapInfo and C_Map.GetMapInfo(map)
    return { zone = (info and info.name) or zone, x = math.floor(x * 1000 + 0.5) / 10, y = math.floor(y * 1000 + 0.5) / 10 }
end

-- A small on-screen badge while the recorder runs, so nobody records by
-- accident (the brief's "Recording: ON").
local recBadge
local function updateRecBadge()
    if not (adb and db) then return end
    if not adb.rec.on then
        if recBadge then recBadge:Hide() end
        return
    end
    if not recBadge then
        recBadge = W.HudFrame("RUIN_PathfinderRecBadge", "Pathfinder", db, "recBadgePos", { "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -220, 160 })
        recBadge:SetSize(190, 44)
        recBadge.title = W.Label(recBadge, "", "GameFontNormalSmall")
        recBadge.title:SetPoint("TOPLEFT", 10, -8)
        recBadge.sub = W.Label(recBadge, "", "GameFontHighlightSmall")
        recBadge.sub:SetPoint("TOPLEFT", recBadge.title, "BOTTOMLEFT", 0, -3)
    end
    recBadge.title:SetText(C.accent .. "RUIN|r  " .. C.good .. "Recording: ON|r")
    recBadge.sub:SetText(C.dim .. #adb.rec.steps .. " steps  ·  /path mark <note>|r")
    recBadge:Show()
end

-- Steps carry the time they were recorded (kept on this account only), so
-- route authors can see how long each stretch really took.
function M:RecordStep(act, quest, text, extra)
    if not adb.rec.on or #adb.rec.steps >= MAX_STEPS then return end
    local st = { act = act, quest = quest, text = (text or ""):sub(1, 120), at = here(), t = GetServerTime() }
    if extra then for k, v in pairs(extra) do st[k] = v end end
    adb.rec.steps[#adb.rec.steps + 1] = st
    updateRecBadge()
    refreshPage()
end

function M:SetRecording(on)
    adb.rec.on = on and true or false
    if on then wasComplete = completeQuests() end
    self:Print(on and "Recording: accept, finish and hand in quests as usual; Pathfinder writes each step down, with level-ups and the gear you get. /path mark <note> adds a note where you stand."
        or "Recording paused.")
    updateRecBadge()
    refreshPage()
end

function M:Mark(note)
    note = R.Util.Trim(note or "")
    if note == "" then return self:Print("Usage: /path mark <note>  (adds a note step where you stand)") end
    if not adb.rec.on then self:SetRecording(true) end
    self:RecordStep("note", nil, note)
    self:Print("Marked: " .. note)
end

function M:RecorderStatus()
    local rec = adb.rec
    self:Print(("Recorder %s  ·  %d steps%s"):format(rec.on and (C.good .. "ON|r") or (C.dim .. "off|r"), #rec.steps,
        rec.on and "  ·  /path mark <note> adds a note here, /path record pauses" or "  ·  /path record starts"))
end

function M:SaveRecording()
    local rec = adb.rec
    if #rec.steps == 0 then return self:Print("Nothing recorded yet.") end
    local title = R.Util.Trim(rec.title or "")
    if title == "" then title = (GetZoneText and GetZoneText() or "My") .. " route" end
    local r = addCustom({ title = title:sub(1, 40), faction = UnitFactionGroup and UnitFactionGroup("player") or "Any",
                          author = UnitName("player"), steps = rec.steps })
    adb.rec = { on = false, title = "", steps = {} }
    self:Print(("Saved %s (%d steps). Find it on the Routes page."):format(r.title, #r.steps))
    updateRecBadge()
    refreshPage()
    return r
end

local function checkComplete()
    local s = currentStep()
    if s and s.act == "complete" and s.quest and questComplete(s.quest) then M:Advance(1) end
    if adb.rec.on then
        local now = completeQuests()
        for title in pairs(now) do
            if not wasComplete[title] then M:RecordStep("complete", title, "") end
        end
        wasComplete = now
    end
end

local function onAccepted(_, a1, a2)
    -- Retail-style clients pass questID; Classic-style pass (logIndex, questID).
    local title = questTitle(a2 or a1, a2 and a1 or nil)
    local s = currentStep()
    if s and s.act == "accept" and sameQuest(s, title) then M:Advance(1) end
    local qid = tonumber(a2 or a1)
    if title then M:RecordStep("accept", title, "", qid and { qid = qid } or nil) end
    C_Timer.After(0.5, checkComplete)
end

local function onTurnedIn(_, questID)
    local title = questTitle(questID)
    local s = currentStep()
    if s and s.act == "turnin" and sameQuest(s, title) then M:Advance(1) end
    if title then
        M:RecordStep("turnin", title, "", tonumber(questID) and { qid = tonumber(questID) } or nil)
        wasComplete[title] = nil
    end
end

---------------------------------------------------------------------------
-- Class track: trainer reminders. Classic-style classes learn new spells and
-- ranks every even level; that rule is not yet confirmed on WoW Forever, so
-- the page labels it unverified.
---------------------------------------------------------------------------
local function nextTrainerLevel(level)
    level = level or UnitLevel("player") or 1
    return level % 2 == 0 and level + 2 or level + 1
end

local function onLevelUp(_, level)
    level = tonumber(level) or UnitLevel("player")
    if not level then return end
    if adb.rec.on then M:RecordStep("note", nil, "Reached level " .. level, { level = level }) end
    if db.trainer and level % 2 == 0 and level > (db.lastTrainer or 0) then
        db.lastTrainer = level
        M:Toast(("Level %d: new spells and ranks at your class trainer."):format(level))
    end
    refreshPage()
end

-- While recording, gear you receive becomes a note step with its item ID,
-- which is how RUIN learns real sources and times for the Gear Path.
local function onLootRecord(_, text, looter)
    if not adb.rec.on or type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return end
    local me = UnitName("player")
    if looter and looter ~= "" and (looter:gsub("%-.*$", "")) ~= me then return end
    -- works with both "|cff..." and the newer "|cnIQ3:" link colors
    for itemString, name in text:gmatch("|H(item:[^|]+)|h%[(.-)%]|h") do
        local id = tonumber(itemString:match("^item:(%d+)"))
        local quality
        if GetItemInfo and id then quality = select(3, GetItemInfo(id)) end
        local equip = (C_Item and C_Item.IsEquippableItem and C_Item.IsEquippableItem(itemString))
            or (IsEquippableItem and IsEquippableItem(itemString))
        if id and equip and (quality == nil or quality >= 2) then
            M:RecordStep("note", nil, "Got " .. (name or ("item " .. id)), { item = id })
        end
    end
end

---------------------------------------------------------------------------
-- Sharing routes: copy-paste strings and sending to RUIN
---------------------------------------------------------------------------
-- Shared and exported routes carry the steps only: recorded times, levels
-- and item IDs stay on your account.
local function exportable(r)
    local clean = cleanRoute(r) or { steps = {} }
    return { title = r.title, faction = r.faction, author = r.author, steps = clean.steps }
end

function M:ExportRoute(id)
    local r = routeById(id)
    if not r then return end
    R:ShowText("Export route", "Copy with Ctrl+C and paste it anywhere: Discord, a website, a friend's Pathfinder.",
        R.Util.Encode("ROUTE", exportable(r)), nil, true)
end

function M:ImportRoute(text)
    local raw, err = R.Util.Decode("ROUTE", text)
    local r = raw and cleanRoute(raw)
    if not r then return self:Print("Couldn't import: " .. tostring(err or "no usable steps") .. ".") end
    addCustom(r)
    self:Print(("Imported %s (%d steps)."):format(r.title, #r.steps))
    refreshPage()
    return r
end

function M:ShareRoute(id)
    local r = routeById(id)
    if not r then return end
    if not R:IsConnected() then return self:Print("Connect to RUIN first, or use Export to share a string.") end
    self:Send("ROUTE", exportable(r), "ORG", nil, R.PRIORITY.BULK)
    self:Print(("Shared %s with RUIN."):format(r.title))
end

function M:OnRoute(d, sender)
    local r = cleanRoute(d)
    if not r then return end
    for _, e in ipairs(adb.inbox) do
        if e.route.title == r.title and e.from == sender then return end
    end
    table.insert(adb.inbox, 1, { from = sender, route = r, t = GetServerTime() })
    while #adb.inbox > 20 do table.remove(adb.inbox) end
    self:Toast(("%s shared a route: %s (%d steps). Add it on the Pathfinder Routes page."):format(W.ClassName(sender), r.title, #r.steps))
    refreshPage()
end

function M:DeleteRoute(id)
    if not adb.custom[id] then return end
    adb.custom[id] = nil
    if db.route == id then db.route = nil; updateTracker() end
    refreshPage()
end

---------------------------------------------------------------------------
-- Page
---------------------------------------------------------------------------
local function routeLabel(r)
    local sample = false
    for _, b in ipairs(ns.Routes) do if b.id == r.id then sample = true end end
    return r.title .. " (" .. (r.faction or "Any") .. ")" .. (sample and "  - sample" or "")
end

local function isBuiltIn(id)
    for _, r in ipairs(ns.Routes) do if r.id == id then return true end end
    return false
end

local LEGEND = {
    { "quest", "Quest" }, { "turnin", "Turn-in" }, { "dungeon", "Dungeon" }, { "class", "Class quest" },
    { "trainer", "Trainer" }, { "flight", "Flight path" }, { "waypoint", "Waypoint" }, { "event", "Group event" },
}

local function diamond(parent, size, color)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetSize(size, size)
    t:SetRotation(math.pi / 4)
    t:SetColorTexture(color[1], color[2], color[3], 1)
    return t
end

local function buildCurrent(page)
    local h = W.Header(page, "Route")
    h:SetPoint("TOPLEFT", 0, -2)
    ui.pickLabels = {}
    ui.pick = W.Button(page, "", 270, nil)
    ui.pick:SetPoint("TOPLEFT", 0, -20)
    ui.pick:SetScript("OnClick", function(_, mouse)
        local routes = allRoutes()
        if #routes == 0 then return end
        local idx = 1
        for i, r in ipairs(routes) do if r.id == ui.pickId then idx = i end end
        idx = (mouse == "RightButton") and ((idx - 2) % #routes + 1) or (idx % #routes + 1)
        ui.pickId = routes[idx].id
        refreshPage()
    end)
    local start = W.Button(page, "Start this route", 130, function() if ui.pickId then M:StartRoute(ui.pickId) end end)
    start:SetPoint("LEFT", ui.pick, "RIGHT", 6, 0)
    local trackCheck = W.Check(page, "Tracker", function() return db.tracker end,
        function(v) db.tracker = v; updateTracker() end)
    trackCheck:SetPoint("LEFT", start, "RIGHT", 10, 0)
    local arrowCheck = W.Check(page, "Arrow + pin", function() return db.arrow end,
        function(v) db.arrow = v; updateStepPin() end)
    arrowCheck:SetPoint("LEFT", trackCheck, "RIGHT", 64, 0)

    -- Steps as a checklist: a box, the step's marker, the quest and where.
    local h2 = W.Header(page, "Steps")
    h2:SetPoint("TOPLEFT", 0, -54)
    ui.stepCount = W.Label(page, "", "GameFontHighlightSmall")
    ui.stepCount:SetPoint("LEFT", h2, "RIGHT", 10, 0)
    ui.samplePill = W.Pill(page, 104)
    ui.samplePill:SetPoint("LEFT", ui.stepCount, "RIGHT", 10, 0)
    ui.samplePill:SetTag("Sample", "Classic sample")
    ui.list = W.List(page, 32, function(row)
        row.box = CreateFrame("Frame", nil, row)
        row.box:SetSize(16, 16)
        row.box:SetPoint("LEFT", 6, 0)
        W.Skin(row.box, "bg", 1, "border")
        row.tick = row.box:CreateTexture(nil, "ARTWORK")
        row.tick:SetPoint("TOPLEFT", 3, -3)
        row.tick:SetPoint("BOTTOMRIGHT", -3, 3)
        row.tick:SetColorTexture(W.PALETTE.good[1], W.PALETTE.good[2], W.PALETTE.good[3], 1)
        row.marker = W.Label(row, "", "GameFontNormalLarge")
        row.marker:SetPoint("LEFT", 32, 0)
        row.marker:SetWidth(14)
        row.text = W.Label(row, "")
        row.text:SetPoint("TOPLEFT", 52, -3)
        row.text:SetPoint("RIGHT", row, "RIGHT", -34, 0)
        row.text:SetWordWrap(false)
        row.sub = W.Label(row, "", "GameFontHighlightSmall")
        row.sub:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -2)
        row.sub:SetPoint("RIGHT", row, "RIGHT", -34, 0)
        row.sub:SetWordWrap(false)
        row.num = W.Label(row, "", "GameFontHighlightSmall")
        row.num:SetPoint("RIGHT", -8, 0)
    end, function(row, s, i)
        local done, cur = i < db.step, i == db.step
        row.tick:SetShown(done)
        W.SetBorder(row.box, cur and "glow" or "border")
        row.marker:SetText(markerHex(s.act) .. (ACT_GLYPH[s.act] or "-") .. "|r")
        local title = s.quest or (s.text ~= "" and s.text) or ACT_LABEL[s.act] or s.act
        row.text:SetText((done and C.dim or (cur and C.white or "|cffd8dee8")) .. title .. "|r")
        local where = s.at and (s.at.zone .. (" (%.1f, %.1f)"):format(s.at.x, s.at.y)) or ""
        local detail = (s.quest and s.text ~= "") and s.text or ""
        row.sub:SetText(markerHex(s.act) .. (ACT_LABEL[s.act] or s.act) .. "|r" .. C.dim
            .. (where ~= "" and ("  ·  " .. where) or "") .. (detail ~= "" and ("  ·  " .. detail) or "") .. "|r")
        row.num:SetText(C.dim .. i .. "|r")
        row.tip = function(tip)
            tip:AddLine((ACT_LABEL[s.act] or s.act) .. (s.quest and (": " .. s.quest) or ""), 1, 0.82, 0)
            if s.text and s.text ~= "" then tip:AddLine(s.text, 1, 1, 1, true) end
            if s.at then tip:AddLine(("%s %.1f, %.1f"):format(s.at.zone, s.at.x, s.at.y), 0.6, 0.8, 0.6) end
        end
    end)
    ui.list:SetEmptyText("Pick a route above and press Start.")
    ui.list.frame:SetPoint("TOPLEFT", 0, -74)
    ui.list.frame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -214, 120)

    -- Right column: class track and the marker legend.
    local ct = W.Card(page)
    ct:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -54)
    ct:SetSize(194, 128)
    local cth = W.Header(ct, "Class track")
    cth:SetPoint("TOPLEFT", 10, -8)
    ui.classLine = W.Label(ct, "", "GameFontHighlight")
    ui.classLine:SetPoint("TOPLEFT", 10, -30)
    ui.trainerLine = W.Label(ct, "", "GameFontHighlightSmall")
    ui.trainerLine:SetPoint("TOPLEFT", 10, -50)
    ui.trainerLine:SetWidth(176)
    local verify = W.Pill(ct, 132)
    verify:SetPoint("TOPLEFT", 10, -68)
    verify:SetTag("Unverified", "Unverified on Forever")
    local remind = W.Check(ct, "Remind me", function() return db.trainer end, function(v) db.trainer = v end)
    remind:SetPoint("TOPLEFT", 6, -92)

    local lg = W.Card(page)
    lg:SetPoint("TOPRIGHT", ct, "BOTTOMRIGHT", 0, -8)
    lg:SetPoint("BOTTOM", page, "BOTTOM", 0, 120)
    lg:SetWidth(194)
    local lgh = W.Header(lg, "Map markers")
    lgh:SetPoint("TOPLEFT", 10, -8)
    for i, e in ipairs(LEGEND) do               -- two columns of four
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        local d = diamond(lg, 8, W.MARKERS[e[1]])
        d:SetPoint("TOPLEFT", 14 + col * 92, -32 - row * 17)
        local l = W.Label(lg, e[2], "GameFontHighlightSmall")
        l:SetPoint("LEFT", d, "RIGHT", 7, 0)
    end

    local h3 = W.Header(page, "RUIN on the road")
    h3:SetPoint("BOTTOMLEFT", 0, 100)
    ui.peers = W.List(page, 24, function(row)
        row.text = W.Label(row, "")
        row.text:SetPoint("LEFT", 4, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -80, 0)
        row.text:SetWordWrap(false)
        row.btn = W.Button(row, "Follow", 76)
        row.btn:SetPoint("RIGHT", 0, 0)
    end, function(row, p)
        local r = routeById(p.route)
        local same = p.route == db.route
        row.text:SetText(("%s  %s%s|r  %sstep %d|r%s"):format(W.ClassName(p.name), same and C.good or C.white,
            r and r.title or (C.dim .. "a route you don't have|r"), C.dim, p.step or 0,
            db.follow == p.guid and ("  " .. C.gold .. "following|r") or ""))
        local following = db.follow == p.guid
        row.btn:SetText(following and "Unfollow" or "Follow")
        row.btn:SetScript("OnClick", function() M:Follow(not following and p.guid or nil) end)
    end)
    ui.peers:SetEmptyText("Nobody else in RUIN is on a route right now.")
    ui.peers.frame:SetPoint("BOTTOMLEFT", 0, 0)
    ui.peers.frame:SetPoint("RIGHT", page, "RIGHT", -24, 0)
    ui.peers.frame:SetHeight(92)
end

local function refreshClassTrack()
    local _, class = UnitClass("player")
    local names = LOCALIZED_CLASS_NAMES_MALE
    local cname = (names and class and names[class]) or (class and (class:sub(1, 1) .. class:sub(2):lower())) or "?"
    local level = UnitLevel("player") or 1
    ui.classLine:SetText(W.ClassIcon(class, 16) .. " " .. W.ClassName(cname, class) .. C.dim .. "  level " .. level .. "|r")
    ui.trainerLine:SetText(C.dim .. "Next trainer visit: |r" .. C.white .. "level " .. nextTrainerLevel(level) .. "|r")
end

local function buildLibrary(page)
    local h = W.Header(page, "Your routes")
    h:SetPoint("TOPLEFT", 0, -2)
    local imp = W.Button(page, "Import string", 120, function()
        R:ShowText("Import route", "Paste a RUIN route string (it starts with RUIN-ROUTE1:) and press OK.", "", function(text)
            M:ImportRoute(text)
        end)
    end)
    imp:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 2)
    ui.library = W.List(page, 26, function(row)
        row.text = W.Label(row, "")
        row.text:SetPoint("LEFT", 4, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -282, 0)
        row.text:SetWordWrap(false)
        row.del = W.Button(row, "Delete", 60)
        row.del:SetPoint("RIGHT", 0, 0)
        row.share = W.Button(row, "Share", 56)
        row.share:SetPoint("RIGHT", row.del, "LEFT", -2, 0)
        row.export = W.Button(row, "Export", 60)
        row.export:SetPoint("RIGHT", row.share, "LEFT", -2, 0)
        row.start = W.Button(row, "Start", 54)
        row.start:SetPoint("RIGHT", row.export, "LEFT", -2, 0)
        row.add = W.Button(row, "Add", 46)
        row.add:SetPoint("RIGHT", row.start, "LEFT", -2, 0)
    end, function(row, e)
        if e.inbox then
            local r = e.inbox.route
            row.text:SetText(("%sShared by %s:|r %s  %s(%d steps)|r"):format(C.gold, R.Util.ShortName(e.inbox.from), r.title, C.dim, #r.steps))
            row.add:Show()
            row.add:SetScript("OnClick", function()
                addCustom(r)
                for i, x in ipairs(adb.inbox) do if x == e.inbox then table.remove(adb.inbox, i) end end
                M:Print("Added " .. r.title .. ".")
                refreshPage()
            end)
            row.start:Hide(); row.export:Hide(); row.share:Hide()
            row.del:Show()
            row.del:SetText("Dismiss")
            row.del:SetScript("OnClick", function()
                for i, x in ipairs(adb.inbox) do if x == e.inbox then table.remove(adb.inbox, i) end end
                refreshPage()
            end)
            return
        end
        local r = e.route
        local mine = adb.custom[r.id] ~= nil
        row.text:SetText(("%s%s|r  %s%s · %d steps · %s|r%s"):format(C.white, r.title, C.dim, r.faction or "Any", #r.steps,
            mine and ("by " .. R.Util.ShortName(r.author or "?")) or "built in", db.route == r.id and ("  " .. C.good .. "current|r") or "")
            .. (mine and "" or ("  " .. W.TagText("Sample", "Classic sample"))))
        row.add:Hide()
        row.start:Show(); row.export:Show(); row.share:Show()
        row.start:SetScript("OnClick", function() M:StartRoute(r.id); ui.tabs:Select(1) end)
        row.export:SetScript("OnClick", function() M:ExportRoute(r.id) end)
        row.share:SetScript("OnClick", function() M:ShareRoute(r.id) end)
        row.del:SetText("Delete")
        row.del:SetShown(mine)
        row.del:SetScript("OnClick", function()
            R:Confirm("Delete route", "Delete " .. r.title .. "? This can't be undone.", function() M:DeleteRoute(r.id) end)
        end)
    end)
    ui.library.frame:SetPoint("TOPLEFT", 0, -24)
    ui.library.frame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -24, 0)
end

local function buildRecorder(page)
    local card = W.Card(page)
    card:SetPoint("TOPLEFT", 0, 0)
    card:SetPoint("RIGHT", page, "RIGHT", -4, 0)
    card:SetHeight(86)
    local h = W.Header(card, "Record a route")
    h:SetPoint("TOPLEFT", 8, -6)
    local tl = W.Label(card, C.dim .. "Title|r", "GameFontHighlightSmall")
    tl:SetPoint("TOPLEFT", 10, -28)
    ui.recTitle = W.EditBox(card, 220, function(t) adb.rec.title = t:sub(1, 40) end)
    ui.recTitle:SetPoint("LEFT", tl, "RIGHT", 10, 0)
    ui.recBtn = W.Button(card, "", 130, function() M:SetRecording(not adb.rec.on) end)
    ui.recBtn:SetPoint("LEFT", ui.recTitle, "RIGHT", 10, 0)
    local save = W.Button(card, "Save route", 100, function() M:SaveRecording() end)
    save:SetPoint("LEFT", ui.recBtn, "RIGHT", 4, 0)
    local discard = W.Button(card, "Discard", 76, function()
        R:Confirm("Discard recording", "Throw away the steps recorded so far?", function()
            adb.rec = { on = false, title = "", steps = {} }
            refreshPage()
        end)
    end)
    discard:SetPoint("LEFT", save, "RIGHT", 4, 0)

    ui.noteAct = "note"
    local act = W.Cycle(card, 96, ACTS, function() return ui.noteAct end, function(v) ui.noteAct = v end)
    act:SetPoint("TOPLEFT", 8, -56)
    local note = W.EditBox(card, 300)
    note:SetPoint("LEFT", act, "RIGHT", 10, 0)
    local add = W.Button(card, "Add step here", 120, function()
        local text = R.Util.Trim(note:GetText() or "")
        if text == "" then return M:Print("Type what the step says first.") end
        if not adb.rec.on then adb.rec.on = true end
        local quest = (ui.noteAct == "accept" or ui.noteAct == "complete" or ui.noteAct == "turnin" or ui.noteAct == "class") and text or nil
        M:RecordStep(ui.noteAct, quest, quest and "" or text)
        note:SetText("")
    end)
    add:SetPoint("LEFT", note, "RIGHT", 6, 0)

    ui.recStatus = W.Label(page, "", "GameFontHighlightSmall")
    ui.recStatus:SetPoint("TOPLEFT", 0, -94)
    ui.recList = W.List(page, 22, function(row)
        row.text = W.Label(row, "")
        row.text:SetPoint("LEFT", 4, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -34, 0)
        row.text:SetWordWrap(false)
        row.x = W.Button(row, "X", 28)
        row.x:SetPoint("RIGHT", 0, 0)
    end, function(row, s, i)
        local where = s.at and (C.dim .. "  " .. s.at.zone .. " " .. s.at.x .. ", " .. s.at.y .. "|r") or ""
        local prev = adb.rec.steps[i - 1]
        local took = (s.t and prev and prev.t) and (C.dim .. "  +" .. W.Duration(s.t - prev.t) .. "|r") or ""
        row.text:SetText(("%2d. %s%s%s"):format(i, stepText(s), where, took))
        row.x:SetScript("OnClick", function() table.remove(adb.rec.steps, i); refreshPage() end)
    end)
    ui.recList:SetEmptyText("Press Start recording, then play: quests you accept, finish and hand in become steps, with level-ups, gear you get and the minutes between steps. Add go-to, note, class quest and trainer steps with the box above, or /path mark <note>.")
    ui.recList.frame:SetPoint("TOPLEFT", 0, -112)
    ui.recList.frame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -24, 0)
end

local function buildPage(panel)
    ui.panel = panel
    ui.tabs = W.SubTabs(panel, { "Route", "Routes", "Recorder" }, function() refreshPage() end)
    buildCurrent(ui.tabs.pages[1])
    buildLibrary(ui.tabs.pages[2])
    buildRecorder(ui.tabs.pages[3])

    refreshPage = function()
        if not ui.panel:IsVisible() then return end
        ui.tabs:SetLabel(2, #adb.inbox > 0 and ("Routes " .. C.good .. "(" .. #adb.inbox .. " new)|r") or "Routes")
        ui.tabs:SetLabel(3, adb.rec.on and ("Recorder " .. C.bad .. "(rec)|r") or "Recorder")
        local tab = ui.tabs.selected
        if tab == 1 then
            if not ui.pickId or not routeById(ui.pickId) then
                ui.pickId = db.route or (allRoutes()[1] and allRoutes()[1].id)
            end
            local pr = routeById(ui.pickId)
            ui.pick:SetText(pr and routeLabel(pr) or "No routes")
            local r = currentRoute()
            ui.list:SetItems(r and r.steps or {})
            ui.stepCount:SetText(r and (C.dim .. ("%d/%d done"):format(math.min(db.step - 1, #r.steps), #r.steps) .. "|r") or "")
            ui.samplePill:SetShown(r ~= nil and isBuiltIn(r.id))
            refreshClassTrack()
            ui.peers:SetItems(livePeers())
        elseif tab == 2 then
            local items = {}
            for _, e in ipairs(adb.inbox) do items[#items + 1] = { inbox = e } end
            for _, r in ipairs(allRoutes()) do items[#items + 1] = { route = r } end
            ui.library:SetItems(items)
        elseif tab == 3 then
            ui.recBtn:SetText(adb.rec.on and "Pause recording" or "Start recording")
            if not ui.recTitle:HasFocus() then ui.recTitle:SetText(adb.rec.title or "") end
            ui.recStatus:SetText(adb.rec.on and (C.bad .. "Recording|r " .. C.dim .. "· " .. #adb.rec.steps .. " steps so far|r")
                or (C.dim .. #adb.rec.steps .. " steps recorded|r"))
            ui.recList:SetItems(adb.rec.steps)
        end
    end
    panel:SetScript("OnShow", function() refreshPage() end)
    ui.tabs:Select(1)
end

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------
function M:OnEnable()
    if type(RUIN_PathfinderCharDB) ~= "table" then RUIN_PathfinderCharDB = {} end
    db = RUIN_PathfinderCharDB
    for k, v in pairs(DEFAULTS) do if db[k] == nil then db[k] = v end end
    if type(RUIN_PathfinderDB) ~= "table" then RUIN_PathfinderDB = {} end
    adb = RUIN_PathfinderDB
    for k, v in pairs(ACCOUNT_DEFAULTS) do if adb[k] == nil then adb[k] = R.Util.DeepCopy(v) end end

    self:Listen("STEP", "OnStep")
    self:Listen("ROUTE", "OnRoute")
    self:AddTab("Pathfinder", buildPage)
    self:RegisterEvent("QUEST_ACCEPTED", onAccepted)
    self:RegisterEvent("QUEST_TURNED_IN", onTurnedIn)
    self:RegisterEvent("QUEST_LOG_UPDATE", function() checkComplete() end)
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", function() updateStepPin() end)
    self:RegisterEvent("PLAYER_LEVEL_UP", onLevelUp)
    self:RegisterEvent("CHAT_MSG_LOOT", onLootRecord)

    R:Subscribe("CHANNELS_CHANGED", function() C_Timer.After(5, share) end)
    C_Timer.NewTicker(10, function()
        if db.route and GetTime() - lastShare >= SHARE_EVERY then share() end
        updateTracker()
        refreshPage()
    end)
    updateTracker()
    updateStepPin()
    updateRecBadge()
end

function RUIN_Pathfinder_Open() M:OpenTab() end
function RUIN_Pathfinder_Next() M:Advance(1) end
function RUIN_Pathfinder_Prev() M:Advance(-1) end
BINDING_HEADER_RUIN_PATHFINDER = "RUIN Pathfinder"
BINDING_NAME_RUIN_PATHFINDER_OPEN = "Open Pathfinder"
BINDING_NAME_RUIN_PATHFINDER_NEXT = "Pathfinder: next step"
BINDING_NAME_RUIN_PATHFINDER_PREV = "Pathfinder: previous step"

-- /path next | prev | tracker | arrow | record | rec | mark <note> | save | import | unfollow | trainer
SLASH_RUINPATH1 = "/path"
SLASH_RUINPATH2 = "/pathfinder"
SlashCmdList.RUINPATH = function(input)
    input = input or ""
    local cmd, rest = input:match("^%s*(%S*)%s*(.-)%s*$")
    if (cmd or ""):lower() == "mark" then return M:Mark(rest) end
    local msg = input:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "rec" or msg == "rec status" or msg == "status" then return M:RecorderStatus() end
    if msg == "trainer" then
        db.trainer = not db.trainer
        return M:Print("Trainer reminders " .. (db.trainer and "on." or "off."))
    end
    if msg == "next" then M:Advance(1)
    elseif msg == "prev" then M:Advance(-1)
    elseif msg == "tracker" then db.tracker = not db.tracker; updateTracker()
    elseif msg == "arrow" then db.arrow = not db.arrow; updateStepPin(); M:Print("Waypoint arrow " .. (db.arrow and "on." or "off."))
    elseif msg == "record" then M:SetRecording(not adb.rec.on)
    elseif msg == "save" then M:SaveRecording()
    elseif msg == "import" then
        R:ShowText("Import route", "Paste a RUIN route string and press OK.", "", function(text) M:ImportRoute(text) end)
    elseif msg == "unfollow" then M:Follow(nil)
    else M:OpenTab() end
end
