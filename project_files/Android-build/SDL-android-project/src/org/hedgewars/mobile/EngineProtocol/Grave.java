package org.hedgewars.mobile.EngineProtocol;

public class Grave{

	public final String name;
	public final String path;
	
	public Grave(String _name, String _path) {
		name = _name;
		path = _path;
	}

	public String toString(){
		return name;
	}
	
}
