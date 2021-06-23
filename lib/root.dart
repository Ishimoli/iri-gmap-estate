import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home.dart';
import 'login.dart';

class RootView extends StatefulWidget {
  RootView({Key key}) : super(key: key);

  @override
  _RootViewState createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  @override
  initState() {
    FirebaseAuth.instance.currentUser().then((currentUser) {
      if (currentUser == null) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) {
          return LoginView();
        }));
      } else {
        Firestore.instance
            .collection("users")
            .document(currentUser.uid)
            .get()
            .then((DocumentSnapshot result) {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) {
            return HomeView();
          }));
        }).catchError((err) => print(err));
      }
    }).catchError((err) => print(err));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.blueGrey[800],
      ),
      home: Scaffold(
        body: Center(
          child: Container(
            child: Text("Loading..."),
          ),
        ),
      ),
    );
  }
}
