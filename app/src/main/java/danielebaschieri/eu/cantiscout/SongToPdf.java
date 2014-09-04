package danielebaschieri.eu.cantiscout;


import android.annotation.TargetApi;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.pdf.PdfDocument;
import android.os.Build;
import android.os.Environment;
import android.service.notification.StatusBarNotification;
import android.util.Log;
import android.view.View;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;

import apw.PDFWriter;
import apw.PaperSize;
import apw.StandardFonts;


/**
 * Created by Danger on 03/09/2014.
 */
public class SongToPdf {
    private final static String SAVING_PATH="CantiScout";

    public static String convertToPdf2(Song song,View view,Context context){
        /*WindowManager wm = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        Display display = wm.getDefaultDisplay();
        Point p=new Point();
        display.getSize(p);*/

        try {

            PDFWriter pdf = new PDFWriter(PaperSize.A4_WIDTH,PaperSize.A4_HEIGHT);
            int max= song.getSongMaxWidth();
            int paddingLeft=100;
            int tsize=12;

            Log.println(Log.DEBUG, "SongToPdf", "Max "+max);
            while(max*(tsize*0.6)>(PaperSize.A4_WIDTH-paddingLeft-paddingLeft/2)){
                tsize--;
                Log.println(Log.DEBUG, "SongToPdf", "Riduco la dimnesione del testo "+tsize);
            }

            int padding=12;
            for(int i=0;i<song.getBody().size();i++){
                if(song.getBody().get(i).isRit())
                    pdf.setFont(StandardFonts.COURIER_BOLD, StandardFonts.COURIER_BOLD);
                else
                    pdf.setFont(StandardFonts.COURIER, StandardFonts.COURIER);
                if(song.getBody().get(i).getNote()!="") {
                    padding += tsize;
                    pdf.addText(paddingLeft, PaperSize.A4_HEIGHT - padding, tsize, song.getBody().get(i).getNote());
                }
                padding+=tsize;
                String lyrics=song.getBody().get(i).getLyric();
                lyrics=convertCharacters(lyrics);
                pdf.addText(paddingLeft,PaperSize.A4_HEIGHT-padding,tsize,lyrics);

                if((padding+50)>PaperSize.A4_HEIGHT){
                    pdf.newPage();
                    padding=12;
                }
            }





            File file = new File(Environment.getExternalStoragePublicDirectory(
                    Environment.DIRECTORY_MUSIC), SAVING_PATH);
            if (android.os.Build.VERSION.SDK_INT>= Build.VERSION_CODES.KITKAT) {
                file = new File(Environment.getExternalStoragePublicDirectory(
                        Environment.DIRECTORY_DOCUMENTS), SAVING_PATH);
            }

            if (!file.mkdirs()) {
                Log.println(Log.DEBUG, "SongToPdf", "Directory not created");
            }

            Log.println(Log.DEBUG,"SongToPdf",file.getAbsolutePath()+File.separator+song.getTitle()+".pdf");
            String fileName=file.getAbsolutePath()+File.separator+song.getTitle()+".pdf";
            FileOutputStream fos=new FileOutputStream(fileName);
            PrintWriter out = new PrintWriter(fos);
            String s=pdf.asString();
            out.println(s);
            out.close();
            fos.close();
            return fileName;

        } catch (IOException e) {
            e.printStackTrace();
            Log.println(Log.DEBUG,"SongToPdf","Errore!");
        }

        return null;
    }

    public static String convertCharacters(String lyrics) {
        lyrics=lyrics.replaceAll("à","a'");
        lyrics=lyrics.replaceAll("à","a'");
        lyrics=lyrics.replaceAll("À","A'");
        lyrics=lyrics.replaceAll("Á","A'");
        lyrics=lyrics.replaceAll("ò","o'");
        lyrics=lyrics.replaceAll("ó","o'");
        lyrics=lyrics.replaceAll("Ò","O'");
        lyrics=lyrics.replaceAll("Ó","O'");
        lyrics=lyrics.replaceAll("è","e'");
        lyrics=lyrics.replaceAll("È","E'");
        lyrics=lyrics.replaceAll("É","E'");
        lyrics=lyrics.replaceAll("é","e'");
        lyrics=lyrics.replaceAll("ù","u'");
        lyrics=lyrics.replaceAll("Ù","U'");
        lyrics=lyrics.replaceAll("Ú","U'");
        lyrics=lyrics.replaceAll("ú","u'");
        lyrics=lyrics.replaceAll("ì","i'");
        lyrics=lyrics.replaceAll("Ì","I'");
        lyrics=lyrics.replaceAll("Í","I'");
        lyrics=lyrics.replaceAll("í","i'");

        return lyrics;
    }
}
