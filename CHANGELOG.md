# RUIN Pathfinder changelog

Versioning: the third number counts the meaningful changes made since the second number last went up.

## Unreleased

(nothing yet)

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
