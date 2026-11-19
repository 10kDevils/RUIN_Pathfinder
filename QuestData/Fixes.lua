-- RUIN Quest Data: corrections from QuestieDB's development version
-- QuestieDB merged a WoW Forever data refresh (the November 18 scrape) after
-- its 1.1.3 release. These rows take its quest levels, minimum levels and quest
-- givers where they differ from 1.1.3. Givers that RUIN Quest Data doesn't
-- carry are left out. Licensed under the GNU GPL v3 (see LICENSE and NOTICE).
-- r = minimum level, l = quest level, s1/s2/s3 = started by NPC/object/item,
-- e1/e2 = finished by NPC/object.
local D = RUIN_QuestData
if not (D and D.q) then return end
local function X(id, f)
    local q = D.q[id]
    if not q then return end
    if f.r then q[4] = f.r end
    if f.l then q[5] = f.l end
    for k = 1, 3 do
        if f["s" .. k] then q[2] = type(q[2]) == "table" and q[2] or {}; q[2][k] = f["s" .. k] end
        if f["e" .. k] then q[3] = type(q[3]) == "table" and q[3] or {}; q[3][k] = f["e" .. k] end
    end
end
X(472, {l=30}) -- Fall of Dun Modr
X(631, {r=26}) -- The Thandol Span
X(632, {r=26}) -- The Thandol Span
X(633, {r=26}) -- The Thandol Span
X(7790, {r=53, l=57}) -- River Ends
X(78823, {s3={211269}}) -- Terror of the Desert Skies
X(80453, {r=45}) -- Best Laid Plans
X(80454, {r=45}) -- One Last Drop
X(80455, {r=45}) -- Biding Our Time
X(81885, {r=45, s1={221587}, e1={221587}}) -- The Ritual
X(82062, {r=48, e1={222530}}) -- Ever After
X(82135, {r=44, s1={221587}, e1={5492}}) -- The Price of Hope
X(84135, {r=55}) -- Beach Bot
X(84137, {r=55}) -- Mechanical Romance
X(84138, {r=55}) -- Frosty Favors
X(84146, {r=55}) -- Red Bag Blues
X(84151, {r=58, e1={230319}}) -- An Earnest Proposition
X(84152, {r=58, e1={230319}}) -- An Earnest Proposition
X(84153, {r=58, s1={230319}, e1={230319}}) -- An Earnest Proposition
X(84163, {r=58, s1={230319}, e1={230319}}) -- Just Compensation
X(84166, {r=58, s1={230319}, e1={230319}}) -- Just Compensation
X(84171, {r=58, s1={230317}, e1={230317}}) -- Just Compensation
X(84211, {r=58, e1={228216}}) -- Poacher's Den
X(84212, {r=58, s1={228216}, e1={228956}}) -- Bookin' it Back
X(84332, {r=54}) -- A Thane's Gratitude
X(84377, {r=60}) -- End of the Dark Horde
X(84394, {r=50, l=58, s1={5497}, e1={5497,7825}}) -- Greater Friend of the Library
X(84414, {r=54}) -- Send Me On Me Way
X(86577, {r=48}) -- A Sampling of Putrescence
X(86620, {r=40}) -- Fledgling Rescue
X(86752, {r=47}) -- Report to Rageroar
X(86757, {r=25}) -- Slowing the Orc Advance
X(86777, {r=47}) -- Master Feardred
X(86791, {r=47}) -- Missing Blackmaw Scouts
X(86792, {r=47}) -- Thinning Their Forces
X(86796, {r=47}) -- Later, Satyr
X(86797, {r=47}) -- Return to Rageroar
X(86799, {r=47}) -- Encroaching Corruption
X(86812, {r=47}) -- Transmuted Tincture
X(86813, {r=47}) -- Potential Panacea
X(86814, {r=47}) -- Blackmaw Counter-Offensive
X(86925, {r=47}) -- Toil and Trouble
X(86926, {r=47}) -- Felfire Burn, Cauldron Bubble
X(86927, {r=47}) -- Running Firewater
X(87491, {r=25}) -- Spark of Freedom
X(88756, {r=25}) -- Bring Back a Bang
X(90647, {r=54}) -- The Staff of the Mountain
X(90854, {r=54}) -- Leather for Inclement Weather
X(90865, {r=54}) -- Eyes of the Watchers
X(91564, {r=54}) -- Itching for a Fixing
X(91697, {r=54}) -- Meet the Elders
X(91698, {r=54}) -- Barkskin Breakout
X(91723, {r=6}) -- Delicate Instruments
X(91755, {r=54}) -- Leaves to Ligatures
X(91883, {r=55}) -- Spear of the Skylord
X(91923, {r=54}) -- Celastrus the Bitter
X(92009, {r=54}) -- Crate Expectations
X(92016, {r=56}) -- Rootwork
X(92017, {r=56}) -- Cleansing Winds
X(92065, {r=47, e1={236573}}) -- Blackmaw Reclamation
X(92066, {r=47}) -- The Twin Bears
X(92070, {r=47, s3={249698}}) -- A Lost Memento
X(92094, {r=52}) -- Rocket Gnomes
X(92100, {r=54}) -- Anywhere But Here
X(92102, {r=54}) -- Praise
X(92169, {r=54}) -- Paying Back the Pact
X(92171, {r=54}) -- Taking to New Heights
X(92189, {r=54}) -- Back to the Grind
X(92328, {r=54}) -- Siegecraft
X(92329, {r=54}) -- Drum Up Trouble
X(92433, {r=54}) -- Now We're Cooking
X(92533, {r=56}) -- Twisted Tools
X(92707, {s3={253711}}) -- The Giant in the Den
X(92754, {e1={253097}}) -- A New Need for Shadow Protection
X(92844, {r=35}) -- Mountain of Bones
X(92847, {r=35}) -- Corrupting Tears
X(92873, {r=35}) -- Proof of Concept
X(92893, {r=35}) -- No Mercy for the Weak
X(92894, {r=35}) -- Bone Raising
X(92914, {r=35}) -- Strange Pylons
X(92959, {r=55}) -- The Dying Ancients
X(93035, {r=35}) -- Ravaging Ravagers
X(93037, {r=35}) -- Outing Outcasts
X(93041, {r=35}) -- Facing the Truth
X(93045, {r=35}) -- Test Your Theory
X(93058, {r=35}) -- Saving Our Own
X(93062, {r=35}) -- Bone Burying
X(93066, {r=35}) -- Bristleback Retreat
X(93125, {r=35}) -- Going Home
X(93341, {r=35}) -- Forlorn Gardens
X(93362, {r=35}) -- What They've Done to My Peonies
X(93394, {r=35}) -- Meeting the Magister
X(93404, {r=35}) -- Rot and Regret
X(93406, {r=56}) -- Unfrozen Deliveries
X(93422, {r=54}) -- Blackthorne Blackout
X(93444, {r=56}) -- Bait the Beast
X(93450, {r=35}) -- Phantasmal Problems
X(93521, {r=57}) -- Challenger of the Gods
X(93546, {r=35}) -- Spectral Iron Ore
X(93547, {r=57}) -- A Thorny Solution
X(93551, {r=54}) -- Praise
X(93574, {r=35}) -- Corpsefeeder's Carapace
X(93594, {r=35}) -- Word of the Woods
X(93604, {r=35}) -- Agamaggan's Blood
X(93606, {r=35}) -- Not on Squealing Terms
X(93609, {r=35}) -- Forlorn Necklace
X(93615, {r=54}) -- Kits and Cats
X(93747, {r=54}) -- Violence Into Verdure
X(93759, {r=54}) -- The Bounty of Nature
X(93825, {r=54}) -- Barkbound Blessings
X(93828, {r=54}) -- Herbs of the Hollow
X(93830, {r=54}) -- Water of Hyjal
X(93833, {r=54}) -- Wicked Wisdom
X(93834, {r=54}) -- Burrow Beetles
X(93848, {r=54}) -- Work Well Done
X(93952, {r=54}) -- Balance Through Strength
X(94276, {e1={262306}}) -- Craftsman's Writ: Wicked Mithril Blade
X(94399, {e1={11701}}) -- Ravasaur Provisions
X(94926, {s3={266889}}) -- Drop the Hammer
X(94961, {r=36}) -- Biting the Hand
X(95120, {r=36}) -- WANTED: Old Rot-Chum
X(95122, {r=38}) -- Unchecked Expansion
X(95123, {r=38}) -- A Blast Ye Scurvy Dogs!
X(95124, {r=38}) -- Admiral Lamora
X(95261, {r=38}) -- It Takes Guts
X(95273, {r=54}) -- Water of Hyjal
X(95288, {r=38}) -- Smuggler's Paradise
X(95294, {r=38}) -- Smuggler's Bargain
X(95316, {r=54}) -- The Experimental Method
X(95317, {r=54}) -- Notation, Notation, Notation
X(95319, {r=54}) -- Crystalline Collection
X(95321, {r=36}) -- Tazzik's Dues
X(95322, {r=36}) -- Get the Goods
X(95325, {r=36}) -- We've Been Robbed!
X(95326, {r=36}) -- The Big Payback
X(95379, {r=54}) -- A Revenge So Sweet
X(95380, {r=54}) -- A Prolific Source
X(95599, {r=35}) -- The Old Key
X(95611, {r=54}) -- Rites of Respect
X(95753, {r=37}) -- Challenge of the Desert Wolf
X(95769, {r=54}) -- Threading a Solution
X(95934, {r=36}) -- Proof of Profit
X(96003, {r=54}) -- Drawing Down the Malevolent
X(96010, {r=35}) -- Fragments of the Pylons
X(96018, {r=35}) -- Powering the Pylons
X(96060, {r=35}) -- Tempered Expectations
X(96063, {r=36}) -- Gaseous Gold
X(96067, {r=36}) -- Rock 'em and Sock 'em
X(96075, {r=60, s1={227853}, e1={227853}}) -- In Demand - Blackrock Legal Records
X(96076, {r=60}) -- In Demand - Ancient Elven Curiosities
X(96246, {r=55, l=60, s1={235903}, e1={235903}}) -- Blackmaw Pouches
X(96252, {r=55}) -- Tarnished Treasures
X(96255, {r=54}) -- Amalgamated Marrow
X(96262, {r=54}) -- Prickly Pinecones
X(96303, {r=54}) -- Memory Mist
X(96322, {r=54}) -- A Revenge Now Bitter
X(96337, {r=48}) -- More Valuable Than Gold
X(96377, {s1={6946}}) -- State Secrets
X(96435, {r=54}) -- A Fitting End
X(96550, {r=54}) -- Battle Recall
X(96602, {r=48, l=58}) -- More Unstable Magic
X(96666, {r=54}) -- Burrow Bonding
X(96912, {r=60}) -- Field of Honor: Week 1
X(96931, {r=54}) -- Heading Up the Mountain
X(96979, {r=56}) -- Sacred Refreshment
X(96983, {r=56}) -- Yashiro's Windwalk
X(97010, {r=56}) -- Blind Vengeance
X(97176, {r=60}) -- Exorcising Terrordale
X(97180, {r=60}) -- Ott's Finest Work
X(97182, {r=60}) -- An Offering of Vengeance
X(97183, {r=60, e1={246378}}) -- Blessed Arcanite Barding
X(97184, {r=60, s1={246378}, e1={246378}}) -- The Divination Scryer
X(97185, {r=60, s1={246378}}) -- Justice and Retribution
X(97186, {r=60, e1={11878}}) -- Manna-Enriched Horse Feed
X(97327, {r=55}) -- Blackmaw Pouches
X(97412, {r=58}) -- Just Compensation
X(97490, {r=56}) -- Halt the Hail
X(97540, {r=40}) -- Oasis
X(97663, {r=34}) -- Supplies and Studies
X(97821, {r=37}) -- Mirage Mirror
X(97883, {r=60}) -- End of the Dark Horde
X(98069, {r=25}) -- Stolen Freewind Supplies
X(98070, {r=25}) -- Stop the Screeching
X(98096, {r=45}) -- Sisters In Duty
X(98205, {r=39}) -- Whelps are the Worst!
X(98215, {r=39}) -- Dragon Scales, Post Burnt Tails
X(98231, {r=39}) -- Active Ingredient
X(98462, {r=55}) -- Shroud of the Winter Wilds
X(98476, {r=48, l=58}) -- More Unstable Magic
X(99048, {r=8}) -- A Missing Hand
X(99049, {r=8}) -- Threat from Below
X(99201, {r=60}) -- Swift as the Wind
X(99202, {r=60}) -- Swift as the Wind
X(99203, {r=60, s1={265756}}) -- Swift as the Wind
X(99204, {r=60, s1={4752}}) -- Swift as the Wind
X(99206, {r=60}) -- Swift as the Wind
X(99213, {r=60}) -- An Epic Ride
X(99214, {r=60, s1={4730}, e1={4730}}) -- An Epic Ride
X(99215, {r=60, s1={3362}, e1={3362}}) -- An Epic Ride
X(99216, {r=60}) -- An Epic Ride
X(99257, {r=35}) -- A Heart of Crystal
X(99258, {r=35}) -- Mana Mania
X(99670, {r=54}) -- Return to Jereman
-- Krol'dok Moulding (Horde) starts from its own copy of the mould, which Tunk drops
if D.i and not D.i[267137] then D.i[267137] = { "Krol'dok Moulding", { 259256 }, nil, nil, 94973 } end
X(94973, { s3 = { 267137 } }) -- Krol'dok Moulding
