package danielebaschieri.eu.cantiscout;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import java.util.Vector;

/**
 * Created by Danger on 15/08/2014.
 */
public class QueryManager {

    public static void dropAllSong(Context context){
        DataBaseManager dbManager=new DataBaseManager(context);
        SQLiteDatabase db = dbManager.getWritableDatabase();
        db.delete("list","'a'='a'",null);
    }
    public static void dropAllTag(Context context){
        DataBaseManager dbManager=new DataBaseManager(context);
        SQLiteDatabase db = dbManager.getWritableDatabase();
        db.delete("tag","'a'='a'",null);
    }
    public static void insertSong(Context context,int id,String title,String author,String body,String time)throws SQLException {
        DataBaseManager dbManager=new DataBaseManager(context);
        SQLiteDatabase db = dbManager.getWritableDatabase();
        ContentValues contentValues = new ContentValues();
        contentValues.put("_id",id);
        contentValues.put("title",title);
        contentValues.put("author",author);
        contentValues.put("body",body);
        contentValues.put("time",time);
        db.insert("list",null,contentValues);
    }

    public static void insertFav(Context context,int id_song)throws SQLException {
        DataBaseManager dbManager=new DataBaseManager(context);
        SQLiteDatabase db = dbManager.getWritableDatabase();
        ContentValues contentValues = new ContentValues();
        contentValues.put("id_song",id_song);
        db.insert("favourite",null,contentValues);
        Log.println(Log.DEBUG,"QueryManager","Aggiunta canzone "+id_song);
    }

    public static void insertTag(Context context,int id,int id_song,String tag)throws SQLException {
        DataBaseManager dbManager=new DataBaseManager(context);
        SQLiteDatabase db = dbManager.getWritableDatabase();
        ContentValues contentValues = new ContentValues();
        contentValues.put("_id",id);
        contentValues.put("id_song",id_song);
        contentValues.put("tag",tag);
        db.insert("tag",null,contentValues);
    }
    public static void removeFav(Context context,int id_song){
        DataBaseManager dbManager=new DataBaseManager(context);
        SQLiteDatabase db = dbManager.getWritableDatabase();
        long row=db.delete("favourite","id_song='"+id_song+"'",null);
        Log.println(Log.DEBUG,"QueryManager","Rimossa canzone "+id_song+" cancellate "+row);
    }
    public static Vector<Couple> findListOfTitle(Context context){
        DataBaseManager dbManager=new DataBaseManager(context);
        SQLiteDatabase db = dbManager.getWritableDatabase();
        final String sql = "SELECT _id,title FROM list ORDER BY title";
        Vector<Couple> list=new Vector<Couple>();
        Cursor c = db.rawQuery(sql, null);
        if(c.moveToFirst()){
            do{
                list.add(new Couple(getId(c),getTitle(c)));
            } while(c.moveToNext());
        }
        return list;
    }

    public static Vector<Couple> findListOfTitleOld(Context context,String filter){
        DataBaseManager dbManager=new DataBaseManager(context);
        SQLiteDatabase db = dbManager.getWritableDatabase();
        final String sql = "SELECT _id,title FROM list WHERE title LIKE '%"+filter+"%' ORDER BY title";
        Vector<Couple> list=new Vector<Couple>();
        Cursor c = db.rawQuery(sql, null);
        if(c.moveToFirst()){
            do{
                list.add(new Couple(getId(c),getTitle(c)));
            } while(c.moveToNext());
        }
        return list;
    }
    public static Vector<Couple> findListOfTitle(Context context,String filter){
        DataBaseManager dbManager=new DataBaseManager(context);
        SQLiteDatabase db = dbManager.getWritableDatabase();
        final String sql = "SELECT l._id,l.title FROM list AS l LEFT JOIN tag AS t ON l._id=t.id_song WHERE l.title LIKE '%"+filter+"%' OR t.tag LIKE '%"+filter+"%' GROUP BY l._id ORDER BY l.title";
        Vector<Couple> list=new Vector<Couple>();
        Cursor c = db.rawQuery(sql, null);
        if(c.moveToFirst()){
            do{
                list.add(new Couple(getId(c),getTitle(c)));
            } while(c.moveToNext());
        }
        return list;
    }
    public static Vector<Couple> findListOfTitleFav(Context context){
        DataBaseManager dbManager=new DataBaseManager(context);
        SQLiteDatabase db = dbManager.getWritableDatabase();
        final String sql = "SELECT l._id,l.title FROM list AS l,favourite AS f WHERE l._id=f.id_song ORDER BY title";
        Vector<Couple> list=new Vector<Couple>();
        Cursor c = db.rawQuery(sql, null);
        if(c.moveToFirst()){
            do{
                list.add(new Couple(getId(c),getTitle(c)));
            } while(c.moveToNext());
        }
        return list;
    }
    public static Song findSong(Context context,int id){
        DataBaseManager dbManager=new DataBaseManager(context);
        SQLiteDatabase db = dbManager.getWritableDatabase();
        final String sql = "SELECT title,author,body FROM list WHERE _id='"+id+"'";
        Cursor c = db.rawQuery(sql, null);
        if(c.moveToFirst()){
               return new Song(getTitle(c),getAuthor(c),getBody(c));
        }
        return null;
    }

    public static String getMax(Context context){
        DataBaseManager dbManager=new DataBaseManager(context);
        SQLiteDatabase db = dbManager.getWritableDatabase();
        final String sql = "SELECT MAX(time) AS max FROM list";
        Cursor c = db.rawQuery(sql, null);
        if(c.moveToFirst()){
            return getMax(c);
        }
        return "";
    }

    public static boolean isFav(Context context,int id_song){
        DataBaseManager dbManager=new DataBaseManager(context);
        SQLiteDatabase db = dbManager.getWritableDatabase();
        final String sql = "SELECT * FROM favourite WHERE id_song='"+id_song+"'";
        Cursor c = db.rawQuery(sql, null);
        Log.println(Log.DEBUG,"QueryManager","Il cursore conta "+c.getCount());
        if(c.getCount()>0){
            return true;
        }
        return false;
    }
    private static String getColumnValue(Cursor cur, String ColumnName) {
        try {
            return cur.getString(cur.getColumnIndex(ColumnName));
        } catch (Exception ex) {
            return "";
        }
    }
    private static String getTitle(Cursor c){
        return getColumnValue(c, "title");
    }
    private static String getAuthor(Cursor c){
        return getColumnValue(c, "author");
    }
    private static String getBody(Cursor c){
        return getColumnValue(c, "body");
    }
    private static int getId(Cursor c){
        return Integer.parseInt(getColumnValue(c, "_id"));
    }
    private static String getMax(Cursor c){
        return getColumnValue(c, "max");
    }
}
