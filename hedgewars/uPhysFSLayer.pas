unit uPhysFSLayer;
{$IFDEF ANDROID}
    {$linklib physfs}
    {$linklib physfsrwops}
{$ELSE}
    {$LINKLIB ../bin/libphysfs.a}
    {$LINKLIB ../bin/libphysfsrwops.a}
{$ENDIF}

interface
uses SDLh;

procedure initModule;
procedure freeModule;

type PFSFile = pointer;

function rwopsOpenRead(fname: shortstring): PSDL_RWops;
function rwopsOpenWrite(fname: shortstring): PSDL_RWops;

function pfsOpenRead(fname: shortstring): PFSFile;
function pfsClose(f: PFSFile): boolean;

procedure pfsReadLn(f: PFSFile; var s: shortstring);
function pfsBlockRead(f: PFSFile; buf: pointer; size: Int64): Int64;
function pfsEOF(f: PFSFile): boolean;

function pfsExists(fname: shortstring): boolean;

implementation
uses uUtils, uVariables;

function PHYSFS_init(argv0: PChar) : LongInt; cdecl; external;
function PHYSFS_deinit() : LongInt; cdecl; external;
function PHYSFSRWOPS_openRead(fname: PChar): PSDL_RWops; cdecl; external;
function PHYSFSRWOPS_openWrite(fname: PChar): PSDL_RWops; cdecl; external;

function PHYSFS_mount(newDir, mountPoint: PChar; appendToPath: LongBool) : LongInt; cdecl; external;
function PHYSFS_openRead(fname: PChar): PFSFile; cdecl; external;
function PHYSFS_eof(f: PFSFile): LongBool; cdecl; external;
function PHYSFS_readBytes(f: PFSFile; buffer: pointer; len: Int64): Int64; cdecl; external;
function PHYSFS_close(f: PFSFile): LongBool; cdecl; external;
function PHYSFS_exists(fname: PChar): LongBool; cdecl; external;

procedure hedgewarsMountPackages(); cdecl; external;

function rwopsOpenRead(fname: shortstring): PSDL_RWops;
begin
    exit(PHYSFSRWOPS_openRead(Str2PChar(fname)));
end;

function rwopsOpenWrite(fname: shortstring): PSDL_RWops;
begin
    exit(PHYSFSRWOPS_openWrite(Str2PChar(fname)));
end;

function pfsOpenRead(fname: shortstring): PFSFile;
begin
    exit(PHYSFS_openRead(Str2PChar(fname)));
end;

function pfsEOF(f: PFSFile): boolean;
begin
    exit(PHYSFS_eof(f))
end;

function pfsClose(f: PFSFile): boolean;
begin
    exit(PHYSFS_close(f))
end;

function pfsExists(fname: shortstring): boolean;
begin
    exit(PHYSFS_exists(Str2PChar(fname)))
end;


procedure pfsReadLn(f: PFSFile; var s: shortstring);
var c: char;
begin
s[0]:= #0;

while (PHYSFS_readBytes(f, @c, 1) = 1) and (c <> #10) do
    if (c <> #13) and (s[0] < #255) then
        begin
        inc(s[0]);
        s[byte(s[0])]:= c
        end
end;

function pfsBlockRead(f: PFSFile; buf: pointer; size: Int64): Int64;
var r: Int64;
begin
    r:= PHYSFS_readBytes(f, buf, size);

    if r <= 0 then
        pfsBlockRead:= 0
    else
        pfsBlockRead:= r
end;

procedure initModule;
var i: LongInt;
begin
    i:= PHYSFS_init(Str2PChar(ParamStr(0)));
    AddFileLog('[PhysFS] init: ' + inttostr(i));

    i:= PHYSFS_mount(Str2PChar(PathPrefix), nil, true);
    AddFileLog('[PhysFS] mount ' + PathPrefix + ': ' + inttostr(i));
    i:= PHYSFS_mount(Str2PChar(UserPathPrefix + '/Data'), nil, true);
    AddFileLog('[PhysFS] mount ' + UserPathPrefix + '/Data: ' + inttostr(i));

    hedgewarsMountPackages;
end;

procedure freeModule;
begin
    PHYSFS_deinit;
end;

end.
