package org.xeli.dataapk;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;

public class MainActivity extends Activity {

	private MainActivity thisActivity = this;
	
	public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        
        Button b = (Button)findViewById(R.id.startCopy);
        b.setOnClickListener(startCopyClicker);
    }
    
    private OnClickListener startCopyClicker = new OnClickListener(){
		public void onClick(View arg0) {
			AssetsToSDCard runnable = new AssetsToSDCard(thisActivity, false, "/sdcard");
			Thread t = new Thread(runnable, "Assets2SDCard - Thread");
			t.start();
		}
    	
    };
    
}