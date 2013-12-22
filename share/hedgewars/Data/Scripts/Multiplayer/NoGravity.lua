function onNewTurn()
    SetGravity(0)
end

function onGameTick20()
    if TurnTimeLeft < 20 then
        SetGravity(100)
    end
end
