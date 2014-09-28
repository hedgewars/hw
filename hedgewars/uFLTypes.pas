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

    TGameType = (gtPreview, gtLocal);
    THedgehog = record
            name: shortstring;
            hat: shortstring;
            end;
    TTeam = record
            teamName: shortstring;
            flag: shortstring;
            graveName: shortstring;
            fortName: shortstring;
            owner: shortstring;
            color: shortstring;
            extDriven: boolean;
            botLevel: Longword;
            hedgehogs: array[0..7] of THedgehog;
            hogsNumber: Longword;
            end;

implementation

end.
