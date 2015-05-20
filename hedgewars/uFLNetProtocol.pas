unit uFLNetProtocol;
interface

procedure passNetData(p: pointer); cdecl;

implementation

procedure passNetData(p: pointer); cdecl;
begin
    writeln('meow')
end;

end.
