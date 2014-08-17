package danielebaschieri.eu.cantiscout;

/**
 * Created by Danger on 15/08/2014.
 */
public class NoteLyrics{
    String note;
    String lyric;
    boolean rit;
    public NoteLyrics(String note,String lyric,boolean rit){
        this.note=note;
        this.lyric=lyric;
        this.rit=rit;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }

    public String getLyric() {
        return lyric;
    }

    public void setLyric(String lyric) {
        this.lyric = lyric;
    }

    public boolean isRit() {
        return rit;
    }

    public void setRit(boolean rit) {
        this.rit = rit;
    }
}
