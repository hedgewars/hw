unit uFLTeams;
interface
uses uFLTypes;

function createRandomTeam: TTeam;
procedure sendTeamConfig(var team: TTeam);


implementation
uses uFLUtils, uFLIPC;

function createRandomTeam: TTeam;
var t: TTeam;
    i: Longword;
begin
    with t do
    begin
        teamName:= 'team' + inttostr(random(100));

        for i:= 0 to 7 do
            with hedgehogs[i] do
            begin
                name:= 'hedgehog ' + inttostr(i);
                hat:= 'NoHat'
            end;

        botLevel:= 0;
        hogsNumber:= 4
    end;
    createRandomTeam:= t
end;

procedure sendTeamConfig(var team: TTeam);
var i: Longword;
begin
    with team do
    begin
        ipcToEngine('eaddteam <hash> ' + color + ' ' + teamName);
        for i:= 0 to Pred(hogsNumber) do
        begin
            ipcToEngine('eaddhh ' + inttostr(botLevel) + ' 100 ' + hedgehogs[i].name);
            ipcToEngine('ehat ' + hedgehogs[i].hat);
        end;
    end
end;

end.
