        begin
        X:= X + dX;
        Y:= Y + dY;
        tx:= hwRound(X);
        ty:= hwRound(Y);
        if ((ty and $FFFFFC00) = 0) and ((tx and $FFFFF800) = 0)and (Land[ty, tx] = $FFFFFF) then
           SetLandPixel(ty, tx)
	end;
