unit uPhysFSLayer;

interface
uses SDLh, LuaPas;

{$INCLUDE "config.inc"}

const PhysfsLibName = {$IFDEF PHYSFS_INTERNAL}'libhwphysfs'{$ELSE}'libphysfs'{$ENDIF};
const PhyslayerLibName = 'libphyslayer';

{$IFNDEF WIN32}
    {$linklib physfs}
    {$linklib physlayer}
{$ENDIF}

procedure initModule;
procedure freeModule;

type PFSFile = pointer;

function rwopsOpenRead(fname: shortstring): PSDL_RWops;
function rwopsOpenWrite(fname: shortstring): PSDL_RWops;

function pfsOpenRead(fname: shortstring): PFSFile;
function pfsClose(f: PFSFile): boolean;

procedure pfsReadLn(f: PFSFile; var s: shortstring);
procedure pfsReadLnA(f: PFSFile; var s: ansistring);
function pfsBlockRead(f: PFSFile; buf: pointer; size: Int64): Int64;
function pfsEOF(f: PFSFile): boolean;

function pfsExists(fname: shortstring): boolean;

function  physfsReader(L: Plua_State; f: PFSFile; sz: Psize_t) : PChar; cdecl; external PhyslayerLibName;
procedure physfsReaderSetBuffer(buf: pointer); cdecl; external PhyslayerLibName;
procedure hedgewarsMountPackage(filename: PChar); cdecl; external PhyslayerLibName;

implementation
uses uUtils, uVariables, sysutils;

function PHYSFS_init(argv0: PChar) : LongInt; cdecl; external PhysfsLibName;
function PHYSFS_deinit() : LongInt; cdecl; external PhysfsLibName;
function PHYSFSRWOPS_openRead(fname: PChar): PSDL_RWops; cdecl ; external PhyslayerLibName;
function PHYSFSRWOPS_openWrite(fname: PChar): PSDL_RWops; cdecl; external PhyslayerLibName;

function PHYSFS_mount(newDir, mountPoint: PChar; appendToPath: LongBool) : LongBool; cdecl; external PhysfsLibName;
function PHYSFS_openRead(fname: PChar): PFSFile; cdecl; external PhysfsLibName;
function PHYSFS_eof(f: PFSFile): LongBool; cdecl; external PhysfsLibName;
function PHYSFS_readBytes(f: PFSFile; buffer: pointer; len: Int64): Int64; cdecl; external PhysfsLibName;
function PHYSFS_close(f: PFSFile): LongBool; cdecl; external PhysfsLibName;
function PHYSFS_exists(fname: PChar): LongBool; cdecl; external PhysfsLibName;
function PHYSFS_getLastError(): PChar; cdecl; external PhysfsLibName;

procedure hedgewarsMountPackages(); cdecl; external PhyslayerLibName;

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

procedure pfsReadLnA(f: PFSFile; var s: ansistring);
var c: char;
    b: shortstring;
begin
s:= '';
b[0]:= #0;

while (PHYSFS_readBytes(f, @c, 1) = 1) and (c <> #10) do
    if (c <> #13) then
        begin
        inc(b[0]);
        b[byte(b[0])]:= c;
        if b[0] = #255 then
            begin
            s:= s + b;
            b[0]:= #0
            end
        end;
        
s:= s + b
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

procedure pfsMount(path: AnsiString; mountpoint: PChar);
begin
    if PHYSFS_mount(Str2PChar(path), mountpoint, false) then
        AddFileLog('[PhysFS] mount ' + path + ' at ' + mountpoint + ' : ok')
    else
        AddFileLog('[PhysFS] mount ' + path + ' at ' + mountpoint + ' : FAILED ("' + PHYSFS_getLastError() + '")');
end;

procedure pfsMountAtRoot(path: AnsiString);
begin
    pfsMount(path, '/');
end;

procedure initModule;
var i: LongInt;
    cPhysfsId: shortstring;
    fp: AnsiString;
begin
{$IFDEF HWLIBRARY}
    //TODO: http://icculus.org/pipermail/physfs/2011-August/001006.html
    cPhysfsId:= GetCurrentDir() + {$IFDEF DARWIN}{$IFNDEF IPHONEOS}'/Hedgewars.app/Contents/MacOS/' + {$ENDIF}{$ENDIF} ' hedgewars';
{$ELSE}
    cPhysfsId:= ParamStr(0);
{$ENDIF}

    i:= PHYSFS_init(Str2PChar(cPhysfsId));
    AddFileLog('[PhysFS] init: ' + inttostr(i));

    // mount system fonts paths first
    fp := cFontsPaths;

    // let's remove paths from fp and mount them until nothing is left
    while length(fp) > 0 do
        begin
        AddFileLog('lol');
        // search for ;
        i := pos(';', fp);
        // if there is no ; left, read to end
        if i < 1 then
            i := length(fp) + 1;
        // don't mount empty path
        if i > 2 then
            pfsMount(copy(fp, 1, i-1), '/Fonts');
        // remove mounted path from fp
        fp := copy(fp, i+1, length(fp)-i);
        end;

    pfsMountAtRoot(PathPrefix);
    pfsMountAtRoot(UserPathPrefix + '/Data');

    hedgewarsMountPackages;

    // need access to teams and frontend configs (for bindings)
    pfsMountAtRoot(UserPathPrefix);

    if cTestLua then
        begin
            pfsMountAtRoot(ExtractFileDir(cScriptName));
            cScriptName := ExtractFileName(cScriptName);
        end;
end;

procedure freeModule;
begin
    PHYSFS_deinit;
end;

end.
