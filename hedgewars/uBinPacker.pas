unit uBinPacker;

interface

// implements a maxrects packer with best short side fit heuristic

type Rectangle = record
    x, y, width, height: LongInt;
    UserData: Pointer;
end;

type Size = record
    width, height: LongInt;
    UserData: Pointer;
end;

type PRectangle = ^Rectangle;
type PSize = ^Size;

type RectangleList = record
    data: PRectangle;
    count: LongInt;
    size: LongInt;
end;

type SizeList = record
    data: PSize;
    count: LongInt;
    size: LongInt;
end;

type Atlas = record
    width, height: Longint;
    freeRectangles: RectangleList;
    usedRectangles: RectangleList;
end;

function atlasInsertAdaptive(var a: Atlas; sz: Size; var output: Rectangle): boolean;
function atlasInsertSet(var a: Atlas; var input: SizeList; var outputs: RectangleList): boolean;
function atlasNew(width, height: LongInt): Atlas;
procedure atlasDelete(var a: Atlas);
procedure atlasReset(var a: Atlas);

procedure rectangleListInit(var list: RectangleList);
procedure rectangleListRemoveAt(var list: RectangleList; index: LongInt);
procedure rectangleListAdd(var list: RectangleList; r: Rectangle);
procedure rectangleListClear(var list: RectangleList);
procedure sizeListInit(var list: SizeList);
procedure sizeListRemoveAt(var list: SizeList; index: LongInt);
procedure sizeListAdd(var list: SizeList; s: Size); overload;
procedure sizeListAdd(var list: SizeList; width, height: LongInt; UserData: Pointer); overload;
procedure sizeListClear(var list: SizeList);

implementation

uses Math; // for min/max

procedure rectangleListRemoveAt(var list: RectangleList; index: LongInt);
var
    i: Integer;
begin
    i:=index;
    while (i + 1 < list.count) do
    begin
        list.data[i]:=list.data[i + 1];
        inc(i);
    end;
    dec(list.count);
end;

procedure rectangleListAdd(var list: RectangleList; r: Rectangle);
begin
    if list.count >= list.size then
    begin
        inc(list.size, 512);
        ReAllocMem(list.data, sizeof(Rectangle) * list.size);
    end;
    list.data[list.count]:=r;
    inc(list.count);
end;

procedure rectangleListInit(var list: RectangleList);
begin
    list.data:= nil;
    list.count:= 0;
    list.size:= 0;
end;

procedure rectangleListClear(var list: RectangleList);
begin
    FreeMem(list.data);
    list.count:= 0;
    list.size:= 0;
end;

procedure sizeListRemoveAt(var list: SizeList; index: LongInt);
begin
    list.data[index]:= list.data[list.count - 1];
    dec(list.count);
end;

procedure sizeListAdd(var list: SizeList; s: Size); overload;
begin
    if list.count >= list.size then
    begin
        inc(list.size, 512);
        ReAllocMem(list.data, sizeof(Size) * list.size);
    end;
    list.data[list.count]:=s;
    inc(list.count);
end;

procedure sizeListAdd(var list: SizeList; width, height: LongInt; UserData: Pointer); overload;
var
    sz: Size;
begin
    sz.width:= width;
    sz.height:= height;
    sz.UserData:= UserData;
    sizeListAdd(list, sz);
end;

procedure sizeListInit(var list: SizeList);
begin
    list.data:= nil;
    list.count:= 0;
    list.size:= 0;
end;

procedure sizeListClear(var list: SizeList);
begin
    FreeMem(list.data);
    list.count:= 0;
    list.size:= 0;
end;


function isContainedIn(a, b: Rectangle): boolean;
begin
    isContainedIn:= (a.x >= b.x) and (a.y >= b.y)
                and (a.x + a.width <= b.x + b.width)
                and (a.y + a.height <= b.y + b.height);
end;

function findPositionForNewNodeBestShortSideFit(var list: RectangleList; width, height: LongInt; 
     var bestShortSideFit, bestLongSideFit: LongInt): Rectangle;
var
    bestNode: Rectangle;
    i: Integer;
    ri: Rectangle;
    leftoverHoriz, leftoverVert, shortSideFit, longSideFit: Longint;
begin
    bestNode.x:= 0;
    bestNode.y:= 0;
    bestNode.width:= 0;
    bestNode.height:= 0;
    bestShortSideFit:= $7FFFFFFF;

    for i:=0 to pred(list.count) do
    begin
        ri:= list.data[i];

        // Try to place the rectangle in upright (non-flipped) orientation.
        if (ri.width >= width) and (ri.height >= height) then
        begin
            leftoverHoriz:= Abs(ri.width - width);
            leftoverVert:= Abs(ri.height - height);
            shortSideFit:= Min(leftoverHoriz, leftoverVert);
            longSideFit:= Max(leftoverHoriz, leftoverVert);

            if (shortSideFit < bestShortSideFit) or
              ((shortSideFit = bestShortSideFit) and (longSideFit < bestLongSideFit)) then
            begin
                bestNode.x:= ri.x;
                bestNode.y:= ri.y;
                bestNode.width:= width;
                bestNode.height:= height;
                bestShortSideFit:= shortSideFit;
                bestLongSideFit:= longSideFit;
            end;
        end;

        if (ri.width >= height) and (ri.height >= width) then
        begin
            leftoverHoriz:= Abs(ri.width - height);
            leftoverVert:= Abs(ri.height - width);
            shortSideFit:= Min(leftoverHoriz, leftoverVert);
            longSideFit:= Max(leftoverHoriz, leftoverVert);

            if (shortSideFit < bestShortSideFit) or
              ((shortSideFit = bestShortSideFit) and (longSideFit < bestLongSideFit)) then
            begin
                bestNode.x:= ri.x;
                bestNode.y:= ri.y;
                bestNode.width:= height;
                bestNode.height:= width;
                bestShortSideFit:= shortSideFit;
                bestLongSideFit:= longSideFit;
            end;
        end;
    end;

    findPositionForNewNodeBestShortSideFit:= bestNode;
end;

function scoreRect(var list: RectangleList; width, height: LongInt; var score1, score2: LongInt): Rectangle;
var
    newNode: Rectangle;
begin
    newNode:= findPositionForNewNodeBestShortSideFit(list, width, height, score1, score2);

    // Cannot fit the current rectangle.
    if newNode.height = 0 then
    begin
        score1:= $7FFFFFFF;
        score2:= $7FFFFFFF;
    end;

    scoreRect:= newNode;
end;

function splitFreeNode(var freeRectangles: RectangleList; freeNode, usedNode: Rectangle): boolean;
var
    newNode: Rectangle;
begin
    // Test with SAT if the rectangles even intersect.
    if (usedNode.x >= freeNode.x + freeNode.width) or (usedNode.x + usedNode.width <= freeNode.x) or
       (usedNode.y >= freeNode.y + freeNode.height) or (usedNode.y + usedNode.height <= freeNode.y) then
    begin
        splitFreeNode:=false;
        exit;
    end;

    if (usedNode.x < freeNode.x + freeNode.width) and (usedNode.x + usedNode.width > freeNode.x) then
    begin
        // New node at the top side of the used node.
        if (usedNode.y > freeNode.y) and (usedNode.y < freeNode.y + freeNode.height) then
        begin
            newNode:= freeNode;
            newNode.height:= usedNode.y - newNode.y;
            rectangleListAdd(freeRectangles, newNode);
        end;

        // New node at the bottom side of the used node.
        if (usedNode.y + usedNode.height < freeNode.y + freeNode.height) then
        begin
            newNode:= freeNode;
            newNode.y:= usedNode.y + usedNode.height;
            newNode.height:= freeNode.y + freeNode.height - (usedNode.y + usedNode.height);
            rectangleListAdd(freeRectangles, newNode);
        end;
    end;

    if (usedNode.y < freeNode.y + freeNode.height) and (usedNode.y + usedNode.height > freeNode.y) then
    begin
        // New node at the left side of the used node.
        if (usedNode.x > freeNode.x) and (usedNode.y < freeNode.y + freeNode.width) then
        begin
            newNode:= freeNode;
            newNode.width:= usedNode.x - newNode.x;
            rectangleListAdd(freeRectangles, newNode);
        end;

        // New node at the right side of the used node.
        if (usedNode.x + usedNode.width < freeNode.x + freeNode.width) then
        begin
            newNode:= freeNode;
            newNode.x:= usedNode.x + usedNode.width;
            newNode.width:= freeNode.x + freeNode.width - (usedNode.x + usedNode.width);
            rectangleListAdd(freeRectangles, newNode);
        end;
  end;

  splitFreeNode:= true;
end;

procedure pruneFreeList(var freeRectangles: RectangleList);
var
  i, j: LongInt;
begin
    // Go through each pair and remove any rectangle that is redundant.
    i:= 0;
    while i < freeRectangles.count do
    begin
        j:= i + 1;
        while j < freeRectangles.count do
        begin  
            if (isContainedIn(freeRectangles.data[i], freeRectangles.data[j])) then
            begin
                rectangleListRemoveAt(freeRectangles, i);
                dec(i);
                break;
            end;

            if (isContainedIn(freeRectangles.data[j], freeRectangles.data[i])) then
                rectangleListRemoveAt(freeRectangles, j)
            else
                inc(j);
        end;
        inc(i);
    end;
end;

function atlasInsertAdaptive(var a: Atlas; sz: Size; var output: Rectangle): boolean;
var
    newNode: Rectangle;
    score1, score2: LongInt;
    numRectanglesToProcess: LongInt;
    i: LongInt;
begin
    newNode:= findPositionForNewNodeBestShortSideFit(a.freeRectangles, sz.width, sz.height, score1, score2);
    if newNode.height = 0 then
    begin
        output:= newNode;
        output.UserData:= nil;
        atlasInsertAdaptive:= false;
        exit;
    end;

    numRectanglesToProcess:= a.freeRectangles.count;

    i:=0;
    while i < numRectanglesToProcess do
    begin
        if splitFreeNode(a.freeRectangles, a.freeRectangles.data[i], newNode) then
        begin
            rectangleListRemoveAt(a.freeRectangles, i);
            dec(numRectanglesToProcess);
        end
        else
            inc(i);
    end;
    
    pruneFreeList(a.freeRectangles);
    newNode.UserData:= sz.UserData;
    rectangleListAdd(a.usedRectangles, newNode);
    output:= newNode;
    atlasInsertAdaptive:= true;
end;

procedure placeRect(var a: Atlas; node: Rectangle);
var
    numRectanglesToProcess: LongInt;
    i: LongInt;
begin
    numRectanglesToProcess:= a.freeRectangles.Count;

    i:= 0;
    while i < numRectanglesToProcess do
    begin
        if not splitFreeNode(a.freeRectangles, a.freeRectangles.data[i], node) then
            inc(i)
        else
        begin
            rectangleListRemoveAt(a.freeRectangles, i);
            dec(numRectanglesToProcess);
        end;
    end;

    pruneFreeList(a.freeRectangles);
    rectangleListAdd(a.usedRectangles, node);
end;


function atlasInsertSet(var a: Atlas; var input: SizeList; var outputs: RectangleList): boolean;
var
    bestScore1, bestScore2, bestRectIndex: LongInt;
    score1, score2: LongInt;
    bestNode, newNode: Rectangle;
    i: LongInt;
    sz: Size;
begin
    atlasInsertSet:= false;

    while input.count > 0 do
    begin
        bestScore1:= $7FFFFFFF;
        bestScore2:= $7FFFFFFF;
        bestRectIndex:= -1;
    
        for i:=0 to pred(input.count) do
        begin
            sz:= input.data[i];
            newNode:= scoreRect(a.freeRectangles, sz.width, sz.height, score1, score2);

            if (score1 >= bestScore1) and ((score1 <> bestScore1) or (score2 >= bestScore2)) then
                continue;

            bestScore1:= score1;
            bestScore2:= score2;
            bestNode:= newNode;
            bestRectIndex:= i;
        end;

        if bestRectIndex = -1 then
            exit;

        bestNode.UserData:= input.data[bestRectIndex].UserData;
        placeRect(a, bestNode);
        rectangleListAdd(outputs, bestNode);
        sizeListRemoveAt(input, bestRectIndex);
    end;
    atlasInsertSet:= true;
end;

function atlasNew(width, height: LongInt): Atlas;
var
    a: Atlas;
    r: Rectangle;
begin
    rectangleListInit(a.freeRectangles);
    rectangleListInit(a.usedRectangles);

    a.width:= width;
    a.height:= height;
    r.x:= 0;
    r.y:= 0;
    r.width:= width;
    r.height:= height;
    rectangleListAdd(a.freeRectangles, r);

    atlasNew:=a;
end;

procedure atlasDelete(var a: atlas);
begin
    rectangleListClear(a.freeRectangles);
    rectangleListClear(a.usedRectangles);
end;

procedure atlasReset(var a: atlas);
begin
    atlasDelete(a);
    a:=atlasNew(a.width, a.height);
end;

begin
end.
