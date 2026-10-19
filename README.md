# RUIN Pathfinder

Questing routes, one step at a time, with a waypoint arrow, RUIN members on the same step, and routes written and shared by RUIN's own route authors.

Part of the RUIN addon suite. Requires **RUIN Core** (0.3.0 or later). Works with **Questie** when installed (hand-in locations for steps without coordinates).

## The experience
- **Where it lives:** the Pathfinder page in the RUIN window (Route, Routes, Recorder), the on-screen tracker, a pin on the map, `/path`, and key bindings for next and previous step.
- **Following a route:** pick a route and press *Start*. Accept, finish and turn-in steps tick off by themselves; the tracker glows when the step changes.
- **Waypoint arrow:** steps with a place show an arrow and the distance on the tracker, and a pin on the world map and minimap. In another zone the tracker names the zone instead. Toggle with *Arrow + pin* or `/path arrow`.
- **Leveling together:** the tracker counts RUIN members on your step, and the Route page lists everyone on a route. Press *Follow* next to a partner and your tracker moves when theirs does.
- **Recorder:** route authors press *Start recording* and play. Every quest you accept, finish and hand in becomes a step with its place; add go-to and note steps with the box. *Save route* adds it to your routes.
- **Sharing:** *Export* gives a copy-paste string (RUIN-ROUTE1:...), *Import string* reads one, and *Share* sends a route to everyone in RUIN, who find it on their Routes page to add.
- **Commands:** `/path next`, `/path prev`, `/path tracker`, `/path arrow`, `/path record`, `/path save`, `/path import`, `/path unfollow`.

## What it shares with RUIN
The route you're on and your step number (when it changes and every 2 minutes), and routes you choose to share.

## Notes
The two built-in sample routes (Valley of Trials, Northshire) use WoW Classic quest names and approximate Classic coordinates; WoW Forever may differ. Recorded routes use the places you actually stood.
