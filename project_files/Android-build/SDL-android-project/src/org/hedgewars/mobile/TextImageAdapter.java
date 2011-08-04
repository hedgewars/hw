package org.hedgewars.mobile;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import org.hedgewars.mobile.R;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.SimpleAdapter;
import android.widget.TextView;


public class TextImageAdapter extends SimpleAdapter {

	private Context context;
	private ArrayList<Map<String, ?>> data;
	
	public TextImageAdapter(Context _context, ArrayList<Map<String, ?>> _data, int resource, String[] from, int[] to) {
		super(_context, _data, resource, from, to);
		context = _context;
		data = _data;
	}
	
	public static TextImageAdapter createAdapter(Context c, String[] txt, String[] img, String[] from, int[] to){
		if(txt.length != img.length) throw new IllegalArgumentException("txt and img parameters not equal");
		
		ArrayList<Map<String, ?>> data = new ArrayList<Map<String, ?>>(txt.length);
		
		for(int i = 0; i < txt.length; i++){
			HashMap<String, Object> map = new HashMap<String, Object>();
			map.put("txt", txt[i]);
			map.put("img", BitmapFactory.decodeFile(img[i]));
			data.add(map);
		}
		return new TextImageAdapter(c, data, R.layout.spinner_textimg_entry, from, to);
	}

	public View getView(int position, View convertView, ViewGroup parent){
		if(convertView == null){
			LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
			convertView = inflater.inflate(R.layout.spinner_textimg_entry, parent);
		}
		TextView tv = (TextView) convertView.findViewById(R.id.spinner_txt);
		ImageView img = (ImageView) convertView.findViewById(R.id.spinner_img);
		
		tv.setText((String)data.get(position).get("txt"));
		img.setImageBitmap((Bitmap)data.get(position).get("img"));
		
		return convertView;
	}
}
