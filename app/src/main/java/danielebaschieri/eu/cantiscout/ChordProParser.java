package danielebaschieri.eu.cantiscout;

import android.provider.ContactsContract;
import android.util.Log;

import java.util.Scanner;
import java.util.Vector;

/**
 * Created by Danger on 15/08/2014.
 */
public class ChordProParser {

    final private String chordregex="\\[([^\\]]*)\\]";
    final private String sharpregex="#.*";
    final private String commentregex=".*\\{.*\\}.*";
    Song out=new Song("Lullaby");
    public ChordProParser(String song){

        Scanner s=new Scanner(song);

        boolean rif=false;
        while(s.hasNextLine()){

            String n=s.nextLine();
            Log.println(Log.DEBUG, "ChordPro-p", n);
            if(n.matches(sharpregex)){
                //Ignoro i commenti del codice
                Log.println(Log.DEBUG, "ChordPro", "#"+n);
            }
            else
            if(n.matches(commentregex)){
                //Gestisco i commenti di tipo title, author, cori e commenti generici
                rif = parseComment(rif, n);
            }
            else{
                boolean singleRif=false;
                //gestisco le note e il testo della canzone
                rif = parseNoteAndLyrics(rif, n, singleRif);
            }

        }
    }

    private boolean parseComment(boolean rif, String n) {
        String token=n.substring(n.indexOf("{")+1,n.lastIndexOf("}"));
        if(token.equals("soc")||token.equals("start_of_chorus")){
            rif=true;
        }
        if(token.equals("eoc")||token.equals("end_of_chorus")){
            rif=false;
        }
        if(token.indexOf(":")!=-1){
            String part[]=token.split(":");
            String corpus="";
            for(int i=1;i<(part.length-1);i++)
                    corpus+=token.split(":")[i]+":";

            corpus+=token.split(":")[part.length-1];
            token=token.split(":")[0];
            if(token.equals("title")||token.equals("t")){
                out.setTitle(capitalize(corpus));
            }
            if(token.equals("author")||token.equals("a")){
                out.setAuthor(corpus);
            }
            if(token.equals("comment")||token.equals("c")){
                //out.setAuthor(corpus);
                corpus="("+corpus+")";
            }
            out.addNoteLyrics(new NoteLyrics("",corpus,rif));
        }

        boolean singleRif=false;
        boolean go=false;
        if(n.matches("\\{soc\\}.*")&&(n.length()>5)){

            Log.println(Log.DEBUG, "ChordPro", "Ho trovato una linea strana " + n);
            n=n.substring(5,n.length());
            Log.println(Log.DEBUG, "ChordPro", "Epurata divene " + n);
            rif=true;
            go=true;
        }
        if(n.matches(".*\\{eoc\\}")&&(n.length()>5)){

            Log.println(Log.DEBUG,"ChordPro","Ho trovato una linea strana2 "+n);
            n=n.substring(0,n.length()-5);
            Log.println(Log.DEBUG, "ChordPro", "Epurata divene " + n);
            rif=true;
            singleRif=true;
            go=true;
        }
        if(go)
            rif = parseNoteAndLyrics(rif, n, singleRif);
        Log.println(Log.DEBUG, "ChordPro", "Aggiungo una linea di Commento "+n);
        return rif;
    }
    public static String capitalize(String s) {
        if (s.length() == 0) return s;
        return s.substring(0, 1).toUpperCase() + s.substring(1).toLowerCase();
    }
    private boolean parseNoteAndLyrics(boolean rif, String n, boolean singleRif) {
        String note = "";
        String lyric = "";
        String q[] = n.split(chordregex);
        int accordi = 0;
        int acc=0;
        for (int i = 0; i < q.length; i++) {
            //Log.println(Log.DEBUG,"ChordPro-find",q[i]);
            lyric += q[i];
            if(n.indexOf(",")!=-1)
                Log.println(Log.DEBUG, "ChordPro-n","INTENSIVE a "+note);

            //if ((i + 1) < q.length) {
                try {
                    //note += getSpace(q[i].length(), accordi) + n.substring(n.indexOf(q[i]) + q[i].length(), n.indexOf(q[i + 1],(n.indexOf(q[i]) + q[i].length())));
                    note += getSpace(q[i].length(), accordi) + n.substring(n.indexOf("[",acc),n.indexOf("]",acc)+1);
                    accordi = n.indexOf("]",acc)+1 - n.indexOf("[",acc);
                    acc=n.indexOf("]",acc)+1;
                    //accordi = n.indexOf(q[i + 1]) - (n.indexOf(q[i]) + q[i].length());
                }catch(Exception e){
                    //Log.println(Log.DEBUG, "ChordPro", "Start: " + (n.indexOf(q[i]) + q[i].length()));
                    //Log.println(Log.DEBUG,"ChordPro","End: "+n.indexOf(q[i + 1],(n.indexOf(q[i]) + q[i].length())));
                    Log.println(Log.DEBUG,"ChordPro","I/q.length: "+i+"/"+q.length);
                    Log.println(Log.DEBUG,"ChordPro","Molto strano "+e.getStackTrace());
                }
                if(n.indexOf(",")!=-1)
                    Log.println(Log.DEBUG, "ChordPro-n","INTENSIVE e"+note);
            /*}
            else {
                Log.println(Log.DEBUG, "ChordPro", "Taste the rainbows");
                //note += getSpace(q[i].length(), accordi) + n.substring(n.indexOf(q[i]) + q[i].length(), n.length());
                //accordi=n.length()-(n.indexOf(q[i]) + q[i].length());

                note += getSpace(q[i].length(), accordi) + n.substring(n.indexOf("[",acc),n.indexOf("]",acc)+1);
                accordi = n.indexOf("]",acc)+1 - n.indexOf("[",acc);
                acc=n.indexOf("]",acc)+1;
                if(n.indexOf(",")!=-1)
                    Log.println(Log.DEBUG, "ChordPro-n","INTENSIVE f"+note);
            }*/


        }
        /*boolean mem=false;
        for(int i=0;i<n.length();i++){
            String c="";
            if(mem)
                c=""+n.charAt(i);
                else
                c=" ";
            if(n.charAt(i)=='[') {
                c="";
                mem=true;
            }
            if(n.charAt(i)==']') {
                c="";
                mem = false;
            }
            note += "" + c;
        }*/
        note=note.replaceAll("\\[", "").replaceAll("\\]", "");

        if(note.matches(" *"))
            note="";
        Log.println(Log.DEBUG, "ChordPro-l", lyric);
        Log.println(Log.DEBUG, "ChordPro-n", note);
        out.addNoteLyrics(new NoteLyrics(note,lyric,rif));
        if(singleRif){
            singleRif=false;
            rif=false;
        }
        return rif;
    }

    public Song getSong(){
        return out;
    }
    public static String getSpace(int l,int accordi){
        String s=" ";
        for(int i=0;i<(l-accordi);i++)
               s+=" ";
        return s;
    }
}
