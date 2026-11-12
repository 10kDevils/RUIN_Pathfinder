# RUIN Pathfinder changelog

Versioning: the third number counts the meaningful changes made since the second number last went up.

## Unreleased

(nothing yet)

## 0.6.1 — 2026-11-11

- Pathfinder never changes the game's tracked quest or waypoint during combat, from any path (closing the tracker's Tracked tab or clearing the waypoint could still do it), and doesn't set the tracked quest again when it's already the one tracked. Whatever waited is caught up when combat ends.
- Pathfinder has its own quest database now: RUIN Quest Data, a new addon in the suite with every WoW Forever quest and the NPCs, objects and items they use (see its NOTICE file for where the data comes from). Zone routes, dungeon quest routes, waypoints and quest tooltips all read from it, and Pathfinder no longer looks for any other quest addon.
- Routes walk less: after the quick passes, a search over the whole order (simulated annealing, a fixed number of tries so the same quests always give the same route) tries moving every stop anywhere the quest order allows. On the real quest data it took about 6% off the walking of zone routes the quick passes made, and up to 30% on some. Quests on neighbouring maps now count as the real distance apart (Elwynn's edge to Westfall's is a short walk) instead of one flat trip across the world.
- Pathfinder no longer looks for any other quest addon; it reads RUIN Quest Data only, and the wording on the Routes and Quests pages, the tooltips and drafted routes says "quest database".
- Quests that share a target are done in one step: when two or more quests in a route kill, loot or use the same NPCs or objects (or need items dropped by them), they get one "do" step named for all of them ("Q1 + Q2"), done once every one of them is ready to hand in. A quest that only opens after another is never folded into that one's step.
- A new route planner for the zone routes. Every quest is a pick-up, its objectives and a hand-in, and the planner orders them for the shortest walk: quest givers standing together are picked up together, objectives in the same area are done one after another, and hand-ins are gathered into one visit, while a quest is still picked up only after the quests it needs are handed in. Objectives are aimed at the busiest part of their area. A 60-quest plan is about 15% shorter than walking to the nearest stop each time.
- Pathfinder's atlas: where RUIN members really pick up, do and hand in quests on WoW Forever, learned while playing and shared with RUIN (only quest numbers and map spots; Options > Waypoint > Share quest locations with RUIN). A pick-up or hand-in seen twice comes before the quest database's data, and objective sightings join the quest database's, so routes and waypoints follow where things are on WoW Forever, including its new and moved quests. A place WoW Forever moved takes over once it's been seen as often as the old one. `/path atlas` shows what's known.
- Key bindings: the original Open Pathfinder, Next step and Previous step bindings are back (0.6.0 had renamed them, which lost keys you'd set), beside the new Clear the route and Show or hide the RUIN pin.

## 0.6.0 — 2026-11-11

- Plays nicer with the game's objective tracker: Pathfinder never changes what the game tracks during combat (it catches up when combat ends), stops tracking your quest when you untrack it in the game instead of re-tracking it a few seconds later, ignores its own tracking changes when deciding what you picked, and only retries a waypoint on the Route tab when the step has a place.
- The tracker shows all of a step's or quest's text: it widens first, and past its widest it grows taller instead of cutting the text off. On Tracked, each objective has its own line, and the tracker grows taller to fit them.
- The step's pin on the minimap and world map is the round RUIN emblem on a soft shadow, matching the waypoint pin.
- Waypoint Editor (Options > RUIN pin, or `/path editor`): turn each part of the pin on or off (the card, its label, the name, the quest objectives, the marker, the stem and ground dot, the distance, the walking time, the edge arrow) and pick the marker style (emblem or dot), the name size, the card's darkness and the pin's size, with a live preview of the pin on screen and at the screen edge. Without the marker the card sits on top of the stem, and without both it sits right where the ground dot would be. The card is only as wide as its text. Reset puts it back. The nudges and hide settings stay in Options.
- The pin's dot now sits on the spot (a touch above rather than below), at every pin size: the size setting had been shifting it. Options > RUIN pin has Up / down and Left / right nudges (5 pixels a click, 0 to reset) to fine-tune where it sits.
- The tracker has two tabs above it, like the chat window's, that fade in while the mouse is over it: Route (the route) and Tracked (the quest you picked in the objective tracker, with its objectives). A tab with nothing to show is greyed out and can't be picked. The world pin follows the selected tab: the route's step on Route, your quest on Tracked; picking a quest in the objective tracker opens Tracked.
- A simpler tracker: small round < and > buttons centered on its sides (on Tracked they step through your quest log), a little x in the top-right corner to leave the route or stop tracking, and a double-click opens Pathfinder on the Guide or on your quest in the Quests tab. It keeps a fixed height and grows wider for longer text: from its left edge in the left third of the screen, from its right edge in the right third, and from the middle in between. Followers and RUIN members on your step show on the title line.
- The pin always hides inside the tracked quest's objective area (near the places its objectives are found, from the quest database), and fades out over half a second rather than vanishing.
- The pin steps aside once you're inside the area of the quest you're tracking (or nearer than a distance you choose, 15 yards to start).
- New Options tab: the tracker (show it, its arrow and map pin, skip done quests, say waypoints in chat), the waypoint (on each step, track quest steps the game's way, turn on In-Game Navigation), and the RUIN pin (on or off, hide in the quest's area, hide distance, objectives, walking time, edge arrow, size). The Guide's "Arrow + pin" box is now "Waypoint", which turns the step waypoints on or off; the waypoint no longer depends on the tracker arrow.
- Key bindings under Keybindings > AddOns > RUIN Pathfinder: next step, previous step, clear the route, show or hide the pin, open Pathfinder.
- New RUIN waypoint pin over whatever the game is navigating to (the quest you select in the objective tracker, a map pin, or Pathfinder's step): the RUIN emblem on a fine stem to a dot on the ground, a dark card above it with the label, the name and a tracked quest's objectives (marked - like the quest log, green when finished), and the distance and walking time in a small tag below. Off screen it waits at the edge with an arrow pointing the way; it shows a check when you arrive. It replaces the game's own marker while it's on; `/path pin` switches back.
- Quest steps whose quest is in your log are tracked the game's own way, like clicking the quest in the objective tracker, so the pin follows its objective or turn-in. A quest the game can't place falls back to a waypoint on Pathfinder's spot.
- Publish shows only to officers and up, and only on routes an officer (or higher) made; built-in routes and members' routes no longer have it. Approving a member's shared route from the inbox is unchanged.
- A step with no place of its own (a note) points the arrow, map pin and waypoint at the next step that has one.
- The world pin needs the game's In-Game Navigation option, which can be off; Pathfinder turns it on when it places a waypoint and says so once.
- `/path nav` prints each link from the step to the arrow and the world pin (the step's spot, your position, world positions, facing, the waypoint), to find where it breaks. The waypoint is retried every few seconds until it can be placed, and the arrow uses the game's navigation arrow art when the client has it.
- The step gets the game's own waypoint: a pin in the world over the spot with the distance under it, plus its map pin. It moves with each step and goes away when you clear the route; a waypoint you place yourself is only replaced at the next step. Part of the Arrow + pin option; `/path waypoint` turns just the world pin off or on.
- The tracker's arrow works on WoW Forever's client (it never showed before) and points to steps in neighbouring zones too (needs RUIN Core 0.6.0). When the step is on another continent, the corner names its zone.
- The tracker is wider and grows taller to fit a long step, so the text no longer runs under the Clear, Open, < and > buttons. The zone (or distance) sits in the top-right corner, right-justified, with the arrow below it.

## 0.5.2 — 2026-11-08

- The tracker has an Open button (beside < and >) that opens Pathfinder on the Guide.
- Clear the route you're on without starting another: Clear on the tracker, Clear route on the Guide, or /path clear.
- Item names and details come from C_Item when the old global item functions aren't there (the Retail 12 client WoW Forever runs on), so items stop showing as "Loading item...".
- New route: Cozy Sleeping Bag, for Alliance and Horde (level 14+). It follows the chain of notes from Westfall and the Barrens through Stonetalon Mountains and Loch Modan to the Thoradin's Wall in Hillsbrad, where the last one gives the camping bag. Each step has its spot and the rewards along the way.
- The other faction's routes no longer show in your lists (your current route always does).
- City of Dalaran's quest route is complete. The Forever database files several of its quests outside the dungeon and records no order between them, so Pathfinder now adds them by hand: for Alliance, An Alarming Request first, then Starving Arcane and Heart of Disruption, then Friend of the Kirin Tor; for Horde, Prison Break In, Dalaran Patrols and Blood in the Streets, then Heart of Disruption and Shrewd Negotiations, plus Key to the City. Opportunistic Education, which has no giver in the database, now says to get it from Rexxie Copperclutch just inside the entrance.
- A route for every zone. With the quest database installed, the Routes page lists a Zone quests section: every zone with quests for your character, split into routes of about 18 quests by level ("Westfall 10-17", "Westfall 17-25"...). Each starts with any quest from elsewhere that unlocks one, then rounds of pick up, do and hand in, nearest first, with follow-ups in the round after their quest. Repeatable quests are left out; dungeons keep their own routes, and cities and battlegrounds get none (their quests are hand-ins, class quests and PvP).
- The Routes page is in three sections, each sorted by level: Dungeons on top, then Zones (the built-in, RUIN and your own routes with every zone's quest routes), then Completed / out-leveled for routes whose quests you've all done or whose top level is 3 or more below yours. The Guide's list follows the same order.
- Each section of the Routes page is a tinted band with a gap above it and a count of its routes. Click a band to fold the section away; click again to open it. What you fold stays folded.
- The Guide tab's Choose a route list now has every route on the Routes page, including the zone and dungeon routes; both use the same list.
- Each route on the Routes page has a checkbox: untick it to hide that route from the Choose a route list. A section header's checkbox hides or shows the whole section. Your current route always stays in the list.
- Built-in routes checked against the Forever quest database: Elwynn's two rabbit quests and Zephras Isle's "Welcome!" aren't in the Forever database and are gone; Zephras Isle's steps lost their placeholder map pins (the quest database places them instead); two quest names match the game's capitals.
- Dungeon routes in general: a quest that follows another of the dungeon's quests is picked up after that one is handed in, instead of at the start.

## 0.5.1 — 2026-11-06

- Route page: *Choose a route* opens a list of every route (14 at a time, scroll for more, the current one in view) instead of stepping to the next one per click (needs RUIN Core 0.5.3).
- Dungeon quest routes: a route through every quest a dungeon has for your race and class, with the quests that unlock them. It runs the unlocking quests in order first (Underground Map before Old Ironforge Incursion; the Defias Brotherhood and Westfall chains before the Deadmines), then the pick-ups nearest first, then the run (quests picked up inside, quest items and what to do), then the hand-ins. Delivery quests get no separate "Do" step, and quests that start from an item say what drops it. Built while you play from the quest database (nothing of it is copied into RUIN), so routes match the database you have. The Routes page lists one for each dungeon with quests for you (raids are left to RUIN Codex's button: their reputation turn-ins make very long routes). Which quests belong to which dungeon: each dungeon's zone IDs, plus the quests filed under a city that still belong to the run (from WoW Forever's dungeon lists, foreverchanges.pro).
- For RUIN Codex: `DungeonQuests(name)`, `DungeonRoute(name)`, `OpenDungeonRoute(name)`, `ShowQuestOnMap(questID)`, `QuestInfo(questID)` and `QuestDone(questID)`.

Routes updated from the WoW Forever launch snapshot (2026-11-05, build 1.60.1.70790; ForeverChanges and ForeverDB):
- Elwynn 1-10: the new level-1 quests Wabbit Pelts and Waskily Wabbits! (accept, do and turn in in Northshire), and a note for the new Paladin and Warrior class letters.
- Zephras Isle 1-12: Welcome! is Zephras Isle's own quest (92454, was 5805), and the new Coming of Age quest.
- Teldrassil 1-12: a note for the new night elf quest The Goddess Provides.
- Hall of Thanes: levels 13-18 and the bosses in order, with what to watch for.
- Westfall: Ruins of Lordaeron (15-20, Tirisfal) as an optional detour.
- Wetlands: Excavation Site is levels 24-31, about 7 Alliance quests worth about 39,300 XP; the Relic Guardian's Titan Relic starts a chain.
- Wetlands, Duskwood and Ashenvale: at 28+, City of Dalaran (28-33, Alterac Mountains) and its Alliance attunement from Emissary Jacques in Southshore.
- The Routes page shows how many quests WoW Forever has in a route's zone, and their levels, when you hover the route.

## 0.5.0 — 2026-11-02

RUIN 0.5.0: every addon in the suite moves to 0.5.0 together. No changes to Pathfinder since 0.4.2.

## 0.4.2 — 2026-11-01

1 change since 0.4.1:

1. **Reads the quest database.** When the quest database is installed (contract 4, for example the copy that ships with Ruinous Forever Planner), Pathfinder uses it for quest givers, hand-ins, objective places, quest levels and drafted routes, without needing the quest database itself. the database is still used when the quest database isn't there. The Quests page says which one it reads.

## 0.4.1 — 2026-10-28

Security update (works best with RUIN Core 0.4.5). 1 change since 0.4.0:

1. Only verified officers can publish or withdraw RUIN routes (a player's own RUIN claiming to be an officer no longer counts), route progress and quest lists are their sender's own (nobody can move the route of someone you follow), and times in the future are refused.

## 0.4.0 — 2026-10-23 · Beta 1

The RUIN Gaming Companion App enters beta: every addon is now 0.4.0. Nothing changed since 0.3.14 apart from the version number. Report what you find under Settings → Feedback.

## 0.3.14 — 2026-10-22

1 change since 0.3.13:

1. Gear the recorder writes down is named ("Got Cruel Barb") even when the game hasn't sent the item's name yet.

## 0.3.13 — 2026-10-21

3 changes since 0.3.12 (needs RUIN Core 0.3.14):

1. **Routes checked against the WoW Forever quest database.** Every quest step now carries its quest ID, so steps tick off by ID. Fixes from the database:
   - Elwynn: *Rest and Relaxation* starts with Falkhaan Isenstrider in Northshire and is handed in to Innkeeper Farley; *A Fishy Peril* comes from Remy "Two Times"; the Lost Guards chain now runs through the half-eaten body, *Discover Rolf's Fate* and *Report to Thomas*; the route ends with the *Report to Gryan Stoutmantle* breadcrumb. Added *Young Lovers*.
   - Westfall: rebuilt along the road in from Elwynn (*Westfall Stew* is a delivery from Verna Furlbrow to Salma Saldean, then the second Stew), with *Red Leather Bandanas* and the second *People's Militia*.
   - Dun Morogh: *Senir's Observations* and *Coldridge Valley Mail Delivery* are two quests each; added *Supplies to Tannok* and *Bitter Rivals*.
   - Teldrassil: the second *Iverron's Antidote*, *The Road to Darnassus*, and Tarindrella's spot. Darkshore: *Bashal'Aran* (first part) and *How Big a Threat?* part two.
   - Redridge: Forever redrew the map, so Lakeshire's people sit about 5 points further west; *Encroaching Gnolls* comes from Guard Parker on the way in and leads to *Assessing the Threat* (its accept was missing).
   - Duskwood: *Wolves at Our Heels* is Lars's at Sven's camp, and *Sven's Revenge* ends at the mound of dirt. Loch Modan, Duskwood and Ashenvale givers moved to where they stand; *The Ashenvale Hunt* (Horde only) is gone; Hall of Thanes picks up *An Ancient Grudge* inside.
   - "Do" steps whose spot was wrong lost it; with the quest database installed the arrow finds the targets.
2. **Quest database integration.** With the quest database installed, Pathfinder reads its quest database while you play (nothing of it is copied into RUIN): where a quest starts and ends, the nearest spot of its targets, its level and objectives. Steps without a place get one; step tooltips show the quest database's details; steps for quests you've already done (or already have) tick themselves off (*Skip done quests* on the Guide, `/path skip`; stepping back with < pauses it); and *Draft from the quest database* (Routes, Quests, or `/path draft`) makes a route of your zone's quests for your level.
3. **Quests shared with RUIN.** A new *Quests* sub-tab lists your quest log with the quest database's details and who in RUIN has the same quest, is ready to hand it in, or has done it; *Show on map* and *Invite them* help you team up. Members share which quests they have (and which of their route's quests they've done) when it changes and every 5 minutes; the Guide marks steps others are on ("2 in RUIN") and *RUIN on the road* counts quests in common. *Share with RUIN* on the Quests page (or `/path questshare`) turns it off.

## 0.3.12 — 2026-10-21

2 changes since 0.3.11 (needs RUIN Core 0.3.14):

1. **Officer routes for the whole org.** Officers can *Publish* any route on the Routes page (their own, an imported one or a built-in one), and it appears in every RUIN member's route list. When a member shares a route, officers see *Approve* next to it, which publishes it as officer-approved. RUIN routes carry an officer badge in the route list and the route picker; hovering shows who made or approved them. Officers can *Withdraw* a RUIN route from everyone. Only officers' routes are accepted, and officers re-send them to members who log in later.
2. The page's first sub-tab is *Guide* again (0.3.10 and 0.3.11 were built on the older 0.3.0 code, where it read "Route"). This release keeps 0.3.11's new routes and everything from 0.3.6–0.3.9: the class track, recorder, the quest database waypoints and the page colors.

## 0.3.11 — 2026-10-20

- Added remaining Alliance leveling routes through ~30:
  - Loch Modan 10-18 (after Dun Morogh)
  - Darkshore 11-18 (after Teldrassil; fuller hub + coastal loop)
  - Redridge 15-22 (expanded Lakeshire circuit)
  - Duskwood 20-28 (Darkshire + Raven Hill / Sven / Night Watch)
  - Wetlands 20-30 (Menethil + Greenwarden)
  - Ashenvale 18-28 (Astranaar + Raene / Zoram)
- Routes assume entry from the primary zone connection and prompt accepts as you pass hubs and roadside givers.
- Optimized for sequential outdoor progress with dungeon inserts (Hall of Thanes, later Excavation Site) called out in notes.

## 0.3.10 — 2026-10-20

- Integrated Alliance 1–30 stepped leveling routes built from the WoW Forever quest database (beta 1.60.1) and public Forever guidance.
- New built-in routes: Elwynn 1-10, Westfall 10-15, Dun Morogh 1-12, Teldrassil 1-12, Zephras Isle 1-12, Hall of Thanes 13-18 (dungeon quest package, group recommended).
- Original sample routes (Valley of Trials, Northshire sample) retained.
- Coordinates are best-effort from database pins and Classic baselines; refine in-game with the Recorder and share.

## 0.3.9 — 2026-10-19

1 change since 0.3.8 (needs RUIN Core 0.3.12):

1. **Clearer pages, in Pathfinder's color.** Sub-tabs are now *Guide* (the route you're on), *Routes* (your library) and *Record*, so "Route" and "Routes" are no longer easy to mix up. Recording uses plain step names (Go to, Accept quest, Turn in, Class quest...) instead of short codes, and the boxes show hints.

## 0.3.8 — 2026-10-19

1 change since 0.3.7:

1. Back to the original name (Pathfinder) in the RUIN window and addon list, after 0.3.7's short-lived rename. Its tab now sits in the order Guild, Finder, Muster, Pathfinder, Codex, Exchange, Options.

## 0.3.7 — 2026-10-19

1 change since 0.3.6:

1. **New display name** (Leveling tab, Leveling & Quest Guide page), to match the RUIN Gaming Companion App brief and RUIN Core 0.3.10's new tab order. The addon list shows it as "Leveling (Pathfinder)". The tabs now read in the brief's plain language. Only what players see changed: the addon folder, repository, command and saved-data names stay the same, so nothing needs reinstalling or re-setting.

## 0.3.6 — 2026-10-18

6 changes since 0.3.0 (needs RUIN Core 0.3.7):

1. Steps read as a checklist: a box that ticks, a marker in the suite's colors (quest, turn-in, class quest, trainer, waypoint), the quest and where, and a done count. A map-marker legend sits beside it, and the step's map pin takes its marker color. Built-in routes are labelled as WoW Classic samples.
2. Class track: your class and the next trainer visit, a reminder when you reach a new even level (the Classic rule, marked unverified for WoW Forever), and two new step kinds for route authors: class quest and trainer.
3. Recorder for collecting real routes: a "Recording: ON" badge, /path mark <note> to drop a note where you stand, /path rec for status, and level-ups, gear you receive (with item IDs) and the minutes between steps recorded along the way.
4. "Waypoint set: <quest> (252 yards)" in chat when a step with a place begins, and the tracker shows distance in yards.
5. New RUIN look (the Pathfinder tab, part of the RUIN Gaming Companion App), and Retail's interface number in the TOC.
6. The quest database, used at runtime: the recorder now saves each quest's ID, and with the quest database installed, accept and class quest steps point to the quest giver and turn-in steps to where the quest is handed in, even before the quest is in your log. Nothing is copied from outside into RUIN. Shared routes carry the quest IDs (not your recorded times).

## 0.3.0 — 2026-10-18

- Suite release: every RUIN addon moves to 0.3.0 together, bringing everything from the 0.2.x entries below. No further code changes.
- Needs RUIN Core 0.3.0.
- From now on a RUIN addon's 0.3.x number counts its own changes since this release.

## 0.2.5 — 2026-10-18

5 changes since 0.2.0:

Needs RUIN Core 0.2.6 or later.

1. Waypoint arrow: steps can carry a place, and the tracker shows an arrow and distance plus a map pin. With the quest database installed, hand-in steps without a place use the quest database's location. The sample routes have approximate coordinates.
2. Route recorder: play a route once and Pathfinder writes down each accept, finish and turn-in with its place. Add go-to and note steps, then save.
3. Route sharing: export and import routes as copy-paste strings, or Share a route with everyone in RUIN, who can add it from their Routes page.
4. Follow: follow a leveling partner's route, and your tracker moves when theirs does.
5. The page is split into Route, Routes and Recorder, and the tracker uses the Pathfinder colours and follows couch mode.

## 0.2.0 — 2026-10-18

- Suite milestone: every RUIN addon moves to 0.2.0 together. No code changes since the last 0.1 release.
- With RUIN Core 0.2.0, this module's page opens in the new RUIN window with its own themed header: a walker on a dotted trail.

## 0.1.2 — 2026-10-18

- Fixed: "Binding header RUIN was attempted to be loaded more than once". Each module now has its own section under Key Bindings, and all of its bindings load.
- The tracker's edge glows and a spark runs around its border when the step changes.
- New key binding: Pathfinder: previous step.
- Northshire route: added the Eagan Peltskinner quest from Deputy Willem before Wolves Across the Border.

## 0.1.0 — 2026-10-18

First proof of concept.
