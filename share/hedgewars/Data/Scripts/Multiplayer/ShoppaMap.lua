HedgewarsScriptLoad("/Scripts/Params.lua")

local ObjectList = {}

-- Overall padding for roping freedom
local Padding = 430
-- If true, rope assumes team color
local TeamRope = false

function onParameters()
    parseParams()
    if params["teamrope"] ~= nil then
        TeamRope = true
    end
end

function onGearAdd(gear)
    if GetGearType(gear) == gtRope and TeamRope then
        SetTag(gear,1)
        SetGearValues(gear,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,GetClanColor(GetHogClan(CurrentHedgehog)))
    end
end

-- This could probably use less points and more precision
-- 700x700 for object space
function DrawStar(x, y, d, f)
    -- default scale is 700x700 or so
    local s = 700
    local i = 0
    local j = 0
    if not(d == 1) then s = div(s,d) end
    if NoOverlap(x,y,s,s) then
        AddCollision(x,y,s,s)
        if not(d == 1) then
            i = 6-d
            j = math.min(div(5,d),1)
            -- centre
            AddPoint(x,y,div(20,d))
            -- arms
            AddPoint(x-div(325,d),y-f*div(108,d),2)
            AddPoint(x+div(325,d),y-f*div(108,d))
            AddPoint(x-div(205,d),y+f*div(270,d))
            AddPoint(x,y-f*div(345,d))
            AddPoint(x+div(205,d),y+f*div(270,d))
            AddPoint(x-div(325,d),y-f*div(108,d))
            if d < 4 then
            -- fill in arm 1
            AddPoint(x-div(275,d),y-f*div(92,d),i)
            AddPoint(x-div(50,d),y-f*div(92,d))
            AddPoint(x-div(105,d),y+f*div(25,d))
            AddPoint(x-div(250,d),y-f*div(80,d))
            AddPoint(x-div(115,d),y-f*div(70,d))
            AddPoint(x-div(130,d),y-f*div(25,d))
            AddPoint(x-div(175,d),y-f*div(60,d))
            -- fill in arm 2
            AddPoint(x+div(275,d),y-f*div(92,d),i)
            AddPoint(x+div(50,d),y-f*div(92,d))
            AddPoint(x+div(105,d),y+f*div(25,d))
            AddPoint(x+div(250,d),y-f*div(80,d))
            AddPoint(x+div(115,d),y-f*div(70,d))
            AddPoint(x+div(130,d),y-f*div(25,d))
            AddPoint(x+div(175,d),y-f*div(60,d))
            -- fill in arm 3
            AddPoint(x-div(175,d),y+f*div(230,d),i)
            AddPoint(x-div(110,d),y+f*div(60,d))
            AddPoint(x,y+f*div(120,d))
            AddPoint(x-div(155,d),y+f*div(215,d))
            AddPoint(x-div(105,d),y+f*div(95,d))
            AddPoint(x-div(60,d),y+f*div(130,d))
            AddPoint(x-div(85,d),y+f*div(155,d),j)
            -- fill in arm 4
            AddPoint(x,y-f*div(300,d),3)
            AddPoint(x+div(50,d),y-f*div(125,d))
            AddPoint(x-div(50,d),y-f*div(125,d))
            AddPoint(x,y-f*div(270,d))
            AddPoint(x-div(40,d),y-f*div(160,d))
            AddPoint(x+div(40,d),y-f*div(160,d))
            AddPoint(x,y-f*div(195,d),j)
            -- fill in arm 5
            AddPoint(x+div(175,d),y+f*div(230,d),i)
            AddPoint(x+div(110,d),y+f*div(60,d))
            AddPoint(x,y+f*div(120,d))
            AddPoint(x+div(155,d),y+f*div(215,d))
            AddPoint(x+div(105,d),y+f*div(95,d))
            AddPoint(x+div(60,d),y+f*div(130,d))
            AddPoint(x+div(85,d),y+f*div(155,d),j)
            end
        else
            -- centre
            AddPoint(x,y,20)
            -- arms
            AddPoint(x-325,y-f*108,1)
            AddPoint(x+325,y-f*108)
            AddPoint(x-205,y+f*270)
            AddPoint(x,y-f*345)
            AddPoint(x+205,y+f*270)
            AddPoint(x-325,y-f*108)
            -- fill in arm 1
            AddPoint(x-275,y-f*92,4)
            AddPoint(x-50,y-f*92)
            AddPoint(x-105,y+f*25)
            AddPoint(x-250,y-f*80)
            AddPoint(x-115,y-f*70)
            AddPoint(x-130,y-f*25)
            AddPoint(x-175,y-f*60)
            -- fill in arm 2
            AddPoint(x+275,y-f*92,4)
            AddPoint(x+50,y-f*92)
            AddPoint(x+105,y+f*25)
            AddPoint(x+250,y-f*80)
            AddPoint(x+115,y-f*70)
            AddPoint(x+130,y-f*25)
            AddPoint(x+175,y-f*60)
            -- fill in arm 3
            AddPoint(x-175,y+f*230,4)
            AddPoint(x-110,y+f*60)
            AddPoint(x-10,y+f*120)
            AddPoint(x-155,y+f*215)
            AddPoint(x-105,y+f*95)
            AddPoint(x-60,y+f*130)
            AddPoint(x-85,y+f*155,5)
            -- fill in arm 4
            AddPoint(x,y-f*300,3)
            AddPoint(x+50,y-f*125)
            AddPoint(x-50,y-f*125)
            AddPoint(x,y-f*270)
            AddPoint(x-40,y-f*160)
            AddPoint(x+40,y-f*160)
            AddPoint(x,y-f*195,5)
            -- fill in arm 5
            AddPoint(x+175,y+f*230,4)
            AddPoint(x+110,y+f*60)
            AddPoint(x+10,y+f*120)
            AddPoint(x+155,y+f*215)
            AddPoint(x+105,y+f*95)
            AddPoint(x+60,y+f*130)
            AddPoint(x+85,y+f*155,5)
        end
        return true
    else
        return false
    end
end

-- well. this was easy
function DrawCircle(x, y, w)
    if NoOverlap(x,y,w*10+6,w*10+6) then
        AddCollision(x,y,w*10+6,w*10+6)
        AddPoint(x,y,w)
        return true
    else
        return false
    end
end

function DrawCrescent(x, y, w, s)
    local b = div(w*(GetRandom(4)+1)*10+6,6)
    
    if NoOverlap(x,y,w*10+6,w*10+6) then
        AddCollision(x,y,w*10+6,w*10+6)
        AddPoint(x,y,w)
        if s then -- side
            if GetRandom(1) == 0 then
                b = b*-1
            end
            AddPoint(x-b,y,w,true)
        else -- top
            AddPoint(x,y-b,w,true)
        end
        return true
    else
        return false
    end
end

function DrawCones(x,w,h,c)
    local i = 0
    local y = 2048-h
    local hw = div(w,2)
    if NoOverlap(x+div(w*c,2),y+div(h,2),w*c,h) then
        AddCollision(x+div(w*c,2),y+div(h,2),w*c,h)
        x = x + hw
        for i = 1,c do -- I'm guessing outlining is slightly more efficient than fanning at 16px brush
            AddPoint(x,y,1)
            AddPoint(x-hw+8,2048)
            AddPoint(x+hw-8,2048)
            AddPoint(x,y)
            for j = x-hw+25,x+hw,34 do
                AddPoint(x,y+30,3)
                AddPoint(j,2048)
            end
            if GetRandom(2)==0 then
                AddPoint(x,y-20,8)
            end
            x = x + w
        end
    else
        return false
    end
    
end

function DrawPlateau(x,y,l,t,b)
    local bo = 0
    local to = 0
    local bSucc = false
    local tSucc = false
    if NoOverlapXY(x-28,y-28,x+l+28,y+l+28) then
        AddPoint(x,y,5)
        AddPoint(x+l,y)

        to = GetRandom(6)
        if not(to==0) then
            if GetRandom(2)==0 then
                to = div(l,to)
            else
                to = l-div(l,to)
            end
        end
        if t>0 and NoOverlapXY(x+to-28,y-t-28,x+to+28,y+28) then
            AddPoint(x+to,y-t,5)
            AddPoint(x+to,y)
            if GetRandom(2)==0 then
                AddPoint(x+to,y-t+75,20)
            else -- square off
                AddPoint(x+to-20,y-t,1)
                AddPoint(x+to-20,y-t-20)
                AddPoint(x+to+20,y-t-20)
                AddPoint(x+to+20,y-t)
            end
            tSucc = true
        end

        if to > 120 and GetRandom(2)==0 then -- left bumper
            AddPoint(x+15,y-20,9)
        else -- square off
            --AddPoint(x-50,y,2)
            AddPoint(x,y+20,1)
            AddPoint(x-20,y+20)
            AddPoint(x-20,y-20)
            AddPoint(x,y-20)
        end
        if to < (l-120) and GetRandom(2)==0 then -- right bumper
            AddPoint(x+l-15,y-20,9)
        else -- square off
            --AddPoint(x+l+50,y,2)
            AddPoint(x+l,y+20,1)
            AddPoint(x+l+20,y+20)
            AddPoint(x+l+20,y-20)
            AddPoint(x+l,y-20)
        end
        bo = GetRandom(6)
        if not(bo == 0) then
            if GetRandom(2)==0 then
                bo = div(l,bo)
            else
                bo = l-div(l,bo)
            end
        end
        -- still consider a success even if we can't place this one.  Might need to return more than true/false
        if b>0 and NoOverlapXY(x+bo-28,y-28,x+bo+28,y+b+28) then
            AddPoint(x+bo,y,5)
            AddPoint(x+bo,y+b)
            if GetRandom(2)==0 then
                AddPoint(x+bo,y+b-75,20)
            else -- square off
                AddPoint(x+bo-20,y+b,1)
                AddPoint(x+bo-20,y+b+20)
                AddPoint(x+bo+20,y+b+20)
                AddPoint(x+bo+20,y+b)
            end
            bSucc = true
        end
        if bSucc then AddCollisionXY(x+bo-28,y-28,x+bo+28,y+b+28) end
        if tSucc then AddCollisionXY(x+to-28,y-t-28,x+to+28,y+28) end
        AddCollisionXY(x-28,y-28,x+l+28,y+28) 
        return true
    else
        return false
    end
end

function AddCollision(x,y,w,h)
    table.insert(ObjectList,{x-div(w+Padding,2),
                             y-div(h+Padding,2),
                             x+div(w+Padding,2),
                             y+div(h+Padding,2)})
end

function AddCollisionXY(x,y,x2,y2)
    table.insert(ObjectList,{x-div(Padding,2),
                             y-div(Padding,2),
                             x2+div(Padding,2),
                             y2+div(Padding,2)})
end

-- bounding box check
function NoOverlap(x,y,w,h)
    w = w
    h = h
    x = x-div(w,2)
    y = y-div(h,2)
    return NoOverlapXY(x,y,x+w,y+h)
end
function NoOverlapXY(x,y,x2,y2)
    local i = 1
    local l = table.getn(ObjectList)
    local ox = 0
    local oy = 0
    local ox2 = 0
    local oy2 = 0
    while i<=l do
        ox = ObjectList[i][1]
        oy = ObjectList[i][2]
        ox2 = ObjectList[i][3]
        oy2 = ObjectList[i][4]
        if x < ox2 and ox < x2 and y < oy2 and oy < y2 then
            return false
        end
        i=i+1
    end
    return true
end

function onPreviewInit()
    onGameInit()
end

function onGameInit()
    -- Calculate padding, determined  by map feature size
    if MapFeatureSize <= 20 then
        -- 10 .. 710. Step size=35
        Padding = 10 + MapFeatureSize * 35
    else
        -- 780 .. 1060. Step size=70
        Padding = 710 + (MapFeatureSize-20) * 70
    end

    MapGen = mgDrawn
    TemplateFilter = 0
    local TotGen = 0
    local Tries = 0
    local i = 0
    local l = 0
    local x = 0
    local y = 0
    local w = 0
    local h = 0 
    if GetGameFlag(gfSolidLand) then EnableGameFlags(gfShoppaBorder) end
    if not GetGameFlag(gfBottomBorder) and GetRandom(2) == 0 then
        AddPoint(-50,2010,7)
        AddPoint(4150,2010)
        for i = 0,GetRandom(3) do
            x = GetRandom(4096)
            w = GetRandom(40)+10
            AddPoint(x,2200,w,true)
            AddPoint(x,1900)
            table.insert(ObjectList,{x-div(w*9,2),
                                     2010-div(100,2),
                                     x+div(w*9,2),
                                     2010+div(100,2)})
        end
    end
        
    if GetRandom(2) == 0 then
        l = GetRandom(3)+1
        w = GetRandom(200)+200
        h = GetRandom(350)+200
        x = GetRandom(4096-w*l)
        DrawCones(x,w,h,l)
        --if DrawCones(x,w,h,l) then TotGen = TotGen+1
    end
    if GetRandom(2) == 0 then
        for i = 1,GetRandom(5)+1 do
            w = GetRandom(35)+15
            x = GetRandom(4096-w*12)+w
	    if GetRandom(2)==0 then
		y = 2048-GetRandom(w*10+6)
	    else
	    	y = 2048
	    end
           -- if AddPoint(x,y,w) then TotGetn = TotGen+1
           DrawCircle(x,y,w)
        end
    end
    if GetRandom(2)==0 then
        x = GetRandom(3300)+382
        y = GetRandom(1300)+382
        if DrawStar(x,y, 1, 1+GetRandom(2)*-2) then
            TotGen = TotGen+1
        end
    end

    while (TotGen < 6) and (Tries < 100) do
        l = GetRandom(1000-Tries*10)+300
        x = GetRandom(3900-l)+100
        y = GetRandom(1900)+100
        if GetRandom(2)==0 then b = GetRandom(800)+300
        else b = 0 end
        if GetRandom(2)==0 then t = GetRandom(800)+300
        else t = 0 end
        if y-t < 50 then t = y - 50 end
        if t < 200 then t = 0 end
        if DrawPlateau(x,y,l,t,b) then
            TotGen = TotGen+1
        end
        Tries = Tries + 1
    end
    Tries = 0
    while (TotGen < 17) and (Tries < 1000) do
        if Tries < 500 and GetRandom(2)==0 then
            x = GetRandom(3300)+350
            y = GetRandom(1300)+350
            if DrawStar(x,y, 1, 1+GetRandom(2)*-2) then
                TotGen = TotGen+1
            end
        else
            if Tries > 500 then d = GetRandom(2)+3
            else d = GetRandom(3)+2 end
            x = GetRandom(4000-div(764,d))+div(764,d*2)
            y = GetRandom(1300-div(764,d))+div(764,d*2)
            if DrawStar(x,y, d, 1+GetRandom(2)*-2) then
                TotGen = TotGen+1
            end
        end
        w = GetRandom(35-div(Tries,29))+15
        x = GetRandom(4050-w*20)+w*10
        y = GetRandom(2000-w*20)+w*10
        if DrawCircle(x,y,w) then
            TotGen = TotGen+1
        end
        w = GetRandom(35-div(Tries,29))+5
        x = GetRandom(4050-w*20)+w*10
        y = GetRandom(2000-w*20)+w*10
        if DrawCrescent(x,y,w,GetRandom(2)==0) then
            TotGen = TotGen+1
        end
        Tries = Tries + 1
    end
    FlushPoints()
end 
