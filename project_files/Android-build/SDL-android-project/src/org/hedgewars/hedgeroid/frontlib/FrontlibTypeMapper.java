package org.hedgewars.hedgeroid.frontlib;

import com.sun.jna.DefaultTypeMapper;
import com.sun.jna.FromNativeContext;
import com.sun.jna.ToNativeContext;
import com.sun.jna.TypeConverter;
import com.sun.jna.TypeMapper;

class FrontlibTypeMapper extends DefaultTypeMapper {
    public static final TypeMapper INSTANCE = new FrontlibTypeMapper();
    
    protected FrontlibTypeMapper() {
        addTypeConverter(Boolean.class, new BooleanConverter());
    }
}

class BooleanConverter implements TypeConverter {
    public Class<Byte> nativeType() {
        return Byte.class;
    }
	public Object fromNative(Object value, FromNativeContext context) {
		return ((Byte)value).intValue() != 0 ? Boolean.TRUE : Boolean.FALSE;
	}
	public Object toNative(Object value, ToNativeContext context) {
		return Byte.valueOf((byte)(Boolean.TRUE.equals(value) ? 1 : 0));
	}
}
