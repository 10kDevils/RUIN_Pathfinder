-- RUIN Pathfinder routes
-- A route is a list of steps. "accept", "complete" and "turnin" steps name
-- a quest and tick off by themselves; "go" and "note" steps are ticked by
-- hand (or skipped with the > button).
--
-- A step may carry a place:  at = { zone = "Elwynn Forest", x = 48.9, y = 41.6 }
-- (map percentages). The tracker's arrow points there while you're in that zone.
--
-- Alliance 1-30 stepped routes integrated from the WoW Forever quest database
-- (beta 1.60.1) and public Forever leveling guidance. Coordinates are best-effort
-- from database pins and Classic baselines; Forever layout can differ slightly.
-- Record your own refinements in-game (Pathfinder > Recorder) and share them.
local ADDON, ns = ...

local function at(zone, x, y) return { zone = zone, x = x, y = y } end

local ELWYNN   = "Elwynn Forest"
local WESTFALL = "Westfall"
local DUNMOR   = "Dun Morogh"
local LOCH     = "Loch Modan"
local TELDRAS  = "Teldrassil"
local DARKSH   = "Darkshore"
local REDRIDGE = "Redridge Mountains"
local IRONFORGE = "Ironforge"
local ZEPHRAS  = "Zephras Isle"

ns.Routes = {

    ------------------------------------------------------------------
    -- ELWYNN FOREST (Human 1-10)
    ------------------------------------------------------------------
    {
        id = "elwynn_1_10", title = "Elwynn 1-10", faction = "Alliance", author = "RUIN+DB",
        steps = {
            { act = "accept",   quest = "A Threat Within", text = "Deputy Willem outside Northshire Abbey.", at = at(ELWYNN, 48.2, 42.9) },
            { act = "turnin",   quest = "A Threat Within", text = "Marshal McBride inside the Abbey.", at = at(ELWYNN, 48.9, 41.6) },
            { act = "accept",   quest = "Kobold Camp Cleanup", text = "Marshal McBride.", at = at(ELWYNN, 48.9, 41.6) },
            { act = "accept",   quest = "Eagan Peltskinner", text = "Deputy Willem outside.", at = at(ELWYNN, 48.2, 42.9) },
            { act = "turnin",   quest = "Eagan Peltskinner", text = "Eagan behind the Abbey.", at = at(ELWYNN, 48.9, 40.2) },
            { act = "accept",   quest = "Wolves Across the Border", text = "Eagan Peltskinner.", at = at(ELWYNN, 48.9, 40.2) },
            { act = "complete", quest = "Wolves Across the Border", text = "Kill wolves in the woods near the Abbey.", at = at(ELWYNN, 46.4, 38.7) },
            { act = "complete", quest = "Kobold Camp Cleanup", text = "Kobold Vermin north-west of the Abbey.", at = at(ELWYNN, 47.6, 34.7) },
            { act = "turnin",   quest = "Wolves Across the Border", text = "Eagan Peltskinner.", at = at(ELWYNN, 48.9, 40.2) },
            { act = "turnin",   quest = "Kobold Camp Cleanup", text = "Marshal McBride.", at = at(ELWYNN, 48.9, 41.6) },
            { act = "accept",   quest = "Investigate Echo Ridge", text = "Marshal McBride.", at = at(ELWYNN, 48.9, 41.6) },
            { act = "accept",   quest = "Brotherhood of Thieves", text = "Deputy Willem.", at = at(ELWYNN, 48.2, 42.9) },
            { act = "complete", quest = "Investigate Echo Ridge", text = "Kobold Workers in Echo Ridge Mine.", at = at(ELWYNN, 47.6, 31.5) },
            { act = "complete", quest = "Brotherhood of Thieves", text = "Defias in the vineyards east of the Abbey.", at = at(ELWYNN, 53.0, 47.0) },
            { act = "turnin",   quest = "Investigate Echo Ridge", text = "Marshal McBride.", at = at(ELWYNN, 48.9, 41.6) },
            { act = "turnin",   quest = "Brotherhood of Thieves", text = "Deputy Willem.", at = at(ELWYNN, 48.2, 42.9) },
            { act = "accept",   quest = "Bounty on Garrick Padfoot", text = "Deputy Willem.", at = at(ELWYNN, 48.2, 42.9) },
            { act = "accept",   quest = "Skirmish at Echo Ridge", text = "Marshal McBride.", at = at(ELWYNN, 48.9, 41.6) },
            { act = "complete", quest = "Bounty on Garrick Padfoot", text = "Garrick Padfoot at the small camp east.", at = at(ELWYNN, 57.3, 48.3) },
            { act = "complete", quest = "Skirmish at Echo Ridge", text = "Kobold Laborers deeper in the mine.", at = at(ELWYNN, 47.6, 31.5) },
            { act = "turnin",   quest = "Bounty on Garrick Padfoot", text = "Deputy Willem.", at = at(ELWYNN, 48.2, 42.9) },
            { act = "turnin",   quest = "Skirmish at Echo Ridge", text = "Marshal McBride.", at = at(ELWYNN, 48.9, 41.6) },
            { act = "accept",   quest = "Report to Goldshire", text = "Marshal McBride. Leave Northshire.", at = at(ELWYNN, 48.9, 41.6) },
            { act = "turnin",   quest = "Report to Goldshire", text = "Marshal Dughan in Goldshire.", at = at(ELWYNN, 42.1, 65.9) },
            { act = "accept",   quest = "Rest and Relaxation", text = "Marshal Dughan (or innkeeper breadcrumb).", at = at(ELWYNN, 42.1, 65.9) },
            { act = "accept",   quest = "Gold Dust Exchange", text = "Remy \"Two Times\" near the forge.", at = at(ELWYNN, 42.1, 67.3) },
            { act = "accept",   quest = "Kobold Candles", text = "William Pestle in the inn.", at = at(ELWYNN, 43.3, 65.7) },
            { act = "accept",   quest = "The Fargodeep Mine", text = "Marshal Dughan.", at = at(ELWYNN, 42.1, 65.9) },
            { act = "accept",   quest = "Lost Necklace", text = "\"Auntie\" Bernice Stonefield at the farm south-west.", at = at(ELWYNN, 34.5, 84.3) },
            { act = "complete", quest = "Gold Dust Exchange", text = "Kobolds in and around Fargodeep Mine.", at = at(ELWYNN, 39.0, 81.0) },
            { act = "complete", quest = "Kobold Candles", text = "Large Candles from the same kobolds.", at = at(ELWYNN, 39.0, 81.0) },
            { act = "complete", quest = "The Fargodeep Mine", text = "Explore the lower levels of Fargodeep.", at = at(ELWYNN, 39.0, 81.0) },
            { act = "turnin",   quest = "Lost Necklace", text = "Billy Maclure at the Maclure farm.", at = at(ELWYNN, 43.1, 85.7) },
            { act = "accept",   quest = "Pie for Billy", text = "Billy Maclure.", at = at(ELWYNN, 43.1, 85.7) },
            { act = "complete", quest = "Pie for Billy", text = "Kill boars for Tender Boar Meat nearby.", at = at(ELWYNN, 42.0, 87.0) },
            { act = "turnin",   quest = "Pie for Billy", text = "\"Auntie\" Bernice Stonefield.", at = at(ELWYNN, 34.5, 84.3) },
            { act = "accept",   quest = "Back to Billy", text = "Bernice.", at = at(ELWYNN, 34.5, 84.3) },
            { act = "turnin",   quest = "Back to Billy", text = "Billy Maclure.", at = at(ELWYNN, 43.1, 85.7) },
            { act = "turnin",   quest = "Gold Dust Exchange", text = "Remy \"Two Times\".", at = at(ELWYNN, 42.1, 67.3) },
            { act = "turnin",   quest = "Kobold Candles", text = "William Pestle.", at = at(ELWYNN, 43.3, 65.7) },
            { act = "turnin",   quest = "The Fargodeep Mine", text = "Marshal Dughan.", at = at(ELWYNN, 42.1, 65.9) },
            { act = "accept",   quest = "The Jasperlode Mine", text = "Marshal Dughan.", at = at(ELWYNN, 42.1, 65.9) },
            { act = "accept",   quest = "A Fishy Peril", text = "Guard Thomas east on the bridge.", at = at(ELWYNN, 74.0, 72.2) },
            { act = "accept",   quest = "Protect the Frontier", text = "Guard Thomas.", at = at(ELWYNN, 74.0, 72.2) },
            { act = "accept",   quest = "Bounty on Murlocs", text = "Guard Thomas or nearby board.", at = at(ELWYNN, 74.0, 72.2) },
            { act = "complete", quest = "The Jasperlode Mine", text = "Explore Jasperlode Mine north-east of Goldshire.", at = at(ELWYNN, 61.0, 53.0) },
            { act = "complete", quest = "Protect the Frontier", text = "Kill Prowlers and Young Forest Bears east.", at = at(ELWYNN, 80.0, 60.0) },
            { act = "complete", quest = "Bounty on Murlocs", text = "Murlocs along the east river / Crystal Lake.", at = at(ELWYNN, 78.0, 69.0) },
            { act = "turnin",   quest = "A Fishy Peril", text = "Marshal Dughan.", at = at(ELWYNN, 42.1, 65.9) },
            { act = "turnin",   quest = "The Jasperlode Mine", text = "Marshal Dughan.", at = at(ELWYNN, 42.1, 65.9) },
            { act = "turnin",   quest = "Protect the Frontier", text = "Guard Thomas.", at = at(ELWYNN, 74.0, 72.2) },
            { act = "turnin",   quest = "Bounty on Murlocs", text = "Guard Thomas.", at = at(ELWYNN, 74.0, 72.2) },
            { act = "accept",   quest = "Further Concerns", text = "Marshal Dughan.", at = at(ELWYNN, 42.1, 65.9) },
            { act = "turnin",   quest = "Further Concerns", text = "Guard Thomas.", at = at(ELWYNN, 74.0, 72.2) },
            { act = "accept",   quest = "Find the Lost Guards", text = "Guard Thomas.", at = at(ELWYNN, 74.0, 72.2) },
            { act = "complete", quest = "Find the Lost Guards", text = "Find the corpses of the lost guards east.", at = at(ELWYNN, 79.8, 55.5) },
            { act = "turnin",   quest = "Find the Lost Guards", text = "Guard Thomas (or via Rolf's report).", at = at(ELWYNN, 74.0, 72.2) },
            { act = "accept",   quest = "Deliver Thomas' Report", text = "Guard Thomas.", at = at(ELWYNN, 74.0, 72.2) },
            { act = "turnin",   quest = "Deliver Thomas' Report", text = "Marshal Dughan.", at = at(ELWYNN, 42.1, 65.9) },
            { act = "accept",   quest = "Westbrook Garrison Needs Help!", text = "Marshal Dughan. Head west.", at = at(ELWYNN, 42.1, 65.9) },
            { act = "turnin",   quest = "Westbrook Garrison Needs Help!", text = "Deputy Rainer at Westbrook Garrison.", at = at(ELWYNN, 24.2, 74.5) },
            { act = "accept",   quest = "Riverpaw Gnoll Bounty", text = "Deputy Rainer.", at = at(ELWYNN, 24.2, 74.5) },
            { act = "complete", quest = "Riverpaw Gnoll Bounty", text = "Riverpaw gnolls west of the garrison.", at = at(ELWYNN, 25.0, 85.0) },
            { act = "turnin",   quest = "Riverpaw Gnoll Bounty", text = "Deputy Rainer.", at = at(ELWYNN, 24.2, 74.5) },
            { act = "note",     text = "Elwynn complete. Take the west road into Westfall and start the Westfall 10-15 route at Sentinel Hill. Pick up Report to Gryan Stoutmantle if you still have the breadcrumb." },
        },
    },

    ------------------------------------------------------------------
    -- WESTFALL (10-15)
    ------------------------------------------------------------------
    {
        id = "westfall_10_15", title = "Westfall 10-15", faction = "Alliance", author = "RUIN+DB",
        steps = {
            { act = "accept",   quest = "Report to Gryan Stoutmantle", text = "Breadcrumb into Westfall (from Elwynn or elsewhere).", at = at(WESTFALL, 56.3, 47.5) },
            { act = "turnin",   quest = "Report to Gryan Stoutmantle", text = "Gryan Stoutmantle at Sentinel Hill.", at = at(WESTFALL, 56.3, 47.5) },
            { act = "accept",   quest = "The People's Militia", text = "Gryan Stoutmantle (first part).", at = at(WESTFALL, 56.3, 47.5) },
            { act = "accept",   quest = "Patrolling Westfall", text = "Captain Danuvin next to Gryan.", at = at(WESTFALL, 56.4, 47.6) },
            { act = "accept",   quest = "Westfall Stew", text = "Verna Furlbrow or Salma Saldean (farm area).", at = at(WESTFALL, 59.9, 19.4) },
            { act = "accept",   quest = "Goretusk Liver Pie", text = "Salma Saldean at Saldean's Farm.", at = at(WESTFALL, 56.4, 30.5) },
            { act = "accept",   quest = "The Killing Fields", text = "Farmer Saldean.", at = at(WESTFALL, 56.0, 31.2) },
            { act = "complete", quest = "Westfall Stew", text = "Collect Stringy Vulture Meat, Murloc Eyes, Goretusk Flanks, Okra around the farms.", at = at(WESTFALL, 54.0, 32.0) },
            { act = "complete", quest = "Goretusk Liver Pie", text = "Goretusk Livers from Goretusks.", at = at(WESTFALL, 54.0, 32.0) },
            { act = "complete", quest = "The Killing Fields", text = "Kill Harvest Watchers in the fields.", at = at(WESTFALL, 54.0, 32.0) },
            { act = "complete", quest = "The People's Militia", text = "Defias at the various camps (Jango / Dust Plains area).", at = at(WESTFALL, 45.0, 60.0) },
            { act = "complete", quest = "Patrolling Westfall", text = "Gnolls / Riverpaw as required while you patrol.", at = at(WESTFALL, 50.0, 45.0) },
            { act = "turnin",   quest = "Westfall Stew", text = "Salma Saldean.", at = at(WESTFALL, 56.4, 30.5) },
            { act = "turnin",   quest = "Goretusk Liver Pie", text = "Salma Saldean.", at = at(WESTFALL, 56.4, 30.5) },
            { act = "turnin",   quest = "The Killing Fields", text = "Farmer Saldean.", at = at(WESTFALL, 56.0, 31.2) },
            { act = "turnin",   quest = "The People's Militia", text = "Gryan Stoutmantle.", at = at(WESTFALL, 56.3, 47.5) },
            { act = "turnin",   quest = "Patrolling Westfall", text = "Captain Danuvin.", at = at(WESTFALL, 56.4, 47.6) },
            { act = "accept",   quest = "The People's Militia", text = "Gryan – next part if available.", at = at(WESTFALL, 56.3, 47.5) },
            { act = "note",     text = "At 14+ start Cozy Sleeping Bag (Burned-Out Remains, Alexston Farmstead ~37,50). Finish Militia / Red Leather Bandanas / Defias toward Deadmines. Next outdoor: Redridge 15-22, or detour north for Hall of Thanes 13-18 while in the IF area." },
        },
    },

    ------------------------------------------------------------------
    -- DUN MOROGH (Dwarf/Gnome 1-12)
    ------------------------------------------------------------------
    {
        id = "dun_morogh_1_12", title = "Dun Morogh 1-12", faction = "Alliance", author = "RUIN+DB",
        steps = {
            { act = "accept",   quest = "Dwarven Outfitters", text = "Sten Stoutarm in Coldridge Valley.", at = at(DUNMOR, 29.9, 71.2) },
            { act = "complete", quest = "Dwarven Outfitters", text = "Kill wolves for Tough Wolf Meat.", at = at(DUNMOR, 30.0, 73.0) },
            { act = "turnin",   quest = "Dwarven Outfitters", text = "Sten Stoutarm.", at = at(DUNMOR, 29.9, 71.2) },
            { act = "accept",   quest = "A New Threat", text = "Balir Frosthammer.", at = at(DUNMOR, 29.7, 71.3) },
            { act = "accept",   quest = "The Boar Hunter", text = "Talin Keeneye (or nearby).", at = at(DUNMOR, 29.0, 72.0) },
            { act = "complete", quest = "A New Threat", text = "Burly Rockjaw Troggs and Young Wendigos.", at = at(DUNMOR, 31.0, 74.0) },
            { act = "complete", quest = "The Boar Hunter", text = "Small Crag Boars.", at = at(DUNMOR, 30.0, 73.0) },
            { act = "turnin",   quest = "A New Threat", text = "Balir Frosthammer.", at = at(DUNMOR, 29.7, 71.3) },
            { act = "turnin",   quest = "The Boar Hunter", text = "Talin Keeneye.", at = at(DUNMOR, 29.0, 72.0) },
            { act = "accept",   quest = "Coldridge Valley Mail Delivery", text = "Talin Keeneye.", at = at(DUNMOR, 29.0, 72.0) },
            { act = "turnin",   quest = "Coldridge Valley Mail Delivery", text = "Grelin Whitebeard further into the valley.", at = at(DUNMOR, 25.0, 76.0) },
            { act = "accept",   quest = "The Troll Cave", text = "Grelin Whitebeard.", at = at(DUNMOR, 25.0, 76.0) },
            { act = "complete", quest = "The Troll Cave", text = "Frostmane Troll Whelps in the cave.", at = at(DUNMOR, 26.0, 79.0) },
            { act = "turnin",   quest = "The Troll Cave", text = "Grelin Whitebeard.", at = at(DUNMOR, 25.0, 76.0) },
            { act = "accept",   quest = "Senir's Observations", text = "Grelin – leave Coldridge for Kharanos.", at = at(DUNMOR, 25.0, 76.0) },
            { act = "turnin",   quest = "Senir's Observations", text = "Senir Whitebeard in Kharanos.", at = at(DUNMOR, 46.7, 53.8) },
            { act = "accept",   quest = "Tools for Steelgrill", text = "Senir or nearby.", at = at(DUNMOR, 46.7, 53.8) },
            { act = "accept",   quest = "Stocking Jetsteam", text = "Pilot Bellowfiz at Steelgrill's Depot.", at = at(DUNMOR, 49.4, 48.4) },
            { act = "accept",   quest = "Beer Basted Boar Ribs", text = "Ragnar Thunderbrew in Kharanos.", at = at(DUNMOR, 46.8, 52.4) },
            { act = "complete", quest = "Stocking Jetsteam", text = "Chunk of Boar Meat and Thick Bear Fur around Kharanos.", at = at(DUNMOR, 48.0, 50.0) },
            { act = "complete", quest = "Beer Basted Boar Ribs", text = "Crag Boar Ribs from boars.", at = at(DUNMOR, 48.0, 50.0) },
            { act = "turnin",   quest = "Stocking Jetsteam", text = "Pilot Bellowfiz.", at = at(DUNMOR, 49.4, 48.4) },
            { act = "accept",   quest = "Evershine", text = "Pilot Bellowfiz.", at = at(DUNMOR, 49.4, 48.4) },
            { act = "turnin",   quest = "Beer Basted Boar Ribs", text = "Ragnar Thunderbrew.", at = at(DUNMOR, 46.8, 52.4) },
            { act = "turnin",   quest = "Evershine", text = "Rejold Barleybrew at the brewery north-west of Kharanos.", at = at(DUNMOR, 30.2, 45.6) },
            { act = "accept",   quest = "A Favor for Evershine", text = "Rejold.", at = at(DUNMOR, 30.2, 45.6) },
            { act = "accept",   quest = "The Perfect Stout", text = "Rejold.", at = at(DUNMOR, 30.2, 45.6) },
            { act = "complete", quest = "A Favor for Evershine", text = "Ice Claw Bears, Elder Crag Boars, Snow Leopards nearby.", at = at(DUNMOR, 32.0, 40.0) },
            { act = "complete", quest = "The Perfect Stout", text = "Shimmerweed from baskets at the Frostmane camps.", at = at(DUNMOR, 37.0, 42.0) },
            { act = "turnin",   quest = "A Favor for Evershine", text = "Rejold.", at = at(DUNMOR, 30.2, 45.6) },
            { act = "turnin",   quest = "The Perfect Stout", text = "Rejold.", at = at(DUNMOR, 30.2, 45.6) },
            { act = "accept",   quest = "Return to Bellowfiz", text = "Rejold.", at = at(DUNMOR, 30.2, 45.6) },
            { act = "turnin",   quest = "Return to Bellowfiz", text = "Pilot Bellowfiz.", at = at(DUNMOR, 49.4, 48.4) },
            { act = "accept",   quest = "Those Blasted Troggs!", text = "Foreman Stonebrow at Gol'Bolar Quarry.", at = at(DUNMOR, 69.2, 56.0) },
            { act = "accept",   quest = "The Public Servant", text = "Senator Mehr Stonehallow at the quarry.", at = at(DUNMOR, 68.7, 56.0) },
            { act = "complete", quest = "Those Blasted Troggs!", text = "Rockjaw Skullthumpers in the quarry.", at = at(DUNMOR, 70.0, 56.0) },
            { act = "complete", quest = "The Public Servant", text = "Rockjaw Bonesnappers deeper in.", at = at(DUNMOR, 71.0, 52.0) },
            { act = "turnin",   quest = "Those Blasted Troggs!", text = "Foreman Stonebrow.", at = at(DUNMOR, 69.2, 56.0) },
            { act = "turnin",   quest = "The Public Servant", text = "Senator Mehr Stonehallow.", at = at(DUNMOR, 68.7, 56.0) },
            { act = "note",     text = "Next: Loch Modan 10-18 via South Gate Pass into Thelsamar. Prep Hall of Thanes anytime from 13+ (Dark Iron Map near Ironband's → Earthseer Farsen ~64.8, 58.4) — see Hall of Thanes route." },
        },
    },

    ------------------------------------------------------------------
    -- TELDRASSIL (Night Elf 1-12)
    ------------------------------------------------------------------
    {
        id = "teldrassil_1_12", title = "Teldrassil 1-12", faction = "Alliance", author = "RUIN+DB",
        steps = {
            { act = "accept",   quest = "The Balance of Nature", text = "Conservator Ilthalaine in Shadowglen.", at = at(TELDRAS, 58.7, 44.3) },
            { act = "complete", quest = "The Balance of Nature", text = "Young Nightsabers and Young Thistle Boars.", at = at(TELDRAS, 60.0, 43.0) },
            { act = "turnin",   quest = "The Balance of Nature", text = "Conservator Ilthalaine.", at = at(TELDRAS, 58.7, 44.3) },
            { act = "accept",   quest = "The Balance of Nature", text = "Second part from Ilthalaine.", at = at(TELDRAS, 58.7, 44.3) },
            { act = "accept",   quest = "The Woodland Protector", text = "Melithar Staghelm.", at = at(TELDRAS, 59.9, 42.5) },
            { act = "complete", quest = "The Balance of Nature", text = "Mangy Nightsabers and Thistle Boars.", at = at(TELDRAS, 61.0, 40.0) },
            { act = "turnin",   quest = "The Woodland Protector", text = "Tarindrella in the northern glade.", at = at(TELDRAS, 57.8, 41.7) },
            { act = "accept",   quest = "The Woodland Protector", text = "Tarindrella – collect Fel Moss.", at = at(TELDRAS, 57.8, 41.7) },
            { act = "complete", quest = "The Woodland Protector", text = "Grellkin for Fel Moss.", at = at(TELDRAS, 55.0, 40.0) },
            { act = "turnin",   quest = "The Balance of Nature", text = "Conservator Ilthalaine.", at = at(TELDRAS, 58.7, 44.3) },
            { act = "turnin",   quest = "The Woodland Protector", text = "Tarindrella.", at = at(TELDRAS, 57.8, 41.7) },
            { act = "accept",   quest = "Webwood Venom", text = "Gilshalan Windwalker.", at = at(TELDRAS, 57.8, 41.7) },
            { act = "accept",   quest = "A Good Friend", text = "Dirania Silvershine.", at = at(TELDRAS, 60.9, 42.0) },
            { act = "complete", quest = "Webwood Venom", text = "Webwood Spiders north of Aldrassil.", at = at(TELDRAS, 57.0, 33.0) },
            { act = "turnin",   quest = "A Good Friend", text = "Iverron by the moonwell north.", at = at(TELDRAS, 54.6, 33.0) },
            { act = "accept",   quest = "A Friend in Need", text = "Iverron.", at = at(TELDRAS, 54.6, 33.0) },
            { act = "turnin",   quest = "Webwood Venom", text = "Gilshalan Windwalker.", at = at(TELDRAS, 57.8, 41.7) },
            { act = "accept",   quest = "Webwood Egg", text = "Gilshalan.", at = at(TELDRAS, 57.8, 41.7) },
            { act = "turnin",   quest = "A Friend in Need", text = "Dirania Silvershine.", at = at(TELDRAS, 60.9, 42.0) },
            { act = "accept",   quest = "Iverron's Antidote", text = "Dirania – collect the three ingredients.", at = at(TELDRAS, 60.9, 42.0) },
            { act = "complete", quest = "Iverron's Antidote", text = "Hyacinth Mushrooms, Moonpetal Lilies, Webwood Ichor in the same northern area.", at = at(TELDRAS, 55.0, 35.0) },
            { act = "complete", quest = "Webwood Egg", text = "Githyiss the Vile at the top of the spider cave.", at = at(TELDRAS, 56.8, 26.5) },
            { act = "turnin",   quest = "Iverron's Antidote", text = "Dirania, then deliver to Iverron.", at = at(TELDRAS, 60.9, 42.0) },
            { act = "turnin",   quest = "Webwood Egg", text = "Gilshalan Windwalker.", at = at(TELDRAS, 57.8, 41.7) },
            { act = "accept",   quest = "Tenaron's Summons", text = "Gilshalan.", at = at(TELDRAS, 57.8, 41.7) },
            { act = "turnin",   quest = "Tenaron's Summons", text = "Tenaron Stormgrip at the top of Aldrassil.", at = at(TELDRAS, 59.1, 39.4) },
            { act = "accept",   quest = "Crown of the Earth", text = "Tenaron – first moonwell sample.", at = at(TELDRAS, 59.1, 39.4) },
            { act = "complete", quest = "Crown of the Earth", text = "Fill the crystal phial at the Shadowglen moonwell.", at = at(TELDRAS, 59.9, 33.0) },
            { act = "turnin",   quest = "Crown of the Earth", text = "Tenaron Stormgrip.", at = at(TELDRAS, 59.1, 39.4) },
            { act = "accept",   quest = "Crown of the Earth", text = "Tenaron – next part toward Dolanaar.", at = at(TELDRAS, 59.1, 39.4) },
            { act = "accept",   quest = "Dolanaar Delivery", text = "Porthannius on the road out of Shadowglen.", at = at(TELDRAS, 61.2, 47.6) },
            { act = "turnin",   quest = "Dolanaar Delivery", text = "Innkeeper Keldamyr in Dolanaar.", at = at(TELDRAS, 55.6, 59.8) },
            { act = "turnin",   quest = "Crown of the Earth", text = "Corithras Moonrage in Dolanaar.", at = at(TELDRAS, 56.1, 61.7) },
            { act = "accept",   quest = "Crown of the Earth", text = "Corithras – continue the chain.", at = at(TELDRAS, 56.1, 61.7) },
            { act = "accept",   quest = "Zenn's Bidding", text = "Zenn Foulhoof east of Dolanaar.", at = at(TELDRAS, 60.5, 56.3) },
            { act = "accept",   quest = "A Troubling Breeze", text = "Athridas Bearmantle in Dolanaar.", at = at(TELDRAS, 56.0, 57.3) },
            { act = "accept",   quest = "The Emerald Dreamcatcher", text = "Tallonkai Swiftroot on the lodge roof.", at = at(TELDRAS, 55.5, 56.9) },
            { act = "complete", quest = "Zenn's Bidding", text = "Nightsaber fangs, Strigid Owl feathers, Webwood spider silk around Dolanaar.", at = at(TELDRAS, 60.0, 58.0) },
            { act = "turnin",   quest = "Zenn's Bidding", text = "Zenn Foulhoof.", at = at(TELDRAS, 60.5, 56.3) },
            { act = "turnin",   quest = "A Troubling Breeze", text = "Gaerolas Talvethren in Starbreeze Village.", at = at(TELDRAS, 66.3, 58.5) },
            { act = "accept",   quest = "Gnarlpine Corruption", text = "Gaerolas.", at = at(TELDRAS, 66.3, 58.5) },
            { act = "complete", quest = "The Emerald Dreamcatcher", text = "Tallonkai's Dresser in Starbreeze.", at = at(TELDRAS, 68.0, 59.6) },
            { act = "turnin",   quest = "Gnarlpine Corruption", text = "Athridas Bearmantle.", at = at(TELDRAS, 56.0, 57.3) },
            { act = "turnin",   quest = "The Emerald Dreamcatcher", text = "Tallonkai Swiftroot.", at = at(TELDRAS, 55.5, 56.9) },
            { act = "note",     text = "Finish Crown of the Earth, Timberling Seeds/Sprouts, Road to Darnassus. Boat Rut'theran → Auberdine and start Darkshore 11-18. Accept every dock/inn quest on arrival." },
        },
    },

    ------------------------------------------------------------------
    -- ZEPHRAS ISLE (Skyborne 1-12) – high-level structure
    ------------------------------------------------------------------
    {
        id = "zephras_1_12", title = "Zephras Isle 1-12", faction = "Alliance", author = "RUIN+DB",
        steps = {
            { act = "note",     text = "Skyborne starter. Accept every quest at each village hub before leaving. Exact pins vary; follow on-screen markers and Questie if installed." },
            { act = "accept",   quest = "Welcome!", text = "Starting area welcome.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "accept",   quest = "Harmony in Balance", text = "Early hub.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "accept",   quest = "Infestation Investigation", text = "Early hub.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "complete", quest = "Harmony in Balance", text = "Starting island objectives.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "complete", quest = "Infestation Investigation", text = "Clear infestation mobs nearby.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "turnin",   quest = "Harmony in Balance", text = "Return to hub.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "turnin",   quest = "Infestation Investigation", text = "Return to hub.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "accept",   quest = "The Cirrusfly Queen", text = "Next wave.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "accept",   quest = "Agitators", text = "Next wave.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "accept",   quest = "Aggressive Encroachment", text = "Next wave.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "complete", quest = "The Cirrusfly Queen", text = "Kill the Cirrusfly Queen / related objectives.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "complete", quest = "Agitators", text = "Deal with agitators.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "complete", quest = "Aggressive Encroachment", text = "Clear encroachment.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "turnin",   quest = "The Cirrusfly Queen", text = "Hub.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "turnin",   quest = "Agitators", text = "Hub.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "turnin",   quest = "Aggressive Encroachment", text = "Hub.", at = at(ZEPHRAS, 50.0, 50.0) },
            { act = "note",     text = "Continue through Shen'dar Village, Falaath, and Valanaar hubs: Hippogryph Harrassment, The Criminal Element, Pilfered Windstones, Make Yourself Useful, Feathers for Binding, Aid For The Refugees, etc. Clear each village loop fully before moving on. Exit via A Grand Adventure / What Comes Next toward Westfall or Loch Modan around level 12." },
        },
    },

    ------------------------------------------------------------------
    -- HALL OF THANES (13-18, group recommended)
    ------------------------------------------------------------------
    {
        id = "hall_of_thanes", title = "Hall of Thanes 13-18", faction = "Alliance", author = "RUIN+DB",
        steps = {
            { act = "note",     text = "GROUP recommended. Prep in Dun Morogh before entering." },
            { act = "accept",   quest = "Nip 'Em in the Bud", text = "Earthseer Farsen in Dun Morogh (~64.8, 58.4).", at = at(DUNMOR, 64.8, 58.4) },
            { act = "complete", quest = "Nip 'Em in the Bud", text = "Kill Dark Iron Spies near Ironband's / Gol'Bolar (~76-78, 60). Loot the Dark Iron Map.", at = at(DUNMOR, 77.0, 61.0) },
            { act = "turnin",   quest = "Nip 'Em in the Bud", text = "Earthseer Farsen.", at = at(DUNMOR, 64.8, 58.4) },
            { act = "accept",   quest = "Underground Map", text = "From the Dark Iron Map or Farsen.", at = at(DUNMOR, 64.8, 58.4) },
            { act = "turnin",   quest = "Underground Map", text = "Earthseer Farsen – receive Old Ironforge Incursion.", at = at(DUNMOR, 64.8, 58.4) },
            { act = "accept",   quest = "Old Ironforge Incursion", text = "Earthseer Farsen.", at = at(DUNMOR, 64.8, 58.4) },
            { act = "go",       text = "Travel to Ironforge – Hall of Thanes entrance in Old Ironforge.", at = at(IRONFORGE, 33.0, 48.0) },
            { act = "accept",   quest = "Important Heirlooms", text = "Thom Filch near the dungeon bridge/entrance.", at = at(IRONFORGE, 32.6, 44.6) },
            { act = "accept",   quest = "The Restless Dead", text = "Afadra Dunwall up the stairs from the entrance area.", at = at(IRONFORGE, 34.0, 48.8) },
            { act = "note",     text = "Enter the Hall of Thanes. Pick up An Ancient Grudge from the Ghostly Attendant inside. Clear the dungeon: collect 8 Dwarven Heirlooms, kill the required apparitions/souls, kill Faldrim Anvilmar, kill Durgen Dirgehammer for the head, and loot the Treaty tablet in the final vault." },
            { act = "complete", quest = "Important Heirlooms", text = "8 Dwarven Heirlooms from urns/chests inside.", at = at(IRONFORGE, 33.0, 48.0) },
            { act = "complete", quest = "The Restless Dead", text = "Enraged Apparitions and Tormented Souls.", at = at(IRONFORGE, 33.0, 48.0) },
            { act = "complete", quest = "An Ancient Grudge", text = "Kill Faldrim Anvilmar (first boss area).", at = at(IRONFORGE, 33.0, 48.0) },
            { act = "complete", quest = "Old Ironforge Incursion", text = "Kill Durgen Dirgehammer and loot his head.", at = at(IRONFORGE, 33.0, 48.0) },
            { act = "accept",   quest = "The Treaty of Understanding", text = "From the tablet/vault item in the final room.", at = at(IRONFORGE, 33.0, 48.0) },
            { act = "turnin",   quest = "Important Heirlooms", text = "Thom Filch outside.", at = at(IRONFORGE, 32.6, 44.6) },
            { act = "turnin",   quest = "The Restless Dead", text = "Afadra Dunwall.", at = at(IRONFORGE, 34.0, 48.8) },
            { act = "turnin",   quest = "An Ancient Grudge", text = "Ghostly Attendant or as directed.", at = at(IRONFORGE, 33.0, 48.0) },
            { act = "turnin",   quest = "Old Ironforge Incursion", text = "King Magni Bronzebeard in the High Seat.", at = at(IRONFORGE, 39.1, 56.2) },
            { act = "turnin",   quest = "The Treaty of Understanding", text = "King Magni Bronzebeard.", at = at(IRONFORGE, 39.1, 56.2) },
            { act = "note",     text = "Hall of Thanes complete. Choice gear rewards are strong for the level. Resume outdoor leveling in Loch Modan, Westfall, or Redridge." },
        },
    },

    ------------------------------------------------------------------
    -- Keep original samples for reference / Horde testing
    ------------------------------------------------------------------
    {
        id = "vot", title = "Valley of Trials 1-5", faction = "Horde", author = "RUIN",
        steps = {
            { act = "accept",   quest = "Your Place In The World", text = "Talk to Kaltunk where you start.", at = at("Durotar", 43.3, 68.5) },
            { act = "turnin",   quest = "Your Place In The World", text = "Gornek, inside the Den in the middle of the valley.", at = at("Durotar", 42.1, 68.3) },
            { act = "accept",   quest = "Cutting Teeth", text = "Gornek gives the next quest.", at = at("Durotar", 42.1, 68.3) },
            { act = "accept",   quest = "Galgar's Cactus Apple Surprise", text = "Galgar, just outside the Den.", at = at("Durotar", 42.7, 67.3) },
            { act = "complete", quest = "Cutting Teeth", text = "Kill Mottled Boars around the valley.", at = at("Durotar", 44.6, 62.4) },
            { act = "complete", quest = "Galgar's Cactus Apple Surprise", text = "Pick Cactus Apples from the cacti while you hunt.", at = at("Durotar", 45.4, 64.8) },
            { act = "turnin",   quest = "Cutting Teeth", text = "Back to Gornek.", at = at("Durotar", 42.1, 68.3) },
            { act = "turnin",   quest = "Galgar's Cactus Apple Surprise", text = "Back to Galgar.", at = at("Durotar", 42.7, 67.3) },
            { act = "accept",   quest = "Sting of the Scorpid", text = "Gornek.", at = at("Durotar", 42.1, 68.3) },
            { act = "complete", quest = "Sting of the Scorpid", text = "Scorpid Workers, north side of the valley.", at = at("Durotar", 45.0, 57.5) },
            { act = "turnin",   quest = "Sting of the Scorpid", text = "Gornek.", at = at("Durotar", 42.1, 68.3) },
            { act = "note",     text = "Example route ends here. Train your new spells before moving on." },
        },
    },
    {
        id = "northshire", title = "Northshire 1-5 (sample)", faction = "Alliance", author = "RUIN",
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
            { act = "note",     text = "Sample ends. Prefer the fuller Elwynn 1-10 route for a complete run." },
        },
    },

    ------------------------------------------------------------------
    -- LOCH MODAN (10-18) — primary after Dun Morogh; also reachable from IF
    ------------------------------------------------------------------
    {
        id = "loch_modan_10_18", title = "Loch Modan 10-18", faction = "Alliance", author = "RUIN+DB",
        steps = {
            { act = "note",     text = "Enter from Dun Morogh via South Gate or from Ironforge. Head to Thelsamar first." },
            { act = "go",       text = "Arrive Thelsamar. Grab flight path. Accept everything at the inn and around the town square.", at = at(LOCH, 35.0, 47.0) },
            { act = "accept",   quest = "Rat Catching", text = "Mountaineer Kadrell (patrols Thelsamar).", at = at(LOCH, 34.2, 47.8) },
            { act = "accept",   quest = "Thelsamar Blood Sausages", text = "Vidra Hearthstove in the inn if available.", at = at(LOCH, 34.8, 49.1) },
            { act = "accept",   quest = "Mercenaries", text = "Magistrate Bluntnose in Thelsamar.", at = at(LOCH, 34.6, 44.5) },
            { act = "accept",   quest = "Ironband's Excavation", text = "Jern Hornhelm in Thelsamar.", at = at(LOCH, 37.2, 47.4) },
            { act = "note",     text = "As you leave south toward the Valley of Kings / Algaz: pick up In Defense of the King's Lands and The Trogg Threat from the Mountaineers at the southern bunkers." },
            { act = "accept",   quest = "In Defense of the King's Lands", text = "Mountaineer Cobbleflint at the southern bunker.", at = at(LOCH, 22.1, 73.1) },
            { act = "accept",   quest = "The Trogg Threat", text = "Captain Rugelfuss at the southern bunker.", at = at(LOCH, 23.2, 73.7) },
            { act = "accept",   quest = "In Defense of the King's Lands", text = "Mountaineer Gravelgaw / Wallbang — next parts as you progress the chain.", at = at(LOCH, 23.5, 76.1) },
            { act = "complete", quest = "Rat Catching", text = "Tunnel Rat kobolds / ears around Silver Stream Mine (north-west of Thelsamar).", at = at(LOCH, 35.0, 35.0) },
            { act = "complete", quest = "In Defense of the King's Lands", text = "Stonesplinter Troggs in the southern hills / Valley of Kings.", at = at(LOCH, 32.0, 72.0) },
            { act = "complete", quest = "The Trogg Threat", text = "Trogg stone teeth from the same packs.", at = at(LOCH, 32.0, 72.0) },
            { act = "turnin",   quest = "Rat Catching", text = "Mountaineer Kadrell in Thelsamar.", at = at(LOCH, 34.2, 47.8) },
            { act = "turnin",   quest = "In Defense of the King's Lands", text = "Southern bunker Mountaineers — continue the chain if more parts open.", at = at(LOCH, 22.1, 73.1) },
            { act = "turnin",   quest = "The Trogg Threat", text = "Captain Rugelfuss.", at = at(LOCH, 23.2, 73.7) },
            { act = "accept",   quest = "Stormpike's Order", text = "Mountaineer Stormpike at Algaz Station (north of Thelsamar on the road).", at = at(LOCH, 24.8, 18.2) },
            { act = "accept",   quest = "Filthy Paws", text = "Mountaineer Stormpike — Silver Stream Mine again.", at = at(LOCH, 24.8, 18.2) },
            { act = "complete", quest = "Filthy Paws", text = "Miners' Gear inside Silver Stream Mine.", at = at(LOCH, 35.5, 24.0) },
            { act = "turnin",   quest = "Filthy Paws", text = "Mountaineer Stormpike.", at = at(LOCH, 24.8, 18.2) },
            { act = "go",       text = "East to Ironband's Excavation Site.", at = at(LOCH, 64.9, 66.7) },
            { act = "turnin",   quest = "Ironband's Excavation", text = "Magmar Fellhew at the dig site.", at = at(LOCH, 64.9, 66.7) },
            { act = "accept",   quest = "Gathering Idols", text = "Magmar Fellhew.", at = at(LOCH, 64.9, 66.7) },
            { act = "accept",   quest = "Excavation Progress Report", text = "Prospector Ironband at the dig.", at = at(LOCH, 65.9, 65.6) },
            { act = "complete", quest = "Gathering Idols", text = "Carved Stone Idols from troggs around the excavation.", at = at(LOCH, 68.0, 63.0) },
            { act = "turnin",   quest = "Gathering Idols", text = "Magmar Fellhew.", at = at(LOCH, 64.9, 66.7) },
            { act = "turnin",   quest = "Excavation Progress Report", text = "Jern Hornhelm in Thelsamar (or as directed).", at = at(LOCH, 37.2, 47.4) },
            { act = "accept",   quest = "Report to Ironforge", text = "Jern Hornhelm if offered.", at = at(LOCH, 37.2, 47.4) },
            { act = "accept",   quest = "Crocolisk Hunting", text = "Marek Ironheart in Thelsamar if available.", at = at(LOCH, 37.0, 47.0) },
            { act = "complete", quest = "Crocolisk Hunting", text = "Loch Crocolisks along the water.", at = at(LOCH, 50.0, 55.0) },
            { act = "accept",   quest = "A Hunter's Boast", text = "Daryl the Youngling at the lodge if you pass it.", at = at(LOCH, 83.0, 62.0) },
            { act = "complete", quest = "A Hunter's Boast", text = "Mountain Buzzards as required.", at = at(LOCH, 75.0, 60.0) },
            { act = "turnin",   quest = "A Hunter's Boast", text = "Daryl the Youngling.", at = at(LOCH, 83.0, 62.0) },
            { act = "accept",   quest = "A Hunter's Challenge", text = "Daryl — next part.", at = at(LOCH, 83.0, 62.0) },
            { act = "complete", quest = "A Hunter's Challenge", text = "Elder Mountain Boars.", at = at(LOCH, 70.0, 50.0) },
            { act = "turnin",   quest = "A Hunter's Challenge", text = "Daryl.", at = at(LOCH, 83.0, 62.0) },
            { act = "note",     text = "Dark Threat Looms chain starts at the dam (Chief Engineer Hinderweir). Do it when you are comfortable in the north; it leads toward Wetlands. At 13+ strongly consider Hall of Thanes (separate route) before leaving the area." },
            { act = "accept",   quest = "A Dark Threat Looms", text = "Chief Engineer Hinderweir VII at the Stonewrought Dam.", at = at(LOCH, 46.0, 13.6) },
            { act = "complete", quest = "A Dark Threat Looms", text = "Inspect the suspicious barrel / follow the chain steps at the dam.", at = at(LOCH, 56.0, 13.2) },
            { act = "turnin",   quest = "A Dark Threat Looms", text = "Continue the multi-part chain with Hinderweir until it sends you onward.", at = at(LOCH, 46.0, 13.6) },
            { act = "note",     text = "Loch Modan dense content done. Options: Hall of Thanes, south into Wetlands via the tunnel, or east/south toward Redridge once you have the level." },
        },
    },

    ------------------------------------------------------------------
    -- DARKSHORE (11-18) — primary after Teldrassil
    ------------------------------------------------------------------
    {
        id = "darkshore_11_18", title = "Darkshore 11-18", faction = "Alliance", author = "RUIN+DB",
        steps = {
            { act = "note",     text = "Arrive Auberdine by boat from Rut'theran. Grab flight path and set hearth if desired." },
            { act = "go",       text = "Auberdine hub — accept every quest on the docks, inn, and north/south edges before leaving town.", at = at(DARKSH, 37.0, 43.0) },
            { act = "accept",   quest = "Buzzbox 827", text = "Wizbang Cranktoggle or the Buzzbox chain starter in Auberdine.", at = at(DARKSH, 37.0, 44.0) },
            { act = "accept",   quest = "Washed Ashore", text = "Gwennyth Bly'Leggonde near the shore (beached creatures chain).", at = at(DARKSH, 36.6, 45.6) },
            { act = "accept",   quest = "How Big a Threat?", text = "Terenthis in Auberdine.", at = at(DARKSH, 39.3, 43.5) },
            { act = "accept",   quest = "Plagued Lands", text = "Tharnariun Treetender.", at = at(DARKSH, 38.8, 43.4) },
            { act = "accept",   quest = "The Red Crystal", text = "Sentinel Glynda Nal'Shea.", at = at(DARKSH, 37.7, 43.4) },
            { act = "accept",   quest = "Bashal'Aran", text = "Asterion at Bashal'Aran (pick up as you head north) or breadcrumb from town.", at = at(DARKSH, 44.2, 36.3) },
            { act = "accept",   quest = "Tools of the Highborne", text = "Thundris Windweaver in Auberdine.", at = at(DARKSH, 37.4, 40.1) },
            { act = "complete", quest = "Buzzbox 827", text = "Crawler legs / parts from coastal crawlers south of Auberdine.", at = at(DARKSH, 36.0, 50.0) },
            { act = "complete", quest = "Washed Ashore", text = "Inspect beached sea creatures along the south coast; there are several.", at = at(DARKSH, 36.0, 62.0) },
            { act = "turnin",   quest = "Buzzbox 827", text = "Buzzbox 827 device (or Wizbang as directed).", at = at(DARKSH, 36.7, 46.3) },
            { act = "accept",   quest = "Buzzbox 411", text = "Next Buzzbox step.", at = at(DARKSH, 36.7, 46.3) },
            { act = "complete", quest = "How Big a Threat?", text = "Blackwood Pathstalkers / furbolgs near the first camp east.", at = at(DARKSH, 39.0, 52.0) },
            { act = "complete", quest = "Plagued Lands", text = "Rabid Thistle Bears — use the trap item on one.", at = at(DARKSH, 39.0, 55.0) },
            { act = "complete", quest = "Tools of the Highborne", text = "Highborne relics among the ruins north/south of Bashal'Aran.", at = at(DARKSH, 43.0, 33.0) },
            { act = "complete", quest = "Bashal'Aran", text = "Work the full Bashal'Aran chain (grells → athrikus) while in the ruins.", at = at(DARKSH, 44.0, 36.0) },
            { act = "turnin",   quest = "How Big a Threat?", text = "Terenthis — accept follow-up if offered.", at = at(DARKSH, 39.3, 43.5) },
            { act = "turnin",   quest = "Plagued Lands", text = "Tharnariun.", at = at(DARKSH, 38.8, 43.4) },
            { act = "turnin",   quest = "Tools of the Highborne", text = "Thundris Windweaver.", at = at(DARKSH, 37.4, 40.1) },
            { act = "turnin",   quest = "Bashal'Aran", text = "Asterion — finish remaining chain parts.", at = at(DARKSH, 44.2, 36.3) },
            { act = "complete", quest = "Buzzbox 411", text = "Threshalon tails from the deeper coast / north.", at = at(DARKSH, 42.0, 28.0) },
            { act = "turnin",   quest = "Buzzbox 411", text = "Buzzbox 411.", at = at(DARKSH, 42.0, 28.0) },
            { act = "accept",   quest = "Buzzbox 323", text = "Continue Buzzbox chain.", at = at(DARKSH, 42.0, 28.0) },
            { act = "complete", quest = "The Red Crystal", text = "Locate the red crystal east of Auberdine / follow Sentinel instructions.", at = at(DARKSH, 47.0, 49.0) },
            { act = "turnin",   quest = "The Red Crystal", text = "Sentinel Glynda — accept As Water Cascades if offered.", at = at(DARKSH, 37.7, 43.4) },
            { act = "complete", quest = "Buzzbox 323", text = "Moonstalker fangs from cats in the central woods.", at = at(DARKSH, 45.0, 40.0) },
            { act = "turnin",   quest = "Buzzbox 323", text = "Buzzbox 323.", at = at(DARKSH, 51.3, 24.6) },
            { act = "note",     text = "Clear remaining beached creatures, Ameth'Aran ruins, and any Grove of the Ancients breadcrumbs. Boat to Stormwind/Menethil when ready for Eastern Kingdoms, or continue south toward Ashenvale." },
        },
    },

    ------------------------------------------------------------------
    -- REDRIDGE (15-22) — after Westfall / Loch Modan
    ------------------------------------------------------------------
    {
        id = "redridge_15_22", title = "Redridge 15-22", faction = "Alliance", author = "RUIN+DB",
        steps = {
            { act = "note",     text = "Enter from Elwynn (east road) or Three Corners. Lakeshire is the hub — accept all before leaving town." },
            { act = "go",       text = "Lakeshire. Grab flight path. Accept every board and NPC quest in town.", at = at(REDRIDGE, 27.0, 47.0) },
            { act = "accept",   quest = "Messenger to Stormwind", text = "Magistrate Solomon in the town hall.", at = at(REDRIDGE, 30.0, 44.5) },
            { act = "accept",   quest = "The Lost Tools", text = "Foreman Oslow on the dock/bridge area.", at = at(REDRIDGE, 32.1, 48.6) },
            { act = "accept",   quest = "Encroaching Gnolls", text = "Guard Howe or Deputy Feldon near the bridge.", at = at(REDRIDGE, 30.8, 46.0) },
            { act = "accept",   quest = "The Everstill Bridge", text = "Foreman Oslow.", at = at(REDRIDGE, 32.1, 48.6) },
            { act = "accept",   quest = "Selling Fish", text = "Dockmaster Baren.", at = at(REDRIDGE, 27.7, 47.3) },
            { act = "accept",   quest = "A Free Lunch", text = "Darcy in the inn / hall.", at = at(REDRIDGE, 26.8, 44.2) },
            { act = "accept",   quest = "Underbelly Scales", text = "Verner Osgood if present (black dragon whelps).", at = at(REDRIDGE, 31.0, 47.0) },
            { act = "complete", quest = "The Lost Tools", text = "Oslow's Toolbox in the lake east of the bridge (murloc area).", at = at(REDRIDGE, 41.5, 54.6) },
            { act = "complete", quest = "Selling Fish", text = "Spotted Sunfish from murlocs in Lake Everstill.", at = at(REDRIDGE, 40.0, 50.0) },
            { act = "complete", quest = "Encroaching Gnolls", text = "Gnolls north/east of Lakeshire — assess and kill as required.", at = at(REDRIDGE, 30.0, 35.0) },
            { act = "complete", quest = "The Everstill Bridge", text = "Gnoll fangs / related from the same camps for bridge supplies.", at = at(REDRIDGE, 30.0, 35.0) },
            { act = "complete", quest = "Underbelly Scales", text = "Black dragon whelps south/east of the lake if on the quest.", at = at(REDRIDGE, 43.0, 70.0) },
            { act = "turnin",   quest = "A Free Lunch", text = "Guard Parker south of Lakeshire on the road — then return the note.", at = at(REDRIDGE, 15.3, 71.5) },
            { act = "turnin",   quest = "The Lost Tools", text = "Foreman Oslow.", at = at(REDRIDGE, 32.1, 48.6) },
            { act = "turnin",   quest = "Selling Fish", text = "Dockmaster Baren.", at = at(REDRIDGE, 27.7, 47.3) },
            { act = "turnin",   quest = "Encroaching Gnolls", text = "Guard Howe / Deputy — accept Assessing the Threat if offered.", at = at(REDRIDGE, 30.8, 46.0) },
            { act = "turnin",   quest = "The Everstill Bridge", text = "Foreman Oslow.", at = at(REDRIDGE, 32.1, 48.6) },
            { act = "turnin",   quest = "Underbelly Scales", text = "Verner Osgood.", at = at(REDRIDGE, 31.0, 47.0) },
            { act = "complete", quest = "Assessing the Threat", text = "More gnoll camps further out if you took the follow-up.", at = at(REDRIDGE, 35.0, 25.0) },
            { act = "turnin",   quest = "Assessing the Threat", text = "Lakeshire guards.", at = at(REDRIDGE, 30.8, 46.0) },
            { act = "turnin",   quest = "Messenger to Stormwind", text = "General Marcus Jonathan in Stormwind (or complete the messenger circuit when convenient).", at = at("Stormwind City", 69.0, 82.0) },
            { act = "note",     text = "Wanted posters (Gath'Ilzogg, Lieutenant Fangore) are elite — do with a group or at the high end of the range. Solomon's Law and Blackrock Bounty open as you level. When done, head west/south into Duskwood or north toward Wetlands/Menethil via the road." },
        },
    },

    ------------------------------------------------------------------
    -- DUSKWOOD (20-28)
    ------------------------------------------------------------------
    {
        id = "duskwood_20_28", title = "Duskwood 20-28", faction = "Alliance", author = "RUIN+DB",
        steps = {
            { act = "note",     text = "Enter from Redridge (south) or Elwynn/Westfall. Darkshire is the hub — accept all town quests first." },
            { act = "go",       text = "Darkshire. Flight path, inn, and every quest giver in town.", at = at("Duskwood", 74.0, 46.0) },
            { act = "accept",   quest = "The Night Watch", text = "Commander Althea Ebonlocke in Darkshire.", at = at("Duskwood", 73.6, 46.9) },
            { act = "accept",   quest = "Wolves at Our Heels", text = "Calor or related wolf quest near town.", at = at("Duskwood", 74.0, 45.0) },
            { act = "accept",   quest = "Raven Hill", text = "Elaine Carevin or Jitters breadcrumb toward Raven Hill.", at = at("Duskwood", 75.3, 48.7) },
            { act = "accept",   quest = "Deliveries to Sven", text = "Accept when you pick up the Raven Hill / Sven line.", at = at("Duskwood", 75.3, 48.7) },
            { act = "accept",   quest = "The Legend of Stalvan", text = "Clerk Daltry in the town hall — long chain, pick up early.", at = at("Duskwood", 72.5, 46.9) },
            { act = "accept",   quest = "Look to the Stars", text = "Viktori Prism'Antras.", at = at("Duskwood", 79.8, 48.0) },
            { act = "accept",   quest = "The Totem of Infliction", text = "Madame Eva.", at = at("Duskwood", 75.8, 45.3) },
            { act = "complete", quest = "Wolves at Our Heels", text = "Starving Dire Wolves / Rabid around the roads west of Darkshire.", at = at("Duskwood", 60.0, 45.0) },
            { act = "complete", quest = "The Night Watch", text = "Skeletal Warriors / Horror first wave near Tranquil Gardens or cemetery.", at = at("Duskwood", 79.0, 70.0) },
            { act = "turnin",   quest = "Wolves at Our Heels", text = "Darkshire.", at = at("Duskwood", 74.0, 45.0) },
            { act = "turnin",   quest = "The Night Watch", text = "Commander Althea — accept next Night Watch parts as they open.", at = at("Duskwood", 73.6, 46.9) },
            { act = "go",       text = "West toward Raven Hill. Deliver to Jitters and Sven as the chain directs.", at = at("Duskwood", 18.0, 56.0) },
            { act = "turnin",   quest = "Raven Hill", text = "Jitters at Raven Hill.", at = at("Duskwood", 18.4, 56.4) },
            { act = "accept",   quest = "Jitters' Growling Gut", text = "Jitters.", at = at("Duskwood", 18.4, 56.4) },
            { act = "turnin",   quest = "Deliveries to Sven", text = "Sven Yorgen at his camp.", at = at("Duskwood", 7.8, 34.1) },
            { act = "accept",   quest = "Sven's Revenge", text = "Sven.", at = at("Duskwood", 7.8, 34.1) },
            { act = "complete", quest = "Sven's Revenge", text = "Mound of loose dirt at the farm (The Rotting Orchard / related).", at = at("Duskwood", 49.9, 77.7) },
            { act = "turnin",   quest = "Sven's Revenge", text = "Continue Sven / Shadowy Figure chain (Abercrombie, Darkshire inn, etc.).", at = at("Duskwood", 7.8, 34.1) },
            { act = "accept",   quest = "Supplies from Darkshire", text = "Abercrombie the hermit when you reach him.", at = at("Duskwood", 28.0, 31.5) },
            { act = "turnin",   quest = "Supplies from Darkshire", text = "Madame Eva — Ghost Hair Thread line.", at = at("Duskwood", 75.8, 45.3) },
            { act = "accept",   quest = "Ghost Hair Thread", text = "Madame Eva.", at = at("Duskwood", 75.8, 45.3) },
            { act = "complete", quest = "Ghost Hair Thread", text = "Blind Mary south-east of Darkshire.", at = at("Duskwood", 82.0, 59.0) },
            { act = "turnin",   quest = "Ghost Hair Thread", text = "Madame Eva — continue Zombie Juice / Deliver the Thread chain through Abercrombie.", at = at("Duskwood", 75.8, 45.3) },
            { act = "complete", quest = "The Totem of Infliction", text = "Ghoul fangs, Vials of Venom, Skeleton fingers from the various undead camps.", at = at("Duskwood", 80.0, 70.0) },
            { act = "turnin",   quest = "The Totem of Infliction", text = "Madame Eva.", at = at("Duskwood", 75.8, 45.3) },
            { act = "complete", quest = "Look to the Stars", text = "Work Viktori's instrument parts (Mary, ogre, etc.) as the chain steps require.", at = at("Duskwood", 79.8, 48.0) },
            { act = "note",     text = "Finish Night Watch parts, Stalvan chain (multi-zone), and remaining Raven Hill / Worgen content. Duskwood pairs well with Wetlands runs and Deadmines/Stockade at the low end of the bracket." },
        },
    },

    ------------------------------------------------------------------
    -- WETLANDS (20-30)
    ------------------------------------------------------------------
    {
        id = "wetlands_20_30", title = "Wetlands 20-30", faction = "Alliance", author = "RUIN+DB",
        steps = {
            { act = "note",     text = "Enter from Loch Modan (north tunnel) or boat to Menethil Harbor. Menethil is the hub." },
            { act = "go",       text = "Menethil Harbor. Flight path, inn, and all dock/hall quests.", at = at("Wetlands", 10.0, 56.0) },
            { act = "accept",   quest = "Claws from the Deep", text = "Karl Boran on the docks.", at = at("Wetlands", 8.3, 58.5) },
            { act = "accept",   quest = "Young Crocolisk Skins", text = "James Halloran.", at = at("Wetlands", 8.5, 55.7) },
            { act = "accept",   quest = "The Third Fleet", text = "First Mate Fitzsimmons in the inn.", at = at("Wetlands", 10.9, 59.6) },
            { act = "accept",   quest = "The Greenwarden", text = "First Mate Fitzsimmons or related.", at = at("Wetlands", 10.9, 59.6) },
            { act = "accept",   quest = "Digging Through the Ooze", text = "Sida in Menethil.", at = at("Wetlands", 11.8, 58.0) },
            { act = "complete", quest = "Claws from the Deep", text = "Bluegill Murlocs on the west shore; kill Gobbler for his head.", at = at("Wetlands", 18.0, 40.0) },
            { act = "complete", quest = "Young Crocolisk Skins", text = "Young Wetlands Crocolisks along the waterways.", at = at("Wetlands", 20.0, 50.0) },
            { act = "turnin",   quest = "Claws from the Deep", text = "Karl Boran.", at = at("Wetlands", 8.3, 58.5) },
            { act = "turnin",   quest = "Young Crocolisk Skins", text = "James Halloran — accept follow-ups.", at = at("Wetlands", 8.5, 55.7) },
            { act = "complete", quest = "The Third Fleet", text = "Buy Flagon of Mead from innkeeper and return to Fitzsimmons.", at = at("Wetlands", 10.7, 61.0) },
            { act = "turnin",   quest = "The Third Fleet", text = "First Mate Fitzsimmons — open the curse/fleet chain.", at = at("Wetlands", 10.9, 59.6) },
            { act = "go",       text = "East toward the Greenwarden and raptor areas. Pick up any roadside quests.", at = at("Wetlands", 56.0, 40.0) },
            { act = "turnin",   quest = "The Greenwarden", text = "Rethiel the Greenwarden.", at = at("Wetlands", 56.3, 40.4) },
            { act = "accept",   quest = "Tramping Paws", text = "Rethiel.", at = at("Wetlands", 56.3, 40.4) },
            { act = "complete", quest = "Tramping Paws", text = "Mosshide gnolls east/south of the Greenwarden.", at = at("Wetlands", 62.0, 45.0) },
            { act = "turnin",   quest = "Tramping Paws", text = "Rethiel — continue Fire Taboo / related if offered.", at = at("Wetlands", 56.3, 40.4) },
            { act = "complete", quest = "Digging Through the Ooze", text = "Sida's bag from oozes near the excavated / ironbeard areas.", at = at("Wetlands", 44.0, 26.0) },
            { act = "turnin",   quest = "Digging Through the Ooze", text = "Sida in Menethil.", at = at("Wetlands", 11.8, 58.0) },
            { act = "note",     text = "Whelgar's Excavation, raptor nest, and Excavation Site dungeon quests open in the mid/high 20s. Do the new Forever Excavation Site dungeon with all quests once you hit its range (~24-29). Remaining Menethil fleet/curse chain is worth finishing." },
        },
    },

    ------------------------------------------------------------------
    -- ASHENVALE (18-28) — strong for Night Elves after Darkshore
    ------------------------------------------------------------------
    {
        id = "ashenvale_18_28", title = "Ashenvale 18-28", faction = "Alliance", author = "RUIN+DB",
        steps = {
            { act = "note",     text = "Enter from Darkshore (south road) or boat/flight. Astranaar is the main Alliance hub." },
            { act = "go",       text = "Astranaar. Flight path and every quest in town.", at = at("Ashenvale", 36.0, 50.0) },
            { act = "accept",   quest = "The Zoram Strand", text = "Accept coastal breadcrumbs when you head west.", at = at("Ashenvale", 34.0, 48.0) },
            { act = "accept",   quest = "Raene's Cleansing", text = "Raene Wolfrunner in Astranaar — long valuable chain.", at = at("Ashenvale", 36.6, 49.6) },
            { act = "accept",   quest = "Culling the Threat", text = "Raene or nearby.", at = at("Ashenvale", 36.6, 49.6) },
            { act = "accept",   quest = "The Ashenvale Hunt", text = "Accept from the hunt board / NPCs if present.", at = at("Ashenvale", 37.0, 50.0) },
            { act = "complete", quest = "Culling the Threat", text = "Dal Bloodclaw (furbolg) north of Astranaar.", at = at("Ashenvale", 37.0, 35.0) },
            { act = "turnin",   quest = "Culling the Threat", text = "Astranaar.", at = at("Ashenvale", 36.6, 49.6) },
            { act = "go",       text = "West to the Zoram Strand for naga / ruins quests.", at = at("Ashenvale", 14.0, 25.0) },
            { act = "complete", quest = "The Zoram Strand", text = "Wrathtail naga heads / related on the strand.", at = at("Ashenvale", 14.0, 23.0) },
            { act = "turnin",   quest = "The Zoram Strand", text = "Talren Highbough or as directed back toward Astranaar / Maestra's Post.", at = at("Ashenvale", 26.0, 38.0) },
            { act = "complete", quest = "Raene's Cleansing", text = "Work Raene's multi-part chain (dartol's rod, elemental, furbolg) as steps open — high XP.", at = at("Ashenvale", 50.0, 55.0) },
            { act = "note",     text = "Maestra's Post, Falathim, and eastern outposts add more density. Blackfathom Deeps quests become relevant mid-bracket. Rotate with Stonetalon or return to EK dungeons as needed." },
        },
    },
}
