import 'package:flutter/material.dart';
import '../view/SongUlSearch.dart';
import '../view/SongUl.dart';
import '../Database.dart';
//https://medium.com/flutterpub/implementing-search-in-flutter-17dc5aa72018

class CustomSearchDelegate extends SearchDelegate {
  //final SongUl songUl;
  CustomSearchDelegate():super();

  String needle="";

  CustomSearchDelegate.builder(String text):super(){
    print(text);
    query = text;
    needle = text;
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
      return SongUlSearchStateful(title:"titolo",search:query);
  }

  updateList(String search) async {
    List<Widget> w=new List<Widget>();
    List<String> titles =  await DBProvider.db.getSongsTitle(search);
    titles.forEach((s){
      w.add(Text(s));
    });
    return Column(
      children: w,
    );
  }
  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    //return new SongUlSearchStateful(title:"titolo",search:query);


    return Column();
  }

}