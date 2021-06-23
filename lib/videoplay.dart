import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';

import 'confirm.dart';
import 'myorders.dart';

class VideoPlayView extends StatefulWidget {
  final String filePath;
  final Order order;

  VideoPlayView({this.filePath, this.order});

  @override
  _VideoPlayerScreenState createState() {
    return _VideoPlayerScreenState();
  }
}

class _VideoPlayerScreenState extends State<VideoPlayView> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;
  Duration playingDuration;

  void setupcontroller() {
    _controller =
        VideoPlayerController.file(File(widget.filePath + "_converted.mp4"));
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(false);
  }

  @override
  void initState() {
    setState(() {
      playingDuration = Duration.zero;
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future download() async {
    bool isExist = await File(widget.filePath + "_converted.mp4").exists();
    if (isExist) {
      return;
    }
    try {
      var auth = 'Basic ' + base64Encode(utf8.encode('user:pass'));
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(widget.filePath,
            filename: widget.filePath.split("/").last),
      });
      Dio dio = new Dio();
      Response response = await dio.post(
        "https://direct-e225xweoqq-an.a.run.app/video/converter",
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
      File file = File(widget.filePath + "_converted.mp4");
      var raf = file.openSync(mode: FileMode.write);
      raf.writeFromSync(response.data);
      raf.closeSync();
    } catch (e) {
      print(e);
      return Future.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: download(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          setupcontroller();
          return _build(context);
        }
        // 非同期処理が未完了の場合にインジケータを表示する
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Center(
                child: FutureBuilder(
                  future: _initializeVideoPlayerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return AspectRatio(
                        aspectRatio: _controller.value.size != null
                            ? _controller.value.aspectRatio
                            : 1.0,
                        // Use the VideoPlayer widget to display the video.
                        child: VideoPlayer(_controller),
                      );
                    }
                    return Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          _controller.value.isPlaying ? Icons.stop : Icons.play_arrow,
        ),
        onPressed: () {
          if (_controller.value.isPlaying) {
            _controller.pause();
            setState(() {
              playingDuration = _controller.value.position;
            });
            showDialog(
              context: context,
              builder: (_) {
                return _playDialog(
                    _, widget.filePath + "_converted.mp4", widget.order);
              },
            );
            return;
          }
          if (_controller.value.position == _controller.value.duration) {
            _controller.seekTo(Duration.zero).then((_) => _controller.play());
            return;
          }
          _controller.seekTo(playingDuration).then((_) => _controller.play());
          return;
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

Widget _playDialog(BuildContext context, String filePath, Order order) {
  return AlertDialog(
    title: Text("この動画をファンに届けますか？"),
    content: Text(""),
    actions: <Widget>[
      RaisedButton(
        child: Text("届ける"),
        onPressed: () {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return ConfirmView(filePath: filePath, order: order);
          }));
        },
      ),
      RaisedButton(
        child: Text("撮り直す"),
        onPressed: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
      RaisedButton(
        child: Text("戻って動画を見る"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    ],
  );
}
