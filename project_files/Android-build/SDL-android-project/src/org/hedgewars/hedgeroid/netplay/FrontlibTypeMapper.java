package org.hedgewars.hedgeroid.netplay;

import java.io.UnsupportedEncodingException;

import com.sun.jna.DefaultTypeMapper;
import com.sun.jna.FromNativeContext;
import com.sun.jna.FromNativeConverter;
import com.sun.jna.Native;
import com.sun.jna.Pointer;
import com.sun.jna.ToNativeContext;
import com.sun.jna.ToNativeConverter;
import com.sun.jna.TypeConverter;
import com.sun.jna.TypeMapper;

public class FrontlibTypeMapper extends DefaultTypeMapper {
    public static final TypeMapper INSTANCE = new FrontlibTypeMapper();
    
    protected FrontlibTypeMapper() {
        addTypeConverter(Boolean.class, new BooleanConverter());
		addToNativeConverter(String.class, new StringToNativeConverter());
		addFromNativeConverter(String.class, new StringFromNativeConverter());
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

class StringToNativeConverter implements ToNativeConverter {
	public byte[] toNative(Object value, ToNativeContext context) {
    	try {
			return value==null ? null : Native.toByteArray((String)value, "UTF-8");
		} catch (UnsupportedEncodingException e) {
			throw new AssertionError(e); // Never happens
		}
	}
	
	public Class<byte[]> nativeType() {
		return byte[].class;
	}
}

class StringFromNativeConverter implements FromNativeConverter {
	public String fromNative(Object value, FromNativeContext context) {
		Pointer p = (Pointer)value;
		if(p==null) {
			return null;
		}
		int i=0;
		while(p.getByte(i) != 0) {
			i++;
		}
    	try {
			return new String(p.getByteArray(0, i), "UTF-8");
		} catch (UnsupportedEncodingException e) {
			throw new AssertionError(e); // Never happens
		}
	}
	
	public Class<Pointer> nativeType() {
		return Pointer.class;
	}
}
