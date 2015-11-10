/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
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

package org.hedgewars.hedgeroid;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

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
