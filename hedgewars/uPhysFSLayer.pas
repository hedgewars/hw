unit uPhysFSLayer;

{$LINKLIB ../bin/libphysfs.a}
{$LINKLIB ../bin/libphysfsrwops.a}

interface
uses SDLh;

procedure initModule;
procedure freeModule;

function PHYSFSRWOPS_openRead(fname: PChar): PSDL_RWops; cdecl; external;
function PHYSFSRWOPS_openWrite(fname: PChar): PSDL_RWops; cdecl; external;

implementation
uses uUtils, uVariables;

function PHYSFS_init(argv0: PChar) : LongInt; cdecl; external;
function PHYSFS_deinit() : LongInt; cdecl; external;

function PHYSFS_mount(newDir, mountPoint: PChar; appendToPath: LongBool) : LongInt; cdecl; external;

procedure initModule;
begin
    PHYSFS_init(Str2PChar(ParamStr(0)));

    PHYSFS_mount(Str2PChar(PathPrefix), nil, true);
    PHYSFS_mount(Str2PChar(UserPathPrefix), nil, true);
end;

procedure freeModule;
begin
    PHYSFS_deinit;
end;

end.
