unit uAI2;

interface

procedure ProcessBot;
procedure initModule;

implementation
uses uLandUtils, uFloat, uVariables, uAmmos, uConsts, 
     uTypes,
    uCommands, uUtils, uDebug, uAILandMarks,
    uGearsUtils;


{$linklib hwengine_future}

type TAmmoCounts = array[TAmmoType] of Longword;
     PAmmoCounts = ^TAmmoCounts;
     HedgehogState = record
        x, y: real;
        angle: Longword;
        looking_to_the_right,
        is_moving: boolean;
        end;

function create_ai(game_field: pointer): pointer; cdecl; external;
procedure ai_clear_team(ai: pointer); cdecl; external;
procedure ai_add_team_hedgehog(ai: pointer; x, y: real; ammo_counts: PAmmoCounts); cdecl; external;
procedure ai_think(ai: pointer); cdecl; external;
function ai_have_plan(): boolean; cdecl; external;
procedure ai_get_action(ai: pointer; var current_hedgehog_state: HedgehogState; var action: shortstring); cdecl; external;
procedure dispose_ai(ai: pointer); cdecl; external;

var ai: pointer;

procedure initiateThinking();
var currHedgehogIndex, itHedgehog: Longword;
    itAmmo: TAmmoType;
    ammoCounts: TAmmoCounts;
begin
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

procedure processActions();
var state: HedgehogState;
    action: shortstring;
begin
  with CurrentHedgehog^ do
    begin
    state.x:= hwfloat2float(Gear^.X);
    state.y:= hwfloat2float(Gear^.Y);
    state.angle:= Gear^.Angle;
    state.looking_to_the_right:= not Gear^.dX.isNegative;
    state.is_moving:= (Gear^.State and (gstAttacking or gstHHJumping or gstMoving)) <> 0;
    end;
    
    ai_get_action(ai, state, action);
    
    if action <> '' then
    begin
      ParseCommand(action, true);
    end
end;

procedure ProcessBot;
begin
  with CurrentHedgehog^ do
      if (Gear = nil) or ((Gear^.State and gstHHDriven) = 0) then
      begin
        // TODO: clear gear messages, stop thininking thread
        exit;
      end;
    
  if ai = nil then
  begin
    ai:= create_ai(gameField)
  end;
  
  if not ai_have_plan() then
  begin
    initiateThinking();
    exit;
  end else
  begin
    processActions();
  end;  
end;

procedure initModule;
begin
    ai:= nil
end;

end.

