
function onPreviewInit()
onGameInit()
end

function onGameInit()
    MapGen = mgDrawn
    TemplateFilter = 0
    local step = 80 + 10 * MapFeatureSize
    local width = 1 + div(math.max(0, MapFeatureSize-12), 6)
    -- center maze
    local xoff = div((4000 % step), 2)
    for y = 48,2048,step do
       for x = 48+xoff,4048-step,step do
            if GetRandom(2) == 0 then
                AddPoint(x,y,width)
                AddPoint(x+step,y+step)
            else
                AddPoint(x,y+step,width)
                AddPoint(x+step,y)
            end
        end
    end
    FlushPoints()
end 
