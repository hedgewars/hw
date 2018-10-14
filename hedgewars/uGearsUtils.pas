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

unit uGearsUtils;
interface
uses uTypes, uFloat;

procedure doMakeExplosion(X, Y, Radius: LongInt; AttackingHog: PHedgehog; Mask: Longword); inline;
procedure doMakeExplosion(X, Y, Radius: LongInt; AttackingHog: PHedgehog; Mask: Longword; const Tint: LongWord);
procedure AddSplashForGear(Gear: PGear; justSkipping: boolean);
procedure AddBounceEffectForGear(Gear: PGear; imageScale: Single);
procedure AddBounceEffectForGear(Gear: PGear);

function  ModifyDamage(dmg: Longword; Gear: PGear): Longword;
procedure ApplyDamage(Gear: PGear; AttackerHog: PHedgehog; Damage: Longword; Source: TDamageSource);
procedure spawnHealthTagForHH(HHGear: PGear; dmg: Longword);
procedure HHHurt(Hedgehog: PHedgehog; Source: TDamageSource);
procedure HHHeal(Hedgehog: PHedgehog; healthBoost: LongInt; showMessage: boolean; vgTint: Longword);
procedure HHHeal(Hedgehog: PHedgehog; healthBoost: LongInt; showMessage: boolean);
function IncHogHealth(Hedgehog: PHedgehog; healthBoost: LongInt): LongInt;
procedure CheckHHDamage(Gear: PGear);
procedure CalcRotationDirAngle(Gear: PGear);
procedure ResurrectHedgehog(var gear: PGear);

procedure FindPlace(var Gear: PGear; withFall: boolean; Left, Right: LongInt); inline;
procedure FindPlace(var Gear: PGear; withFall: boolean; Left, Right: LongInt; skipProximity: boolean);

function  CheckGearNear(Kind: TGearType; X, Y: hwFloat; rX, rY: LongInt): PGear;
function  CheckGearNear(Gear: PGear; Kind: TGearType; rX, rY: LongInt): PGear;
function  CheckGearDrowning(var Gear: PGear): boolean;
procedure CheckCollision(Gear: PGear); inline;
procedure CheckCollisionWithLand(Gear: PGear); inline;

procedure AmmoShove(Ammo: PGear; Damage, Power: LongInt);
procedure AmmoShoveLine(Ammo: PGear; Damage, Power: LongInt; oX, oY, tX, tY: hwFloat);
function  GearsNear(X, Y: hwFloat; Kind: TGearType; r: LongInt): PGearArrayS;
procedure SpawnBoxOfSmth;
procedure ShotgunShot(Gear: PGear);
function  CanUseTardis(HHGear: PGear): boolean;

procedure SetAllToActive;
procedure SetAllHHToActive(Ice: boolean);
procedure SetAllHHToActive(); inline;

function  GetAmmo(Hedgehog: PHedgehog): TAmmoType;
function  GetUtility(Hedgehog: PHedgehog): TAmmoType;

function WorldWrap(var Gear: PGear): boolean;

function IsHogLocal(HH: PHedgehog): boolean;


function MakeHedgehogsStep(Gear: PGear) : boolean;

var doStepHandlers: array[TGearType] of TGearStepProcedure;

implementation
uses uSound, uCollisions, uUtils, uConsts, uVisualGears, uAIMisc,
    uVariables, uLandGraphics, uScript, uStats, uCaptions, uTeams, uStore,
    uLocale, uTextures, uRenderUtils, uRandom, SDLh, uDebug,
    uGearsList, Math, uVisualGearsList, uGearsHandlersMess,
    uGearsHedgehog;

procedure doMakeExplosion(X, Y, Radius: LongInt; AttackingHog: PHedgehog; Mask: Longword); inline;
begin
    doMakeExplosion(X, Y, Radius, AttackingHog, Mask, $FFFFFFFF);
end;

procedure doMakeExplosion(X, Y, Radius: LongInt; AttackingHog: PHedgehog; Mask: Longword; const Tint: LongWord);
var Gear: PGear;
    dmg, dmgBase: LongInt;
    fX, fY, tdX, tdY: hwFloat;
    vg: PVisualGear;
    i, cnt: LongInt;
    wrap: boolean;
    bubble: PVisualGear;
    s: ansistring;
begin
if Radius > 4 then AddFileLog('Explosion: at (' + inttostr(x) + ',' + inttostr(y) + ')');
if Radius > 25 then KickFlakes(Radius, X, Y);

if ((Mask and EXPLNoGfx) = 0) then
    begin
    vg:= nil;
    if CheckCoordInWater(X, Y - Radius) then
        begin
        cnt:= 2 * Radius;
        for i:= (Radius * Radius) div 4 downto 0 do
            begin
            bubble := AddVisualGear(X - Radius + random(cnt), Y - Radius + random(cnt), vgtBubble);
            if bubble <> nil then
                bubble^.dY:= 0.1 + random(20)/10;
            end
        end
    else if Radius > 50 then vg:= AddVisualGear(X, Y, vgtBigExplosion)
    else if Radius > 10 then vg:= AddVisualGear(X, Y, vgtExplosion);
    if vg <> nil then
        vg^.Tint:= Tint;
    end;
if (Mask and EXPLAutoSound) <> 0 then PlaySound(sndExplosion);

(*if (Mask and EXPLAllDamageInRadius) = 0 then
    dmgRadius:= Radius shl 1
else
    dmgRadius:= Radius;
dmgBase:= dmgRadius + cHHRadius div 2;*)
dmgBase:= Radius shl 1 + cHHRadius div 2;

// we might have to run twice if weWrap is enabled
wrap:= false;
repeat

fX:= int2hwFloat(X);
fY:= int2hwFloat(Y);
Gear:= GearsList;

while Gear <> nil do
    begin
    dmg:= 0;
    //dmg:= dmgRadius  + cHHRadius div 2 - hwRound(Distance(Gear^.X - int2hwFloat(X), Gear^.Y - int2hwFloat(Y)));
    //if (dmg > 1) and
    if (Gear^.State and gstNoDamage) = 0 then
        begin
        case Gear^.Kind of
            gtHedgehog,
                gtMine,
                gtBall,
                gtMelonPiece,
                gtGrenade,
                gtClusterBomb,
            //    gtCluster, too game breaking I think
                gtSMine,
                gtAirMine,
                gtCase,
                gtTarget,
                gtFlame,
                gtKnife,
                gtExplosives: begin //,
                //gtStructure: begin
// Run the calcs only once we know we have a type that will need damage
                        tdX:= Gear^.X-fX;
                        tdY:= Gear^.Y-fY;
                        if LongInt(tdX.Round + tdY.Round + 2) < dmgBase then
                            dmg:= dmgBase - hwRound(Distance(tdX, tdY));
                        if dmg > 1 then
                            begin
                            dmg:= ModifyDamage(min(dmg div 2, Radius), Gear);
                            //AddFileLog('Damage: ' + inttostr(dmg));
                            if (Mask and EXPLNoDamage) = 0 then
                                begin
                                if (Gear^.Kind <> gtHedgehog) or (Gear^.Hedgehog^.Effects[heInvulnerable] = 0) then
                                    ApplyDamage(Gear, AttackingHog, dmg, dsExplosion)
                                else
                                    Gear^.State:= Gear^.State or gstWinner;
                                end;
                            if ((Mask and EXPLDoNotTouchAny) = 0) and (((Mask and EXPLDoNotTouchHH) = 0) or (Gear^.Kind <> gtHedgehog)) then
                                begin
                                DeleteCI(Gear);
                                Gear^.dX:= Gear^.dX + SignAs(_0_005 * dmg + cHHKick, tdX)/(Gear^.Density/_3);
                                Gear^.dY:= Gear^.dY + SignAs(_0_005 * dmg + cHHKick, tdY)/(Gear^.Density/_3);

                                Gear^.State:= (Gear^.State or gstMoving) and (not gstLoser);
                                if Gear^.Kind = gtKnife then Gear^.State:= Gear^.State and (not gstCollision);
                                if (Gear^.Kind = gtHedgehog) and (Gear^.Hedgehog^.Effects[heInvulnerable] = 0) then
                                    Gear^.State:= (Gear^.State or gstMoving) and (not gstWinner);
                                Gear^.Active:= true;
                                if Gear^.Kind <> gtFlame then FollowGear:= Gear
                                end;
                            if ((Mask and EXPLPoisoned) <> 0) and (Gear^.Kind = gtHedgehog) and
                                (Gear^.Hedgehog^.Effects[heInvulnerable] = 0) and (Gear^.Hedgehog^.Effects[heFrozen] = 0) and
                                (Gear^.State and gstHHDeath = 0) then
                                    begin
                                    if Gear^.Hedgehog^.Effects[hePoisoned] = 0 then
                                        begin
                                        s:= ansistring(Gear^.Hedgehog^.Name);
                                        AddCaption(FormatA(GetEventString(eidPoisoned), s), capcolDefault, capgrpMessage);
                                        uStats.HedgehogPoisoned(Gear, AttackingHog)
                                        end;
                                    Gear^.Hedgehog^.Effects[hePoisoned] := 5;
                                    end
                            end;

                        end;
                gtGrave: if Mask and EXPLDoNotTouchAny = 0 then
// Run the calcs only once we know we have a type that will need damage
                            begin
                            tdX:= Gear^.X-fX;
                            tdY:= Gear^.Y-fY;
                            if LongInt(tdX.Round + tdY.Round + 2) < dmgBase then
                                dmg:= dmgBase - hwRound(Distance(tdX, tdY));
                            if dmg > 1 then
                                begin
                                dmg:= ModifyDamage(min(dmg div 2, Radius), Gear);
                                Gear^.dY:= - _0_004 * dmg;
                                Gear^.Active:= true
                                end
                            end;
            end;
        end;
    Gear:= Gear^.NextGear
    end;

if (Mask and EXPLDontDraw) = 0 then
    if ((GameFlags and gfSolidLand) = 0) or ((Mask and EXPLForceDraw) <> 0) then
        begin
        cnt:= DrawExplosion(X, Y, Radius) div 1608; // approx 2 16x16 circles to erase per chunk
        if (cnt > 0) and (SpritesData[sprChunk].Texture <> nil) then
            for i:= 0 to cnt do
                AddVisualGear(X, Y, vgtChunk)
        end;

if (WorldEdge = weWrap) then
    begin
    // already wrapped? let's not wrap again!
    if wrap then
        break;

    // Radius + 5 because that's the actual radius the explosion changes graphically
    if X + (Radius + 5) > LongInt(rightX) then
        begin
        dec(X, playWidth);
        wrap:= true;
        end
    else if X - (Radius + 5) < LongInt(leftX) then
        begin
        inc(X, playWidth);
        wrap:= true;
        end;
    end;

until (not wrap);

uAIMisc.AwareOfExplosion(0, 0, 0)
end;

function ModifyDamage(dmg: Longword; Gear: PGear): Longword;
var i: hwFloat;
begin
(* Invulnerability cannot be placed in here due to still needing kicks
   Not without a new damage machine.
   King check should be in here instead of ApplyDamage since Tiy wants them kicked less
*)
i:= _1;
if (CurrentHedgehog <> nil) and CurrentHedgehog^.King then
    i:= _1_5;
if (Gear^.Kind = gtHedgehog) and (Gear^.Hedgehog <> nil) and
   (Gear^.Hedgehog^.King or (Gear^.Hedgehog^.Effects[heFrozen] > 0)) then
    ModifyDamage:= hwRound(cDamageModifier * dmg * i * cDamagePercent * _0_5 * _0_01)
else
    ModifyDamage:= hwRound(cDamageModifier * dmg * i * cDamagePercent * _0_01);
end;

procedure ApplyDamage(Gear: PGear; AttackerHog: PHedgehog; Damage: Longword; Source: TDamageSource);
var vampDmg, tmpDmg, i: Longword;
    vg: PVisualGear;
begin
    if Damage = 0 then
        exit; // nothing to apply

    if (Gear^.Kind = gtHedgehog) then
        begin
        Gear^.LastDamage := AttackerHog;

        Gear^.Hedgehog^.Team^.Clan^.Flawless:= false;
        HHHurt(Gear^.Hedgehog, Source);
        AddDamageTag(hwRound(Gear^.X), hwRound(Gear^.Y), Damage, Gear^.Hedgehog^.Team^.Clan^.Color);
        tmpDmg:= min(Damage, max(0,Gear^.Health-Gear^.Damage));
        if (Gear <> CurrentHedgehog^.Gear) and (CurrentHedgehog^.Gear <> nil) and (tmpDmg >= 1) then
            begin
            if cVampiric then
                begin
                vampDmg:= hwRound(int2hwFloat(tmpDmg)*_0_8);
                if vampDmg >= 1 then
                    begin
                    // was considering pulsing on attack, Tiy thinks it should be permanent while in play
                    //CurrentHedgehog^.Gear^.State:= CurrentHedgehog^.Gear^.State or gstVampiric;
                    vampDmg:= IncHogHealth(CurrentHedgehog, vampDmg);
                    RenderHealth(CurrentHedgehog^);
                    RecountTeamHealth(CurrentHedgehog^.Team);
                    HHHeal(CurrentHedgehog, vampDmg, true, $FF0000FF);
                    end
                end;
            if (GameFlags and gfKarma <> 0) and (GameFlags and gfInvulnerable = 0) and
               (CurrentHedgehog^.Effects[heInvulnerable] = 0) then
                begin // this cannot just use Damage or it interrupts shotgun and gets you called stupid
                inc(CurrentHedgehog^.Gear^.Karma, tmpDmg);
                CurrentHedgehog^.Gear^.LastDamage := CurrentHedgehog;
                spawnHealthTagForHH(CurrentHedgehog^.Gear, tmpDmg);
                end;
            end;

        uStats.HedgehogDamaged(Gear, AttackerHog, Damage, false);

	if AprilOne and (Gear^.Hedgehog^.Hat = 'fr_tomato') and (Damage > 2) then
	    for i := 0 to random(min(Damage,20))+5 do
		begin
		vg:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtStraightShot);
		if vg <> nil then
		    with vg^ do
			begin
			dx:= 0.001 * (random(100)+10);
			dy:= 0.001 * (random(100)+10);
			tdy:= -cGravityf;
			if random(2) = 0 then
			    dx := -dx;
			//if random(2) = 0 then
			//    dy := -dy;
			FrameTicks:= random(500) + 1000;
			State:= ord(sprBubbles);
			//Tint:= $bd2f03ff
			Tint:= $ff0000ff
			end
	end
    end else
    //else if Gear^.Kind <> gtStructure then // not gtHedgehog nor gtStructure
        Gear^.Hedgehog:= AttackerHog;
    inc(Gear^.Damage, Damage);

    ScriptCall('onGearDamage', Gear^.UID, Damage);
end;

procedure spawnHealthTagForHH(HHGear: PGear; dmg: Longword);
var tag: PVisualGear;
begin
tag:= AddVisualGear(hwRound(HHGear^.X), hwRound(HHGear^.Y), vgtHealthTag, dmg);
if (tag <> nil) then
    tag^.Hedgehog:= HHGear^.Hedgehog; // the tag needs the tag to determine the text color
AllInactive:= false;
HHGear^.Active:= true;
end;

// Play effects for hurt hedgehog
procedure HHHurt(Hedgehog: PHedgehog; Source: TDamageSource);
begin
if Hedgehog^.Effects[heFrozen] <> 0 then exit;

if (Source = dsFall) or (Source = dsExplosion) then
    case random(3) of
        0: PlaySoundV(sndOoff1, Hedgehog^.Team^.voicepack);
        1: PlaySoundV(sndOoff2, Hedgehog^.Team^.voicepack);
        2: PlaySoundV(sndOoff3, Hedgehog^.Team^.voicepack);
    end
else if (Source = dsPoison) then
    case random(2) of
        0: PlaySoundV(sndPoisonCough, Hedgehog^.Team^.voicepack);
        1: PlaySoundV(sndPoisonMoan, Hedgehog^.Team^.voicepack);
    end
else
    case random(4) of
        0: PlaySoundV(sndOw1, Hedgehog^.Team^.voicepack);
        1: PlaySoundV(sndOw2, Hedgehog^.Team^.voicepack);
        2: PlaySoundV(sndOw3, Hedgehog^.Team^.voicepack);
        3: PlaySoundV(sndOw4, Hedgehog^.Team^.voicepack);
    end
end;

{-
Show heal particles and message at hog gear.
Hedgehog: Hedgehog which gets the health boost
healthBoost: Amount of added health added
showMessage: Whether to show announcer message
vgTint: Tint of heal particle (if 0, don't render particles)
-}
procedure HHHeal(Hedgehog: PHedgehog; healthBoost: LongInt; showMessage: boolean; vgTint: Longword);
var i: LongInt;
    vg: PVisualGear;
    s: ansistring;
begin
    if healthBoost < 1 then
        exit;

    if showMessage then
        begin
        s:= IntToStr(healthBoost);
        AddCaption(FormatA(trmsg[sidHealthGain], s), Hedgehog^.Team^.Clan^.Color, capgrpAmmoinfo)
        end;

    i:= 0;
    // One particle for every 5 HP. Max. 200 particles
    if (vgTint <> 0) then
        while (i < healthBoost) and (i < 1000) do
            begin
            vg:= AddVisualGear(hwRound(Hedgehog^.Gear^.X), hwRound(Hedgehog^.Gear^.Y), vgtStraightShot);
            if vg <> nil then
                with vg^ do
                    begin
                    Tint:= vgTint;
                    State:= ord(sprHealth)
                    end;
            inc(i, 5)
            end;
end;

// Shorthand for the same above, but with tint implied
procedure HHHeal(Hedgehog: PHedgehog; healthBoost: LongInt; showMessage: boolean);
begin
    HHHeal(Hedgehog, healthBoost, showMessage, $00FF00FF);
end;

// Increase hog health by healthBoost (at least 1).
// Resulting health is capped at cMaxHogHealth.
// Returns actual amount healed.
function IncHogHealth(Hedgehog: PHedgehog; healthBoost: LongInt): LongInt;
var oldHealth: LongInt;
begin
   if healthBoost < 1 then
       begin
       IncHogHealth:= 0;
       exit;
       end;
   oldHealth:= Hedgehog^.Gear^.Health;
   inc(Hedgehog^.Gear^.Health, healthBoost);
   // Prevent overflow
   if (Hedgehog^.Gear^.Health < 1) or (Hedgehog^.Gear^.Health > cMaxHogHealth) then
       Hedgehog^.Gear^.Health:= cMaxHogHealth;
   IncHogHealth:= Hedgehog^.Gear^.Health - oldHealth;
end;

procedure CheckHHDamage(Gear: PGear);
var
    dmg: LongInt;
    i: LongWord;
    particle: PVisualGear;
begin
if _0_4 < Gear^.dY then
    begin
    dmg := ModifyDamage(1 + hwRound((Gear^.dY - _0_4) * 70), Gear);
    if Gear^.Hedgehog^.Effects[heFrozen] = 0 then
         PlaySound(sndBump)
    else PlaySound(sndFrozenHogImpact);
    if dmg < 1 then
        exit;

    for i:= min(12, 3 + dmg div 10) downto 0 do
        begin
        particle := AddVisualGear(hwRound(Gear^.X) - 5 + Random(10), hwRound(Gear^.Y) + 12, vgtDust);
        if particle <> nil then
            particle^.dX := particle^.dX + (Gear^.dX.QWordValue / 21474836480);
        end;

    if ((Gear^.Hedgehog^.Effects[heInvulnerable] <> 0)) then
        exit;

    //if _0_6 < Gear^.dY then
    //    PlaySound(sndOw4, Gear^.Hedgehog^.Team^.voicepack)
    //else
    //    PlaySound(sndOw1, Gear^.Hedgehog^.Team^.voicepack);

    if Gear^.LastDamage <> nil then
        ApplyDamage(Gear, Gear^.LastDamage, dmg, dsFall)
    else
        ApplyDamage(Gear, CurrentHedgehog, dmg, dsFall);
    end
end;


procedure CalcRotationDirAngle(Gear: PGear);
var
    dAngle: real;
begin
    // Frac/Round to be kind to JS as of 2012-08-27 where there is yet no int64/uint64
    //dAngle := (Gear^.dX.QWordValue + Gear^.dY.QWordValue) / $80000000;
    dAngle := (Gear^.dX.Round + Gear^.dY.Round) / 2 + (Gear^.dX.Frac/$100000000+Gear^.dY.Frac/$100000000);
    if not Gear^.dX.isNegative then
        Gear^.DirAngle := Gear^.DirAngle + dAngle
    else
        Gear^.DirAngle := Gear^.DirAngle - dAngle;

    if Gear^.DirAngle < 0 then
        Gear^.DirAngle := Gear^.DirAngle + 360
    else if 360 < Gear^.DirAngle then
        Gear^.DirAngle := Gear^.DirAngle - 360
end;

procedure AddSplashForGear(Gear: PGear; justSkipping: boolean);
var x, y, i, distL, distR, distB, minDist, maxDrops: LongInt;
    splash, particle: PVisualGear;
    speed, hwTmp: hwFloat;
    vi, vs, tmp: real; // impact speed and sideways speed
    isImpactH, isImpactRight: boolean;
const dist2surf = 4;
begin
x:= hwRound(Gear^.X);
y:= hwRound(Gear^.Y);

// find position for splash and impact speed

distB:= cWaterline - y;

if WorldEdge <> weSea then
    minDist:= distB
else
    begin
    distL:= x - leftX;
    distR:= rightX - x;
    minDist:= min(distB, min(distL, distR));
    end;

isImpactH:= (minDist <> distB);

if not isImpactH then
    begin
    y:= cWaterline - dist2surf;
    speed:= hwAbs(Gear^.dY);
    end
else
    begin
    isImpactRight := minDist = distR;
    if isImpactRight then
        x:= rightX - dist2surf
    else
        x:= leftX + dist2surf;
    speed:= hwAbs(Gear^.dX);
    end;

// splash sound

if justSkipping then
    PlaySound(sndSkip)
else
    begin
    // adjust water impact sound based on gear speed and density
    hwTmp:= hwAbs(Gear^.Density * speed);

    if hwTmp > _1 then
        PlaySound(sndSplash)
    else if hwTmp > _0_5 then
        PlaySound(sndSkip)
    else if hwTmp > _0_0002 then  // arbitrary sanity cutoff.  mostly for airmines
        PlaySound(sndDroplet2);
    end;


// splash visuals

if ((cReducedQuality and rqPlainSplash) <> 0) then
    exit;

splash:= AddVisualGear(x, y, vgtSplash);
if splash = nil then
    exit;

if not isImpactH then
    vs:= abs(hwFloat2Float(Gear^.dX))
else
    begin
    if isImpactRight then
        splash^.Angle:= -90
    else
        splash^.Angle:=  90;
    vs:= abs(hwFloat2Float(Gear^.dY));
    end;


vi:= hwFloat2Float(speed);

with splash^ do
    begin
    Scale:= abs(hwFloat2Float(Gear^.Density / _3 * speed));
    if Scale > 1 then Scale:= power(Scale,0.3333)
    else Scale:= Scale + ((1-Scale) / 2);
    if Scale > 1 then Timer:= round(min(Scale*0.0005/cGravityf,4))
    else Timer:= 1;
    // Low Gravity
    FrameTicks:= FrameTicks*Timer;
    end;


// eject water drops

maxDrops := (hwRound(Gear^.Density) * 3) div 2 + round((vi + vs) * hwRound(Gear^.Density) * 6);
for i:= max(maxDrops div 3, min(32, Random(maxDrops))) downto 0 do
    begin
    if isImpactH then
        particle := AddVisualGear(x, y - 3 + Random(7), vgtDroplet)
    else
        particle := AddVisualGear(x - 3 + Random(7), y, vgtDroplet);

    if particle <> nil then
        with particle^ do
            begin
            // dX and dY were initialized to have a random value on creation (see uVisualGearsList)
            if isImpactH then
                begin
                tmp:= dX;
                if isImpactRight then
                    dX:=  dY - vi / 5
                else
                    dX:= -dy + vi / 5;
                dY:= tmp * (1 + vs / 10);
                end
            else
                begin
                dX:= dX * (1 + vs / 10);
                dY:= dY - vi / 5;
                end;

            if splash <> nil then
                begin
                if splash^.Scale > 1 then
                    begin
                    dX:= dX * power(splash^.Scale, 0.3333); // tone down the droplet height further
                    dY:= dY * power(splash^.Scale, 0.3333);
                    end
                else
                    begin
                    dX:= dX * splash^.Scale;
                    dY:= dY * splash^.Scale;
                    end;
                end;
            end
    end;

end;

procedure DrownGear(Gear: PGear);
begin
Gear^.doStep := @doStepDrowningGear;

Gear^.Timer := 5000; // how long game should wait
end;

function CheckGearDrowning(var Gear: PGear): boolean;
var
    skipSpeed, skipAngle, skipDecay: hwFloat;
    tmp, X, Y, dist2Water: LongInt;
    isSubmersible, isDirH, isImpact, isSkip: boolean;
    s: ansistring;
begin
    // probably needs tweaking. might need to be in a case statement based upon gear type
    X:= hwRound(Gear^.X);
    Y:= hwRound(Gear^.Y);

    dist2Water:= cWaterLine - (Y + Gear^.Radius);
    isDirH:= false;

    if WorldEdge = weSea then
        begin
        tmp:= dist2Water;
        dist2Water:= min(dist2Water, min(X - Gear^.Radius - LongInt(leftX), LongInt(rightX) - (X + Gear^.Radius)));
        // if water on sides is closer than on bottom -> horizontal direction
        isDirH:= tmp <> dist2Water;
        end;

    isImpact:= false;

    if dist2Water < 0 then
        begin
        // invisible gears will just be deleted
        // unless they are generic fallers, then they will be "respawned"
        if Gear^.State and gstInvisible <> 0 then
            begin
            if Gear^.Kind = gtGenericFaller then
                begin
                Gear^.X:= int2hwFloat(GetRandom(rightX-leftX)+leftX);
                Gear^.Y:= int2hwFloat(GetRandom(LAND_HEIGHT-topY)+topY);
                Gear^.dX:= _90-(GetRandomf*_360);
                Gear^.dY:= _90-(GetRandomf*_360)
                end
            else DeleteGear(Gear);
            exit(true)
            end;
        isSubmersible:= ((Gear = CurrentHedgehog^.Gear) and (CurAmmoGear <> nil) and (CurAmmoGear^.State and gstSubmersible <> 0)) or (Gear^.State and gstSubmersible <> 0);

        skipSpeed := _0_25;
        skipAngle := _1_9;
        skipDecay := _0_87;


        // skipping

        if (not isSubmersible) and (hwSqr(Gear^.dX) + hwSqr(Gear^.dY) > skipSpeed)
        and ( ((not isDirH) and (hwAbs(Gear^.dX) > skipAngle * hwAbs(Gear^.dY)))
          or (isDirH and (hwAbs(Gear^.dY) > skipAngle * hwAbs(Gear^.dX))) ) then
            begin
            isSkip:= true;
            // if skipping we move the gear out of water
            if isDirH then
                begin
                Gear^.dX.isNegative := (not Gear^.dX.isNegative);
                Gear^.X:= Gear^.X + Gear^.dX;
                end
            else
                begin
                Gear^.dY.isNegative := (not Gear^.dY.isNegative);
                Gear^.Y:= Gear^.Y + Gear^.dY;
                end;
            Gear^.dY := Gear^.dY * skipDecay;
            Gear^.dX := Gear^.dX * skipDecay;
            CheckGearDrowning := false;
            end
        else // not skipping
            begin
            isImpact:= true;
            isSkip:= false;
            if not isSubmersible then
                begin
                CheckGearDrowning := true;
                Gear^.State := gstDrowning;
                if Gear = CurrentHedgehog^.Gear then
                    TurnTimeLeft := 0;
                Gear^.RenderTimer := false;
                if (Gear^.Kind <> gtSniperRifleShot) and (Gear^.Kind <> gtShotgunShot)
                and (Gear^.Kind <> gtDEagleShot) and (Gear^.Kind <> gtSineGunShot)
                and (Gear^.Kind <> gtMinigunBullet) then
                    if Gear^.Kind = gtHedgehog then
                        begin
                        if Gear^.Hedgehog^.Effects[heResurrectable] <> 0 then
                            begin
                            // Gear could become nil after this, just exit to skip splashes
                            ResurrectHedgehog(Gear);
                            exit(true)
                            end
                        else
                            begin
                            DrownGear(Gear);
                            Gear^.State := Gear^.State and (not gstHHDriven);
                            s:= ansistring(Gear^.Hedgehog^.Name);
                            if Gear^.Hedgehog^.King then
                                AddCaption(FormatA(GetEventString(eidKingDied), s), capcolDefault, capgrpMessage)
                            else
                                AddCaption(FormatA(GetEventString(eidDrowned), s), capcolDefault, capgrpMessage);
                            end
                        end
                    else
                        DrownGear(Gear);
                    if Gear^.Kind = gtFlake then
                        exit(true); // skip splashes
                end
            else // submersible
                begin
                // drown submersible grears if far below map
                if (Y > cWaterLine + cVisibleWater*4) then
                    begin
                    DrownGear(Gear);
                    exit(true); // no splashes needed
                    end;

                CheckGearDrowning := false;

                // check if surface was penetrated

                // no penetration if center's water distance not smaller than radius
                if  ((dist2Water + Gear^.Radius div 2) < 0) or (abs(dist2Water + Gear^.Radius) >= Gear^.Radius) then
                    isImpact:= false
                else
                    begin
                    // get distance to water of last tick
                    if isDirH then
                        begin
                        tmp:= hwRound(Gear^.X - Gear^.dX);
                        if abs(tmp - real(leftX)) < abs(tmp - real(rightX)) then  // left edge
                            isImpact:= (abs(tmp-real(leftX)) >= Gear^.Radius) and (Gear^.dX.isNegative)
                        else
                            isImpact:= (abs(tmp-real(rightX)) >= Gear^.Radius) and (not Gear^.dX.isNegative);
                        end
                    else
                        begin
                        tmp:= hwRound(Gear^.Y - Gear^.dY);
                        tmp:= abs(cWaterLine - tmp);
                        // there was an impact if distance was >= radius
                        isImpact:= (tmp >= Gear^.Radius) and (not Gear^.dY.isNegative);
                        end;

                    end;
                end; // end of submersible
            end; // end of not skipping

        // splash sound animation and droplets
        if isImpact or isSkip then
            addSplashForGear(Gear, isSkip);

        if isSkip then
            ScriptCall('onGearWaterSkip', Gear^.uid);
        end
    else
        CheckGearDrowning := false
end;


procedure ResurrectHedgehog(var gear: PGear);
var tempTeam : PTeam;
    sparkles, expl: PVisualGear;
    gX, gY: LongInt;
begin
    if (Gear^.LastDamage <> nil) then
        uStats.HedgehogDamaged(Gear, Gear^.LastDamage, 0, true)
    else
        uStats.HedgehogDamaged(Gear, CurrentHedgehog, 0, true);
    // Reset gear state
    AttackBar:= 0;
    gear^.dX := _0;
    gear^.dY := _0;
    gear^.Damage := 0;
    gear^.Health := gear^.Hedgehog^.InitialHealth;
    gear^.Hedgehog^.Effects[hePoisoned] := 0;
    if (CurrentHedgehog^.Effects[heResurrectable] = 0) or ((CurrentHedgehog^.Effects[heResurrectable] <> 0)
          and (Gear^.Hedgehog^.Team^.Clan <> CurrentHedgehog^.Team^.Clan)) then
        with CurrentHedgehog^ do
            begin
            inc(Team^.stats.AIKills);
            FreeAndNilTexture(Team^.AIKillsTex);
            Team^.AIKillsTex := RenderStringTex(ansistring(inttostr(Team^.stats.AIKills)), Team^.Clan^.Color, fnt16);
            end;
    tempTeam := gear^.Hedgehog^.Team;
    DeleteCI(gear);
    gX := hwRound(gear^.X);
    gY := hwRound(gear^.Y);
    // Spawn a few sparkles at death position.
    // Might need more sparkles for a column.
    sparkles:= AddVisualGear(gX, gY, vgtDust, 1);
    if sparkles <> nil then
        begin
        sparkles^.Tint:= tempTeam^.Clan^.Color shl 8 or $FF;
        end;
    // Set new position of gear (might fail)
    FindPlace(gear, false, 0, LAND_WIDTH, true);
    if gear <> nil then
        begin
        // Visual effect at position of resurrection
        expl:= AddVisualGear(hwRound(gear^.X), hwRound(gear^.Y), vgtExplosion);
        PlaySound(sndWarp);
        RenderHealth(gear^.Hedgehog^);
        if expl <> nil then
            ScriptCall('onGearResurrect', gear^.uid, expl^.uid)
        else
            ScriptCall('onGearResurrect', gear^.uid);
        gear^.State := gstWait;
        end;
    RecountTeamHealth(tempTeam);
end;

function CountLand(x, y, r, c: LongInt; mask, antimask: LongWord): LongInt;
var i: LongInt;
    count: LongInt = 0;
begin
    if (y and LAND_HEIGHT_MASK) = 0 then
        for i:= max(x - r, 0) to min(x + r, LAND_WIDTH - 1) do
            if (Land[y, i] and mask <> 0) and (Land[y, i] and antimask = 0) then
                begin
                inc(count);
                if count = c then
                    begin
                    CountLand:= count;
                    exit
                    end;
                end;
    CountLand:= count;
end;

function isSteadyPosition(x, y, r, c: LongInt; mask: Longword): boolean;
var cnt, i: LongInt;
begin
    cnt:= 0;
    isSteadyPosition:= false;

    if ((y and LAND_HEIGHT_MASK) = 0) and (x - r >= 0) and (x + r < LAND_WIDTH) then
    begin
        for i:= r - c + 2 to r do
        begin
            if (Land[y, x - i] and mask <> 0) then inc(cnt);
            if (Land[y, x + i] and mask <> 0) then inc(cnt);

            if cnt >= c then
            begin
                isSteadyPosition:= true;
                exit
            end;
        end;
    end;
end;


function NoGearsToAvoid(mX, mY: LongInt; rX, rY: LongInt): boolean;
var t: PGear;
begin
NoGearsToAvoid:= false;
t:= GearsList;
rX:= sqr(rX);
rY:= sqr(rY);
while t <> nil do
    begin
    if t^.Kind <= gtExplosives then
        if not (hwSqr(int2hwFloat(mX) - t^.X) / rX + hwSqr(int2hwFloat(mY) - t^.Y) / rY > _1) then
            exit;
    t:= t^.NextGear
    end;
NoGearsToAvoid:= true
end;

procedure FindPlace(var Gear: PGear; withFall: boolean; Left, Right: LongInt); inline;
begin
    FindPlace(Gear, withFall, Left, Right, false);
end;

procedure FindPlace(var Gear: PGear; withFall: boolean; Left, Right: LongInt; skipProximity: boolean);
var x: LongInt;
    y, sy, dir: LongInt;
    ar: array[0..1023] of TPoint;
    ar2: array[0..2047] of TPoint;
    temp: TPoint;
    cnt, cnt2: Longword;
    delta: LongInt;
    ignoreNearObjects, ignoreOverlap, tryAgain: boolean;
begin
ignoreNearObjects:= false; // try not skipping proximity at first
ignoreOverlap:= false; // this not only skips proximity, but allows overlapping objects (barrels, mines, hogs, crates).  Saving it for a 3rd pass.  With this active, winning AI Survival goes back to virtual impossibility
tryAgain:= true;
if WorldEdge <> weNone then
    begin
    Left:= max(Left, LongInt(leftX) + Gear^.Radius);
    Right:= min(Right,rightX-Gear^.Radius)
    end;
while tryAgain do
    begin
    delta:= LAND_WIDTH div 16;
    cnt2:= 0;
    repeat
        if GetRandom(2) = 0 then dir:= -1 else dir:= 1;
        x:= max(LAND_WIDTH div 2048, LongInt(GetRandom(Delta)));
        if dir = 1 then x:= Left + x else x:= Right - x; 
        repeat
            cnt:= 0;
            y:= min(1024, topY) - Gear^.Radius shl 1;
            while y < cWaterLine do
                begin
                repeat
                    inc(y, 2);
                until (y >= cWaterLine) or
                    (ignoreOverLap and (CountLand(x, y, Gear^.Radius - 1, 1, $FF00, 0) = 0)) or
                    (not ignoreOverLap and (CountLand(x, y, Gear^.Radius - 1, 1, $FFFF, 0) = 0));


                sy:= y;

                repeat
                    inc(y);
                until (y >= cWaterLine) or
                        (ignoreOverlap and 
                                (CountLand(x, y, Gear^.Radius - 1, 1, $FFFF, 0) <> 0)) or
                        (not ignoreOverlap and 
                            (CountLand(x, y, Gear^.Radius - 1, 1, lfLandMask, 0) <> 0));

                if (y - sy > Gear^.Radius * 2) and (y < cWaterLine)
                    and (((Gear^.Kind = gtExplosives)
                        and (ignoreNearObjects or NoGearsToAvoid(x, y - Gear^.Radius, 60, 60))
                        and (isSteadyPosition(x, y+1, Gear^.Radius - 1, 3, $FFFF)
                         or (CountLand(x, y+1, Gear^.Radius - 1, Gear^.Radius+1, $FFFF, 0) > Gear^.Radius)
                            ))
                    or
                        ((Gear^.Kind <> gtExplosives)
                        and (ignoreNearObjects or NoGearsToAvoid(x, y - Gear^.Radius, 110, 110))
                        and (isSteadyPosition(x, y+1, Gear^.Radius - 1, 3, lfIce)
                         or (CountLand(x, y+1, Gear^.Radius - 1, Gear^.Radius+1, $FFFF, lfIce) <> 0)
                            ))) then
                    begin
                    ar[cnt].X:= x;
                    if withFall then
                        ar[cnt].Y:= sy + Gear^.Radius
                    else
                        ar[cnt].Y:= y - Gear^.Radius;
                    inc(cnt)
                    end;

                inc(y, 10)
                end;

            if cnt > 0 then
                begin
                temp := ar[GetRandom(cnt)];
                with temp do
                    begin
                    ar2[cnt2].x:= x;
                    ar2[cnt2].y:= y;
                    inc(cnt2)
                    end;
                end;
            inc(x, Delta*dir)
        until ((dir = 1) and (x > Right)) or ((dir = -1) and (x < Left));

        dec(Delta, 60)
    until (cnt2 > 0) or (Delta < 70);
    // if either of these has not been tried, do another pass
    if (cnt2 = 0) and skipProximity and (not ignoreOverlap) then
        tryAgain:= true
    else tryAgain:= false;
    if ignoreNearObjects then ignoreOverlap:= true;
    ignoreNearObjects:= true;
    end;

if cnt2 > 0 then
    begin
    temp := ar2[GetRandom(cnt2)];
    with temp do
        begin
        Gear^.X:= int2hwFloat(x);
        Gear^.Y:= int2hwFloat(y);
        AddFileLog('Assigned Gear coordinates (' + inttostr(x) + ',' + inttostr(y) + ')');
        end
    end
else
    begin
    OutError('Can''t find place for Gear', false);
    if Gear^.Kind = gtHedgehog then
        begin
        cnt:= 0;
        if GameTicks = 0 then
            begin
            //AddFileLog('Trying to make a hole');
            while (cnt < 1000) do
                begin
                inc(cnt);
                x:= left+GetRandom(right-left-2*cHHRadius)+cHHRadius;
                y:= topY+GetRandom(LAND_HEIGHT-topY-64)+48;
                if NoGearsToAvoid(x, y, 100 div max(1,cnt div 100), 100 div max(1,cnt div 100)) then
                    begin
                    Gear^.State:= Gear^.State or gsttmpFlag;
                    Gear^.X:= int2hwFloat(x);
                    Gear^.Y:= int2hwFloat(y);
                    AddFileLog('Picked a spot for hog at coordinates (' + inttostr(hwRound(Gear^.X)) + ',' + inttostr(hwRound(Gear^.Y)) + ')');
                    cnt:= 2000
                    end
                end;
            end;
        if cnt < 2000 then
            begin
            Gear^.Hedgehog^.Effects[heResurrectable] := 0;
            DeleteGear(Gear);
            Gear:= nil
            end
        end
    else
        begin
        DeleteGear(Gear);
        Gear:= nil
        end
    end
end;

function CheckGearNearImpl(Kind: TGearType; X, Y: hwFloat; rX, rY: LongInt; exclude: PGear): PGear;
var t: PGear;
    width, dX, dY: hwFloat;
    bound: LongInt;
    isHit: Boolean;
begin
    t:= GearsList;
    bound:= _1_5 * int2hwFloat(max(rX, rY));
    rX:= sqr(rX);
    rY:= sqr(rY);
    width:= int2hwFloat(RightX - LeftX);

    while t <> nil do
    begin
        if (t <> exclude) and (t^.Kind = Kind) then
        begin
            dX := X - t^.X;
            dY := Y - t^.Y;
            isHit := (hwAbs(dX) + hwAbs(dY) < bound)
                and (not ((hwSqr(dX) / rX + hwSqr(dY) / rY) > _1));

            if (not isHit) and (WorldEdge = weWrap) then
            begin
                if (hwAbs(dX - width) + hwAbs(dY) < bound)
                    and (not ((hwSqr(dX - width) / rX + hwSqr(dY) / rY) > _1)) then
                    isHit := true
                else if (hwAbs(dX + width) + hwAbs(dY) < bound)
                    and (not ((hwSqr(dX + width) / rX + hwSqr(dY) / rY) > _1)) then
                    isHit := true
            end;

            if isHit then
            begin
                CheckGearNear:= t;
                exit;
            end;
        end;
        t:= t^.NextGear
    end;

    CheckGearNear:= nil
end;

function CheckGearNear(Kind: TGearType; X, Y: hwFloat; rX, rY: LongInt): PGear;
begin
    CheckGearNear := CheckGearNearImpl(Kind, X, Y, rX, rY, nil);
end;

function CheckGearNear(Gear: PGear; Kind: TGearType; rX, rY: LongInt): PGear;
begin
    CheckGearNear := CheckGearNearImpl(Kind, Gear^.X, Gear^.Y, rX, rY, Gear);
end;

procedure CheckCollision(Gear: PGear); inline;
begin
    if (TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) <> 0)
    or (TestCollisionYwithGear(Gear, hwSign(Gear^.dY)) <> 0) then
        Gear^.State := Gear^.State or gstCollision
    else
        Gear^.State := Gear^.State and (not gstCollision)
end;

procedure CheckCollisionWithLand(Gear: PGear); inline;
begin
    if (TestCollisionX(Gear, hwSign(Gear^.dX)) <> 0)
    or (TestCollisionY(Gear, hwSign(Gear^.dY)) <> 0) then
        Gear^.State := Gear^.State or gstCollision
    else
        Gear^.State := Gear^.State and (not gstCollision)
end;

function MakeHedgehogsStep(Gear: PGear) : boolean;
begin
    if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) <> 0 then if (TestCollisionYwithGear(Gear, -1) = 0) then
        begin
        Gear^.Y:= Gear^.Y - _1;
    if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) <> 0 then if (TestCollisionYwithGear(Gear, -1) = 0) then
        begin
        Gear^.Y:= Gear^.Y - _1;
    if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) <> 0 then if (TestCollisionYwithGear(Gear, -1) = 0) then
        begin
        Gear^.Y:= Gear^.Y - _1;
    if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) <> 0 then if (TestCollisionYwithGear(Gear, -1) = 0) then
        begin
        Gear^.Y:= Gear^.Y - _1;
    if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) <> 0 then if (TestCollisionYwithGear(Gear, -1) = 0) then
        begin
        Gear^.Y:= Gear^.Y - _1;
    if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) <> 0 then if (TestCollisionYwithGear(Gear, -1) = 0) then
        begin
        Gear^.Y:= Gear^.Y - _1;
        if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) <> 0 then
            Gear^.Y:= Gear^.Y + _6
        end else Gear^.Y:= Gear^.Y + _5 else
        end else Gear^.Y:= Gear^.Y + _4 else
        end else Gear^.Y:= Gear^.Y + _3 else
        end else Gear^.Y:= Gear^.Y + _2 else
        end else Gear^.Y:= Gear^.Y + _1
        end;

    if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) = 0 then
        begin
        Gear^.X:= Gear^.X + SignAs(_1, Gear^.dX);
        MakeHedgehogsStep:= true
        end else
        MakeHedgehogsStep:= false;

    if TestCollisionYwithGear(Gear, 1) = 0 then
        begin
        Gear^.Y:= Gear^.Y + _1;
    if TestCollisionYwithGear(Gear, 1) = 0 then
        begin
        Gear^.Y:= Gear^.Y + _1;
    if TestCollisionYwithGear(Gear, 1) = 0 then
        begin
        Gear^.Y:= Gear^.Y + _1;
    if TestCollisionYwithGear(Gear, 1) = 0 then
        begin
        Gear^.Y:= Gear^.Y + _1;
    if TestCollisionYwithGear(Gear, 1) = 0 then
        begin
        Gear^.Y:= Gear^.Y + _1;
    if TestCollisionYwithGear(Gear, 1) = 0 then
        begin
        Gear^.Y:= Gear^.Y + _1;
    if TestCollisionYwithGear(Gear, 1) = 0 then
        begin
        Gear^.Y:= Gear^.Y - _6;
        Gear^.dY:= _0;
        Gear^.State:= Gear^.State or gstMoving;
        exit
        end;
        end
        end
        end
        end
        end
        end;
end;


procedure ShotgunShot(Gear: PGear);
var t: PGear;
    dmg, r, dist: LongInt;
    dx, dy: hwFloat;
begin
Gear^.Radius:= cShotgunRadius;
t:= GearsList;
while t <> nil do
    begin
    case t^.Kind of
        gtHedgehog,
            gtMine,
            gtSMine,
            gtAirMine,
            gtKnife,
            gtCase,
            gtTarget,
            gtExplosives: begin//,
//            gtStructure: begin
//addFileLog('ShotgunShot radius: ' + inttostr(Gear^.Radius) + ', t^.Radius = ' + inttostr(t^.Radius) + ', distance = ' + inttostr(dist) + ', dmg = ' + inttostr(dmg));
                    dmg:= 0;
                    r:= Gear^.Radius + t^.Radius;
                    dx:= Gear^.X-t^.X;
                    dx.isNegative:= false;
                    dy:= Gear^.Y-t^.Y;
                    dy.isNegative:= false;
                    if r-hwRound(dx+dy) > 0 then
                        begin
                        dist:= hwRound(Distance(dx, dy));
                        dmg:= ModifyDamage(min(r - dist, Gear^.Boom), t);
                        end;
                    if dmg > 0 then
                        begin
                        if (t^.Kind <> gtHedgehog) or (t^.Hedgehog^.Effects[heInvulnerable] = 0) then
                            ApplyDamage(t, Gear^.Hedgehog, dmg, dsBullet)
                        else
                            Gear^.State:= Gear^.State or gstWinner;

                        DeleteCI(t);
                        t^.dX:= t^.dX + Gear^.dX * dmg * _0_01 + SignAs(cHHKick, Gear^.dX);
                        t^.dY:= t^.dY + Gear^.dY * dmg * _0_01;
                        t^.State:= t^.State or gstMoving;
                        if t^.Kind = gtKnife then t^.State:= t^.State and (not gstCollision);
                        t^.Active:= true;
                        FollowGear:= t
                        end
                    end;
            gtGrave: begin
                    dmg:= 0;
                    r:= Gear^.Radius + t^.Radius;
                    dx:= Gear^.X-t^.X;
                    dx.isNegative:= false;
                    dy:= Gear^.Y-t^.Y;
                    dy.isNegative:= false;
                    if r-hwRound(dx+dy) > 0 then
                        begin
                        dist:= hwRound(Distance(dx, dy));
                        dmg:= ModifyDamage(min(r - dist, Gear^.Boom), t);
                        end;
                    if dmg > 0 then
                        begin
                        t^.dY:= - _0_1;
                        t^.Active:= true
                        end
                    end;
        end;
    t:= t^.NextGear
    end;
if (GameFlags and gfSolidLand) = 0 then
    DrawExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), cShotgunRadius)
end;

// Returns true if the given hog gear can use the tardis
function CanUseTardis(HHGear: PGear): boolean;
var usable: boolean;
    i, j, cnt: LongInt;
    HH: PHedgehog;
begin
(*
    Conditions for not activating.
    1. Hog is last of his clan
    2. Sudden Death is in play
    3. Hog is a king
*)
    usable:= true;
    HH:= HHGear^.Hedgehog;
    if HHGear <> nil then
    if (HHGear = nil) or (HH^.King) or (SuddenDeathActive) then
        usable:= false;
    cnt:= 0;
    for j:= 0 to Pred(HH^.Team^.Clan^.TeamsNumber) do
        for i:= 0 to Pred(HH^.Team^.Clan^.Teams[j]^.HedgehogsNumber) do
            if (HH^.Team^.Clan^.Teams[j]^.Hedgehogs[i].Gear <> nil)
            and ((HH^.Team^.Clan^.Teams[j]^.Hedgehogs[i].Gear^.State and gstDrowning) = 0)
            and (HH^.Team^.Clan^.Teams[j]^.Hedgehogs[i].Gear^.Health > HH^.Team^.Clan^.Teams[j]^.Hedgehogs[i].Gear^.Damage) then
                inc(cnt);
    if (cnt < 2) then
        usable:= false;
    CanUseTardis:= usable;
end;

procedure AmmoShoveImpl(Ammo: PGear; Damage, Power: LongInt; collisions: PGearArray);
var t: PGearArray;
    Gear: PGear;
    i, j, tmpDmg: LongInt;
    VGear: PVisualGear;
begin
t:= collisions;

// Just to avoid hogs on rope dodging fire.
if (CurAmmoGear <> nil) and ((CurAmmoGear^.Kind = gtRope) or (CurAmmoGear^.Kind = gtJetpack) or (CurAmmoGear^.Kind = gtBirdy))
and (CurrentHedgehog^.Gear <> nil) and (CurrentHedgehog^.Gear^.CollisionIndex = -1)
and (sqr(hwRound(Ammo^.X) - hwRound(CurrentHedgehog^.Gear^.X)) + sqr(hwRound(Ammo^.Y) - hwRound(CurrentHedgehog^.Gear^.Y)) <= sqr(cHHRadius + Ammo^.Radius)) then
    begin
    t^.ar[t^.Count]:= CurrentHedgehog^.Gear;
    inc(t^.Count)
    end;

i:= t^.Count;

if (Ammo^.Kind = gtFlame) and (i > 0) then
    Ammo^.Health:= 0;
while i > 0 do
    begin
    dec(i);
    Gear:= t^.ar[i];
    if (Ammo^.Kind in [gtDEagleShot, gtSniperRifleShot, gtMinigunBullet])
        and (((Ammo^.Data <> nil) and (PGear(Ammo^.Data) = Gear))
             or (not UpdateHitOrder(Gear, Ammo^.WDTimer))) then
        continue;

    if ((Ammo^.Kind = gtFlame) or (Ammo^.Kind = gtBlowTorch)) and
    (Gear^.Kind = gtHedgehog) and (Gear^.Hedgehog^.Effects[heFrozen] > 255) then
        Gear^.Hedgehog^.Effects[heFrozen]:= max(255,Gear^.Hedgehog^.Effects[heFrozen]-10000);
    tmpDmg:= ModifyDamage(Damage, Gear);
    if (Gear^.State and gstNoDamage) = 0 then
        begin

        if (Gear^.Kind = gtHedgehog) and (Ammo^.State and gsttmpFlag <> 0) and (Ammo^.Kind = gtShover) then
            Gear^.FlightTime:= 1;

        case Gear^.Kind of
            gtHedgehog,
            gtMine,
            gtAirMine,
            gtSMine,
            gtKnife,
            gtTarget,
            gtCase,
            gtExplosives: //,
            //gtStructure:
            begin
            if Ammo^.Kind in [gtDEagleShot, gtSniperRifleShot, gtMinigunBullet] then
                begin
                VGear := AddVisualGear(t^.cX[i], t^.cY[i], vgtBulletHit);
                if VGear <> nil then
                    VGear^.Angle := DxDy2Angle(-Ammo^.dX, Ammo^.dY);
                end;
            if (Ammo^.Kind = gtDrill) then
                begin
                Ammo^.Timer:= 0;
                exit;
                end;
            if (Gear^.Kind <> gtHedgehog) or (Gear^.Hedgehog^.Effects[heInvulnerable] = 0) then
                begin
                if (Ammo^.Kind = gtKnife) and (tmpDmg > 0) then
                    for j:= 1 to max(1,min(3,tmpDmg div 5)) do
                        begin
                        VGear:= AddVisualGear(
                            t^.cX[i] - ((t^.cX[i] - hwround(Gear^.X)) div 2),
                            t^.cY[i] - ((t^.cY[i] - hwround(Gear^.Y)) div 2),
                            vgtStraightShot);
                        if VGear <> nil then
                            with VGear^ do
                                begin
                                Tint:= $FFCC00FF;
                                Angle:= random(360);
                                dx:= 0.0005 * (random(100));
                                dy:= 0.0005 * (random(100));
                                if random(2) = 0 then
                                    dx := -dx;
                                if random(2) = 0 then
                                    dy := -dy;
                                FrameTicks:= 600+random(200);
                                State:= ord(sprStar)
                                end
                        end;
                ApplyDamage(Gear, Ammo^.Hedgehog, tmpDmg, dsShove)
                end
            else
                Gear^.State:= Gear^.State or gstWinner;
            if (Gear^.Kind = gtExplosives) and (Ammo^.Kind = gtBlowtorch) then
                begin
                if (Ammo^.Hedgehog^.Gear <> nil) then
                    Ammo^.Hedgehog^.Gear^.State:= Ammo^.Hedgehog^.Gear^.State and (not gstNotKickable);
                ApplyDamage(Gear, Ammo^.Hedgehog, tmpDmg * 100, dsUnknown); // crank up damage for explosives + blowtorch
                end;

            if (Gear^.Kind = gtHedgehog) and (Gear^.Hedgehog^.King or (Gear^.Hedgehog^.Effects[heFrozen] > 0)) then
                begin
                Gear^.dX:= Ammo^.dX * Power * _0_005;
                Gear^.dY:= Ammo^.dY * Power * _0_005
                end
            else if ((Ammo^.Kind <> gtFlame) or (Gear^.Kind = gtHedgehog)) and (Power <> 0) then
                begin
                Gear^.dX:= Ammo^.dX * Power * _0_01;
                Gear^.dY:= Ammo^.dY * Power * _0_01
                end;

            if (not isZero(Gear^.dX)) or (not isZero(Gear^.dY)) then
                begin
                Gear^.Active:= true;
                DeleteCI(Gear);
                Gear^.State:= Gear^.State or gstMoving;
                if Gear^.Kind = gtKnife then Gear^.State:= Gear^.State and (not gstCollision);
                // move the gear upwards a bit to throw it over tiny obstacles at start
                if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) <> 0 then
                    begin
                    if (TestCollisionXwithXYShift(Gear, _0, -3, hwSign(Gear^.dX)) = 0) and
                       (TestCollisionYwithGear(Gear, -1) = 0) then
                        Gear^.Y:= Gear^.Y - _1;
                    if (TestCollisionXwithXYShift(Gear, _0, -2, hwSign(Gear^.dX)) = 0) and
                       (TestCollisionYwithGear(Gear, -1) = 0) then
                        Gear^.Y:= Gear^.Y - _1;
                    if (TestCollisionXwithXYShift(Gear, _0, -1, hwSign(Gear^.dX)) = 0) and
                       (TestCollisionYwithGear(Gear, -1) = 0) then
                        Gear^.Y:= Gear^.Y - _1;
                    end
                end;


            if (Ammo^.Kind <> gtFlame) or ((Ammo^.State and gsttmpFlag) = 0) then
                FollowGear:= Gear
            end;
        end
        end;
    end;
if i <> 0 then
    SetAllToActive
end;

procedure AmmoShoveLine(Ammo: PGear; Damage, Power: LongInt; oX, oY, tX, tY: hwFloat);
var t: PGearArray;
begin
    t:= CheckAllGearsLineCollision(Ammo, oX, oY, tX, tY);
    AmmoShoveImpl(Ammo, Damage, Power, t);
end;

procedure AmmoShove(Ammo: PGear; Damage, Power: LongInt);
begin
    AmmoShoveImpl(Ammo, Damage, Power,
        CheckGearsCollision(Ammo));
end;


function CountGears(Kind: TGearType): Longword;
var t: PGear;
    count: Longword = 0;
begin

t:= GearsList;
while t <> nil do
    begin
    if t^.Kind = Kind then
        inc(count);
    t:= t^.NextGear
    end;
CountGears:= count;
end;

procedure SetAllToActive;
var t: PGear;
begin
AllInactive:= false;
t:= GearsList;
while t <> nil do
    begin
    t^.Active:= true;
    t:= t^.NextGear
    end
end;

procedure SetAllHHToActive; inline;
begin
SetAllHHToActive(true)
end;


procedure SetAllHHToActive(Ice: boolean);
var t: PGear;
begin
AllInactive:= false;
t:= GearsList;
while t <> nil do
    begin
    if (t^.Kind = gtHedgehog) or (t^.Kind = gtExplosives) then
        begin
        if (t^.Kind = gtHedgehog) and Ice then CheckIce(t);
        t^.Active:= true
        end;
    t:= t^.NextGear
    end
end;


var GearsNearArray : TPGearArray;
function GearsNear(X, Y: hwFloat; Kind: TGearType; r: LongInt): PGearArrayS;
var
    t: PGear;
    s: Longword;
    xc, xc_left, xc_right, yc: hwFloat;
begin
    r:= r*r;
    s:= 0;
    SetLength(GearsNearArray, s);
    t := GearsList;
    while t <> nil do
        begin
            xc:= (X - t^.X)*(X - t^.X);
            xc_left:= ((X - int2hwFloat(RightX-LeftX)) - t^.X)*((X - int2hwFloat(RightX-LeftX)) - t^.X);
            xc_right := ((X + int2hwFloat(RightX-LeftX)) - t^.X)*((X + int2hwFloat(RightX-LeftX)) - t^.X);
            yc:= (Y - t^.Y)*(Y - t^.Y);
            if (t^.Kind = Kind)
                and ((xc + yc < int2hwFloat(r))
                or ((WorldEdge = weWrap) and
                ((xc_left + yc < int2hwFloat(r)) or
                (xc_right + yc < int2hwFloat(r))))) then
                begin
                inc(s);
                SetLength(GearsNearArray, s);
                GearsNearArray[s - 1] := t;
                end;
            t := t^.NextGear;
        end;

    GearsNear.size:= s;
    GearsNear.ar:= @GearsNearArray
end;

procedure SpawnBoxOfSmth;
var t, aTot, uTot, a, h: LongInt;
    i: TAmmoType;
begin
if (PlacingHogs) or
    (cCaseFactor = 0)
    or (CountGears(gtCase) >= cMaxCaseDrops)
    or (GetRandom(cCaseFactor) <> 0) then
       exit;

FollowGear:= nil;
aTot:= 0;
uTot:= 0;
for i:= Low(TAmmoType) to High(TAmmoType) do
    if (Ammoz[i].Ammo.Propz and ammoprop_Utility) = 0 then
        inc(aTot, Ammoz[i].Probability)
    else
        inc(uTot, Ammoz[i].Probability);

t:=0;
a:=aTot;
h:= 1;

if (aTot+uTot) <> 0 then
    if ((GameFlags and gfInvulnerable) = 0) then
        begin
        h:= cHealthCaseProb * 100;
        t:= GetRandom(10000);
        a:= (10000-h)*aTot div (aTot+uTot)
        end
    else
        begin
        t:= GetRandom(aTot+uTot);
        h:= 0
        end;


if t<h then
    begin
    FollowGear:= AddGear(0, 0, gtCase, 0, _0, _0, 0);
    FollowGear^.Health:= cHealthCaseAmount;
    FollowGear^.Pos:= posCaseHealth;
    // health crate is smaller than the other crates
    FollowGear^.Radius := cCaseHealthRadius;
    AddCaption(GetEventString(eidNewHealthPack), capcolDefault, capgrpAmmoInfo);
    end
else if (t<a+h) then
    begin
    t:= aTot;
    if (t > 0) then
        begin
        FollowGear:= AddGear(0, 0, gtCase, 0, _0, _0, 0);
        t:= GetRandom(t);
        i:= Low(TAmmoType);
        FollowGear^.Pos:= posCaseAmmo;
        FollowGear^.AmmoType:= i;
        AddCaption(GetEventString(eidNewAmmoPack), capcolDefault, capgrpAmmoInfo);
        end
    end
else
    begin
    t:= uTot;
    if (t > 0) then
        begin
        FollowGear:= AddGear(0, 0, gtCase, 0, _0, _0, 0);
        t:= GetRandom(t);
        i:= Low(TAmmoType);
        FollowGear^.Pos:= posCaseUtility;
        FollowGear^.AmmoType:= i;
        AddCaption(GetEventString(eidNewUtilityPack), capcolDefault, capgrpAmmoInfo);
        end
    end;

// handles case of no ammo or utility crates - considered also placing booleans in uAmmos and altering probabilities
if (FollowGear <> nil) then
    begin
    FindPlace(FollowGear, true, 0, LAND_WIDTH);

    if (FollowGear <> nil) then
        AddVoice(sndReinforce, CurrentTeam^.voicepack)
    end
end;


function GetAmmo(Hedgehog: PHedgehog): TAmmoType;
var t, aTot: LongInt;
    i: TAmmoType;
begin
Hedgehog:= Hedgehog; // avoid hint

aTot:= 0;
for i:= Low(TAmmoType) to High(TAmmoType) do
    if (Ammoz[i].Ammo.Propz and ammoprop_Utility) = 0 then
        inc(aTot, Ammoz[i].Probability);

t:= aTot;
i:= Low(TAmmoType);
if (t > 0) then
    begin
    t:= GetRandom(t);
    while t >= 0 do
        begin
        inc(i);
        if (Ammoz[i].Ammo.Propz and ammoprop_Utility) = 0 then
            dec(t, Ammoz[i].Probability)
        end
    end;
GetAmmo:= i
end;

function GetUtility(Hedgehog: PHedgehog): TAmmoType;
var t, uTot: LongInt;
    i: TAmmoType;
begin

uTot:= 0;
for i:= Low(TAmmoType) to High(TAmmoType) do
    if ((Ammoz[i].Ammo.Propz and ammoprop_Utility) <> 0)
    and ((Hedgehog^.Team^.HedgehogsNumber > 1) or (Ammoz[i].Ammo.AmmoType <> amSwitch)) then
        inc(uTot, Ammoz[i].Probability);

t:= uTot;
i:= Low(TAmmoType);
if (t > 0) then
    begin
    t:= GetRandom(t);
    while t >= 0 do
        begin
        inc(i);
        if ((Ammoz[i].Ammo.Propz and ammoprop_Utility) <> 0) and ((Hedgehog^.Team^.HedgehogsNumber > 1)
        or (Ammoz[i].Ammo.AmmoType <> amSwitch)) then
            dec(t, Ammoz[i].Probability)
        end
    end;
GetUtility:= i
end;

(*
Intended to check Gear X/Y against the map left/right edges and apply one of the world modes
* Normal - infinite world, do nothing
* Wrap (entering left edge exits at same height on right edge)
* Bounce (striking edge is treated as a 100% elasticity bounce)
* From the depths (same as from sky, but from sea, with submersible flag set)

Trying to make the checks a little broader than on first pass to catch things that don't move normally.
*)
function WorldWrap(var Gear: PGear): boolean;
//var tdx: hwFloat;
begin
WorldWrap:= false;
if WorldEdge = weNone then exit(false);
if (hwRound(Gear^.X) < LongInt(leftX)) or
   (hwRound(Gear^.X) > LongInt(rightX)) then
    begin
    if WorldEdge = weWrap then
        begin
        if (hwRound(Gear^.X) < LongInt(leftX)) then
             Gear^.X:= Gear^.X + int2hwfloat(rightX - leftX)
        else Gear^.X:= Gear^.X - int2hwfloat(rightX - leftX);
        LeftImpactTimer:= 150;
        RightImpactTimer:= 150
        end
    else if WorldEdge = weBounce then
        begin
        if (hwRound(Gear^.X) - Gear^.Radius < LongInt(leftX)) then
            begin
            LeftImpactTimer:= 333;
            Gear^.dX.isNegative:= false;
            Gear^.X:= int2hwfloat(LongInt(leftX) + Gear^.Radius)
            end
        else
            begin
            RightImpactTimer:= 333;
            Gear^.dX.isNegative:= true;
            Gear^.X:= int2hwfloat(rightX-Gear^.Radius)
            end;
        if (Gear^.Radius > 2) and (Gear^.dX.QWordValue > _0_001.QWordValue) then
            AddBounceEffectForGear(Gear);
        end{
    else if WorldEdge = weSea then
        begin
        if (hwRound(Gear^.Y) > cWaterLine) and (Gear^.State and gstSubmersible <> 0) then
            Gear^.State:= Gear^.State and (not gstSubmersible)
        else
            begin
            Gear^.State:= Gear^.State or gstSubmersible;
            Gear^.X:= int2hwFloat(PlayWidth)*int2hwFloat(min(max(0,hwRound(Gear^.Y)),PlayHeight))/PlayHeight;
            Gear^.Y:= int2hwFloat(cWaterLine+cVisibleWater+Gear^.Radius*2);
            tdx:= Gear^.dX;
            Gear^.dX:= -Gear^.dY;
            Gear^.dY:= tdx;
            Gear^.dY.isNegative:= true
            end
        end};
(*
* Window in the sky (Gear moved high into the sky, Y is used to determine X) [unfortunately, not a safe thing to do. shame, I thought aerial bombardment would be kinda neat
This one would be really easy to freeze game unless it was flagged unfortunately.

    else
        begin
        Gear^.X:= int2hwFloat(PlayWidth)*int2hwFloat(min(max(0,hwRound(Gear^.Y)),PlayHeight))/PlayHeight;
        Gear^.Y:= -_2048-_256-_256;
        tdx:= Gear^.dX;
        Gear^.dX:= Gear^.dY;
        Gear^.dY:= tdx;
        Gear^.dY.isNegative:= false
        end
*)
    WorldWrap:= true
    end;
end;


// Add an audiovisual bounce effect for gear after it bounced from bouncy material.
// Graphical effect is based on speed.
procedure AddBounceEffectForGear(Gear: PGear);
begin
    AddBounceEffectForGear(Gear, hwFloat2Float(Gear^.Density * hwAbs(Gear^.dY) + hwAbs(Gear^.dX)) / 1.5);
end;

// Same as above, but can specify the size of bounce image with imageScale manually.
procedure AddBounceEffectForGear(Gear: PGear; imageScale: Single);
var boing: PVisualGear;
begin
    if Gear^.Density < _0_01 then
        exit;
    boing:= AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtStraightShot, 0, false, 1);
    if boing <> nil then
        with boing^ do
            begin
            Angle:= random(360);
            dx:= 0;
            dy:= 0;
            FrameTicks:= 200;
            Scale:= imageScale;
            State:= ord(sprBoing)
            end;
    PlaySound(sndMelonImpact, true)
end;

function IsHogLocal(HH: PHedgehog): boolean;
begin
    IsHogLocal:= (not (HH^.Team^.ExtDriven or (HH^.BotLevel > 0))) or (HH^.Team^.Clan^.ClanIndex = LocalClan) or (GameType = gmtDemo);
end;

end.
