package org.hedgewars.hedgeroid.frontlib;

import com.sun.jna.DefaultTypeMapper;
import com.sun.jna.FromNativeContext;
import com.sun.jna.ToNativeContext;
import com.sun.jna.TypeConverter;
import com.sun.jna.TypeMapper;

class AndroidTypeMapper extends DefaultTypeMapper {
	static final int NATIVE_INT_SIZE = 4;
	static final int NATIVE_SIZE_T_SIZE = 4;
	static final int NATIVE_BOOL_SIZE = 1;
    public static final TypeMapper INSTANCE = new AndroidTypeMapper();
    
    protected AndroidTypeMapper() {
        addTypeConverter(Boolean.class, new BooleanConverter());
        addTypeConverter(NativeSizeT.class, new SizeTConverter());
    }

    private static final class BooleanConverter implements TypeConverter {
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
    
    private static final class SizeTConverter implements TypeConverter {
    	public Class<Integer> nativeType() {
    		return Integer.class;
    	}
    	public Object fromNative(Object value, FromNativeContext context) {
    		return NativeSizeT.valueOf((Integer)value);
    	}
    	public Object toNative(Object value, ToNativeContext context) {
    		return Integer.valueOf(value==null ? 0 : ((NativeSizeT)value).intValue());
    	}
    }
}

