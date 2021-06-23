import 'dart:convert';

import 'package:dio/dio.dart';
import 'confirm.dart';
import 'video.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'myorders.dart';

class OrderView extends StatefulWidget {
  final Order order;

  OrderView({this.order});

  @override
  _OrderViewState createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  BuildContext context;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('リクエスト'),
        ),
        body: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            child: GestureDetector(
              child: Text(widget.order.content, style: TextStyle(fontSize: 20)),
              onLongPress: () {
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text('リクエストをコピーしました'),
                ));
                Clipboard.setData(ClipboardData(text: widget.order.content));
              },
            ),
          ),
        ),
        persistentFooterButtons: <Widget>[
          ButtonBar(
            children: <Widget>[
              RaisedButton(
                onPressed: () {
                  gocamera(context);
                },
                child: const Text('撮る', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
          ButtonBar(
            children: <Widget>[
              RaisedButton(
                onPressed: () {
                  showUploader(context);
                },
                child:
                    const Text('動画をアップロードする', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> gocamera(context) async {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return VideoView(order: widget.order);
    }));
  }

  Future<void> showUploader(BuildContext context) async {
    String filePath = await FilePicker.getFilePath(
        type: FileType.custom, allowedExtensions: ['mp4']);
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("アップロードを開始するとファンに動画が届きます。"),
          actions: <Widget>[
            RaisedButton(
              child: Text('アップロード開始', style: TextStyle(fontSize: 20.0)),
              onPressed: () {
                upload(filePath);
                Navigator.pop(_);
                Navigator.pop(_);
                Navigator.of(_).push(MaterialPageRoute(builder: (context) {
                  return ConfirmView(filePath: filePath, order: widget.order);
                }));
              },
            ),
            RaisedButton(
              child: Text('やめる', style: TextStyle(fontSize: 20.0)),
              onPressed: () => {
                Navigator.pop(_),
              },
            ),
          ],
        );
      },
    );
  }

  Future upload(filePath) async {
    try {
      var auth = 'Basic ' + base64Encode(utf8.encode('user:pass'));
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath,
            filename: filePath.split("/").last),
      });
      Dio dio = new Dio();
      await dio.post(
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
    } catch (e) {
      print(e);
      return Future.error(e);
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return FutureBuilder(
  //     future: download(),
  //     builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
  //       if (snapshot.connectionState == ConnectionState.done) {
  //         if (snapshot.hasError) {
  //           return Text(snapshot.error.toString());
  //         }
  //         setupcontroller();
  //         return _build(context);
  //       }
  //       // 非同期処理が未完了の場合にインジケータを表示する
  //       return Center(child: CircularProgressIndicator());
  //     },
  //   );
  // }

}
