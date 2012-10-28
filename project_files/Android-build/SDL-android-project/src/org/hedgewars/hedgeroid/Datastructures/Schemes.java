package org.hedgewars.hedgeroid.Datastructures;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.hedgewars.hedgeroid.frontlib.Flib;
import org.hedgewars.hedgeroid.frontlib.Frontlib.SchemelistPtr;

import android.content.Context;

/**
 * Functions for handling the persistent list of schemes.
 * Schemes in that list are identified by name (case sensitive).
 */
public final class Schemes {
	private Schemes() {
		throw new AssertionError("This class is not meant to be instantiated");
	}
	
	public static File getUserSchemesFile(Context c) {
		return new File(c.getFilesDir(), "schemes_user.ini");
	}
	
	public static File getBuiltinSchemesFile(Context c) {
		return new File(c.getFilesDir(), "schemes_builtin.ini");
	}
	
	public static List<Scheme> loadAllSchemes(Context c) throws IOException {
		List<Scheme> result = loadBuiltinSchemes(c);
		result.addAll(loadUserSchemes(c));
		return result;
	}
	
	public static List<Scheme> loadUserSchemes(Context c) throws IOException {
		return loadSchemes(c, getUserSchemesFile(c));
	}
	
	public static List<Scheme> loadBuiltinSchemes(Context c) throws IOException {
		return loadSchemes(c, getBuiltinSchemesFile(c));
	}
	
	public static List<Scheme> loadSchemes(Context c, File schemeFile) throws IOException {
		if(!schemeFile.isFile()) {
			// No schemes file == no schemes, no error
			return new ArrayList<Scheme>();
		}
		SchemelistPtr schemeListPtr = null;
		try {
			schemeListPtr = Flib.INSTANCE.flib_schemelist_from_ini(schemeFile.getAbsolutePath());
			if(schemeListPtr == null) {
				throw new IOException("Unable to read schemelist");
			}
			return schemeListPtr.deref();
		} finally {
			if(schemeListPtr != null) {
				Flib.INSTANCE.flib_schemelist_destroy(schemeListPtr);
			}
		}
	}
	
	public static void saveUserSchemes(Context c, List<Scheme> schemes) throws IOException {
		SchemelistPtr ptr = SchemelistPtr.createJavaOwned(schemes);
		Flib.INSTANCE.flib_schemelist_to_ini(getUserSchemesFile(c).getAbsolutePath(), ptr);
	}
	
	public static List<String> toNameList(List<Scheme> schemes) {
		List<String> result = new ArrayList<String>();
		for(Scheme scheme : schemes) {
			result.add(scheme.name);
		}
		return result;
	}
}
