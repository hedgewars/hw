HedgewarsScriptLoad("/Scripts/Utils.lua")

function onPreviewInit()
    onGameInit()
end

function onGameInit()
    MapGen = mgDrawn
    TemplateFilter = 0
    fillMap(false)
    side = 0
    for i = 0,1+MapFeatureSize*2 do
        if side > 3 then 
            size = GetRandom(4)+4
        else
            size = GetRandom(12)+4
        end
        --side = GetRandom(4)
        dx = div(size,4)
        maxshift = dx
        dy = dx
        if side == 0 then
            x = 0
            y = GetRandom(2048-size*4)+size*2
            dy = 0
        elseif side == 1 then
            x = GetRandom(4096-size*4)+size*2
            y = 0
            dx = 0
        elseif side == 2 then
            x = 4096
            y = GetRandom(2048-size*4)+size*2
            dx = -dx
            dy = 0
        elseif side == 3 then
            x = GetRandom(4096-size*4)+size*2
            y = 2048
            dx = 0
            dy = -dy
        elseif side > 3 then
            x = GetRandom(2500)+500
            y = GetRandom(1250)+250
            dx = GetRandom(maxshift*2)-maxshift
            dy = GetRandom(maxshift*2)-maxshift
        end
        length = GetRandom(500-size*25)+600
        while (length > 0) and (x > -300) and (y > -300) and (x < 4400) and (y < 2400) do
            length = length - 1
            AddPoint(x,y,size,true)
            x = x + dx
            y = y + dy
            if GetRandom(8) == 0 then
                shift = GetRandom(10)-5
                if (shift > 0) and (dx < maxshift) then
                    dx = dx + shift
                elseif (shift < 0) and (dx > -maxshift) then
                    dx = dx + shift
                end
                shift = GetRandom(10)-5
                if (shift > 0) and (dy < maxshift) then
                    dy = dy + shift
                elseif (shift < 0) and (dy > -maxshift) then
                    dy = dy + shift
                end
            end
        end
        if side < 6 then
            side = side + 1
        else 
            side = 0
        end
    end

    FlushPoints()
end 
