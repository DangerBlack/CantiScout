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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      supportedLocales: [Locale("en"), Locale("it")],
      title: "",
      theme: ThemeData(
        primarySwatch: primaryColorShades,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: true,
      home: Homepage(),
    );
  }
}
