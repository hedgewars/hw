{$INCLUDE "options.inc"}

unit uPhysFSLayer;

interface
uses SDLh, LuaPas;

const PhysfsLibName = {$IFDEF PHYSFS_INTERNAL}'libhwphysfs'{$ELSE}'libphysfs'{$ENDIF};
const PhyslayerLibName = 'libphyslayer';

{$IFNDEF WIN32}
    {$linklib physfs}
    {$linklib physlayer}
{$ENDIF}

procedure initModule(localPrefix, userPrefix: PChar);
procedure freeModule;

type PFSFile = pointer;

function rwopsOpenRead(fname: shortstring): PSDL_RWops;
function rwopsOpenWrite(fname: shortstring): PSDL_RWops;

function pfsOpenRead(fname: shortstring): PFSFile;
function pfsOpenWrite(fname: shortstring): PFSFile;
function pfsFlush(f: PFSFile): boolean;
function pfsClose(f: PFSFile): boolean;

procedure pfsReadLn(f: PFSFile; var s: shortstring);
procedure pfsReadLnA(f: PFSFile; var s: ansistring);
procedure pfsWriteLn(f: PFSFile; s: shortstring);
function pfsBlockRead(f: PFSFile; buf: pointer; size: Int64): Int64;
function pfsEOF(f: PFSFile): boolean;

function pfsExists(fname: shortstring): boolean;
function pfsMakeDir(path: shortstring): boolean;

function  physfsReader(L: Plua_State; f: PFSFile; sz: Psize_t) : PChar; cdecl; external PhyslayerLibName;
procedure physfsReaderSetBuffer(buf: pointer); cdecl; external PhyslayerLibName;
procedure hedgewarsMountPackage(filename: PChar); cdecl; external PhyslayerLibName;

implementation
uses uConsts, uUtils, uVariables{$IFNDEF PAS2C}, sysutils{$ELSE}, physfs{$ENDIF};

function PHYSFSRWOPS_openRead(fname: PChar): PSDL_RWops; cdecl; external PhyslayerLibName;
function PHYSFSRWOPS_openWrite(fname: PChar): PSDL_RWops; cdecl; external PhyslayerLibName;
procedure hedgewarsMountPackages(); cdecl; external PhyslayerLibName;
{$IFNDEF PAS2C}
function PHYSFS_init(argv0: PChar): LongInt; cdecl; external PhysfsLibName;
function PHYSFS_deinit(): LongInt; cdecl; external PhysfsLibName;
function PHYSFS_mount(newDir, mountPoint: PChar; appendToPath: LongBool) : LongBool; cdecl; external PhysfsLibName;
function PHYSFS_openRead(fname: PChar): PFSFile; cdecl; external PhysfsLibName;
function PHYSFS_openWrite(fname: PChar): PFSFile; cdecl; external PhysfsLibName;
function PHYSFS_setWriteDir(path: PChar): LongBool; cdecl; external PhysfsLibName;
function PHYSFS_eof(f: PFSFile): LongBool; cdecl; external PhysfsLibName;
function PHYSFS_readBytes(f: PFSFile; buffer: pointer; len: Int64): Int64; cdecl; external PhysfsLibName;
function PHYSFS_writeBytes(f: PFSFile; buffer: pointer; len: Int64): Int64; cdecl; external PhysfsLibName;
function PHYSFS_seek(f: PFSFile; pos: QWord): LongBool; cdecl; external PhysfsLibName;
function PHYSFS_flush(f: PFSFile): LongBool; cdecl; external PhysfsLibName;
function PHYSFS_close(f: PFSFile): LongBool; cdecl; external PhysfsLibName;
function PHYSFS_exists(fname: PChar): LongBool; cdecl; external PhysfsLibName;
function PHYSFS_mkdir(path: PChar): LongBool; cdecl; external PhysfsLibName;
function PHYSFS_getLastError(): PChar; cdecl; external PhysfsLibName;
function PHYSFS_enumerateFiles(dir: PChar): PPChar; cdecl; external PhysfsLibName;
procedure PHYSFS_freeList(list: PPChar); cdecl; external PhysfsLibName;
{$ELSE}
function PHYSFS_readBytes(f: PFSFile; buffer: pointer; len: Int64): Int64;
begin
    PHYSFS_readBytes:= PHYSFS_read(f, buffer, 1, len);
end;
{$ENDIF}

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

function pfsOpenWrite(fname: shortstring): PFSFile;
begin
    exit(PHYSFS_openWrite(Str2PChar(fname)));
end;

function pfsEOF(f: PFSFile): boolean;
begin
    exit(PHYSFS_eof(f))
end;

function pfsFlush(f: PFSFile): boolean;
begin
    exit(PHYSFS_flush(f))
end;

function pfsClose(f: PFSFile): boolean;
begin
    exit(PHYSFS_close(f))
end;

function pfsExists(fname: shortstring): boolean;
begin
    exit(PHYSFS_exists(Str2PChar(fname)))
end;

function pfsMakeDir(path: shortstring): boolean;
begin
    exit(PHYSFS_mkdir(Str2PChar(path)))
end;

function pfsEnumerateFiles(dir: shortstring): PPChar;
begin
    exit(PHYSFS_enumerateFiles(Str2PChar(dir)))
end;

procedure pfsFreeList(list: PPChar);
begin
    PHYSFS_freeList(list)
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
            s:= s + ansistring(b);
            b[0]:= #0
            end
        end;

s:= s + ansistring(b)
end;

procedure pfsWriteLn(f: PFSFile; s: shortstring);
var c: char;
begin
    c:= #10;
    PHYSFS_writeBytes(f, @s[1], byte(s[0]));
    PHYSFS_writeBytes(f, @c, 1);
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

procedure pfsMount(path: ansistring; mountpoint: PChar);
begin
    if PHYSFS_mount(PChar(path), mountpoint, false) then
        //AddFileLog('[PhysFS] mount ' + shortstring(path) + ' at ' + shortstring(mountpoint) + ' : ok')
    else
        //AddFileLog('[PhysFS] mount ' + shortstring(path) + ' at ' + shortstring(mountpoint) + ' : FAILED ("' + shortstring(PHYSFS_getLastError()) + '")');
end;

procedure pfsMountAtRoot(path: ansistring);
begin
    pfsMount(path, PChar(_S'/'));
end;

procedure initModule(localPrefix, userPrefix: PChar);
var i: LongInt;
    cPhysfsId: shortstring;
{$IFNDEF MOBILE}
    fp: PChar;
{$ENDIF}
begin
{$IFDEF HWLIBRARY}
    //TODO: http://icculus.org/pipermail/physfs/2011-August/001006.html
    cPhysfsId:= GetCurrentDir() + {$IFDEF DARWIN}{$IFNDEF IPHONEOS}'/Hedgewars.app/Contents/MacOS/' + {$ENDIF}{$ENDIF} ' hedgewars';
{$ELSE}
    cPhysfsId:= ParamStr(0);
{$ENDIF}

    i:= PHYSFS_init(Str2PChar(cPhysfsId));
    AddFileLog('[PhysFS] init: ' + inttostr(i));

{$IFNDEF MOBILE}
    // mount system fonts paths first
    for i:= low(cFontsPaths) to high(cFontsPaths) do
        begin
            fp := cFontsPaths[i];
            if fp <> nil then
                pfsMount(ansistring(fp), _P'/Fonts');
        end;
{$ENDIF}

    pfsMountAtRoot(localPrefix);
    pfsMount(userPrefix, PChar('/Config'));
    pfsMakeDir('/Config/Data');
    pfsMakeDir('/Config/Logs');
    pfsMountAtRoot(userPrefix + ansistring('/Data'));
    PHYSFS_setWriteDir(userPrefix);

    hedgewarsMountPackages;

    // need access to teams and frontend configs (for bindings)
    pfsMountAtRoot(userPrefix);

    if cTestLua then
        begin
            pfsMountAtRoot(ansistring(ExtractFileDir(cScriptName)));
            cScriptName := ExtractFileName(cScriptName);
        end;
end;

procedure freeModule;
begin
    PHYSFS_deinit;
end;

end.
