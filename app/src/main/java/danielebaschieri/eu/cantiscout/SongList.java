package danielebaschieri.eu.cantiscout;

import android.annotation.TargetApi;
import android.app.ActionBar;
import android.app.SearchManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Build;
import android.os.Parcelable;
import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.support.v7.widget.SearchView;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.webkit.WebSettings;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Vector;


public class SongList extends ActionBarActivity implements View.OnClickListener {

    final private String DEFAULT_FILTER="none";
    final private String FAV_FILTER="favourite";
    private String filter="none";
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_song_list);

        Bundle extras;
        if (savedInstanceState == null) {
            extras = getIntent().getExtras();
            if(extras == null) {
                filter= DEFAULT_FILTER;
            } else {
                filter= extras.getString("FILTER_BY");
                if(filter==null){
                    filter=DEFAULT_FILTER;
                }
            }
        } else {
            //filter= (String) savedInstanceState.getSerializable("FILTER_BY");
        }

        createInterface();

        Intent intent = getIntent();
        if (Intent.ACTION_SEARCH.equals(intent.getAction())) {
            String query = intent.getStringExtra(SearchManager.QUERY);
            stop=true;
            doMySearch(query);
        }



    }
    boolean stop=false;
    ListView listOfSong;
    private void createInterface() {
        listOfSong= (ListView)findViewById(R.id.listOfSong);

        Vector<Couple> lista=new Vector<Couple>();
        if(filter.equals(DEFAULT_FILTER))
            lista= QueryManager.findListOfTitle(getApplicationContext());

        if(filter.equals(FAV_FILTER))
            lista=QueryManager.findListOfTitleFav(getApplicationContext());

        renderList(listOfSong, lista);

    }

    private static final String LIST_STATE = "listState";
    private Parcelable mListState = null;
    @Override
    protected void onRestoreInstanceState(Bundle state) {
        super.onRestoreInstanceState(state);
        mListState = state.getParcelable(LIST_STATE);
    }
    @Override
    protected void onSaveInstanceState(Bundle state) {
        super.onSaveInstanceState(state);
        mListState = getListView().onSaveInstanceState();
        state.putParcelable(LIST_STATE, mListState);
    }
    public ListView getListView(){
        return listOfSong;
    }
    @Override
    protected void onResume() {
        super.onResume();
        if(!stop)
            createInterface();
        else
           stop=false;

        if (mListState != null)
            getListView().onRestoreInstanceState(mListState);
        mListState = null;
    }
    public void doMySearch(String query){
        ListView listOfSong= (ListView)findViewById(R.id.listOfSong);
        Vector<Couple> lista=new Vector<Couple>();
        lista=QueryManager.findListOfTitle(getApplicationContext(),query);
        Log.println(Log.DEBUG,"SongList","Trovati "+lista.size());

        renderList(listOfSong, lista);
    }

    private void renderList(ListView listOfSong, Vector<Couple> lista) {
        final ArrayList<String> list = new ArrayList<String>();
        for (int i = 0; i < lista.size(); ++i) {
            list.add(lista.get(i).getTitle());
        }

        final StableArrayAdapter adapter = new StableArrayAdapter(this,
                android.R.layout.simple_list_item_1, list,lista);
        listOfSong.setAdapter(adapter);

        listOfSong.setOnItemClickListener(new AdapterView.OnItemClickListener() {

            @Override
            public void onItemClick(AdapterView<?> parent, final View view,
                                    int position, long id) {
                final String item = (String) parent.getItemAtPosition(position);
                Intent gate = new Intent(getApplicationContext(), CantiScout.class);
                gate.putExtra("SONG_SELECTED_ID",(int)id);
                startActivity(gate);
            }

        });
    }

    private class StableArrayAdapter extends ArrayAdapter<String> {

        HashMap<String, Integer> mIdMap = new HashMap<String, Integer>();

        public StableArrayAdapter(Context context, int textViewResourceId,
                                  List<String> objects,Vector<Couple> lista) {
            super(context, textViewResourceId, objects);
            for (int i = 0; i < objects.size(); ++i) {
                mIdMap.put(objects.get(i), lista.get(i).getId());
            }
        }

        @Override
        public long getItemId(int position) {
            String item = getItem(position);
            return mIdMap.get(item);
        }

        @Override
        public boolean hasStableIds() {
            return true;
        }

    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.song_list, menu);

        configureSearchMenu(menu);
        return super.onCreateOptionsMenu(menu);
    }

    @TargetApi(Build.VERSION_CODES.HONEYCOMB)
    public void configureSearchMenu(Menu menu){

        if (android.os.Build.VERSION.SDK_INT>=android.os.Build.VERSION_CODES.HONEYCOMB) {
            SearchManager searchManager = (SearchManager) getSystemService(Context.SEARCH_SERVICE);
            SearchView searchView = (SearchView) menu.findItem(R.id.action_search).getActionView();

            searchView.setSearchableInfo(searchManager.getSearchableInfo(getComponentName()));
            searchView.setIconifiedByDefault(false); // Do not iconify the widget; expand it by default
        }
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

        switch (item.getItemId()) {
            case R.id.LC:
                doMySearch("lupetti");
                break;
            case R.id.EG:
                doMySearch("reparto");
                break;
            case R.id.RS:
                doMySearch("lupetti");
                break;
            case R.id.messa:
                doMySearch("messa");
                break;

        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onClick(View view) {
        //Toast.makeText(getApplicationContext(),"Funziona",Toast.LENGTH_SHORT).show();
        Intent gate = new Intent(getApplicationContext(), CantiScout.class);
        gate.putExtra("SONG_SELECTED_ID",view.getId());
        startActivity(gate);

    }
}
