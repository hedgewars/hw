local PointsBuffer = ''  -- A string to accumulate points in

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
