import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gradient_app_bar/gradient_app_bar.dart';

class MyOrdersView extends StatefulWidget {
  final FirebaseUser user;

  MyOrdersView({this.user});

  @override
  _MyOrdersState createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrdersView> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('Order')
          .where("provider", isEqualTo: widget.user.uid)
          .where("accepted", isNull: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LinearProgressIndicator();
        }
        var gradientAppBar = GradientAppBar(
          title: Text('リクエスト'),
          bottomOpacity: 0.7,
          backgroundColorStart: const Color(0xffe4a972),
          backgroundColorEnd: const Color(0xff9941d8),
        );
        return Scaffold(
          appBar: gradientAppBar,
          body: _buildList(context, snapshot.data.documents),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    if (snapshot.length == 0) {
      return Center(child: Text('リクエストはまだありません'));
    }
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final order = Order.fromSnapshot(data);
    final double width = MediaQuery.of(context).size.width - 100.0;

    return GestureDetector(
      child: Card(
        semanticContainer: true,
        margin: const EdgeInsets.only(
            top: 10.0, right: 50.0, bottom: 10.0, left: 50.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5,
        child: Container(
            width: width,
            height: width * 5 / 8,
            child: Center(
                child: Stack(
              children: <Widget>[
                // Image.network(
                //   'https://www.art-tips.com/images/paint/gradation.jpg',
                //   fit: BoxFit.cover,
                // ),
                Text(
                  order.content,
                  style: TextStyle(color: Colors.black, fontSize: 18.0),
                ),
              ],
            ))),
      ),
      onTap: () {
        print("onTap called.");
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return OrderView(order: order);
        }));
      },
    );
  }
}

class Order {
  final Timestamp accepted;
  final String content;
  final Timestamp deleted;
  final Timestamp ordered;
  final String orderer;
  final int price;
  final String provider;
  final String thumbnail;
  final String video;
  final DocumentReference reference;

  Order.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['content'] != null),
        assert(map['ordered'] != null),
        assert(map['orderer'] != null),
        assert(map['price'] != null),
        assert(map['provider'] != null),
        accepted = map['accepted'],
        content = map['content'],
        deleted = map['deleted'],
        ordered = map['ordered'],
        orderer = map['orderer'],
        price = map['price'],
        provider = map['provider'],
        thumbnail = map['thumbnail'],
        video = map['video'];

  Order.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  Map<String, dynamic> map() {
    return {
      'accepted': accepted,
      'content': content,
      'deleted': deleted,
      'ordered': ordered,
      'orderer': orderer,
      'price': price,
      'provider': provider,
      'thumbnail': thumbnail,
      'video': video
    };
  }

  @override
  String toString() => "Order<$orderer:$provider>";
}
