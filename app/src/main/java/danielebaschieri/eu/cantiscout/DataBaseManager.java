package danielebaschieri.eu.cantiscout;

import android.content.Context;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * Created by Danger on 15/08/2014.
 */
public class DataBaseManager extends SQLiteOpenHelper {

    // Tag just for the LogCat window
    private static String TAG = "DataBaseHelper";
    // destination path (location) of our database on device
    private static String DB_PATH = "";
    private static String DB_PATH_DOWNLOAD = "";


    // Database name
    public static String DB_NAME = "song.db";
    private static final int DB_VERSION = 1;
    private SQLiteDatabase database;
    private final Context mContext;

    public DataBaseManager(Context context) {
        super(context, DB_NAME, null, DB_VERSION);// 1? its Database Version
        DB_PATH			 = "/data/data/" + context.getPackageName() + "/databases/";
        DB_PATH_DOWNLOAD = "/data/data/" + context.getPackageName() + "/";
        this.mContext = context;
    }
    @Override
    public void onCreate(SQLiteDatabase db) {
        String sql = "CREATE TABLE list";
        sql += "(_id INTEGER PRIMARY KEY,";
        sql += "title TEXT NOT NULL,";
        sql += "author TEXT,";
        sql += "time TIMESTAMP NOT NULL,";
        sql += "body TEXT NOT NULL);";

        //Eseguiamo la query
        db.execSQL(sql);


        sql = "CREATE TABLE favourite";
        sql += "(_id INTEGER PRIMARY KEY,";
        sql += "id_song INTEGER NOT NULL UNIQUE);";

        //Eseguiamo la query
        db.execSQL(sql);

        sql = "CREATE TABLE tag";
        sql += "(_id INTEGER PRIMARY KEY,";
        sql += "id_song INTEGER NOT NULL,";
        sql += "tag TEXT NOT NULL);";

        //Eseguiamo la query
        db.execSQL(sql);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int i, int i2) {

    }
}
