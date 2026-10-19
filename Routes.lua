-- RUIN Pathfinder routes
-- A route is a list of steps. "accept", "complete" and "turnin" steps name
-- a quest and tick off by themselves; "go" and "note" steps are ticked by
-- hand (or skipped with the > button).
--
-- A step may carry a place:  at = { zone = "Elwynn Forest", x = 48.9, y = 41.6 }
-- (map percentages, as most guides and coordinate addons show them). The
-- tracker's arrow points there while you're in that zone.
--
-- These two example routes use WoW Classic quest names and approximate
-- Classic coordinates. WoW Forever has changed some quests, so treat them as
-- samples to test the feel, not as verified guides. RUIN route authors can
-- record their own routes in game (Pathfinder > Recorder) and share them.
local ADDON, ns = ...

local function at(zone, x, y) return { zone = zone, x = x, y = y } end
local DUROTAR, ELWYNN = "Durotar", "Elwynn Forest"

ns.Routes = {
    {
        id = "vot", title = "Valley of Trials 1-5", faction = "Horde", author = "RUIN",
        steps = {
            { act = "accept",   quest = "Your Place In The World", text = "Talk to Kaltunk where you start.", at = at(DUROTAR, 43.3, 68.5) },
            { act = "turnin",   quest = "Your Place In The World", text = "Gornek, inside the Den in the middle of the valley.", at = at(DUROTAR, 42.1, 68.3) },
            { act = "accept",   quest = "Cutting Teeth", text = "Gornek gives the next quest.", at = at(DUROTAR, 42.1, 68.3) },
            { act = "accept",   quest = "Galgar's Cactus Apple Surprise", text = "Galgar, just outside the Den.", at = at(DUROTAR, 42.7, 67.3) },
            { act = "complete", quest = "Cutting Teeth", text = "Kill Mottled Boars around the valley.", at = at(DUROTAR, 44.6, 62.4) },
            { act = "complete", quest = "Galgar's Cactus Apple Surprise", text = "Pick Cactus Apples from the cacti while you hunt.", at = at(DUROTAR, 45.4, 64.8) },
            { act = "turnin",   quest = "Cutting Teeth", text = "Back to Gornek.", at = at(DUROTAR, 42.1, 68.3) },
            { act = "turnin",   quest = "Galgar's Cactus Apple Surprise", text = "Back to Galgar.", at = at(DUROTAR, 42.7, 67.3) },
            { act = "accept",   quest = "Sting of the Scorpid", text = "Gornek.", at = at(DUROTAR, 42.1, 68.3) },
            { act = "complete", quest = "Sting of the Scorpid", text = "Scorpid Workers, north side of the valley.", at = at(DUROTAR, 45.0, 57.5) },
            { act = "turnin",   quest = "Sting of the Scorpid", text = "Gornek.", at = at(DUROTAR, 42.1, 68.3) },
            { act = "note",     text = "Example route ends here. Train your new spells before moving on." },
        },
    },
    {
        id = "northshire", title = "Northshire 1-5", faction = "Alliance", author = "RUIN",
        steps = {
            { act = "accept",   quest = "A Threat Within", text = "Deputy Willem, outside the Abbey.", at = at(ELWYNN, 48.2, 42.9) },
            { act = "turnin",   quest = "A Threat Within", text = "Marshal McBride, inside Northshire Abbey.", at = at(ELWYNN, 48.9, 41.6) },
            { act = "accept",   quest = "Kobold Camp Cleanup", text = "Marshal McBride.", at = at(ELWYNN, 48.9, 41.6) },
            { act = "accept",   quest = "Eagan Peltskinner", text = "Deputy Willem, outside the Abbey.", at = at(ELWYNN, 48.2, 42.9) },
            { act = "turnin",   quest = "Eagan Peltskinner", text = "Eagan Peltskinner, behind the Abbey.", at = at(ELWYNN, 48.9, 40.2) },
            { act = "accept",   quest = "Wolves Across the Border", text = "Eagan Peltskinner.", at = at(ELWYNN, 48.9, 40.2) },
            { act = "complete", quest = "Wolves Across the Border", text = "Wolves in the woods near the Abbey.", at = at(ELWYNN, 46.4, 38.7) },
            { act = "complete", quest = "Kobold Camp Cleanup", text = "Kobold Vermin in the camp north-west of the Abbey.", at = at(ELWYNN, 47.6, 34.7) },
            { act = "turnin",   quest = "Wolves Across the Border", text = "Eagan Peltskinner.", at = at(ELWYNN, 48.9, 40.2) },
            { act = "turnin",   quest = "Kobold Camp Cleanup", text = "Marshal McBride.", at = at(ELWYNN, 48.9, 41.6) },
            { act = "accept",   quest = "Investigate Echo Ridge", text = "Marshal McBride.", at = at(ELWYNN, 48.9, 41.6) },
            { act = "complete", quest = "Investigate Echo Ridge", text = "Kobold Workers in Echo Ridge Mine.", at = at(ELWYNN, 47.6, 31.5) },
            { act = "turnin",   quest = "Investigate Echo Ridge", text = "Marshal McBride.", at = at(ELWYNN, 48.9, 41.6) },
            { act = "note",     text = "Example route ends here. Train your new spells before moving on." },
        },
    },
}
