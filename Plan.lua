-- RUIN Pathfinder: what the planned levelling routes add
--   * Suggested for you: the planned route for your level (for your starting
--     area at level 1), at the top of the Routes page
--   * Start next: a planned route's last step offers 1-3 routes to start
--   * Session: pick how long you'll play and the Guide shows where to stop
--     (steps carry the planner's minutes and levels)
--   * Class quests: the next one for your class, on the Guide's class card
--   * Group quests: an Elite or Group quest on your step gets a Find group
--     button that lists you on RUIN Finder's board
--   * Party sync: in a party on the same route, you follow the leader's step
local ADDON, ns = ...
local R = RUIN_API
if not R then return end
local W = R.Widgets
local C = W.COLORS

local Plan = {}
ns.Plan = Plan
local M

local function db() return M and M.CharDB and M.CharDB() or {} end
local function level() return UnitLevel and UnitLevel("player") or 1 end

---------------------------------------------------------------------------
-- Suggested routes
---------------------------------------------------------------------------
-- the starting area for your race (level 1 routes)
local START_FOR = { Human = "a_01_northshire_valley", Dwarf = "a_01_coldridge_valley", Gnome = "a_01_coldridge_valley",
                    NightElf = "a_01_shadowglen" }

local function planned()
    local mine = UnitFactionGroup and UnitFactionGroup("player")
    local out = {}
    for _, r in ipairs(ns.Routes or {}) do
        if r.plan and (not mine or r.faction == mine) then out[#out + 1] = r end
    end
    return out
end
Plan.Planned = planned

-- 1-3 planned routes for a level: the bracket's best first, then its others
function Plan.Suggested(lvl)
    lvl = lvl or level()
    local list = {}
    for _, r in ipairs(planned()) do
        if r.startLevel and lvl >= r.startLevel and lvl < (r.endLevel or 60) then list[#list + 1] = r end
    end
    if #list == 0 then
        -- above every bracket's start: the last ones
        for _, r in ipairs(planned()) do if r.endLevel == 60 and lvl >= (r.startLevel or 0) then list[#list + 1] = r end end
    end
    local race
    if UnitRace then race = select(2, UnitRace("player")) end      -- not "UnitRace and UnitRace(...)": that keeps only the first value
    local startId = race and START_FOR[race]
    table.sort(list, function(a, b)
        if (a.id == startId) ~= (b.id == startId) then return a.id == startId end
        local aa, ba = a.id:find("_alt") ~= nil, b.id:find("_alt") ~= nil
        if aa ~= ba then return not aa end
        if (a.startLevel or 0) ~= (b.startLevel or 0) then return (a.startLevel or 0) > (b.startLevel or 0) end
        return (a.xph or 0) > (b.xph or 0)
    end)
    for i = #list, 4, -1 do list[i] = nil end
    return list
end

-- the routes a route's last step names, that exist
function Plan.Next(r)
    local out = {}
    for _, id in ipairs(r and r.next or {}) do
        local n = M and M:GetRoute(id)
        if n then out[#out + 1] = n end
    end
    return out
end

---------------------------------------------------------------------------
-- Session time budget
---------------------------------------------------------------------------
Plan.BUDGETS = { 0, 30, 60, 90, 120, 180, 240 }
function Plan.BudgetLabel(m)
    if not m or m == 0 then return "Session: whole route" end
    if m < 60 then return ("Session: %d min"):format(m) end
    return ("Session: %s h"):format((m % 60 == 0) and tostring(math.floor(m / 60)) or ("%.1f"):format(m / 60))
end

-- Where to stop: { step = index, level = lv } for a budget in minutes from
-- step `from`, or nil when the route has no times or no budget is set.
function Plan.StopAt(r, from, minutes)
    if not (r and r.plan and minutes and minutes > 0) then return nil end
    local start = r.steps[from] and r.steps[from].t
    if not start then return nil end
    local stop = #r.steps
    for i = from, #r.steps do
        local t = r.steps[i].t
        if t and t - start > minutes then stop = math.max(from, i - 1); break end
    end
    return { step = stop, level = r.steps[stop].lv }
end

-- minutes left on a planned route from step i
function Plan.MinutesLeft(r, i)
    if not (r and r.plan and r.steps[i] and r.steps[i].t) then return nil end
    return math.max(0, (r.minutes or r.steps[#r.steps].t or 0) - r.steps[i].t)
end

-- set at the step you're on when you pick it; told once when you reach it
function Plan.SetBudget(minutes)
    local d = db()
    d.budget = minutes ~= 0 and minutes or nil
    d.budgetFrom = d.step
    d.budgetToldAt = nil
end

function Plan.BudgetStop()
    local d = db()
    if not (d.budget and d.route) then return nil end
    local r = M:GetRoute(d.route)
    return Plan.StopAt(r, d.budgetFrom or d.step or 1, d.budget)
end

-- the tracker calls this when the step changes
function Plan.CheckBudget()
    local d, stop = db(), Plan.BudgetStop()
    if stop and d.step and d.step > stop.step and d.budgetToldAt ~= stop.step then
        d.budgetToldAt = stop.step
        M:Toast(("That's your session: about level %s. Good place to stop."):format(tostring(stop.level)), { sound = true })
    end
end

---------------------------------------------------------------------------
-- Class quests
---------------------------------------------------------------------------
-- The next class quest for you: { name, level, giver } or nil. Quests are
-- for your class in RUIN Quest Data, not done, from your level to 6 above.
local classCache
function Plan.ForgetClassQuests() classCache = nil end
function Plan.NextClassQuest(lvl)
    local QB = ns.QB
    if not (QB and QB.Has()) then return nil end
    lvl = lvl or level()
    local _, _, classId = UnitClass("player")
    if not classId then return nil end
    if not classCache or classCache.class ~= classId then
        classCache = { class = classId, list = {} }
        local D = RUIN_QuestData
        for qid in pairs(D and D.q or {}) do
            local mask = tonumber(QB.Field(qid, "requiredClasses")) or 0
            if mask ~= 0 and math.floor(mask / 2 ^ (classId - 1)) % 2 == 1 and QB.ForMe(qid) then
                local req = tonumber(QB.Field(qid, "requiredLevel")) or 1
                classCache.list[#classCache.list + 1] = { qid = qid, req = req }
            end
        end
        table.sort(classCache.list, function(a, b) if a.req ~= b.req then return a.req < b.req end return a.qid < b.qid end)
    end
    for _, e in ipairs(classCache.list) do
        if e.req >= lvl - 2 and e.req <= lvl + 6 and not QB.Done(e.qid) and not QB.InLog(e.qid) then
            local pre = QB.Prereqs(e.qid)
            local ready = true
            for _, p in ipairs(pre) do if not QB.Done(p) then ready = false; break end end
            if ready then
                local info = QB.Quest(e.qid)
                if info then return { qid = e.qid, name = info.name, level = e.req, giver = info.starts and info.starts[1] } end
            end
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Elite and group quests
---------------------------------------------------------------------------
-- "Elite", "Group" or "Dungeon" for a quest in your log that needs a group, else nil
function Plan.GroupTag(qid)
    if not qid then return nil end
    local name
    if C_QuestLog and C_QuestLog.GetQuestTagInfo then
        local ok, info = pcall(C_QuestLog.GetQuestTagInfo, qid)
        name = ok and type(info) == "table" and info.tagName or nil
    end
    if not name and GetQuestTagInfo then
        local ok, _, tagName = pcall(GetQuestTagInfo, qid)
        name = ok and tagName or nil
    end
    if type(name) ~= "string" then return nil end
    for _, t in ipairs({ "Elite", "Group", "Dungeon", "Raid" }) do
        if name:find(t, 1, true) then return t end
    end
    return nil
end

-- the current step's quest, when it's a group quest: qid, name, tag
function Plan.GroupStep()
    local d = db()
    local r = d.route and M:GetRoute(d.route)
    local s = r and r.steps[d.step or 1]
    if not (s and s.qid) then return nil end
    for _, q in ipairs(s.qids or { s.qid }) do
        local tag = Plan.GroupTag(q)
        if tag then
            local info = ns.QB and ns.QB.Quest(q)
            return q, (info and info.name) or s.quest, tag
        end
    end
    return nil
end

function Plan.FindGroup()
    local q, name, tag = Plan.GroupStep()
    if not q then return false, "Your step isn't a group quest." end
    local finder = R:GetModule("Finder")
    if not (finder and finder.QuickList) then return false, "RUIN Finder isn't installed." end
    local dungeon = tag == "Dungeon" or tag == "Raid"
    finder:QuickList(dungeon and "Dungeon" or "Questing", name, 1, 1, dungeon and 3 or 1)
    return true
end

---------------------------------------------------------------------------
-- Party sync
---------------------------------------------------------------------------
local function inParty(name)
    if not (IsInGroup and IsInGroup()) then return false end
    return UnitInParty and UnitInParty(R.Util.ShortName(name)) and true or false
end
local function isLeader(name)
    return UnitIsGroupLeader and UnitIsGroupLeader(R.Util.ShortName(name)) and true or false
end

-- a peer's step arrived: in a party on the same route, follow its leader
function Plan.OnPeerStep(d, sender)
    local cdb = db()
    if not cdb.partySync or not cdb.route or type(d.r) ~= "string" then return end
    if d.r ~= cdb.route or not inParty(sender) or not isLeader(sender) then return end
    if cdb.follow ~= d.g then
        cdb.followParty = d.g
        M:Follow(d.g)
    end
end

local function partyChanged()
    local cdb = db()
    if cdb.followParty and cdb.follow == cdb.followParty and not (IsInGroup and IsInGroup()) then
        cdb.followParty = nil
        M:Follow(nil)
    end
end

---------------------------------------------------------------------------
function Plan.Init(module)
    M = module
    local d = db()
    if d.partySync == nil then d.partySync = true end
    M:RegisterEvent("GROUP_ROSTER_UPDATE", partyChanged)
end
