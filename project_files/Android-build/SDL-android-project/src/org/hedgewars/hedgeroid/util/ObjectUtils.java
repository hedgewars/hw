package org.hedgewars.hedgeroid.util;

public final class ObjectUtils {
	public static boolean equal(Object o1, Object o2) {
		if(o1==o2) {
			return true;
		} else if(o1==null || o2 == null) {
			return false;
		} else {
			return o1.equals(o2);
		}
	}
}
