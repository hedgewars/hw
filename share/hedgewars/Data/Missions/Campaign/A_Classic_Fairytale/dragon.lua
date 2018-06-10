--[[
A Classic Fairytale: Dragon's Lair

= SUMMARY =
Hero must collect an utility crate on the other side of the river.
To accomplish that, hero must first collect a series of crates with
the rope and wipe out the cyborgs.
The hero is one survivor of the previous missions.

= GOALS =
- Mission goal (leads to immediate victory): Collect utility crate at the right side of the river
- First sub-goal: Collect (or destroy) a series of crates (all other utility crates)
- Second sub-goal: Wipe out the cyborgs

= FLOW CHART =
- Choose hog to be hero (read from m5DeployedNum)
- Cut scene: Intro
- TBS
| Player accomplishes first sub-goal first:
    - Cut scene: Cyborg reveals second goal
    - A ton of weapon crates and some rope crates spawn on the long platform
| Player accomplshed second sub-goal first:
    - Hero reminds player to collect/destroy remaining crates
- Player accomplished both goals
- Cut scene: Cyborg teleports hero to the long platform and congrats hero
- Hero's ammo is cleared, all crates, mines, sticky mines and barrels are removed from platform
- Spawn a portal gun crate on the long platform and also a teleportation crate further to the right
- (These utilities can be used to finish the mission)
- Player takes final crate at the very right
> Victory

]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

-----------------------------Map--------------------------------------
local map = 
{
	"\0\91\4\253\131\0\88\0\46\0\0\91\0\49\131\15\196\0\53\0\15\196\0\53\131\15\196\4\250\0\255\242\7\179\131\1\128\7\214\0",
	"\1\113\7\207\131\3\182\7\157\0\3\175\7\143\131\6\58\7\200\0\6\76\7\193\131\6\188\7\129\0\6\188\7\129\131\6\248\6\216\0",
	"\6\248\6\216\131\7\52\8\14\0\10\206\8\0\131\11\203\6\65\0\11\203\6\65\131\12\18\7\66\0\12\18\7\69\131\16\0\7\69\0",
	"\0\109\1\1\131\2\111\0\49\0\2\111\0\49\131\3\133\1\18\0\3\140\1\18\131\4\162\0\165\0\4\162\0\165\131\5\135\1\29\0",
	"\5\145\1\22\131\8\84\0\232\0\8\84\0\232\131\9\26\0\70\0\9\26\0\70\131\10\5\1\4\0\10\48\0\243\131\10\2\1\8\0",
	"\10\58\0\243\131\10\118\1\15\0\10\118\1\15\131\10\234\1\173\0\11\10\1\177\131\12\11\1\22\0\12\39\1\40\131\12\243\2\9\0",
	"\12\243\2\9\131\13\106\0\165\0\13\131\0\176\131\15\186\1\78\0\1\244\0\81\136\0\120\0\84\0\1\99\0\123\137\0\130\0\215\0",
	"\0\158\0\130\143\0\158\0\130\0\2\216\0\88\138\4\165\0\102\0\4\91\0\127\142\3\129\0\197\0\3\69\0\134\142\3\69\0\134\0",
	"\4\215\0\120\143\8\88\0\134\0\8\187\0\84\139\8\187\0\84\0\8\239\0\70\135\8\239\0\70\0\8\60\0\187\138\5\99\0\222\0",
	"\5\61\0\197\138\5\61\0\197\0\9\99\0\81\137\10\23\0\218\0\9\187\0\77\137\11\31\1\117\0\10\30\0\88\137\15\161\0\109\0",
	"\15\126\0\225\144\13\177\0\116\0\15\150\0\144\139\15\157\1\26\0\10\202\0\169\152\12\246\0\169\0\10\72\0\144\145\11\122\1\36\0",
	"\11\17\1\121\141\11\17\1\121\0\12\229\1\194\138\12\229\1\194\0\12\208\1\85\150\12\208\1\85\0\12\148\1\15\147\12\148\1\15\0",
	"\13\145\0\208\147\13\145\0\208\0\6\238\7\45\135\7\10\7\238\0\6\220\7\150\135\6\206\7\242\0\6\174\7\175\135\6\135\8\7\0",
	"\6\118\7\214\135\6\62\7\238\0\6\30\7\245\140\3\217\7\210\0\3\161\7\221\138\255\252\7\231\0\15\242\7\165\148\11\115\7\175\0",
	"\11\196\6\164\138\11\10\8\4\0\11\210\7\31\141\11\210\7\31\0\14\216\2\72\166\14\216\2\72\0\14\213\4\4\166\14\213\4\4\0",
	"\13\216\1\159\148\13\216\1\159\0\13\159\2\143\148\13\159\2\143\0\13\230\3\69\145\13\230\3\69\0\13\163\4\11\145\13\166\4\11\0",
	"\13\237\4\208\145\13\237\4\208\0\14\195\5\61\145\14\195\5\61\0\13\78\1\254\136\13\78\1\254\0\12\239\2\93\136\12\239\2\93\0",
	"\12\250\2\227\136\12\250\2\227\0\13\71\3\59\136\13\71\3\59\0\13\1\3\168\136\13\1\3\168\0\12\243\4\32\136\12\246\4\32\0",
	"\13\40\4\130\136\13\43\4\134\0\13\92\4\243\136\13\92\4\243\0\13\142\5\135\136\13\142\5\135\0\14\33\5\106\136\14\33\5\106\0",
	"\14\111\5\208\136\14\121\5\216\0\15\13\5\237\136\15\13\5\237\0\15\73\5\128\136\15\73\5\128\0\15\84\4\243\136\15\84\4\243\0",
	"\14\199\6\33\133\14\199\6\33\0\14\97\6\44\133\14\83\6\44\0\14\9\5\240\133\14\9\5\240\0\13\226\5\163\133\13\226\5\163\0",
	"\13\170\5\233\133\13\170\5\233\0\13\71\5\205\133\13\71\5\205\0\13\61\5\117\133\13\61\5\117\0\13\22\5\40\133\13\22\5\40\0",
	"\12\253\4\211\133\12\253\4\211\0\12\197\4\169\133\12\197\4\169\0\12\204\4\106\133\12\204\4\106\0\12\162\4\46\133\12\162\4\42\0",
	"\12\194\3\200\133\12\194\3\196\0\12\201\3\84\133\12\201\3\84\0\12\253\3\62\133\12\253\3\62\0\12\169\2\241\133\12\169\2\241\0",
	"\12\187\2\167\133\12\187\2\167\0\12\158\2\93\133\12\158\2\93\0\12\162\2\9\133\12\162\2\9\0\12\123\1\205\132\12\123\1\205\0",
	"\12\84\1\251\132\12\84\1\251\0\12\91\2\55\132\12\95\2\55\0\12\63\2\139\132\12\63\2\139\0\12\120\2\164\132\12\120\2\164\0",
	"\12\81\2\206\132\12\81\2\206\0\12\106\3\17\132\12\109\3\20\0\12\137\3\73\132\12\137\3\73\0\12\84\3\122\132\12\84\3\122\0",
	"\12\137\3\150\132\12\137\3\150\0\12\95\3\217\132\12\95\3\217\0\12\134\3\231\132\12\134\3\231\0\12\106\4\63\132\12\106\4\63\0",
	"\12\137\4\120\132\12\141\4\120\0\12\88\4\179\132\12\88\4\183\0\12\134\4\190\132\12\134\4\190\0\12\158\4\232\132\12\165\4\232\0",
	"\12\215\5\15\132\12\215\5\15\0\12\91\4\243\130\12\91\4\243\0\12\144\5\26\130\12\144\5\26\0\12\176\5\54\130\12\176\5\54\0",
	"\12\225\5\82\130\12\225\5\82\0\13\4\5\117\130\13\1\5\117\0\12\239\5\166\130\12\239\5\166\0\13\8\5\184\130\13\11\5\184\0",
	"\13\8\5\226\130\13\8\5\226\0\13\54\6\12\130\13\57\6\12\0\13\106\6\2\130\13\106\5\254\0\13\138\6\12\130\13\138\6\12\0",
	"\13\184\6\30\130\13\187\6\30\0\13\223\5\254\130\13\223\5\254\0\13\149\6\69\130\13\145\6\69\0\13\128\6\33\130\13\128\6\33\0",
	"\13\85\6\40\130\13\85\6\40\0\12\232\6\2\130\12\232\6\2\0\12\204\5\205\130\12\204\5\201\0\12\183\5\159\130\12\183\5\156\0",
	"\12\211\5\128\130\12\211\5\128\0\12\165\5\103\130\12\165\5\103\0\12\123\5\64\130\12\120\5\64\0\12\81\5\71\130\12\81\5\71\0",
	"\12\84\5\18\130\12\84\5\18\0\12\39\4\243\130\12\39\4\243\0\12\35\4\194\130\12\35\4\194\0\12\63\4\127\130\12\63\4\127\0",
	"\12\91\4\106\130\12\91\4\106\0\12\53\4\60\130\12\53\4\60\0\12\74\4\25\130\12\84\4\21\0\12\120\4\4\130\12\120\4\4\0",
	"\12\42\3\231\130\12\42\3\231\0\12\39\3\189\130\12\42\3\186\0\12\60\3\175\130\12\60\3\175\0\12\39\3\133\130\12\39\3\133\0",
	"\12\70\3\73\130\12\70\3\73\0\12\25\3\77\130\12\25\3\77\0\12\42\3\13\130\12\46\3\13\0\12\81\3\31\130\12\81\3\31\0",
	"\12\32\2\213\130\12\32\2\213\0\12\14\2\178\130\12\14\2\178\0\12\42\2\181\130\12\46\2\181\0\12\14\2\128\130\12\14\2\128\0",
	"\12\39\2\100\130\12\42\2\100\0\12\74\2\104\130\12\77\2\104\0\12\106\2\135\130\12\109\2\135\0\12\39\2\72\130\12\39\2\69\0",
	"\12\35\2\37\130\12\35\2\37\0\12\32\2\2\130\12\32\2\2\0\12\28\1\226\130\12\28\1\223\0\12\63\1\208\130\12\63\1\208\0",
	"\12\84\1\173\130\12\84\1\170\0\12\63\1\159\130\12\60\1\159\0\12\39\1\113\130\12\39\1\113\0\12\14\1\96\130\12\11\1\96\0",
	"\11\228\1\131\130\11\228\1\135\0\12\7\1\149\130\12\7\1\149\0\12\21\1\177\130\12\25\1\177\0\11\242\1\201\130\11\242\1\201\0",
	"\13\226\6\58\130\13\226\6\58\0\14\16\6\40\130\14\16\6\40\0\13\208\6\86\130\13\208\6\86\0\13\247\6\111\130\13\247\6\114\0",
	"\13\184\6\121\130\13\184\6\121\0\13\198\6\146\130\13\201\6\146\0\13\244\6\139\130\13\244\6\139\0\13\223\6\185\130\13\223\6\185\0",
	"\13\173\6\199\130\13\173\6\199\0\13\159\6\171\130\13\159\6\171\0\13\138\6\220\130\13\138\6\220\0\13\184\6\238\130\13\184\6\238\0",
	"\13\208\6\223\130\13\208\6\223\0\13\216\7\10\130\13\216\7\10\0\13\184\7\10\130\13\180\7\10\0\13\142\7\38\130\13\142\7\41\0",
	"\13\128\7\6\130\13\128\7\6\0\13\85\7\34\130\13\89\7\34\0\13\89\7\3\130\13\89\7\3\0\13\117\6\220\130\13\121\6\220\0",
	"\13\75\6\195\130\13\75\6\195\0\13\110\6\164\130\13\110\6\164\0\13\156\6\125\130\13\156\6\125\0\13\106\6\135\130\13\106\6\135\0",
	"\13\103\6\100\130\13\103\6\100\0\13\64\6\143\130\13\64\6\143\0\13\47\6\104\130\13\47\6\104\0\13\71\6\79\130\13\71\6\79\0",
	"\13\40\6\65\130\13\36\6\65\0\13\8\6\44\130\13\1\6\44\0\13\8\6\76\130\13\8\6\76\0\13\1\6\132\130\13\1\6\132\0",
	"\13\33\6\135\130\13\33\6\135\0\13\26\6\178\130\13\22\6\178\0\13\47\6\202\130\13\50\6\202\0\13\54\6\245\130\13\54\6\245\0",
	"\13\22\7\3\130\13\22\7\3\0\13\43\7\27\130\13\43\7\27\0\12\253\6\248\130\12\250\6\248\0\12\253\6\220\130\12\253\6\220\0",
	"\12\215\6\174\130\12\225\6\174\0\12\253\6\174\130\12\253\6\174\0\12\215\6\121\130\12\215\6\121\0\12\229\6\76\130\12\229\6\76\0",
	"\12\201\6\51\130\12\201\6\51\0\12\190\6\19\130\12\190\6\19\0\12\151\5\223\130\12\151\5\223\0\12\148\5\194\130\12\151\5\194\0",
	"\12\155\5\159\130\12\155\5\156\0\12\144\5\121\130\12\144\5\121\0\12\95\5\110\130\12\95\5\110\0\12\102\5\156\130\12\102\5\159\0",
	"\12\99\5\216\130\12\106\5\219\0\12\148\6\40\130\12\148\6\40\0\12\127\6\19\130\12\127\6\19\0\12\176\6\104\130\12\176\6\104\0",
	"\12\141\6\72\130\12\141\6\72\0\12\162\6\139\130\12\162\6\143\0\12\172\6\181\130\12\172\6\181\0\12\204\6\216\130\12\208\6\216\0",
	"\12\201\7\3\130\12\201\7\3\0\12\236\7\24\130\12\236\7\24\0\12\120\6\146\130\12\120\6\146\0\12\123\6\104\130\12\123\6\104\0",
	"\12\123\6\185\130\12\123\6\185\0\12\162\6\227\130\12\162\6\227\0\12\134\6\241\130\12\134\6\241\0\12\155\7\10\130\12\155\7\10\0",
	"\12\190\7\41\130\12\190\7\41\0\11\228\1\96\129\11\228\1\96\0\11\200\1\121\129\11\200\1\121\0\11\193\1\156\129\11\196\1\156\0",
	"\11\221\1\170\129\11\221\1\170\0\11\217\1\208\129\11\217\1\208\0\11\245\1\230\129\11\245\1\230\0\11\245\2\16\129\11\245\2\16\0",
	"\12\14\2\62\129\12\18\2\62\0\11\242\2\93\129\11\242\2\93\0\11\235\2\178\129\11\235\2\178\0\11\231\2\238\129\11\235\2\238\0",
	"\12\4\2\252\129\12\4\2\252\0\11\252\3\34\129\11\252\3\34\0\11\235\3\87\129\11\238\3\87\0\12\11\3\119\129\12\11\3\119\0",
	"\12\4\3\168\129\12\4\3\168\0\11\245\3\200\129\11\245\3\200\0\11\252\3\238\129\11\252\3\242\0\12\11\4\7\129\12\11\4\7\0",
	"\11\245\4\60\129\11\238\4\60\0\11\224\4\74\129\11\221\4\74\0\11\210\4\137\129\11\210\4\137\0\11\228\4\151\129\11\231\4\151\0",
	"\11\242\4\130\129\11\242\4\130\0\12\4\4\113\129\12\7\4\113\0\12\28\4\102\129\12\28\4\102\0\12\11\4\141\129\12\11\4\141\0",
	"\11\249\4\162\129\11\249\4\162\0\11\221\4\116\129\11\221\4\116\0\11\214\4\106\129\11\217\4\102\0\12\4\4\211\129\12\4\4\211\0",
	"\11\249\5\8\129\11\252\5\8\0\12\39\5\11\129\12\42\5\11\0\12\56\5\50\129\12\60\5\47\0\12\46\5\96\129\12\49\5\96\0",
	"\12\70\5\113\129\12\70\5\113\0\12\56\5\166\129\12\63\5\166\0\12\70\5\145\129\12\74\5\145\0\12\70\5\194\129\12\77\5\194\0",
	"\12\70\5\237\129\12\74\5\237\0\12\106\5\240\129\12\109\5\240\0\12\99\6\33\129\12\99\6\33\0\12\88\6\72\129\12\88\6\72\0",
	"\12\91\6\107\129\12\95\6\107\0\12\77\6\146\129\12\81\6\146\0\12\88\6\181\129\12\91\6\181\0\12\91\6\220\129\12\99\6\220\0",
	"\12\113\7\10\129\12\116\7\10\0\8\116\4\18\179\8\116\4\18\0\9\205\3\73\156\9\205\3\73\0\10\83\2\146\144\10\83\2\146\0",
	"\10\153\2\44\136\10\153\2\44\0\10\181\1\240\132\10\181\1\240\0\10\199\1\205\131\10\199\1\205\0\10\209\1\184\129\10\209\1\184\0",
	"\8\42\2\167\150\8\42\2\167\0\8\53\1\240\141\8\53\1\237\0\8\67\1\135\134\8\67\1\135\0\11\224\5\8\129\11\224\5\8\0",
	"\11\200\5\8\129\11\200\5\8\0\11\182\5\8\129\11\182\5\8\0\11\154\5\4\129\11\154\5\4\0\11\129\5\8\129\11\129\5\8\0",
	"\11\119\3\84\129\11\119\3\84\0\11\140\3\87\129\11\140\3\87\0\11\165\3\87\129\11\165\3\87\0\11\182\3\87\129\11\182\3\87\0",
	"\11\203\3\87\129\11\203\3\87\0\9\33\6\223\132\9\33\8\11\0\9\33\6\188\129\9\33\6\188\0\0\123\1\26\136\0\211\2\223\0",
	"\0\211\2\223\136\0\120\3\84\0\0\130\3\101\136\0\211\4\53\0\0\204\4\53\136\0\120\4\151\0\0\130\3\193\136\0\127\4\63\0",
	"\0\130\3\31\136\0\130\1\201\0\0\91\4\253\130\0\91\6\76\0\7\94\3\136\138\7\94\3\136\0\7\24\3\77\135\7\24\3\77\0",
	"\6\238\3\24\132\6\241\3\24\0\6\223\2\238\131\6\223\2\238\0\6\220\2\209\129\6\220\2\209\0\7\87\4\14\133\7\87\4\14\0",
	"\7\38\4\0\131\7\38\4\0\0\7\6\3\242\130\7\6\3\242\0\6\241\3\228\129\6\241\3\228\0\6\227\3\217\128\6\227\3\217\0",
	"\0\109\4\197\135\0\162\5\99\0\0\144\5\121\135\0\123\6\9\0\0\127\5\92\135\0\127\5\92\0\0\127\5\54\135\0\127\5\54\0",
	"\0\134\6\23\132\0\236\6\97\0\0\236\6\97\132\1\106\6\135\0\1\117\6\135\132\1\177\6\143\0\2\234\7\80\130\3\69\7\80\0",
	"\3\69\7\80\130\3\84\7\101\0\3\84\7\101\130\3\87\7\129\0\3\87\7\129\130\3\84\7\150\0\0\183\5\103\130\1\92\5\159\0",
	"\1\11\5\138\130\0\253\5\180\0\0\253\5\180\130\0\158\5\166\0\0\239\4\60\131\1\166\4\95\0\2\104\3\133\131\3\84\3\129\0",
	"\4\162\2\181\131\4\162\3\147\0\3\115\2\26\131\4\74\2\30\0\2\23\1\54\131\2\230\1\54\0\0\204\2\5\131\1\194\2\5\0",
	"\4\74\2\33\131\5\226\1\223\0\0\225\5\121\197\1\135\5\163\0\0\204\5\173\197\1\1\5\173\0\0\179\5\152\131\1\57\5\163\0",
	"\1\57\5\159\131\1\106\5\219\0\0\165\5\226\130\0\253\5\230\0\0\253\5\230\130\1\8\5\159\0\1\254\6\86\131\1\254\6\86\0",
	"\1\254\6\33\131\1\254\6\33\0\1\254\5\230\131\1\254\5\230\0\1\254\5\170\131\1\254\5\170\0\1\254\5\113\131\1\254\5\113\0",
	"\1\251\6\5\129\1\251\6\5\0\1\254\5\201\129\1\254\5\201\0\1\254\5\138\129\1\254\5\138\0\1\254\6\58\129\1\254\6\58\0",
	"\1\254\5\78\129\1\254\5\78\0\2\2\5\40\131\2\2\5\40\0\2\2\4\246\131\2\2\4\246\0\1\237\4\204\131\1\237\4\204\0",
	"\2\40\4\190\131\2\40\4\190\0\6\160\7\52\223\7\27\7\126\0\1\219\4\172\204\1\219\4\172\0\2\37\4\183\197\2\37\4\183\0",
	"\3\98\3\122\131\3\126\3\84\0\3\126\3\84\131\3\126\3\52\0\3\126\3\41\131\3\80\3\24\0\3\80\3\24\131\3\112\2\248\0",
	"\3\112\2\248\131\3\98\2\188\0",
}


-----------------------------Constants---------------------------------
choiceAccepted = 1
choiceRefused = 2
choiceAttacked = 3

choiceEliminate = 1
choiceSpare = 2

leaksNum = 1
denseNum = 2
waterNum = 3
buffaloNum = 4
chiefNum = 5
girlNum = 6
wiseNum = 7

nativeNames = {loc("Leaks A Lot"), loc("Dense Cloud"), loc("Fiery Water"), 
               loc("Raging Buffalo"), loc("Righteous Beard"), loc("Fell From Grace"),
               loc("Wise Oak")}

nativeUnNames = {loc("Zork"), loc("Steve"), loc("Jack"),
                 loc("Lee"), loc("Elmo"), loc("Rachel"),
                 loc("Muriel")}

nativeHats = {"Rambo", "RobinHood", "pirate_jack", "zoo_Bunny", "IndianChief",
              "tiara", "AkuAku"}

nativePos = {257, 1950}

cyborgNames = {loc("Syntax Errol"), loc("Segmentation Paul"), loc("Unexpected Igor"), loc("Jeremiah")}
cyborgPos = {745, 1847}
cyborgsPos = {{2937, 831}, {2945, 1264}, {2335, 1701}, {448, 484}}
cyborgsDir = {"Left", "Left", "Left", "Right"}

cratePos = {
            {{788, 1919, amGirder, 2}, true}, {{412, 1615, amGirder, 1}, true},
            {{209, 1474, amSniperRifle, 1}}, {{1178, 637, amDEagle, 1}},
            {{633, 268, amDEagle, 1}}, {{3016, 1545, amDEagle, 1}},
            {{249, 1377, amRope, 3}, true}, {{330, 1018, amGirder, 1}, true},
            {{888, 647, amRope, 3}, true}, {{2116, 337, amRope, 3}, true},
            {{1779, 948, amRope, 3}, true}, {{3090, 1066, amRope, 3}, true},
            {{947, 480, amBazooka, 3}}, {{1097, 480, amMortar, 3}},
            {{1139, 451, amSnowball, 3}}, {{1207, 468, amShotgun, 3}},
            {{1024, 393, amSniperRifle, 2}}, {{998, 391, amDynamite, 2}},
            {{1024, 343, amRope, 2}, true}, {{998, 341, amRope, 2}, true},
           }
reactions = {loc("Yeah, take that!"), loc("Bullseye"), loc("Die, die, die!")}

secondPos = {{1010, 510}, {1067, 510}}
-----------------------------Variables---------------------------------
natives = {}
native = nil

cyborgs = {}
cyborg = {}
cyborgsLeft = 0

gearDead = {}
hedgeHidden = {}

startAnim = {}
killAnim = {}
killedAnim = {}

freshDead = nil
crates = {}
cratesNum = 0
jetCrate = nil

firstTurn = true
cyborgsKilledBeforeCrates = false
cratesTaken = false
doneCyborgsDead = false

annoyingGearsForPortalScene = {}
-----------------------------Animations--------------------------------
function EmitDenseClouds(dir)
  local dif
  if dir == "Left" then
    dif = 10
  else
    dif = -10
  end
  AnimInsertStepNext({func = AnimVisualGear, args = {native, GetX(native) + dif, GetY(native) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimVisualGear, args = {native, GetX(native) + dif, GetY(native) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimVisualGear, args = {native, GetX(native) + dif, GetY(native) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimWait, args = {native, 800}})
  AnimInsertStepNext({func = AnimVisualGear, args = {native, GetX(native) + dif, GetY(native) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimVisualGear, args = {native, GetX(native) + dif, GetY(native) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimWait, args = {native, 800}})
  AnimInsertStepNext({func = AnimVisualGear, args = {native, GetX(native) + dif, GetY(native) + dif, vgtSteam, 0, true}, swh = false})
end

function AnimationSetup()
  startAnim = {}
  local m = m5DeployedNum
  table.insert(startAnim, {func = AnimWait, args = {native, 3000}})
  table.insert(startAnim, {func = AnimCaption, args = {native, string.format(loc("With the rest of the tribe gone, it was up to %s to save the village."), nativeNames[m5DeployedNum]), 5000}})
  table.insert(startAnim, {func = AnimCaption, args = {native, loc("But it proved to be no easy task!"), 2000}})
  for i = 1, 4 do
    table.insert(startAnim, {func = FollowGear, swh = false, args = {cyborgs[i]}})
    table.insert(startAnim, {func = AnimWait, args = {native, 1000}})
  end
  table.insert(startAnim, {func = FollowGear, swh = false, args = {native}})
  if m == leaksNum then
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 50, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("What a strange cave!"), SAY_THINK, 0}})
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 200, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("Now how do I get on the other side?!"), SAY_THINK, 5500}})
  elseif m == denseNum then
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 50, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("Dude, what's this place?!"), SAY_THINK, 0}})
    table.insert(startAnim, {func = AnimCustomFunction, args = {native, EmitDenseClouds, {"Right"}}})
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 200, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("And where's all the weed?"), SAY_THINK, 4000}})
  elseif m == waterNum then
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 50, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("Is this place in my head?"), SAY_THINK, 0}})
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 200, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("I shouldn't have drunk that last pint."), SAY_THINK, 6000}})
  elseif m == buffaloNum then
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 50, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("Where did that alien run?"), SAY_THINK, 0}})
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 200, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("When I find it..."), SAY_THINK, 3000}})
  elseif m == girlNum then
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 50, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("This is typical!"), SAY_THINK, 0}})
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 200, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("It's always up to women to clear up the mess men created!"), SAY_THINK, 8500}})
  elseif m == chiefNum then
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 50, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("What is this place?"), SAY_THINK, 0}})
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 200, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("It doesn't matter. I won't let that alien hurt my daughter!"), SAY_THINK, 8500}})
  elseif m == wiseNum then
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 50, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("Every single time!"), SAY_THINK, 0}})
    table.insert(startAnim, {func = AnimMove, args = {native, "Right", nativePos[1] + 200, 0}})
    table.insert(startAnim, {func = AnimSay, args = {native, loc("How come in a village full of warriors, it's up to me to save it?"), SAY_THINK, 8500}})
  end

  table.insert(startAnim, {func = AnimCustomFunction, args = {native, RestoreHedge, {cyborg, unpack(cyborgPos)}}})
  table.insert(startAnim, {func = AnimOutOfNowhere, args = {cyborg, unpack(cyborgPos)}})
  table.insert(startAnim, {func = AnimTurn, args = {cyborg, "Left"}})
  table.insert(startAnim, {func = AnimSay, args = {cyborg, string.format(loc("Greetings, %s!"), nativeUnNames[m]), SAY_SAY, 2500}})
  table.insert(startAnim, {func = AnimSay, args = {cyborg, loc("As you can see, there is no way to get on the other side!"), SAY_SAY, 7000}})
  table.insert(startAnim, {func = AnimSay, args = {cyborg, string.format(loc("I wish to help you, %s!"), nativeUnNames[m]), SAY_SAY, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {cyborg, loc("Beware, though! If you are slow, you die!"), SAY_SAY, 7000}})
  table.insert(startAnim, {func = AnimDisappear, args = {cyborg, unpack(cyborgPos)}})
  table.insert(startAnim, {func = AnimSwitchHog, args = {native}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {native, HideHedge, {cyborg}}})
  table.insert(startAnim, {func = AnimSay, args = {native, loc("Talk about mixed signals..."), SAY_SAY, 4000}})
  AddSkipFunction(startAnim, SkipStartAnim, {})
end

function SetupKillAnim()
  table.insert(killAnim, {func = AnimSay, args = {native, loc("Well, that was a waste of time."), SAY_THINK, 5000}})
  table.insert(killAnim, {func = AnimCustomFunction, args = {native, RestoreHedge, {cyborg, unpack(cyborgPos)}}})
  table.insert(killAnim, {func = AnimOutOfNowhere, args = {cyborg, unpack(cyborgPos)}})
  table.insert(killAnim, {func = AnimCustomFunction, args = {cyborg, CondNeedToTurn, {cyborg, native}}})
  table.insert(killAnim, {func = AnimSay, args = {cyborg, string.format(loc("You bear impressive skills, %s!"), nativeUnNames[m5DeployedNum]), SAY_SHOUT, 4000}})
  if CheckCyborgsDead() then
    table.insert(killAnim, {func = AnimSay, args = {cyborg, loc("I see you already took care of your enemies."), SAY_SHOUT, 7000}})
    table.insert(killAnim, {func = AnimSay, args = {cyborg, loc("Those were scheduled for disposal anyway."), SAY_SHOUT, 4000}})
    table.insert(killAnim, {func = AnimSay, args = {cyborg, loc("So you basically did the dirty work for us."), SAY_SHOUT, 4000}})
    cyborgsKilledBeforeCrates = true
  else
    table.insert(killAnim, {func = AnimSay, args = {cyborg, loc("However, my mates don't agree with me on letting you go..."), SAY_SHOUT, 7000}})
    table.insert(killAnim, {func = AnimSay, args = {cyborg, loc("I guess you'll have to kill them."), SAY_SHOUT, 4000}})
  end
  table.insert(killAnim, {func = AnimDisappear, args = {cyborg, unpack(cyborgPos)}})
  table.insert(killAnim, {func = AnimSwitchHog, args = {native}})
  table.insert(killAnim, {func = AnimWait, args = {native, 1}})
  table.insert(killAnim, {func = AnimCustomFunction, args = {native, HideHedge, {cyborg}}})

  local function checkCyborgsAgain()
     if CheckCyborgsDead() then
        DoCyborgsDead()
     end
  end
  table.insert(killAnim, {func = AnimCustomFunction, args = {native, checkCyborgsAgain, {}}})

  AddSkipFunction(killAnim, SkipKillAnim, {})
end

function SetupKilledAnim()
  table.insert(killedAnim, {func = AnimWait, args = {cyborg, 500}})
  table.insert(killedAnim, {func = AnimOutOfNowhere, args = {cyborg, unpack(secondPos[2])}})
  table.insert(killedAnim, {func = AnimOutOfNowhere, args = {native, unpack(secondPos[1])}})
  table.insert(killedAnim, {func = AnimCustomFunction, args = {cyborg, CondNeedToTurn, {cyborg, native}}})
  if not cyborgsKilledBeforeCrates then
    table.insert(killedAnim, {func = AnimSay, args = {cyborg, string.format(loc("Nice work, %s!"), nativeUnNames[m5DeployedNum]), SAY_SHOUT, 4000}})
  end
  table.insert(killedAnim, {func = AnimSay, args = {cyborg, loc("As a reward for your performance, here's some new technology!"), SAY_SHOUT, 8000}})
  table.insert(killedAnim, {func = AnimSay, args = {cyborg, loc("Use it wisely!"), SAY_SHOUT, 3000}})
  table.insert(killedAnim, {func = AnimDisappear, args = {cyborg, unpack(secondPos[2])}})
  table.insert(killedAnim, {func = AnimSwitchHog, args = {native}})
  AddSkipFunction(killedAnim, SkipKilledAnim, {})
end
--------------------------Anim skip functions--------------------------
function SkipStartAnim()
  AnimSetGearPosition(native, 457, 1955)
  AnimSwitchHog(native)
  AnimWait(native, 1)
  AddFunction({func = HideHedge, args = {cyborg}})
end

function SpawnCrateByID(id)
    if cratePos[id][2] == true then
       crates[id] = SpawnSupplyCrate(unpack(cratePos[id][1]))
    else
       crates[id] = SpawnSupplyCrate(unpack(cratePos[id][1]))
    end
    return crates[id]
end

function AfterStartAnim()
  SetGearMessage(native, 0)
  cratesNum = 0
  for i = 1, 6 do
    SpawnCrateByID(i)
    cratesNum = cratesNum + 1
  end
  FollowGear(native)
  AddNewEvent(CheckGearsDead, {{crates[1], crates[2]}}, PutCrates, {2}, 0) 
  TurnTimeLeft = TurnTime
  ShowMission(loc("Dragon's Lair"), loc("Obstacle course"), loc("In order to get to the other side, you need to get rid of the crates first.") .. "|" ..
                                                  loc("As the ammo is sparse, you might want to reuse ropes while mid-air.") .. "|" ..
                                                  loc("The enemy can't move but it might be a good idea to stay out of sight!") .. "|" ..
                                                  loc("Mines time: 5 seconds"), 1, 0)
end

function SkipKillAnim()
  AnimSwitchHog(native)
  AnimWait(native, 1)
  AddFunction({func = HideHedge, args = {cyborg}})
  if CheckCyborgsDead() then
    DoCyborgsDead()
  end
end

function AfterKillAnim()
  if not cyborgsKilledBeforeCrates then
    PutWeaponCrates()
    TurnTimeLeft = TurnTime
    AddEvent(CheckCyborgsDead, {}, DoCyborgsDead, {}, 0)
    ShowMission(loc("Dragon's Lair"), loc("The Slaughter"), loc("Kill the aliens!").."|"..loc("Mines time: 5 seconds"), 1, 2000)
  end
end

function SkipKilledAnim()
  AnimSetGearPosition(native, unpack(secondPos[1]))
  AnimSwitchHog(native)
  AnimWait(native, 1)
end

function AfterKilledAnim()
  -- Final mission segment with the portal gun
  HideHedge(cyborg)
  TurnTimeLeft = TurnTime
  SetGearMessage(native, 0)
  SpawnSupplyCrate(1184, 399, amPortalGun, 100)
  SpawnSupplyCrate(2259, 755, amTeleport, 2)
  SpawnHealthCrate(secondPos[1][1] + 50, secondPos[1][2] - 20)
  ShowMission(loc("Dragon's Lair"), loc("The what?!"), loc("Use the portal gun to get to the next crate, then use the new gun to get to the final destination!|")..
                                             loc("Portal hint: One goes to the destination, the other one is the entrance.|")..
                                             loc("Teleport hint: Just use the mouse to select the destination!").."|"..
                                             loc("Mines time: 5 seconds"), 1, 8000)
end
-----------------------------Events------------------------------------

function CheckCyborgsDead()
  return cyborgsLeft == 0
end

function NullifyAmmo()
  -- Clear the ammo and delete all inappropirate gears on the long platform for the portal scene
  AddAmmo(native, amRope, 0)
  AddAmmo(native, amGirder, 0)
  AddAmmo(native, amLowGravity, 0)
  AddAmmo(native, amBazooka, 0)
  AddAmmo(native, amSniperRifle, 0)
  AddAmmo(native, amDEagle, 0)
  AddAmmo(native, amDynamite, 0)
  AddAmmo(native, amFirePunch, 0)
  AddAmmo(native, amBaseballBat, 0)
  AddAmmo(native, amMortar, 0)
  AddAmmo(native, amSnowball, 0)
  AddAmmo(native, amShotgun, 0)

  for i=1, #annoyingGearsForPortalScene do
    local gear = annoyingGearsForPortalScene[i]
    if not gearDead[gear] and GetY(gear) > 100 and GetY(gear) < 571 and GetX(gear) > 840 and GetX(gear) < 1550 then
      DeleteGear(annoyingGearsForPortalScene[i])
    end
  end
end

function DoCyborgsDead()
  if cratesTaken and not doneCyborgsDead then
    NullifyAmmo()
    RestoreHedge(cyborg)
    SetupKilledAnim()
    SetGearMessage(CurrentHedgehog, 0)
    AddAnim(killedAnim)
    AddFunction({func = AfterKilledAnim, args = {}})
    doneCyborgsDead = true
  end
end


function PutWeaponCrates()
  for i = 1, 8 do
    cratesNum = cratesNum + 1
    SpawnCrateByID(cratesNum)
  end
  FollowGear(native)
end

function DoCratesTaken()
  cratesTaken = true
  SetupKillAnim()
  SetGearMessage(CurrentHedgehog, 0)
  AddAnim(killAnim)
  AddFunction({func = AfterKillAnim, args = {}})
end

function CheckPutCrates(gear)
  if gear and GetHealth(gear) then
    return StoppedGear(gear)
  else
    return false
  end
end

function PutCrates(index)
  if index <= 7 then
    cratesNum = cratesNum + 1
    SpawnCrateByID(cratesNum)
    AddNewEvent(CheckGearDead, {crates[cratesNum]}, PutCrates, {index + 1}, 0)
    FollowGear(native)
  else
    AddEvent(CheckPutCrates, {native}, DoCratesTaken, {}, 0)
  end
  if index == 4 then
    AnimSay(native, loc("I'm a ninja."), SAY_THINK, 0)
  end
end

function CheckMissionFinished()
  return gearDead[jetCrate] == true
end

function DoMissionFinished()
  AddCaption(loc("Salvation was one step closer now..."))
  if progress and progress<6 then
    SaveCampaignVar("Progress", "6")
  end
  RestoreHedge(cyborg)
  DeleteGear(cyborg)
  EndTurn(true)
end

function CheckGearsDead(gearList)
  for i = 1, # gearList do
    if gearDead[gearList[i]] ~= true then
      return false
    end
  end
  return true
end


function CheckGearDead(gear)
  return gearDead[gear]
end

function EndMission()
  RestoreHedge(cyborg)
  DeleteGear(cyborg)
  EndTurn(true)
end

function CheckFreshDead()
  return freshDead ~= nil
end

function CyborgDeadReact()
  freshDead = nil
  if cyborgsLeft == 0 then
    if not cratesTaken then
       AnimSay(native, loc("I still have to get rid of the crates."), SAY_THINK, 8000)
    end
    return
  end
  AnimSay(native, reactions[cyborgsLeft])
end
-----------------------------Misc--------------------------------------
function HideHedge(hedge)
  if hedgeHidden[hedge] ~= true then
    HideHog(hedge)
    hedgeHidden[hedge] = true
  end
end

function RestoreHedge(hedge)
  if hedgeHidden[hedge] == true then
    RestoreHog(hedge)
    hedgeHidden[hedge] = false
  end
end

function GetVariables()
  progress = tonumber(GetCampaignVar("Progress"))
  m5DeployedNum = tonumber(GetCampaignVar("M5DeployedNum")) or leaksNum
end

function SetupPlace()
  for i = 1, 7 do
    if i ~= m5DeployedNum then 
      DeleteGear(natives[i])
    else
      native = natives[i]
    end
  end
  HideHedge(cyborg)
  jetCrate = SpawnSupplyCrate(3915, 1723, amJetpack)

  --[[ Block the left entrance.
       Otherwise the player could rope out of the map and
       go all the way around to the final crate. ]]
  PlaceGirder(90, 1709, 6)
  PlaceGirder(90, 1875, 6)

  -- Place mines on the ground floor
  AddGear(1071, 1913, gtMine, 0, 0, 0, 0)
  AddGear(1098, 1919, gtMine, 0, 0, 0, 0)
  AddGear(1136, 1923, gtMine, 0, 0, 0, 0)
  AddGear(1170, 1930, gtMine, 0, 0, 0, 0)
  AddGear(1203, 1924, gtMine, 0, 0, 0, 0)
  AddGear(1228, 1939, gtMine, 0, 0, 0, 0)
  AddGear(1264, 1931, gtMine, 0, 0, 0, 0)
  AddGear(1309, 1938, gtMine, 0, 0, 0, 0)
  AddGear(1352, 1936, gtMine, 0, 0, 0, 0)
  AddGear(1386, 1939, gtMine, 0, 0, 0, 0)
  AddGear(1432, 1942, gtMine, 0, 0, 0, 0)
  AddGear(1483, 1950, gtMine, 0, 0, 0, 0)
  AddGear(1530, 1954, gtMine, 0, 0, 0, 0)
  AddGear(1579, 1959, gtMine, 0, 0, 0, 0)
  AddGear(1000, 1903, gtMine, 0, 0, 0, 0)
  AddGear(957, 1903, gtMine, 0, 0, 0, 0)
  AddGear(909, 1910, gtMine, 0, 0, 0, 0)
  AddGear(889, 1917, gtMine, 0, 0, 0, 0)

  -- Place misc. mines
  AddGear(759, 878, gtMine, 0, 0, 0, 0)
  AddGear(2388, 759, gtMine, 0, 0, 0, 0)
  AddGear(2498, 696, gtMine, 0, 0, 0, 0)
  AddGear(2936, 1705, gtMine, 0, 0, 0, 0)
  AddGear(3119, 1366, gtMine, 0, 0, 0, 0)
  AddGear(2001, 832, gtMine, 0, 0, 0, 0)
  AddGear(2008, 586, gtMine, 0, 0, 0, 0)
  AddGear(511, 1245, gtMine, 0, 0, 0, 0)

  -- And one barrel for fun
  AddGear(719, 276, gtExplosives, 0, 0, 0, 0)

  ------ STICKY MINE LIST ------
  AddGear(1199, 733, gtSMine, 0, 0, 0, 0)
  AddGear(1195, 793, gtSMine, 0, 0, 0, 0)
  AddGear(1201, 861, gtSMine, 0, 0, 0, 0)
  AddGear(682, 878, gtSMine, 0, 0, 0, 0)
  AddGear(789, 876, gtSMine, 0, 0, 0, 0)
end

function SetupEvents()
  AddNewEvent(CheckMissionFinished, {}, DoMissionFinished, {}, 0)
  AddNewEvent(CheckGearDead, {native}, EndMission, {}, 0)
  AddNewEvent(CheckFreshDead, {}, CyborgDeadReact, {}, 1)
end

function SetupAmmo()
  AddAmmo(cyborgs[1], amBazooka, 100)
  AddAmmo(cyborgs[1], amShotgun, 100)
  AddAmmo(cyborgs[1], amSwitch, 100)
end

function AddHogs()
  AddTeam(loc("Natives"), 0x4980C1, "Bone", "Island", "HillBilly", "cm_birdy")
  for i = 1, 7 do
    natives[i] = AddHog(nativeNames[i], 0, 200, nativeHats[i])
    gearDead[natives[i]] = false
  end

  AddTeam(loc("011101001"), 0xFF0204, "ring", "UFO", "Robot", "cm_binary")
  cyborg = AddHog(loc("Unit 334a$7%;.*"), 0, 200, "cyborg1")
  gearDead[cyborg] = false

  AddTeam(loc("011101000"), 0xFFFF01, "ring", "UFO", "Robot", "cm_binary")
  for i = 1, 4 do
    cyborgs[i] = AddHog(cyborgNames[i], 2, 100, "cyborg2")
    gearDead[cyborgs[i]] = false
    SetEffect(cyborgs[i], heArtillery, 1)
  end
  cyborgsLeft = 4

  for i = 1, 7 do
    AnimSetGearPosition(natives[i], unpack(nativePos))
  end

  AnimSetGearPosition(cyborg, unpack(cyborgPos))

  for i = 1, 4 do
    AnimSetGearPosition(cyborgs[i], unpack(cyborgsPos[i]))
    AnimTurn(cyborgs[i], cyborgsDir[i])
  end

end

function CondNeedToTurn(hog1, hog2)
  xl, xd = GetX(hog1), GetX(hog2)
  if xl > xd then
    AnimInsertStepNext({func = AnimTurn, args = {hog1, "Left"}})
    AnimInsertStepNext({func = AnimTurn, args = {hog2, "Right"}})
  elseif xl < xd then
    AnimInsertStepNext({func = AnimTurn, args = {hog2, "Left"}})
    AnimInsertStepNext({func = AnimTurn, args = {hog1, "Right"}})
  end
end

-----------------------------Main Functions----------------------------

function onGameInit()
  Seed = 0
  GameFlags = gfSolidLand + gfDisableLandObjects + gfDisableWind + gfDisableGirders
  TurnTime = 60000 
  CaseFreq = 0
  MinesNum = 0
  MinesTime = 5000
  Explosives = 0
  MapGen = mgDrawn
  Theme = "City"
  SuddenDeathTurns = 25

  for i = 1, #map do
     ParseCommand('draw ' .. map[i])
  end

  AddHogs()
  AnimInit(true)
end

function onGameStart()
  GetVariables()
  SetupAmmo()
  SetupPlace()
  AnimationSetup()
  SetupEvents()
  ShowMission(loc("Dragon's Lair"), loc("Y Chwiliad"), loc("Find your tribe!|Cross the lake!"), 1, 0)
end

function onGameTick()
  AnimUnWait()
  if ShowAnimation() == false then
    return
  end
  ExecuteAfterAnimations()
  CheckEvents()
end

function onGearDelete(gear)
  gearDead[gear] = true
  if GetGearType(gear) == gtHedgehog then
    if GetHogTeamName(gear) == loc("011101000") then
      freshDead = GetHogName(gear)
      cyborgsLeft = cyborgsLeft - 1
    end
  end
end

function onGearAdd(gear)
  -- Track gears for removal when reaching the portal segment
  local gt = GetGearType(gear)
  if gt == gtMine or gt == gtSMine or gt == gtCase or gt == gtExplosives then
    table.insert(annoyingGearsForPortalScene, gear)
  end
end

function onAmmoStoreInit()
  SetAmmo(amFirePunch, 3, 0, 0, 0)
  SetAmmo(amBaseballBat, 2, 0, 0, 0)
  SetAmmo(amGirder, 0, 0, 0, 2)
  SetAmmo(amLowGravity, 0, 0, 0, 1)
  SetAmmo(amJetpack, 0, 0, 0, 1)
  SetAmmo(amSkip, 9, 0, 0, 0)
end

function onNewTurn()
  if firstTurn then
    AddAnim(startAnim)
    AddFunction({func = AfterStartAnim, args = {}})
    firstTurn = false
  end
  if GetHogTeamName(CurrentHedgehog) == loc("011101000") then
    if TotalRounds % 6 == 0 then
      AddAmmo(CurrentHedgehog, amSniperRifle, 1)
      AddAmmo(CurrentHedgehog, amDEagle, 1)
    end
    TurnTimeLeft = 30000
  elseif GetHogTeamName(CurrentHedgehog) == loc("011101001") then
    EndTurn(true)
  end
end

function onPrecise()
  if GameTime > 2500 and AnimInProgress() then
    SetAnimSkip(true)
  end
end
