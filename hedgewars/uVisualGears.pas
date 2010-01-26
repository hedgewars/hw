(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2008 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 *)

{$INCLUDE "options.inc"}

unit uVisualGears;
interface
uses SDLh, uConsts, uFloat,
{$IFDEF GLES11}
	gles11;
{$ELSE}
	GL;
{$ENDIF}

type PVisualGear = ^TVisualGear;
	TVGearStepProcedure = procedure (Gear: PVisualGear; Steps: Longword);
	TVisualGear = record
		NextGear, PrevGear: PVisualGear;
		Frame,
		FrameTicks: Longword;
		X : hwFloat;
		Y : hwFloat;
		dX: hwFloat;
		dY: hwFloat;
		mdY: QWord;
		Timer: Longword;
		Angle, dAngle: real;
		Kind: TVisualGearType;
		doStep: TVGearStepProcedure;
		Tex: PTexture;
        Hedgehog: pointer;
        Text: shortstring
		end;

procedure init_uVisualGears;
procedure free_uVisualGears;
function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType): PVisualGear;
procedure ProcessVisualGears(Steps: Longword);
procedure DrawVisualGears(Layer: LongWord);
procedure DeleteVisualGear(Gear: PVisualGear);
procedure AddClouds;
procedure AddDamageTag(X, Y, Damage, Color: LongWord);

var VisualGearsList: PVisualGear;
    vobFrameTicks, vobFramesCount: Longword;
    vobVelocity, vobFallSpeed: LongInt;

implementation
uses uWorld, uMisc, uStore, uTeams, uSound;
const cExplFrameTicks = 110;

procedure AddDamageTag(X, Y, Damage, Color: LongWord);
var s: shortstring;
	Gear: PVisualGear;
begin
if cAltDamage then
	begin
	Gear:= AddVisualGear(X, Y, vgtSmallDamageTag);
	if Gear <> nil then
		with Gear^ do
			begin
			str(Damage, s);
			Tex:= RenderStringTex(s, Color, fntSmall);
			end
	end
end;


// ==================================================================
procedure doStepFlake(Gear: PVisualGear; Steps: Longword);
begin
with Gear^ do
	begin
	inc(FrameTicks, Steps);
	if FrameTicks > vobFrameTicks then
		begin
		dec(FrameTicks, vobFrameTicks);
		inc(Frame);
		if Frame = vobFramesCount then Frame:= 0
		end
	end;

Gear^.X:= Gear^.X + (cWindSpeed * 200 + Gear^.dX) * Steps;
Gear^.Y:= Gear^.Y + (Gear^.dY + cGravity * vobFallSpeed) * Steps;
Gear^.Angle:= Gear^.Angle + Gear^.dAngle * Steps;

if hwRound(Gear^.X) < -cScreenWidth - 64 then Gear^.X:= int2hwFloat(cScreenWidth + LAND_WIDTH) else
if hwRound(Gear^.X) > cScreenWidth + LAND_WIDTH then Gear^.X:= int2hwFloat(-cScreenWidth - 64);
// if hwRound(Gear^.Y) < (LAND_HEIGHT - 1024 - 75) then Gear^.Y:= Gear^.Y + int2hwFloat(25); // For if flag is set for flakes rising upwards?
if hwRound(Gear^.Y) > (LAND_HEIGHT + 75) then Gear^.Y:= Gear^.Y - int2hwFloat(1024 + 150) // TODO - configure in theme (jellies for example could use limited range)
end;

procedure doStepCloud(Gear: PVisualGear; Steps: Longword);
var i: Longword;
begin
Gear^.X:= Gear^.X + (cWindSpeed * 200 + Gear^.dX) * Steps;

for i:= 0 to Steps - 1 do
	begin
	if hwRound(Gear^.Y) > LAND_HEIGHT-1184 then // TODO - configure in theme
		Gear^.dY:= Gear^.dY - _1div50000
	else
		Gear^.dY:= Gear^.dY + _1div50000;

	Gear^.Y:= Gear^.Y + Gear^.dY
	end;

if hwRound(Gear^.X) < -cScreenWidth - 256 then Gear^.X:= int2hwFloat(cScreenWidth + LAND_WIDTH) else
if hwRound(Gear^.X) > cScreenWidth + LAND_WIDTH then Gear^.X:= int2hwFloat(-cScreenWidth - 256)
end;

procedure doStepExpl(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
//Gear^.dY:= Gear^.dY + cGravity;

if Gear^.FrameTicks <= Steps then
	if Gear^.Frame = 0 then DeleteVisualGear(Gear)
	else
		begin
		dec(Gear^.Frame);
		Gear^.FrameTicks:= cExplFrameTicks
		end
	else dec(Gear^.FrameTicks, Steps)
end;

procedure doStepFire(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;// + cGravity * (Steps * Steps);
Gear^.dY:= Gear^.dY + cGravity * Steps;

if Gear^.FrameTicks <= Steps then
       DeleteVisualGear(Gear)
else
	dec(Gear^.FrameTicks, Steps)
end;

procedure doStepSmallDamage(Gear: PVisualGear; Steps: Longword);
begin
Gear^.Y:= Gear^.Y - _0_02 * Steps;

if Gear^.FrameTicks <= Steps then
	DeleteVisualGear(Gear)
else
	dec(Gear^.FrameTicks, Steps)
end;

procedure doStepBubble(Gear: PVisualGear; Steps: Longword);
begin
	Gear^.X:= Gear^.X + (cWindSpeed * 100 + Gear^.dX) * Steps;
	Gear^.Y:= Gear^.Y - cDrownSpeed * Steps;

	if (Gear^.FrameTicks <= Steps) or (hwRound(Gear^.Y) < cWaterLine) then
		DeleteVisualGear(Gear)
	else
		dec(Gear^.FrameTicks, Steps)
end;

procedure doStepHealth(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;
Gear^.Y:= Gear^.Y - Gear^.dY * Steps;

if Gear^.FrameTicks <= Steps then
	DeleteVisualGear(Gear)
else
	dec(Gear^.FrameTicks, Steps);
end;

procedure doStepSteam(Gear: PVisualGear; Steps: Longword);
begin
	Gear^.X:= Gear^.X + (cWindSpeed * 100 + Gear^.dX) * Steps;
	Gear^.Y:= Gear^.Y - cDrownSpeed * Steps;

	if Gear^.FrameTicks <= Steps then
		if Gear^.Frame = 0 then DeleteVisualGear(Gear)
		else
			begin
			if Random(2) = 0 then dec(Gear^.Frame);
			Gear^.FrameTicks:= cExplFrameTicks
			end
		else dec(Gear^.FrameTicks, Steps)
end;

procedure doStepSmoke(Gear: PVisualGear; Steps: Longword);
begin
	Gear^.X:= Gear^.X + (cWindSpeed + Gear^.dX) * Steps;
	Gear^.Y:= Gear^.Y - (cDrownSpeed + Gear^.dY) * Steps;

	Gear^.dX := Gear^.dX + (cWindSpeed * _0_3 * Steps);
	//Gear^.dY := Gear^.dY - (cDrownSpeed * _0_995);

	if Gear^.FrameTicks <= Steps then
		if Gear^.Frame = 0 then DeleteVisualGear(Gear)
		else
			begin
			if Random(2) = 0 then dec(Gear^.Frame);
			Gear^.FrameTicks:= cExplFrameTicks
			end
		else dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
const cSorterWorkTime = 640;
var thexchar: array[0..cMaxTeams] of
			record
			dy, ny, dw: LongInt;
			team: PTeam;
			SortFactor: QWord;
			end;
    currsorter: PVisualGear = nil;

procedure doStepTeamHealthSorterWork(Gear: PVisualGear; Steps: Longword);
var i, t: LongInt;
begin
for t:= 1 to Steps do
	begin
	dec(Gear^.Timer);
	if (Gear^.Timer and 15) = 0 then
		for i:= 0 to Pred(TeamsCount) do
			with thexchar[i] do
				begin
				{$WARNINGS OFF}
				team^.DrawHealthY:= ny + dy * Gear^.Timer div 640;
				team^.TeamHealthBarWidth:= team^.NewTeamHealthBarWidth + dw * Gear^.Timer div cSorterWorkTime;
				{$WARNINGS ON}
				end;

	if (Gear^.Timer = 0) or (currsorter <> Gear) then
		begin
		if currsorter = Gear then currsorter:= nil;
		DeleteVisualGear(Gear);
		exit
		end
	end
end;

procedure doStepTeamHealthSorter(Gear: PVisualGear; Steps: Longword);
var i: Longword;
	b: boolean;
	t: LongInt;
begin
for t:= 0 to Pred(TeamsCount) do
	with thexchar[t] do
		begin
		dy:= TeamsArray[t]^.DrawHealthY;
		dw:= TeamsArray[t]^.TeamHealthBarWidth - TeamsArray[t]^.NewTeamHealthBarWidth;
		team:= TeamsArray[t];
		SortFactor:= TeamsArray[t]^.Clan^.ClanHealth;
		SortFactor:= (SortFactor shl  3) + TeamsArray[t]^.Clan^.ClanIndex;
		SortFactor:= (SortFactor shl 30) + TeamsArray[t]^.TeamHealth;
		end;

if TeamsCount > 1 then
	repeat
	b:= true;
	for t:= 0 to TeamsCount - 2 do
		if (thexchar[t].SortFactor > thexchar[Succ(t)].SortFactor) then
			begin
			thexchar[cMaxTeams]:= thexchar[t];
			thexchar[t]:= thexchar[Succ(t)];
			thexchar[Succ(t)]:= thexchar[cMaxTeams];
			b:= false
			end
	until b;

t:= - 4;
for i:= 0 to Pred(TeamsCount) do
	with thexchar[i] do
		begin
		dec(t, team^.HealthTex^.h + 2);
		ny:= t;
		dy:= dy - ny
		end;

Gear^.Timer:= cSorterWorkTime;
Gear^.doStep:= @doStepTeamHealthSorterWork;
currsorter:= Gear;
//doStepTeamHealthSorterWork(Gear, Steps)
end;

procedure doStepSpeechBubbleWork(Gear: PVisualGear; Steps: Longword);
begin
if Gear^.Timer > Steps then dec(Gear^.Timer, Steps) else Gear^.Timer:= 0;

if (PHedgehog(Gear^.Hedgehog)^.Gear <> nil) then
	begin
	Gear^.X:= PHedgehog(Gear^.Hedgehog)^.Gear^.X + int2hwFloat(Gear^.Tex^.w div 2  - Gear^.FrameTicks);
	Gear^.Y:= PHedgehog(Gear^.Hedgehog)^.Gear^.Y - int2hwFloat(16 + Gear^.Tex^.h);
	end;

if Gear^.Timer = 0 then
	begin
	if PHedgehog(Gear^.Hedgehog)^.SpeechGear = Gear then
		PHedgehog(Gear^.Hedgehog)^.SpeechGear:= nil;
	DeleteVisualGear(Gear)
	end;
end;

procedure doStepSpeechBubble(Gear: PVisualGear; Steps: Longword);
begin
with PHedgehog(Gear^.Hedgehog)^ do
    if SpeechGear <> nil then SpeechGear^.Timer:= 0;

PHedgehog(Gear^.Hedgehog)^.SpeechGear:= Gear;

Gear^.Timer:= max(Length(Gear^.Text) * 150, 3000);

Gear^.Tex:= RenderSpeechBubbleTex(Gear^.Text, Gear^.FrameTicks, fnt16);

case Gear^.FrameTicks of
    1: Gear^.FrameTicks:= SpritesData[sprSpeechTail].Width-28;
    2: Gear^.FrameTicks:= SpritesData[sprThoughtTail].Width-20;
    3: Gear^.FrameTicks:= SpritesData[sprShoutTail].Width-10;
    end;

Gear^.doStep:= @doStepSpeechBubbleWork;

Gear^.Y:= Gear^.Y - int2hwFloat(Gear^.Tex^.h)
end;

// ==================================================================
const doStepHandlers: array[TVisualGearType] of TVGearStepProcedure =
		(
			@doStepFlake,
			@doStepCloud,
			@doStepExpl,
			@doStepExpl,
			@doStepFire,
			@doStepSmallDamage,
			@doStepTeamHealthSorter,
			@doStepSpeechBubble,
			@doStepBubble,
			@doStepSteam,
			@doStepSmoke,
			@doStepHealth
		);

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType): PVisualGear;
var gear: PVisualGear;
	t: Longword;
	sp: hwFloat;
begin
if (GameType = gmtSave) or (fastUntilLag and (GameType = gmtNet)) then // we are scrolling now
	if Kind <> vgtCloud then
		begin
		AddVisualGear:= nil;
		exit
		end;

if cReducedQuality and
   (Kind <> vgtTeamHealthSorter) and
   (Kind <> vgtSmallDamageTag) and
   (Kind <> vgtSpeechBubble) then
	begin
	AddVisualGear:= nil;
	exit
	end;

New(gear);
FillChar(gear^, sizeof(TVisualGear), 0);
gear^.X:= int2hwFloat(X);
gear^.Y:= int2hwFloat(Y);
gear^.Kind := Kind;
gear^.doStep:= doStepHandlers[Kind];

with gear^ do
	case Kind of
	vgtFlake: begin
				FrameTicks:= random(vobFrameTicks);
				Frame:= random(vobFramesCount);
				Angle:= random * 360;
				dx.isNegative:= random(2) = 0;
				dx.QWordValue:= random(100000000);
				dy.isNegative:= false;
				dy.QWordValue:= random(70000000);
				dAngle:= (random(2) * 2 - 1) * (1 + random) * vobVelocity / 1000
				end;
	vgtCloud: begin
				Frame:= random(4);
				dx.isNegative:= random(2) = 0;
				dx.QWordValue:= random(214748364);
				dy.isNegative:= random(2) = 0;
				dy.QWordValue:= 21474836 + random(64424509);
				mdY:= dy.QWordValue
				end;
	vgtExplPart,
	vgtExplPart2: begin
				t:= random(1024);
				sp:= _0_001 * (random(95) + 70);
				dx:= AngleSin(t) * sp;
				dx.isNegative:= random(2) = 0;
				dy:= AngleCos(t) * sp;
				dy.isNegative:= random(2) = 0;
				Frame:= 7 - random(3);
				FrameTicks:= cExplFrameTicks
				end;
		vgtFire: begin
				t:= random(1024);
				sp:= _0_001 * (random(85) + 95);
				dx:= AngleSin(t) * sp;
				dx.isNegative:= random(2) = 0;
				dy:= AngleCos(t) * sp;
				dy.isNegative:= random(2) = 0;
				FrameTicks:= 650 + random(250);
				Frame:= random(8)
				end;
	vgtSmallDamageTag: begin
				gear^.FrameTicks:= 1100
				end;
	vgtBubble: begin
				dx.isNegative:= random(2) = 0;
				dx.QWordValue:= random(100000000);
				dy:= _0_001 * (random(85) + 95);
				dy.isNegative:= false;
				FrameTicks:= 250 + random(1751);
				Frame:= random(5)
				end;
	vgtSteam: begin
				dx.isNegative:= random(2) = 0;
				dx.QWordValue:= random(100000000);
				dy:= _0_001 * (random(85) + 95);
				dy.isNegative:= false;
				Frame:= 7 - random(3);
				FrameTicks:= cExplFrameTicks * 2;
				end;
  vgtSmoke: begin
				dx:= _0_0002 * (random(45) + 10);
				dx.isNegative:= random(2) = 0;
				dy:= _0_0002 * (random(45) + 10);
				dy.isNegative:= false;
				Frame:= 7 - random(2);
				FrameTicks:= cExplFrameTicks * 2;
				end;
	vgtHealth: begin
				dx:= _0_001 * random(45);
				dx.isNegative:= random(2) = 0;
				dy:= _0_001 * (random(20) + 25);
				Frame:= 0;
				FrameTicks:= random(750) + 1250;
				end;
		end;

if VisualGearsList <> nil then
	begin
	VisualGearsList^.PrevGear:= gear;
	gear^.NextGear:= VisualGearsList
	end;
VisualGearsList:= gear;

AddVisualGear:= gear;
end;

procedure DeleteVisualGear(Gear: PVisualGear);
begin
if Gear^.Tex <> nil then
	FreeTexture(Gear^.Tex);

if Gear^.NextGear <> nil then Gear^.NextGear^.PrevGear:= Gear^.PrevGear;
if Gear^.PrevGear <> nil then Gear^.PrevGear^.NextGear:= Gear^.NextGear
   else VisualGearsList:= Gear^.NextGear;

Dispose(Gear)
end;

procedure ProcessVisualGears(Steps: Longword);
var Gear, t: PVisualGear;
begin
if Steps = 0 then exit;

t:= VisualGearsList;
while t <> nil do
      begin
      Gear:= t;
      t:= Gear^.NextGear;
      Gear^.doStep(Gear, Steps)
      end
end;

procedure DrawVisualGears(Layer: LongWord);
var Gear: PVisualGear;
begin
Gear:= VisualGearsList;
case Layer of
	0: while Gear <> nil do
		begin
		case Gear^.Kind of
			vgtFlake: if vobVelocity = 0 then
						DrawSprite(sprFlake, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Frame)
					else
						DrawRotatedF(sprFlake, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
			vgtCloud: DrawSprite(sprCloud, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Frame);
			end;
		Gear:= Gear^.NextGear
		end;
	1: while Gear <> nil do
		begin
			if not cReducedQuality then
				case Gear^.Kind of
					vgtSmoke: DrawSprite(sprSmoke, hwRound(Gear^.X) + WorldDx - 11, hwRound(Gear^.Y) + WorldDy - 11, 7 - Gear^.Frame);
				end;
		Gear:= Gear^.NextGear
		end;
	2: while Gear <> nil do
		begin
        if not cReducedQuality then
            case Gear^.Kind of
                vgtExplPart: DrawSprite(sprExplPart, hwRound(Gear^.X) + WorldDx - 16, hwRound(Gear^.Y) + WorldDy - 16, 7 - Gear^.Frame);
                vgtExplPart2: DrawSprite(sprExplPart2, hwRound(Gear^.X) + WorldDx - 16, hwRound(Gear^.Y) + WorldDy - 16, 7 - Gear^.Frame);
                vgtFire: DrawSprite(sprFlame, hwRound(Gear^.X) + WorldDx - 8, hwRound(Gear^.Y) + WorldDy, (RealTicks div 64 + Gear^.Frame) mod 8);
				vgtBubble: DrawSprite(sprBubbles, hwRound(Gear^.X) + WorldDx - 8, hwRound(Gear^.Y) + WorldDy - 8, Gear^.Frame);//(RealTicks div 64 + Gear^.Frame) mod 8);
				vgtSteam: DrawSprite(sprExplPart, hwRound(Gear^.X) + WorldDx - 16, hwRound(Gear^.Y) + WorldDy - 16, 7 - Gear^.Frame);
				vgtHealth:  begin
							case Gear^.Frame div 10 of
								0:glColor4f(0, 1, 0, Gear^.FrameTicks / 1000);
								1:glColor4f(1, 0, 0, Gear^.FrameTicks / 1000);
							end;
							DrawSprite(sprHealth, hwRound(Gear^.X) + WorldDx - 8, hwRound(Gear^.Y) + WorldDy - 8, 0);
							glColor4f(1, 1, 1, 1);
							end;
            end;
        case Gear^.Kind of
            vgtSmallDamageTag: DrawCentered(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Tex);
            vgtSpeechBubble: if Gear^.Tex <> nil then DrawCentered(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Tex);
        end;
		Gear:= Gear^.NextGear
		end
	end
end;

procedure AddClouds;
var i: LongInt;
begin
for i:= 0 to cCloudsNumber - 1 do
    AddVisualGear( - cScreenWidth + i * ((cScreenWidth * 2 + (LAND_WIDTH+256)) div (cCloudsNumber + 1)), LAND_HEIGHT-1184, vgtCloud)
end;

procedure init_uVisualGears;
begin
	VisualGearsList:= nil;
end;

procedure free_uVisualGears;
begin
while VisualGearsList <> nil do DeleteVisualGear(VisualGearsList);
end;

end.
