
function onPreviewInit()
onGameInit()
end

function onGameInit()
    MapGen = mgDrawn
    TemplateFilter = 0
    for y = 48,2048,200 do
       for x = 48,4048,200 do
            if GetRandom(2) == 0 then
                AddPoint(x,y,1)
                AddPoint(x+200,y+200)
            else
                AddPoint(x,y+200,1)
                AddPoint(x+200,y)
            end
        end
    end
    FlushPoints()
end 
