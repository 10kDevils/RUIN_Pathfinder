# RUIN Quest Data

The quests, NPCs, objects and items in this folder of RUIN Pathfinder
(QuestData/Data.lua, QuestData/Horde.lua and QuestData/Fixes.lua)
are extracted from **QuestieDB 1.1.3** (November 19, 2026), the Forever build
(https://github.com/Questie/QuestieDB), with corrections from QuestieDB's
development version (commit 4f628e8, November 18, 2026), and are distributed under the
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
- Fixes.lua takes quest levels, minimum levels and quest givers from
  QuestieDB's newer Forever data where it differs from 1.1.3, after
  QuestieDB's own player-trace and hand-written corrections.

The extraction tools are in the RUIN suite's repository under
tools/questdb (wowenv.lua, extract.lua, assemble.py).
