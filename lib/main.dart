import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controller/AppLocalizations.dart';
import 'model/Constants.dart';
import 'view/Homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrapUsername();
  runApp(const MyApp());
}

Future<void> _bootstrapUsername() async {
  final prefs = await SharedPreferences.getInstance();
  if ((prefs.getString(Constants.sharedUsername) ?? '').isNotEmpty) return;
  const adjectives = [
    'Veloce', 'Forte', 'Saggio', 'Coraggioso', 'Agile',
    'Fedele', 'Furbo', 'Vivace', 'Ardito', 'Pronto',
  ];
  const animals = [
    'Lupo', 'Volpe', 'Aquila', 'Orso', 'Cervo',
    'Falco', 'Lontra', 'Castoro', 'Lince', 'Gufo',
  ];
  final rng = Random();
  final name = adjectives[rng.nextInt(adjectives.length)] +
      animals[rng.nextInt(animals.length)];
  await prefs.setString(Constants.sharedUsername, name);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF558B2F); // lightGreen[700]
    final primarySwatch = MaterialColor(primary.toARGB32(), const <int, Color>{
      50: Color(0xFFF1F8E9),
      100: Color(0xFFDCEDC8),
      200: Color(0xFFAED581),
      300: Color(0xFF8BC34A),
      400: Color(0xFF7CB342),
      500: Color(0xFF558B2F),
      600: Color(0xFF255D00),
      700: Color(0xFF255D00),
      800: Color(0xFF255D00),
      900: Color(0xFF255D00),
    });

    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      title: '',
      theme: ThemeData(primarySwatch: primarySwatch),
      darkTheme: ThemeData(primarySwatch: Colors.green),
      debugShowCheckedModeBanner: false,
      home: const Homepage(),
    );
  }
}
