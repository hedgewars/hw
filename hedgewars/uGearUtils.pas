unit uGearUtils;
interface
uses uTypes;

procedure doMakeExplosion(X, Y, Radius: LongInt; AttackingHog: PHedgehog; Mask: Longword; const Tint: LongWord = $FFFFFFFF); 

implementation
uses uGearsList;

procedure doMakeExplosion(X, Y, Radius: LongInt; AttackingHog: PHedgehog; Mask: Longword; const Tint: LongWord);
var Gear: PGear;
    dmg, dmgRadius, dmgBase: LongInt;
    fX, fY: hwFloat;
    vg: PVisualGear;
    i, cnt: LongInt;
begin
    if Radius > 4 then AddFileLog('Explosion: at (' + inttostr(x) + ',' + inttostr(y) + ')');
    if Radius > 25 then KickFlakes(Radius, X, Y);

    if ((Mask and EXPLNoGfx) = 0) then
        begin
        vg:= nil;
        if Radius > 50 then vg:= AddVisualGear(X, Y, vgtBigExplosion)
        else if Radius > 10 then vg:= AddVisualGear(X, Y, vgtExplosion);
        if vg <> nil then
            vg^.Tint:= Tint;
        end;
    if (Mask and EXPLAutoSound) <> 0 then PlaySound(sndExplosion);

    if (Mask and EXPLAllDamageInRadius) = 0 then
        dmgRadius:= Radius shl 1
    else
        dmgRadius:= Radius;
    dmgBase:= dmgRadius + cHHRadius div 2;
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
                    gtCase,
                    gtTarget,
                    gtFlame,
                    gtExplosives,
                    gtStructure: begin
    // Run the calcs only once we know we have a type that will need damage
                            if hwRound(hwAbs(Gear^.X-fX)+hwAbs(Gear^.Y-fY)) < dmgBase then
                                dmg:= dmgBase - max(hwRound(Distance(Gear^.X - fX, Gear^.Y - fY)),Gear^.Radius);
                            if dmg > 1 then
                                begin
                                dmg:= ModifyDamage(min(dmg div 2, Radius), Gear);
                                //AddFileLog('Damage: ' + inttostr(dmg));
                                if (Mask and EXPLNoDamage) = 0 then
                                    begin
                                    if not Gear^.Invulnerable then
                                        ApplyDamage(Gear, AttackingHog, dmg, dsExplosion)
                                    else
                                        Gear^.State:= Gear^.State or gstWinner;
                                    end;
                                if ((Mask and EXPLDoNotTouchAny) = 0) and (((Mask and EXPLDoNotTouchHH) = 0) or (Gear^.Kind <> gtHedgehog)) then
                                    begin
                                    DeleteCI(Gear);
                                    if Gear^.Kind <> gtHedgehog then
                                        begin
                                        Gear^.dX:= Gear^.dX + SignAs(_0_005 * dmg + cHHKick, Gear^.X - fX)/Gear^.Density;
                                        Gear^.dY:= Gear^.dY + SignAs(_0_005 * dmg + cHHKick, Gear^.Y - fY)/Gear^.Density;
                                        end
                                    else
                                        begin
                                        Gear^.dX:= Gear^.dX + SignAs(_0_005 * dmg + cHHKick, Gear^.X - fX);
                                        Gear^.dY:= Gear^.dY + SignAs(_0_005 * dmg + cHHKick, Gear^.Y - fY);
                                        end;

                                    Gear^.State:= (Gear^.State or gstMoving) and (not gstLoser);
                                    if not Gear^.Invulnerable then
                                        Gear^.State:= (Gear^.State or gstMoving) and (not gstWinner);
                                    Gear^.Active:= true;
                                    if Gear^.Kind <> gtFlame then FollowGear:= Gear
                                    end;
                                if ((Mask and EXPLPoisoned) <> 0) and (Gear^.Kind = gtHedgehog) and (not Gear^.Invulnerable) then
                                    Gear^.Hedgehog^.Effects[hePoisoned] := true;
                                end;

                            end;
                    gtGrave: begin
    // Run the calcs only once we know we have a type that will need damage
                            if hwRound(hwAbs(Gear^.X-fX)+hwAbs(Gear^.Y-fY)) < dmgBase then
                                dmg:= dmgBase - hwRound(Distance(Gear^.X - fX, Gear^.Y - fY));
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
        if (GameFlags and gfSolidLand) = 0 then
            begin
            cnt:= DrawExplosion(X, Y, Radius) div 1608; // approx 2 16x16 circles to erase per chunk
            if (cnt > 0) and (SpritesData[sprChunk].Texture <> nil) then
                for i:= 0 to cnt do
                    AddVisualGear(X, Y, vgtChunk)
            end;

    uAIMisc.AwareOfExplosion(0, 0, 0)
end;

end.
