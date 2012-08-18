package org.hedgewars.hedgeroid.frontlib;

/**
 * This class represents the native C type size_t. On Android, this type could be mapped with int,
 * but we use a separate type to make it easier to adapt for other platforms if anyone wants to use
 * the mappings elsewhere. 
 */
public final class NativeSizeT extends Number {
	private static final long serialVersionUID = 1L;
	private final long value;
	
	private NativeSizeT(long value) {
		this.value = value;
	}
	
	public static NativeSizeT valueOf(long l) {
		return new NativeSizeT(l);
	}
	
	@Override
	public int intValue() {
		return (int)value;
	}
	
	@Override
	public long longValue() {
		return value;
	}

	@Override
	public double doubleValue() {
		return value;
	}

	@Override
	public float floatValue() {
		return value;
	}
}
