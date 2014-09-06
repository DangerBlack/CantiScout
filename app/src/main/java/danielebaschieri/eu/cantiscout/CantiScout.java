package danielebaschieri.eu.cantiscout;

import android.annotation.TargetApi;
import android.app.ActionBar;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Point;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Build;
import android.preference.PreferenceManager;
import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.TypedValue;
import android.view.Display;
import android.view.Menu;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ZoomControls;
import android.view.View.OnClickListener;

import org.w3c.dom.Text;

import java.io.File;
import java.util.Vector;


public class CantiScout extends ActionBarActivity {

    private final static String MY_PREFERENCES = "CantiScout";
    private final static String ID_SONG_KEY= "id_song";
    private final static String SIZE_SONG_KEY= "pref_size_of_text";
    final public static String URL_PATH_SONG="http://www.512b.it/cantiscout/php/song.php";
    final public static String URL_PATH_REPORT="http://www.512b.it/cantiscout/report.php";
    final public static float max_text_scale=50;
    final public static float min_text_scale=2;
    int id_song=1;
    public float textScale=12;

    @TargetApi(Build.VERSION_CODES.HONEYCOMB_MR2)
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_canti_scout);

        View linearLayout= findViewById(R.id.canzone);
        id_song=1;
        Bundle extras;
        if (savedInstanceState == null) {
            extras = getIntent().getExtras();
            if(extras == null) {
                id_song= 1;
            } else {
                id_song= extras.getInt("SONG_SELECTED_ID");
            }
        } else {
            //id= (int) savedInstanceState.getSerializable("SONG_SELECTED_ID");
            id_song=loadIdSong();
        }

        Intent intent = getIntent();
        String link = intent.getDataString();
        Log.println(Log.DEBUG,"CantiScout","HO BECCATO IL LINK "+link);
        if(link!=null){
            try {
                id_song = Integer.parseInt(link.split("\\?id=")[1]);
            }catch(Exception e){
                id_song=1;
            }
        }

        saveIdSong();
        textScale=loadSizeSong();

        //Toast.makeText(getApplicationContext(), "Funge:"+id_song, Toast.LENGTH_SHORT).show();
        Song s=QueryManager.findSong(getApplicationContext(),id_song);
        if(s!=null) {
            generateLayoutLyrics((LinearLayout) linearLayout, s);
        }
        else{
            Toast.makeText(getApplicationContext(),getString(R.string.song404),Toast.LENGTH_LONG).show();
        }

        ZoomControls zoom= (ZoomControls) findViewById(R.id.zoomControls);
        zoom.setOnZoomInClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                textScale+=2;
                if(textScale>max_text_scale)
                        textScale=max_text_scale;
                scaleTextSize(textScale);
                saveSizeSong(textScale);
            }
        });
        zoom.setOnZoomOutClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                textScale-=2;
                if(textScale<min_text_scale)
                    textScale=min_text_scale;
                scaleTextSize(textScale);
                saveSizeSong(textScale);
            }
        });

    }

    private void generateLayoutLyrics(LinearLayout linearLayout, Song s) {

        setTitle(s.getTitle());
        Vector<NoteLyrics> body = s.getNoteLyrics();
        //Typeface font = Typeface.createFromAsset(getAssets(), "fonts/SourceSansPro-Regular.ttf");

        //Typeface fontb = Typeface.createFromAsset(getAssets(), "fonts/SourceSansPro-Bold.ttf");
        for (int i = 0; i < body.size(); i++) {
            if (!body.get(i).getNote().equals("")) {
                TextView note = new TextView(this);
                note.setText(body.get(i).getNote());
                note.setId(i);
                note.setLayoutParams(new LinearLayout.LayoutParams(ActionBar.LayoutParams.MATCH_PARENT, ActionBar.LayoutParams.WRAP_CONTENT));
                //note.setTextSize(15);
                //note.setTextIsSelectable(true);
                if (body.get(i).isRit()) {
                    //note.setTextColor(Color.BLUE);
                    note.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
                }
                //note.setTypeface(font);
                note.setTypeface(Typeface.MONOSPACE);
                note.setMaxLines(1);
                //note.setTypeface(null, Typeface.ITALIC);
                ((LinearLayout) linearLayout).addView(note);
            }

            TextView lyrics = new TextView(this);
            lyrics.setText(body.get(i).getLyric());
            lyrics.setId(100 + i);
            lyrics.setLayoutParams(new LinearLayout.LayoutParams(ActionBar.LayoutParams.MATCH_PARENT, ActionBar.LayoutParams.WRAP_CONTENT));
            //lyrics.setTextSize(15);
            //lyrics.setTextIsSelectable(true);
            if (body.get(i).isRit()) {
                //lyrics.setTextColor(Color.BLUE);
                lyrics.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
            }
            //lyrics.setTypeface(font);
            lyrics.setTypeface(Typeface.MONOSPACE);
            lyrics.setMaxLines(1);
            ((LinearLayout) linearLayout).addView(lyrics);
        }

        addMoreInfoBottom(linearLayout);
        scaleTextSize(textScale);
    }
    private void saveIdSong() {
        SharedPreferences prefs = getSharedPreferences(MY_PREFERENCES, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putInt(ID_SONG_KEY,id_song);
        editor.commit();
    }
    private int loadIdSong(){
        SharedPreferences prefs = getSharedPreferences(MY_PREFERENCES, Context.MODE_PRIVATE);
        return prefs.getInt(ID_SONG_KEY, 1);
    }
    private void saveSizeSong(float size) {
        SharedPreferences sharedPrefs = PreferenceManager.getDefaultSharedPreferences(this);
        SharedPreferences.Editor editor = sharedPrefs.edit();
        editor.putString(SIZE_SONG_KEY,(new Float(size)).toString());
        editor.commit();
    }
    @TargetApi(Build.VERSION_CODES.HONEYCOMB_MR2)
    private float loadSizeSong(){
        SharedPreferences sharedPrefs = PreferenceManager.getDefaultSharedPreferences(this);
        boolean adapt=sharedPrefs.getBoolean("pref_adapt_checkbox", false);
        if(adapt){

            double width=getScreenSize();
            Song s=QueryManager.findSong(getApplicationContext(),id_song);
            int max=s.getSongMaxWidth();
            DisplayMetrics metrics = getResources().getDisplayMetrics();
            float densityDpi =(metrics.density);
            /**
             * We add some magic number in order to display the text in correct width.
             * We absolutely don't know why it works and we hope a future bugfix in order
             * to fix this weird stuff
             * 6.4 = 320/50 (50 number of character in a line) (320 = default width of screen with density 1)
             * 12 = default width of a character height
             * 0.8 = ratio of a character 12*0.8= character width
             */
            width=width/(6.4*densityDpi);
            Log.println(Log.DEBUG,"CantiScout","WIDTH="+width+" #LET="+max+" PROP="+(float)((width/max)*12*0.8)+" DENS="+densityDpi);
            return (float)((width/max)*12*0.8);
        }else {
            SharedPreferences prefs2 = PreferenceManager.getDefaultSharedPreferences(this);
            String siz=prefs2.getString(SIZE_SONG_KEY,"12");
            Log.println(Log.DEBUG,"CantiScout","SIZE OF TEXT IN PREF "+siz);
            float f=Float.parseFloat(siz);
            return f;//prefs.getFloat(SIZE_SONG_KEY, 12);
        }
    }

    @TargetApi(Build.VERSION_CODES.HONEYCOMB_MR2)
    public int getScreenSize(){
        if (android.os.Build.VERSION.SDK_INT>= Build.VERSION_CODES.HONEYCOMB_MR2) {
            Display display = getWindowManager().getDefaultDisplay();
            Point size = new Point();
            display.getSize(size);
            return size.x;
        }else {
            Display display = getWindowManager().getDefaultDisplay();
            int width = display.getWidth();  // deprecated
            return width;
        }
    }
    public void addMoreInfoBottom(LinearLayout linearLayout){
        for (int i = 0; i < 3; i++) {
            TextView info = new TextView(this);
            info.setMaxLines(1);
            ((LinearLayout) linearLayout).addView(info);
        }
    }
    @Override
    protected void onResume() {
        // TODO Auto-generated method stub
        super.onResume();

        id_song=loadIdSong();
        Log.println(Log.DEBUG,"CantiScout","Ho caricato dalla memoria la canzone "+id_song);
        Song s=QueryManager.findSong(getApplicationContext(),id_song);
        if(s!=null) {
            Vector<NoteLyrics> body = s.getNoteLyrics();
            for (int i = 0; i < body.size(); i++) {

                if (!body.get(i).getNote().equals("")) {
                    TextView note = (TextView) findViewById(i);
                    if (body.get(i).isRit()){
                        //note.setTextColor(Color.BLUE);
                        note.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
                    }
                    note.setTypeface(Typeface.MONOSPACE);

                }
                TextView lyrics = (TextView) findViewById(100 + i);
                if (body.get(i).isRit()){
                    //lyrics.setTextColor(Color.BLUE);
                    lyrics.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
                }
                lyrics.setTypeface(Typeface.MONOSPACE);
            }
        }
        scaleTextSize(textScale);
    }
    private void scaleTextSize(float size){
        id_song=loadIdSong();
        Log.println(Log.DEBUG,"CantiScout","Ho caricato dalla memoria la canzone "+id_song);
        Song s=QueryManager.findSong(getApplicationContext(),id_song);
        if(s!=null) {
            Vector<NoteLyrics> body = s.getNoteLyrics();
            for (int i = 0; i < body.size(); i++) {
                if (!body.get(i).getNote().equals("")) {
                    TextView note = (TextView) findViewById(i);
                    note.setTextSize(TypedValue.COMPLEX_UNIT_SP,size);
                }
                TextView lyrics = (TextView) findViewById(100 + i);
                lyrics.setTextSize(TypedValue.COMPLEX_UNIT_SP,size);
            }
        }
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.canti_scout, menu);
        MenuItem favMenu = menu.findItem(R.id.addFavourite);
        if(QueryManager.isFav(getApplicationContext(),id_song)){
            Log.println(Log.DEBUG,"CantiScout","La canzone è già nei preferiti "+id_song);
            favMenu.setTitle(R.string.unfavourite);
            favMenu.setChecked(true);
        }else{
            Log.println(Log.DEBUG,"CantiScout","La canzone non è tra i preferiti "+id_song);
            //favMenu.setChecked(false);
        }
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
        if (id == R.id.addFavourite) {
            if (item.isChecked()) {
                item.setChecked(false);
                QueryManager.removeFav(getApplicationContext(),id_song);
                Toast.makeText(getApplicationContext(),getString(R.string.unfavourite),Toast.LENGTH_SHORT).show();
                item.setTitle(R.string.favourite);
            }else{
                item.setChecked(true);
                QueryManager.insertFav(getApplicationContext(),id_song);
                Toast.makeText(getApplicationContext(),getString(R.string.favourite),Toast.LENGTH_SHORT).show();
                item.setTitle(R.string.unfavourite);
            }


            return super.onOptionsItemSelected(item);
        }

        switch(id){
            case R.id.share:
                Intent sendIntent = new Intent();
                sendIntent.setAction(Intent.ACTION_SEND);
                sendIntent.putExtra(Intent.EXTRA_TEXT, URL_PATH_SONG + "?id=" + id_song);
                sendIntent.setType("text/plain");
                startActivity(sendIntent);
            break;

            case R.id.export:
                Song song=QueryManager.findSong(getApplicationContext(),id_song);
                View linearLayout= findViewById(R.id.canzone);
                String fileName= SongToPdf.convertToPdf2(song,linearLayout,getApplicationContext());
                if(fileName.indexOf("/Documents/")!=-1){
                    fileName=fileName.substring(fileName.indexOf("/Documents/"));
                }else{
                    if(fileName.indexOf("/Music/")!=-1){
                        fileName=fileName.substring(fileName.indexOf("/Music/"));
                    }
                }
                Toast.makeText(getApplicationContext(), getString(R.string.pdfSavedSuccessfully)+"\n"+fileName, Toast.LENGTH_LONG).show();
                openPdfView(fileName);
                break;

            case R.id.report:
                Intent browserIntentStats = new Intent(Intent.ACTION_VIEW, Uri.parse(URL_PATH_REPORT+"?id="+id_song));
                startActivity(browserIntentStats);
                break;

            case R.id.settings:
                Intent settingScreen = new Intent(getApplicationContext(), SettingsActivity.class);
                startActivity(settingScreen);
                break;

        }

        return super.onOptionsItemSelected(item);
    }

    private void openPdfView(String fileName) {
        File pdfFile = new File(fileName);
        if(pdfFile.exists())
        {
            Uri path = Uri.fromFile(pdfFile);
            Intent pdfIntent = new Intent(Intent.ACTION_VIEW);
            pdfIntent.setDataAndType(path, "application/pdf");
            pdfIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);

            try
            {
                startActivity(pdfIntent);
            }
            catch(ActivityNotFoundException e)
            {
                Toast.makeText(getApplicationContext(), getString(R.string.noPdfProgram), Toast.LENGTH_LONG).show();
            }
        }
    }
}
