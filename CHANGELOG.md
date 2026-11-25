# RUIN Pathfinder changelog

Versioning: the third number counts the meaningful changes made since the second number last went up.

## Unreleased

- **New levelling routes, Alliance 1-60.** Every Alliance levelling route is now planned from the quest database for the most experience an hour solo: each starts in the best zone for its levels, does the quests worth doing there at your level, and moves zone to zone as the game expects (taking the boat only when it pays). There's a level-1 route for each starting area (Northshire Valley, Coldridge Valley, Shadowglen, Zephras Isle), then routes of about five or six levels up to 60, with up to two alternatives per bracket. The last step offers 1-3 routes to start next.
- **No repeated or dead-end quests in levelling routes.** A route no longer sends you back for a quest you already turned in earlier on the way, no longer ends with quests picked up that it never hands in (the 6-13/6-14 routes left five Zephras Isle quests in your log), and its last step shows the level you actually end at.
- **Start next picks up where you are.** The first route a levelling route offers next carries on from that route's own end, so it sends you back for at most a few quests you already handed in, and choices that would repeat more are left out.
- **Route names start with their levels.** Every route shows its level range first ("13-18 Hall of Thanes", "1-10 Elwynn Forest", "13-18 Deadmines quests"; a single level shows once, "60 ...") in the route list, the picker, the tracker and Start next, and every section of the list, Suggested for you included, is sorted by level. Saved route titles aren't changed.
- **The low levels stay at home.** Each starting area has one route to about level 6 and one that stays in your race's own zone (Elwynn Forest, Dun Morogh, Teldrassil or Zephras Isle) until its quests run out, around 10-11, with no grinding. Its last step tells you where to move on to and starts your next route from there, so the levelling keeps flowing. Each starting route offers only its home route next, and Suggested for you never offers another race's zone.
- **Follow-on routes only where they belong.** A route planned to carry on from one particular route is suggested only after you've played that route.
- **Renamed routes start over cleanly.** If an update renames the route you're on, you move to the new one at its first step, and Skip done quests catches you up (before, you could land past its end).
- **Renamed routes keep your place.** If an update renames the route you're on (57-60 Winterspring became 57-60 Azshara), Pathfinder moves you to the new one at the same step instead of leaving the tracker empty.
- **Suggested for you.** The Routes page opens with the best planned routes for your level (at level 1, your race's starting area), then all planned routes under Levelling.
- **Session time.** Pick how long you'll play on the Guide page (30 minutes to 4 hours): it shows the step to stop at and the level you'll be about then, the tracker shows the stop step, and you're told once when you reach it. Without a session it shows the time left on the route.
- **Class quests.** The Guide's Class track card names the next class quest for your class and level, and who gives it. Planned routes remind you to visit your trainer at even levels.
- **Group.** When your step's quest is Elite or Group, a *Group* button lists you on RUIN Finder's board for it.
- **Follow my party leader.** In a party on the same route as your leader, your step moves with theirs (on by default; the checkbox is by RUIN on the road). Leaving the party stops it.

- **Route names show in full**: on Routes, a row's text now runs up to the buttons it actually shows, so dungeon routes keep their level range and section headers such as *Completed / out-leveled* aren't cut short.

## 0.8.10

- Version matched to the rest of the RUIN suite; no changes.

## 0.8.9

- **The waypoint's distance sits right under its card.** Top to bottom: the card, the distance and walking time, then the marker, the stem and the dot (the distance used to hang under the dot).
- **The waypoint arrows follow your style's accent.** The arrow on the waypoint at the screen's edge and the one on the quest tracker were the game's gold, which a tint can't change; they're greyed first now, so they take the accent of the style you picked (the tracker's still turns green when you're there).
- **The N keeps turning in dungeons.** Inside dungeons and raids the game keeps your facing from addons, and won't let them read how far its own compass ring has turned either, so on a rotating minimap the N stopped at the top. The game still turns that ring, so there Pathfinder puts its badge on it, with an arrowhead pointing north (it reads right however the ring is turned; a letter would be on its side), and the game turns it. Everywhere else the N is Pathfinder's own, upright, placed by your facing. With rotation off, the ring is given back as it was. `/path minimap north` shows what the N has to go on. It only ever sets the ring (reading it is what the game refuses in dungeons, which flooded errors), and if the game refuses anything else it leaves the ring alone for the session and the N sits on top.
- **Quest marks clear themselves.** A Mark on Map or View Location mark goes once you've done with it: a pick-up mark when you take the quest, any mark for a quest when you hand it in. Right-click a mark (Mark on Map's, or the route's next step) to clear it yourself; a cleared step mark comes back for the next step. `/ruin clearmap` clears them all.
- **Routes keep to their levels.** Every route (zone, dungeon and hand-written) now leaves out any quest that needs you more than 3 levels above the level most of its quests are at (the level 80% of them are at or below), along with anything on the route that waits on it. Today that takes The Mad King (level 40) out of the Gnomeregan route, whose quests are mostly 27-34; every other route already kept to its levels.
- **No endgame set quests in zone routes.** The dungeon set upgrade chain (Mux Manascrambler in Gadgetzan, Deliana, Mokvar, Anthion Harmon and Bodley) needs level 58 and the full dungeon set, but its few level-60 quests had joined Tanaris's top route. They're left out of zone routes now.
- **"You walked past" only for quests you can take.** A route's pick-up reminder now waits until you're the quest's level and have done its earlier quests, so it never sends you back for one the giver won't offer yet.

## 0.8.5

- **Quieter quest reminders.** A reminder's sound now plays at most once every 30 seconds, so several reminders at once (or a run of them along a road) chime once; the reminders themselves still all show. The sound is now the short minimap ping instead of the longer Artifact Forge chime.

## 0.8.4

- **Quest data from November 19.** Rebuilt from QuestieDB 1.1.3's WoW Forever database: 749 new quests (149 in Riverglades, 36 on Mount Hyjal, 34 in Azshara, and more across the world) and 535 updated ones, with their givers, hand-ins, targets and items. Zone routes now cover Riverglades (five routes, levels 22-58), Mount Hyjal and the new Azshara quests. Quests still marked "not yet in game" in the files are left out.
- **Dungeon routes for the newer dungeons.** The Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold and Shaper's Terrace now have their quests, so each gets a dungeon route (Krol'dok's begins with the Riverglades quests that lead there). A quest with no known giver outside, like Krol'dok's escort, is picked up inside.
- **Zone quest counts** on the Routes page are November's (Zephras Isle 128, Elwynn 85, Riverglades 100, Stranglethorn 122, the Horde starting zones and more), and the 20-30 routes end with where to go past 30: Stranglethorn and The Drowned City, then Riverglades and Krol'dok.
- **Newer quest levels and givers.** QuestieDB's development version (its November 18 data, not yet released) fills in the minimum level of 171 quests that had none, mostly level 40-60 quests such as the Blackmaw Hold prelude, so they no longer show at low levels. It also corrects 24 other minimum levels and 6 quest levels (the Thandol Span quests need 26, Fall of Dun Modr is level 30) and adds missing givers and hand-ins to about 30 quests, among them River Ends and Blackmaw Reclamation. The Horde's Krol'dok Moulding now starts from the mould Tunk drops in Krol'dok Stronghold, so it's picked up during the run.
- **Hall of Thanes:** Afadra Dunwall's place comes from the quest database, which has moved her.
- **Leaner zone routes.** They now leave out quests a hand-written route already covers, dungeon quests (the dungeon's route has them), profession quests, the Crafting area's 145 Craftsman's Writs (eight routes of them), quests with no known giver, extra versions of a quest you can only take once (like the 13 versions of Your First Horse), quests that need a long chain from other zones first (the Ahn'Qiraj war effort, Narain's chain), and quests you can only pick up at 60 (raid attunements, raid set turn-ins). A route made only of level-60 quests is endgame, not levelling, so the 60-60 routes are gone. Each route stays within about six levels, so none runs from 30 to 60 any more, and a few stray quests far above a zone's level are left out. A handful of leftover quests joins the route before them, and quests that scale to your level count at the level you can pick them up. For an Alliance human that's 103 zone routes instead of 125, about 500 fewer quests across them, and the longest route went from 109 steps to 78.
- **Tidier hand-written routes.** Northshire 1-5 is gone (Elwynn 1-10 covers it step for step). Loch Modan no longer picks up In Defense of the King's Lands twice, or Mercenaries, Thelsamar Blood Sausages and Stormpike's Order without doing them, and now hands in Crocolisk Hunting. Dun Morogh hands in Tools for Steelgrill. Teldrassil no longer picks up a Crown of the Earth step it never does. Darkshore does Bashal'Aran in order and hands in Washed Ashore. Duskwood drops the Stalvan and Look To The Stars chains it only started and hands in Jitters' Growling Gut. Ashenvale finds Teronis on the way to the Zoram Strand instead of a vague "work the chain" step.
- **A shopping list on your route.** When a route's quests need items a vendor sells, a step says what to buy and from whom (the arrow points to the vendor); when they take items the Auction House has (ones RUIN Exchange has seen listed there, or that anyone can trade), another says buying them will speed things up. Where the route visits the vendor's city, or a city with an Auction House, the step comes just before the route leaves it; otherwise the two are its first steps. Worked out when you start the route and kept with it, so steps don't move as you go; your group still stays in step with you.
- **Dungeon quest routes pick everything up first.** Every quest given outside the dungeon is picked up before a new Travel step, and the quests given inside are the last thing before the run. Quests started by an item you find in the dungeon come during the run.
- **Notifications stay 15 seconds by default.** Standard is now 15 seconds and Longer is 25 (Customization > Tracker > Notifications).
- **Starting a route picks it in the Guide tab**, from the Routes page or anywhere else you start one.
- **Minimap addon buttons on the square frame.** With a modern minimap, Customization > Minimap addon buttons can put addons' minimap buttons on the square frame around the map instead of around the round map.

## 0.8.3

- **Choose how long notifications stay** (Customization > Tracker > Notifications): Chat only, Short (8 seconds), Longer (15), Standard (25) or Until I close it. Every notification still goes to chat.
- **The alerts window wears the tracker's look** (Customization > Tracker > Look) and its background opacity, and follows it when you change it.
- **Background opacity steps evenly**, from 100% down to 20% (lower settings are gone; they only looked broken). Each step is a clear change from the next: a little closer together near solid and a little wider lower down, where the eye sees less difference. This affects the minimap, the objective tracker, the world map and the tracker.
- **The RUIN look keeps RUIN's softer gold** with the app in the Blizzard window style (it turned the game's bright yellow), like Ink and Exchange. The tracker's tabs and buttons keep the look's colors too.

## 0.8.2 — 2026-11-16

- **Fewer frame stutters**: the quest reminders read your quest log once (it was read again for every quest in the zone), rebuild the zone's quest list every two minutes or when your log or level changes (it was every 30 seconds), and don't look again for five minutes for a place the database doesn't have.

## 0.8.1 — 2026-11-15

- Fixed: **a quest's details were unreadable in the modern looks** (its text, objectives and rewards stayed in the game's dark parchment ink on the dark panel). Dark text is lightened now, headings in the look's color; item names and other colored text keep their colors.

## 0.8.0 — 2026-11-15

- **The square minimap is gone.** A rotating map leaves a square's corners empty, and the fixes didn't hold up on WoW Forever, so the minimap is round again. A tracker docked to a corner spot moves to that side.
- **Pathfinder's minimap style gets a cap and a foot.** A flat square frame in the suite's HUD look (the tracker's panel, edges and accent band) sits around the ring, with the information tucked into its corners: the cap above holds the tracking button, the addon list, the zone name with your coordinates beside it, and the calendar; the foot below holds the mail icon and the clock. The map sits a little low in the frame to give the top its room, and the frame sits close around it, a little inside the Edit Mode box. The tracking, calendar and mail icons are redrawn flat (they still work as before), and nothing sits on the map. Coordinates another addon prints by the map give way to the foot's. Back in the game's own look, everything goes back where it was.
- **The objective tracker gets the same choice: the game's look or Pathfinder's** (Customization > Objective Tracker, or `/path objectives blizzard | pathfinder`). Pathfinder's puts a panel in the suite's look behind it, sized to hold everything it shows (quest markers and item buttons included), and colors its text like the suite: headers in Pathfinder's green with a short rule beneath, quest titles in bright white with a firm shadow, objectives in a quieter grey with a green dash so the names lead, finished ones in green. The game still lays it out and handles its buttons.
- **Pathfinder's own icons in the modern style.** On the objective tracker, quest markers become flat rings in Pathfinder's green (a gold ? to hand in, dots while under way, filled green when it's the quest you're following), collapse buttons a plain - and +, item buttons a thin rounded frame, finished objectives a green check, and the small buttons beside quests a green arrow. On the minimap, the tracking and mail icons are redrawn to match. The game's buttons still take the clicks.
- **The world map and quest log get the same choice: the game's look or Pathfinder's** (Customization > World Map & Quest Log, or `/path worldmap blizzard | pathfinder`). Pathfinder's swaps the gold frame, portrait and parchment for a panel in the suite's look, with the title, the breadcrumb bar and the quest log's zone headers in Pathfinder's green, objectives in the suite's grey, and the quest markers, collapse buttons, close and maximize buttons drawn flat. Quest titles keep the game's difficulty colors. A Background setting sets its opacity.
- **Eight looks for the minimap, the objective tracker and the world map**: Blizzard (the game's own), RUIN (the core app's navy and gold), Ink (gold on a near-black, as the RUIN Waypoint wears it), Pathfinder, Finder, Muster, Codex and Exchange (the modern style in that module's color). Also `/path minimap <look>`, `/path objectives <look>`, `/path worldmap <look>`.
- **The RUIN Waypoint has a Style too** (Customization > Waypoint): any of the looks, and a Background setting for how see-through the whole waypoint is (marker, card, stem and distance).
- **The tracker and the RUIN Waypoint can wear the game's own look too** (Style: Blizzard): a warm near-black edged in WoW Forever's bronze (the background tucked inside the rounded edge), with the game's gold for the title and marks. All Styles' Blizzard now sets them as well.
- **So does Pathfinder's tracker** (Customization > Tracker): a Style (any of the looks) and a Background opacity, with the same slight gradient as the others.
- **A roomier Customization tab (the Options tab, renamed)** that scrolls: Tracker, Waypoint, Game Frames and Controls, each with space to breathe. Each section's look sits on its own row (Style and Background), and the minimap, objective tracker and world map share one Game Frames section under All styles.
- **One opacity for everything**: beside All styles, a Background setting for the minimap, objective tracker, world map, tracker and the whole waypoint at once (Mixed when they differ).
- Fixed: choosing a minimap style could report an error from a game frame addons can't touch.
- **All Styles** (Customization): one setting that sets the minimap, objective tracker, world map, tracker and waypoint to the same look. It reads Mixed when they differ; Blizzard puts the game's frames back and leaves the tracker and waypoint as they are.
- **Docking the tracker to the minimap is gone**: the tracker always moves freely (the Dock setting and `/path dock` are removed).
- The Options tab's Objective Tracker and World Map settings sit side by side with the Minimap's, a style and background each on one row.
- **A slight green-to-black gradient behind the minimap frame and the objective tracker, with a Background opacity setting for each.**
- **A clearer N on the modern minimap**: a dark badge edged in Pathfinder's green with a bold white N, so it holds up on any ground as the map turns.
- **A day / night icon in the minimap's cap**, beside the calendar: a gold sun by day, a pale moon by night (server time), with the time on hover. WoW Forever's own sun or moon on the ring gives way to it (another addon's that takes clicks moves into it).
- **Tooltips are compact and sit beside what you point at**: long lines break onto several short ones, and the tooltip opens to the side of the button with more room.
- **The modern minimap fills its Edit Mode box.** The map grows so its square frame is as big as the box's shorter side, centered in it; move or resize the box in Edit Mode and the map follows. Back in the game's own look, the map returns to its own size and place.
- **The N turns with a rotating minimap** (Pathfinder's style): it sits on the ring where north is, instead of staying on top.
- `/path minimap blizzard | pathfinder | debug`.
- **The tracker and waypoint start in the game's own look** (Blizzard), like the minimap, objective tracker and world map.
- **Mark on Map and View Location** on the Quests page: *Show on Map* is now *Mark on Map* (puts the pin down), and *View Location* tracks the quest and opens your world map on where it is.
- **Game Frames is at the top of Customization**, above Tracker and Waypoint.
- **Quest log zone headers stand out** in every look: a band of the look's color fading across each, an edge down its left and a line under it, and larger text that keeps its color when you hover it. Blizzard's look gets them in WoW Forever's gold and bronze.
- **Travel time follows your speed**: the waypoint's time is worked out at the speed you're going (on foot, mounted, swimming, flying, or with a speed boost), by road on the ground with a straight cut across for the last stretch, and along the flight path in the air. (The Waypoint Editor's *Walking time* is now *Travel time*.)
- **The waypoint rises over faraway spots**: a faraway spot sits low on the ground, so the whole waypoint eases up toward the horizon, from 100 yards to a twentieth of the screen at 800 yards and beyond.
- Fixed: **constant Lua errors in combat** from the waypoint's travel time. Retail 12 hides your speed (and can hide the distance) in combat; the waypoint now keeps the last ones it was told instead.
- **Lighter**: the waypoint reads its settings and what's tracked four times a second instead of every frame, and reuses one table instead of making new ones each frame; the minimap housing updates ten times a second (the N turns 30 times a second, only on a rotating minimap) and does nothing at all in the game's own look; the objective tracker's restyle backstop runs once a second (the game's own update still restyles at once); the zone and coordinates aren't redrawn while you stand still.
- **No errors from hidden values**: the tracker's arrow and distance, the minimap's coordinates and N, and loot recording skip what Retail 12 hides in combat.

## 0.7.5 — 2026-11-13

- **Fixed: Pathfinder's square minimap had a dark see-through layer over the map.** Its shadow was one dark square under the edge, drawn above the map. It's now four soft bands outside the edge, fading outward.

## 0.7.4 — 2026-11-13

- **Fixed: the round minimap went see-through after trying the square one.** Going back to round put on a round mask WoW Forever's client doesn't have. Pathfinder now ships its own round mask and uses that.

## 0.7.3 — 2026-11-13

- **Fixed: the square minimap stayed round, with the game's round border.** When the game (or WoW Forever's own UI) puts its round mask back, Pathfinder now puts the square one straight back over it, and it reapplies the minimap's look whenever you change zones. The game's round border is found by what it draws (not only by name) and kept hidden while the map is square or in Pathfinder's style. Quest and dig-site areas no longer draw a round ring on a square map.
- `/path minimap debug` lists what's drawn around the minimap, to find any border RUIN missed.

## 0.7.2 — 2026-11-13

- **Fixed: the minimap went see-through** with the minimap options on: RUIN gave the round map a mask from the classic client, which WoW Forever's client doesn't have. RUIN now leaves the game's own round mask alone and only changes it for the square map (and back to WoW Forever's round one after that).

## 0.7.1 — 2026-11-12

- **Mark on map** in Pathfinder's alert window now closes the window and opens the world map on the quest's giver, with a pin there.
- The alert window and the step tracker match the new look: the alert window has Pathfinder's compass and name over a hairline, more room around each alert with a line between them, and a close x that turns red under the mouse; the tracker's title, tabs and < > buttons use Pathfinder's green instead of gold, and its x is the same close button.
- The arrow at the screen edge sits right on the edge of whatever you show (the marker, the card and the distance, as picked in the Waypoint Editor), on the side it points to, instead of a fixed distance from the marker's middle (with the marker off it used to land in the gap between the card and the distance). With the marker off, the card lines up with the distance's edge. The edge pin pulls in far enough to keep the arrow on screen.
- **Minimap options** (Options > Minimap; /path minimap round | square | blizzard | pathfinder):
  - **Shape:** round, as the game draws it, or square. Other addons are told the minimap is square, so their minimap buttons line up with it.
  - **Style:** the game's own look (Blizzard / WoW Forever), or Pathfinder's modern one: a slim ring (or square edge) in Pathfinder's green with a soft shadow, an N at the top, the zone name in a pill above the map (in its PvP color), and mouse-wheel zoom in place of the + and - buttons. On a square map the game's look gets a classic tooltip-style frame.
  - **Dock the tracker** to the minimap (/path dock <spot>). A round map offers above, below and each side; a square one also offers each end of every edge. Above, the tracker grows up as it fills; below, it grows down; on a side, it grows away from the map. Dragging the tracker off the map undocks it.

## 0.7.0 — 2026-11-12

- **A new look, with the rest of the suite.** Pathfinder's pages take its green through and through: the open tab's underline, check marks, the bar on a row under the mouse and the edge a button gets when you point at it. Its header carries a drawing of the route over contour lines with a traveler walking it, and Pathfinder has its own icon (a compass) on its tab, its header and in the AddOns list. The Waypoint Editor wears the same green, the choice you picked is filled rather than only gold text, and a finished step shows a green check.
- **Pathfinder's alerts in a little window** (pick-up reminders, trainer visits, shared and new RUIN routes): the last three, newest on top, with **Mark on map** for a quest's giver. Drag it where you like; it remembers. It closes itself after 25 seconds unless the mouse is on it, and x closes it at once. Each alert goes to chat once (they were printed twice), and the same alert again while it's up is only refreshed.
- Options > Waypoint > **In-Game Navigation** (was "Turn on In-Game Navigation") works both ways now: off turns the game's In-Game Navigation off, so nothing is drawn in the world (the RUIN Waypoint included), and on turns it back on. Before, unticking it only stopped Pathfinder from turning it on, so the waypoint stayed. In combat the change waits until combat ends.
- The Waypoint Editor holds everything about the waypoint now, in three columns: what it shows and how it looks, then Position (the nudges), Hiding (hide when the game says you're there, and the hide distance) and Screen edge (the four boundaries). In Options, the Waypoint card opens with **Show the RUIN Waypoint** (renamed from Show the RUIN pin), larger than the rest, with the Waypoint Editor button beside it; the RUIN pin and Screen edge cards are gone.
- The on-screen preview in the Waypoint Editor moves with the Position nudges. Options is respaced so nothing crowds: the Tracker rows have room again and "Turn on In-Game Navigation" no longer runs into the column beside it.
- With the marker off, the card at the screen edge takes the marker's place, just above the distance and time, stopping short of the arrow.
- Guide tidied so nothing overlaps: Clear route sits over the steps list instead of on the Class track card, the steps list leaves room for its scroll bar beside the right column, and Quests in your log reads "Quests in your log (35)" so it fits the route picker. A step for several quests that share targets is named for the first and how many more ("Save Techbot's Brain! + 2 more"); its tooltip lists them all.
- **RUIN Quest Data is part of Pathfinder now** (the `QuestData` folder, GPLv3; see its NOTICE.md), so there's no separate addon to install or enable. If the old RUIN_QuestData folder is still in your AddOns, Pathfinder says once that you can delete it.
- **Quests in your log as a route.** The Guide's route list starts with "Quests in your log": the best order to finish every quest you have from where you stand, with what's left to do for each and its hand-in (ready quests go straight to the hand-in, no pick-ups). It's planned when you pick or start it and keeps its order while you follow it; start it again to plan it afresh. Quests the quest database doesn't know come last.
- Pathfinder's tabs are in a new order: Quests, Guide, Routes, Record, Options. Pathfinder opens on the Guide while you're on a route, otherwise on Quests.
- **The card at the screen edge.** While the pin waits at the edge, its card shows too (with the parts ticked in the Waypoint Editor), beside the marker on the side toward the middle of the screen. Waypoint Editor > Card at the edge too turns it off.
- **Screen edge boundaries** (Waypoint Editor > Screen edge): how close the spot may come to the top, bottom, left and right of the screen, each on its own (0-45% of the screen), before the pin moves to the edge. The edge pin waits on that line. They start at 10% on every side; 0% keeps the old behaviour (only when the spot is off screen).
- **Pick-up reminders.** Walk near the giver of a quest your route picks up next and leave without taking it, and Pathfinder reminds you who gives it and where (route step and coordinates). Walk into the area where a quest's targets are while you don't have the quest (your route's, or one of this zone's for your level whose earlier quests you've done), and it tells you where to pick it up. Each quest once a session; not in instances. Options > Tracker has a switch for each, /path remind turns both on or off.
- **Security:** quest-place sightings from others count once per player and place, so one player sending a sighting again and again can't move a quest giver. With quest log or quest place sharing off (RUIN Core), Pathfinder doesn't send them.
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
