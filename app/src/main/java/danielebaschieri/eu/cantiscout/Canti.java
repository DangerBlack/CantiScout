package danielebaschieri.eu.cantiscout;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.AsyncTask;
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

import java.util.ArrayList;
import java.util.GregorianCalendar;

import static danielebaschieri.eu.cantiscout.QueryManager.insertSong;


public class Canti extends ActionBarActivity implements View.OnClickListener {

    final public static String URL_PATH_INDEX="http://www.512b.it/cantiscout/index.html";
    final public static String URL_PATH_STATS="http://www.512b.it/cantiscout/stats.html";
    private final static String DATE_OF_SYNC = "SyncDate";
    private final static String MY_PREFERENCES = "CantiScout";
    private final static long interval=86400000;
    //one day  86400000
    //one hour  3600000
    //one minute  60000

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_canti);

        Long lastSync=loadDateOfSync();
        GregorianCalendar g=new GregorianCalendar();
        Long data=g.getTimeInMillis();

        if((lastSync==1)||(data-lastSync>interval)) {
            DownloadDBTask ddbt = new DownloadDBTask();
            ddbt.execute(new String[]{});
        }

        Button songbook=(Button)findViewById(R.id.songbook);
        Button favourite=(Button)findViewById(R.id.favourite);
        Button stats=(Button)findViewById(R.id.stats);
        Button add=(Button)findViewById(R.id.add);

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

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.canti, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();
        /*if (id == R.id.action_settings) {
            return true;
        }*/
        return super.onOptionsItemSelected(item);
    }

    final private String DEFAULT_FILTER="none";
    final private String FAV_FILTER="favourite";
    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.songbook:
                Intent showList = new Intent(getApplicationContext(), SongList.class);
                showList.putExtra("FILTER_BY", DEFAULT_FILTER);
                startActivity(showList);
                break;
            case R.id.favourite:
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


    private class DownloadDBTask extends AsyncTask<String, Void, String> {
        private String URL_PATH="http://www.512b.it/cantiscout/php/";
        ProgressBar prb;
        TextView error;

        private DownloadDBTask(){
            //this.prb = p;
            //this.error = err;
        }

        @Override
        protected void onPreExecute() {
            //error.setVisibility(View.GONE);
            //prb.setVisibility(View.VISIBLE);
        }

        @Override
        protected void onPostExecute(String result) {
              Toast.makeText(getApplicationContext(), getString(R.string.downloadSuccess), Toast.LENGTH_SHORT).show();
              Log.println(Log.DEBUG, "Canti", "Download2 " + result);
              if(result.indexOf("204")!=0) {
                  try {
                      /*int max = QueryManager.getMaxId(getApplicationContext());

                      boolean go = false;
                      for (int i = 0; i < jArr.length(); i++) {
                          JSONObject obj = jArr.getJSONObject(i);
                          if (obj.getInt("id") > max)
                              go = true;
                      }
                      if (go) {*/
                      JSONObject jObj = new JSONObject(result);
                      String elenco=jObj.getString("songlist");
                      Log.println(Log.DEBUG,"Canti",elenco);
                      JSONArray jArr = new JSONArray(elenco);
                      //QueryManager.dropAllSong(getApplicationContext());
                      for (int i = 0; i < jArr.length(); i++) {
                          JSONObject obj = jArr.getJSONObject(i);
                          QueryManager.insertSong(getApplicationContext(), obj.getInt("id"), obj.getString("title"), obj.getString("author"), obj.getString("body"),obj.getString("time"));
                          Log.println(Log.DEBUG, "Canti", "insert: " + obj.getString("title"));
                      }

                      elenco=jObj.getString("taglist");
                      jArr = new JSONArray(elenco);
                      //QueryManager.dropAllTag(getApplicationContext());
                      for (int i = 0; i < jArr.length(); i++) {
                          JSONObject obj = jArr.getJSONObject(i);
                          QueryManager.insertTag(getApplicationContext(), obj.getInt("id"), obj.getInt("id_song"), obj.getString("tag"));
                          //Log.println(Log.DEBUG, "Canti", "insert: " + obj.getString("title"));
                      }


                      Toast.makeText(getApplicationContext(), getString(R.string.databaseUpdated), Toast.LENGTH_SHORT).show();
                      saveDateOfSync();
                  } catch (JSONException e) {
                      e.printStackTrace();
                  }
              } else {
                  Toast.makeText(getApplicationContext(), getString(R.string.databaseNotUpdated), Toast.LENGTH_SHORT).show();
              }


        }

        @Override
        protected String doInBackground(String... params) {
            String res = null;
            String response = null;
            try{
                String lastSongUpdate="";
                try {
                    lastSongUpdate = QueryManager.getMax(getApplicationContext());
                }catch(Exception e){
                    Log.println(Log.DEBUG, "Canti", "UBER EXCEPTION");
                }
                if(lastSongUpdate==null)
                    lastSongUpdate="";
                Log.println(Log.DEBUG, "Canti", "Upload Max " + lastSongUpdate);
                response = CustomHttpClient.executeHttpGet(URL_PATH+"get.php?max="+Uri.encode(lastSongUpdate));

                res = response.toString();
                Log.println(Log.DEBUG, "Canti", "Download1 " + res);
                //res = res.replaceAll("\\s+","");
            } catch (Exception e) {

            }
            return res;
        }
    }
}
