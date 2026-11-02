-- RUIN Pathfinder: Questie bridge
-- When the standalone QuestieDB addon (contract 4, e.g. the one that ships
-- with Ruinous Forever Planner) is installed, Pathfinder reads it; otherwise,
-- when Questie is installed, Pathfinder reads Questie's quest database at run time
-- (nothing of Questie's data is copied into RUIN): where a quest starts, where
-- it is handed in, where its targets are, its level and objectives, which
-- quests you have finished, and which quests are available in your zone.
-- Every call is guarded: if Questie is missing, still loading, or changes its
-- internals, these functions return nil and Pathfinder carries on without it.
--
-- Questie API used (Questie 11.x / 12.x):
--   QuestieLoader:ImportModule("QuestieDB" | "ZoneDB")
--   QuestieDB.GetQuest(id)  -> { name, level, requiredLevel, Starts = { NPC, GameObject },
--                               Finisher = { NPC, GameObject }, ObjectiveData, objectivesText, zoneOrSort }
--   QuestieDB:GetNPC(id) / QuestieDB:GetObject(id) / QuestieDB:GetItem(id) -> { name, spawns = { [areaId] = { {x, y}, ... } } }
--   QuestieDB.QuestPointers, QuestieDB.QueryQuestSingle(id, field), QuestieDB.IsDoable(id)
--   ZoneDB:GetUiMapIdByAreaId(areaId), ZoneDB:GetAreaIdByUiMapId(uiMapId)
--   Questie.db.char.complete[questId]
local ADDON, ns = ...

local QB = {}
ns.QB = QB

local cache = { quest = {}, spot = {}, miss = {} }
local modules

-- QuestieDB (the standalone database addon, contract 4) when it's installed:
-- the same shape as Questie's own modules, so everything below reads either.
local function readMap(text)
    if type(text) == "table" then return text end
    if type(text) ~= "string" then return nil end
    local load = loadstring or load
    local okc, chunk = pcall(load, text)
    if not okc or type(chunk) ~= "function" then return nil end
    local okr, t = pcall(chunk)
    return okr and type(t) == "table" and t or nil
end

local function zoneMaps(lib)
    local support = type(lib.Support) == "table" and type(lib.Support.Get) == "function" and lib.Support.Get("ZoneDB")
    local private = type(support) == "table" and support.private or {}
    local function merged(baseKey, overrideKey)
        local out = {}
        for k, v in pairs(readMap(private[baseKey]) or {}) do out[k] = v end
        for k, v in pairs(readMap(private[overrideKey]) or {}) do out[k] = v end
        return out
    end
    return merged("areaIdToUiMapId", "areaIdToUiMapIdOverride"), merged("uiMapIdToAreaId", "uiMapIdToAreaIdOverride")
end

local OBJECTIVE_KINDS = { "monster", "object", "item" }     -- QuestieDB's positional objective groups 1-3

local function fromQuestieDB()
    local lib = rawget(_G, "LibQuestieDB")
    if type(lib) ~= "table" or type(lib.RequireContract) ~= "function" then return nil end
    local okc, compatible = pcall(lib.RequireContract, 4)
    if not okc or not compatible then return nil end
    local Q, N, O, I = lib.Quest, lib.Npc, lib.Object, lib.Item
    if type(Q) ~= "table" or type(Q.Get) ~= "function" or type(Q.Exists) ~= "function" then return nil end
    local toMap, toArea = zoneMaps(lib)
    local function exists(E, id) return type(E) == "table" and type(id) == "number" and E.Exists(id) end
    local DB = {}
    function DB.GetQuest(id)
        if not exists(Q, id) then return nil end
        local starts, ends = Q.Get(id, "startedBy") or {}, Q.Get(id, "finishedBy") or {}
        local data = {}
        local objectives = Q.Get(id, "objectives")
        for group, kind in ipairs(OBJECTIVE_KINDS) do
            local list = type(objectives) == "table" and objectives[group]
            for _, o in ipairs(type(list) == "table" and list or {}) do
                if type(o) == "table" and tonumber(o[1]) then data[#data + 1] = { Type = kind, Id = tonumber(o[1]), Text = type(o[2]) == "string" and o[2] or nil } end
            end
        end
        return { name = Q.Get(id, "name"), level = Q.Get(id, "questLevel"), requiredLevel = Q.Get(id, "requiredLevel"),
                 Starts = { NPC = starts[1], GameObject = starts[2] }, Finisher = { NPC = ends[1], GameObject = ends[2] },
                 ObjectiveData = data, objectivesText = Q.Get(id, "objectivesText"), zoneOrSort = Q.Get(id, "zoneOrSort") }
    end
    function DB:GetNPC(id) if exists(N, id) then return { name = N.Get(id, "name"), spawns = N.Get(id, "spawns") } end end
    function DB:GetObject(id) if exists(O, id) then return { name = O.Get(id, "name"), spawns = O.Get(id, "spawns") } end end
    function DB:GetItem(id) if exists(I, id) then return { name = I.Get(id, "name"), npcDrops = I.Get(id, "npcDrops"), objectDrops = I.Get(id, "objectDrops") } end end
    DB.QuestPointers = type(Q.GetAllIds) == "function" and Q.GetAllIds(true) or nil
    function DB.QueryQuestSingle(id, field) if exists(Q, id) then return Q.Get(id, field) end end
    -- Class and race masks (bit n-1 for class or race ID n); other requirements are the game's to judge.
    function DB.IsDoable(id)
        if not exists(Q, id) then return false end
        local function allowed(mask, unitFn)
            mask = tonumber(mask)
            if not mask or mask == 0 or not unitFn then return true end
            local _, _, n = unitFn("player")
            n = tonumber(n)
            if not n then return true end
            return math.floor(mask / 2 ^ (n - 1)) % 2 == 1
        end
        return allowed(Q.Get(id, "requiredClasses"), UnitClass) and allowed(Q.Get(id, "requiredRaces"), UnitRace)
    end
    local Zone = {}
    function Zone:GetUiMapIdByAreaId(areaId) return toMap[areaId] end
    function Zone:GetAreaIdByUiMapId(uiMap) return toArea[uiMap] end
    return { DB = DB, Zone = Zone, source = "QuestieDB" }
end

local function db()
    if modules ~= nil then return modules or nil end
    -- The standalone QuestieDB addon first, then Questie's own database.
    local ok, fromLib = pcall(fromQuestieDB)
    if ok and fromLib then modules = fromLib; return modules end
    if type(QuestieLoader) ~= "table" or type(QuestieLoader.ImportModule) ~= "function" then return nil end
    local ok1, DB = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieDB")
    local ok2, ZoneDB = pcall(QuestieLoader.ImportModule, QuestieLoader, "ZoneDB")
    if not (ok1 and type(DB) == "table" and type(DB.GetQuest) == "function" and ok2 and type(ZoneDB) == "table") then
        return nil                                -- not ready yet; try again on the next call
    end
    modules = { DB = DB, Zone = ZoneDB, source = "Questie" }
    return modules
end

-- "QuestieDB" or "Questie" (whichever Pathfinder reads), or nil.
function QB.Source()
    local m = db()
    return m and m.source or nil
end

-- Is Questie installed and its database ready?
function QB.Has()
    return db() ~= nil
end

function QB.Forget() cache = { quest = {}, spot = {}, miss = {} }; modules = nil end

-- What Questie knows about a quest:
-- { id, name, level, req, starts = { names }, ends = { names }, objectives = { text }, zone }
function QB.Quest(qid)
    qid = tonumber(qid)
    if not qid then return nil end
    local hit = cache.quest[qid]
    if hit ~= nil then return hit or nil end
    local m = db()
    if not m then return nil end
    local ok, q = pcall(m.DB.GetQuest, qid)
    if not ok or type(q) ~= "table" then return nil end      -- not cached: Questie may still be loading
    local function names(list, kind)
        local out = {}
        for _, id in ipairs(type(list) == "table" and list or {}) do
            local okn, rec
            if kind == "npc" then okn, rec = pcall(m.DB.GetNPC, m.DB, id) else okn, rec = pcall(m.DB.GetObject, m.DB, id) end
            if okn and type(rec) == "table" and type(rec.name) == "string" then out[#out + 1] = rec.name end
        end
        return out
    end
    local starts, ends = {}, {}
    local s, f = type(q.Starts) == "table" and q.Starts or {}, type(q.Finisher) == "table" and q.Finisher or {}
    for _, n in ipairs(names(s.NPC, "npc")) do starts[#starts + 1] = n end
    for _, n in ipairs(names(s.GameObject, "object")) do starts[#starts + 1] = n end
    for _, n in ipairs(names(f.NPC, "npc")) do ends[#ends + 1] = n end
    for _, n in ipairs(names(f.GameObject, "object")) do ends[#ends + 1] = n end
    local objectives = {}
    for _, o in ipairs(type(q.ObjectiveData) == "table" and q.ObjectiveData or {}) do
        if type(o) == "table" and type(o.Text) == "string" and o.Text ~= "" then objectives[#objectives + 1] = o.Text end
    end
    if #objectives == 0 and type(q.objectivesText) == "table" and type(q.objectivesText[1]) == "string" then
        objectives[1] = q.objectivesText[1]
    end
    local info = { id = qid, name = q.name, level = tonumber(q.level or q.questLevel), req = tonumber(q.requiredLevel),
                   starts = starts, ends = ends, objectives = objectives, zone = tonumber(q.zoneOrSort) }
    cache.quest[qid] = info
    return info
end

-- Spawns of an NPC, object or item drop as { { map, x, y }, ... } (x, y 0-1).
local function spawnsOf(m, kind, id, out, limit)
    local ok, rec
    if kind == "npc" then ok, rec = pcall(m.DB.GetNPC, m.DB, id)
    elseif kind == "object" then ok, rec = pcall(m.DB.GetObject, m.DB, id) end
    if not ok or type(rec) ~= "table" or type(rec.spawns) ~= "table" then return end
    for areaId, spots in pairs(rec.spawns) do
        local okm, map = pcall(m.Zone.GetUiMapIdByAreaId, m.Zone, areaId)
        if okm and map and type(spots) == "table" then
            for _, p in ipairs(spots) do
                if type(p) == "table" and tonumber(p[1]) and tonumber(p[2]) and p[1] >= 0 then
                    out[#out + 1] = { map = map, x = p[1] / 100, y = p[2] / 100, name = rec.name }
                    if #out >= (limit or 400) then return end
                end
            end
        end
    end
end

-- All the places for a quest. which: "start", "finish" or "objective".
function QB.Spots(qid, which)
    qid = tonumber(qid)
    if not qid then return {} end
    local key = which .. ":" .. qid
    if cache.spot[key] then return cache.spot[key] end
    local now = GetTime and GetTime() or 0
    if cache.miss[key] and now - cache.miss[key] < 30 then return {} end   -- the arrow asks often
    local m = db()
    if not m then return {} end
    local ok, q = pcall(m.DB.GetQuest, qid)
    local out = {}
    if ok and type(q) == "table" then
        if which == "start" or which == "finish" then
            local by = which == "start" and q.Starts or q.Finisher
            by = type(by) == "table" and by or {}
            for _, id in ipairs(type(by.NPC) == "table" and by.NPC or {}) do spawnsOf(m, "npc", id, out, 40) end
            for _, id in ipairs(type(by.GameObject) == "table" and by.GameObject or {}) do spawnsOf(m, "object", id, out, 40) end
        else
            for _, o in ipairs(type(q.ObjectiveData) == "table" and q.ObjectiveData or {}) do
                if type(o) == "table" and o.Id then
                    if o.Type == "monster" then spawnsOf(m, "npc", o.Id, out)
                    elseif o.Type == "object" then spawnsOf(m, "object", o.Id, out)
                    elseif o.Type == "item" then
                        local oki, item = pcall(m.DB.GetItem, m.DB, o.Id)
                        if oki and type(item) == "table" then
                            for i, npc in ipairs(type(item.npcDrops) == "table" and item.npcDrops or {}) do
                                if i > 12 then break end
                                spawnsOf(m, "npc", npc, out)
                            end
                            for i, obj in ipairs(type(item.objectDrops) == "table" and item.objectDrops or {}) do
                                if i > 12 then break end
                                spawnsOf(m, "object", obj, out)
                            end
                        end
                    end
                end
            end
        end
    end
    if #out > 0 then cache.spot[key] = out else cache.miss[key] = now end   -- asked again in 30 seconds
    return out
end

-- The spot closest to (map, x, y), else the first on that map, else the first.
function QB.Spot(qid, which, map, x, y)
    local list = QB.Spots(qid, which)
    if #list == 0 then return nil end
    local best, bestD
    for _, s in ipairs(list) do
        if map and s.map == map then
            local d = (x and y) and ((s.x - x) ^ 2 + (s.y - y) ^ 2) or 0
            if not bestD or d < bestD then best, bestD = s, d end
        end
    end
    return best or list[1]
end

---------------------------------------------------------------------------
-- Quest status: works without Questie too (the game knows what you've done)
---------------------------------------------------------------------------
function QB.Done(qid)
    qid = tonumber(qid)
    if not qid then return false end
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local ok, done = pcall(C_QuestLog.IsQuestFlaggedCompleted, qid)
        if ok and done then return true end
    elseif IsQuestFlaggedCompleted then
        local ok, done = pcall(IsQuestFlaggedCompleted, qid)
        if ok and done then return true end
    end
    local char = type(Questie) == "table" and type(Questie.db) == "table" and type(Questie.db.char) == "table" and Questie.db.char.complete
    return type(char) == "table" and char[qid] and true or false
end

-- Your quest log: { { id, title, ready }, ... }
function QB.Log()
    local out = {}
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and info.questID and info.title then
                local ready = C_QuestLog.IsComplete and C_QuestLog.IsComplete(info.questID) or false
                out[#out + 1] = { id = info.questID, title = info.title, ready = ready and true or false, level = info.level }
            end
        end
    elseif GetNumQuestLogEntries and GetQuestLogTitle then
        for i = 1, GetNumQuestLogEntries() do
            local title, level, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
            if title and not isHeader and questID then
                out[#out + 1] = { id = questID, title = title, ready = isComplete == 1 or isComplete == true, level = level }
            end
        end
    end
    return out
end

function QB.InLog(qid)
    qid = tonumber(qid)
    for _, q in ipairs(QB.Log()) do if q.id == qid then return true, q.ready end end
    return false, false
end

---------------------------------------------------------------------------
-- Drafting a route from Questie: the quests you can do in your zone at your
-- level, in a nearest-first order (accept them all, do them, hand them in).
---------------------------------------------------------------------------
local function near(list, map, x, y)
    -- order spots nearest-neighbour from (x, y)
    local out, left = {}, {}
    for i, e in ipairs(list) do left[i] = e end
    while #left > 0 do
        local bi, bd = 1, nil
        for i, e in ipairs(left) do
            local d = (e.at.x - x) ^ 2 + (e.at.y - y) ^ 2
            if not bd or d < bd then bi, bd = i, d end
        end
        local e = table.remove(left, bi)
        out[#out + 1] = e
        x, y = e.at.x, e.at.y
    end
    return out
end

-- Returns a route table, or nil and a reason.
function QB.DraftRoute(uiMap, level, px, py)
    local m = db()
    if not m then return nil, "Questie isn't installed or hasn't loaded yet." end
    if type(m.DB.QuestPointers) ~= "table" or type(m.DB.QueryQuestSingle) ~= "function" then
        return nil, "this version of Questie doesn't offer its quest list."
    end
    local okA, areaId = pcall(m.Zone.GetAreaIdByUiMapId, m.Zone, uiMap)
    if not okA or not areaId then return nil, "Questie doesn't know this zone." end
    level = level or 1
    local picks = {}
    for qid in pairs(m.DB.QuestPointers) do
        local okz, zone = pcall(m.DB.QueryQuestSingle, qid, "zoneOrSort")
        if okz and zone == areaId and not QB.Done(qid) then
            local okd, doable = true, true
            if type(m.DB.IsDoable) == "function" then okd, doable = pcall(m.DB.IsDoable, qid) end
            local info = QB.Quest(qid)
            if okd and doable and info and info.level and info.level <= level + 3 and info.level >= level - 4 then
                local s = QB.Spot(qid, "start", uiMap, px, py)
                local f = QB.Spot(qid, "finish", uiMap, px, py)
                if s and f and s.map == uiMap and f.map == uiMap then picks[#picks + 1] = { info = info, s = s, f = f } end
            end
        end
        if #picks >= 30 then break end
    end
    if #picks == 0 then return nil, "Questie lists no quests for your level here that you haven't done." end
    table.sort(picks, function(a, b) return a.info.level < b.info.level end)
    local zoneName
    local mi = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(uiMap)
    zoneName = mi and mi.name or "Zone"
    local function at(spot) return { zone = zoneName, x = math.floor(spot.x * 1000 + 0.5) / 10, y = math.floor(spot.y * 1000 + 0.5) / 10 } end
    local accepts, dos, turnins = {}, {}, {}
    for _, p in ipairs(picks) do
        local q = p.info
        accepts[#accepts + 1] = { act = "accept", quest = q.name, qid = q.id, text = (q.starts[1] or "") .. ".", at = at(p.s) }
        local o = QB.Spot(q.id, "objective", uiMap, p.s.x, p.s.y)
        if o and o.map == uiMap then
            dos[#dos + 1] = { act = "complete", quest = q.name, qid = q.id, text = (q.objectives[1] or ""):sub(1, 120), at = at(o) }
        end
        turnins[#turnins + 1] = { act = "turnin", quest = q.name, qid = q.id, text = (q.ends[1] or "") .. ".", at = at(p.f) }
    end
    local x, y = (px or 0.5) * 100, (py or 0.5) * 100
    local steps = {}
    for _, list in ipairs({ accepts, dos, turnins }) do
        for _, s in ipairs(near(list, uiMap, x, y)) do
            steps[#steps + 1] = s
            x, y = s.at.x, s.at.y
        end
    end
    return { title = (zoneName .. " (Questie draft)"):sub(1, 40), faction = UnitFactionGroup and UnitFactionGroup("player") or "Any",
             author = "Questie draft", steps = steps, draft = true }
end
