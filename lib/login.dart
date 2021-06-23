import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home.dart';

// FYI:https://qiita.com/iketeruhiyoko/items/7d0718bc6210ed545913

enum FormType { login, register }

class LoginView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final formKey = GlobalKey<FormState>();

  String _name;
  String _age;
  String _email;
  String _password;
  String _message;
  bool _flag = false;
  FormType _formType = FormType.login;

  @override
  initState() {
    setState(() {
      _message = "";
    });
    super.initState();
  }

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void validateAndSubmit() async {
    if (validateAndSave()) {
      if (_formType == FormType.login) {
        try {
          FirebaseUser user = (await FirebaseAuth.instance
                  .signInWithEmailAndPassword(
                      email: _email, password: _password))
              .user;
          print('Singed in: ${user.uid}');
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) {
            return HomeView();
          }));
        } catch (e) {
          String msg = e.toString();
          if (msg.contains("ERROR_WRONG_PASSWORD")) {
            setState(() {
              _message = "パスワードが違います";
            });
          } else {
//          if (msg.contains("ERROR_USER_NOT_FOUND")) {
            setState(() {
              _message = "そのアカウントはまだ登録されていません";
            });
          }
        }
        return;
      }
      if (!_flag) {
        setState(() {
          _message = "利用規約とプライバシーポリシーに同意してください";
        });
        return;
      }
      try {
        FirebaseUser user = (await FirebaseAuth.instance
                .createUserWithEmailAndPassword(
                    email: _email, password: _password))
            .user;
        print('Registered User: ${user.uid}');
        Map<String, dynamic> data = {
          'age': _age,
          'deleted': null,
          'influencable': false,
          'name': _name,
          'pr': '-',
          'thumbnail': '-'
        };
        await Firestore.instance
            .collection('Profile')
            .document(user.uid)
            .setData(data)
            .then((value) {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) {
            return HomeView();
          }));
        });
      } catch (e) {
        String msg = e.toString();
        if (msg.contains("ERROR_EMAIL_ALREADY_IN_USE")) {
          setState(() {
            _message = "そのアカウントは既に登録されています";
          });
        } else {
          setState(() {
            _message = "アカウントを登録できません（" + msg + "）";
          });
        }
      }
    }
  }

  List<Widget> buildInputs() {
    if (_formType == FormType.register) {
      return [
        TextFormField(
          decoration: InputDecoration(labelText: 'あなたの名前'),
          validator: (value) => value.isEmpty ? 'あなたの名前を入れてください' : null,
          onSaved: (value) => _name = value,
        ),
        DropdownButtonFormField(
          decoration: InputDecoration(labelText: 'あなたの年齢'),
          items: <DropdownMenuItem>[
            DropdownMenuItem(
              value: "10代",
              child: Text("10代"),
            ),
            DropdownMenuItem(
              value: "20代",
              child: Text("20代"),
            ),
            DropdownMenuItem(
              value: "30代",
              child: Text("30代"),
            ),
            DropdownMenuItem(
              value: "40代",
              child: Text("40代"),
            ),
            DropdownMenuItem(
              value: "50代",
              child: Text("50代"),
            ),
            DropdownMenuItem(
              value: "60代",
              child: Text("60代"),
            ),
            DropdownMenuItem(
              value: "70代",
              child: Text("70代"),
            ),
            DropdownMenuItem(
              value: "80代以上",
              child: Text("80代以上"),
            ),
          ],
          onChanged: (value) => _age = value,
        ),
        TextFormField(
          decoration: InputDecoration(labelText: 'メールアドレス'),
          validator: (value) => value.isEmpty ? 'メールアドレスを入れてください' : null,
          onSaved: (value) => _email = value,
        ),
        TextFormField(
          decoration: InputDecoration(labelText: '希望のパスワード'),
          obscureText: true,
          validator: (value) => value.isEmpty ? '希望のパスワードを入れてください' : null,
          onSaved: (value) => _password = value,
        ),
        FlatButton(
          child: Text('利用規約', style: TextStyle(fontSize: 14.0)),
          onPressed: () {},
        ),
        FlatButton(
          child: Text('プライバシーポリシー', style: TextStyle(fontSize: 14.0)),
          onPressed: () {},
        ),
        Row(
          children: [
            Checkbox(
              activeColor: Colors.blue,
              value: _flag,
              onChanged: (bool e) {
                setState(() {
                  _flag = e;
                });
              },
            ),
            Text('利用規約とプライバシーポリシーに同意する', style: TextStyle(fontSize: 14.0)),
          ],
        )
      ];
    }
    return [
      TextFormField(
        decoration: InputDecoration(labelText: 'メールアドレス'),
        validator: (value) =>
            value.isEmpty ? 'メールアドレスを入れてください' : null, // 将来的に or ログインIDを用意する
        onSaved: (value) => _email = value,
      ),
      TextFormField(
        decoration: InputDecoration(labelText: 'パスワード'),
        obscureText: true,
        validator: (value) => value.isEmpty ? 'パスワードを入れてください' : null,
        onSaved: (value) => _password = value,
      ),
    ];
  }

  List<Widget> buildSubmitButtons() {
    if (_formType == FormType.login) {
      return [
        Text(
          '$_message',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        RaisedButton(
          child: Text(
            'ログイン',
            style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w600),
          ),
          onPressed: validateAndSubmit,
        ),
        FlatButton(
          child: Text('アカウント登録はこちら', style: TextStyle(fontSize: 14.0)),
          onPressed: () {
            setState(() {
              _formType = FormType.register;
              _message = "";
            });
          },
        ),
      ];
    } else {
      return [
        Text(
          '$_message',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        RaisedButton(
          child: Text('アカウントを登録', style: TextStyle(fontSize: 20.0)),
          onPressed: validateAndSubmit,
        ),
        FlatButton(
          child: Text('ログインはこちら', style: TextStyle(fontSize: 14.0)),
          onPressed: () {
            formKey.currentState.reset();
            setState(() {
              _formType = FormType.login;
              _message = "";
            });
          },
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: FractionalOffset.topLeft,
            end: FractionalOffset.bottomRight,
            colors: [
              const Color(0xffe4a972).withOpacity(0.6),
              const Color(0xff9941d8).withOpacity(0.6),
            ],
            stops: const [
              0.0,
              1.0,
            ],
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: buildInputs() + buildSubmitButtons(),
            ),
          ),
        ),
      ),
    );
  }
}
