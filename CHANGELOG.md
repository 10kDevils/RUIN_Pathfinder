# RUIN Pathfinder changelog

Versioning: the third number counts the meaningful changes made since the second number last went up.

## Unreleased

(nothing yet)

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
   - "Do" steps whose spot was wrong lost it; with Questie installed the arrow finds the targets.
2. **Questie integration.** With Questie installed, Pathfinder reads its quest database while you play (nothing of Questie's is copied): where a quest starts and ends, the nearest spot of its targets, its level and objectives. Steps without a place get one; step tooltips show Questie's details; steps for quests you've already done (or already have) tick themselves off (*Skip done quests* on the Guide, `/path skip`; stepping back with < pauses it); and *Draft from Questie* (Routes, Quests, or `/path draft`) makes a route of your zone's quests for your level.
3. **Quests shared with RUIN.** A new *Quests* sub-tab lists your quest log with Questie's details and who in RUIN has the same quest, is ready to hand it in, or has done it; *Show on map* and *Invite them* help you team up. Members share which quests they have (and which of their route's quests they've done) when it changes and every 5 minutes; the Guide marks steps others are on ("2 in RUIN") and *RUIN on the road* counts quests in common. *Share with RUIN* on the Quests page (or `/path questshare`) turns it off.

## 0.3.12 — 2026-10-21

2 changes since 0.3.11 (needs RUIN Core 0.3.14):

1. **Officer routes for the whole org.** Officers can *Publish* any route on the Routes page (their own, an imported one or a built-in one), and it appears in every RUIN member's route list. When a member shares a route, officers see *Approve* next to it, which publishes it as officer-approved. RUIN routes carry an officer badge in the route list and the route picker; hovering shows who made or approved them. Officers can *Withdraw* a RUIN route from everyone. Only officers' routes are accepted, and officers re-send them to members who log in later.
2. The page's first sub-tab is *Guide* again (0.3.10 and 0.3.11 were built on the older 0.3.0 code, where it read "Route"). This release keeps 0.3.11's new routes and everything from 0.3.6–0.3.9: the class track, recorder, Questie waypoints and the page colors.

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
6. Questie, used at runtime: the recorder now saves each quest's ID, and with Questie installed, accept and class quest steps point to the quest giver and turn-in steps to where the quest is handed in, even before the quest is in your log. Nothing from Questie is copied into RUIN. Shared routes carry the quest IDs (not your recorded times).

## 0.3.0 — 2026-10-18

- Suite release: every RUIN addon moves to 0.3.0 together, bringing everything from the 0.2.x entries below. No further code changes.
- Needs RUIN Core 0.3.0.
- From now on a RUIN addon's 0.3.x number counts its own changes since this release.

## 0.2.5 — 2026-10-18

5 changes since 0.2.0:

Needs RUIN Core 0.2.6 or later.

1. Waypoint arrow: steps can carry a place, and the tracker shows an arrow and distance plus a map pin. With Questie installed, hand-in steps without a place use Questie's location. The sample routes have approximate coordinates.
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
