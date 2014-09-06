package danielebaschieri.eu.cantiscout;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Looper;
import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import org.apache.http.NameValuePair;
import org.apache.http.message.BasicNameValuePair;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.GregorianCalendar;

import static danielebaschieri.eu.cantiscout.QueryManager.insertSong;


public class Canti extends ActionBarActivity implements View.OnClickListener {

    final public static String URL_PATH_INDEX="http://www.512b.it/cantiscout/index.html";
    final public static String URL_PATH_STATS="http://www.512b.it/cantiscout/stats.html";
    private final static String MY_PREFERENCES = "CantiScout";
    private final static String DATE_OF_SYNC = "SyncDate";
    private final static String QUERY_FILTER = "";
    private final static long interval=86400000;
    //one day  86400000
    //one hour  3600000
    //one minute  60000

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_canti);

        //Typeface font = Typeface.createFromAsset(getAssets(), "fonts/BABYDOLL.TTF");
        //Typeface font = Typeface.createFromAsset(getAssets(), "fonts/Strato-unlinked.ttf");
        Typeface font = Typeface.createFromAsset(getAssets(), "fonts/Midan-Black.ttf");

        TextView tv=(TextView)findViewById(R.id.mainTitle);
        if(tv!=null)
            tv.setTypeface(font);
        Long lastSync=loadDateOfSync();
        GregorianCalendar g=new GregorianCalendar();
        Long data=g.getTimeInMillis();

        if((lastSync==1)||(data-lastSync>interval)) {


            Intent splashScreen = new Intent(getApplicationContext(), SplashScreen.class);
            //showList.putExtra("FILTER_BY", DEFAULT_FILTER);
            startActivity(splashScreen);
            finish();
        }

        Button songbook=(Button)findViewById(R.id.songbook);
        Button favourite=(Button)findViewById(R.id.favourite);
        Button stats=(Button)findViewById(R.id.stats);
        Button add=(Button)findViewById(R.id.add);

        songbook.setTypeface(font);
        favourite.setTypeface(font);
        stats.setTypeface(font);
        add.setTypeface(font);

        songbook.setOnClickListener(this);
        favourite.setOnClickListener(this);
        stats.setOnClickListener(this);
        add.setOnClickListener(this);
    }


    private void saveDateOfSync() {
        SharedPreferences prefs = getSharedPreferences(MY_PREFERENCES, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        GregorianCalendar g=new GregorianCalendar();
        Long data=g.getTimeInMillis();
        editor.putLong(DATE_OF_SYNC, data);
        editor.commit();
    }
    private long loadDateOfSync(){
        SharedPreferences prefs = getSharedPreferences(MY_PREFERENCES, Context.MODE_PRIVATE);
        return prefs.getLong(DATE_OF_SYNC, 1);
    }

    /**
     * This methods erase the value of the last search in app,
     * it's useful because from main menù the SongList must be
     * reinitialized.
     */
    public void eraseQueryFilter() {
        SharedPreferences prefs = getSharedPreferences(MY_PREFERENCES, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString(QUERY_FILTER, "");
        editor.commit();
    }
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.canti, menu);
        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();
        switch (item.getItemId()) {
            case R.id.sync:
                //DownloadDBTask ddbt = new DownloadDBTask();
                //ddbt.execute(new String[]{});
                Intent splashScreen = new Intent(getApplicationContext(), SplashScreen.class);
                startActivity(splashScreen);
                break;
            case R.id.settings:
                Intent settingScreen = new Intent(getApplicationContext(), SettingsActivity.class);
                startActivity(settingScreen);
                break;

        }
        return super.onOptionsItemSelected(item);
    }

    final private String DEFAULT_FILTER="none";
    final private String FAV_FILTER="favourite";
    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.songbook:
                eraseQueryFilter();
                Intent showList = new Intent(getApplicationContext(), SongList.class);
                showList.putExtra("FILTER_BY", DEFAULT_FILTER);
                startActivity(showList);
                break;
            case R.id.favourite:
                eraseQueryFilter();
                Intent showListFav = new Intent(getApplicationContext(), SongList.class);
                showListFav.putExtra("FILTER_BY", FAV_FILTER);
                startActivity(showListFav);
                break;
            case R.id.stats:
                Intent browserIntentStats = new Intent(Intent.ACTION_VIEW, Uri.parse(URL_PATH_STATS));
                startActivity(browserIntentStats);
                break;
            case R.id.add:
                Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(URL_PATH_INDEX));
                startActivity(browserIntent);
                break;
        }
    }



}
