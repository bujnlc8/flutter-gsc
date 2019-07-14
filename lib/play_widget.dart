import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';

class PlayAudioWidget extends StatefulWidget {
  final String playUrl;

  @override
  _PlayAudioWidgetState createState() {
    return new _PlayAudioWidgetState();
  }

  PlayAudioWidget({Key key, @required this.playUrl})
      : assert(playUrl.length > 0),
        super(key: key);
}

class _PlayAudioWidgetState extends State<PlayAudioWidget> {
  // 是否在播放
  bool isPlaying;

  // 播放链接
  String playUrl;

  final AudioPlayer audioPlayer = new AudioPlayer();

  @override
  void initState() {
    super.initState();
    isPlaying = false;
    playUrl = widget.playUrl;
  }

  @override
  void didUpdateWidget(PlayAudioWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (playUrl != widget.playUrl) {
      audioPlayer.pause();
      setState(() {
        isPlaying = false;
        playUrl = widget.playUrl;
      });
    }
  }

  _PlayAudioWidgetState() {
    audioPlayer.onPlayerStateChanged.listen((onData) {
      if (onData == AudioPlayerState.STOPPED) {
        setState(() {
          playUrl = widget.playUrl;
          isPlaying = false;
        });
      }
    }, onError: (msg) {
      setState(() {
        playUrl = widget.playUrl;
        isPlaying = false;
      });
      debugPrint(msg);
    });
  }

  void togglePlaying() async {
    if (!isPlaying) {
      await audioPlayer.play(widget.playUrl);
    } else {
      await audioPlayer.pause();
    }
    setState(() {
      isPlaying = !isPlaying;
      playUrl = widget.playUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isPlaying) {
      return GestureDetector(
          child: Icon(Icons.pause), onTap: () => {this.togglePlaying()});
    } else {
      return GestureDetector(
          child: Icon(Icons.play_arrow), onTap: () => {this.togglePlaying()});
    }
  }
}