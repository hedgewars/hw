unit uAI2;

interface

procedure ProcessBot;
procedure initModule;

implementation
uses uLandUtils, uFloat, uVariables, uTypes, uAmmos;

{$linklib hwengine_future}

type TAmmoCounts = array[TAmmoType] of Longword;
     PAmmoCounts = ^TAmmoCounts;

function create_ai(game_field: pointer): pointer; cdecl; external;
procedure ai_clear_team(ai: pointer); cdecl; external;
procedure ai_add_team_hedgehog(ai: pointer; x, y: real; ammo_counts: PAmmoCounts); cdecl; external;
procedure ai_think(ai: pointer); cdecl; external;
function ai_have_plan(): boolean; cdecl; external;
procedure dispose_ai(ai: pointer); cdecl; external;

var ai: pointer;

procedure ProcessBot;
var currHedgehogIndex, itHedgehog: Longword;
    itAmmo: TAmmoType;
    ammoCounts: TAmmoCounts;
begin
    if ai = nil then
    begin
        ai:= create_ai(gameField)
    end;
    
    ai_clear_team(ai);
    
    currHedgehogIndex:= CurrentTeam^.CurrHedgehog;
    itHedgehog:= currHedgehogIndex;
    repeat
        with CurrentTeam^.Hedgehogs[itHedgehog] do
            if (Gear <> nil) and (Effects[heFrozen] = 0) then
            begin
                for itAmmo:= Low(TAmmoType) to High(TAmmoType) do
                    ammoCounts[itAmmo]:= HHHasAmmo(CurrentTeam^.Hedgehogs[itHedgehog], itAmmo);

                ai_add_team_hedgehog(ai, hwFloat2float(Gear^.X), hwFloat2float(Gear^.Y), @ammoCounts)
            end;
        itHedgehog:= Succ(itHedgehog) mod CurrentTeam^.HedgehogsNumber;
    until (itHedgehog = currHedgehogIndex);
    
    ai_think(ai);
end;

procedure initModule;
begin
    ai:= nil
end;

end.

