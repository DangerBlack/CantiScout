import 'dart:async';
import 'dart:convert';
import '../model/User.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/Constants.dart';

abstract class BaseAuth {
  Future<String> signIn(String email, String password);

  Future<String> signUp(String email, String password);

  Future<User> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Future<bool> isEmailVerified();
}

class Auth implements BaseAuth {

  static final tokenApi = 'https://512b.it/cantiscout/api/';

  Future<String> signIn(String email, String password) async {
    print("working");
    User user = new User(email,password);
    print(user.toMap());
    final response = await http.post(tokenApi+"token", body: json.encode(user.toMap()));
    print("sent");
    if (response.statusCode == 200) {
      print("yeah");
      print(response.body);
      final jsonData = json.decode(response.body);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(Constants.sharedMail, email);
      prefs.setString(Constants.sharedToken, jsonData["token"]);
      prefs.setString(Constants.sharedName, jsonData["name"]);
      return user.mail;
    }else{
      print(response.body);
      print("Unautorized!");
      return null;
    }

  }

  Future<String> signUp(String email, String password) async {
    User user = new User("luca@luca.it","afiafianfwnf");
    return user.name;
  }

  Future<User> getCurrentUser() async {
    User user = new User("luca@luca.it","afiafianfwnf");
    return user;
  }

  Future<void> signOut() async {

  }

  Future<void> sendEmailVerification() async {

  }

  Future<bool> isEmailVerified() async {
    return true;
  }

}
