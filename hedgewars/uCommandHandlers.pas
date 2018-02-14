(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

{$INCLUDE "options.inc"}

unit uCommandHandlers;

interface

procedure initModule;
procedure freeModule;

implementation
uses uCommands, uTypes, uVariables, uIO, uDebug, uConsts, uScript, uUtils, SDLh, uWorld, uRandom, uCaptions, uConsole
    , uVisualGearsList, uGearsHedgehog
     {$IFDEF USE_VIDEO_RECORDING}, uVideoRec {$ENDIF};

var prevGState: TGameState = gsConfirm;
    cTagsMasks : array[0..15] of byte = (7, 0, 0, 0, 15, 6, 4, 5, 0, 0, 0, 0, 0, 14, 12, 13);
    cTagsMasksNoHealth: array[0..15] of byte = (3, 2, 11, 1, 0, 0, 0, 0, 0, 10, 0, 9, 0, 0, 0, 0);

procedure chGenCmd(var s: shortstring);
begin
case s[1] of
    'R': if ReadyTimeLeft > 0 then
        begin
        ReadyTimeLeft:= 0;
        if not isExternalSource then
            SendIPC('c'+s);
        end
    end
end;

procedure chQuit(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    if (GameState = gsGame) or (GameState = gsChat) then
        begin
        prevGState:= GameState;
        GameState:= gsConfirm;
        end
    else
        if GameState = gsConfirm then
            GameState:= prevGState;

    updateCursorVisibility;
end;

procedure chForceQuit(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    GameState:= gsConfirm;
    ParseCommand('confirm', true);
end;

procedure chConfirm(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    if GameState = gsConfirm then
        begin
        SendIPC(_S'Q');
        GameState:= gsExit
        end
end;

procedure chHalt (var s: shortstring);
begin
    s:= s; // avoid compiler hint
    SendIPC(_S'H');
    GameState:= gsExit
end;

procedure chCheckProto(var s: shortstring);
var i: LongInt;
begin
    if isDeveloperMode then
        begin
        i:= StrToInt(s);
        checkFails(i <= cNetProtoVersion, 'Protocol version mismatch: engine is too old (got '+intToStr(i)+', expecting '+intToStr(cNetProtoVersion)+')', true);
        checkFails(i >= cNetProtoVersion, 'Protocol version mismatch: engine is too new (got '+intToStr(i)+', expecting '+intToStr(cNetProtoVersion)+')', true);
        end
end;

procedure chTeamLocal(var s: shortstring);
begin
s:= s; // avoid compiler hint
if not isDeveloperMode then
    exit;
if CurrentTeam = nil then
    OutError(errmsgIncorrectUse + ' "/rdriven"', true);
CurrentTeam^.ExtDriven:= true
end;

procedure chScript(var s: shortstring);
begin
if s[1]='"' then
    Delete(s, 1, 1);
if s[byte(s[0])]='"' then
    Delete(s, byte(s[0]), 1);
cScriptName:= s;
ScriptLoad(s)
end;

procedure chScriptParam(var s: shortstring);
begin
    ScriptSetString('ScriptParam', s);
    ScriptCall('onParameters');
end;

procedure chCurU_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementY:= -1;
end;

procedure chCurU_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementY:= 0;
end;

procedure chCurD_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementY:= 1;
end;

procedure chCurD_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementY:= 0;
end;

procedure chCurL_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementX:= -1;
end;

procedure chCurL_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementX:= 0;
end;

procedure chCurR_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementX:= 1;
end;

procedure chCurR_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementX:= 0;
end;

procedure chLeft_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
if not isExternalSource then
    SendIPC(_S'L');
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or (gmLeft and InputMask);
    ScriptCall('onLeft');
end;

procedure chLeft_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
if not isExternalSource then
    SendIPC(_S'l');
with CurrentHedgehog^.Gear^ do
    Message:= Message and (not (gmLeft and InputMask));
    ScriptCall('onLeftUp');
end;

procedure chRight_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
if not isExternalSource then
    SendIPC(_S'R');
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or (gmRight and InputMask);
    ScriptCall('onRight');
end;

procedure chRight_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
if not isExternalSource then
    SendIPC(_S'r');
with CurrentHedgehog^.Gear^ do
    Message:= Message and (not (gmRight and InputMask));
    ScriptCall('onRightUp');
end;

procedure chUp_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
if not isExternalSource then
    SendIPC(_S'U');
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or (gmUp and InputMask);
    ScriptCall('onUp');
end;

procedure chUp_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
if not isExternalSource then
    SendIPC(_S'u');
with CurrentHedgehog^.Gear^ do
    Message:= Message and (not (gmUp and InputMask));
    ScriptCall('onUpUp');
end;

procedure chDown_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
if not isExternalSource then
    SendIPC(_S'D');
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or (gmDown and InputMask);
    ScriptCall('onDown');
end;

procedure chDown_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
if not isExternalSource then
    SendIPC(_S'd');
with CurrentHedgehog^.Gear^ do
    Message:= Message and (not (gmDown and InputMask));
    ScriptCall('onDownUp');
end;

procedure chPrecise_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
if not isExternalSource then
    SendIPC(_S'Z');
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or (gmPrecise and InputMask);
    ScriptCall('onPrecise');
end;

procedure chPrecise_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
if not isExternalSource then
    SendIPC(_S'z');
with CurrentHedgehog^.Gear^ do
    Message:= Message and (not (gmPrecise and InputMask));
    ScriptCall('onPreciseUp');
end;

procedure chLJump(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
if not isExternalSource then
    SendIPC(_S'j');
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or (gmLJump and InputMask);
    ScriptCall('onLJump');
end;

procedure chHJump(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
if not isExternalSource then
    SendIPC(_S'J');
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or (gmHJump and InputMask);
    ScriptCall('onHJump');
end;

procedure chAttack_p(var s: shortstring);
var inbtwnTrgtAttks: Boolean;
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    begin
    AddFileLog('/+attack: hedgehog''s Gear^.State = '+inttostr(State));
    if ((State and gstHHDriven) <> 0) then
        begin
        inbtwnTrgtAttks:= ((GameFlags and gfInfAttack) <> 0) and ((Ammoz[CurrentHedgehog^.CurAmmoType].Ammo.Propz and ammoprop_NeedTarget) <> 0);
        if (not inbtwnTrgtAttks) then
            FollowGear:= CurrentHedgehog^.Gear;
        if not isExternalSource then
            SendIPC(_S'A');
        Message:= Message or (gmAttack and InputMask);
        ScriptCall('onAttack'); // so if I fire airstrike, it doesn't count as attack? fine, fine
        end
    end
end;

procedure chAttack_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
with CurrentHedgehog^.Gear^ do
    begin
    if not isExternalSource and
        ((Message and gmAttack) <> 0) then
            SendIPC(_S'a');
    Message:= Message and (not (gmAttack and InputMask));
    ScriptCall('onAttackUp');
    end
end;

procedure chSwitch(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;
if not isExternalSource then
    SendIPC(_S'S');
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or (gmSwitch and InputMask);
    ScriptCall('onSwitch');
end;

procedure chNextTurn(var s: shortstring);
var gi: PGear;
begin
    s:= s; // avoid compiler hint

    if checkFails(AllInactive, '/nextturn called when not all gears are inactive', true) then exit;

    CheckSum:= CheckSum xor GameTicks;
    gi := GearsList;
    while gi <> nil do
        begin
        with gi^ do CheckSum:= CheckSum xor X.round xor X.frac xor dX.round xor dX.frac xor Y.round xor Y.frac xor dY.round xor dY.frac;
        AddRandomness(CheckSum);
        gi := gi^.NextGear
        end;

    if not isExternalSource then
        begin
        s[0]:= #5;
        s[1]:= 'N';
        SDLNet_Write32(CheckSum, @s[2]);
        SendIPC(s)
        end
    else
        checkFails(CurrentTeam^.hasGone or (CheckSum = lastTurnChecksum), 'Desync detected', true);

    AddFileLog('Next turn: time '+inttostr(GameTicks));
end;

procedure chTimer(var s: shortstring);
begin
if CheckNoTeamOrHH then
    exit;

if checkFails((s[0] = #1) and (s[1] >= '1') and (s[1] <= '5'), 'Malformed /timer', true) then exit;

if not isExternalSource then
    SendIPC(s);
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    begin
    Message:= Message or (gmTimer and InputMask);
    MsgParam:= byte(s[1]) - ord('0');
    ScriptCall('onTimer', MsgParam);
    end
end;

procedure chSlot(var s: shortstring);
var slot: LongWord;
    ss: shortstring;
begin
if (s[0] <> #1) or CheckNoTeamOrHH then
    exit;
slot:= byte(s[1]) - 49;
if slot > cMaxSlotIndex then
    exit;
if not isExternalSource then
    begin
    ss[0]:= #1;
    ss[1]:= char(byte(s[1]) + 79);
    SendIPC(ss);
    end;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    begin
    Message:= Message or (gmSlot and InputMask);
    MsgParam:= slot;
    ScriptCall('onSlot', MsgParam);
    end
end;

procedure chSetWeapon(var s: shortstring);
begin
    if CheckNoTeamOrHH then
        exit;

    if checkFails((s[0] = #1) and (s[1] <= char(High(TAmmoType))), 'Malformed /setweap', true) then exit;

    if not isExternalSource then
        SendIPC('w' + s);

    with CurrentHedgehog^.Gear^ do
        begin
        Message:= Message or (gmWeapon and InputMask);
        MsgParam:= byte(s[1]);
        ScriptCall('onSetWeapon', MsgParam);
        end;
end;

procedure chTaunt(var s: shortstring);
begin
if (s[0] <> #1) or CheckNoTeamOrHH then
    exit;

if TWave(s[1]) > High(TWave) then
    exit;

if not isExternalSource then
    SendIPC('t' + s);

PlayTaunt(byte(s[1]))
end;

procedure chPut(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    doPut(0, 0, false);
end;

procedure chCapture(var s: shortstring);
begin
s:= s; // avoid compiler hint
flagMakeCapture:= true;
flagDumpLand:= (LocalMessage and gmPrecise  <> 0);
end;

procedure chRecord(var s: shortstring);
begin
s:= s; // avoid compiler hint
{$IFDEF USE_VIDEO_RECORDING}
if flagPrerecording then
    StopPreRecording()
else
    BeginPreRecording();
{$ENDIF}
end;

procedure chSetMap(var s: shortstring);
begin
if isDeveloperMode then
    begin
    if s = '' then
        cPathz[ptMapCurrent]:= s
    else
        cPathz[ptMapCurrent]:= cPathz[ptMaps] + '/' + s;
    InitStepsFlags:= InitStepsFlags or cifMap
    end;
cMapName:= s;
ScriptLoad('Maps/' + s + '/map.lua')
end;

procedure chSetTheme(var s: shortstring);
begin
if isDeveloperMode then
    begin
    cPathz[ptCurrTheme]:= cPathz[ptThemes] + '/' + s;
    Theme:= s;
    InitStepsFlags:= InitStepsFlags or cifTheme
    end
end;

procedure chSetSeed(var s: shortstring);
begin
if isDeveloperMode then
    begin
    SetRandomSeed(s, true);
    cSeed:= s;
    InitStepsFlags:= InitStepsFlags or cifRandomize
    end
end;

procedure chAmmoMenu(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    bShowAmmoMenu:= (not bShowAmmoMenu)
else
    begin
    with CurrentTeam^ do
        with Hedgehogs[CurrHedgehog] do
            begin
            bSelected:= false;

            if bShowAmmoMenu then
                bShowAmmoMenu:= false
            else if not(CurrentTeam^.Extdriven) and ((Gear = nil) or ((Gear^.State and (gstAttacking or gstAttacked)) <> 0)
            or ((Gear^.State and gstHHDriven) = 0)) then
                begin
                end
            else
                bShowAmmoMenu:= true
            end;
    end
end;

procedure chVol_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
inc(cVolumeDelta, 3)
end;

procedure chVol_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
dec(cVolumeDelta, 3)
end;

procedure chFindhh(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    exit;

if autoCameraOn then
    begin
    FollowGear:= nil;
    AddCaption(trmsg[sidAutoCameraOff], $CCCCCC, capgrpVolume);
    autoCameraOn:= false
    end
else
    begin
    AddCaption(trmsg[sidAutoCameraOn], $CCCCCC, capgrpVolume);
    bShowFinger:= true;
    if not CurrentHedgehog^.Unplaced then
        FollowGear:= CurrentHedgehog^.Gear;
    autoCameraOn:= true
    end
end;

procedure chPause(var s: shortstring);
begin
if (gameType <> gmtNet) or (s = 'server') then
    isPaused:= not isPaused
    else
    if (CurrentTeam^.ExtDriven) or (CurrentHedgehog^.BotLevel > 0) then
        isAFK:= not isAFK
    else
        isAFK:= false; // for real ninjas

updateCursorVisibility;
end;

procedure chRotateMask(var s: shortstring);
begin
s:= s; // avoid compiler hint
// this is just for me, 'cause I thought it'd be fun.  using the old precise + switch to keep it out of people's way
if LocalMessage and (gmPrecise or gmSwitch) = (gmPrecise or gmSwitch) then
    begin
    if UIDisplay <> uiNone then
         UIDisplay:= uiNone
    else UIDisplay:= uiAll
    end
else
    begin
    if UIDisplay <> uiNoTeams then
         UIDisplay:= uiNoTeams
    else UIDisplay:= uiAll
    end
end;

procedure chRotateTags(var s: shortstring);
begin
s:= s; // avoid compiler hint
if ((GameFlags and gfInvulnerable) = 0) then
    cTagsMask:= cTagsMasks[cTagsMask]
else
    cTagsMask:= cTagsMasksNoHealth[cTagsMask]
end;

procedure chSpeedup_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
SpeedStart:= RealTicks;
isSpeed:= true
end;

procedure chSpeedup_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
isSpeed:= false
end;

procedure chZoomIn(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    if ZoomValue < cMinZoomLevel then
        ZoomValue:= ZoomValue + cZoomDelta;
end;

procedure chZoomOut(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    if ZoomValue > cMaxZoomLevel then
        ZoomValue:= ZoomValue - cZoomDelta;
end;

procedure chZoomReset(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    ZoomValue:= cDefaultZoomLevel;
end;

procedure chMapGen(var s: shortstring);
begin
cMapGen:= TMapGen(StrToInt(s))
end;

procedure chTemplateFilter(var s: shortstring);
begin
cTemplateFilter:= StrToInt(s)
end;

procedure chFeatureSize(var s: shortstring);
begin
cFeatureSize:= StrToInt(s)
end;

procedure chInactDelay(var s: shortstring);
begin
cInactDelay:= StrToInt(s)
end;

procedure chReadyDelay(var s: shortstring);
begin
cReadyDelay:= StrToInt(s)
end;

procedure chCaseFactor(var s: shortstring);
begin
cCaseFactor:= StrToInt(s)
end;

procedure chHealthCaseProb(var s: shortstring);
begin
cHealthCaseProb:= StrToInt(s)
end;

procedure chHealthCaseAmount(var s: shortstring);
begin
cHealthCaseAmount:= StrToInt(s)
end;

procedure chSuddenDTurns(var s: shortstring);
begin
cSuddenDTurns:= StrToInt(s)
end;

procedure chWaterRise(var s: shortstring);
begin
cWaterRise:= StrToInt(s)
end;

procedure chHealthDecrease(var s: shortstring);
begin
cHealthDecrease:= StrToInt(s)
end;

procedure chDamagePercent(var s: shortstring);
begin
cDamagePercent:= StrToInt(s)
end;

procedure chRopePercent(var s: shortstring);
begin
cRopePercent:= StrToInt(s)
end;

procedure chGetAwayTime(var s: shortstring);
begin
cGetAwayTime:= StrToInt(s)
end;

procedure chMineDudPercent(var s: shortstring);
begin
cMineDudPercent:= StrToInt(s)
end;

procedure chLandMines(var s: shortstring);
begin
cLandMines:= StrToInt(s)
end;

procedure chAirMines(var s: shortstring);
begin
cAirMines:= StrToInt(s)
end;

procedure chExplosives(var s: shortstring);
begin
cExplosives:= StrToInt(s)
end;

procedure chGameFlags(var s: shortstring);
begin
GameFlags:= StrToInt(s);
if GameFlags and gfSharedAmmo <> 0 then GameFlags:= GameFlags and (not gfPerHogAmmo)
end;

procedure chHedgehogTurnTime(var s: shortstring);
begin
cHedgehogTurnTime:= StrToInt(s)
end;

procedure chMinesTime(var s: shortstring);
begin
cMinesTime:= StrToInt(s)
end;

procedure chFastUntilLag(var s: shortstring);
begin
    fastUntilLag:= StrToInt(s) <> 0;

    if not fastUntilLag then
    begin
        // update health bars and the wind indicator
        AddVisualGear(0, 0, vgtTeamHealthSorter);
        AddVisualGear(0, 0, vgtSmoothWindBar)
    end
end;

procedure chCampVar(var s:shortstring);
begin
  CampaignVariable := s;
end;

procedure chWorldEdge(var s: shortstring);
begin
WorldEdge:= TWorldEdge(StrToInt(s))
end;

procedure chAdvancedMapGenMode(var s:shortstring);
begin
  s:= s; // avoid compiler hint
  cAdvancedMapGenMode:= true;
end;

procedure initModule;
begin
//////// Begin top sorted by freq analysis not including chatmsg
    RegisterVariable('+right'  , @chRight_p      , false, true);
    RegisterVariable('-right'  , @chRight_m      , false, true);
    RegisterVariable('+up'     , @chUp_p         , false, true);
    RegisterVariable('-up'     , @chUp_m         , false, true);
    RegisterVariable('+left'   , @chLeft_p       , false, true);
    RegisterVariable('-left'   , @chLeft_m       , false, true);
    RegisterVariable('+attack' , @chAttack_p     , false);
    RegisterVariable('+down'   , @chDown_p       , false, true);
    RegisterVariable('-down'   , @chDown_m       , false, true);
    RegisterVariable('hjump'   , @chHJump        , false, true);
    RegisterVariable('ljump'   , @chLJump        , false, true);
    RegisterVariable('nextturn', @chNextTurn     , false);
    RegisterVariable('-attack' , @chAttack_m     , false);
    RegisterVariable('slot'    , @chSlot         , false);
    RegisterVariable('setweap' , @chSetWeapon    , false, true);
//////// End top by freq analysis
    RegisterVariable('gencmd'  , @chGenCmd       , false);
    RegisterVariable('script'  , @chScript       , false);
    RegisterVariable('scriptparam', @chScriptParam, false);
    RegisterVariable('proto'   , @chCheckProto   , true );
    RegisterVariable('spectate', @chFastUntilLag   , false);
    RegisterVariable('capture' , @chCapture      , true );
    RegisterVariable('rotmask' , @chRotateMask   , true );
    RegisterVariable('rottags' , @chRotateTags   , true );
    RegisterVariable('rdriven' , @chTeamLocal    , false);
    RegisterVariable('map'     , @chSetMap       , false);
    RegisterVariable('theme'   , @chSetTheme     , false);
    RegisterVariable('seed'    , @chSetSeed      , false);
    RegisterVariable('template_filter', @chTemplateFilter, false);
    RegisterVariable('mapgen'  , @chMapGen        , false);
    RegisterVariable('maze_size',@chTemplateFilter, false);
    RegisterVariable('feature_size',@chFeatureSize, false);
    RegisterVariable('delay'   , @chInactDelay    , false);
    RegisterVariable('ready'   , @chReadyDelay    , false);
    RegisterVariable('casefreq', @chCaseFactor    , false);
    RegisterVariable('healthprob', @chHealthCaseProb, false);
    RegisterVariable('hcaseamount', @chHealthCaseAmount, false);
    RegisterVariable('sd_turns', @chSuddenDTurns  , false);
    RegisterVariable('waterrise', @chWaterRise    , false);
    RegisterVariable('healthdec', @chHealthDecrease, false);
    RegisterVariable('damagepct',@chDamagePercent , false);
    RegisterVariable('ropepct' , @chRopePercent   , false);
    RegisterVariable('getawaytime' , @chGetAwayTime , false);
    RegisterVariable('minedudpct',@chMineDudPercent, false);
    RegisterVariable('minesnum', @chLandMines     , false);
    RegisterVariable('airmines', @chAirMines      , false);
    RegisterVariable('explosives',@chExplosives    , false);
    RegisterVariable('gmflags' , @chGameFlags      , false);
    RegisterVariable('turntime', @chHedgehogTurnTime, false);
    RegisterVariable('minestime',@chMinesTime     , false);
    RegisterVariable('quit'    , @chQuit         , true );
    RegisterVariable('forcequit', @chForceQuit   , true );
    RegisterVariable('confirm' , @chConfirm      , true );
    RegisterVariable('halt',     @chHalt         , true );
    RegisterVariable('+speedup', @chSpeedup_p    , true );
    RegisterVariable('-speedup', @chSpeedup_m    , true );
    RegisterVariable('zoomin'  , @chZoomIn       , true );
    RegisterVariable('zoomout' , @chZoomOut      , true );
    RegisterVariable('zoomreset',@chZoomReset    , true );
    RegisterVariable('ammomenu', @chAmmoMenu     , true);
    RegisterVariable('+precise', @chPrecise_p    , false, true);
    RegisterVariable('-precise', @chPrecise_m    , false, true);
    RegisterVariable('switch'  , @chSwitch       , false);
    RegisterVariable('timer'   , @chTimer        , false, true);
    RegisterVariable('taunt'   , @chTaunt        , false);
    RegisterVariable('put'     , @chPut          , false);
    RegisterVariable('+volup'  , @chVol_p        , true );
    RegisterVariable('-volup'  , @chVol_m        , true );
    RegisterVariable('+voldown', @chVol_m        , true );
    RegisterVariable('-voldown', @chVol_p        , true );
    RegisterVariable('findhh'  , @chFindhh       , true );
    RegisterVariable('pause'   , @chPause        , true );
    RegisterVariable('+cur_u'  , @chCurU_p       , true );
    RegisterVariable('-cur_u'  , @chCurU_m       , true );
    RegisterVariable('+cur_d'  , @chCurD_p       , true );
    RegisterVariable('-cur_d'  , @chCurD_m       , true );
    RegisterVariable('+cur_l'  , @chCurL_p       , true );
    RegisterVariable('-cur_l'  , @chCurL_m       , true );
    RegisterVariable('+cur_r'  , @chCurR_p       , true );
    RegisterVariable('-cur_r'  , @chCurR_m       , true );
    RegisterVariable('campvar' , @chCampVar      , true );
    RegisterVariable('record'  , @chRecord       , true );
    RegisterVariable('worldedge',@chWorldEdge    , false);
    RegisterVariable('advmapgen',@chAdvancedMapGenMode, false);
end;

procedure freeModule;
begin
end;

end.
