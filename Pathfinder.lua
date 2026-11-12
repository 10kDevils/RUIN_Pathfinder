-- RUIN Pathfinder: the Leveling & Quest Guide
-- Pick a route; a small tracker shows the current step, points an arrow at
-- where to go, and ticks steps off as you accept, finish and hand in quests.
-- Steps read as a checklist with the brief's marker colors (quest, turn-in,
-- class quest, trainer, waypoint), and a class track reminds you of trainer
-- visits. RUIN members on the same step are counted, and you can follow a
-- leveling partner's route. Route authors record routes in game (the
-- recorder is how RUIN collects real WoW Forever routes) and share them with
-- RUIN or as copy-paste strings.
-- Pathfinder reads RUIN Quest Data (where quests
-- start and end, where their targets are, what's available in your zone),
-- and RUIN members share their quest status with each other: who has the
-- same quest, who is ready to hand it in, who has done it.
local ADDON, ns = ...

-- WoW Forever runs on the Retail 12 client, where the old global item
-- functions may be gone; these ask C_Item when they are. (Inside each
-- function the name still means the global, so tests and older clients work.)
local GetItemInfo = function(...)
    local f = GetItemInfo or (C_Item and C_Item.GetItemInfo)
    if f then return f(...) end
end
local GetItemInfoInstant = function(...)
    local f = GetItemInfoInstant or (C_Item and C_Item.GetItemInfoInstant)
    if f then return f(...) end
end
local R = RUIN_API
if not R or (R.apiLevel or 1) < 7 then
    print("|cff54b7d9[RUIN]|r Pathfinder needs a newer RUIN Core (0.3.14 or later).")
    return
end
local W = R.Widgets
local C = W.COLORS

local M = R:RegisterModule("Pathfinder", { version = "0.6.1" })
local QB = ns.QB

-- What the player lets RUIN share about them (RUIN Core: Settings > Display)
local function shares(kind) return not (R.Shares and not R:Shares(kind)) end

local SHARE_EVERY, PEER_TTL = 120, 300
local QUEST_SHARE_MIN, QUEST_SHARE_EVERY, QUEST_TTL = 20, 300, 900
local ACT_LABEL = { accept = "Accept", complete = "Do", turnin = "Turn in", go = "Go", note = "Note",
                    class = "Class quest", trainer = "Trainer" }
local ACTS = { "go", "note", "accept", "complete", "turnin", "class", "trainer" }
local ACT_LABELS = { go = "Go to", note = "Note", accept = "Accept quest", complete = "Complete quest",
                     turnin = "Turn in", class = "Class quest", trainer = "Trainer" }
-- Marker color for each kind of step, shared with the map legend.
local ACT_MARKER = { accept = "quest", complete = "quest", turnin = "turnin", go = "waypoint", note = "waypoint",
                     class = "class", trainer = "trainer" }
local ACT_GLYPH = { accept = "!", complete = "!", turnin = "?", go = ">", note = "i", class = "!", trainer = "T" }
local DEFAULTS = { route = nil, step = 1, tracker = true, trackerPos = nil, follow = nil, arrow = true,
                   trainer = true, lastTrainer = 0, recBadgePos = nil, skipDone = true, shareQuests = true,
                   -- waypoint and pin settings (Options tab)
                   waypoint = true, trackQuests = true, autoNav = true, announce = true,
                   pin = true, pinHideInArea = true, pinHideYards = 15, pinObjectives = true, pinWalk = true,
                   pinScale = 1, pinEdge = true, pinOffsetX = 0, pinOffsetY = 0 }
local ACCOUNT_DEFAULTS = { custom = {}, inbox = {}, official = {}, rec = { on = false, title = "", steps = {} } }
-- Officer routes carry this badge wherever they're listed.
local OFFICER_ICON = "|TInterface\\GroupFrame\\UI-Group-AssistantIcon:14:14|t"
local MAX_STEPS = 200

local db           -- per character: route, step, tracker
local adb          -- account: custom routes, shared-route inbox, recorder
local peers = {}   -- GUID -> { name, guild, route, step, t }
local lastShare = -999
local ui = { tab = 1 }
M.UI = ui         -- for tests
local tracker
local warnedMissing = {}

---------------------------------------------------------------------------
-- Routes: built-in, recorded and shared
---------------------------------------------------------------------------
-- RUIN routes pushed by officers come first, then the built-in ones, then yours.
local function sortedOfficial()
    local list = {}
    for _, r in pairs(adb and adb.official or {}) do list[#list + 1] = r end
    table.sort(list, function(a, b) return a.title < b.title end)
    return list
end

local function allRoutes()
    local list = sortedOfficial()
    for _, r in ipairs(ns.Routes) do list[#list + 1] = r end
    local custom = {}
    for _, r in pairs(adb.custom) do custom[#custom + 1] = r end
    table.sort(custom, function(a, b) return a.title < b.title end)
    for _, r in ipairs(custom) do list[#list + 1] = r end
    return list
end

-- Dungeon quest routes, built from the quest database when first asked for (id "dq:<name>")
local dqRoutes = {}
local dqCache = {}     -- dungeon -> { t, list }: the Journal redraws often (loot, kills)
local function dqKey(name) return (tostring(name or ""):lower():gsub("^the ", ""):gsub("[^%w]", "")) end
local function dqEntry(name)
    local k = dqKey(name)
    if k == "" then return nil end
    for _, e in ipairs(ns.DungeonQuestIndex or {}) do
        if dqKey(e.name) == k then return e end
    end
    return nil
end
M.DungeonEntry = function(_, name) return dqEntry(name) end

local function dungeonRoute(entry)
    if not entry then return nil end
    local id = "dq:" .. dqKey(entry.name)
    if dqRoutes[id] then return dqRoutes[id] end
    local quests = QB.DungeonQuests(entry)
    if not quests or #quests == 0 then return nil end
    local steps = QB.DungeonRoute(entry, quests)
    if not steps or #steps == 0 then return nil end
    if #steps > MAX_STEPS then
        for i = #steps, MAX_STEPS, -1 do steps[i] = nil end
        steps[MAX_STEPS] = { act = "note", text = "The rest of this dungeon's quests didn't fit in one route." }
    end
    local r = { id = id, title = (entry.name .. " quests"):sub(1, 40), faction = UnitFactionGroup and UnitFactionGroup("player") or "Any",
                author = "RUIN (from " .. (QB.Source() or "RUIN Quest Data") .. ")", steps = steps, dungeon = entry.name, levels = entry.levels,
                quests = #quests }
    dqRoutes[id] = r
    return r
end

-- Zone quest routes, built from the quest database (id "zq:<area>:<part>"): a stub
-- with the title and levels for the lists, the steps when it's opened.
local zqRoutes = {}
local function zoneStub(z)
    local several = false
    for _, o in ipairs(QB.Zones()) do if o.area == z.area and o.part ~= z.part then several = true end end
    return { id = ("zq:%d:%d"):format(z.area, z.part),
             title = (("%s %d-%d"):format(z.name, z.lo, z.hi) .. (several and (" (" .. z.part .. ")") or "")):sub(1, 40),
             faction = UnitFactionGroup and UnitFactionGroup("player") or "Any", zoneArea = z.area, part = z.part,
             zoneName = z.name, levels = z.lo .. "-" .. z.hi, quests = #z.quests, qids = z.quests,
             author = "RUIN (from " .. (QB.Source() or "RUIN Quest Data") .. ")" }
end
local function zoneRoute(id)
    if zqRoutes[id] and zqRoutes[id].steps then return zqRoutes[id] end
    if not QB.Has() then return nil end
    for _, z in ipairs(QB.Zones()) do
        if ("zq:%d:%d"):format(z.area, z.part) == id then
            local r = zqRoutes[id] or zoneStub(z)
            local steps = QB.ZoneRoute(z.quests)
            if not steps or #steps == 0 then return nil end
            if #steps > MAX_STEPS then
                for i = #steps, MAX_STEPS, -1 do steps[i] = nil end
                steps[MAX_STEPS] = { act = "note", text = "The rest of this zone's quests didn't fit in one route." }
            end
            r.steps = steps
            zqRoutes[id] = r
            return r
        end
    end
    return nil
end
-- every zone part with quests for you, as stubs (no steps yet)
local function zoneRoutes()
    local out = {}
    if not QB.Has() then return out end
    for _, z in ipairs(QB.Zones()) do
        local id = ("zq:%d:%d"):format(z.area, z.part)
        zqRoutes[id] = zqRoutes[id] or zoneStub(z)
        out[#out + 1] = zqRoutes[id]
    end
    return out
end

local function isBuiltInRoute(id)
    for _, r in ipairs(ns.Routes) do if r.id == id then return true end end
    return false
end

local function routeById(id)
    if not id then return nil end
    if type(id) == "string" and id:sub(1, 3) == "zq:" then return zoneRoute(id) end
    if type(id) == "string" and id:sub(1, 3) == "dq:" then
        if dqRoutes[id] then return dqRoutes[id] end
        for _, e in ipairs(ns.DungeonQuestIndex or {}) do
            if "dq:" .. dqKey(e.name) == id then return dungeonRoute(e) end
        end
        return nil
    end
    for _, r in ipairs(ns.Routes) do if r.id == id then return r end end
    return adb and (adb.custom[id] or adb.official[id])
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
            if s.act == "complete" and type(s.qids) == "table" then
                local list = {}
                for k, q in ipairs(s.qids) do
                    if k > 6 then break end
                    if tonumber(q) then list[#list + 1] = math.floor(tonumber(q)) end
                end
                if #list > 1 then st.qids = list end
            end
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
    -- anywhere else: the zone by name from the world map's own list
    return R.Map.ZoneMapID and R.Map:ZoneMapID(zone) or nil
end

local function questIdByTitle(title)
    if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) then return nil end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.title and info.title:lower() == title:lower() then return info.questID end
    end
end

-- Where a step happens when the route gives no place: the quest database
-- (see QuestDB.lua) by quest ID, else by finding the quest in your log.
-- The quest a step is about: for a "complete" step shared by several
-- quests, the first one that still needs work.
local function workQid(s)
    if s and s.act == "complete" and type(s.qids) == "table" then
        for _, q in ipairs(s.qids) do
            if not QB.Done(q) and not select(2, QB.InLog(q)) then return q end
        end
    end
    return s and s.qid
end
M.WorkQid = function(_, s) return workQid(s) end
local function stepQid(s)
    return s and (workQid(s) or (s.quest and questIdByTitle(s.quest))) or nil
end

-- map, x, y (0-1) for a step, or nil, plus the zone name when it's elsewhere.
local function stepPos(s)
    if not s then return nil end
    if s.at then
        local map = resolveZone(s.at.zone)
        if map then return map, s.at.x / 100, s.at.y / 100 end
        return nil, nil, nil, s.at.zone
    end
    local which = (s.act == "turnin" and "finish") or ((s.act == "accept" or s.act == "class") and "start")
        or (s.act == "complete" and "objective")
    local qid = which and stepQid(s)
    if not qid then return nil end
    local map, px, py = R.Map:PlayerPos()
    local q = QB.Spot(qid, which, map, px, py)
    if q then return q.map, q.x, q.y end
    return nil
end

-- Where to point: the current step's spot, or for a step with no place of
-- its own (a note, a level-up) the next step that has one.
local function navStep()
    local s, r = currentStep()
    if not s then return nil end
    for i = db.step, math.min(#r.steps, db.step + 6) do
        local st = r.steps[i]
        local map, x, y, elsewhere = stepPos(st)
        if map or elsewhere then return st, map, x, y, elsewhere end
    end
    return s
end

-- The game's own waypoint on the step: its 3D pin in the world (with the
-- distance under it) and its map pin. Only a waypoint Pathfinder placed is
-- ever moved or cleared; one you place yourself is left alone until the
-- next step.
-- When Pathfinder itself last changed what the game tracks: tracking events
-- right after that are Pathfinder's, not yours.
local selfChangeAt = -10
local function selfChange() selfChangeAt = GetTime() end
M.SelfChanged = function() return GetTime() - selfChangeAt < 0.75 end

local placedWp
local function sameSpot(a, b)
    return a and b and a.map == b.map and math.abs(a.x - b.x) < 0.0005 and math.abs(a.y - b.y) < 0.0005
end
local function currentWaypoint()
    local p = C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
    if not p then return nil end
    local x, y = p.position.x, p.position.y
    if p.position.GetXY then x, y = p.position:GetXY() end
    return { map = p.uiMapID, x = x, y = y }
end
-- Changes to the game's tracking (super-tracked quest, user waypoint) never
-- happen in combat: the objective tracker answers them, and its quest item
-- buttons are protected then. They wait for combat to end (combatPending).
local combatPending
local function inCombat()
    if InCombatLockdown and InCombatLockdown() then combatPending = true; return true end
    return false
end
local function clearWaypoint()
    if inCombat() then return end
    if placedWp and C_Map and C_Map.ClearUserWaypoint and sameSpot(currentWaypoint(), placedWp) then
        selfChange()
        C_Map.ClearUserWaypoint()
    end
    placedWp = nil
end
-- The world pin only draws with the game's In-Game Navigation option on.
local function ensureNavigation()
    if db.autoNav == false then return end
    if GetCVar and SetCVar and GetCVar("showInGameNavigation") == "0" and not (InCombatLockdown and InCombatLockdown()) then
        if pcall(SetCVar, "showInGameNavigation", "1") and not db.navTurnedOn then
            db.navTurnedOn = true
            M:Print("Turned on the game's In-Game Navigation so the waypoint shows in the world. /path waypoint turns Pathfinder's waypoint off.")
        end
    end
end

-- A quest step whose quest is in your log is tracked the game's own way
-- (super-tracked), so the pin follows the quest's objective or turn-in
-- like clicking it in the objective tracker. Quests the game can't place
-- fall back to a waypoint on Pathfinder's spot.
local placedQuest, questAt
local questNoNav = {}
local function inLog(qid)
    return C_QuestLog and C_QuestLog.GetLogIndexForQuestID and (C_QuestLog.GetLogIndexForQuestID(qid) or 0) > 0
end
local function trackableQuest(s)
    local q = workQid(s)
    return q and (s.act == "complete" or s.act == "turnin") and not questNoNav[q]
        and C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID and inLog(q) and q
end
-- The quest YOU chose to track (clicked in the objective tracker, or picked
-- on the tracker's Tracked tab), kept apart from the quests Pathfinder
-- tracks for route steps. The world pin follows it while the tracker is on
-- the Tracked tab.
local settingQuest            -- a quest Pathfinder is tracking right now (its event isn't yours)
local function userQuest()
    local q = db and db.userQuest
    if q and inLog(q) then return q end
end
M.UserQuest = userQuest
local function superTrackQuest(q)
    if not (C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID) or inCombat() then return false end
    if C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID() == q then return true end
    settingQuest = q
    selfChange()
    local ok = pcall(C_SuperTrack.SetSuperTrackedQuestID, q)
    settingQuest = nil
    return ok
end

local function releaseQuest()
    if placedQuest and C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID
            and C_SuperTrack.GetSuperTrackedQuestID() == placedQuest and placedQuest ~= userQuest() then
        superTrackQuest(0)
    end
    placedQuest = nil
end

local function noteWp(why, map, x, y, err)
    db.navLast = { t = time and time() or 0, route = db.route, step = db.step, why = why, map = map, x = x, y = y, err = err and tostring(err) }
end
local function updateWaypoint(map, x, y, s)
    -- never change the game's tracking in combat (see inCombat); catch up when combat ends
    if inCombat() then return end
    combatPending = nil
    -- the Tracked tab: the world pin follows your tracked quest, not the route
    local uq = userQuest()
    if uq and (db.trackerTab == "tracked" or not currentRoute()) then
        clearWaypoint()
        placedQuest = nil
        if not (C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID() == uq) then superTrackQuest(uq) end
        ensureNavigation()
        return noteWp("following your tracked quest " .. uq)
    end
    local tq = db.waypoint ~= false and db.trackQuests ~= false and trackableQuest(s)
    if tq then
        if placedQuest == tq and C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID() == tq then return end
        clearWaypoint()
        if placedQuest ~= tq then releaseQuest() end
        settingQuest = tq
        selfChange()
        local ok, err = pcall(C_SuperTrack.SetSuperTrackedQuestID, tq)
        settingQuest = nil
        if not ok then
            questNoNav[tq] = true
            noteWp("quest tracking failed", nil, nil, nil, err)
            return updateWaypoint(map, x, y, s)
        end
        placedQuest, questAt = tq, GetTime()
        ensureNavigation()
        return noteWp("tracking quest " .. tq)
    end
    releaseQuest()
    if not (C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates) then
        return noteWp("no waypoint API (C_Map.SetUserWaypoint " .. tostring(C_Map and C_Map.SetUserWaypoint ~= nil) .. ", UiMapPoint " .. tostring(UiMapPoint ~= nil) .. ")")
    end
    if not (map and db.waypoint ~= false) then
        clearWaypoint()
        return noteWp(not map and "step has no spot" or "turned off")
    end
    local want = { map = map, x = x, y = y }
    if sameSpot(placedWp, want) and sameSpot(currentWaypoint(), want) then return end
    if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(map) then
        clearWaypoint()
        return noteWp("map doesn't take waypoints", map, x, y)
    end
    selfChange()
    local ok, err = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(map, x, y))
    if not ok then return noteWp("SetUserWaypoint failed", map, x, y, err) end
    placedWp = want
    local tok, terr = true, nil
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        tok, terr = pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    end
    ensureNavigation()
    noteWp(tok and ("placed; now " .. tostring(currentWaypoint() and "set" or "missing")) or "super-track failed", map, x, y, terr)
end

function M.PinOn() return db and db.pin ~= false end
-- the pin's settings, read live by WaypointPin.lua
function M.PinSetting(key) return db and db[key] end
function M.SetPinSetting(key, v) if db then db[key] = v end; M.pinDirty = true end

-- What the RUIN pin should call the current target, when it's Pathfinder's.
function M.PinInfo()
    local s = navStep()
    if not s then return nil end
    local label = ACT_LABEL[s.act] or s.act
    local title = s.quest or (s.text ~= "" and s.text) or label
    if placedWp and C_SuperTrack and C_SuperTrack.IsSuperTrackingUserWaypoint and C_SuperTrack.IsSuperTrackingUserWaypoint()
            and sameSpot(currentWaypoint(), placedWp) then
        return { title = title, act = label, step = db.step, route = currentRoute() and currentRoute().title }
    end
    if placedQuest then return { quest = placedQuest, act = label, step = db.step, route = currentRoute() and currentRoute().title } end
end

-- /path nav: every link from the step to the arrow and the world pin, so a
-- break can be seen from chat
function M:NavReport()
    local lines = {}
    adb.navReport = lines
    local realPrint = self.Print
    local me = self
    local function out(_, m) lines[#lines + 1] = m; realPrint(me, m) end
    self = setmetatable({ Print = out }, { __index = me })
    local function v(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end return table.concat(t, ", ") end
    local s, r = currentStep()
    self:Print(("Nav: route %s, step %s/%s: %s %s"):format(tostring(db.route), tostring(db.step), r and #r.steps or "-",
        s and tostring(s.act) or "-", s and s.at and ("at " .. v(s.at.zone, s.at.x, s.at.y)) or (s and s.qid and ("quest " .. s.qid) or "")))
    local ns_, map, x, y, elsewhere = navStep()
    if ns_ and ns_ ~= s then self:Print("  pointing at a later step: " .. v(ns_.act, ns_.quest or ns_.text)) end
    local info = map and C_Map.GetMapInfo and C_Map.GetMapInfo(map)
    self:Print("  step spot: " .. v(map, x, y, elsewhere) .. (info and (" (" .. tostring(info.name) .. ", type " .. tostring(info.mapType) .. ")") or ""))
    if s and s.at then self:Print("  zone lookup: " .. v(R.Map.ZoneMapID and R.Map:ZoneMapID(s.at.zone))) end
    local pm, px, py = R.Map:PlayerPos()
    self:Print("  you: " .. v(C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"), pm, px, py))
    if map then self:Print("  world (step): " .. v(R.Map:WorldPos(map, x, y))) end
    if pm then self:Print("  world (you): " .. v(R.Map:WorldPos(pm, px, py))) end
    if map then self:Print("  offset: " .. v(R.Map:Offset(map, x, y))) end
    self:Print("  facing: " .. v(GetPlayerFacing and GetPlayerFacing()) .. ", arrow option " .. v(db.arrow) .. ", tracker shown " .. v(tracker and tracker:IsShown()))
    self:Print("  APIs: GetWorldPosFromMapPos " .. v(C_Map.GetWorldPosFromMapPos ~= nil) .. ", SetUserWaypoint " .. v(C_Map.SetUserWaypoint ~= nil)
        .. ", UiMapPoint " .. v(UiMapPoint ~= nil) .. ", C_SuperTrack " .. v(C_SuperTrack ~= nil))
    if map and C_Map.CanSetUserWaypointOnMap then self:Print("  can waypoint here: " .. v(C_Map.CanSetUserWaypointOnMap(map))) end
    local wp = currentWaypoint and C_Map.GetUserWaypoint and currentWaypoint()
    self:Print("  waypoint: " .. (wp and v(wp.map, wp.x, wp.y) or "none") .. ", placed by Pathfinder " .. (placedWp and v(placedWp.map, placedWp.x, placedWp.y) or "none")
        .. ", super-tracked " .. v(C_SuperTrack and C_SuperTrack.IsSuperTrackingUserWaypoint and C_SuperTrack.IsSuperTrackingUserWaypoint())
        .. ", in-game navigation " .. v(GetCVar and GetCVar("showInGameNavigation")))
    local n = db.navLast
    if n then self:Print("  last waypoint try: " .. v(n.why, n.map, n.x, n.y, n.err)) end
    self:Print("  tracked quest: Pathfinder's " .. v(placedQuest) .. ", yours " .. v(userQuest()) .. ", the game's " .. v(C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()) .. ", tab " .. v(db.trackerTab))
    if M.Pin then self:Print("  RUIN pin: " .. M.Pin.State()) end
end

local function updateStepPin()
    local s, map, x, y = navStep()
    updateWaypoint(s and map, x, y, s)
    if map and db.arrow then
        R.Map:SetPin("Pathfinder", "step", { map = map, x = x, y = y, icon = "Interface\\AddOns\\RUIN_Core\\Media\\EmblemIcon", plain = true, shadow = true,
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

---------------------------------------------------------------------------
-- Quest status shared with RUIN: the quests in your log (and which are
-- ready to hand in), and which of your route's quests you've done. Sent when
-- it changes (at most every 20 seconds) and every 5 minutes; members use it
-- to see who has the same quest. Turn it off with /path questshare.
---------------------------------------------------------------------------
local lastQuestShare, lastQuestSig = -999, nil

local function routeQids(r)
    local out, seen = {}, {}
    for _, s in ipairs(r and r.steps or {}) do
        if s.qid and not seen[s.qid] then seen[s.qid] = true; out[#out + 1] = s.qid end
    end
    return out
end

local function questPayload()
    local log = {}
    for i, q in ipairs(QB.Log()) do
        if i > 25 then break end
        log[#log + 1] = q.id .. (q.ready and "+" or "")
    end
    local done = {}
    for _, qid in ipairs(routeQids(currentRoute())) do
        if #done >= 80 then break end
        if QB.Done(qid) then done[#done + 1] = tostring(qid) end
    end
    return { g = R:GetPlayerGUID(), l = table.concat(log, ","), d = table.concat(done, ","),
             qz = QB.Has() and 1 or nil, lv = UnitLevel and UnitLevel("player") or nil }
end

local function shareQuests(force)
    if not (db and db.shareQuests and shares("quests")) or not R:IsConnected() then return end
    local now = GetTime()
    if not force and now - lastQuestShare < QUEST_SHARE_MIN then return end
    local d = questPayload()
    local sig = d.l .. "|" .. d.d
    if not force and sig == lastQuestSig and now - lastQuestShare < QUEST_SHARE_EVERY then return end
    lastQuestShare, lastQuestSig = now, sig
    M:Send("QSTAT", d, "ORG", nil, R.PRIORITY.BULK)
end
M.ShareQuests = function(_, force) shareQuests(force) end

-- "123,456+" -> { [123] = "have", [456] = "ready" }
local function parseIds(text, as)
    local out, n = {}, 0
    for item in tostring(text or ""):gmatch("[^,]+") do
        local id, plus = item:match("^(%d+)(%+?)$")
        id = tonumber(id)
        if id then
            out[id] = (plus == "+") and "ready" or (as or "have")
            n = n + 1
            if n >= 120 then break end
        end
    end
    return out
end

-- A member's record (keyed by GUID) is theirs alone: the GUID must be the
-- sender's (for guildmates the roster says), and nobody replaces another's.
local function ownRecord(d, sender)
    if R.GUIDMatches and not R:GUIDMatches(sender, d.g) then return false end
    local p = peers[d.g]
    return not (p and p.name and R.SameName and not R:SameName(p.name, sender))
end

function M:OnQuests(d, sender)
    if type(d) ~= "table" or type(d.g) ~= "string" or d.g == R:GetPlayerGUID() then return end
    if not ownRecord(d, sender) then return end
    local p = peers[d.g] or { route = "", step = 0, t = 0 }
    p.name = sender
    p.quests = parseIds(d.l)
    p.done = parseIds(d.d, "done")
    p.fromData = d.qz == 1
    p.level = tonumber(d.lv)
    p.qt = GetTime()
    peers[d.g] = p
    refreshPage()
end

-- Who in RUIN has a quest, is ready to hand it in, or has done it (names).
local function whoHas(qid)
    local have, ready, done, now = {}, {}, {}, GetTime()
    qid = tonumber(qid)
    if not qid then return have, ready, done end
    for _, p in pairs(peers) do
        if p.qt and now - p.qt <= QUEST_TTL then
            local st = p.quests and p.quests[qid]
            local name = R.Util.ShortName(p.name or "?")
            if st then
                have[#have + 1] = name
                if st == "ready" then ready[#ready + 1] = name end
            elseif p.done and p.done[qid] then
                done[#done + 1] = name
            end
        end
    end
    table.sort(have); table.sort(ready); table.sort(done)
    return have, ready, done
end
M.WhoHas = function(_, qid) return whoHas(qid) end

-- Members who have any of the quests in your log.
local function commonQuests(p)
    if not p.quests then return 0 end
    local n = 0
    for _, q in ipairs(QB.Log()) do if p.quests[q.id] then n = n + 1 end end
    return n
end

local function nameList(list, max)
    max = max or 4
    local shown = {}
    for i = 1, math.min(max, #list) do shown[i] = list[i] end
    local text = table.concat(shown, ", ")
    if #list > max then text = text .. (" and %d more"):format(#list - max) end
    return text
end

-- Tooltip lines about a quest: the database's details, then RUIN members.
local function questTip(tip, qid)
    local info = QB.Quest(qid)
    if info then
        tip:AddLine(((QB.Source() or "RUIN Quest Data") .. ": level %s%s"):format(tostring(info.level or "?"), info.req and (", needs " .. info.req) or ""), 0.55, 0.72, 0.85)
        if info.starts[1] then tip:AddLine("Starts: " .. info.starts[1], 0.8, 0.8, 0.8) end
        if info.ends[1] then tip:AddLine("Ends: " .. info.ends[1], 0.8, 0.8, 0.8) end
        for i = 1, math.min(3, #info.objectives) do tip:AddLine("- " .. info.objectives[i], 0.8, 0.8, 0.8, true) end
    end
    local have, ready, done = whoHas(qid)
    if #have > 0 then tip:AddLine("In RUIN with this quest: " .. nameList(have), 0.4, 0.9, 0.4, true) end
    if #ready > 0 then tip:AddLine("Ready to hand in: " .. nameList(ready), 0.4, 0.9, 0.4, true) end
    if #done > 0 then tip:AddLine("Done it: " .. nameList(done), 0.7, 0.7, 0.7, true) end
end

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
    if not ownRecord(d, sender) then return end
    local p = peers[d.g] or {}
    p.name, p.guild, p.route, p.step, p.t = sender, d.gu, d.r, tonumber(d.s) or 0, GetTime()
    peers[d.g] = p
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
    nav.wp = (nav.wp or 0) + (elapsed or 0)
    if nav.acc < 0.05 then return end
    nav.acc = 0
    if nav.wp > 3 then
        nav.wp = 0
        -- a tracked quest the game can't place (no navigation after a few seconds) gets a waypoint instead
        if placedQuest and questAt and GetTime() - questAt > 3 and C_Navigation and C_Navigation.GetFrame and not C_Navigation.GetFrame() then
            questNoNav[placedQuest] = true
            placedQuest = nil
            updateStepPin()
        elseif not placedWp and not placedQuest and not combatPending and db.waypoint ~= false
                and not (db.trackerTab == "tracked" and userQuest()) then
            local _, map = navStep()
            if map then updateStepPin() end
        end
    end
    local arrow, dist = tracker.arrow, tracker.dist
    if db.trackerTab == "tracked" and userQuest() or not currentRoute() then
        -- the Tracked tab: how far the game's navigation says the quest is
        arrow:Hide()
        local q = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()
        local yd = q and q > 0 and C_Navigation and C_Navigation.GetFrame and C_Navigation.GetFrame() and C_Navigation.GetDistance and C_Navigation.GetDistance()
        dist:SetText(yd and ("%d yards"):format(yd) or "")
        return
    end
    local s, map, x, y, elsewhere = navStep()
    if not db.arrow or not s then arrow:Hide(); dist:SetText(""); return end
    if not map then
        arrow:Hide()
        dist:SetText(elsewhere and (C.dim .. elsewhere .. "|r") or "")
        return
    end
    local east, north, yards = R.Map:Offset(map, x, y)
    local facing = GetPlayerFacing and GetPlayerFacing()
    if not yards then
        arrow:Hide()
        local info = C_Map.GetMapInfo and C_Map.GetMapInfo(map)
        dist:SetText(info and info.name and (C.dim .. info.name .. "|r") or "")
        return
    end
    if not facing then arrow:Hide(); dist:SetText(("%d yards"):format(yards)); return end
    arrow:SetRotation(math.atan2(-east, north) - facing)
    if yards < 15 then arrow:SetVertexColor(0.3, 1, 0.3) else arrow:SetVertexColor(1, 0.82, 0.2) end
    arrow:Show()
    dist:SetText(yards < 15 and (C.good .. "here|r") or ("%d yards"):format(yards))
end

local TRACKER_W, TRACKER_H, TRACKER_MAX_W = 320, 66, 640
local SIDE = 22                 -- room for < and > on each side

-- Are you in a quest's objective area? Near any place its objectives are
-- found (the database's spawn points for its mobs, objects and drops), on your
-- map. Not for a quest that's ready to hand in: that's the turn-in NPC.
M.QB = QB   -- for tests
local AREA_YARDS = 60
local areaCache = { t = -1 }
local mapScale = {}
local function yardsPerUnit(map)
    local m = mapScale[map]
    if m == nil then
        local w = R.Map.Yards and R.Map:Yards(map, 0, 0, 1, 0)
        local h = R.Map.Yards and R.Map:Yards(map, 0, 0, 0, 1)
        m = (w and h and w > 0 and h > 0) and { w, h } or false
        mapScale[map] = m
    end
    return m or nil
end
function M.InQuestArea(qid)
    if not (qid and QB.Has and QB.Has()) then return false end
    local now = GetTime()
    if areaCache.q == qid and now - areaCache.t < 0.5 then return areaCache.v end
    local v = false
    local ready = C_QuestLog and C_QuestLog.IsComplete and C_QuestLog.IsComplete(qid)
    local pm, px, py = R.Map:PlayerPos()
    local scale = pm and yardsPerUnit(pm)
    if not ready and scale then
        local lim = AREA_YARDS * AREA_YARDS
        for _, sp in ipairs(QB.Spots(qid, "objective")) do
            if sp.map == pm then
                local dx, dy = (sp.x - px) * scale[1], (sp.y - py) * scale[2]
                if dx * dx + dy * dy <= lim then v = true; break end
            end
        end
    end
    areaCache.q, areaCache.t, areaCache.v = qid, now, v
    return v
end

-- A quest's objectives as lines with pips: filled for done, hollow for not.
function M.ObjectiveLines(qid, max)
    if not (qid and C_QuestLog and C_QuestLog.GetQuestObjectives) then return "" end
    local list = C_QuestLog.GetQuestObjectives(qid)
    local out = {}
    for _, o in ipairs(type(list) == "table" and list or {}) do
        if o.text and o.text ~= "" then
            -- "- 3/10 Turtle Meat", like the quest log; finished ones in green
            out[#out + 1] = o.finished and (C.good .. "- " .. o.text .. "|r") or (C.white .. "- " .. o.text .. "|r")
            if max and #out >= max then break end
        end
    end
    if #out == 0 and C_QuestLog.IsComplete and C_QuestLog.IsComplete(qid) then out[1] = C.good .. "- Ready to turn in|r" end
    return table.concat(out, "\n")
end

-- Quests in your log, in log order, for < and > on the Tracked tab.
local function logQuests()
    local out = {}
    if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) then return out end
    for i = 1, (C_QuestLog.GetNumQuestLogEntries() or 0) do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and not info.isHidden and info.questID then out[#out + 1] = info.questID end
    end
    return out
end

-- Which tab shows: the one picked, unless it has nothing (then the other).
local function trackerTab()
    local hasRoute, hasQuest = currentRoute() ~= nil, userQuest() ~= nil
    local want = db.trackerTab == "tracked" and "tracked" or "route"
    if want == "tracked" and not hasQuest and hasRoute then want = "route" end
    if want == "route" and not hasRoute and hasQuest then want = "tracked" end
    return want, hasRoute, hasQuest
end

local function selectTab(key)
    db.trackerTab = key
    updateStepPin()
    updateTracker()
    if M.RefreshPin then M.RefreshPin() end
end

-- Tracked tab: < and > move through your quest log.
local function stepTracked(dir)
    local list = logQuests()
    if #list == 0 then return end
    local cur, at = userQuest(), 0
    for i, q in ipairs(list) do if q == cur then at = i end end
    local nxt = at == 0 and list[dir > 0 and 1 or #list] or list[((at - 1 + dir) % #list) + 1]
    db.userQuest = nxt
    selectTab("tracked")
end

-- The little x: leaves the route, or stops tracking your quest.
local function closeTab()
    if trackerTab() == "tracked" then
        db.userQuest = nil
        superTrackQuest(0)
        selectTab("route")
    else
        M:ClearRoute()
    end
end

-- Double-click: Pathfinder on the Guide (Route) or on this quest (Tracked).
local function openFromTracker()
    M:OpenTab()
    if trackerTab() == "tracked" then
        ui.qSel = userQuest()
        if ui.tabs then ui.tabs:Select(2) end
    elseif ui.tabs then
        ui.tabs:Select(1)
    end
    refreshPage()
end
M.OpenFromTracker = openFromTracker

-- Keeps the side nearest the screen edge still while the width changes:
-- left third grows rightward, right third leftward, the middle both ways.
local function anchorTracker()
    if not (tracker.GetLeft and tracker:GetLeft()) then return end
    local ratio = (tracker:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
    local screenW = (UIParent:GetWidth() or 0) / ratio
    local left, right, top = tracker:GetLeft(), tracker:GetRight(), tracker:GetTop()
    if not (left and right and top and screenW > 0) then return end
    local center = (left + right) / 2
    local point, x
    if center < screenW / 3 then point, x = "TOPLEFT", left
    elseif center > screenW * 2 / 3 then point, x = "TOPRIGHT", right
    else point, x = "TOP", center end
    tracker:ClearAllPoints()
    tracker:SetPoint(point, UIParent, "BOTTOMLEFT", x, top)
    db.trackerPos = { point = point, rel = "BOTTOMLEFT", x = x, y = top }
end

-- Width to fit all the text in two lines (wider first); past the widest the
-- tracker grows taller instead, so nothing is ever cut off.
local function fitTracker()
    local lineH = 14
    -- two lines, or one per objective on the Tracked tab
    local maxLines = math.max(math.max(1, math.floor((TRACKER_H - 28 - 8) / lineH)), tracker.wantLines or 0)
    local pad = SIDE * 2 + 8 + 26      -- the sides, plus room for the arrow at the right
    local step = tracker.step
    if step.SetMaxLines then step:SetMaxLines(0) end   -- measure the whole text
    local function height(w)
        step:SetWidth(w - pad)
        return step.GetStringHeight and step:GetStringHeight() or lineH
    end
    local width = TRACKER_W
    while width < TRACKER_MAX_W and height(width) > maxLines * lineH + 2 do width = width + 20 end
    width = math.min(width, TRACKER_MAX_W)
    local titleW = (tracker.title.GetStringWidth and tracker.title:GetStringWidth() or 0)
                 + (tracker.dist.GetStringWidth and tracker.dist:GetStringWidth() or 0) + pad + 40
    width = math.min(TRACKER_MAX_W, math.max(width, titleW))
    local newH = math.max(TRACKER_H, math.ceil(26 + height(width) + 10))
    if math.abs((tracker:GetWidth() or 0) - width) > 0.5 or math.abs((tracker:GetHeight() or 0) - newH) > 0.5 then
        anchorTracker()
        tracker:SetSize(width, newH)
    end
end

-- Tabs above the tracker, like the chat window's: they fade in while the
-- mouse is over the tracker and out again when it leaves. A tab with
-- nothing to show is greyed out and can't be picked.
local TAB_FADE = 0.15
local function over(f) return f and f.IsMouseOver and f:IsMouseOver() end
local function buildTrackerTabs()
    tracker.tabs = {}
    local function tab(key, label)
        local t = CreateFrame("Button", nil, tracker)
        t.key = key
        t:SetHeight(20)
        t:SetFrameLevel((tracker:GetFrameLevel() or 1) + 5)
        t.bg = t:CreateTexture(nil, "BACKGROUND")
        t.bg:SetAllPoints()
        t.top = t:CreateTexture(nil, "BORDER")
        t.top:SetPoint("TOPLEFT"); t.top:SetPoint("TOPRIGHT"); t.top:SetHeight(2)
        t.top:SetColorTexture(0.90, 0.72, 0.38, 1)
        t.text = W.Label(t, label, "GameFontNormalSmall")
        t.text:SetPoint("CENTER", 0, 0)
        t:SetWidth(((t.text.GetStringWidth and t.text:GetStringWidth()) or 40) + 24)
        t:SetScript("OnClick", function(self) if self.ok then selectTab(self.key) end end)
        tracker.tabs[#tracker.tabs + 1] = t
        return t
    end
    local a = tab("route", "Route")
    a:SetPoint("BOTTOMLEFT", tracker, "TOPLEFT", 8, -1)
    local b = tab("tracked", "Tracked")
    b:SetPoint("BOTTOMLEFT", a, "BOTTOMRIGHT", 2, 0)
    tracker.tabAlpha = 0
    for _, t in ipairs(tracker.tabs) do t:SetAlpha(0) end
    tracker.tabFader = CreateFrame("Frame", nil, tracker)
    tracker.tabFader:SetScript("OnUpdate", function(_, elapsed)
        local want = (over(tracker) or over(tracker.tabs[1]) or over(tracker.tabs[2])) and 1 or 0
        local a0 = tracker.tabAlpha or 0
        if a0 == want then return end
        local step = (elapsed or 0) / TAB_FADE
        a0 = want > a0 and math.min(1, a0 + step) or math.max(0, a0 - step)
        tracker.tabAlpha = a0
        for _, t in ipairs(tracker.tabs) do t:SetAlpha(a0) end
    end)
end

local function paintTrackerTabs(cur, hasRoute, hasQuest)
    for _, t in ipairs(tracker.tabs) do
        local on = t.key == cur
        t.ok = (t.key == "route" and hasRoute) or (t.key == "tracked" and hasQuest)
        t.bg:SetColorTexture(on and 0.07 or 0.035, on and 0.085 or 0.045, on and 0.13 or 0.075, on and 0.94 or 0.80)
        t.top:SetShown(on)
        if not t.ok then t.text:SetTextColor(0.40, 0.40, 0.42)
        elseif on then t.text:SetTextColor(1, 0.86, 0.55)
        else t.text:SetTextColor(0.70, 0.73, 0.80) end
        if t.text.SetDesaturated then t.text:SetDesaturated(not t.ok) end
        t:SetEnabled(t.ok and true or false)
    end
end

-- A small round button for < and >, centered on the tracker's sides: a
-- dark disc in a thin gold ring with the arrow in the middle.
local DISC = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local function sideButton(label, onClick)
    local b = CreateFrame("Button", nil, tracker)
    b:SetSize(18, 18)
    b.ring = b:CreateTexture(nil, "BACKGROUND")
    b.ring:SetTexture(DISC)
    b.ring:SetAllPoints()
    b.ring:SetVertexColor(0.90, 0.72, 0.38, 0.75)
    b.disc = b:CreateTexture(nil, "BORDER")
    b.disc:SetTexture(DISC)
    b.disc:SetPoint("TOPLEFT", 1, -1); b.disc:SetPoint("BOTTOMRIGHT", -1, 1)
    b.disc:SetVertexColor(0.05, 0.065, 0.10, 1)
    b.text = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    b.text:SetText(label)
    b.text:SetPoint("CENTER", label == "<" and -0.5 or 0.5, 1)
    b.text:SetTextColor(0.90, 0.72, 0.38)
    b:SetScript("OnClick", function() onClick() end)
    b:SetScript("OnEnter", function(self)
        self.disc:SetVertexColor(0.11, 0.13, 0.19, 1)
        self.text:SetTextColor(1, 0.88, 0.55)
        if self.tip and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(self.tip); GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        self.disc:SetVertexColor(0.05, 0.065, 0.10, 1)
        self.text:SetTextColor(0.90, 0.72, 0.38)
        if GameTooltip then GameTooltip:Hide() end
    end)
    return b
end

updateTracker = function()
    if not db then return end
    local s, r = currentStep()
    local cur, hasRoute, hasQuest = trackerTab()
    if not db.tracker or not (hasRoute or hasQuest) then
        if tracker then tracker:Hide() end
        return
    end
    if not tracker then
        tracker = W.HudFrame("RUIN_PathfinderTracker", "Pathfinder", db, "trackerPos", { "RIGHT", UIParent, "RIGHT", -40, 140 })
        tracker:SetSize(TRACKER_W, TRACKER_H)
        tracker.title = W.Label(tracker, "", "GameFontNormalSmall")
        tracker.title:SetPoint("TOPLEFT", SIDE + 4, -9)
        tracker.title:SetWordWrap(false)
        tracker.step = W.Label(tracker, "")
        tracker.step:SetPoint("TOPLEFT", SIDE + 4, -26)
        tracker.step:SetJustifyV("TOP")
        tracker.step:SetWidth(TRACKER_W - SIDE * 2 - 34)
        if tracker.step.SetSpacing then tracker.step:SetSpacing(2) end
        -- < and > centered on the sides
        tracker.prev = sideButton("<", function()
            if trackerTab() == "tracked" then stepTracked(-1) else M:Advance(-1) end
        end)
        tracker.prev:SetPoint("LEFT", 5, 0)
        tracker.next = sideButton(">", function()
            if trackerTab() == "tracked" then stepTracked(1) else M:Advance(1) end
        end)
        tracker.next:SetPoint("RIGHT", -5, 0)
        -- a little x in the top-right corner
        tracker.clear = CreateFrame("Button", nil, tracker)
        tracker.clear:SetSize(14, 14)
        tracker.clear:SetPoint("TOPRIGHT", -6, -6)
        tracker.clear.icon = tracker.clear:CreateTexture(nil, "ARTWORK")
        tracker.clear.icon:SetTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
        tracker.clear.icon:SetAllPoints()
        tracker.clear.icon:SetAlpha(0.7)
        tracker.clear:SetScript("OnClick", function() closeTab() end)
        tracker.clear:SetScript("OnEnter", function(self)
            self.icon:SetAlpha(1)
            if GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(trackerTab() == "tracked" and "Stop tracking this quest" or "Leave this route")
                GameTooltip:Show()
            end
        end)
        tracker.clear:SetScript("OnLeave", function(self) self.icon:SetAlpha(0.7); if GameTooltip then GameTooltip:Hide() end end)
        -- the zone (or distance) at the top right, beside the x
        tracker.dist = W.Label(tracker, "", "GameFontHighlightSmall")
        tracker.dist:SetPoint("TOPRIGHT", -24, -9)
        tracker.dist:SetJustifyH("RIGHT")
        tracker.dist:SetWordWrap(false)
        tracker.title:SetPoint("RIGHT", tracker.dist, "LEFT", -8, 0)
        -- Waypoint arrow: points where the step happens and turns as you turn.
        tracker.arrow = tracker:CreateTexture(nil, "ARTWORK")
        -- the game's navigation arrow when the client has it, else the minimap arrow
        if not (tracker.arrow.SetAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("Navigation-Tracked-Arrow")
                and tracker.arrow:SetAtlas("Navigation-Tracked-Arrow") ~= false) then
            tracker.arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
        end
        tracker.arrow:SetSize(22, 22)
        tracker.arrow:SetPoint("RIGHT", tracker.next, "LEFT", -4, -6)
        tracker.arrow:Hide()
        tracker.nav = CreateFrame("Frame", nil, tracker)
        tracker.nav:SetScript("OnUpdate", arrowTick)
        -- double-click opens Pathfinder on the right page (a drag doesn't count)
        tracker:HookScript("OnMouseUp", function(self, button)
            if button ~= "LeftButton" then return end
            if self.justMoved then anchorTracker(); return end
            local now = GetTime()
            if self.lastClick and now - self.lastClick < 0.4 then
                self.lastClick = nil
                openFromTracker()
            else
                self.lastClick = now
            end
        end)
        buildTrackerTabs()
        tracker.prev.tip, tracker.next.tip = "Previous", "Next"
    end
    paintTrackerTabs(cur, hasRoute, hasQuest)
    if cur == "tracked" then
        local tq = userQuest()
        local title = tq and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(tq)
        tracker.title:SetText("Tracked" .. (title and ("  ·  " .. title) or ""))
        local body = tq and M.ObjectiveLines(tq) or ""
        -- each objective on its own line; the tracker grows taller to fit them
        local _, breaks = body:gsub("\n", "")
        tracker.wantLines = breaks + 1
        if body == "" then body = C.dim .. "No objectives to show.|r" end
        tracker.step:SetText(body)
        tracker.prev.tip, tracker.next.tip = "Track the previous quest in your log.", "Track the next quest in your log."
    else
        local n = #sameStepPeers()
        local follow = db.follow and peers[db.follow]
        local extra = (follow and ("  " .. C.gold .. "· following " .. R.Util.ShortName(follow.name) .. "|r") or "")
            .. (n > 0 and ("  " .. C.good .. "· " .. n .. " RUIN here|r") or "")
        tracker.title:SetText(("Pathfinder  ·  %s  %d/%d"):format(r.title, math.min(db.step, #r.steps), #r.steps) .. extra)
        tracker.step:SetText(s and stepText(s) or (C.good .. "Route complete!|r"))
        tracker.wantLines = nil
        tracker.prev.tip, tracker.next.tip = "Previous step.", "Next step."
    end
    tracker:Show()
    fitTracker()
end

M.UpdateTracker = function() updateTracker() end   -- for tests

-- The tracker follows the game: you pick a quest in the objective tracker
-- (it becomes your tracked quest and the Tracked tab opens), objectives
-- progress, quests come and go.
do
    local ev = CreateFrame("Frame")
    local pending
    ev:SetScript("OnEvent", function(_, event)
        if not db then return end
        if event == "PLAYER_REGEN_ENABLED" then
            if combatPending then updateStepPin() end
            return
        end
        if event == "SUPER_TRACKING_CHANGED" and not M.SelfChanged() then
            local q = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()
            if q and q > 0 and q ~= settingQuest and q ~= placedQuest and q ~= db.userQuest then
                -- you picked a quest: it's yours, and Tracked shows it
                db.userQuest = q
                db.trackerTab = "tracked"
                updateStepPin()
            elseif (not q or q == 0) and db.userQuest and settingQuest == nil then
                -- you stopped tracking it in the game: so does Pathfinder (never tracked again behind your back)
                db.userQuest = nil
            end
        end
        if pending then return end
        pending = true
        C_Timer.After(0.2, function() pending = nil; updateTracker() end)
    end)
    for _, e in ipairs({ "SUPER_TRACKING_CHANGED", "QUEST_LOG_UPDATE", "QUEST_WATCH_UPDATE", "PLAYER_REGEN_ENABLED" }) do pcall(ev.RegisterEvent, ev, e) end
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
    local s, map, x, y = navStep()
    if not (s and db.waypoint ~= false and db.announce ~= false) then return end
    if not map then return end
    local _, _, yards = R.Map:Offset(map, x, y)
    M:Print(("Waypoint set: %s%s"):format(s.quest or (s.text ~= "" and s.text) or ACT_LABEL[s.act] or "next step",
        yards and (" (%d yards)"):format(yards) or ""))
end

-- A "complete" step for several quests (they share targets) is done when
-- every one of them is ready to hand in or handed in.
local function allReady(s)
    for _, q in ipairs(s.qids or { s.qid }) do
        if not QB.Done(q) and not select(2, QB.InLog(q)) then return false end
    end
    return true
end

-- A step for a quest you've already done (or already have) needs nothing
-- from you. Quests are matched by ID, so steps without one never skip.
local function stepDone(s)
    if not (s and s.qid) then return false end
    if s.act ~= "accept" and s.act ~= "complete" and s.act ~= "turnin" then return false end
    if s.act == "complete" and s.qids then return allReady(s) end
    if QB.Done(s.qid) then return true end
    local inLog, ready = QB.InLog(s.qid)
    if s.act == "accept" then return inLog end
    if s.act == "complete" then return ready end
    return false
end
M.StepDone = function(_, s) return stepDone(s) end

local holdUntil       -- after you step back by hand, nothing skips until you pass that step again

function M:SkipDone()
    if not (db and db.skipDone) or db.follow then return 0 end
    local r = currentRoute()
    if not r then return 0 end
    local n = 0
    while db.step <= #r.steps and not (holdUntil and db.step < holdUntil) and stepDone(r.steps[db.step]) and n < MAX_STEPS do
        db.step, n = db.step + 1, n + 1
    end
    if holdUntil and db.step >= holdUntil then holdUntil = nil end
    if n > 0 then
        share()
        updateTracker()
        updateStepPin()
        refreshPage()
        flashTracker()
    end
    return n
end

function M:Advance(delta)
    local r = currentRoute()
    if not r then return end
    local before = db.step
    db.step = math.max(1, math.min(#r.steps + 1, db.step + delta))
    if delta < 0 then holdUntil = math.max(holdUntil or 0, before) end
    if delta > 0 then
        if holdUntil and db.step >= holdUntil then holdUntil = nil end
        while db.step <= #r.steps and not holdUntil and db.skipDone and not db.follow and stepDone(r.steps[db.step]) do
            db.step = db.step + 1
        end
    end
    share()
    updateTracker()
    updateStepPin()
    refreshPage()
    if db.step ~= before then flashTracker(); announceWaypoint() end
end

function M:StartRoute(id)
    if not routeById(id) then return end
    db.route, db.step = id, 1
    holdUntil = nil
    if db.skipDone then
        local r = routeById(id)
        while db.step <= #r.steps and stepDone(r.steps[db.step]) do db.step = db.step + 1 end
    end
    share()
    shareQuests(true)
    updateTracker()
    updateStepPin()
    refreshPage()
    announceWaypoint()
end

-- Leaves the current route without starting another (and stops following).
function M:ClearRoute()
    if not db.route then return end
    db.route, db.step, db.follow = nil, 1, nil
    holdUntil = nil
    share()
    updateTracker()
    updateStepPin()
    refreshPage()
    self:Print("Route cleared.")
end

-- The step's quest: by ID when both sides have one, else by title.
local function sameQuest(step, title, qid)
    if not step then return false end
    qid = tonumber(qid)
    if step.qid and qid then return step.qid == qid end
    return step.quest and type(title) == "string" and step.quest:lower() == title:lower()
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

local sharedOn          -- the quest a shared "do" step was pointing at
local function checkComplete()
    local s = currentStep()
    if s and s.act == "complete" and ((s.qids and allReady(s)) or (not s.qids and ((s.qid and select(2, QB.InLog(s.qid))) or (s.quest and questComplete(s.quest))))) then
        M:Advance(1)
    elseif s and s.qids then
        -- one quest of a shared step is ready: point at the next one
        local q = workQid(s)
        if sharedOn and q ~= sharedOn then updateTracker(); updateStepPin() end
        sharedOn = q
    end
    M:SkipDone()
    shareQuests()
    if adb.rec.on then
        local now = completeQuests()
        for title in pairs(now) do
            if not wasComplete[title] then M:RecordStep("complete", title, "") end
        end
        wasComplete = now
    end
end

---------------------------------------------------------------------------
-- The atlas: where quests are really picked up, done and handed in on WoW
-- Forever, learned as RUIN members play and shared with RUIN. It's RUIN's
-- own quest map: it fills in quests the database doesn't know, corrects places
-- WoW Forever moved, and comes first when routes are planned.
---------------------------------------------------------------------------
local ATLAS_NEAR = 60           -- yards: a sighting this close to the known spot refines it
local ATLAS_OBJ_MAX = 16        -- places kept per quest's objectives
local ATLAS_SHARE_EVERY = 300   -- seconds between sharing new sightings
local ATLAS_SHARE_MAX = 40      -- sightings per message
local atlasPending, atlasLastShare = {}, 0

local function atlas()
    adb.atlas = adb.atlas or { s = {}, f = {}, o = {} }
    return adb.atlas
end

local function yd(map, x1, y1, x2, y2)
    return (R.Map.Yards and R.Map:Yards(map, x1, y1, x2, y2)) or (math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2) * 4000)
end

-- one sighting: kind "s" (picked up), "f" (handed in) or "o" (objective progress)
local function atlasNote(kind, qid, map, x, y, mine)
    qid, map, x, y = tonumber(qid), tonumber(map), tonumber(x), tonumber(y)
    if not (qid and qid > 0 and map and x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1) then return false end
    local A = atlas()
    if kind == "o" then
        local list = A.o[qid] or {}
        A.o[qid] = list
        for _, p in ipairs(list) do
            if p[1] == map and yd(map, p[2], p[3], x, y) < 25 then p[4] = math.min(99, (p[4] or 1) + 1); return false end
        end
        if #list >= ATLAS_OBJ_MAX then
            -- make room: drop the least-seen place
            local low = 1
            for i, p in ipairs(list) do if (p[4] or 1) < (list[low][4] or 1) then low = i end end
            table.remove(list, low)
        end
        list[#list + 1] = { map, x, y, 1 }
    else
        local t = A[kind][qid]
        if t and t[1] == map and yd(map, t[2], t[3], x, y) < ATLAS_NEAR then
            local n = math.min(50, t[4] or 1)
            t[2], t[3], t[4] = (t[2] * n + x) / (n + 1), (t[3] * n + y) / (n + 1), n + 1
        elseif not t then
            A[kind][qid] = { map, x, y, 1 }               -- the first sighting
        else
            -- somewhere else: a stray, or the place moved. It takes over once
            -- it's been seen as often as the old place.
            local alt = t[5]
            if alt and alt[1] == map and yd(map, alt[2], alt[3], x, y) < ATLAS_NEAR then
                local n = alt[4] or 1
                alt[2], alt[3], alt[4] = (alt[2] * n + x) / (n + 1), (alt[3] * n + y) / (n + 1), n + 1
            else
                alt = { map, x, y, 1 }
                t[5] = alt
            end
            if alt[4] < (t[4] or 1) then return false end
            A[kind][qid] = { alt[1], alt[2], alt[3], alt[4] }
        end
    end
    if QB.ForgetSpots then QB.ForgetSpots(qid) end
    if mine and adb.atlasShare ~= false and shares("atlas") then
        atlasPending[#atlasPending + 1] = { kind, qid, map, math.floor(x * 10000 + 0.5), math.floor(y * 10000 + 0.5) }
        while #atlasPending > ATLAS_SHARE_MAX * 4 do table.remove(atlasPending, 1) end
    end
    return true
end
M.AtlasNote = atlasNote

-- for QuestDB.lua: what the atlas knows, as spots
ns.AtlasSpots = function(qid, which)
    if not adb or not adb.atlas then return nil end
    local A = adb.atlas
    if which == "objective" then
        local list = A.o[qid]
        if not list or #list == 0 then return nil end
        local out = {}
        for _, p in ipairs(list) do out[#out + 1] = { map = p[1], x = p[2], y = p[3], seen = p[4] } end
        return out
    end
    local t = A[which == "start" and "s" or "f"][qid]
    if t then return { { map = t[1], x = t[2], y = t[3], seen = t[4] } } end
end

local function atlasHere(kind, qid)
    local map, x, y = R.Map:PlayerPos()
    if map then atlasNote(kind, qid, map, x, y, true) end
end

-- objective progress: a quest's objectives went up since we last looked
local objSeen, objLook = {}, 0
local function atlasObjectives()
    local now = GetTime()
    if now - objLook < 1 then return end
    objLook = now
    if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo and C_QuestLog.GetQuestObjectives) then return end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            local total = 0
            for _, o in ipairs(C_QuestLog.GetQuestObjectives(info.questID) or {}) do total = total + (tonumber(o.numFulfilled) or 0) end
            local before = objSeen[info.questID]
            if before and total > before then atlasHere("o", info.questID) end
            objSeen[info.questID] = total
        end
    end
end

local function atlasShare()
    if #atlasPending == 0 or adb.atlasShare == false or not shares("atlas") or GetTime() - atlasLastShare < ATLAS_SHARE_EVERY then return end
    atlasLastShare = GetTime()
    local flat = {}
    for i = 1, math.min(#atlasPending, ATLAS_SHARE_MAX) do
        local e = table.remove(atlasPending, 1)
        for _, v in ipairs(e) do flat[#flat + 1] = v end
    end
    M:Send("ATLAS", { l = flat }, "ORG", nil, R.PRIORITY.BULK)
end

function M:OnAtlas(d, sender)
    if type(d) ~= "table" or type(d.l) ~= "table" or adb.atlasShare == false then return end
    local l = d.l
    -- one vote per player and place: sending the same sighting again (or a
    -- made-up one many times) can't outweigh what others saw
    adb.atlasVoters = type(adb.atlasVoters) == "table" and adb.atlasVoters or {}
    local who = (R.NormalizeName and R:NormalizeName(sender)) or tostring(sender):lower()
    for i = 1, math.min(#l, ATLAS_SHARE_MAX * 5) - 4, 5 do
        local kind = l[i]
        if kind == "s" or kind == "f" or kind == "o" then
            local key = kind .. tostring(tonumber(l[i + 1]) or "?")
            if kind == "o" then key = key .. ":" .. tostring(tonumber(l[i + 2]) or "?") .. ":" .. math.floor((tonumber(l[i + 3]) or 0) / 500) .. ":" .. math.floor((tonumber(l[i + 4]) or 0) / 500) end
            local voters = adb.atlasVoters[key] or {}
            local n = 0
            for _ in pairs(voters) do n = n + 1 end
            if not voters[who] and n < 16 then
                voters[who] = true
                adb.atlasVoters[key] = voters
                atlasNote(kind, l[i + 1], l[i + 2], (tonumber(l[i + 3]) or -1) / 10000, (tonumber(l[i + 4]) or -1) / 10000, false)
            end
        end
    end
end

function M.AtlasCounts()
    local A = adb and adb.atlas or { s = {}, f = {}, o = {} }
    local n = { s = 0, f = 0, o = 0 }
    for k in pairs(n) do for _ in pairs(A[k]) do n[k] = n[k] + 1 end end
    return n
end

local function onAccepted(_, a1, a2)
    dqCache = {}
    -- Retail-style clients pass questID; Classic-style pass (logIndex, questID).
    local title = questTitle(a2 or a1, a2 and a1 or nil)
    local s = currentStep()
    local qid = tonumber(a2 or a1)
    -- the atlas: where it was picked up (not for quests started from an item)
    -- (only from an NPC or object: a quest a party member shared isn't where you stand)
    local fromNpc = UnitExists and UnitExists("npc") and not (UnitIsPlayer and UnitIsPlayer("npc"))
    if qid and fromNpc and not (QB.StartItem and QB.StartItem(qid)) then atlasHere("s", qid) end
    if s and s.act == "accept" and sameQuest(s, title, qid) then M:Advance(1) end
    if title then M:RecordStep("accept", title, "", qid and { qid = qid } or nil) end
    C_Timer.After(0.5, checkComplete)
end

local function onTurnedIn(_, questID)
    dqCache = {}
    if tonumber(questID) then atlasHere("f", tonumber(questID)); objSeen[tonumber(questID)] = nil end
    C_Timer.After(1, function() shareQuests() end)
    local title = questTitle(questID)
    local s = currentStep()
    if s and s.act == "turnin" and sameQuest(s, title, questID) then M:Advance(1) end
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
-- which is how RUIN learns where gear really comes from.
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
            M:RecordStep("note", nil, "Got " .. (name or (R.Items and R.Items.Info(id)) or "an item"), { item = id })
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

---------------------------------------------------------------------------
-- Officer routes: an officer publishes a route (theirs, or one a member
-- shared, which makes it officer-approved) and it lands in every RUIN
-- member's route list with the officer badge. Only officers' messages are
-- accepted, and officers re-send them to members who log in later.
---------------------------------------------------------------------------
-- Built-in routes travel as a reference (everyone has their steps already).
local function officialPayload(r)
    local d = { id = r.id, title = r.title, faction = r.faction, author = r.author,
                ob = r.official.by, oa = r.official.approved and 1 or nil, ot = r.official.t }
    if r.builtin then d.bi = r.builtin else d.steps = exportable(r).steps end
    return d
end

-- Was this route made by an officer (or higher)? Built-in routes weren't.
local function officerMade(r)
    if not r or isBuiltInRoute(r.id) or type(r.author) ~= "string" or r.author == "" then return false end
    return R.IsOfficerName and R:IsOfficerName(r.author) or false
end
M.OfficerMade = officerMade

-- from: the member whose shared route an officer approves from the inbox
function M:PublishRoute(id, from)
    local r = routeById(id)
    if not r then return end
    if not R:IsOfficer() then return self:Print("Only officers publish routes to RUIN.") end
    if not from and not officerMade(r) then return self:Print("Only routes made by officers can be published.") end
    local me = UnitName("player")
    local oid = r.official and r.id or ("o" .. tostring(r.id):gsub("^o", ""))
    local copy = cleanRoute(exportable(r))
    if not copy then return end
    copy.id = oid
    copy.author = r.author or from or me
    if isBuiltInRoute(r.id) then copy.builtin = r.id end
    local author = R.Util.ShortName(copy.author or "")
    -- "approved" when an officer passes on a member's route; otherwise the officer made or chose it
    local othersRoute = from ~= nil or (adb.custom[r.id] ~= nil and author ~= "" and author ~= "?" and author ~= R.Util.ShortName(me))
    copy.official = { by = me, t = GetServerTime(), approved = othersRoute }
    adb.official[oid] = copy
    if R:IsConnected() then self:Send("OFFICIAL", officialPayload(copy), "ORG", nil, R.PRIORITY.BULK) end
    self:Print(("%s is now a RUIN route for everyone%s."):format(copy.title, R:IsConnected() and "" or " (sent when you connect)"))
    refreshPage()
    return copy
end

function M:WithdrawRoute(id)
    local r = adb.official[id]
    if not r then return end
    if not R:IsOfficer() then return self:Print("Only officers withdraw RUIN routes.") end
    adb.official[id] = nil
    adb.withdrawn = adb.withdrawn or {}
    adb.withdrawn[id] = GetServerTime()
    if R:IsConnected() then self:Send("OFFDEL", { id = id, t = GetServerTime() }, "ORG", nil, R.PRIORITY.BULK) end
    if db.route == id then db.route = nil; updateTracker() end
    refreshPage()
end

function M:OnOfficial(d, sender)
    if type(d) ~= "table" or type(d.id) ~= "string" or not R:IsOfficerName(sender) then return end
    local base = type(d.bi) == "string" and isBuiltInRoute(d.bi) and routeById(d.bi) or nil
    local r = cleanRoute(base and { title = d.title or base.title, faction = base.faction, author = base.author, steps = base.steps } or d)
    if not r then return end
    if base then r.builtin = d.bi end
    local t = tonumber(d.ot) or GetServerTime()
    if R.SaneTime and not R:SaneTime(t) then return end            -- never in the future
    local cur = adb.official[d.id]
    if cur and (cur.official.t or 0) >= t then return end
    if adb.withdrawn and (adb.withdrawn[d.id] or 0) >= t then return end
    r.id = d.id
    r.author = type(d.author) == "string" and d.author:sub(1, 40) or nil
    r.official = { by = type(d.ob) == "string" and d.ob or sender, t = t, approved = d.oa == 1 }
    adb.official[d.id] = r
    if not cur then
        self:Toast(("New RUIN route from %s: %s (%d steps), on the Pathfinder Routes page."):format(
            W.ClassName(r.official.by), r.title, #r.steps))
    end
    refreshPage()
end

function M:OnOfficialDelete(d, sender)
    if type(d) ~= "table" or type(d.id) ~= "string" or not R:IsOfficerName(sender) then return end
    adb.withdrawn = adb.withdrawn or {}
    adb.withdrawn[d.id] = (R.SaneTime and R:SaneTime(d.t)) or GetServerTime()
    if adb.official[d.id] then
        adb.official[d.id] = nil
        if db.route == d.id then db.route = nil; updateTracker() end
        refreshPage()
    end
end

-- Someone logged in: officers re-send the RUIN routes they hold, one at a
-- time so long routes don't crowd each other out.
function M:OnAsk()
    if not R:IsOfficer() then return end
    local list = sortedOfficial()
    local delay = 3 + math.random() * 10
    for _, r in ipairs(list) do
        C_Timer.After(delay, function() self:Send("OFFICIAL", officialPayload(r), "ORG", nil, R.PRIORITY.BULK) end)
        delay = delay + (r.builtin and 2 or math.min(60, 5 + #r.steps / 2))
    end
end

local function officialTip(r)
    if not r.official then return nil end
    return (r.official.approved and ("Approved by " .. R.Util.ShortName(r.official.by) .. " (made by " .. R.Util.ShortName(r.author or "?") .. ")")
        or ("Made by officer " .. R.Util.ShortName(r.official.by)))
end
M.OfficialTip = officialTip

function M:DeleteRoute(id)
    if not adb.custom[id] then return end
    adb.custom[id] = nil
    if db.route == id then db.route = nil; updateTracker() end
    refreshPage()
end

---------------------------------------------------------------------------
-- Dungeon quests, for this page and for RUIN Codex's Journal
---------------------------------------------------------------------------
-- A dungeon's quests for your character (see QB.DungeonQuests), or nil and why.
function M:DungeonQuests(name)
    local entry = dqEntry(name)
    if not entry then return nil, "Pathfinder has no quest list for " .. tostring(name) .. "." end
    local hit = dqCache[entry.name]
    if hit and GetTime() - hit.t < 10 then return hit.list, nil, entry end
    local list, why = QB.DungeonQuests(entry)
    if list then dqCache[entry.name] = { t = GetTime(), list = list } end
    return list, why, entry
end
function M:ForgetDungeonQuests() dqCache = {}; for k in pairs(zqRoutes) do zqRoutes[k] = nil end end

-- The route through a dungeon's quests, built from the quest database (nil and why if it can't be).
function M:DungeonRoute(name)
    local entry = dqEntry(name)
    if not entry then return nil, "Pathfinder has no quest list for " .. tostring(name) .. "." end
    if not QB.Has() then return nil, "Enable RUIN Quest Data for dungeon quest routes." end
    local r = dungeonRoute(entry)
    if not r then return nil, "The quest database lists no quests in " .. entry.name .. " for your character." end
    return r
end

-- What the database knows about one quest (see QB.Quest), and whether you've done it.
function M:QuestInfo(qid) return QB.Quest(qid) end
function M:QuestDone(qid) return QB.Done(qid) end

-- Start a dungeon's quest route and open it on the Route page.
function M:OpenDungeonRoute(name)
    local r, why = self:DungeonRoute(name)
    if not r then self:Print(why); return nil end
    self:StartRoute(r.id)
    self:OpenTab()
    if ui.tabs then ui.tabs:Select(1) end
    self:Print(("Started %s: %d steps, %d quests."):format(r.title, #r.steps, r.quests or 0))
    return r
end

-- Mark where a quest starts (or is handed in, once it's in your log) on the map, and open it.
function M:ShowQuestOnMap(qid, which)
    qid = tonumber(qid)
    if not qid then return false end
    local inLog, ready = QB.InLog(qid)
    which = which or (ready and "finish") or (inLog and "objective") or "start"
    local map, x, y = R.Map:PlayerPos()
    local spot = QB.Spot(qid, which, map, x, y) or (which ~= "start" and QB.Spot(qid, "finish", map, x, y))
    if not spot then
        self:Print("The quest database doesn't have a place for this quest.")
        return false
    end
    local info = QB.Quest(qid)
    local label = which == "start" and "Pick up" or which == "finish" and "Hand in" or "Do"
    R.Map:SetPin("Pathfinder", "quest", { map = spot.map, x = spot.x, y = spot.y, icon = "Interface\\AddOns\\RUIN_Core\\Media\\EmblemIcon", plain = true, shadow = true,
        color = W.MARKERS[which == "finish" and "turnin" or "quest"], title = "Pathfinder: " .. ((info and info.name) or "quest"),
        text = label .. ": " .. (spot.name or "") })
    local open = rawget(_G, "OpenWorldMap")
    local wmf = rawget(_G, "WorldMapFrame")
    if open then pcall(open, spot.map)
    elseif wmf and ShowUIPanel then pcall(ShowUIPanel, wmf); if wmf.SetMapID then pcall(wmf.SetMapID, wmf, spot.map) end end
    self:Print(("Marked on your map: %s %s (%s)."):format(label:lower(), (info and info.name) or "the quest", spot.name or "?"))
    return true
end

-- Every dungeon's quest route that has quests for you (raids are left to
-- RUIN Codex's button: their reputation turn-ins make very long routes).
local function dungeonRoutes()
    local out = {}
    if not QB.Has() then return out end
    for _, e in ipairs(ns.DungeonQuestIndex or {}) do
        if not e.raid then
            local r = dungeonRoute(e)
            if r then out[#out + 1] = r end
        end
    end
    return out
end
M.DungeonRoutes = function() return dungeonRoutes() end
M.ZoneRoutes = function() return zoneRoutes() end
function M:GetRoute(id) return routeById(id) end

-- The one list of routes both the Guide's picker and the Routes page use:
-- { { header = text or nil, routes = { ... } }, ... }
-- A route's levels: from its levels field ("13-18"), its title ("Elwynn
-- 1-10"), or the levels of its quests; nil when nothing says.
local OUTLEVELED = 3        -- a route whose top level is this far below you is out-leveled
local function routeLevels(r)
    local lo, hi = tostring(r.levels or ""):match("(%d+)%s*%-%s*(%d+)")
    if not lo then lo, hi = tostring(r.title or ""):match("(%d+)%s*%-%s*(%d+)") end
    if lo then return tonumber(lo), tonumber(hi) end
    local a, b
    for _, st in ipairs(r.steps or {}) do
        local info = st.qid and QB.Has() and QB.Quest(st.qid)
        local l = info and tonumber(info.level)
        if l and l > 0 then a = a and math.min(a, l) or l; b = b and math.max(b, l) or l end
    end
    return a, b
end
M.RouteLevels = function(_, r) return routeLevels(r) end

-- every quest on the route done?
local function routeDone(r)
    local any = false
    for _, qid in ipairs(r.qids or {}) do any = true; if not QB.Done(qid) then return false end end
    for _, st in ipairs(r.steps or {}) do
        if st.qid and (st.act == "accept" or st.act == "turnin") then
            any = true
            if not QB.Done(st.qid) then return false end
        end
    end
    return any
end

-- The one list of routes both the Guide's picker and the Routes page use:
-- Dungeons, then Zones (built-in, RUIN, yours and the zone quest routes),
-- then Completed / out-leveled, each sorted by level.
-- { { header, sub, routes = { ... } }, ... }
local function routeLibrary()
    local level = UnitLevel and UnitLevel("player") or 1
    local dungeons, zones, past = {}, {}, {}
    local function place(r, list)
        local lo, hi = routeLevels(r)
        r.lo, r.hi = lo, hi
        if r.id ~= db.route and ((hi and hi <= level - OUTLEVELED) or routeDone(r)) then
            past[#past + 1] = r
        else
            list[#list + 1] = r
        end
    end
    for _, r in ipairs(dungeonRoutes()) do place(r, dungeons) end
    -- the other faction's routes stay out of the list (your current route always shows)
    local mine = UnitFactionGroup and UnitFactionGroup("player")
    for _, r in ipairs(allRoutes()) do
        local f = r.faction
        if not (mine and f and f ~= "Any" and f ~= "" and f ~= mine and r.id ~= db.route) then place(r, zones) end
    end
    for _, r in ipairs(zoneRoutes()) do place(r, zones) end
    local function byLevel(a, b)
        local al, bl = a.lo or 999, b.lo or 999
        if al ~= bl then return al < bl end
        local ah, bh = a.hi or 999, b.hi or 999
        if ah ~= bh then return ah < bh end
        return (a.title or "") < (b.title or "")
    end
    table.sort(dungeons, byLevel); table.sort(zones, byLevel); table.sort(past, byLevel)
    local out = {}
    if #dungeons > 0 then out[#out + 1] = { header = "Dungeons", sub = "every quest, with the ones that unlock it", routes = dungeons } end
    out[#out + 1] = { header = "Zones", sub = "leveling routes and every zone's quests", routes = zones }
    if #past > 0 then out[#out + 1] = { header = "Completed / out-leveled", sub = ("done, or %d+ levels below you"):format(OUTLEVELED), routes = past } end
    return out
end
M.RouteLibrary = function() return routeLibrary() end

-- Routes hidden from the Guide's picker (Routes page checkbox), per account
local function hiddenRoute(id) return adb.hiddenRoutes and adb.hiddenRoutes[id] or false end
local function setHidden(id, v)
    adb.hiddenRoutes = adb.hiddenRoutes or {}
    adb.hiddenRoutes[id] = v or nil
end
M.IsRouteHidden = function(_, id) return hiddenRoute(id) end
M.SetRouteHidden = function(_, id, v) setHidden(id, v) end

-- The picker's routes: the library minus the hidden ones (the current
-- route always stays so it can be seen)
local function pickerRoutes()
    local ids = {}
    for _, sec in ipairs(routeLibrary()) do
        for _, r in ipairs(sec.routes) do
            if not hiddenRoute(r.id) or r.id == db.route then ids[#ids + 1] = r.id end
        end
    end
    return ids
end
M.PickerRoutes = function() return pickerRoutes() end

---------------------------------------------------------------------------
-- Page
---------------------------------------------------------------------------
local function routeLabel(r)
    return (r.official and (OFFICER_ICON .. " ") or "") .. r.title .. " (" .. (r.faction or "Any") .. ")"
end

-- the picker labels zone and dungeon routes without building their steps
local function pickerLabel(id)
    if type(id) == "string" and id:sub(1, 3) == "zq:" then
        local r = zqRoutes[id]
        return r and (r.title .. "  " .. C.dim .. "zone · " .. r.quests .. " quests|r") or id
    end
    local r = routeById(id)
    if r and r.dungeon then return r.title .. "  " .. C.dim .. "dungeon|r" end
    return r and routeLabel(r) or tostring(id)
end

local function isBuiltIn(id)
    for _, r in ipairs(ns.Routes) do if r.id == id then return true end end
    return false
end

-- The two original WoW Classic samples; the other built-in routes are RUIN's.
local function isSample(id) return id == "vot" or id == "northshire" end

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
    local h = W.Header(page, "Choose a route")
    h:SetPoint("TOPLEFT", 0, -2)
    ui.pickLabels = {}
    ui.pick = W.Button(page, "", 270, nil)
    ui.pick:SetPoint("TOPLEFT", 0, -20)
    W.MarkChoice(ui.pick)
    W.AttachMenu(ui.pick, { width = 270,
        items = function() return pickerRoutes() end,
        label = function(id) return pickerLabel(id) end,
        current = function() return ui.pickId end, pick = function(id) ui.pickId = id; refreshPage() end })
    local start = W.Button(page, "Start this route", 130, function() if ui.pickId then M:StartRoute(ui.pickId) end end)
    start:SetPoint("LEFT", ui.pick, "RIGHT", 6, 0)
    local trackCheck = W.Check(page, "Tracker", function() return db.tracker end,
        function(v) db.tracker = v; updateTracker() end)
    trackCheck:SetPoint("LEFT", start, "RIGHT", 10, 0)
    local arrowCheck = W.Check(page, "Waypoint", function() return db.waypoint ~= false end,
        function(v) db.waypoint = v; updateStepPin(); if M.RefreshPin then M.RefreshPin() end end)
    arrowCheck:SetPoint("LEFT", trackCheck, "RIGHT", 64, 0)
    arrowCheck.tip = "Put a waypoint on each step (or track its quest the game's way) so the RUIN pin leads you there. More in the Options tab."
    local skipCheck = W.Check(page, "Skip done quests", function() return db.skipDone end,
        function(v) db.skipDone = v; if v then M:SkipDone() end end)
    skipCheck:SetPoint("LEFT", arrowCheck, "RIGHT", 76, 0)
    skipCheck.tip = "Steps for quests you've already done, or already have, tick themselves off. Going back with < pauses this until you pass that step again."

    -- Steps as a checklist: a box, the step's marker, the quest and where.
    local h2 = W.Header(page, "Steps")
    h2:SetPoint("TOPLEFT", 0, -54)
    ui.stepCount = W.Label(page, "", "GameFontHighlightSmall")
    ui.stepCount:SetPoint("LEFT", h2, "RIGHT", 10, 0)
    ui.samplePill = W.Pill(page, 104)
    ui.samplePill:SetPoint("LEFT", ui.stepCount, "RIGHT", 10, 0)
    ui.samplePill:SetTag("Sample", "Classic sample")
    ui.clearBtn = W.Button(page, "Clear route", 90, function() M:ClearRoute() end)
    ui.clearBtn:SetPoint("TOPRIGHT", page, "TOPRIGHT", -24, -50)
    ui.clearBtn.tip = "Leave the route you're on without starting another."
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
        local have = s.qid and #(whoHas(s.qid)) or 0
        local org = (have > 0 and not done) and ("  " .. C.good .. have .. " in RUIN|r") or ""
        row.sub:SetText(markerHex(s.act) .. (ACT_LABEL[s.act] or s.act) .. "|r" .. org .. C.dim
            .. (where ~= "" and ("  ·  " .. where) or "") .. (detail ~= "" and ("  ·  " .. detail) or "") .. "|r")
        row.num:SetText(C.dim .. i .. "|r")
        row.tip = function(tip)
            tip:AddLine((ACT_LABEL[s.act] or s.act) .. (s.quest and (": " .. s.quest) or ""), 1, 0.82, 0)
            if s.text and s.text ~= "" then tip:AddLine(s.text, 1, 1, 1, true) end
            if s.at then tip:AddLine(("%s %.1f, %.1f"):format(s.at.zone, s.at.x, s.at.y), 0.6, 0.8, 0.6) end
            if s.qid then questTip(tip, s.qid) end
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
        local common = commonQuests(p)
        row.text:SetText(("%s  %s%s|r  %sstep %d|r%s%s"):format(W.ClassName(p.name), same and C.good or C.white,
            r and r.title or (C.dim .. "a route you don't have|r"), C.dim, p.step or 0,
            common > 0 and ("  " .. C.good .. common .. (common == 1 and " quest" or " quests") .. " in common|r") or "",
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

---------------------------------------------------------------------------
-- Quests page: your quest log with the database's details, and who in RUIN has
-- the same quests (invite them, or put the quest on your map).
---------------------------------------------------------------------------
-- A route of the quests the database lists for your zone and level.
function M:DraftFromData()
    local map, x, y = R.Map:PlayerPos()
    if not map then return self:Print("Couldn't tell which zone you're in.") end
    local r, why = QB.DraftRoute(map, UnitLevel("player"), x, y)
    if not r then return self:Print("No draft: " .. tostring(why)) end
    local clean = cleanRoute(r)
    if not clean then return self:Print("No draft: no usable steps.") end
    clean.author = (QB.Source() or "RUIN Quest Data") .. " draft"
    addCustom(clean)
    self:Print(("Drafted %s (%d steps) from the quest database. It's on the Routes page; start it, or record a better one."):format(clean.title, #clean.steps))
    refreshPage()
    return clean
end

local function questRows()
    local list = QB.Log()
    for _, q in ipairs(list) do
        local have, ready, done = whoHas(q.id)
        q.have, q.readyN, q.doneN = have, #ready, #done
        local info = QB.Quest(q.id)
        q.level = q.level or (info and info.level)
    end
    table.sort(list, function(a, b)
        if (#a.have > 0) ~= (#b.have > 0) then return #a.have > 0 end
        return (a.level or 0) < (b.level or 0)
    end)
    return list
end

local function buildQuests(page)
    local h = W.Header(page, "Your quests")
    h:SetPoint("TOPLEFT", 0, -2)
    ui.qInfo = W.Label(page, "", "GameFontHighlightSmall")
    ui.qInfo:SetPoint("LEFT", h, "RIGHT", 10, 0)
    ui.qShare = W.Check(page, "Share with RUIN", function() return db.shareQuests end, function(v)
        db.shareQuests = v
        if v then shareQuests(true) end
    end)
    ui.qShare.tip = "Tell RUIN members which quests you have and which of your route's quests you've done, so you can find each other."
    ui.qShare:SetPoint("TOPRIGHT", page, "TOPRIGHT", -112, 0)

    ui.qList = W.List(page, 34, function(row)
        row.text = W.Label(row, "")
        row.text:SetPoint("TOPLEFT", 6, -3)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.text:SetWordWrap(false)
        row.sub = W.Label(row, "", "GameFontHighlightSmall")
        row.sub:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -2)
        row.sub:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.sub:SetWordWrap(false)
        row:SetScript("OnMouseUp", function(self) if self.q then ui.qSel = self.q.id; refreshPage() end end)
    end, function(row, q)
        row.q = q
        local on = ui.qSel == q.id
        row.text:SetText(("%s[%s]|r %s%s|r%s"):format(C.dim, tostring(q.level or "?"), on and C.gold or C.white, q.title,
            q.ready and ("  " .. C.good .. "ready to hand in|r") or ""))
        local bits = {}
        if #q.have > 0 then bits[#bits + 1] = C.good .. #q.have .. " in RUIN have it|r" end
        if q.readyN > 0 then bits[#bits + 1] = C.good .. q.readyN .. " ready|r" end
        if q.doneN > 0 then bits[#bits + 1] = C.dim .. q.doneN .. " done it|r" end
        row.sub:SetText(#bits > 0 and table.concat(bits, C.dim .. "  ·  |r") or (C.dim .. "Nobody else in RUIN has this one right now.|r"))
        row.tip = function(tip) tip:AddLine(q.title, 1, 0.82, 0); questTip(tip, q.id) end
    end)
    ui.qList:SetEmptyText("Your quest log is empty. Accept a quest and it shows here, with who in RUIN has it too.")
    ui.qList.frame:SetPoint("TOPLEFT", 0, -24)
    ui.qList.frame:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
    ui.qList.frame:SetWidth(330)

    -- detail card
    local card = W.Card(page)
    card:SetPoint("TOPLEFT", 352, -24)
    card:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 72)
    ui.qName = W.Label(card, "", "GameFontNormalLarge")
    ui.qName:SetPoint("TOPLEFT", 12, -10)
    ui.qName:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    ui.qName:SetWordWrap(false)
    ui.qBody = W.Label(card, "", "GameFontHighlightSmall")
    ui.qBody:SetPoint("TOPLEFT", 12, -36)
    ui.qBody:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    ui.qBody:SetJustifyV("TOP")
    ui.qBody:SetWordWrap(true)
    ui.qMap = W.Button(card, "Show on map", 110, function()
        local q = ui.qSel
        if not q then return end
        local _, ready = QB.InLog(q)
        local map, x, y = R.Map:PlayerPos()
        local spot = QB.Spot(q, ready and "finish" or "objective", map, x, y) or QB.Spot(q, "finish", map, x, y)
        if not spot then return M:Print("The quest database doesn't have a place for this quest.") end
        R.Map:SetPin("Pathfinder", "quest", { map = spot.map, x = spot.x, y = spot.y, icon = "Interface\\AddOns\\RUIN_Core\\Media\\EmblemIcon", plain = true, shadow = true,
            color = W.MARKERS[ready and "turnin" or "quest"], title = "Pathfinder: " .. (C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(q) or "quest"),
            text = ready and ("Hand in: " .. (spot.name or "")) or (spot.name or "") })
        M:Print("Marked on your map: " .. (spot.name or "the quest") .. ".")
    end)
    ui.qMap:SetPoint("BOTTOMLEFT", 12, 12)
    ui.qInvite = W.Button(card, "Invite them", 104, function()
        local have = whoHas(ui.qSel)
        local invite = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit
        if not invite or #have == 0 then return end
        local me = UnitName("player")
        for _, p in pairs(peers) do
            local st = p.qt and p.quests and p.quests[ui.qSel]
            if st and R.Util.ShortName(p.name or "") ~= me and GetTime() - p.qt <= QUEST_TTL then pcall(invite, p.name) end
        end
        M:Print("Invited " .. nameList(have, 6) .. ".")
    end)
    ui.qInvite:SetPoint("LEFT", ui.qMap, "RIGHT", 6, 0)
    ui.qInvite.tip = "Invite the RUIN members who have this quest to your group."

    -- database footer
    local foot = W.Card(page)
    foot:SetPoint("BOTTOMLEFT", 352, 0)
    foot:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 0)
    foot:SetHeight(64)
    ui.qzHead = W.Label(foot, "", "GameFontNormal")
    ui.qzHead:SetPoint("TOPLEFT", 12, -9)
    ui.qzText = W.Label(foot, "", "GameFontHighlightSmall")
    ui.qzText:SetPoint("TOPLEFT", 12, -27)
    ui.qzText:SetPoint("RIGHT", foot, "RIGHT", -150, 0)
    ui.qzText:SetWordWrap(true)
    ui.qDraft = W.Button(foot, "Draft a route here", 134, function() M:DraftFromData() end)
    ui.qDraft:SetPoint("RIGHT", foot, "RIGHT", -10, 0)
end

local function refreshQuests()
    local rows = questRows()
    local found = false
    for _, q in ipairs(rows) do if q.id == ui.qSel then found = true end end
    if not found then ui.qSel = rows[1] and rows[1].id or nil end
    ui.qList:SetItems(rows)
    ui.qShare:Refresh()
    local members, now = 0, GetTime()
    for _, p in pairs(peers) do if p.qt and now - p.qt <= QUEST_TTL then members = members + 1 end end
    ui.qInfo:SetText(C.dim .. ("%d in your log  ·  %d RUIN member%s sharing quests"):format(#rows, members, members == 1 and "" or "s") .. "|r")
    local qid = ui.qSel
    local sel
    for _, q in ipairs(rows) do if q.id == qid then sel = q end end
    if not sel then
        ui.qName:SetText(C.dim .. "No quest picked.|r")
        ui.qBody:SetText("")
        ui.qMap:SetEnabled(false); ui.qInvite:SetEnabled(false)
    else
        ui.qName:SetText(sel.title)
        local lines = {}
        local info = QB.Quest(qid)
        if info then
            lines[#lines + 1] = C.dim .. "Level |r" .. tostring(info.level or "?") .. (info.req and (C.dim .. ", needs |r" .. info.req) or "")
            if info.starts[1] then lines[#lines + 1] = C.dim .. "Starts: |r" .. info.starts[1] end
            if info.ends[1] then lines[#lines + 1] = C.dim .. "Hand in: |r" .. info.ends[1] end
            for i = 1, math.min(4, #info.objectives) do lines[#lines + 1] = "- " .. info.objectives[i] end
        else
            lines[#lines + 1] = C.dim .. (QB.Has() and "The quest database has no entry for this quest." or "Enable RUIN Quest Data to see where this quest starts, ends and where its targets are.") .. "|r"
        end
        lines[#lines + 1] = " "
        local have, ready, done = whoHas(qid)
        lines[#lines + 1] = C.gold .. "In RUIN|r"
        lines[#lines + 1] = #have > 0 and (C.good .. "Have it: |r" .. nameList(have, 8)) or (C.dim .. "Nobody else has it right now.|r")
        if #ready > 0 then lines[#lines + 1] = C.good .. "Ready to hand in: |r" .. nameList(ready, 8) end
        if #done > 0 then lines[#lines + 1] = C.dim .. "Done it: |r" .. nameList(done, 8) end
        ui.qBody:SetText(table.concat(lines, "\n"))
        ui.qMap:SetEnabled(QB.Has())
        ui.qInvite:SetEnabled(#have > 0)
    end
    if QB.Has() then
        ui.qzHead:SetText(C.good .. (QB.Source() or "RUIN Quest Data") .. " found|r")
        ui.qzText:SetText(C.dim .. "Givers, hand-ins and targets come from " .. (QB.Source() or "RUIN Quest Data") .. ". Draft a route of this zone's quests for your level.|r")
    else
        ui.qzHead:SetText(C.dim .. "No quest database|r")
        ui.qzText:SetText(C.dim .. "Routes and sharing work without it. Enable RUIN Quest Data and every step gets a place and you can draft routes.|r")
    end
    ui.qDraft:SetEnabled(QB.Has())
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
    ui.draftBtn = W.Button(page, "Draft a route", 140, function() M:DraftFromData() end)
    ui.draftBtn:SetPoint("RIGHT", imp, "LEFT", -6, 0)
    ui.draftBtn.tip = "Make a route of the quests the database lists for your zone and level."
    ui.library = W.List(page, 26, function(row)
        -- ticked: the route is in the Guide's "Choose a route" list
        -- on a section header it ticks or unticks the whole section
        row.show = W.Check(row, "", function()
            local e = row.e
            if e and e.route then return not hiddenRoute(e.route.id) end
            for _, r in ipairs(e and e.routes or {}) do if not hiddenRoute(r.id) then return true end end
            return false
        end, function(v)
            local e = row.e
            if e and e.route then setHidden(e.route.id, not v)
            else for _, r in ipairs(e and e.routes or {}) do setHidden(r.id, not v) end end
            refreshPage()
        end)
        row.show:SetPoint("LEFT", 2, 0)
        -- a section header is a tinted band with Pathfinder's color down its
        -- left edge and a gold line under it; clicking it folds the section
        local ac = W.SchemeOf(row).accent
        row.band = row:CreateTexture(nil, "BORDER")
        row.band:SetAllPoints()
        row.band:SetColorTexture(ac[1], ac[2], ac[3], 0.22)
        row.bandEdge = row:CreateTexture(nil, "ARTWORK")
        row.bandEdge:SetPoint("TOPLEFT"); row.bandEdge:SetPoint("BOTTOMLEFT")
        row.bandEdge:SetWidth(3)
        row.bandEdge:SetColorTexture(ac[1], ac[2], ac[3], 0.95)
        row.bandLine = row:CreateTexture(nil, "ARTWORK")
        row.bandLine:SetPoint("BOTTOMLEFT"); row.bandLine:SetPoint("BOTTOMRIGHT")
        row.bandLine:SetHeight(1)
        row.bandLine:SetColorTexture(0.9, 0.72, 0.38, 0.6)
        row:SetScript("OnMouseUp", function(self, button)
            local e = self.e
            if button == "LeftButton" and e and e.header and e.key then
                adb.collapsedRoutes = adb.collapsedRoutes or {}
                adb.collapsedRoutes[e.key] = not adb.collapsedRoutes[e.key] or nil
                refreshPage()
            end
        end)
        row.text = W.Label(row, "")
        row.text:SetPoint("LEFT", 28, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -368, 0)
        row.text:SetWordWrap(false)
        row.del = W.Button(row, "Delete", 74)
        row.del:SetPoint("RIGHT", 0, 0)
        row.share = W.Button(row, "Share", 56)
        row.share:SetPoint("RIGHT", row.del, "LEFT", -2, 0)
        row.export = W.Button(row, "Export", 60)
        row.export:SetPoint("RIGHT", row.share, "LEFT", -2, 0)
        row.start = W.Button(row, "Start", 54)
        row.start:SetPoint("RIGHT", row.export, "LEFT", -2, 0)
        row.add = W.Button(row, "Add", 46)
        row.add:SetPoint("RIGHT", row.start, "LEFT", -2, 0)
        row.pub = W.Button(row, OFFICER_ICON .. " Publish", 84)
        row.pub:SetPoint("RIGHT", row.add, "LEFT", -2, 0)
    end, function(row, e)
        local officer = R:IsOfficer()
        row.tip = nil
        row.e = e
        local isHead = e.header ~= nil
        row.band:SetShown(isHead); row.bandEdge:SetShown(isHead); row.bandLine:SetShown(isHead)
        row.text:SetFontObject(isHead and "GameFontNormal" or "GameFontHighlight")
        if e.spacer then
            row.zebra:SetColorTexture(0, 0, 0, 0)
            row.show:Hide(); row.text:SetText("")
            row.add:Hide(); row.start:Hide(); row.export:Hide(); row.share:Hide(); row.del:Hide(); row.pub:Hide()
            return
        end
        if e.route or e.routes then
            row.show:Show(); row.show:Refresh()
            row.show.tip = e.route and "Show this route in the Guide tab's Choose a route list. Untick to hide it there; it stays here."
                or "Show or hide every route in this section in the Guide tab's Choose a route list."
        else
            row.show:Hide()
        end
        if e.header then
            row.text:SetText(C.gold .. e.header .. "|r")
            row.add:Hide(); row.start:Hide(); row.export:Hide(); row.share:Hide(); row.del:Hide(); row.pub:Hide()
            return
        end
        if e.route and e.route.zoneArea then
            local r = e.route
            row.text:SetText(("%s%s|r  %s%s · %d quests · levels %s|r%s"):format(C.white, r.title, C.dim, r.faction or "Any",
                r.quests or 0, r.levels or "?", db.route == r.id and ("  " .. C.good .. "current|r") or ""))
            row.add:Hide(); row.del:Hide(); row.pub:Hide()
            row.start:Show(); row.export:Show(); row.share:Show()
            row.start:SetScript("OnClick", function() M:StartRoute(r.id); ui.tabs:Select(1) end)
            row.export:SetScript("OnClick", function() M:ExportRoute(r.id) end)
            row.share:SetScript("OnClick", function() M:ShareRoute(r.id) end)
            row.tip = function(tip)
                tip:AddLine(r.title, 1, 1, 1)
                tip:AddLine(("Every quest %s has for your character at levels %s, with the quests from elsewhere that unlock them, nearest first. Built from %s."):format(
                    r.zoneName or "this zone", r.levels or "?", QB.Source() or "RUIN Quest Data"), 0.8, 0.85, 0.95, true)
            end
            return
        end
        if e.route and e.route.dungeon then
            local r = e.route
            row.text:SetText(("%s%s|r  %s%s · %d quests · %d steps · levels %s|r%s"):format(C.white, r.title, C.dim, r.faction or "Any",
                r.quests or 0, #r.steps, r.levels or "?", db.route == r.id and ("  " .. C.good .. "current|r") or ""))
            row.add:Hide(); row.del:Hide(); row.pub:Hide()
            row.start:Show(); row.export:Show(); row.share:Show()
            row.start:SetScript("OnClick", function() M:StartRoute(r.id); ui.tabs:Select(1) end)
            row.export:SetScript("OnClick", function() M:ExportRoute(r.id) end)
            row.share:SetScript("OnClick", function() M:ShareRoute(r.id) end)
            row.tip = function(tip)
                tip:AddLine(r.title, 1, 1, 1)
                tip:AddLine("Every quest " .. r.dungeon .. " has for your character, the quests that unlock them, the run, and the hand-ins. Built from " .. (QB.Source() or "RUIN Quest Data") .. ".", 0.8, 0.85, 0.95, true)
            end
            return
        end
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
            -- officers can approve a member's route for all of RUIN
            row.pub:SetShown(officer)
            row.pub:SetText(OFFICER_ICON .. " Approve")
            row.pub:ClearAllPoints()
            row.pub:SetPoint("RIGHT", row.add, "LEFT", -2, 0)
            row.pub:SetScript("OnClick", function()
                local added = addCustom(R.Util.DeepCopy(r))
                added.author = added.author or e.inbox.from
                M:PublishRoute(added.id, e.inbox.from)
                adb.custom[added.id] = nil
                for i, x in ipairs(adb.inbox) do if x == e.inbox then table.remove(adb.inbox, i) end end
                refreshPage()
            end)
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
        local official = r.official ~= nil
        local who = official and (C.gold .. "RUIN · " .. officialTip(r) .. "|r" .. C.dim)
            or mine and ("by " .. R.Util.ShortName(r.author or "?")) or "built in"
        row.text:SetText(("%s%s%s|r  %s%s · %d steps · %s|r%s"):format(official and (OFFICER_ICON .. " ") or "", C.white, r.title,
            C.dim, r.faction or "Any", #r.steps, who, db.route == r.id and ("  " .. C.good .. "current|r") or "")
            .. (isSample(r.id) and ("  " .. W.TagText("Sample", "Classic sample")) or ""))
        -- how many quests WoW Forever has in the route's zone (ForeverDB, launch)
        local zq = r.zone and ns.ZoneQuests and ns.ZoneQuests[r.zone]
        row.tip = (official or zq) and function(tip)
            if official then
                tip:AddLine(OFFICER_ICON .. " RUIN route", 1, 0.82, 0)
                tip:AddLine(officialTip(r), 1, 1, 1, true)
            end
            if zq then
                tip:AddLine(("%s: %d quests in WoW Forever, levels %s"):format(r.zone, zq[1], zq[2]), 0.8, 0.85, 0.95)
                tip:AddLine("Quest count from ForeverDB at launch (Nov 5, 2026).", 0.6, 0.6, 0.6, true)
            end
        end or nil
        row.add:Hide()
        -- officers publish their routes (or the built-in ones) to everyone, and withdraw RUIN routes
        row.pub:SetShown(officer and not official and officerMade(r))
        row.pub:SetText(OFFICER_ICON .. " Publish")
        row.pub:ClearAllPoints()
        row.pub:SetPoint("RIGHT", row.start, "LEFT", -2, 0)
        row.pub:SetScript("OnClick", function() M:PublishRoute(r.id) end)
        row.start:Show(); row.export:Show(); row.share:Show()
        row.start:SetScript("OnClick", function() M:StartRoute(r.id); ui.tabs:Select(1) end)
        row.export:SetScript("OnClick", function() M:ExportRoute(r.id) end)
        row.share:SetScript("OnClick", function() M:ShareRoute(r.id) end)
        row.del:SetText(official and "Withdraw" or "Delete")
        row.del:SetShown(mine or (official and officer))
        row.del:SetScript("OnClick", function()
            if official then
                R:Confirm("Withdraw RUIN route", "Remove " .. r.title .. " from every RUIN member's route list?", function() M:WithdrawRoute(r.id) end)
            else
                R:Confirm("Delete route", "Delete " .. r.title .. "? This can't be undone.", function() M:DeleteRoute(r.id) end)
            end
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
    ui.recTitle = W.EditBox(card, 240, function(t) adb.rec.title = t:sub(1, 40) end, "Route title")
    ui.recTitle:SetPoint("TOPLEFT", 10, -28)
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
    local act = W.Cycle(card, 140, ACTS, function() return ui.noteAct end, function(v) ui.noteAct = v end)
    act.format = function(v) return ACT_LABELS[v] or v end
    act.tipTitle = "What kind of step to add"
    act:Refresh()
    act:SetPoint("TOPLEFT", 8, -56)
    local note = W.EditBox(card, 260, nil, "What the step says (quest name for quests)")
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

-- Key bindings (Bindings.xml): Game Menu > Options > Keybindings > AddOns.
BINDING_NAME_RUIN_PATH_CLEAR = "Pathfinder: clear the route"
BINDING_NAME_RUIN_PATH_PIN = "Pathfinder: show or hide the RUIN pin"
function RUIN_PathfinderBinding(cmd)
    if cmd == "open" then M:OpenTab(); if ui.tabs then ui.tabs:Select(1) end; return end
    if SlashCmdList and SlashCmdList.RUINPATH then SlashCmdList.RUINPATH(cmd) end
end

-- Options: the tracker, waypoints and the RUIN pin.
local function buildOptions(page)
    local checks = {}
    local function check(parent, label, key, tip, after, x, y)
        local c = W.Check(parent, label, function() return db[key] ~= false end, function(v)
            db[key] = v
            updateTracker(); updateStepPin()
            if M.RefreshPin then M.RefreshPin() end
        end)
        c:SetPoint("TOPLEFT", x, y)
        c.tip = tip
        checks[#checks + 1] = c
        return c
    end
    local function card(title, top, height)
        local c = W.Card(page)
        c:SetPoint("TOPLEFT", 0, top)
        c:SetPoint("RIGHT", page, "RIGHT", 0, 0)
        c:SetHeight(height)
        local h = W.Header(c, title)
        h:SetPoint("TOPLEFT", 10, -8)
        return c
    end
    local COL2 = 300

    local t = card("Tracker", 0, 84)
    check(t, "Show the tracker", "tracker", "The small window with the Route and Tracked tabs: < and > on its sides, the x to clear, double-click to open Pathfinder.", nil, 12, -30)
    check(t, "Tracker arrow and map pin", "arrow", "The arrow on the tracker pointing to the step, and the step's pin on the world map.", nil, COL2, -30)
    check(t, "Skip done quests", "skipDone", "Steps for quests you've already done, or already have, tick themselves off.", nil, 12, -54)
    check(t, "Say each new waypoint in chat", "announce", "\"Waypoint set: ... (N yards)\" when you move to a step.", nil, COL2, -54)

    local w = card("Waypoint", -92, 84)
    check(w, "Put a waypoint on each step", "waypoint", "The game's waypoint on the step's spot, so the pin (and the game's navigation) leads you there. /path waypoint", nil, 12, -30)
    check(w, "Track quest steps the game's way", "trackQuests", "For a quest in your log, track the quest itself (like clicking it in the objective tracker) so the pin follows its objective or turn-in.", nil, COL2, -30)
    check(w, "Turn on In-Game Navigation when needed", "autoNav", "The game draws nothing in the world while its In-Game Navigation option is off. Pathfinder turns it on when it places a waypoint.", nil, 12, -54)
    local share = W.Check(w, "Share quest locations with RUIN", function() return adb.atlasShare ~= false end, function(v) adb.atlasShare = v end)
    share:SetPoint("TOPLEFT", COL2, -54)
    share.tip = "Pathfinder's atlas: where you pick up, do and hand in quests, shared with RUIN so routes follow where things really are on WoW Forever. Only quest numbers and map spots. /path atlas"
    checks[#checks + 1] = share

    local p = card("RUIN pin", -184, 132)
    check(p, "Show the RUIN pin", "pin", "RUIN's marker over whatever the game is navigating to. Off: the game's own marker shows instead. /path pin", nil, 12, -30)
    check(p, "Hide when the game says you're there", "pinHideInArea", "The pin always steps aside in the tracked quest's objective area. This also hides it when the game says you've arrived, or within the distance below.", nil, COL2, -30)

    local edit = W.Button(p, "Waypoint Editor", 140, function() if M.OpenWaypointEditor then M.OpenWaypointEditor() end end)
    edit:SetPoint("TOPLEFT", 14, -56)
    edit.tip = "Choose what the pin shows (card, label, title, objectives, marker, stem, distance, walking time, edge arrow) and how it looks, with a live preview. /path editor"

    local hl = W.Label(p, "", "GameFontHighlight")
    hl:SetPoint("TOPLEFT", COL2 + 4, -60)
    local function yardsLabel() hl:SetText(("Hide within %s%d yd|r"):format(C.gold, db.pinHideYards or 15)) end
    local minus = W.Button(p, "-", 24, function() db.pinHideYards = math.max(0, (db.pinHideYards or 15) - 5); yardsLabel() end)
    minus:SetPoint("LEFT", hl, "RIGHT", 10, 0)
    local plus = W.Button(p, "+", 24, function() db.pinHideYards = math.min(100, (db.pinHideYards or 15) + 5); yardsLabel() end)
    plus:SetPoint("LEFT", minus, "RIGHT", 2, 0)
    minus.tip, plus.tip = "Nearer than this, the pin hides (0: never).", "Nearer than this, the pin hides (0: never)."

    -- nudge: where the pin sits over the spot, in screen pixels
    local function nudge(label, key, x, y, upWord, downWord)
        local l = W.Label(p, "", "GameFontHighlight")
        l:SetPoint("TOPLEFT", x, y)
        local function show()
            local v = db[key] or 0
            l:SetText(("%s %s%s|r"):format(label, C.gold, v == 0 and "centered" or (("%d %s"):format(math.abs(v), v > 0 and upWord or downWord))))
        end
        local minus = W.Button(p, "-", 24, function() db[key] = math.max(-150, (db[key] or 0) - 5); show() end)
        minus:SetPoint("TOPLEFT", x + 150, y + 4)
        local plus = W.Button(p, "+", 24, function() db[key] = math.min(150, (db[key] or 0) + 5); show() end)
        plus:SetPoint("LEFT", minus, "RIGHT", 2, 0)
        local zero = W.Button(p, "0", 24, function() db[key] = 0; show() end)
        zero:SetPoint("LEFT", plus, "RIGHT", 2, 0)
        minus.tip, plus.tip, zero.tip = "Move it " .. downWord .. " 5 pixels.", "Move it " .. upWord .. " 5 pixels.", "Back to the spot."
        return show
    end
    local showY = nudge("Up / down:", "pinOffsetY", 16, -100, "up", "down")
    local showX = nudge("Left / right:", "pinOffsetX", COL2 + 4, -100, "right", "left")
    local syncSize = function() end

    local k = card("Controls", -324, 76)
    local kl = W.Label(k, "", "GameFontHighlightSmall")
    kl:SetPoint("TOPLEFT", 12, -30)
    kl:SetPoint("RIGHT", k, "RIGHT", -12, 0)
    kl:SetJustifyV("TOP")
    if kl.SetSpacing then kl:SetSpacing(3) end
    kl:SetText(C.white .. "Key bindings|r " .. C.dim .. "(Game Menu > Options > Keybindings > AddOns > RUIN Pathfinder):|r next step, previous step, clear the route, show or hide the pin, open Pathfinder.\n"
        .. C.white .. "Chat:|r " .. C.dim .. "/path next, /path prev, /path clear, /path pin, /path editor, /path waypoint, /path nav|r")

    page:SetScript("OnShow", function()
        for _, c in ipairs(checks) do c:Refresh() end
        yardsLabel(); syncSize(); showY(); showX()
    end)
    ui.optionChecks = checks
end

local function buildPage(panel)
    ui.panel = panel
    ui.tabs = W.SubTabs(panel, { "Guide", "Quests", "Routes", "Record", "Options" }, function() refreshPage() end)
    buildCurrent(ui.tabs.pages[1])
    buildQuests(ui.tabs.pages[2])
    buildLibrary(ui.tabs.pages[3])
    buildRecorder(ui.tabs.pages[4])
    buildOptions(ui.tabs.pages[5])

    refreshPage = function()
        if not ui.panel:IsVisible() then return end
        ui.tabs:SetLabel(3, #adb.inbox > 0 and ("Routes " .. C.good .. "(" .. #adb.inbox .. " new)|r") or "Routes")
        ui.tabs:SetLabel(4, adb.rec.on and ("Record " .. C.bad .. "(on)|r") or "Record")
        local tab = ui.tabs.selected
        if tab == 1 then
            if not ui.pickId or not routeById(ui.pickId) then
                ui.pickId = db.route or pickerRoutes()[1]
            end
            local pr = routeById(ui.pickId)
            ui.pick:SetText(pr and routeLabel(pr) or "No routes")
            local r = currentRoute()
            ui.list:SetItems(r and r.steps or {})
            ui.stepCount:SetText(r and (C.dim .. ("%d/%d done"):format(math.min(db.step - 1, #r.steps), #r.steps) .. "|r") or "")
            ui.samplePill:SetShown(r ~= nil and isSample(r.id))
            if r then ui.clearBtn:Show() else ui.clearBtn:Hide() end
            refreshClassTrack()
            ui.peers:SetItems(livePeers())
        elseif tab == 2 then
            refreshQuests()
        elseif tab == 3 then
            ui.draftBtn:SetShown(QB.Has())
            local items = {}
            for _, e in ipairs(adb.inbox) do items[#items + 1] = { inbox = e } end
            local PLUS, MINUS = "|TInterface\\Buttons\\UI-PlusButton-Up:14:14|t", "|TInterface\\Buttons\\UI-MinusButton-Up:14:14|t"
            for i, sec in ipairs(routeLibrary()) do
                local folded = adb.collapsedRoutes and adb.collapsedRoutes[sec.header]
                if i > 1 or #items > 0 then items[#items + 1] = { spacer = true } end
                items[#items + 1] = { key = sec.header, routes = sec.routes,
                    header = ("%s %s  %s(%d)|r  %s%s|r"):format(folded and PLUS or MINUS, sec.header, C.white, #sec.routes, C.dim,
                        folded and "click to show" or sec.sub) }
                if not folded then
                    for _, r in ipairs(sec.routes) do items[#items + 1] = { route = r } end
                end
            end
            ui.library:SetItems(items)
        elseif tab == 4 then
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
    self:Listen("OFFICIAL", "OnOfficial")
    self:Listen("OFFDEL", "OnOfficialDelete")
    self:Listen("ASK", "OnAsk")
    self:Listen("QSTAT", "OnQuests")
    self:Listen("ATLAS", "OnAtlas")
    self:AddTab("Pathfinder", buildPage)
    self:RegisterEvent("QUEST_ACCEPTED", onAccepted)
    self:RegisterEvent("QUEST_TURNED_IN", onTurnedIn)
    self:RegisterEvent("QUEST_LOG_UPDATE", function() checkComplete(); atlasObjectives() end)
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", function() updateStepPin() end)
    self:RegisterEvent("PLAYER_LEVEL_UP", onLevelUp)
    self:RegisterEvent("CHAT_MSG_LOOT", onLootRecord)

    R:Subscribe("CHANNELS_CHANGED", function()
        C_Timer.After(5, share)
        C_Timer.After(12, function() shareQuests(true) end)
        -- ask officers for the RUIN routes published while you were away
        C_Timer.After(9, function() if R:IsConnected() then self:Send("ASK", {}, "ORG") end end)
    end)
    C_Timer.NewTicker(10, function()
        if db.route and GetTime() - lastShare >= SHARE_EVERY then share() end
        shareQuests()
        atlasShare()
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

-- /path next | prev | tracker | arrow | record | rec | mark <note> | save | import | unfollow | clear | waypoint | pin | editor | trainer
--       | quests | draft | skip | questshare
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
    if msg == "quests" then M:OpenTab(); if ui.tabs then ui.tabs:Select(2) end; return end
    if msg == "draft" then return M:DraftFromData() end
    if msg == "skip" then
        db.skipDone = not db.skipDone
        if db.skipDone then M:SkipDone() end
        return M:Print("Skipping quests you've done " .. (db.skipDone and "on." or "off."))
    end
    if msg == "questshare" then
        db.shareQuests = not db.shareQuests
        if db.shareQuests then shareQuests(true) end
        return M:Print("Sharing your quests with RUIN " .. (db.shareQuests and "on." or "off."))
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
    elseif msg == "clear" or msg == "stop" then M:ClearRoute()
    elseif msg == "nav" then M:NavReport()
    elseif msg == "atlas" then
        local n = M.AtlasCounts()
        M:Print(("Atlas: where %d quests are picked up, %d handed in, and the objectives of %d, from RUIN members playing WoW Forever. Sharing is %s."):format(
            n.s, n.f, n.o, adb.atlasShare == false and "off" or "on"))
    elseif msg == "editor" or msg == "edit" then if M.OpenWaypointEditor then M.OpenWaypointEditor() end
    elseif msg == "pin" then
        db.pin = db.pin == false
        if M.RefreshPin then M.RefreshPin() end
        M:Print("RUIN waypoint pin " .. (db.pin and "on." or "off (the game's own marker shows instead)."))
    elseif msg == "waypoint" then
        db.waypoint = db.waypoint == false
        updateStepPin()
        M:Print("Waypoint in the world " .. (db.waypoint and "on." or "off."))
    else M:OpenTab() end
end
