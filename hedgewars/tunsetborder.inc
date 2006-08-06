        begin
        X:= X + dX;
        Y:= Y + dY;
        tx:= round(X);
        ty:= round(Y);
        if ((ty and $FFFFFC00) = 0) and ((tx and $FFFFF800) = 0)and (Land[ty, tx] = $FFFFFF) then
           SetLandPixel(ty, tx)
	end;