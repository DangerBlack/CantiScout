package danielebaschieri.eu.cantiscout;

import java.util.Vector;

/**
 * Created by Danger on 15/08/2014.
 */
public class Song{
    String title;
    String author;
    Vector<NoteLyrics> body=new Vector<NoteLyrics>();
    public Song(String title){

    }
    public Song(String title,String author,String body){
        ChordProParser cpp=new ChordProParser(body);
        Song s=cpp.getSong();
        this.title=s.getTitle();
        this.author=s.getAuthor();
        this.body=s.getBody();
    }
    public void addNoteLyrics(NoteLyrics nl){
        body.add(nl);
    }
    public Vector<NoteLyrics> getNoteLyrics(){
        return body;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public Vector<NoteLyrics> getBody() {
        return body;
    }
    public void setBody(Vector<NoteLyrics> body) {
        this.body = body;
    }
}
