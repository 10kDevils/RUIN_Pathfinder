-- RUIN Pathfinder: the quest database
-- Pathfinder reads RUIN Quest Data (the database addon that ships with the
-- suite): where a quest starts, where it is handed in, where its targets are,
-- its level and objectives, which quests you have finished, and which quests
-- are available in your zone.
-- Every call is guarded: if the database is missing, these functions return
-- nil and Pathfinder carries on without it.
--
-- The tables it reads (RUIN_QuestData.q / n / o / i, with the column names in
-- RUIN_QuestData.fields) are turned into one shape here:
--   DB.GetQuest(id)  -> { name, level, requiredLevel, Starts = { NPC, GameObject },
--                         Finisher = { NPC, GameObject }, ObjectiveData, objectivesText, zoneOrSort }
--   DB:GetNPC(id) / DB:GetObject(id) / DB:GetItem(id) -> { name, spawns = { [areaId] = { {x, y}, ... } } }
--   DB.QuestPointers, DB.QueryQuestSingle(id, field), DB.IsDoable(id)
--   Zone:GetUiMapIdByAreaId(areaId), Zone:GetAreaIdByUiMapId(uiMapId)
local ADDON, ns = ...

local QB = {}
ns.QB = QB

local cache = { quest = {}, spot = {}, miss = {} }
local modules

local OBJECTIVE_KINDS = { "monster", "object", "item" }     -- the positional objective groups 1-3

-- Quest, NPC, object and item tables that answer Get(id, field) and
-- Exists(id); the rest of Pathfinder reads the shape below.
local function adapt(Q, N, O, I, toMap, toArea, source)
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
                 Starts = { NPC = starts[1], GameObject = starts[2], Item = starts[3] }, Finisher = { NPC = ends[1], GameObject = ends[2] },
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
    return { DB = DB, Zone = Zone, source = source }
end

-- RUIN Quest Data: positional rows, with the field names in
-- RUIN_QuestData.fields.
local function fromRUIN()
    local D = rawget(_G, "RUIN_QuestData")
    if type(D) ~= "table" or type(D.q) ~= "table" or type(D.fields) ~= "table" or next(D.q) == nil then return nil end
    -- the rows that differ for your faction (the data is Alliance's otherwise)
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if not D.applied and type(faction) == "string" then
        local put = type(D.faction) == "table" and D.faction[faction]
        if type(put) == "function" then pcall(put, D.q, D.n or {}, D.o or {}, D.i or {}) end
        D.applied = faction
    end
    local function table_(rows, names)
        local col = {}
        for i, f in ipairs(names or {}) do col[f] = i end
        local T = {}
        function T.Exists(id) return rows[id] ~= nil end
        function T.Get(id, field)
            local r, c = rows[id], col[field]
            if r and c then return r[c] end
        end
        function T.GetAllIds() return rows end
        return T
    end
    local F = D.fields
    local z = D.z or {}
    return adapt(table_(D.q, F.Q), table_(D.n or {}, F.N), table_(D.o or {}, F.O), table_(D.i or {}, F.I),
        z.areaToMap or {}, z.mapToArea or {}, "RUIN Quest Data")
end

local function db()
    if modules ~= nil then return modules or nil end
    local ok, fromData = pcall(fromRUIN)
    if ok and fromData then modules = fromData; return modules end
    return nil
end

-- "RUIN Quest Data" when the database is loaded, or nil.
function QB.Source()
    local m = db()
    return m and m.source or nil
end

-- Is the quest database loaded?
function QB.Has()
    return db() ~= nil
end

local zoneIndex      -- area ID -> { quest IDs }, built the first time a dungeon asks
local zoneList       -- QB.Zones(), built once
function QB.Forget() cache = { quest = {}, spot = {}, miss = {} }; modules = nil; zoneIndex = nil; zoneList = nil end

-- What the database knows about a quest:
-- { id, name, level, req, starts = { names }, ends = { names }, objectives = { text }, zone }
function QB.Quest(qid)
    qid = tonumber(qid)
    if not qid then return nil end
    local hit = cache.quest[qid]
    if hit ~= nil then return hit or nil end
    local m = db()
    if not m then return nil end
    local ok, q = pcall(m.DB.GetQuest, qid)
    if not ok or type(q) ~= "table" then return nil end      -- not in the database
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
    -- where RUIN members actually picked it up, did it and handed it in on
    -- WoW Forever (Pathfinder's atlas) comes first; the database fills the gaps
    local seen = ns.AtlasSpots and ns.AtlasSpots(qid, which)
    if seen and #seen > 0 and (which ~= "objective" or #seen >= 3) then
        -- a pick-up or hand-in seen twice or more is where it is
        if which ~= "objective" and (seen[1].seen or 1) >= 2 then cache.spot[key] = seen; return seen end
    else
        seen = nil
    end
    local m = db()
    if not m then
        if seen then cache.spot[key] = seen; return seen end
        return {}
    end
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
    if seen then
        local merged = {}
        for _, sp in ipairs(seen) do merged[#merged + 1] = sp end
        for _, sp in ipairs(out) do merged[#merged + 1] = sp end
        out = merged
    end
    if #out > 0 then cache.spot[key] = out else cache.miss[key] = now end   -- asked again in 30 seconds
    return out
end

-- The atlas learned something new about a quest: ask again.
function QB.ForgetSpots(qid)
    for _, which in ipairs({ "start", "finish", "objective" }) do
        cache.spot[which .. ":" .. qid] = nil
        cache.miss[which .. ":" .. qid] = nil
    end
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
-- Quest status: the game knows what you've done
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
    return false
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
-- Drafting a route from the database: the quests you can do in your zone at your
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
    if not m then return nil, "No quest database is loaded (enable RUIN Quest Data)." end
    if type(m.DB.QuestPointers) ~= "table" or type(m.DB.QueryQuestSingle) ~= "function" then
        return nil, "the quest database has no quest list."
    end
    local okA, areaId = pcall(m.Zone.GetAreaIdByUiMapId, m.Zone, uiMap)
    if not okA or not areaId then return nil, "The quest database doesn't know this zone." end
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
    if #picks == 0 then return nil, "The quest database lists no quests for your level here that you haven't done." end
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
    return { title = (zoneName .. " (draft)"):sub(1, 40), faction = UnitFactionGroup and UnitFactionGroup("player") or "Any",
             author = "RUIN draft", steps = steps, draft = true }
end

---------------------------------------------------------------------------
-- Dungeon quests: every quest a dungeon has for your race and class, the
-- quests you must do first to unlock them, and a route through them all.
-- Which quests belong to a dungeon comes from ns.DungeonQuestIndex (its zone
-- IDs, plus quests filed under a city); the rest is the database's.
---------------------------------------------------------------------------
-- One field of a quest (the database's field names), or nil.
function QB.Field(qid, field)
    local m = db()
    if not m or type(m.DB.QueryQuestSingle) ~= "function" then return nil end
    local ok, v = pcall(m.DB.QueryQuestSingle, qid, field)
    if ok then return v end
end

local function areaQuests()
    if zoneIndex then return zoneIndex end
    local m = db()
    if not m or type(m.DB.QuestPointers) ~= "table" or type(m.DB.QueryQuestSingle) ~= "function" then return nil end
    zoneIndex = {}
    for qid in pairs(m.DB.QuestPointers) do
        local ok, z = pcall(m.DB.QueryQuestSingle, qid, "zoneOrSort")
        if ok and type(z) == "number" and z > 0 then
            local list = zoneIndex[z] or {}
            list[#list + 1] = qid
            zoneIndex[z] = list
        end
    end
    return zoneIndex
end

-- Race and class masks: bit n-1 for race or class ID n; 0 or none is everyone.
local function maskAllows(mask, unitFn)
    mask = tonumber(mask)
    if not mask or mask == 0 or not unitFn then return true end
    local _, _, n = unitFn("player")
    n = tonumber(n)
    if not n then return true end
    return math.floor(mask / 2 ^ (n - 1)) % 2 == 1
end

-- Is this quest one your character can ever take (race and class)?
function QB.ForMe(qid)
    if type(qid) ~= "number" or not QB.Field(qid, "name") then return false end
    return maskAllows(QB.Field(qid, "requiredClasses"), UnitClass) and maskAllows(QB.Field(qid, "requiredRaces"), UnitRace)
end

local function ids(v)
    local out = {}
    for _, id in ipairs(type(v) == "table" and v or {}) do
        id = tonumber(id)
        if id and id > 0 then out[#out + 1] = id end      -- a negative ID is a quest you must not have done
    end
    return out
end

-- The quests to do before qid, deepest first (qid itself not included):
-- every quest of its group prerequisites, and one of its single ones (none
-- when you've done any of them; else the first your character can take).
function QB.Prereqs(qid)
    local order, added, seen = {}, {}, {}
    local function add(id) if not added[id] then added[id] = true; order[#order + 1] = id end end
    local function visit(id, depth)
        if seen[id] or depth > 12 then return end
        seen[id] = true
        for _, p in ipairs(ids(QB.Field(id, "preQuestGroup"))) do
            if QB.ForMe(p) then visit(p, depth + 1); add(p) end
        end
        -- order the database doesn't record yet (Routes.lua)
        for _, p in ipairs(ns.QuestPrereqHints and ns.QuestPrereqHints[id] or {}) do
            if not added[p] and QB.ForMe(p) then visit(p, depth + 1); add(p) end
        end
        local single = ids(QB.Field(id, "preQuestSingle"))
        if #single > 0 then
            local done, pick = false, nil
            for _, p in ipairs(single) do if QB.Done(p) then done = true; pick = p; break end end
            if not done then
                for _, p in ipairs(single) do if QB.ForMe(p) then pick = p; break end end
            end
            if pick then visit(pick, depth + 1); add(pick) end
        end
    end
    visit(qid, 0)
    return order
end

-- Where a quest giver or hand-in stands: the area IDs of its spawns.
local function giverAreas(qid, which)
    local m = db()
    if not m then return {} end
    local ok, q = pcall(m.DB.GetQuest, qid)
    if not ok or type(q) ~= "table" then return {} end
    local by = which == "start" and q.Starts or q.Finisher
    by = type(by) == "table" and by or {}
    local out = {}
    local function from(kind, list)
        for _, id in ipairs(type(list) == "table" and list or {}) do
            local okr, rec
            if kind == "npc" then okr, rec = pcall(m.DB.GetNPC, m.DB, id) else okr, rec = pcall(m.DB.GetObject, m.DB, id) end
            if okr and type(rec) == "table" and type(rec.spawns) == "table" then
                for area in pairs(rec.spawns) do out[area] = true end
            end
        end
    end
    from("npc", by.NPC)
    from("object", by.GameObject)
    return out
end

-- The item that starts a quest (looted, then right-clicked), if any:
-- its ID, its name, and what drops it (an NPC's or object's name).
function QB.StartItem(qid)
    local m = db()
    if not m then return nil end
    local ok, q = pcall(m.DB.GetQuest, qid)
    local list = ok and type(q) == "table" and type(q.Starts) == "table" and q.Starts.Item
    if type(list) ~= "table" then
        local by = QB.Field(qid, "startedBy")
        list = type(by) == "table" and by[3] or nil
    end
    local id = type(list) == "table" and tonumber(list[1]) or nil
    if not id then return nil end
    local okI, rec = pcall(m.DB.GetItem, m.DB, id)
    if not okI or type(rec) ~= "table" then return id end
    local from, kind
    local npc = type(rec.npcDrops) == "table" and tonumber(rec.npcDrops[1])
    local obj = type(rec.objectDrops) == "table" and tonumber(rec.objectDrops[1])
    if npc then
        local okn, n = pcall(m.DB.GetNPC, m.DB, npc)
        from, kind = okn and type(n) == "table" and n.name or nil, "npc"
    elseif obj then
        local oko, o = pcall(m.DB.GetObject, m.DB, obj)
        from, kind = oko and type(o) == "table" and o.name or nil, "object"
    end
    return id, rec.name, from, kind
end

-- Does a quest have anything to do besides talking to someone (kill,
-- collect, use)? Delivery quests don't get a "Do" step. The database leaves some
-- new quests' objectives out; their text decides then.
local DELIVERY = { "^deliver", "^bring ", "^take ", "^speak", "^talk", "^report", "^return", "^travel", "^seek",
                   "talk to ", "speak with ", "speak to ", "report to ", "deliver " }
local function hasObjectives(qid)
    local o = QB.Field(qid, "objectives")
    if type(o) == "table" then
        for _, group in pairs(o) do
            if type(group) == "table" and next(group) ~= nil then return true end
        end
        return false
    end
    local t = QB.Field(qid, "objectivesText")
    t = type(t) == "table" and t[1]
    if type(t) ~= "string" or t == "" then return false end
    local low = t:lower()
    for _, pat in ipairs(DELIVERY) do if low:find(pat) then return false end end
    return true
end
QB.HasObjectives = hasObjectives

-- done, ready (in your log and complete), active (in your log), low (you
-- need more levels), locked (a quest before it isn't done), or available.
function QB.State(qid, pre)
    if QB.Done(qid) then return "done" end
    local inLog, ready = QB.InLog(qid)
    if inLog then return ready and "ready" or "active" end
    local req = tonumber(QB.Field(qid, "requiredLevel"))
    local level = UnitLevel and UnitLevel("player") or 1
    for _, p in ipairs(pre or QB.Prereqs(qid)) do
        if not QB.Done(p) then return "locked" end
    end
    if req and level < req then return "low" end
    return "available"
end

-- Step texts: who gives a quest, where it's handed in, what to do.
local function firstOf(list) return type(list) == "table" and list[1] or nil end
local function giverHint(qid) return ns.QuestGiverHints and ns.QuestGiverHints[qid] end
function QB.AcceptText(qid)
    local i = QB.Quest(qid)
    local who = i and firstOf(i.starts) or (giverHint(qid) and giverHint(qid).starts)
    if who then return who .. "." end
    local _, item, from, kind = QB.StartItem(qid)
    if item then
        local src = from and (kind == "object" and (" (found on " .. from .. ")") or (" (drops from " .. from .. ")")) or ""
        return "Starts from " .. item .. src .. "."
    end
    return "No giver is known for this quest yet."
end
function QB.TurninText(qid)
    local i = QB.Quest(qid)
    local who = i and firstOf(i.ends) or (giverHint(qid) and giverHint(qid).ends)
    return who and (who .. ".") or "No hand-in place is known for this quest yet."
end
function QB.DoText(qid)
    if not hasObjectives(qid) then return "" end
    local i = QB.Quest(qid)
    return i and i.objectives[1] or ""
end

-- A dungeon's quests for your character, by level:
-- { { id, name, level, req, state, pre = { ids }, starts = { names }, ends = { names },
--     item = item name when an item starts it, inside = starts in the dungeon,
--     endsInside = handed in in the dungeon, objective }, ... }
-- or nil and a reason.
function QB.DungeonQuests(entry)
    if type(entry) ~= "table" then return nil, "unknown dungeon" end
    local m = db()
    if not m then return nil, "No quest database is loaded (enable RUIN Quest Data)." end
    local byArea = areaQuests()
    if not byArea then return nil, "the quest database has no quest list." end
    local areas, list, seen = {}, {}, {}
    for _, a in ipairs(entry.areas or {}) do areas[a] = true end
    local function consider(qid)
        if seen[qid] then return end
        seen[qid] = true
        if not QB.ForMe(qid) then return end
        local info = QB.Quest(qid)
        if not info or type(info.name) ~= "string" then return end
        local pre = QB.Prereqs(qid)
        local hint = ns.QuestGiverHints and ns.QuestGiverHints[qid]
        local inside, endsInside = hint and hint.inside or false, hint and hint.inside or false
        for a in pairs(giverAreas(qid, "start")) do if areas[a] then inside = true end end
        for a in pairs(giverAreas(qid, "finish")) do if areas[a] then endsInside = true end end
        local _, itemName, itemFrom = QB.StartItem(qid)
        list[#list + 1] = { id = qid, name = info.name, level = info.level, req = info.req, state = QB.State(qid, pre), pre = pre,
                            starts = info.starts, ends = info.ends, item = (#info.starts == 0) and itemName or nil,
                            itemFrom = (#info.starts == 0) and itemFrom or nil,
                            inside = inside, endsInside = endsInside, objective = info.objectives[1] }
    end
    for _, a in ipairs(entry.areas or {}) do
        for _, qid in ipairs(byArea[a] or {}) do consider(qid) end
    end
    for _, qid in ipairs(entry.extra or {}) do consider(qid) end
    table.sort(list, function(a, b)
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
        return a.id < b.id
    end)
    return list
end

-- A route through a dungeon's quests: the quests that unlock them first (in
-- order), then every quest to pick up outside, the run itself (quests picked
-- up and handed in inside, and what to do), and the hand-ins after.
function QB.DungeonRoute(entry, quests)
    quests = quests or QB.DungeonQuests(entry)
    if not quests or #quests == 0 then return nil end
    local map, px, py = nil, nil, nil
    if RUIN_API and RUIN_API.Map and RUIN_API.Map.PlayerPos then map, px, py = RUIN_API.Map:PlayerPos() end
    local isDungeonQuest, before, seenPre = {}, {}, {}
    for _, q in ipairs(quests) do isDungeonQuest[q.id] = true end
    for _, q in ipairs(quests) do
        for _, p in ipairs(q.pre) do
            if not isDungeonQuest[p] and not seenPre[p] then seenPre[p] = true; before[#before + 1] = p end
        end
    end
    local steps = {}
    local function name(qid) local i = QB.Quest(qid); return i and i.name or ("Quest " .. qid) end
    local function first(list) return type(list) == "table" and list[1] or nil end
    local function step(act, qid, text)
        steps[#steps + 1] = { act = act, quest = name(qid), qid = qid, text = (text or ""):sub(1, 120) }
    end
    local acceptText, turninText, doText = QB.AcceptText, QB.TurninText, QB.DoText
    -- order quests nearest-first, by map then distance, from where you stand
    local cm, cx, cy = map, px or 0.5, py or 0.5     -- where the route has got to
    local function nearest(list, which)
        local placed, rest = {}, {}
        for _, qid in ipairs(list) do
            local s = QB.Spot(qid, which, map, px, py)
            if s then placed[#placed + 1] = { qid = qid, s = s } else rest[#rest + 1] = qid end
        end
        local out = {}
        while #placed > 0 do
            local bi, bd
            for i, e in ipairs(placed) do
                local d = (e.s.map == cm and 0 or 10) + (e.s.x - cx) ^ 2 + (e.s.y - cy) ^ 2
                if not bd or d < bd then bi, bd = i, d end
            end
            local e = table.remove(placed, bi)
            out[#out + 1] = e.qid
            cm, cx, cy = e.s.map, e.s.x, e.s.y
        end
        for _, qid in ipairs(rest) do out[#out + 1] = qid end
        return out
    end
    -- 1. the quests that unlock the dungeon's, in the order they need
    for _, p in ipairs(before) do
        step("accept", p, acceptText(p))
        if doText(p) ~= "" then step("complete", p, doText(p)) end
        step("turnin", p, turninText(p))
        local f = QB.Spot(p, "finish", cm, cx, cy)
        if f then cm, cx, cy = f.map, f.x, f.y end
    end
    -- 2. pick up the dungeon's quests outside. A quest that follows another
    -- of the dungeon's quests (Friend of the Kirin Tor after Heart of
    -- Disruption) waits until that one is handed in.
    local outside, inside, handOut, handIn, after = {}, {}, {}, {}, {}
    for _, q in ipairs(quests) do
        local follows = false
        for _, p in ipairs(q.pre) do if isDungeonQuest[p] then follows = true end end
        if follows then
            after[#after + 1] = q
        else
            if q.inside or (q.item and #q.starts == 0) then inside[#inside + 1] = q.id else outside[#outside + 1] = q.id end
            if q.endsInside then handIn[#handIn + 1] = q.id else handOut[#handOut + 1] = q.id end
        end
    end
    local isAfter = {}
    for _, q in ipairs(after) do isAfter[q.id] = true end
    for _, qid in ipairs(nearest(outside, "start")) do step("accept", qid, acceptText(qid)) end
    -- 3. the run
    steps[#steps + 1] = { act = "note", text = ("Run %s (levels %s): the quests below are done inside."):format(entry.name, entry.levels or "?") }
    for _, qid in ipairs(inside) do step("accept", qid, acceptText(qid)) end
    for _, q in ipairs(quests) do
        local t = not isAfter[q.id] and doText(q.id) or ""
        if t ~= "" then step("complete", q.id, t) end
    end
    for _, qid in ipairs(handIn) do step("turnin", qid, turninText(qid)) end
    -- 4. hand in the rest
    for _, qid in ipairs(nearest(handOut, "finish")) do step("turnin", qid, turninText(qid)) end
    -- 5. the follow-ups, each once the quest before it is in
    for _, q in ipairs(after) do
        step("accept", q.id, acceptText(q.id))
        local t = doText(q.id)
        if t ~= "" then step("complete", q.id, t) end
        step("turnin", q.id, turninText(q.id))
    end
    return steps
end

---------------------------------------------------------------------------
-- Zone quest routes: every zone the database has quests in, split into
-- routes of ZONE_CHUNK quests by level. Built from the database in game, so a
-- zone the hand-written routes don't cover still gets one.
---------------------------------------------------------------------------
local ZONE_CHUNK = 18
local MIN_ZONE_QUESTS = 3
QB.ZONE_CHUNK = ZONE_CHUNK

-- Cities and battlegrounds get no zone route: their quests are hand-ins and
-- class quests scattered across the world, or PvP.
local NO_ZONE_ROUTE = {
    [1519] = true, [1537] = true, [1657] = true, [3557] = true,    -- Stormwind, Ironforge, Darnassus, Exodar
    [1637] = true, [1638] = true, [1497] = true, [3487] = true,    -- Orgrimmar, Thunder Bluff, Undercity, Silvermoon
    [3703] = true, [4395] = true, [2257] = true,                   -- Shattrath, Dalaran (Northrend), Deeprun Tram
    [2597] = true, [3277] = true, [3358] = true, [3820] = true,    -- Alterac Valley, Warsong Gulch, Arathi Basin, Eye of the Storm
    [4384] = true, [4710] = true,                                  -- Strand of the Ancients, Isle of Conquest
}
QB.NO_ZONE_ROUTE = NO_ZONE_ROUTE

local function dungeonAreas()
    local out = {}
    for a in pairs(NO_ZONE_ROUTE) do out[a] = true end
    for _, e in ipairs(ns.DungeonQuestIndex or {}) do
        for _, a in ipairs(e.areas or {}) do out[a] = true end
    end
    return out
end

function QB.AreaName(area)
    local name = C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(area)
    if type(name) == "string" and name ~= "" then return name end
    return "Zone " .. tostring(area)
end

local function repeatable(qid)
    local f = tonumber(QB.Field(qid, "specialFlags"))
    return f and f % 2 == 1
end

-- A zone's quests for your character, by level: { { id, level }, ... }
function QB.ZoneQuests(area)
    local byArea = areaQuests()
    if not byArea then return {} end
    local list = {}
    for _, qid in ipairs(byArea[area] or {}) do
        if QB.ForMe(qid) and not repeatable(qid) then
            list[#list + 1] = { id = qid, level = tonumber(QB.Field(qid, "questLevel")) or tonumber(QB.Field(qid, "requiredLevel")) or 0 }
        end
    end
    table.sort(list, function(a, b) if a.level ~= b.level then return a.level < b.level end return a.id < b.id end)
    return list
end

-- Every zone with quests for you, split into parts:
-- { { area, part, name, quests = { ids }, lo, hi }, ... } by level
function QB.Zones()
    if zoneList then return zoneList end
    local byArea = areaQuests()
    if not byArea then return {} end
    local skip = dungeonAreas()
    local out = {}
    for area in pairs(byArea) do
        if not skip[area] then
            local list = QB.ZoneQuests(area)
            if #list >= MIN_ZONE_QUESTS then
                local name = QB.AreaName(area)
                local parts = math.ceil(#list / ZONE_CHUNK)
                for k = 1, parts do
                    local ids, lo, hi = {}, nil, nil
                    for i = (k - 1) * ZONE_CHUNK + 1, math.min(k * ZONE_CHUNK, #list) do
                        local e = list[i]
                        ids[#ids + 1] = e.id
                        lo = lo and math.min(lo, e.level) or e.level
                        hi = hi and math.max(hi, e.level) or e.level
                    end
                    -- a short last part joins the one before it
                    if k == parts and k > 1 and #ids < MIN_ZONE_QUESTS then
                        local prev = out[#out]
                        for _, id in ipairs(ids) do prev.quests[#prev.quests + 1] = id end
                        prev.hi = math.max(prev.hi, hi)
                    else
                        out[#out + 1] = { area = area, part = k, name = name, quests = ids, lo = lo, hi = hi }
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if a.lo ~= b.lo then return a.lo < b.lo end
        if a.name ~= b.name then return a.name < b.name end
        return a.part < b.part
    end)
    zoneList = out
    return out
end

---------------------------------------------------------------------------
-- Route planning: the order to pick up, do and hand in a set of quests with
-- the least walking. Every quest is three stops (pick up, its objectives,
-- hand in) with the order a quest needs (pick up before doing before
-- handing in; a quest's earlier quests handed in before it's picked up).
-- A first pass always walks to the nearest stop that's allowed (so quest
-- givers standing together are picked up together, and objectives in the
-- same area are done one after another); then stops are moved wherever that
-- shortens the walk without breaking the order, which gathers hand-ins into
-- one visit and stops going back and forth.
---------------------------------------------------------------------------
local OTHER_MAP = 4000       -- yards a change of zone counts as
local SAME_STOP = 30         -- yards: closer than this is the same stop

-- yards across a map, for distances (cached per map)
local mapYards = {}
local function yardsPer(map)
    local m = mapYards[map]
    if m == nil then
        local Map = RUIN_API and RUIN_API.Map
        local w = Map and Map.Yards and Map:Yards(map, 0, 0, 1, 0)
        local h = Map and Map.Yards and Map:Yards(map, 0, 0, 0, 1)
        m = (w and h and w > 0 and h > 0) and { w, h } or { 4000, 2700 }
        mapYards[map] = m
    end
    return m
end
-- A stop's place in the world (continent and yards), looked up once: two
-- stops on different maps of one continent are as far apart as the world
-- says (Elwynn's edge to Westfall's is a short walk, not a trip across the
-- world); anything else counts as OTHER_MAP.
local function place(at)
    if at and at.wc == nil then
        local Map = RUIN_API and RUIN_API.Map
        local c, wx, wy
        if Map and Map.WorldPos then c, wx, wy = Map:WorldPos(at.map, at.x, at.y) end
        if c then at.wc, at.wx, at.wy = c, wx, wy else at.wc = false end
    end
end
local function dist(a, b)
    if not (a and b) then return 0 end                -- a stop we can't place costs nothing to reach
    if a.map ~= b.map then
        if a.wc and a.wc == b.wc then
            local dx, dy = a.wx - b.wx, a.wy - b.wy
            return math.min(OTHER_MAP * 2, math.sqrt(dx * dx + dy * dy))
        end
        return OTHER_MAP
    end
    local s = yardsPer(a.map)
    return math.sqrt(((a.x - b.x) * s[1]) ^ 2 + ((a.y - b.y) * s[2]) ^ 2)
end

-- Where a quest's objectives are best done: of the places its targets are,
-- the one with the most others nearby (the middle of the busiest area).
local function objectiveSpot(qid, near)
    local list = QB.Spots(qid, "objective")
    if #list == 0 then return nil end
    -- the map most of them are on (or the one you're on)
    local count, map = {}, nil
    for _, sp in ipairs(list) do count[sp.map] = (count[sp.map] or 0) + 1 end
    for m, n in pairs(count) do if not map or n > count[map] or (near and m == near.map and n == count[map]) then map = m end end
    local onMap = {}
    for _, sp in ipairs(list) do if sp.map == map then onMap[#onMap + 1] = sp end end
    if #onMap <= 2 then return onMap[1] end
    local step = math.max(1, math.floor(#onMap / 40))  -- big lists: a sample is plenty
    local best, bestN
    for i = 1, #onMap, step do
        local a, n = onMap[i], 0
        for j = 1, #onMap, step do if dist(a, onMap[j]) < 150 then n = n + 1 end end
        if not bestN or n > bestN then best, bestN = a, n end
    end
    return best
end
QB.ObjectiveSpot = objectiveSpot

-- What a quest's objectives are done on: the NPCs and objects it needs
-- killed, used or looted (an item counts as the NPCs and objects it drops
-- from), as a set of "n<id>" / "o<id>" keys.
function QB.Targets(qid)
    local m = db()
    local out = {}
    if not m then return out end
    local ok, q = pcall(m.DB.GetQuest, qid)
    if not (ok and type(q) == "table") then return out end
    for _, o in ipairs(type(q.ObjectiveData) == "table" and q.ObjectiveData or {}) do
        if type(o) == "table" and o.Id then
            if o.Type == "monster" then out["n" .. o.Id] = true
            elseif o.Type == "object" then out["o" .. o.Id] = true
            elseif o.Type == "item" then
                local oki, item = pcall(m.DB.GetItem, m.DB, o.Id)
                if oki and type(item) == "table" then
                    for _, n in ipairs(type(item.npcDrops) == "table" and item.npcDrops or {}) do out["n" .. n] = true end
                    for _, b in ipairs(type(item.objectDrops) == "table" and item.objectDrops or {}) do out["o" .. b] = true end
                end
            end
        end
    end
    return out
end

-- Quests of the set that share a target are done as one stop: groups of
-- quest IDs (a quest alone is a group of one). Two quests where one leads to
-- the other are never put together (the later one can't be picked up yet).
local MAX_TOGETHER = 4
local function doGroups(list)
    local group, members, byTarget = {}, {}, {}
    local before = {}
    for _, q in ipairs(list) do
        group[q], members[q] = q, { q }
        before[q] = {}
        for _, p in ipairs(QB.Prereqs(q)) do before[q][p] = true end
    end
    local function linked(a, b)
        for _, x in ipairs(members[a]) do
            for _, y in ipairs(members[b]) do
                if before[x][y] or before[y][x] then return true end
            end
        end
    end
    for _, q in ipairs(list) do
        for key in pairs(QB.Targets(q)) do
            local other = byTarget[key]
            if not other then
                byTarget[key] = q
            else
                local ga, gb = group[other], group[q]
                if ga ~= gb and #members[ga] + #members[gb] <= MAX_TOGETHER and not linked(ga, gb) then
                    for _, x in ipairs(members[gb]) do group[x] = ga; members[ga][#members[ga] + 1] = x end
                    members[gb] = nil
                end
            end
        end
    end
    return group, members
end
QB.DoGroups = doGroups

-- Of a group's objective spots, the one nearest the rest.
local function groupSpot(qids, here)
    local spots = {}
    for _, q in ipairs(qids) do spots[#spots + 1] = objectiveSpot(q, here) end
    local best, bestD
    for _, a in pairs(spots) do
        local d = 0
        for _, b in pairs(spots) do d = d + dist(a, b) end
        if not bestD or d < bestD then best, bestD = a, d end
    end
    return best
end

-- tasks: { kind = "accept" | "complete" | "turnin", qid, qids (a shared
-- "complete": every quest done there), at = spot, after = { task indexes } }
local function buildTasks(qids, here)
    local tasks, index = {}, {}
    local inSet = {}
    for _, q in ipairs(qids) do inSet[q] = true end
    local function add(kind, qid, at)
        tasks[#tasks + 1] = { kind = kind, qid = qid, at = at, after = {} }
        index[kind .. qid] = #tasks
        return #tasks
    end
    local withDo = {}
    for _, q in ipairs(qids) do if QB.DoText(q) ~= "" then withDo[#withDo + 1] = q end end
    local group, members = doGroups(withDo)
    for _, q in ipairs(qids) do
        local a = add("accept", q, QB.Spot(q, "start", here and here.map, here and here.x, here and here.y))
        local prev = a
        if group[q] then
            local g = group[q]
            local d = index["complete" .. g]
            if not d then
                d = add("complete", g, nil)
                local list = members[g]
                if #list > 1 then tasks[d].qids = list end
                tasks[d].at = groupSpot(list, here)
            end
            index["complete" .. q] = d
            tasks[d].after[#tasks[d].after + 1] = a
            prev = d
        end
        local t = add("turnin", q, QB.Spot(q, "finish", here and here.map, here and here.x, here and here.y))
        tasks[t].after[#tasks[t].after + 1] = prev
    end
    -- a stop we can't place stands where the quest's previous stop was
    for k, t in ipairs(tasks) do
        if not t.at then
            local need = t.after[1]
            t.at = need and tasks[need].at or nil
            if not t.at and t.kind == "accept" then
                local tk = index["turnin" .. t.qid]
                t.at = tk and tasks[tk].at or here
            end
        end
    end
    for _, t in ipairs(tasks) do place(t.at) end
    place(here)
    -- earlier quests in the set are handed in before a quest is picked up
    for _, q in ipairs(qids) do
        for _, p in ipairs(QB.Prereqs(q)) do
            if inSet[p] then
                local a, t = index["accept" .. q], index["turnin" .. p]
                tasks[a].after[#tasks[a].after + 1] = t
            end
        end
    end
    return tasks
end

local function routeLength(tasks, order, here)
    local total, pos = 0, here
    for _, i in ipairs(order) do
        local at = tasks[i].at
        total = total + dist(pos, at)
        pos = at or pos
    end
    return total
end

-- is this order allowed (every task after the ones it needs)?
local function allowed(tasks, order)
    local seen = {}
    for _, i in ipairs(order) do
        for _, need in ipairs(tasks[i].after) do if not seen[need] then return false end end
        seen[i] = true
    end
    return true
end

-- First pass: always the nearest allowed stop. At the same stop, pick-ups
-- before objectives before hand-ins, and a hand-in before the pick-up it opens.
local KIND_RANK = { turnin = 1, accept = 2, complete = 3 }
local ANNEAL_PER_STOP, ANNEAL_MAX = 400, 24000      -- moves tried per stop, and at most
local function greedy(tasks, here)
    local done, order, pos = {}, {}, here
    for _ = 1, #tasks do
        local best, bestD
        for i, t in ipairs(tasks) do
            if not done[i] then
                local ok = true
                for _, need in ipairs(t.after) do if not done[need] then ok = false; break end end
                if ok then
                    local d = dist(pos, t.at)
                    if d < SAME_STOP then d = KIND_RANK[t.kind] * 0.01 end   -- same stop: hand in, pick up, then do
                    if not bestD or d < bestD then best, bestD = i, d end
                end
            end
        end
        if not best then break end
        done[best] = true
        order[#order + 1] = best
        pos = tasks[best].at or pos
    end
    return order
end

-- Second pass: move one stop, or a run of up to three, to wherever the walk
-- gets shorter and the order still holds; again until nothing helps. Each
-- move is costed by what changes at its two ends, so this stays quick.
local function improve(tasks, order, here, budget)
    local n = #order
    local function at(k) if k < 1 then return here end return tasks[order[k]].at end
    local passes, improved = 0, true
    while improved and passes < (budget or 40) do
        improved, passes = false, passes + 1
        for len = 1, 3 do
            local i = 1
            while i <= n - len + 1 do
                local first, last = at(i), at(i + len - 1)
                local prev, nxt = at(i - 1), (i + len <= n) and at(i + len) or nil
                -- taking the run out
                local gain = dist(prev, first) + (nxt and (dist(last, nxt) - dist(prev, nxt)) or 0)
                local moved = false
                for j = 0, n do
                    -- put it between order[j] and order[j + 1] (in the original numbering), outside the run
                    if j < i - 1 or j > i + len - 1 then
                        local a, b = at(j), (j + 1 <= n) and at(j + 1) or nil
                        if j + 1 >= i and j + 1 <= i + len - 1 then b = nxt end
                        local cost = dist(a, first) + (b and (dist(last, b) - dist(a, b)) or 0)
                        if cost + 1 < gain then
                            local cand, run = {}, {}
                            for k = i, i + len - 1 do run[#run + 1] = order[k] end
                            for k = 1, n do
                                if k < i or k > i + len - 1 then cand[#cand + 1] = order[k] end
                                if k == j then for _, v in ipairs(run) do cand[#cand + 1] = v end end
                            end
                            if j == 0 then
                                local c2 = {}
                                for _, v in ipairs(run) do c2[#c2 + 1] = v end
                                for _, v in ipairs(cand) do c2[#c2 + 1] = v end
                                cand = c2
                            end
                            if #cand == n and allowed(tasks, cand) then
                                order, improved, moved = cand, true, true
                                break
                            end
                        end
                    end
                end
                if not moved then i = i + 1 end
            end
        end
    end
    return order, routeLength(tasks, order, here)
end

-- Third pass: simulated annealing over the order. A random stop is moved to
-- a random place; a shorter walk is always kept, a longer one sometimes (less
-- and less as it cools), and only orders the quest rules allow are tried. It
-- starts from the best order found so far and never returns anything longer.
-- A fixed seed makes the same set of quests give the same route every time.
local function anneal(tasks, order, here, iterations)
    local n = #order
    if n < 4 then return order, routeLength(tasks, order, here) end
    local seed = 12345 + n
    local function rnd(m)
        seed = (seed * 1103515245 + 12345) % 2147483648
        return 1 + math.floor(seed / 2147483648 * m)
    end
    local function unit() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
    local cur, curL = order, routeLength(tasks, order, here)
    local best, bestL = cur, curL
    local temp = math.max(curL / n / 3, 1)
    local cool = (1 / temp) ^ (1 / iterations)           -- cools to a temperature of 1 yard
    for _ = 1, iterations do
        local i, j = rnd(n), rnd(n)
        if i ~= j then
            local cand = {}
            for k = 1, n do cand[k] = cur[k] end
            local v = table.remove(cand, i)
            table.insert(cand, j, v)
            if allowed(tasks, cand) then
                local L = routeLength(tasks, cand, here)
                if L < curL or unit() < math.exp((curL - L) / temp) then
                    cur, curL = cand, L
                    if L < bestL then best, bestL = cand, L end
                end
            end
        end
        temp = temp * cool
    end
    return best, bestL
end

QB.Planner = { build = buildTasks, length = routeLength, allowed = allowed, greedy = greedy, improve = improve, anneal = anneal, dist = dist }

-- Plans a set of quests from where you stand: the ordered tasks, and the walk in yards.
function QB.Plan(qids, here)
    local tasks = buildTasks(qids, here)
    if #tasks == 0 then return {}, 0 end
    local order = greedy(tasks, here)
    local before = routeLength(tasks, order, here)
    local budget = #tasks > 60 and 6 or 40               -- big sets: fewer passes, still most of the gain
    local better, length = improve(tasks, order, here, budget)
    -- then a search over the whole order, within a fixed amount of work
    local iterations = math.min(ANNEAL_MAX, ANNEAL_PER_STOP * #tasks, math.floor(1500000 / #tasks))   -- about the same work however big the set
    if iterations >= 200 then
        local a, aLength = anneal(tasks, better, here, iterations)
        if aLength < length then
            better, length = improve(tasks, a, here, 6)
        end
    end
    local out = {}
    for _, i in ipairs(better) do out[#out + 1] = tasks[i] end
    return out, length, before
end

-- A route through one part of a zone: quests from elsewhere that unlock
-- these first, then the planned order of pick-ups, objectives and hand-ins.
function QB.ZoneRoute(qids)
    if type(qids) ~= "table" or #qids == 0 then return nil end
    local here
    if RUIN_API and RUIN_API.Map and RUIN_API.Map.PlayerPos then
        local map, px, py = RUIN_API.Map:PlayerPos()
        if map then here = { map = map, x = px, y = py } end
    end
    local inPart = {}
    for _, q in ipairs(qids) do inPart[q] = true end
    local steps = {}
    local function name(qid) local i = QB.Quest(qid); return i and i.name or ("Quest " .. qid) end
    local function step(act, qid, text)
        steps[#steps + 1] = { act = act, quest = name(qid), qid = qid, text = (text or ""):sub(1, 120) }
    end
    -- quests from other zones that come first, in the plan too
    local before, seen = {}, {}
    for _, q in ipairs(qids) do
        for _, p in ipairs(QB.Prereqs(q)) do
            if not inPart[p] and not seen[p] then
                seen[p] = true
                if QB.Field(p, "zoneOrSort") ~= QB.Field(q, "zoneOrSort") then before[#before + 1] = p end
            end
        end
    end
    -- the ones from other zones first (they're elsewhere), then the zone's own
    local function emit(plan)
        for _, t in ipairs(plan) do
            if t.qids then
                -- quests that share targets: one stop for all of them
                local names, texts = {}, {}
                for _, q in ipairs(t.qids) do
                    names[#names + 1] = name(q)
                    local d = QB.DoText(q)
                    if d ~= "" then texts[#texts + 1] = d end
                end
                steps[#steps + 1] = { act = "complete", quest = table.concat(names, " + "):sub(1, 60), qid = t.qids[1],
                                      qids = { unpack(t.qids) }, text = table.concat(texts, "; "):sub(1, 120) }
            else
                local text = t.kind == "accept" and QB.AcceptText(t.qid) or t.kind == "turnin" and QB.TurninText(t.qid) or QB.DoText(t.qid)
                step(t.kind, t.qid, text)
            end
            here = t.at or here
        end
    end
    if #before > 0 then emit((QB.Plan(before, here))) end
    emit((QB.Plan(qids, here)))
    return steps
end
