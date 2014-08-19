package danielebaschieri.eu.cantiscout;

import android.app.ActionBar;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.net.Uri;
import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import org.w3c.dom.Text;

import java.util.Vector;


public class CantiScout extends ActionBarActivity {

    private final static String MY_PREFERENCES = "CantiScout";
    private final static String ID_SONG_KEY= "id_song";
    final public static String URL_PATH_SONG="http://www.512b.it/cantiscout/php/song.php";
    final public static String URL_PATH_REPORT="http://www.512b.it/cantiscout/report.php";
    int id_song=1;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_canti_scout);

        View linearLayout= findViewById(R.id.canzone);
        /*TextView p=new TextView(this);
        p.setText("   DO             SI");
        p.setId(5);
        p.setLayoutParams(new LinearLayout.LayoutParams(ActionBar.LayoutParams.MATCH_PARENT, ActionBar.LayoutParams.WRAP_CONTENT));
        p.setTextSize(20);
        ((LinearLayout) linearLayout).addView(p);

        TextView g=new TextView(this);
        g.setText("La seconda strofa comincia con cacca");
        g.setId(55);
        g.setLayoutParams(new LinearLayout.LayoutParams(ActionBar.LayoutParams.MATCH_PARENT, ActionBar.LayoutParams.WRAP_CONTENT));
        g.setTextSize(20);
        ((LinearLayout) linearLayout).addView(g);*/

        /*ChordProParser cpp=new ChordProParser("{comment:Chorus}\n" +
                "{start_of_chorus}\n" +
                "[D]This land is [G]your land, this land is [D]my land\n" +
                "From Cali[A7]fornia to the New York [D]Island\n" +
                "From the redwood [G]forests to the Gulf Stream [D]waters\n" +
                "[A7]This land was made for you and [D]me\n" +
                "{end_of_chorus}\n" +
                "\n" +
                "{comment:Verse 1}\n" +
                "[D]As I was [G]walking that ribbon of [D]highway\n" +
                "I looked a[A7]bove me, there in the [D]sky way\n" +
                "I saw be[G]low me the golden [D]valley\n" +
                "[A7]This land was made for you and [D]me");*/


        //Song s=cpp.getSong();
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

        //Toast.makeText(getApplicationContext(), "Funge:"+id_song, Toast.LENGTH_SHORT).show();
        Song s=QueryManager.findSong(getApplicationContext(),id_song);
        if(s!=null) {
            generateLayoutLyrics((LinearLayout) linearLayout, s);
        }
        else{
            Toast.makeText(getApplicationContext(),getString(R.string.song404),Toast.LENGTH_LONG).show();
        }
    }

    private void generateLayoutLyrics(LinearLayout linearLayout, Song s) {
        Vector<NoteLyrics> body = s.getNoteLyrics();
        for (int i = 0; i < body.size(); i++) {
            if (!body.get(i).getNote().equals("")) {
                TextView note = new TextView(this);
                note.setText(body.get(i).getNote());
                note.setId(i);
                note.setLayoutParams(new LinearLayout.LayoutParams(ActionBar.LayoutParams.MATCH_PARENT, ActionBar.LayoutParams.WRAP_CONTENT));
                //note.setTextSize(15);
                //note.setTextIsSelectable(true);
                if (body.get(i).isRit()) {
                    note.setTextColor(Color.BLUE);
                    note.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
                }
                note.setTypeface(Typeface.MONOSPACE);
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
                lyrics.setTextColor(Color.BLUE);
                lyrics.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
            }
            lyrics.setTypeface(Typeface.MONOSPACE);
            ((LinearLayout) linearLayout).addView(lyrics);
        }
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
                    if (body.get(i).isRit())
                        note.setTextColor(Color.BLUE);
                    note.setTypeface(Typeface.MONOSPACE);
                }
                TextView lyrics = (TextView) findViewById(100 + i);
                if (body.get(i).isRit())
                    lyrics.setTextColor(Color.BLUE);

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

            case R.id.report:
                Intent browserIntentStats = new Intent(Intent.ACTION_VIEW, Uri.parse(URL_PATH_REPORT+"?id="+id_song));
                startActivity(browserIntentStats);
                break;

        }

        return super.onOptionsItemSelected(item);
    }
}
