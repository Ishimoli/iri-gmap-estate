import 'package:direct/orders.dart';
import 'package:direct/payinfo.dart';
import 'package:direct/root.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatefulWidget {
  ProfileView();
  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  FirebaseUser user;

  @override
  initState() {
    FirebaseAuth.instance
        .currentUser()
        .then((currentUser) => {
              setState(() {
                user = currentUser;
              })
            })
        .catchError((err) => print(err));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Center(
                child: Text(
                  '個人情報・プロフィール画面 ' + user.email,
                  style: TextStyle(color: Colors.black, fontSize: 18.0),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
            ),
          ),
          RaisedButton(
            child: Text('リクエスト一覧', style: TextStyle(fontSize: 20.0)),
            onPressed: () {},
          ),
          RaisedButton(
            child: Text('決済方法', style: TextStyle(fontSize: 20.0)),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return PayInfoView();
              }));
            },
          ),
          RaisedButton(
            child: Text('利用規約', style: TextStyle(fontSize: 20.0)),
            onPressed: () {
              //この中に利用規約の画面遷移を記入
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                //return KiyakuInfoView();
              }));
            },
          ),
          RaisedButton(
            child: Text('プライバシーポリシー', style: TextStyle(fontSize: 20.0)),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                //return PpInfoView();
              }));
            },
          ),
          RaisedButton(
            child: Text('ログアウト', style: TextStyle(fontSize: 20.0)),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) {
                return RootView();
              }));
            },
          ),
          RaisedButton(
            child:
                Text('自分にきたリクエスト（インフルエンサー）', style: TextStyle(fontSize: 20.0)),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return MyOrders(user: user);
              }));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Icon(Icons.keyboard_return),
      ),
    );
  }
}
