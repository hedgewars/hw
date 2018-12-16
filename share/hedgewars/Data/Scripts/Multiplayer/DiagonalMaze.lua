HedgewarsScriptLoad("/Scripts/Params.lua")
local overrideFeatureSize = true
local mazeScale = 0

function onPreviewInit()
onGameInit()
end

function onParameters()
    parseParams()
    if params["scalemap"] ~= nil then 
        overrideFeatureSize = false 
    end
    if params["mazescale"] ~= nil then
        mazeScale = tonumber(params["mazescale"])
    end
end


function onGameInit()
    local step
    local width 

    MapGen = mgDrawn
    TemplateFilter = 0

    if mazeScale > 0 then
        step = 80 + 10 * mazeScale
        width = 1 + div(math.max(0, mazeScale-12), 6)
    else
        step = 80 + 10 * MapFeatureSize
        width = 1 + div(math.max(0, MapFeatureSize-12), 6)
    end
    -- reset feature size after use, to disable scaling
    if overrideFeatureSize then MapFeatureSize = 12 end
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
