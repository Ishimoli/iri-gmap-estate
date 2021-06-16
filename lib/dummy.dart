import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'orders.dart';

class DummyView extends StatefulWidget {
  DummyView();
  @override
  _DummyViewState createState() => _DummyViewState();
}

class _DummyViewState extends State<DummyView> {
  String username = "";
  @override
  initState() {
    FirebaseAuth.instance
        .currentUser()
        .then((currentUser) => {
              setState(() {
                username = currentUser.email;
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
                  'ダミー画面 ($username)',
                  style: TextStyle(color: Colors.black, fontSize: 18.0),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return MyOrders();
          }));
        },
        child: Icon(Icons.keyboard_return),
      ),
    );
  }
}
