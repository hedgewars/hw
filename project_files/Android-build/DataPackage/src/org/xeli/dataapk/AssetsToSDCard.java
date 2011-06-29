package org.xeli.dataapk;


import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;

public class AssetsToSDCard implements Runnable {

	public int INTERNAL_SDCARD = 0;
	public int EXTERNAL_SDCARD = 1;

	private Context context;
	private File outputDir;
	public AssetsToSDCard(Context c, boolean verifiedFreeSpace, String _outputDir){
		context = c;
		outputDir = c.getExternalFilesDir("Data").getParentFile();
	}

	private void copyFile(InputStream in, OutputStream out) throws IOException {
		byte[] buffer = new byte[1024];
		int read;
		while((read = in.read(buffer)) != -1){
			out.write(buffer, 0, read);
		}
	}

	private void visitAllFiles(AssetManager assManager, String[] childs, String file){
		try {
			InputStream in;
			OutputStream out;
			if(childs.length == 0){ //file = a non directory file
				in = assManager.open(file);
				File f = new File(outputDir, file);
				out = new FileOutputStream(f);
				copyFile(in, out);
			}else{ //file = a directory
				for(String s : childs){
					File f = new File(outputDir, file);
					f.mkdir();
					String tmp = file + '/' + s;
					visitAllFiles(assManager, assManager.list(tmp), tmp);
				}
			}

		} catch (IOException e) {
			//TODO handle correctly
			Log.e("fail", file);
			e.printStackTrace();
		}
	}

	public void run() {//Runs in it's own thread
		AssetManager assManager = context.getAssets();

		try {
			Log.e("DataDownloader", "Starting to copy files");
			visitAllFiles(assManager, assManager.list("Data"), "Data");
			Log.e("DataDownloader", "Done copying files");
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

}
