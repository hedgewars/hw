package org.hedgewars.hedgeroid.Downloader;

import android.app.ListActivity;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;

public class DownloadListActivity extends ListActivity implements OnItemClickListener{

	
	public void onCreate(Bundle savedInstanceState){
		super.onCreate(savedInstanceState);
		
		DownloadTask[] tasks = new DownloadTask[3];
		tasks[0] = new DownloadTask("url1", "/home/path/1", 1, "entry 1");
		tasks[1] = new DownloadTask("url2", "/home/path/2", 1, "entry 2");
		tasks[2] = new DownloadTask("url3", "/home/path/3", 1, "entry 3");
		
		ArrayAdapter<DownloadTask> adapter = new ArrayAdapter<DownloadTask>(this, android.R.layout.simple_list_item_1, tasks);
		this.setListAdapter(adapter);
		this.getListView().setOnItemClickListener(this);
		
	}
	
	public void onItemClick(AdapterView<?> arg0, View arg1, int position, long arg3) {
		DownloadTask task = (DownloadTask)arg0.getAdapter().getItem(position);
	}
	
//	public static class Dialog extends DialogFragment{
		
//	}
	
}

