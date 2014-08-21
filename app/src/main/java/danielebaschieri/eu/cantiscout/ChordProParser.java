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
            NoteLyrics nl=L(n);
            if(nl.getNote().matches(" *"))
                nl.setNote("");
            if((nl!=null)&&(nl.getLyric()!=""))
                out.addNoteLyrics(nl);
            if(n.equals("")){
                out.addNoteLyrics(new NoteLyrics("","",rif));
            }
        }
    }
    boolean rif=false;
    private NoteLyrics L(String input){
        if(input.matches(sharpregex)){
            Log.println(Log.DEBUG, "ChordPro-#", input);
            return new NoteLyrics("","",false);
        }
        else {
            return M(input);
        }
    }
    private NoteLyrics M(String input){
        if (input.matches(commentregex)) {
                int pG=input.indexOf("{");
                int pC=input.indexOf("}",pG)+1;
                String comment= input.substring(pG,pC);
                if(pG==0){

                    String rest= input.substring(pC,input.length());
                    Log.println(Log.DEBUG, "ChordPro-M1", input+" ["+comment+" "+rest+"]");
                    NoteLyrics nl=new NoteLyrics("","",false);
                    nl.sumNoteLyrics(C(comment));
                    nl.sumNoteLyrics(M(rest));
                    return nl;
                }else{
                    String rest= input.substring(0,pG);
                    String commentRest= input.substring(pG,input.length());
                    Log.println(Log.DEBUG, "ChordPro-M2", input+" ["+rest+" "+commentRest+"]");
                    NoteLyrics nl=new NoteLyrics("","",false);
                    nl.sumNoteLyrics(M(rest));
                    nl.sumNoteLyrics(M(commentRest));
                    return nl;
                }
        }
        else{
            Log.println(Log.DEBUG, "ChordPro-M", input);
            return parseNoteAndLyrics(rif, input);
        }
    }
    private NoteLyrics C(String input){
        Log.println(Log.DEBUG, "ChordPro-C", input);
        return parseComment(input);
    }
    private NoteLyrics parseComment(String n) {
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
            return new NoteLyrics(getSpace(corpus.length(),0),corpus,rif);
        }
        return new NoteLyrics("","",rif);
    }
    public static String capitalize(String s) {
        if (s.length() == 0) return s;
        return s.substring(0, 1).toUpperCase() + s.substring(1).toLowerCase();
    }
    private NoteLyrics parseNoteAndLyrics(boolean rif, String n) {
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

        }
        note=note.replaceAll("\\[", "").replaceAll("\\]", "");

        if(note.matches(" *"))
            note="";
        Log.println(Log.DEBUG, "ChordPro-l", lyric);
        Log.println(Log.DEBUG, "ChordPro-n", note);
        NoteLyrics nl=new NoteLyrics(note,lyric,rif);
        return nl;
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
