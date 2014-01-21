/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

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

