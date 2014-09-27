unit uFLTypes;
interface

type
    TMessageType = (mtPreview);

    TIPCMessage = record
                   str: shortstring;
                   len: Longword;
                   buf: Pointer
               end;
    TIPCCallback = procedure (p: pointer; msg: PChar; len: Longword);
    TGUICallback = procedure (p: pointer; msgType: TMessageType; msg: PChar; len: Longword); cdecl;

implementation

end.
