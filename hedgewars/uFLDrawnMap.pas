unit uFLDrawnMap;
interface
uses SDLh;

procedure decodeDrawnMap(data: ansistring; dataSize: Longword; var mapData: PByteArray; var size: Longword);

implementation
uses uUtils, zlib;

procedure decodeDrawnMap(data: ansistring; dataSize: Longword; var mapData: PByteArray; var size: Longword);
var i, cl: Longword;
    ul: uLong;
    s: shortstring;
    r: LongInt;
    compressedBuf, uncompressedData: PByteArray;
begin
    if dataSize = 0 then
    begin
        mapData:= nil;
        size:= 0;
        exit;
    end;

    compressedBuf:= GetMem(dataSize * 3 div 4);
    cl:= 0;
    i:= 1;

    while i < dataSize do
    begin
        if dataSize - i > 240 then
            s:= copy(data, i, 240)
        else
            s:= copy(data, i, dataSize - i + 1);

        s:= DecodeBase64(s);
        Move(s[1], compressedBuf^[cl], byte(s[0]));
        inc(i, 240);
        inc(cl, byte(s[0]));
    end;

    ul:= SDLNet_Read32(compressedBuf);
    uncompressedData:= GetMem(ul);
    r:= uncompress(pBytef(uncompressedData), @ul, @(compressedBuf^[4]), cl - 4);
    FreeMem(compressedBuf, dataSize * 3 div 4);

    if r = Z_OK then
    begin
        mapData:= uncompressedData;
        size:= ul
    end else
    begin
        FreeMem(uncompressedData, ul);
        mapData:= nil;
        size:= 0
    end;
end;

end.
