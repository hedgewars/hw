 PointsBuffer = ''  -- A string to accumulate points in
 function AddPoint(x, y, width, erase)
     PointsBuffer = PointsBuffer .. string.char(band(x,0xff00) / 256 , band(x,0xff) , band(y,0xff00) / 256 , band(y,0xff))
     if width then
         width = bor(width,0x80)
         if erase then
             width = bor(width,0x40)
         end
         PointsBuffer = PointsBuffer .. string.char(width)
     else
         PointsBuffer = PointsBuffer .. string.char(0)
     end
     if #PointsBuffer > 245 then
         ParseCommand('draw '..PointsBuffer)
         PointsBuffer = ''
     end
 end
 function FlushPoints()
     if #PointsBuffer > 0 then
         ParseCommand('draw '..PointsBuffer)
         PointsBuffer = ''
     end
 end


function onGameInit()
    MapGen = 2
    TemplateFilter = 0
    for i = 200,2000,600 do
        AddPoint(1,i,63)
        AddPoint(4000,i)
    end

        side = 0
    for i = 0,GetRandom(15)+30 do
        size = GetRandom(15)+3
        --side = GetRandom(4)
        dx = div(size,4)
        maxshift = dx
        dy = dx
        if side == 0 then
            x = 0
            y = GetRandom(2048)
            dy = 0
        elseif side == 1 then
            x = GetRandom(4096)
            y = 0
            dx = 0
        elseif side == 2 then
            x = 4096
            y = GetRandom(2048)
            dx = -dx
            dy = 0
        elseif side == 3 then
            x = GetRandom(4096)
            y = 2048
            dx = 0
            dy = -dy
        elseif side == 4 then
            x = GetRandom(2500)+500
            y = GetRandom(1250)+250
            dx = GetRandom(maxshift*2)-maxshift
            dy = GetRandom(maxshift*2)-maxshift
        end
        length = GetRandom(500)+500
        while (length > 0) and (x > -300) and (y > -300) and (x < 4400) and (y < 2400) do
            length = length - 1
            AddPoint(x,y,size,true)
            x = x + dx
            y = y + dy
            if GetRandom(4) == 0 then
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
        if side < 5 then
            side = side + 1
        else 
            side = 0
        end
    end

    FlushPoints()
end 
