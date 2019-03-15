import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'view/Homepage.dart';
import 'controller/AppLocalizations.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final MaterialColor primaryColorShades = MaterialColor(
    Colors.lightGreen[700].value,
    <int, Color>{
      50: Colors.lightGreen[50],
      100: Colors.lightGreen[200],
      200: Colors.lightGreen[400],
      300: Colors.lightGreen[500],
      400: Colors.lightGreen[600],
      500: Colors.lightGreen[700],
      600: Color.fromARGB(255, 37, 93, 0),
      700: Color.fromARGB(255, 37, 93, 0),
      800: Color.fromARGB(255, 37, 93, 0),
      900: Color.fromARGB(255, 37, 93, 0),
    },
  );
  /*
  final MaterialColor primaryColorShades2 = MaterialColor(
    Colors.green[900].value,
    <int, Color>{
      50: Colors.green[50],
      100: Colors.green[200],
      200: Colors.green[400],
      300: Colors.green[500],
      400: Colors.green[600],
      500: Colors.green[900],
      600: Colors.green[900],
      800: Color.fromARGB(255, 0, 51, 0),
      700: Color.fromARGB(255, 0, 51, 0),
      900: Color.fromARGB(255, 0, 51, 0),
    },
  );
  final MaterialColor primaryColorShades3 = MaterialColor(
    Colors.green[500].value,
    <int, Color>{
      50: Colors.green[50],
      100: Colors.green[100],
      200: Colors.green[200],
      300: Colors.green[300],
      400: Colors.green[400],
      500: Colors.green[500],
      600: Colors.green[500],
      800: Colors.green[600],
      700: Colors.green[700],
      900: Colors.green[800],
    },
  );*/

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //initUniLinks(context);
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      supportedLocales: [Locale("en"), Locale("it")],
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: primaryColorShades, //Colors.lightGreen,
        //primaryColor: Colors.lightGreen[800],
        //primaryColorDark: Colors.brown,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.green,
      ),
      onGenerateTitle: (BuildContext context) =>
      AppLocalizations.of(context).title,
      home: Homepage(title: "lol"), //AppLocalizations.of(context).title // MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
