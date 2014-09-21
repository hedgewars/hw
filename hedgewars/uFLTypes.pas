unit uFLTypes;
interface

type TIPCMessage = record
                   str: shortstring;
                   len: Longword;
                   buf: Pointer
               end;
    TIPCCallback = procedure (p: pointer; msg: PChar; len: Longword);

implementation

end.
