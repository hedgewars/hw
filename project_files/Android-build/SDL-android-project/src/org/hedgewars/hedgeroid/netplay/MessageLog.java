package org.hedgewars.hedgeroid.netplay;

import java.util.Date;
import java.util.LinkedList;
import java.util.List;

import org.hedgewars.hedgeroid.R;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.text.Html;
import android.text.Spannable;
import android.text.SpannableString;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.TextUtils;
import android.text.format.DateFormat;
import android.text.style.ForegroundColorSpan;
import android.text.style.RelativeSizeSpan;
import android.text.style.StyleSpan;
import android.util.Log;

public class MessageLog {
	private static final int BACKLOG_CHARS = 10000;
	
	private static final int INFO_COLOR = Color.GRAY;
	private static final int CHAT_COLOR = Color.GREEN;
	private static final int MECHAT_COLOR = Color.CYAN;
	private static final int WARN_COLOR = Color.RED;
	private static final int ERROR_COLOR = Color.RED;
	
	private final Context context;
	private List<Observer> observers = new LinkedList<Observer>();
	
	private SpannableStringBuilder log = new SpannableStringBuilder();
	private List<Integer> lineLengths = new LinkedList<Integer>();
	
	public MessageLog(Context context) {
		this.context = context;
	}
	
	private Spanned makeLogTime() {
		String time = DateFormat.getTimeFormat(context).format(new Date());
		return withColor("[" + time + "] ", INFO_COLOR);
	}
	
	private static Spanned span(CharSequence s, Object o) {
		Spannable spannable = new SpannableString(s);
		spannable.setSpan(o, 0, s.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
		return spannable;
	}
	
	private static Spanned withColor(CharSequence s, int color) {
		return span(s, new ForegroundColorSpan(color));
	}
	
	private static Spanned bold(CharSequence s) {
		return span(s, new StyleSpan(Typeface.BOLD));
	}
	
	private void append(CharSequence msg) {
		SpannableStringBuilder ssb = new SpannableStringBuilder();
		ssb.append(makeLogTime()).append(msg).append("\n");
		appendRaw(ssb);
	}
	
	private void appendRaw(CharSequence msg) {
		lineLengths.add(msg.length());
		log.append(msg);
		while(log.length() > BACKLOG_CHARS) {
			log.delete(0, lineLengths.remove(0));
		}
		for(Observer o : observers) {
			o.textChanged(log);
		}
	}
	
	void appendPlayerJoin(String playername) {
		append(withColor("***" + context.getResources().getString(R.string.log_player_join, playername), INFO_COLOR));
	}
	
	void appendPlayerLeave(String playername, String partMsg) {
		String msg = "***";
		if(partMsg != null) {
			msg += context.getResources().getString(R.string.log_player_leave_with_msg, playername, partMsg);
		} else {
			msg += context.getResources().getString(R.string.log_player_leave, playername);
		}
		append(withColor(msg, INFO_COLOR));
	}
	
	void appendChat(String playerName, String msg) {
		if(msg.startsWith("/me ")) {
			append(withColor("*"+playerName+" "+msg, MECHAT_COLOR));
		} else {
			Spanned name = bold(playerName+": ");
			Spanned fullMessage = withColor(TextUtils.concat(name, msg), CHAT_COLOR);
			append(fullMessage);			
		}
	}
	
	void appendMessage(int type, String msg) {
		switch(type) {
		case JnaFrontlib.NETCONN_MSG_TYPE_ERROR:
			append(withColor("***"+msg, ERROR_COLOR));
			break;
		case JnaFrontlib.NETCONN_MSG_TYPE_WARNING:
			append(withColor("***"+msg, WARN_COLOR));
			break;
		case JnaFrontlib.NETCONN_MSG_TYPE_PLAYERINFO:
			// TODO better formatting or different way to display
			append(msg);
			break;
		case JnaFrontlib.NETCONN_MSG_TYPE_SERVERMESSAGE:
			appendRaw(span(TextUtils.concat("\n", Html.fromHtml(msg), "\n\n"), new RelativeSizeSpan(1.5f)));
			break;
		default:
			Log.e("MessageLog", "Unknown messagetype "+type);
		}
	}
	
	void clear() {
		log.clear();
		lineLengths.clear();
	}
	
	public void observe(Observer o) {
		observers.add(o);
	}
	
	public void unobserve(Observer o) {
		observers.remove(o);
	}
	
	public static interface Observer {
		void textChanged(Spanned text);
	}
}
