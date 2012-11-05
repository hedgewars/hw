unit uPhysFSLayer;

{$LINKLIB ../bin/libphysfs.a}

interface

procedure initModule;
procedure freeModule;

implementation
uses uUtils;

function PHYSFS_init(argv0: PChar) : LongInt; cdecl; external;
function PHYSFS_deinit() : LongInt; cdecl; external;

function PHYSFS_mount(newDir, mountPoint: PChar; appendToPath: LongBool); cdecl; external;

procedure initModule;
begin
    PHYSFS_init(Str2PChar(ParamStr(0)));
end;

procedure freeModule;
begin
    PHYSFS_deinit;
end;

end.
