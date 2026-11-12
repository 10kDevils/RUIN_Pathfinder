# RUIN Quest Data

The quests, NPCs, objects and items in this folder of RUIN Pathfinder
(QuestData/Data.lua and QuestData/Horde.lua)
are extracted from **QuestieDB 1.0.13**, the Forever build
(https://github.com/Questie/QuestieDB), and are distributed under the
**GNU General Public License v3** (see LICENSE.md), as QuestieDB permits for
copies and forks.

Credit for the data belongs to QuestieDB's and Questie's contributors.
Contributors who have placed their work under the GPLv3 include Muehe,
Logon, TheCrux/BreakBB, Drejjmit, Cheeq, TechoHunter and Yttrium, along with
the Questie team and over 100 historic Questie contributors.

QuestieDB's own license notes that not every historic contributor has given
consent, and asks that the Questie name and logo not be used by forks. RUIN
Pathfinder is not Questie or QuestieDB, is not made or endorsed by the Questie
team, and uses neither the name as its own nor the logo.

## What was changed

- Only quests and the NPCs, objects and items those quests use are kept
  (givers, hand-ins, objective targets and the sources of quest items).
- Spawn coordinates are rounded to one decimal place.
- Rows are stored as plain Lua tables; the Horde's differing rows are kept
  separately in Horde.lua.
- Class-specific corrections are not applied.

The extraction tools are in the RUIN suite's repository under
tools/questdb (wowenv.lua, extract.lua, assemble.py).
