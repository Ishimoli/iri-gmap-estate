import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'profile.dart';
import 'request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gradient_app_bar/gradient_app_bar.dart';
import 'package:video_player/video_player.dart';

import 'myorders.dart';
import 'package:intl/intl.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Profile profile;
  FirebaseUser user;

  Future<Map<String, dynamic>> _getYourProfile() async {
    user = await FirebaseAuth.instance.currentUser();
    DocumentSnapshot docSnapshot =
        await Firestore.instance.collection("Profile").document(user.uid).get();
    return docSnapshot.data;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getYourProfile(),
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.hasData) {
          return MaterialApp(
            theme: ThemeData(
              primaryColor: Colors.orange,
            ),
            home: _loaded(context, Profile.fromMap(snapshot.data)),
          );
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          return LinearProgressIndicator();
        }
      },
    );
  }

  Widget _loaded(BuildContext context, Profile profile) {
    var gradientAppBar = GradientAppBar(
      leading: IconButton(
        icon: Icon(Icons.search),
        onPressed: () => setState(() {}),
      ),
      title: Text("What's new"),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.insert_emoticon),
          onPressed: () => setState(() {
            // プロフィール画面
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return ProfileView();
            }));
          }),
        ),
      ],
      bottomOpacity: 0.7,
      backgroundColorStart: const Color(0xffe4a972),
      backgroundColorEnd: const Color(0xff9941d8),
    );
    return Scaffold(
      appBar: gradientAppBar,
      body: Container(
        child: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            // あれば　あなたへのお知らせ
            _yourNotifications(context),
            // あれば、あなたに届いた動画・あなたが送った動画
            _yourVideo(context, profile),
            // 最近のトップスター　スクロール読み込み
            _recentVideo(context)
          ],
        ),
      ),
    );
  }

  Future<QuerySnapshot> _getYourVideo(Profile profile) async {
    if (profile.influencable) {
      return await Firestore.instance
          .collection('Order')
          .where("orderer", isEqualTo: user.uid)
          .getDocuments();
    }
    return await Firestore.instance
        .collection('Order')
        .where("provider", isEqualTo: user.uid)
        .getDocuments();
  }

  Widget _yourVideo(BuildContext context, Profile profile) {
    String yourVideoTitle = "　🎞リクエストしたビデオ";
    if (profile.influencable) {
      yourVideoTitle = "　🎞撮影したビデオ";
    }

    return FutureBuilder(
      future: _getYourVideo(profile),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          } else if (snapshot.data.documents.length == 0) {
            return Center();
          }
          List<Order> yourOrders = snapshot.data.documents
              .map<Order>((e) => Order.fromSnapshot(e))
              .toList();
          List<Widget> yourWidgets = yourOrders
              .where((e) => e.accepted != null)
              .where((e) => e.deleted == null)
              .map<Widget>((e) => _yourVideoCard(context, e, profile))
              .toList();
          if (yourWidgets.length == 0) {
            return Center();
          }
          return Container(
            color: Colors.orange,
            child: Column(
              children: <Widget>[
                Align(
                  heightFactor: 1.5,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    yourVideoTitle,
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
                Container(
                  height: 190.0,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: yourWidgets,
                  ),
                ),
              ],
            ),
          );
        }
        return LinearProgressIndicator();
      },
    );
  }

  Widget _yourVideoCard(BuildContext context, Order order, Profile profile) {
    return GestureDetector(
      child: Card(
        margin: EdgeInsets.all(10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Container(
          padding: EdgeInsets.all(5.0),
          child: Column(
            children: <Widget>[
              Image.network(
                order.thumbnail,
                height: 90.0,
              ),
              Text(
                order.orderer.substring(1, 20),
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              Text(
                DateFormat('yyyy年MM月dd日').format(order.ordered.toDate()) +
                    'にリクエスト',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Text(
                DateFormat('yyyy年MM月dd日').format(order.accepted.toDate()) +
                    'に撮影',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        showVideo(order);
      },
    );
  }

  void showVideo(Order order) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(order.orderer.substring(1, 15) + "さんに送った動画"),
          content: Column(children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('yyyy年MM月dd日').format(order.ordered.toDate()) +
                    'にリクエスト',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('yyyy年MM月dd日').format(order.accepted.toDate()) +
                    'に撮影',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
            PlayFrame(video: order.video, user: user),
          ]),
          actions: <Widget>[
            RaisedButton(
              child: Text('保存', style: TextStyle(fontSize: 20.0)),
              onPressed: () => {},
            ),
            RaisedButton(
              child: Text('閉じる', style: TextStyle(fontSize: 20.0)),
              onPressed: () => {
                Navigator.pop(_),
              },
            ),
          ],
        );
      },
    );
  }

// トップインフルエンサー一覧
  Future<QuerySnapshot> _getRecentInfluencers() async {
    return await Firestore.instance
        .collection('Profile')
        .where("influencable", isEqualTo: true)
        .getDocuments();
  }

  Widget _recentVideo(BuildContext context) {
    return FutureBuilder(
      future: _getRecentInfluencers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          } else if (snapshot.data.documents.length == 0) {
            return Center();
          }
          List<Profile> influencers = snapshot.data.documents
              .map<Profile>((e) => Profile.fromSnapshot(e))
              .toList();
          List<Widget> yourWidgets = influencers
              .where((e) => e.deleted == null)
              .map<Widget>((e) => _recentVideoCard(context, e))
              .toList();
          if (yourWidgets.length == 0) {
            return Center();
          }
          return Column(
            children: yourWidgets,
          );
        }
        return LinearProgressIndicator();
      },
    );
  }

  Widget _recentVideoCard(BuildContext context, Profile influencer) {
    return GestureDetector(
      child: Card(
          margin: const EdgeInsets.only(
              top: 10.0, right: 10.0, bottom: 10.0, left: 10.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
          elevation: 5,
          child: Hero(
            tag: "thumbnail",
            child: Container(
              padding: const EdgeInsets.only(
                  top: 5.0, right: 5.0, bottom: 5.0, left: 5.0),
              child: Column(
                children: <Widget>[
                  Image.network(
                    influencer.thumbnail,
                    width: 150.0,
                  ),
                  Text(
                    influencer.name,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return RequestView(influencer: influencer);
        }));
      },
    );
  }

// 通知
  Future<QuerySnapshot> get getNotifications async {
    return await Firestore.instance
        .collection('Notification')
        .where("reciever", isEqualTo: user.uid)
        .where("deleted", isNull: true)
        .getDocuments();
  }

  Widget _notifListItem(BuildContext context, Notification notification) {
    return GestureDetector(
      child: Card(
        margin: EdgeInsets.all(10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Container(
          width: 1000,
          margin:
              EdgeInsets.only(top: 10.0, right: 10.0, bottom: 10.0, left: 10.0),
          child: Center(
            child: Text(
              notification.message,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ),
      onTap: () async {
        if (notification.route == "orders") {
          // ファンからビデオリクエストが届いています
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            notification.deleted = DateTime.now();
            Firestore.instance
                .collection('Notification')
                .document(notification.reference.documentID)
                .setData(notification.map());
            return MyOrdersView(user: user);
          }));
        } else if (notification.route == "recieve") {
          // アイドルからビデオが届きました。
          var getNewVideo = await Firestore.instance
              .collection('Order')
              .orderBy("accepted", descending: true)
              .getDocuments();
          for (var element in getNewVideo.documents) {
            Order order = Order.fromSnapshot(element);
            if (order.orderer == user.uid) {
              showVideo(order);
              return;
            }
          }
        }
      },
    );
  }

  Widget _yourNotifications(BuildContext context) {
    return FutureBuilder(
      future: getNotifications,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          } else if (snapshot.data.documents.length == 0) {
            return Center();
          }
          List<Notification> yourNotifications = snapshot.data.documents
              .map<Notification>((e) => Notification.fromSnapshot(e))
              .toList();
          List<Widget> yourWidgets = yourNotifications
              .map<Widget>((e) => _notifListItem(context, e))
              .toList();
          if (yourWidgets.length == 0) {
            return Center();
          }
          return Container(
            color: Colors.orange,
            child: Column(
              children: yourWidgets,
            ),
          );
        }
        return LinearProgressIndicator();
      },
    );
  }
}

class Notification {
  String reciever;
  String message;
  String route;
  DateTime deleted;
  DocumentReference reference;

  Notification.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['reciever'] != null),
        assert(map['message'] != null),
        assert(map['route'] != null),
        reciever = map['reciever'],
        message = map['message'],
        route = map['route'];

  Notification.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  Map<String, dynamic> map() {
    return {
      'deleted': deleted,
      'message': message,
      'route': route,
      'reciever': reciever
    };
  }

  @override
  String toString() => "Notification<$reciever:$message>";
}

class Profile {
  final String age;
  final bool influencable;
  final DateTime deleted;
  final String name;
  final String pr;
  final String thumbnail;
  final DocumentReference reference;

  Profile.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['age'] != null),
        assert(map['influencable'] != null),
        assert(map['name'] != null),
        assert(map['pr'] != null),
        assert(map['thumbnail'] != null),
        age = map['age'],
        deleted = map['deleted'],
        influencable = map['influencable'],
        name = map['name'],
        pr = map['pr'],
        thumbnail = map['thumbnail'];

  Profile.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  @override
  String toString() => "Profile<$name:$age:$influencable>";
}

class PlayFrame extends StatefulWidget {
  final String video;
  final FirebaseUser user;

  PlayFrame({this.video, this.user});

  Future download() async {
    try {
      var auth = 'Basic ' +
          base64Encode(utf8.encode(this.user.uid + ':' + this.video));
      Dio dio = new Dio();
      Response response = await dio.get(
        "https://direct-e225xweoqq-an.a.run.app/video/get",
        options: Options(
          headers: <String, String>{'authorization': auth},
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status < 500;
          },
        ),
      );
      File file = File("download.mp4");
      var raf = file.openSync(mode: FileMode.write);
      raf.writeFromSync(response.data);
      raf.closeSync();
    } catch (e) {
      print(e);
      return Future.error(e);
    }
  }

  @override
  _PlayFrameState createState() {
    download();
    return _PlayFrameState();
  }
}

class _PlayFrameState extends State<PlayFrame> {
  VideoPlayerController _controller;
  Duration playingDuration;

  @override
  void initState() {
    super.initState();
    // widget.url
    _controller = VideoPlayerController.file(File("download.mp4"));
    //    _controller.setLooping(false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Center(
        child: _controller.value.initialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Container(),
      ),
      Center(
          child: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      )),
    ]);
  }
}
