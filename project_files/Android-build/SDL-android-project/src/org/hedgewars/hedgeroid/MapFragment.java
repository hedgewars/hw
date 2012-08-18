package org.hedgewars.hedgeroid;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Random;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.FrontendDataUtils;
import org.hedgewars.hedgeroid.Datastructures.MapFile;
import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Weaponset;
import org.hedgewars.hedgeroid.frontlib.Frontlib;

import android.content.Context;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.Spinner;
import android.widget.TableRow;
import android.widget.Toast;

public class MapFragment extends Fragment implements RoomStateManager.Observer {
	private Spinner mapTypeSpinner, mapNameSpinner, templateSpinner, mazeSizeSpinner;
	private TableRow nameRow, templateRow, mazeSizeRow;
	private ImageView mapPreview;
	private List<MapFile> mapFiles;
	private RoomStateManager stateManager;
	private Random random = new Random();
	private CalmDownHandler mapPreviewHandler;
	
	/*
	 * Rendering the preview can take a few seconds on Android, so we want to prevent preview
	 * requests from queueing up if maps are changed quickly. So if there is already a preview
	 * being generated, we store our latest request in the newPreviewRequest variable instead.
	 * Once the current preview is finished generating it will start on that one.
	 */
	private boolean previewGenerationInProgress;
	private MapRecipe newPreviewRequest;
	private MapRecipe currentMap; // kept for reference on every change to find out what changed
	
	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
		View v = inflater.inflate(R.layout.fragment_map, container, false);

		final Context appContext = getActivity().getApplicationContext();
		mapPreviewHandler = new CalmDownHandler(getActivity().getMainLooper(), new Runnable() {
			public void run() {
				if(!previewGenerationInProgress) {
					mapPreview.setImageResource(R.drawable.roomlist_preparing);
					MapPreviewGenerator.startPreviewGeneration(appContext, stateManager.getMapRecipe(), mapPreviewListener);
					previewGenerationInProgress = true;
				} else {
					newPreviewRequest = stateManager.getMapRecipe();
				}
			}
		}, 250);
		
		nameRow = (TableRow) v.findViewById(R.id.rowMapName);
		templateRow = (TableRow) v.findViewById(R.id.rowTemplateFilter);
		mazeSizeRow = (TableRow) v.findViewById(R.id.rowMazeSize);
		mapPreview = (ImageView) v.findViewById(R.id.mapPreview);
		mapPreview.setImageDrawable(null);;
		mapPreview.setOnClickListener(mapClickListener);
		
		try {
			mapFiles = FrontendDataUtils.getMaps(getActivity());
		} catch (IOException e) {
			Toast.makeText(getActivity().getApplicationContext(), R.string.error_missing_sdcard_or_files, Toast.LENGTH_LONG).show();
			getActivity().finish();
		}
		Collections.sort(mapFiles, MapFile.MISSIONS_FIRST_NAME_ORDER);
		
		List<String> mapNames = MapFile.toDisplayNameList(mapFiles, getResources());
		mapTypeSpinner = prepareSpinner(v, R.id.spinMapType, Arrays.asList(getResources().getStringArray(R.array.map_types)), mapTypeSelectedListener);
		mapNameSpinner = prepareSpinner(v, R.id.spinMapName, mapNames, mapNameSelectedListener);
		templateSpinner = prepareSpinner(v, R.id.spinTemplateFilter, Arrays.asList(getResources().getStringArray(R.array.map_templates)), mapTemplateSelectedListener);
		mazeSizeSpinner = prepareSpinner(v, R.id.spinMazeSize, Arrays.asList(getResources().getStringArray(R.array.map_maze_sizes)), mazeSizeSelectedListener);

		stateManager.registerObserver(this);
		currentMap = stateManager.getMapRecipe();
		if(currentMap != null) {
			updateDisplay(currentMap);
		}
		setChiefState(stateManager.getChiefStatus());
		mapPreviewHandler.activity();
		return v;
	}
	
	private static Spinner prepareSpinner(View v, int id, List<String> items, OnItemSelectedListener itemSelectedListener) {
		Spinner spinner = (Spinner)v.findViewById(id);
		ArrayAdapter<String> adapter = new ArrayAdapter<String>(v.getContext(), R.layout.listview_item, items);
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		spinner.setAdapter(adapter);
		spinner.setOnItemSelectedListener(itemSelectedListener);
		return spinner;
	}
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		try {
			stateManager = ((RoomStateManager.Provider)getActivity()).getRoomStateManager();
		} catch(ClassCastException e) {
			throw new RuntimeException("Hosting activity must implement RoomStateManager.Provider.", e);
		}
	}
	
	@Override
	public void onDestroy() {
		super.onDestroy();
		mapPreviewHandler.stop();
		stateManager.unregisterObserver(this);
	}
	
	private void setChiefState(boolean chiefState) {
		mapTypeSpinner.setEnabled(chiefState);
		mapNameSpinner.setEnabled(chiefState);
		templateSpinner.setEnabled(chiefState);
		mazeSizeSpinner.setEnabled(chiefState);
		mapPreview.setEnabled(chiefState);
		
		if(chiefState) {
			sendMapnameAndGenerator();
			stateManager.changeMapTemplate(templateSpinner.getSelectedItemPosition());
			stateManager.changeMazeSize(mazeSizeSpinner.getSelectedItemPosition());
		}
	}
	
	private void updateDisplay(MapRecipe map) {
		nameRow.setVisibility(map.mapgen == Frontlib.MAPGEN_NAMED ? View.VISIBLE : View.GONE);
		templateRow.setVisibility(map.mapgen == Frontlib.MAPGEN_REGULAR ? View.VISIBLE : View.GONE);
		mazeSizeRow.setVisibility(map.mapgen == Frontlib.MAPGEN_MAZE ? View.VISIBLE : View.GONE);
		
		mapTypeSpinner.setSelection(map.mapgen);
		int mapPosition = findMapPosition(mapFiles, map.name);
		if(mapPosition >= 0) {
			mapNameSpinner.setSelection(mapPosition);
		}
		templateSpinner.setSelection(map.templateFilter);
		mazeSizeSpinner.setSelection(map.mazeSize);
	}
	
	private static int findMapPosition(List<MapFile> mapFiles, String mapName) {
		for(int i=0; i<mapFiles.size(); i++) {
			if(mapName.equals(mapFiles.get(i).name)) {
				return i;
			}
		}
		return -1;
	}
	
	private void sendMapnameAndGenerator() {
		int mapType = mapTypeSpinner.getSelectedItemPosition();
		String mapName = mapFiles.get(mapNameSpinner.getSelectedItemPosition()).name;
		stateManager.changeMapNameAndGenerator(MapRecipe.mapnameForGenerator(mapType, mapName));
	}
	
	private final OnItemSelectedListener mapTypeSelectedListener = new OnItemSelectedListener() {
		public void onItemSelected(AdapterView<?> adapter, View v, int position, long arg3) {
			sendMapnameAndGenerator();
		}
		public void onNothingSelected(AdapterView<?> arg0) {}
	};
	
	private final OnItemSelectedListener mapNameSelectedListener = new OnItemSelectedListener() {
		public void onItemSelected(AdapterView<?> adapter, View v, int position, long arg3) {
			sendMapnameAndGenerator();
		}
		public void onNothingSelected(AdapterView<?> arg0) {}
	};
	
	private final OnItemSelectedListener mapTemplateSelectedListener = new OnItemSelectedListener() {
		public void onItemSelected(AdapterView<?> adapter, View v, int position, long arg3) {
			stateManager.changeMapTemplate(position);
		}
		public void onNothingSelected(AdapterView<?> arg0) {}
	};
	
	private final OnItemSelectedListener mazeSizeSelectedListener = new OnItemSelectedListener() {
		public void onItemSelected(AdapterView<?> adapter, View v, int position, long arg3) {
			stateManager.changeMazeSize(position);
		}
		public void onNothingSelected(AdapterView<?> arg0) {}
	};
	
	private final OnClickListener mapClickListener = new OnClickListener() {
		public void onClick(View v) {
			stateManager.changeMapSeed(MapRecipe.makeRandomSeed());
			switch(mapTypeSpinner.getSelectedItemPosition()) {
			case Frontlib.MAPGEN_NAMED:
				mapNameSpinner.setSelection(random.nextInt(mapNameSpinner.getCount()));
				break;
			case Frontlib.MAPGEN_REGULAR:
				templateSpinner.setSelection(Frontlib.TEMPLATEFILTER_ALL);
				break;
			case Frontlib.MAPGEN_MAZE:
				mazeSizeSpinner.setSelection(random.nextInt(mazeSizeSpinner.getCount()));
				break;
			}
		}
	};
	
	public void onChiefStatusChanged(boolean isChief) {
		setChiefState(isChief);
	}
	
	public void onMapChanged(MapRecipe recipe) {
		if(currentMap==null
				|| currentMap.mapgen != recipe.mapgen
				|| currentMap.mazeSize != recipe.mazeSize
				|| !currentMap.name.equals(recipe.name)
				|| !currentMap.seed.equals(recipe.seed)
				|| currentMap.templateFilter != recipe.templateFilter
				|| !Arrays.equals(currentMap.getDrawData(), recipe.getDrawData())) {
			mapPreviewHandler.activity();
		}
		updateDisplay(recipe);
		currentMap = recipe;
	}
	
	public void onGameStyleChanged(String gameStyle) { }
	public void onSchemeChanged(Scheme scheme) { }
	public void onWeaponsetChanged(Weaponset weaponset) { }
	
	private MapPreviewGenerator.Listener mapPreviewListener = new MapPreviewGenerator.Listener() {
		public void onMapPreviewResult(Drawable preview) {
			if(newPreviewRequest != null) {
				MapPreviewGenerator.startPreviewGeneration(getActivity().getApplicationContext(), newPreviewRequest, mapPreviewListener);
				newPreviewRequest = null;
			} else {
				if(mapPreview != null) {
					mapPreview.setImageDrawable(preview);
				}
				previewGenerationInProgress = false;
			}
		}
	};
	
	/**
	 * This class allows you to define a runnable that is called when there has been no activity
	 * for a set amount of time, where activity is determined by calls to the activity() method
	 * of the handler. It is used here to update the map preview when there have been no updates
	 * to the relevant map information for a time, to prevent triggering several updates at once
	 * when different parts of the information change.
	 */
	private static final class CalmDownHandler extends Handler {
		int runningMessagesCounter = 0;
		final Runnable inactivityRunnable;
		final long inactivityMs;
		boolean stopped;

		public CalmDownHandler(Looper looper, Runnable runnable, long inactivityMs) {
			super(looper);
			this.inactivityRunnable = runnable;
			this.inactivityMs = inactivityMs;
		}
		
		public void activity() {
			runningMessagesCounter++;
			sendMessageDelayed(obtainMessage(), inactivityMs);
		}
		
		@Override
		public void handleMessage(Message msg) {
			runningMessagesCounter--;
			if(runningMessagesCounter==0 && !stopped) {
				inactivityRunnable.run();
			}
		}
		
		public void stop() {
			stopped = true;
		}
	}
}
