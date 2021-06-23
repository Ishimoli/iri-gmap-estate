import 'package:flutter/material.dart';
import 'root.dart';

class StartApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          primaryColor: Colors.blueGrey[800],
        ),
        home: RootView());
  }
}

void main() async {
  runApp(StartApp());
}
