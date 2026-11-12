-- The rows that are different for the Horde (see LICENSE and NOTICE),
-- put in by Pathfinder once it knows your faction.
local D = RUIN_QuestData
D.faction = D.faction or {}
D.faction.Horde = function(q, n, o, i)
q[113]={"Insect Part Analysis",{{5594}},{{7724}},39,48,0,0,{"Deliver the report to Senior Surveyor Fizzledowser in Gadgetzan. Be sure he gives you a copy of the report, as Alchemist Pestlezugg has requested."},nil,{},8594,nil,{110},nil,nil,nil,440,nil,nil,nil,nil,32,0,0,0,{{369,10}},0,nil,nil,0,0,0,0,0,nil,0}
q[687]={"Theldurin the Lost",{{2787}},{{2785}},30,40,0,0,{"Find Theldurin the Lost."},nil,{},0,nil,{653,688},nil,nil,nil,45,nil,nil,nil,nil,692,8,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[709]={"Solution to Doom",{{2785}},{{2785}},30,40,0,0,{"Bring the Tablet of Ryun'eh to Theldurin the Lost."},nil,{[3]={{4631,[3]=0}}},0,nil,nil,nil,nil,nil,1517,nil,nil,nil,nil,728,8,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[737]={"Forbidden Knowledge",{{2934}},{{2785}},30,40,0,0,{"Bring Yagyin's Digest to Theldurin."},nil,{},4647,nil,{735,736},nil,nil,nil,3,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[1198]={"In Search of Thaelrid",{{4786}},{{4787}},18,24,0,0,{"Seek out Argent Guard Thaelrid in Blackfathom Deeps."},nil,{},0,nil,nil,nil,nil,nil,719,nil,nil,nil,nil,0,8,0,0,{{529,150},{69,150}},0,nil,nil,0,0,0,0,0,nil,0}
q[1393]={"Galen's Escape",{{5391}},{[2]={32569}},30,38,0,0,{"Escort Galen out of danger, then find his camp in the Swamp of Sorrows and open his strongbox."},{"Escort Galen out of the Fallow Sanctuary.",{[8]={{53.08,29.55}}}},{},0,nil,nil,nil,nil,nil,8,nil,nil,nil,nil,0,2,2,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[1718]={"The Islander",{{3041,3354,4595}},{{6236}},30,30,0,1,{"Speak with Klannoc Macleod."},nil,{},0,nil,nil,nil,nil,nil,-81,nil,nil,nil,nil,1719,8,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[1947]={"Journey to the Marsh",{{3048,4568,5885}},{{6546}},30,38,0,128,{"Speak with Tabetha."},nil,{},0,nil,nil,nil,nil,nil,-161,nil,nil,nil,nil,0,8,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[1953]={"Return to the Marsh",{{3048,4568,5885}},{{6546}},35,40,0,128,{"Speak with Tabetha."},nil,{},0,nil,nil,nil,nil,nil,-161,nil,nil,nil,nil,1954,8,0,0,nil,1954,nil,nil,0,0,0,0,0,nil,0}
q[2861]={"Tabetha's Task",{{4568,5885}},{{6546}},40,46,0,0,{"Speak with Tabetha in Dustwallow Marsh."},nil,{},0,nil,nil,nil,nil,nil,978,nil,nil,nil,nil,2846,8,0,0,nil,2846,nil,nil,0,0,0,0,0,nil,0}
q[2954]={"The Stone Watcher",{{7918},{142343}},{[2]={142343}},45,50,0,0,{"Learn the purpose of the Stone Watcher of Norgannon, and then interact with the Uldum Pedestal in the Tanaris desert."},nil,{{{7918,[3]=5}}},0,nil,{2946,2966},nil,nil,nil,440,nil,nil,nil,nil,2967,2,2,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[3741]={"Hilary's Necklace",{{8965}},{{8962}},12,15,0,0,{"Find Hilary's Necklace, and return it to Hilary in Lakeshire."},nil,{[3]={{10958,[3]=0}}},0,nil,nil,nil,nil,nil,44,nil,nil,nil,nil,0,8,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[4507]={"Pawn Captures Queen",{{5594}},{{5594}},50,54,0,0,{"Defeat the Gorishi Hive Queen once she is summoned.","","Bring the Gorishi Queen's Brain to Alchemist Pestlezugg in Gadgetzan."},nil,{[3]={{11835,[3]=0}}},11833,nil,{4496},nil,nil,nil,440,nil,nil,nil,nil,4509,0,0,0,nil,0,nil,{{nil,4,"Use the Gorishi Queen Lure.",0,{{"object",174792}}}},0,0,0,0,0,nil,0}
q[4985]={"The Wildlife Suffers Too",{{10739}},{{10739}},51,56,0,0,{"Destroy 8 Diseased Grizzlies, and then return to Mulgris Deepriver at the Writhing Haunt, Western Plaguelands."},nil,{{{1816,[3]=0}}},0,nil,{4984},nil,nil,nil,28,nil,nil,nil,nil,4987,8,0,0,{{609,75}},0,nil,nil,0,0,0,0,0,nil,0}
q[5021]={"Better Late Than Never",{{10778}},{[2]={175894}},50,52,0,0,{"The ramblings of the ghostly woman indicated that she needed a package delivered. She claimed that it was where her horse was. As to where the horse is or where the package was to be delivered - the ghost remains incomprehensible."},nil,{},0,nil,nil,nil,nil,nil,28,nil,nil,nil,nil,5023,8,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[5050]={"Good Luck Charm",{{8403}},{{10778}},50,52,0,0,{"Return to Janice Felstone in Western Plaguelands her Good Luck Half-Charm."},nil,{},12721,nil,{5048,5049},nil,nil,nil,28,nil,nil,nil,nil,5051,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[6804]={"Poisoned Water",{{13278}},{{13278}},55,56,0,0,{"Use the Aspect of Neptulon on poisoned elementals of Eastern Plaguelands. Bring 12 Discordant Bracers and the Aspect of Neptulon to Duke Hydraxis in Azshara."},nil,{[3]={{17309,[3]=0}}},17310,nil,nil,nil,{6805},nil,16,nil,nil,nil,nil,0,0,0,0,{{67,100}},0,nil,nil,0,0,0,0,0,nil,0}
q[6981]={"The Glowing Shard",{[3]={10441}},{{8418}},15,26,0,0,{"Travel to Ratchet to find someone that can tell you more about the glowing shard.","","Then, deliver the shard as you are directed."},nil,{{{3442,[3]=5}}},10441,nil,nil,nil,nil,nil,718,nil,nil,nil,nil,3369,2,2,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[7562]={"Mor'zul Bloodbringer",{{5753,5815}},{{14436}},60,58,0,256,{"Speak with Mor'zul Bloodbringer in the Burning Steppes."},nil,{},0,nil,nil,nil,nil,nil,-61,nil,nil,nil,nil,7563,0,0,0,nil,7563,nil,nil,0,0,0,0,0,nil,0}
q[8151]={"The Hunter's Charm",{{3039,3352}},{{8405}},50,52,0,4,{"Speak to Ogtinc in Azshara."},nil,{},0,nil,nil,nil,nil,nil,-261,nil,nil,nil,nil,8153,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[8233]={"A Simple Request",{{3328,4583}},{{6768}},50,52,0,8,{"Speak with Lord Jorach Ravenholdt in Ravenholdt Manor."},nil,{},0,nil,nil,nil,nil,nil,-162,nil,nil,nil,nil,8234,0,0,0,{{349,10}},8234,nil,nil,0,0,0,0,0,nil,0}
q[8250]={"Magecraft",{{3047,4567,7311}},{{8395}},50,52,0,128,{"Seek out Sanath Lim-yo and gain passage to see Archmage Xylem."},nil,{},0,nil,nil,nil,nil,nil,-161,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[8254]={"Cenarion Aid",{{3045,6018}},{{8405}},50,52,0,16,{"Seek out Ogtinc in Azshara."},nil,{},0,nil,nil,nil,nil,nil,-262,nil,nil,nil,nil,8255,8,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[8417]={"A Troubled Spirit",{{3041,3354,4593}},{{7572}},50,50,0,1,{"Speak with the Fallen Hero of the Horde at the entrance to the Blasted Lands."},nil,{},0,nil,nil,nil,nil,nil,-81,nil,nil,nil,nil,8423,0,0,0,nil,8423,nil,nil,0,0,0,0,0,nil,0}
q[8419]={"An Imp's Request",{{3326,4563}},{{14470}},50,52,0,256,{"Bring a piece of felcloth to Impsy in Felwood."},nil,{[3]={{14256,[3]=0}}},0,nil,nil,nil,nil,{8420},-61,nil,nil,nil,nil,8421,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[8619]={"Morndeep the Elder",{{15549}},{{15549}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8635]={"Splitrock the Elder",{{15556}},{{15556}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8636]={"Rumblerock the Elder",{{15557}},{{15557}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8642]={"Silvervein the Elder",{{15558}},{{15558}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8643]={"Highpeak the Elder",{{15559}},{{15559}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8644]={"Stonefort the Elder",{{15560}},{{15560}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8645]={"Obsidian the Elder",{{15561}},{{15561}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8646]={"Hammershout the Elder",{{15562}},{{15562}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8647]={"Bellowrage the Elder",{{15563}},{{15563}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8648]={"Darkcore the Elder",{{15564}},{{15564}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8649]={"Stormbrow the Elder",{{15565}},{{15565}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8650]={"Snowcrown the Elder",{{15566}},{{15566}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8651]={"Ironband the Elder",{{15567}},{{15567}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8652]={"Graveborn the Elder",{{15568}},{{15568}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8653]={"Goldwell the Elder",{{15569}},{{15569}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8654]={"Primestone the Elder",{{15570}},{{15570}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8670]={"Runetotem the Elder",{{15572}},{{15572}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8671]={"Ragetotem the Elder",{{15573}},{{15573}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8672]={"Stonespire the Elder",{{15574}},{{15574}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8673]={"Bloodhoof the Elder",{{15575}},{{15575}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8674]={"Winterhoof the Elder",{{15576}},{{15576}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8675]={"Skychaser the Elder",{{15577}},{{15577}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8676]={"Wildmane the Elder",{{15578}},{{15578}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8677]={"Darkhorn the Elder",{{15579}},{{15579}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8678]={"Proudhorn the Elder",{{15580}},{{15580}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8679]={"Grimtotem the Elder",{{15581}},{{15581}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8680]={"Windtotem the Elder",{{15582}},{{15582}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8681]={"Thunderhorn the Elder",{{15583}},{{15583}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8682]={"Skyseer the Elder",{{15584}},{{15584}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8683]={"Dawnstrider the Elder",{{15585}},{{15585}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8684]={"Dreamseer the Elder",{{15586}},{{15586}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8685]={"Mistwalker the Elder",{{15587}},{{15587}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8686]={"High Mountain the Elder",{{15588}},{{15588}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8688]={"Windrun the Elder",{{15592}},{{15592}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8713]={"Starsong the Elder",{{15593}},{{15593}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8714]={"Moonstrike the Elder",{{15594}},{{15594}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8715]={"Bladeleaf the Elder",{{15595}},{{15595}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8716]={"Starglade the Elder",{{15596}},{{15596}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8717]={"Moonwarden the Elder",{{15597}},{{15597}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8718]={"Bladeswift the Elder",{{15598}},{{15598}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8719]={"Bladesing the Elder",{{15599}},{{15599}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8720]={"Skygleam the Elder",{{15600}},{{15600}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8721]={"Starweave the Elder",{{15601}},{{15601}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8722]={"Meadowrun the Elder",{{15602}},{{15602}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8723]={"Nightwind the Elder",{{15603}},{{15603}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8724]={"Morningdew the Elder",{{15604}},{{15604}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8725]={"Riversong the Elder",{{15605}},{{15605}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8726]={"Brightspear the Elder",{{15606}},{{15606}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8727]={"Farwhisper the Elder",{{15607}},{{15607}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8866]={"Bronzebeard the Elder",{{15871}},{{15871}},1,60,0,0,nil,nil,{},0,nil,nil,nil,nil,nil,-366,nil,nil,nil,nil,0,8,0,0,{{67,50}},0,nil,nil,0,0,0,0,0,nil,0}
q[8928]={"A Shifty Merchant",{{16014}},{{16014}},58,60,0,0,{"Search for an imp inside a cave at the entrance of Darkwhisper Gorge in southern Winterspring, purchase a Fel Elemental Rod and return to Mux Manascrambler in Gadgetzan."},nil,{[3]={{21939,[3]=0}}},0,nil,{8925},nil,nil,nil,440,nil,nil,nil,nil,8978,8,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[8996]={"Return to Bodley",{{16073}},{{16033}},58,60,0,0,{"Return to Bodley inside Blackrock Mountain and give him the Brazier of Beckoning."},nil,{[3]={{22056,[3]=0}}},0,nil,{8995},nil,nil,nil,25,nil,nil,nil,nil,8998,8,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[9063]={"Torwa Pathfinder",{{3033,12042}},{{9619}},50,52,0,1024,{"Speak with Torwa Pathfinder in Un'Goro Crater."},nil,{},0,nil,nil,nil,nil,nil,-263,nil,nil,nil,nil,9052,0,0,0,nil,9052,nil,nil,0,0,0,0,0,nil,0}
q[9388]={"Flickering Flames in Kalimdor",{{16818}},{{16788}},1,25,0,0,{"Visit the bonfires within Ashenvale, the Barrens, Darkshore, and Stonetalon Mountains, then speak with the Festival Flamekeeper."},nil,{[2]={{181561,[3]=0},{181560,[3]=0},{181563,[3]=0},{181562,[3]=0}}},0,nil,nil,nil,nil,nil,-369,nil,nil,nil,nil,0,8,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[9389]={"Flickering Flames in the Eastern Kingdoms",{{16818}},{{16788}},1,25,0,0,{"Visit the bonfires within Hillsbrad Foothills, Silverpine Forest, Westfall, and the Wetlands, then speak with the Festival Flamekeeper."},nil,{[2]={{181566,[3]=0},{181564,[3]=0},{181565,[3]=0},{181567,[3]=0}}},0,nil,nil,nil,nil,nil,-369,nil,nil,nil,nil,0,8,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[78124]={"Nar'thalas Almanac",{{211022},{409496}},{{211022}},1,20,0,0,{"Collect 'Nar'thalas Almanac, Vol. 74' and bring it to Owen Thadd in Undercity."},nil,{[3]={{209843,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[78127]={"The Dalaran Digest",{{211022},{409501}},{{211022}},1,20,0,0,{"Collect 'The Dalaran Digest, Vol. 23' and bring it to Owen Thadd in Undercity."},nil,{[3]={{209844,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[78142]={"Bewitchments and Glamours",{{211022},{409562}},{{211022}},1,20,0,0,{"Collect 'Bewitchments and Glamours' and bring it to Owen Thadd in Undercity."},nil,{[3]={{209845,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[78143]={"Secrets of the Dreamers",{{211022},{409692}},{{211022}},1,20,0,0,{"Collect 'Secrets of the Dreamers' located just outside the Wailing Cavern dungeon and bring it to Owen Thadd in Undercity."},nil,{[3]={{209846,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[78145]={"Arcanic Systems Manual",{{211022},{409700}},{{211022}},1,20,0,0,{"Collect 'Arcanic Systems Manual' and bring it to Owen Thadd in Undercity."},nil,{[3]={{209847,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[78146]={"Goaz Scrolls",{{211022},{409717}},{{211022}},1,20,0,0,{"Collect 'Goaz Scrolls' and bring it to Owen Thadd in Undercity."},nil,{[3]={{209848,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[78147]={"Crimes Against Anatomy",{{211022},{409735}},{{211022}},1,20,0,0,{"Collect 'Crimes Against Anatomy' and bring it to Owen Thadd in Undercity."},nil,{[3]={{209849,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[78148]={"Runes of the Sorcerer-Kings",{{211022},{409731}},{{211022}},1,20,0,0,{"Collect 'Runes of the Sorcerer-Kings' and bring it to Owen Thadd in Undercity."},nil,{[3]={{209850,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[78149]={"Fury of the Land",{{211022},{409711}},{{211022}},1,20,0,0,{"Collect 'Fury of the Land' and bring it to Owen Thadd in Undercity."},nil,{[3]={{209851,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[78150]={"Friend of the Library",{{211022}},{{211022}},1,20,0,0,{"You will need to hand in 10 books to complete this quest, however you can hand 1 in at any time."},nil,{},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79091]={"Archmage Antonidas: The Unabridged Autobiography",{{211022},{386691}},{{211022}},1,20,0,0,{"Collect 'Archmage Antonidas: The Unabridged Autobiography' and bring it to Owen Thadd in Undercity."},nil,{[3]={{203754,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79092]={"Archmage Theocritus' Research Journal",{{211022},{386759}},{{211022}},1,20,0,0,{"Collect 'Archmage Theocritus' Research Journal' and bring it to Owen Thadd in Undercity."},nil,{[3]={{203755,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79093]={"Rumi of Gnomeregan: The Collected Works",{{211022},{408014}},{{211022}},1,20,0,0,{"Collect 'Rumi of Gnomeregan: The Collected Works' and bring it to Owen Thadd in Undercity."},nil,{[3]={{208860,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79094]={"The Lessons of Ta'zo",{{211022},{405149}},{{211022}},1,20,0,0,{"Collect 'The Lessons of Ta'zo' and bring it to Owen Thadd in Undercity."},nil,{[3]={{207972,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79095]={"The Apothecary's Metaphysical Primer",{{211022},{405879}},{{211022}},1,20,0,0,{"Collect 'The Apothecary's Metaphysical Primer' and bring it to Owen Thadd in Undercity."},nil,{[3]={{208185,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79096]={"Ataeric: On Arcane Curiosities",{{211022},{410299}},{{211022}},1,20,0,0,{"Collect 'Ataeric: On Arcane Curiosities' and bring it to Owen Thadd in Undercity."},nil,{[3]={{210177,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79097]={"Baxtan: On Destructive Magics",{{211022},{407566}},{{211022}},1,20,0,0,{"Collect 'Baxtan: On Destructive Magics' and bring it to Owen Thadd in Undercity."},nil,{[3]={{208800,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79535]={"Basilisks: Should Petrification be Feared?",{{211022},{421526}},{{211022}},1,35,0,0,{"Collect 'Basilisks: Should Petrification be Feared?' and bring it to Owen Thadd in Undercity."},nil,{[3]={{213165,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79536]={"Greater Friend of the Library",{{211022}},{{211022}},20,35,0,0,{"You will need to hand in 20 books to complete this quest, however you can hand 1 in at any time."},nil,{},0,nil,{78150},nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79947]={"Geomancy: The Stone-Cold Truth",{{211022},{423895}},{{211022}},1,35,0,0,{"Collect 'Geomancy: The Stone-Cold Truth' and bring it to Owen Thadd in Undercity."},nil,{[3]={{215683,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79948]={"Defensive Magics 101",{{211022},{423896}},{{211022}},1,35,0,0,{"Collect 'Defensive Magics 101' and bring it to Owen Thadd in Undercity."},nil,{[3]={{215815,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79949]={"A Web of Lies: Debunking Myths and Legends",{{211022},{423897}},{{211022}},1,35,0,0,{"Collect 'A Web of Lies: Debunking Myths and Legends' and bring it to Owen Thadd in Undercity."},nil,{[3]={{215816,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79950]={"Demons and You",{{211022},{423898}},{{211022}},1,35,0,0,{"Collect 'Demons and You' and bring it to Owen Thadd in Undercity."},nil,{[3]={{215817,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79951]={"Mummies: A Guide to the Unsavory Undead",{{211022},{423899}},{{211022}},1,35,0,0,{"Collect 'Mummies: A Guide to the Unsavory Undead' and bring it to Owen Thadd in Undercity."},nil,{[3]={{215820,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79952]={"RwlRwlRwlRwl!",{{211022},{423900}},{{211022}},1,35,0,0,{"Collect 'RwlRwlRwlRwl!' and bring it to Owen Thadd in Undercity."},nil,{[3]={{215822,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[79953]={"A Ludite's Guide to Caring for Your Demonic Pet",{{211022},{423901}},{{211022}},1,35,0,0,{"Collect 'A Ludite's Guide to Caring for Your Demonic Pet' and bring it to Owen Thadd in Undercity."},nil,{[3]={{215824,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[81947]={"Sanguine Sorcery",{{211022},{441247}},{{211022}},1,45,0,0,{"Collect 'Sanguine Sorcery' and bring it to Owen Thadd in Undercity."},nil,{[3]={{220345,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[81949]={"Legends of the Tidesages",{{211022},{441248}},{{211022}},1,45,0,0,{"Collect 'Legends of the Tidesages' and bring it to Owen Thadd in Undercity."},nil,{[3]={{220346,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[81951]={"The Liminal and the Arcane",{{211022},{441249}},{{211022}},1,45,0,0,{"Collect 'The Liminal and the Arcane' and bring it to Owen Thadd in Undercity."},nil,{[3]={{220347,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[81952]={"Everyday Etiquette",{{211022},{441250}},{{211022}},1,45,0,0,{"Collect 'Everyday Etiquette' and bring it to Owen Thadd in Undercity."},nil,{[3]={{220348,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[81953]={"Stonewrought Design",{{211022},{441251}},{{211022}},1,45,0,0,{"Collect 'Stonewrought Design' and bring it to Owen Thadd in Undercity."},nil,{[3]={{220349,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[81954]={"Venomous Journeys",{{211022},{441252}},{{211022}},1,45,0,0,{"Collect 'Venomous Journeys' and bring it to Owen Thadd in Undercity."},nil,{[3]={{220350,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[81955]={"A Mind of Metal",{{211022},{441253}},{{211022}},1,45,0,0,{"Collect 'A Mind of Metal' and bring it to Owen Thadd in Undercity."},nil,{[3]={{220352,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[81956]={"Conjurer's Codex",{{211022},{441254}},{{211022}},1,45,0,0,{"Collect 'Conjurer's Codex' and bring it to Owen Thadd in Undercity."},nil,{[3]={{220353,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[82208]={"Greater Friend of the Library",{{211022}},{{211022}},30,45,0,0,{"You will need to hand in 25 books to complete this quest, however you can hand 1 in at any time."},nil,{},0,nil,{79536},nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[84395]={"Undead Potatoes",{{7825},{463213}},{{7825}},1,60,0,0,{"Collect 'Undead Potatoes' and bring it to Oran Snakewrithe in Undercity."},nil,{[3]={{228132,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[84396]={"Magma or Lava?",{{7825},{463206}},{{7825}},1,60,0,0,{"Collect 'Magma or Lava?' and bring it to Oran Snakewrithe in Undercity."},nil,{[3]={{228133,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[84397]={"Northern Kalimdor - A Comprehensive Guide",{{7825},{463209}},{{7825}},1,60,0,0,{"Collect 'Northern Kalimdor - A Comprehensive Guide' and bring it to Oran Snakewrithe in Undercity."},nil,{[3]={{228134,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[84398]={"A Study of the Light",{{7825},{463207}},{{7825}},1,60,0,0,{"Collect 'A Study of the Light' and bring it to Oran Snakewrithe in Undercity."},nil,{[3]={{228135,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[84399]={"Ka-Boom!",{{7825},{463214}},{{7825}},1,60,0,0,{"Collect 'Ka-Boom!' and bring it to Oran Snakewrithe in Undercity."},nil,{[3]={{228136,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[84400]={"The Knight and the Lady",{{7825},{463208}},{{7825}},1,60,0,0,{"Collect 'The Knight and the Lady' and bring it to Oran Snakewrithe in Undercity."},nil,{[3]={{228138,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[84401]={"Scourge: Undead Menace or Misunderstood?",{{7825},{463212}},{{7825}},1,60,0,0,{"Collect 'Scourge: Undead Menace or Misunderstood?' and bring it to Oran Snakewrithe in Undercity."},nil,{[3]={{228140,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[84402]={"Necromancy 101",{{7825},{463211}},{{7825}},1,60,0,0,{"Collect 'Necromancy 101' and bring it to Oran Snakewrithe in Undercity."},nil,{[3]={{228141,[3]=0}}},0,nil,nil,nil,nil,nil,1497,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
q[97286]={"Research Access",{{211022}},{{211022}},1,20,0,128,nil,nil,{},0,nil,{78124,78127,78142,78143,78145,78146,78147,78148,78149,79091,79092,79093,79094,79095,79096,79097,79535,79947,79948,79949,79950,79951,79952,79953,81947,81949,81951,81952,81953,81954,81955,81956,84395,84396,84397,84398,84399,84400,84401,84402},nil,nil,nil,-161,nil,nil,nil,nil,0,0,0,0,nil,0,nil,nil,0,0,0,0,0,nil,0}
n[2397]={"Derak Nightfall",32,32,{[267]={{63.1,19.4}}},267,nil,nil,"H","Cook"}
n[3045]={"Malakai Cross",50,50,{[1638]={{24.6,22.6}}},1638,{8254},nil,"H","Priest Trainer"}
n[3047]={"Archmage Shymm",60,60,{[1638]={{22.8,14.5}}},1638,{8250},nil,"H","Mage Trainer"}
n[3048]={"Ursyn Ghull",40,40,{[1638]={{25.7,14.2}}},1638,{1947,1953},nil,"H","Mage Trainer"}
n[3327]={"Gest",40,40,{[1637]={{42.7,51.5}}},1637,nil,nil,"H","Rogue Trainer"}
n[3328]={"Ormok",50,50,{[1637]={{43.9,54.6}}},1637,{8233},nil,"H","Rogue Trainer"}
n[4567]={"Pierce Shackleton",50,50,{[1497]={{85.5,13.5}}},1497,{8250},nil,"H","Mage Trainer"}
n[4582]={"Carolyn Ward",40,40,{[1497]={{83.9,72.1}}},1497,nil,nil,"H","Rogue Trainer"}
n[4583]={"Miles Dexter",50,50,{[1497]={{85.2,71.6}}},1497,{8233},nil,"H","Rogue Trainer"}
n[4584]={"Gregory Charles",60,60,{[1497]={{84.9,73.5}}},1497,nil,nil,"H","Rogue Trainer"}
n[4593]={"Christoph Walker",60,60,{[1497]={{46.9,15.2}}},1497,{8417},nil,"H","Warrior Trainer"}
n[5676]={"Summoned Voidwalker",10,10,{[1497]={{86.6,27.1}},[1637]={{49.4,50}}},1637,nil,nil,"AH"}
n[5677]={"Summoned Succubus",20,20,{[1497]={{86.6,27.1}},[1637]={{49.4,50}}},1637}
n[5753]={"Martha Strain",20,20,{[1497]={{85.7,16.1}}},1497,nil,nil,"H","Demon Trainer"}
n[5815]={"Kurgul",45,45,{[1637]={{47.5,46.7}}},1637,{7562},nil,"H","Demon Trainer"}
n[8307]={"Tarban Hearthgrain",22,22,{[17]={{55.2,32.1}}},17,nil,nil,"H","Baker"}
n[12138]={"Lunaclaw",12,12,{[17]={{42,60.8}}},17}
n[12144]={"Lunaclaw Spirit",13,13,{[17]={{42,60.8}}},17,nil,nil,"AH"}
n[13778]={"PvP Tower Credit Marker",1,1,{[2597]={{52.8,44},{50.8,30.8},{45.2,14.6},{44,18.1}}},2597,nil,nil,"AH"}
n[15898]={"Lunar Festival Vendor",55,55,{[1497]={{66.5,36}},[1637]={{41.3,32.4}},[1638]={{70.6,27.8}},[493]={{36.6,58.1},{36.3,58.5}}},493,nil,nil,"AH"}
n[16788]={"Festival Flamekeeper",60,60,{[1497]={{65.6,36}},[1637]={{42.6,34.2}},[1638]={{21.6,26.2}}},1637,{9319,9322,9323,9386},{9319,9322,9323,9386,9388,9389},"AH"}
n[185335]={"Summoned Incubus",20,20,{[1497]={{86.6,27.1}},[1637]={{49.4,50}}},1637}
n[211022]={"Owen Thadd",40,40,{[1497]={{73.4,33}}},1497,{79095,78150,79536,82208,78124,78127,78142,78143,78145,78146,78147,78148,78149,79091,79092,79093,79094,79096,79097,79535,79947,79948,79949,79950,79951,79952,79953,81947,81949,81951,81952,81953,81954,81955,81956,97286},{78148,79092,79095,79536,82208,97286,78124,78127,78142,78143,78145,78146,78147,78149,78150,79091,79093,79094,79096,79097,79535,79947,79948,79949,79950,79951,79952,81947,81949,81952,81953,81955,81956,79953,81951,81954},"H","Librarian"}
o[103574]={"Filled Containment Coffer",{[1497]={{53.3,74.6},{53.7,76.8},{52,76},{53.2,71.4}}},1497}
o[105174]={"Chest of Containment Coffers",{[1497]={{85.7,9.9},{85.5,10},{85.5,9.9},{85.6,10}}},1519}
o[105175]={"Cantation of Manifestation",{[1497]={{85.8,10.1},{85.7,10.1},{85.7,10.2}}},1497}
o[177794]={"Strange Lockbox",{[17]={{56.7,8.3}}},17}
o[177844]={"Strange Lockbox",{[130]={{29.6,29.2}}},130}
o[180743]={"Carefully Wrapped Present",{[1637]={{52.4,69.5}}},1537,{8744},{8744}}
o[180746]={"Gently Shaken Gift",{[1637]={{52.3,69.4}}},1537,{8767,8788},{8767,8788}}
o[180747]={"Gaily Wrapped Present",{[1637]={{52.3,69.2}}},1537,{8768},{8768}}
o[180748]={"Ticking Present",{[1637]={{52.3,69.3}}},1637,{8769},{8769}}
o[180793]={"Festive Gift",{[1637]={{52.4,69.3}}},1537,{8803},{8803}}
i[3713]={"Soothing Spices",{2397,8307},nil,nil,0,{960,989,1148,1286,1456,2225,2381,2393,2397,2664,2810,2821,3027,3085,3367,3400,3779,3954,3955,4223,4229,4265,4553,4561,4775,4877,4897,5100,5135,5160,5163,5483,5817,6301,7947,8145,8307,8363,8934,9636,11189,12022,12028,12033,12245,12941,12957,12958,14738,15179,242498,248198,251905,252020,252083,254695,256731,259962,260559,267000,270780,272646}}
i[15882]={"Half Pendant of Aquatic Endurance",nil,{177844},nil,0}
i[15883]={"Half Pendant of Aquatic Agility",nil,{177794},nil,0}
i[17126]={"Elegant Letter",{3327,3328,3401,4582,4583,4584},nil,nil,6681}
i[20810]={"Signed Field Duty Papers",{15612},nil,nil,0}
end
