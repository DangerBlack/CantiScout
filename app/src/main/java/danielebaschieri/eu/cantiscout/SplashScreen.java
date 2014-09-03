package danielebaschieri.eu.cantiscout;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Looper;
import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.GregorianCalendar;


public class SplashScreen extends ActionBarActivity {
    final public static String URL_PATH_INDEX="http://www.512b.it/cantiscout/index.html";
    final public static String URL_PATH_STATS="http://www.512b.it/cantiscout/stats.html";
    private final static String DATE_OF_SYNC = "SyncDate";
    private final static String MY_PREFERENCES = "CantiScout";
    private final static long interval=86400000;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash_screen);

        DownloadDBTask ddbt = new DownloadDBTask();
        ddbt.execute(new String[]{});

    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.splash_screen, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();
       // if (id == R.id.action_settings) {
         //   return true;
        //}
        return super.onOptionsItemSelected(item);
    }


    private class DownloadDBTask extends AsyncTask<String, Void, String> implements Runnable{
        private String URL_PATH="http://www.512b.it/cantiscout/php/";
        //ProgressBar prb;
        //TextView loading;
        Thread t;
        Context context;

        private DownloadDBTask(){
            //this.prb = p;
            //this.loading = loading;
        }

        @Override
        protected void onPreExecute() {
            //error.setVisibility(View.GONE);
            //prb.setVisibility(View.VISIBLE);
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
        protected void onPostExecute(String result) {
            if(result!=null)
                Toast.makeText(getApplicationContext(), getString(R.string.downloadSuccess), Toast.LENGTH_SHORT).show();
            else {
                Toast.makeText(getApplicationContext(), getString(R.string.downloadInsucces), Toast.LENGTH_LONG).show();
                saveDateOfSync();
                //Toast.makeText(getApplicationContext(), getString(R.string.databaseNotUpdated), Toast.LENGTH_SHORT).show();
                Intent cantiIntent = new Intent(getApplicationContext(), Canti.class);
                startActivity(cantiIntent);
                finish();
                return;
            }
            Log.println(Log.DEBUG, "SplashScreen", "Download2 " + result);
            if((result!=null)&&(result.indexOf("204")!=0)) {
               t=new Thread(this);
                fresult=result;
                context=getApplicationContext();
                t.start();
            } else {
                saveDateOfSync();
                Toast.makeText(getApplicationContext(), getString(R.string.databaseNotUpdated), Toast.LENGTH_SHORT).show();
                Intent cantiIntent = new Intent(getApplicationContext(), Canti.class);
                startActivity(cantiIntent);
                finish();
            }


        }

        private void insertDataOnDB(String result) {
            try {
                JSONObject jObj = new JSONObject(result);
                String elenco=jObj.getString("songlist");
                Log.println(Log.DEBUG, "SplashScreen", elenco);
                JSONArray jArr = new JSONArray(elenco);
                //QueryManager.dropAllSong(getApplicationContext());
                for (int i = 0; i < jArr.length(); i++) {
                    JSONObject obj = jArr.getJSONObject(i);
                    long ris=QueryManager.insertSong(getApplicationContext(), obj.getInt("id"), obj.getString("title"), obj.getString("author"), obj.getString("body"), obj.getString("time"));
                    Log.println(Log.DEBUG, "SplashScreen", "insert: " + obj.getString("title"));
                    if(ris==-1){
                        Log.println(Log.DEBUG, "SplashScreen", "update: " + obj.getString("title"));
                        ris=QueryManager.updateSong(getApplicationContext(), obj.getInt("id"), obj.getString("title"), obj.getString("author"), obj.getString("body"), obj.getString("time"));
                    }

                }

                elenco=jObj.getString("taglist");
                jArr = new JSONArray(elenco);
                //QueryManager.dropAllTag(getApplicationContext());
                for (int i = 0; i < jArr.length(); i++) {
                    JSONObject obj = jArr.getJSONObject(i);
                    QueryManager.insertTag(getApplicationContext(), obj.getInt("id"), obj.getInt("id_song"), obj.getString("tag"));
                    //Log.println(Log.DEBUG, "Canti", "insert: " + obj.getString("title"));
                }


                Toast.makeText(getApplicationContext(), getString(R.string.databaseUpdated), Toast.LENGTH_LONG).show();
                saveDateOfSync();
            } catch (JSONException e) {
                e.printStackTrace();
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
                    Log.println(Log.DEBUG, "SplashScreen", "UBER EXCEPTION");
                }
                if(lastSongUpdate==null)
                    lastSongUpdate="";
                Log.println(Log.DEBUG, "SplashScreen", "Upload Max " + lastSongUpdate);
                response = CustomHttpClient.executeHttpGet(URL_PATH+"get.php?max="+ Uri.encode(lastSongUpdate));

                res = response.toString();
                Log.println(Log.DEBUG, "SplashScreen", "Download1 " + res);
                //res = res.replaceAll("\\s+","");
            } catch (Exception e) {
                Log.println(Log.DEBUG, "SplashScreen", "Errore nel download ");
                //Toast.makeText(context, "Errore nel download", Toast.LENGTH_LONG).show();
            }
            return res;
        }

        public String fresult;
        @Override
        public void run() {
            Looper.prepare();
            insertDataOnDB(fresult);

            Intent cantiIntent = new Intent(context, Canti.class);
            startActivity(cantiIntent);
            finish();
            Log.println(Log.DEBUG, "Thread","Dovrei aver lanciato il nuovo intent!");
            Looper.loop();
        }
    }
}
