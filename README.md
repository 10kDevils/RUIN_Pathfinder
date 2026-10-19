# RUIN Pathfinder

Questing routes, one step at a time, with a waypoint arrow, RUIN members on the same step, and routes written and shared by RUIN's own route authors.

Part of the **RUIN Gaming Companion App**. Requires **RUIN Core** (0.3.7 or later). Works with **Questie** when installed: steps without coordinates point to the quest giver or the hand-in, read from Questie at runtime (nothing of Questie's is copied into RUIN). The recorder saves quest IDs so this works for shared routes too.

## The experience
- **Where it lives:** the Pathfinder tab in the RUIN window (Route, Routes, Recorder), the on-screen tracker, a pin on the map, `/path`, and key bindings for next and previous step.
- **Checklist:** the route's steps tick off as you go, each with a marker in RUIN's colors (yellow quest, blue turn-in, purple class quest and trainer, blue waypoint) and where it happens; a legend sits beside the list. When a step with a place begins, chat says "Waypoint set: <quest> (252 yards)".
- **Class track:** your class and the next trainer visit, with a reminder at each new even level (`/path trainer` turns it off). That rule is Classic's and is marked unverified for WoW Forever until RUIN confirms it.
- **Following a route:** pick a route and press *Start*. Accept, finish and turn-in steps tick off by themselves; the tracker glows when the step changes.
- **Waypoint arrow:** steps with a place show an arrow and the distance on the tracker, and a pin on the world map and minimap. In another zone the tracker names the zone instead. Toggle with *Arrow + pin* or `/path arrow`.
- **Leveling together:** the tracker counts RUIN members on your step, and the Route page lists everyone on a route. Press *Follow* next to a partner and your tracker moves when theirs does.
- **Recorder:** route authors press *Start recording* and play. Every quest you accept, finish and hand in becomes a step with its place, and level-ups, gear you receive (with its item ID) and the minutes between steps are written down too. A "Recording: ON" badge shows while it runs. Add go-to, note, class quest and trainer steps with the box, or type `/path mark <note>` where you stand; `/path rec` shows the status. *Save route* adds it to your routes. This is how RUIN turns beta play into real WoW Forever routes and gear times.
- **Sharing:** *Export* gives a copy-paste string (RUIN-ROUTE1:...), *Import string* reads one, and *Share* sends a route to everyone in RUIN, who find it on their Routes page to add.
- **Commands:** `/path next`, `/path prev`, `/path tracker`, `/path arrow`, `/path record`, `/path rec`, `/path mark <note>`, `/path trainer`, `/path save`, `/path import`, `/path unfollow`.

## What it shares with RUIN
The route you're on and your step number (when it changes and every 2 minutes), and routes you choose to share.

## Notes
The two built-in sample routes (Valley of Trials, Northshire) use WoW Classic quest names and approximate Classic coordinates, and are labelled as samples; WoW Forever may differ. Recorded times stay on your account; shared and exported routes carry the steps only. Recorded routes use the places you actually stood.
