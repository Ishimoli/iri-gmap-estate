// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:direct/play.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'orders.dart';

class VideoView extends StatelessWidget {
  final Order order;

  VideoView({@required this.order});

  Future<List<CameraDescription>> _getArticle() async {
    // Fetch the available cameras before initializing the app.
    try {
      WidgetsFlutterBinding.ensureInitialized();
      List<CameraDescription> cameras = await availableCameras();
      return Future.value(cameras);
    } on CameraException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getArticle(),
      builder: (BuildContext context,
          AsyncSnapshot<List<CameraDescription>> snapshot) {
        if (snapshot.hasData) {
          return MaterialApp(
            home: CameraExampleHome(cameras: snapshot.data, order: order),
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

class CameraExampleHome extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Order order;

  CameraExampleHome({this.cameras, this.order});

  @override
  _CameraExampleHomeState createState() {
    return _CameraExampleHomeState();
  }
}

class _CameraExampleHomeState extends State<CameraExampleHome>
    with WidgetsBindingObserver {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  VideoPlayerController videoController;
  CameraController controller;
  String videoPath;

  @override
  void initState() {
    super.initState();
    _cameraTogglesRowWidget();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  Future<List<CameraDescription>> _getArticle() async {
    // Fetch the available cameras before initializing the app.
    try {
      WidgetsFlutterBinding.ensureInitialized();
      List<CameraDescription> cameras = await availableCameras();
      return Future.value(cameras);
    } on CameraException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Padding(
        padding: EdgeInsets.only(
          left: 10.0,
          top: 100.0,
          right: 10.0,
          bottom: 100.0,
        ),
        child: SingleChildScrollView(
          child: GestureDetector(
            child: Text(widget.order.content,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w400,
                )),
            onLongPress: () {},
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Center(
                child: _cameraPreviewWidget(),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: controller != null && controller.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          onVideoRecordButtonPressed();
        },
        child: controller != null && controller.value.isRecordingVideo
            ? Icon(Icons.stop)
            : Icon(Icons.videocam),
        backgroundColor: controller != null && controller.value.isRecordingVideo
            ? Colors.red
            : Colors.grey,
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'カメラの権限をONにしてください',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  void _cameraTogglesRowWidget() {
    if (widget.cameras.isEmpty) {
      print('No CameraLensDirection');
      return;
    }
    for (CameraDescription cameraDescription in widget.cameras) {
      if (CameraLensDirection.back == cameraDescription.lensDirection) {
        print('CameraLensDirection.back OK');
      } else if (CameraLensDirection.front == cameraDescription.lensDirection) {
        print('CameraLensDirection.front OK');
        // set front lens
        onNewCameraSelected(cameraDescription);
      } else if (CameraLensDirection.external ==
          cameraDescription.lensDirection) {
        print('CameraLensDirection.external OK');
      } else {
        print('CameraLensDirection unknown NG');
      }
    }
  }

  String timestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: true,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onVideoRecordButtonPressed() {
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isRecordingVideo) {
      stopVideoRecording().then((_) {
        if (mounted) setState(() {});
//        showInSnackBar('Video recorded to: $videoPath');
      });
    } else {
      startVideoRecording().then((String filePath) {
        if (mounted) setState(() {});
//        if (filePath != null) showInSnackBar('Saving video to $filePath');
      });
    }
  }

  Future<String> startVideoRecording() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    await Directory('${extDir.path}/').create(recursive: true);
    final String filePath = '${extDir.path}/${timestamp()}.mp4';
    // TODO path
    //final String dirPath = '/storage/emulated/0/DCIM';

    if (controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      videoPath = filePath;
      await controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    showDialog(
      context: context,
      builder: (_) {
        return _videoDialog(_, videoPath, widget.order);
      },
    );
  }

  void _showCameraException(CameraException e) {
    print(e);
//    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

Widget _videoDialog(BuildContext context, String videoPath, Order order) {
  return AlertDialog(
    title: Text("撮影、お疲れ様でした"),
    content: Text("撮影が終わりました。撮影した動画を見るか、見ずに撮り直せます。"),
    actions: <Widget>[
      FlatButton(
        child: Text("撮り直す"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      FlatButton(
        child: Text("動画を見る"),
        onPressed: () {
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return VideoPlayView(filePath: videoPath, order: order);
          }));
        },
      ),
    ],
  );
}
