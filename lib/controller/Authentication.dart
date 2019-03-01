import 'dart:async';
import '../model/User.dart';

abstract class BaseAuth {
  Future<String> signIn(String email, String password);

  Future<String> signUp(String email, String password);

  Future<User> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Future<bool> isEmailVerified();
}

class Auth implements BaseAuth {

  Future<String> signIn(String email, String password) async {
    User user = new User("Luca","luca@luca.it","afiafianfwnf");
    return user.username;
  }

  Future<String> signUp(String email, String password) async {
    User user = new User("Luca","luca@luca.it","afiafianfwnf");
    return user.username;
  }

  Future<User> getCurrentUser() async {
    User user = new User("Luca","luca@luca.it","afiafianfwnf");
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
