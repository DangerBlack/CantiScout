
class User{
  String name;
  String mail;
  String pswd;

  bool logged = false;

  User(this.mail,this.pswd);

  factory User.noPassword(name,mail){
    User tmp=new User(mail, "");
    tmp.name = name;
    return tmp;
  }

  Map<String, String> toMap() => {
    "mail": mail,
    "pswd": pswd,
  };
}