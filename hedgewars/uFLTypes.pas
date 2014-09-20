unit uFLTypes;
interface

type TIPCMessage = record
                   str: shortstring;
                   len: Longword;
                   buf: Pointer
               end;
    TIPCCallback = procedure (p: pointer; len: byte; msg: PChar);

implementation

end.
