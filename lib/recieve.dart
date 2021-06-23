import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'myorders.dart';
import 'payinfo.dart';

class RecieveView extends StatefulWidget {
  final Profile influencer;
  RecieveView({this.influencer});
  @override
  _RecieveViewState createState() => _RecieveViewState();
}

class _RecieveViewState extends State<RecieveView> {
  TextEditingController _textEditingController = TextEditingController();
  FirebaseUser user;
  VideoService service;
  Map<String, dynamic> cardObj;

  void _textEditListener() {}

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
    _textEditingController.addListener(_textEditListener);
  }

  @override
  void dispose() {
    _textEditingController.removeListener(_textEditListener);
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topLeft,
          padding:
              EdgeInsets.only(left: 5.0, top: 40.0, right: 5.0, bottom: 30.0),
          child: Column(
            children: <Widget>[
              Align(
                heightFactor: 1.8,
                child: Text(
                  widget.influencer.name,
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Row(
                children: <Widget>[
                  Hero(
                    tag: "thumbnail",
                    child: Image.network(
                      widget.influencer.thumbnail,
                      width: 180.0,
                    ),
                  ),
                  Flexible(
                    child: Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.only(
                          left: 5.0, top: 0.0, right: 5.0, bottom: 0.0),
                      child: Column(
                        children: <Widget>[
                          Text(
                            widget.influencer.pr,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 10,
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                          ),
//                          _socialNetworkButtons(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              //              _howToRequest(),
              _videoServiceList(context),
            ],
          ),
        ),
      ),
    );
  }

  Future<QuerySnapshot> get _getVideoServices async {
    return await Firestore.instance
        .collection('VideoService')
        .where("provider", isEqualTo: widget.influencer.reference.documentID)
        .getDocuments();
  }

  Widget _videoServiceList(BuildContext context) {
    return FutureBuilder(
      future: _getVideoServices,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          } else if (snapshot.data.documents.length == 0) {
            return Center();
          }
          List<VideoService> services = snapshot.data.documents
              .map<VideoService>((e) => VideoService.fromSnapshot(e))
              .toList();
          if (services.length == 0) {
            return Center();
          }
          return Column(children: <Widget>[
            Align(
              heightFactor: 1.6,
              child: Text(
                services[0].price.toString() + "円",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            ),
            _request(services[0])
          ]);
        }
        return LinearProgressIndicator();
      },
    );
  }

  Future<Map<String, dynamic>> _initPayjp() async {
    try {
      if (user == null) {
        return null;
      }
      final formData = {"id": user.uid};
      var response = await http
          .post('https://direct-e225xweoqq-an.a.run.app/cards', body: formData);
      cardObj = json.decode(response.body);
      if (response.statusCode >= 400) {
        throw ApiException(cardObj['message']);
      }
      return cardObj;
    } on SocketException catch (e) {
      throw ApiException(e.message);
    }
  }

  Widget _request(VideoService service) {
    return FutureBuilder(
      future: _initPayjp(),
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.length == 0) {
            return Container(
              margin: EdgeInsets.only(top: 20.0, bottom: 20.0),
              child: RaisedButton(
                child: Text("クレジットカードを登録する"),
                color: Colors.orange,
                textColor: Colors.white,
                splashColor: Colors.purple,
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return PayInfoView();
                  }));
                },
              ),
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 20.0, bottom: 20.0),
                  child: TextFormField(
                    controller: _textEditingController,
                    decoration: InputDecoration(
                      hintText: '誕生日なので一曲歌ってください。呼び名は',
                      enabledBorder: new OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: 2.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.orange,
                          width: 2.0,
                        ),
                      ),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                RaisedButton(
                  child: Text("この内容でリクエストする"),
                  color: Colors.orange,
                  textColor: Colors.white,
                  splashColor: Colors.purple,
                  onPressed: () {
                    Order request = Order.fromMap({
                      'content': _textEditingController.text,
                      'ordered': Timestamp.now(),
                      'orderer': user.uid,
                      'price': service.price,
                      'provider': widget.influencer.reference.documentID,
                    });
                    showDialog(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          content: Column(children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "この内容でリクエストします",
                                style: TextStyle(fontSize: 16.0),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _textEditingController.text,
                                style: TextStyle(fontSize: 16.0),
                              ),
                            ),
                          ]),
                          actions: <Widget>[
                            RaisedButton(
                              child: Text("リクエスト"),
                              color: Colors.orange,
                              textColor: Colors.white,
                              splashColor: Colors.purple,
                              onPressed: () => {
                                Navigator.pop(_),
                                Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (context) {
                                  return RequestedView(request: request);
                                }))
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                )
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          // 非同期処理が未完了の場合にインジケータを表示する
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class RequestedView extends StatefulWidget {
  final Order request;
  RequestedView({this.request});
  @override
  _RequestedViewState createState() => _RequestedViewState();
}

class _RequestedViewState extends State<RequestedView> {
  Future<void> _addData(Map<String, dynamic> data) async {
    await Firestore.instance
        .collection('Order')
        .add(data)
        .then((value) => print(value));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _addData(widget.request.map()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          return Container(
            child: Center(
              child: Text(
                'リクエスト完了画面',
                style: TextStyle(color: Colors.black, fontSize: 18.0),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
            ),
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class VideoService {
  final String title;
  final String content;
  final String provider;
  final int price;
  final DocumentReference reference;

  VideoService.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['content'] != null),
        assert(map['provider'] != null),
        assert(map['price'] != null),
        title = map['title'],
        content = map['content'],
        provider = map['provider'],
        price = map['price'];

  VideoService.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  @override
  String toString() => "VideoService<$provider:$price>";
}
