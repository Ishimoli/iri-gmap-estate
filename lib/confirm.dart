import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'home.dart';
import 'payinfo.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'myorders.dart';

class ConfirmView extends StatefulWidget {
  final String filePath;
  final Order order;

  ConfirmView({this.filePath, this.order});

  @override
  _ConfirmViewScreenState createState() {
    return _ConfirmViewScreenState();
  }
}

class _ConfirmViewScreenState extends State<ConfirmView> {
  // TODO 同じものがorder.dartにあり
  Future<Map<String, String>> upload(filePath) async {
    try {
      var auth = 'Basic ' + base64Encode(utf8.encode('user:pass'));
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath,
            filename: filePath.split("/").last),
      });
      Dio dio = new Dio();
      Response response = await dio.post(
        "https://direct-e225xweoqq-an.a.run.app/video/upload",
        data: formData,
        options: Options(
          method: "POST",
          headers: <String, String>{'authorization': auth},
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status < 500;
          },
        ),
      );
      print(response.data.toString());
      return json.decode(response.data..toString());
    } catch (e) {
      print(e);
      return Future.error(e);
    }
  }

  Future<void> _updateData() async {
    upload(widget.filePath).then((Map<String, String> response) {
      pay(widget.order);
      Firestore.instance
          .collection('Order')
          .document(widget.order.reference.documentID)
          .updateData({
        'accepted': Timestamp.now(),
        'thumbnail':
            "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcTZ-rmh-erWDimF31VyWv8u_I_eyUV8nlNG3g&usqp=CAU",
        'video': response['video']
      });
    });
  }

  Future pay(Order request) async {
    try {
      final formData = {
        "card": request.price.toString(),
        "id": request.orderer,
        "amount": request.price.toString()
      };
      var response = await http.post(
          'https://direct-e225xweoqq-an.a.run.app/cards/pay',
          body: formData);
      final body = json.decode(response.body);
      if (response.statusCode >= 400) {
        throw ApiException(body['message']);
      }
    } on SocketException catch (e) {
      throw ApiException(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _updateData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          return Scaffold(
            body: Container(
              child: Center(
                child: Text(
                  "ファンに送られました",
                  style: TextStyle(color: Colors.black, fontSize: 18.0),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
            ),
            floatingActionButton: FloatingActionButton(
              child: Icon(Icons.keyboard_return),
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return HomeView();
                }));
              },
            ),
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
