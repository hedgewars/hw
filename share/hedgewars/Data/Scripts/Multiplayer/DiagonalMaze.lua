
function onPreviewInit()
onGameInit()
end

function onGameInit()
    MapGen = mgDrawn
    TemplateFilter = 0
    local step = 80 + 10 * MapFeatureSize;
    for y = 48,2048,step do
       for x = 48,4048,step do
            if GetRandom(2) == 0 then
                AddPoint(x,y,1)
                AddPoint(x+step,y+step)
            else
                AddPoint(x,y+step,1)
                AddPoint(x+step,y)
            end
        end
    end
    FlushPoints()
end 
