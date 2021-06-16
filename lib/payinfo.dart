/*
 * Copyright (c) 2020 PAY, Inc.
 *
 * Use of this source code is governed by a MIT License that can by found in the LICENSE file.
 */

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/material.dart' as material show Card;
import 'package:payjp_flutter/payjp_flutter.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

//使えるカード一覧：https://pay.jp/docs/testcard
//

class PayInfoView extends StatefulWidget {
  final FirebaseUser user;

  PayInfoView({this.user});

  @override
  _PayInfoViewState createState() => _PayInfoViewState();
}

class _PayInfoViewState extends State<PayInfoView> {
  FirebaseUser user;
  Map<String, dynamic> cardObj;

  @override
  void initState() {
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

  Future<Map<String, dynamic>> _initPayjp() async {
    // TODO _initPayjp例外が起きると画面がローディングだけになる
    await Payjp.init(
        publicKey: 'pk_test_ce4bad8bfbfb4e73bb569d7d',
        debugEnabled: true,
        threeDSecureRedirect: PayjpThreeDSecureRedirect(
            url: 'jp.pay.example://tds/finish', key: 'mobileapp'));
    if (Platform.isIOS) {
      await Payjp.setIOSCardFormStyle(
        labelTextColor: Colors.black87,
        inputTextColor: Colors.blue[700],
        errorTextColor: Colors.red,
        submitButtonColor: Colors.blue[800],
      );
      var isApplePayAvailable = false;
      isApplePayAvailable = await Payjp.isApplePayAvailable();
    }
    try {
      if (user == null) {
        return null;
      }
      final formData = {"id": user.uid};
      var response = await http
          .post('https://direct-e225xweoqq-an.a.run.app/cards', body: formData);
      cardObj = json.decode(response.body);
      if (response.statusCode == 404) {
        return cardObj;
      }
      if (response.statusCode >= 400) {
        throw ApiException(cardObj['message']);
      }
      return cardObj;
    } on SocketException catch (e) {
      throw ApiException(e.message);
    }
  }

  bool _isLoading = true;

  Future<void> saveCard(Token token) async {
    try {
      final formData = {
        "card": token.id,
        "id": user.uid,
        "email": user.email,
        "description": "test"
      };
      var response = await http.post(
          'https://direct-e225xweoqq-an.a.run.app/cards/save',
          body: formData);
      final body = json.decode(response.body);
      if (response.statusCode >= 400) {
        throw ApiException(body['message']);
      }
    } on SocketException catch (e) {
      throw ApiException(e.message);
    }
  }

  FutureOr<CallbackResult> _onCardFormProducedToken(Token token) async {
    try {
      await saveCard(token);
    } on ApiException catch (e) {
      return CallbackResultError(e.message);
    }
    return CallbackResultOk();
  }

  void _onCardFormCompleted() {
    // カード情報を登録した
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return PayInfoView();
    }));
  }

  void _onCardFormCanceled() {
    // ユーザーがカードフォームをキャンセル
    print('_onCardFormCanceled');
  }

  void _onStartCardForm({CardFormType formType}) async {
    await Payjp.startCardForm(
        onCardFormCanceledCallback: _onCardFormCanceled,
        onCardFormCompletedCallback: _onCardFormCompleted,
        onCardFormProducedTokenCallback: _onCardFormProducedToken,
        cardFormType: formType);
  }

  Widget _build(BuildContext context) {
    // https://pay.jp/d/customers
    if (cardObj['count'] == 0) {
      return ListView(
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          GestureDetector(
            child: material.Card(
              child: ListTile(
                title: Text('クレジットカードで支払う'),
              ),
            ),
            onTap: _onStartCardForm,
          ),
          // material.Card(
          //   child: ListTile(
          //     title: Text('Start ApplePay Sample (iOS only)'),
          //     subtitle: Text(_canUseApplePay
          //         ? 'Sample payment with Apple Pay.'
          //         : 'This device is not supported.'),
          //     enabled: _canUseApplePay,
          //     onTap: _onStartApplePay,
          //   ),
          // ),
        ],
      );
    }
    List<dynamic> card = cardObj["cards"];
    Map<String, dynamic> defaultcard = card[0];
    return ListView(
      padding: EdgeInsets.all(16.0),
      children: <Widget>[
        GestureDetector(
          child: material.Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Text(defaultcard["brand"]),
                  title:
                      Text('****-****-****-' + defaultcard["last4"].toString()),
                  subtitle: Text(defaultcard["name"]),
                  trailing: Text(defaultcard["exp_year"].toString() +
                      '/' +
                      defaultcard["exp_month"].toString()),
                ),
              ],
            ),
          ),
          onTap: _onStartCardForm,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("決済情報"),
      ),
      body: FutureBuilder(
        future: _initPayjp(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data['count'] == 0) {
              return _build(context);
            }
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class ApiException implements Exception {
  String message;
  ApiException(this.message);
}
