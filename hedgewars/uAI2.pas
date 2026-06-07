unit uAI2;

interface

procedure ProcessBot;
procedure initModule;

implementation
uses uLandUtils, uFloat, uVariables, uAmmos, uConsts,
     uTypes,
    uCommands, uUtils, uDebug, uAILandMarks,
    uGearsUtils, uRust, uConsole, uAIMisc;

var ai: pointer;

procedure initiateThinking();
var currHedgehogIndex, itHedgehog, i: Longword;
    itAmmo: TAmmoType;
    ammoCounts: TAmmoCounts;
begin
  FillTargets;
  ai_clear_targets(ai);
  for i:= 0 to Pred(Targets.Count) do
    if not Targets.ar[i].dead then
      ai_add_target(ai, Targets.ar[i].Point.X, Targets.ar[i].Point.Y, Targets.ar[i].Score, Targets.ar[i].Radius, Targets.ar[i].Density);

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
    state.looking_to_the_right:= not isNegative(Gear^.dX);
    state.is_moving:= (Gear^.State and (gstAttacking or gstHHJumping or gstMoving)) <> 0;
    state.game_ticks:= GameTicks;
    end;
    
    ai_get_action(ai, state, action);
    
    if action <> '' then
    begin
      while Pos(#10, action) > 0 do
      begin
        ParseCommand(Copy(action, 1, Pos(#10, action) - 1), true);
        Delete(action, 1, Pos(#10, action));
      end;
      if action <> '' then
        ParseCommand(action, true);
    end
end;

procedure ProcessBot;
begin
  with CurrentHedgehog^ do
      if (Gear = nil) or ((Gear^.State and gstHHDriven) = 0) then
      begin
        // TODO: clear gear messages, stop thininking thread
        if ai <> nil then
          begin
          ai_clear_team(ai);
          ai_think(ai);
          end;

        exit;
      end;
    
  if ai = nil then
  begin
    ai:= create_ai(gameField)
  end;
  
  if not ai_have_plan(ai) and (GameTicks mod 128 = 0) then
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

