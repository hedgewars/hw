        begin
        X:= X + dX;
        Y:= Y + dY;
        tx:= round(X);
        ty:= round(Y);
        if ((ty and $FFFFFC00) = 0) and ((tx and $FFFFF800) = 0)and (Land[ty, tx] <> 0) then
        case LandSurface.format.BytesPerPixel of
             1: ;
             2: PWord(p + LandSurface.pitch * ty + tx * 2)^:= cExplosionBorderColor;
             3: begin
                PByte(p + LandSurface.pitch * ty + tx * 3 + 0)^:= cExplosionBorderColor and $FF;
                PByte(p + LandSurface.pitch * ty + tx * 3 + 1)^:= (cExplosionBorderColor shr 8) and $FF;
                PByte(p + LandSurface.pitch * ty + tx * 3 + 2)^:= (cExplosionBorderColor shr 16);
                end;
             4: PLongword(p + LandSurface.pitch * ty + tx * 4)^:= cExplosionBorderColor;
             end
	end;