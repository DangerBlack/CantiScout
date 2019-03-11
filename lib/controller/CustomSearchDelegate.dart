import 'package:flutter/material.dart';
import '../view/SongUlSearch.dart';
//https://medium.com/flutterpub/implementing-search-in-flutter-17dc5aa72018

class CustomSearchDelegate extends SearchDelegate {

  SongUlSearch songsState;
  CustomSearchDelegate():super(){
    print("Costruisco songState 1 ");
    this.songsState = new SongUlSearch(query);
  }

  String needle="";

  CustomSearchDelegate.builder(String text):super(){
    print("Costruisco songState 2 ");
    print(text);
    query = text;
    needle = text;
    this.songsState = new SongUlSearch(query);
  }
  
  @override
  List<Widget> buildActions(BuildContext context) {
    // TODO: implement buildActions
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
            query = "";
            needle="";
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    if(needle!="") {
      query = needle;
      needle="";
    }
    // TODO: implement buildLeading
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
      /*return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Text(
              "Search term must be longer than two letters.",
            ),
          )
        ],
      );*/
      print("Richiedo songState ");
      this.songsState = new SongUlSearch(query);
      return new SongUlSearchStateful(title:"titolo",search:query, state: songsState);
  }


  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    //return new SongUlSearchStateful(title:"titolo",search:query);

    //this.songsState.updateList(query);

    print("cambia la query ["+query+"]");
    if(this.songsState == null || !this.songsState.mounted){
      this.songsState = new SongUlSearch(query);
    }else {
      this.songsState.updateListS(query);
    }
    return new SongUlSearchStateful(title:"titolo 2",search:query, state: songsState);//this.songsState;
  }

}