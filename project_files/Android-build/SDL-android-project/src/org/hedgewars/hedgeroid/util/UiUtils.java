package org.hedgewars.hedgeroid.util;

import org.hedgewars.hedgeroid.R;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.TabHost;
import android.widget.TextView;

public final class UiUtils {
	private UiUtils() {
		throw new AssertionError("This class is not meant to be instantiated");
	}

	public static View createTabIndicator(TabHost tabHost, int label, int icon) {
		LayoutInflater inflater = (LayoutInflater) tabHost.getContext()
				.getSystemService(Context.LAYOUT_INFLATER_SERVICE);

		View view = inflater.inflate(R.layout.tab_indicator_vertical,
				tabHost.getTabWidget(), false);

		final TextView tv = (TextView) view.findViewById(R.id.title);
		tv.setText(label);

		if (icon != 0) {
			ImageView iconView = (ImageView) view.findViewById(R.id.icon);
			iconView.setImageResource(icon);
		}

		return view;
	}
}
