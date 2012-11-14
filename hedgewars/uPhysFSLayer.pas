unit uPhysFSLayer;

{$LINKLIB ../bin/libphysfs.a}
{$LINKLIB ../bin/libphysfsrwops.a}

interface
uses SDLh;

procedure initModule;
procedure freeModule;

function rwopsOpenRead(fname: shortstring): PSDL_RWops;
function rwopsOpenWrite(fname: shortstring): PSDL_RWops;

implementation
uses uUtils, uVariables;

function PHYSFS_init(argv0: PChar) : LongInt; cdecl; external;
function PHYSFS_deinit() : LongInt; cdecl; external;
function PHYSFSRWOPS_openRead(fname: PChar): PSDL_RWops; cdecl; external;
function PHYSFSRWOPS_openWrite(fname: PChar): PSDL_RWops; cdecl; external;

function PHYSFS_mount(newDir, mountPoint: PChar; appendToPath: LongBool) : LongInt; cdecl; external;

function rwopsOpenRead(fname: shortstring): PSDL_RWops;
begin
    exit(PHYSFSRWOPS_openRead(Str2PChar(fname)));
end;

function rwopsOpenWrite(fname: shortstring): PSDL_RWops;
begin
    exit(PHYSFSRWOPS_openWrite(Str2PChar(fname)));
end;

procedure initModule;
var i: LongInt;
begin
    i:= PHYSFS_init(Str2PChar(ParamStr(0)));
    AddFileLog('[PhysFS] init: ' + inttostr(i));

    i:= PHYSFS_mount(Str2PChar(PathPrefix), nil, true);
    AddFileLog('[PhysFS] mount ' + PathPrefix + ': ' + inttostr(i));
    i:= PHYSFS_mount(Str2PChar(UserPathPrefix), nil, true);
    AddFileLog('[PhysFS] mount ' + UserPathPrefix + ': ' + inttostr(i));
end;

procedure freeModule;
begin
    PHYSFS_deinit;
end;

end.
