package danielebaschieri.eu.cantiscout;

/**
 * Created by Danger on 15/08/2014.
 */
public class Couple {
    int id;
    String title;
    public Couple(int id,String title){
        this.id=id;
        this.title=title;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }
}
