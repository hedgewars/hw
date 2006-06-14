unit uAIActions;
interface
uses uGears;
const MAXACTIONS = 256;
      aia_none       = 0;
      aia_Left       = 1;
      aia_Right      = 2;
      aia_Timer      = 3;
      aia_Slot       = 4;
      aia_attack     = 5;
      aia_Up         = 6;
      aia_Down       = 7;

      aia_Weapon     = $80000000;
      aia_WaitX      = $80000001;
      aia_WaitY      = $80000002;
      aia_LookLeft   = $80000003;
      aia_LookRight  = $80000004;

      aim_push       = $80000000;
      aim_release    = $80000001;
      ai_specmask    = $80000000;

type TAction = record
               Action, Param: Longword;
               Time: Longword;
               end;
     TActions = record
                Count, Pos: Longword;
                actions: array[0..Pred(MAXACTIONS)] of TAction;
                Score: integer;
                end;

procedure AddAction(var Actions: TActions; Action, Param, TimeDelta: Longword);
procedure ProcessAction(var Actions: TActions; Me: PGear);

implementation
uses uMisc, uTeams, uConsts, uConsole;

const ActionIdToStr: array[0..7] of string[16] = (
{aia_none}           '',
{aia_Left}           'left',
{aia_Right}          'right',
{aia_Timer}          'timer',
{aia_slot}           'slot',
{aia_attack}         'attack',
{aia_Up}             'up',
{aia_Down}           'down'
                     );

procedure AddAction(var Actions: TActions; Action, Param, TimeDelta: Longword);
begin
with Actions do
     begin
     actions[Count].Action:= Action;
     actions[Count].Param:= Param;
     if Count > 0 then actions[Count].Time:= actions[Pred(Count)].Time + TimeDelta
                  else actions[Count].Time:= GameTicks + TimeDelta;
     inc(Count);
     TryDo(Count < MAXACTIONS, 'AI: actions overflow', true);
     end
end;

procedure SetWeapon(weap: Longword);
begin
with CurrentTeam^ do
     with Hedgehogs[CurrHedgehog] do
          while Ammo[CurSlot, CurAmmo].AmmoType <> TAmmotype(weap) do
                ParseCommand('/slot ' + chr(49 + Ammoz[TAmmoType(weap)].Slot));
end;

procedure ProcessAction(var Actions: TActions; Me: PGear);
var s: shortstring;
begin
if Actions.Pos >= Actions.Count then exit;
with Actions.actions[Actions.Pos] do
     begin
     if Time > GameTicks then exit;
     if (Action and ai_specmask) <> 0 then
        case Action of
           aia_Weapon: SetWeapon(Param);
            aia_WaitX: if round(Me.X) = Param then Time:= GameTicks
                                              else exit;
            aia_WaitY: if round(Me.Y) = Param then Time:= GameTicks
                                              else exit;
         aia_LookLeft: if Me.dX >= 0 then
                          begin
                          ParseCommand('+left');
                          exit
                          end else ParseCommand('-left');
        aia_LookRight: if Me.dX < 0 then
                          begin
                          ParseCommand('+right');
                          exit
                          end else ParseCommand('-right');
             end else
        begin
        s:= ActionIdToStr[Action];
        if (Param and ai_specmask) <> 0 then
           case Param of
             aim_push: s:= '+' + s;
          aim_release: s:= '-' + s;
             end
          else if Param <> 0 then s:= s + ' ' + inttostr(Param);
        ParseCommand(s)
        end
     end;
inc(Actions.Pos)
end;

end.
