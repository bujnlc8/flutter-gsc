import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:audioplayer/audioplayer.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:image_picker_saver/image_picker_saver.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'gsc.dart';

const mainColor = Color.fromARGB(255, 98, 91, 87);
const backgroundColor = Color.fromARGB(255, 0xe9, 0xe9, 0xe9);

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new MyAppState();
  }
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver{
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title: 'i古诗词',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        backgroundColor: backgroundColor,
        primaryColor: mainColor,
      ),
      home: MyHomePage(
        //title: 'i古诗词',
        gsc: null,
        from: "",
      ),
    );
  }

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('$state');
    if(state == AppLifecycleState.paused){
      dB.db.close();
      dB.db = null;
    }
  }
  @override
  void dispose(){
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class MyHomePage extends StatefulWidget {
  final Gsc gsc;
  final String from;
  MyHomePage({Key key, this.title, this.gsc, this.from}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final searchHistoryKey = "__search_history__";

  Gsc _gsc;
  bool searchLike;
  bool loading;

  // 当前选中的项目
  int currentSelect;
  List<Gsc> gscList;
  List<String> _searchHistory;
  bool showHistorySearch;

  @override
  void initState() {
    _gsc = widget.gsc;
    searchLike = false;
    loading = false;
    showHistorySearch = true;
    gscList = [];
    _searchHistory = [];
    if (_gsc != null) {
      if (widget.from == "author") {
        editController.text = _gsc.workAuthor;
        search(_gsc.workAuthor);
      } else {
        editController.text = _gsc.workTitle;
        search(_gsc.workTitle);
      }
    } else {
      getHomeGsc();
    }
    currentSelect = -1;
    getSearchHistory();
    super.initState();
  }

  style(i) {
    if (currentSelect == i) {
      return TextStyle(
          height: 1.5, fontSize: 18, fontFamily: "songkai", color: mainColor);
    }
    return TextStyle(height: 1.5, fontSize: 16, fontFamily: "songti");
  }

  workTitleStyle(i) {
    if (currentSelect == i) {
      return TextStyle(
          height: 1.5,
          fontSize: 18,
          fontFamily: "songkai",
          fontWeight: FontWeight.w600,
          color: mainColor);
    }
    return TextStyle(
        height: 1.5,
        fontSize: 16,
        fontFamily: "songti",
        fontWeight: FontWeight.w600);
  }

  shortContentStyle(i) {
    if (i == currentSelect) {
      return TextStyle(
          height: 1.5, fontSize: 17, fontFamily: "songkai", color: mainColor);
    } else {
      return TextStyle(height: 1.5, fontSize: 15, fontFamily: "songti");
    }
  }

  HttpClient httpClient = new HttpClient();

  final homeAip = "https://igsc.wx.haihui.site/songci/index/all/b";
  final searchAip =
      "https://igsc.wx.haihui.site/songci/query/{inputText}/main/b";

  var editController = TextEditingController();
  var _contentFocusNode = FocusNode();

  void getHomeGsc() async {
    gscList = [];
    setState(() {
      currentSelect = -1;
      loading = true;
    });
    HttpClientRequest request =
        await httpClient.getUrl(Uri.parse(this.homeAip));
    request.headers.set("user-agent", "iGsc/1.0.0");
    HttpClientResponse response = await request.close();
    String resp = await response.transform(utf8.decoder).join();
    var gscs = jsonDecode(resp)["data"]["data"];
    gscList = [];
    for (var i = 0; i < gscs.length; i++) {
      gscList.add(Gsc(gscs[i]));
    }
    setState(() {
      currentSelect = -1;
      loading = false;
      gscList = gscList;
    });
  }

  // 跳转到详情
  void goToDetail(int index) {
    setState(() {
      currentSelect = index;
    });
    Navigator.push(
      context,
      new MaterialPageRoute(
          builder: (context) =>
              new GscDetailScreen(gscs: gscList, index: index)),
    );
  }

  Future<void> _refresh() async {
    search(null);
  }

  Widget renderListView() {
    if (loading) {
      return getProgressDialog();
    }
    return RefreshIndicator(
        displacement: 10,
        color: mainColor,
        backgroundColor: backgroundColor,
        onRefresh: _refresh,
        child: ListView.builder(
            itemCount: gscList.length,
            itemBuilder: (context, index) {
              var gsc = gscList[index];
              return new GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    goToDetail(index);
                  },
                  onDoubleTap: () {
                    goToDetail(index);
                  },
                  child: Column(
                    children: <Widget>[
                      Flex(direction: Axis.horizontal, children: <Widget>[
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: new EdgeInsets.only(
                                    left: 16, right: 16, top: 2),
                                child: Text(
                                  gsc.workTitle,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: workTitleStyle(index),
                                ),
                              ),
                              Padding(
                                padding: new EdgeInsets.only(
                                    left: 16, right: 16, top: 4),
                                child: Text(gsc.shortContent,
                                    softWrap: true,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: shortContentStyle(index)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Padding(
                                padding: new EdgeInsets.only(right: 16),
                                child: () {
                                  if (gsc.audioId > 0) {
                                    return Icon(
                                      Icons.audiotrack,
                                      size: 16,
                                    );
                                  }
                                }(),
                              ),
                              Padding(
                                padding: new EdgeInsets.only(right: 16),
                                child: Text(
                                    "【" +
                                        gsc.workDynasty +
                                        "】" +
                                        gsc.workAuthor.toString(),
                                    textAlign: TextAlign.end,
                                    style: style(index)),
                              )
                            ],
                          ),
                        )
                      ]),
                      Padding(
                        padding: EdgeInsets.only(left: 14, right: 14),
                        child: Divider(
                            height: 16.0, indent: 0, color: Colors.grey),
                      )
                    ],
                  ));
            }));
  }

  search(searchText) async {
    if (loading) {
      return;
    }
    setState(() {
      currentSelect = -1;
      loading = true;
      gscList = [];
    });
    String inputText;
    if (searchText == null) {
      inputText = editController.text.trim();
    } else {
      inputText = searchText;
    }
    // 只搜索喜欢
    if (searchLike) {
      var maps = [];
      if (inputText.length > 0) {
        maps = await dB.query(
            "gsc_like",
            ["*"],
            " `like` = 1 and (work_title like '%?%' or work_author like '%?%' or content like '%?%') group by id order by audio_id desc"
                .replaceAll("?", inputText),
            []);
      } else {
        maps = await dB.query("gsc_like", ["*"],
            "`like` = 1 group by id order by audio_id desc", []);
      }
      gscList = [];
      for (var i = 0; i < maps.length; i++) {
        gscList.add(new Gsc.fromDictionary(maps[i]));
      }
      setState(() {
        currentSelect = -1;
        loading = false;
        gscList = gscList;
      });
      return;
    }
    Uri uri;
    var key = "search_" + inputText;
    var gscs = [];
    var cacheData;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (inputText.length == 0) {
      uri = Uri.parse(homeAip);
    } else {
      cacheData = prefs.get(key);
      if (cacheData != null) gscs = json.decode(cacheData);
      uri = Uri.parse(searchAip.replaceAll("{inputText}", inputText));
    }
    if (cacheData == null) {
      HttpClientRequest request = await httpClient.getUrl(uri);
      request.headers.set("User-Agent", "iGsc/1.0.0");
      HttpClientResponse response = await request.close();
      var resp = await response.transform(utf8.decoder).join();
      gscs = jsonDecode(resp)["data"]["data"];
    }
    gscList = [];
    List<String> __searchHistory = prefs.getStringList(searchHistoryKey);
    if (inputText.length > 0) {
      if (__searchHistory == null) {
        __searchHistory = [inputText];
      } else {
        if (__searchHistory.indexOf(inputText) == -1) {
          __searchHistory.add(inputText);
        }
      }
      prefs.setStringList(searchHistoryKey, __searchHistory);
      if (cacheData == null) {
        prefs.setString(key, json.encode(gscs));
      }
    }
    for (var i = 0; i < gscs.length; i++) {
      gscList.add(Gsc(gscs[i]));
    }
    setState(() {
      currentSelect = -1;
      loading = false;
      gscList = gscList;
      _searchHistory = __searchHistory;
    });
  }

  getProgressDialog() {
    return Center(
        child: new CupertinoActivityIndicator(
      radius: 25,
    ));
  }

  Function genOnChange() {
    if (!loading) {
      return (e) {
        setState(() {
          searchLike = e;
        });
        search(null);
      };
    } else {
      return null;
    }
  }

  getSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> __searchHistory = prefs.getStringList(searchHistoryKey);
    if (__searchHistory != null)
      setState(() {
        _searchHistory = __searchHistory;
      });
  }

  Widget renderHistory() {
    if (_searchHistory != null &&
        _searchHistory.length > 0 &&
        showHistorySearch) {
      var result = [];
      var total = _searchHistory.length;
      for (var i = total - 1; i >= 0; i--) {
        if (result.length >= 8) {
          break;
        }
        result.add(Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            GestureDetector(
                child: Text(
                  _searchHistory[i],
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                      color: Colors.grey, fontFamily: "songkai", fontSize: 14),
                ),
                onTap: () {
                  editController.text = _searchHistory[i];
                  search(_searchHistory[i]);
                }),
            IconButton(
              alignment: Alignment.topCenter,
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                List<String> __searchHistory =
                    prefs.getStringList(searchHistoryKey);
                __searchHistory.remove(_searchHistory[i]);
                prefs.setStringList(searchHistoryKey, __searchHistory);
                setState(() {
                  _searchHistory = __searchHistory;
                });
              },
              icon: Icon(Icons.clear),
              iconSize: 12,
            ),
          ],
        ));
      }
      return Wrap(children: result.cast<Widget>());
    } else {
      return Container(width: 0, height: 0);
    }
  }

  Widget renderSearchHistory() {
    if (_searchHistory != null && _searchHistory.length > 0) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Padding(
                  child: Text("搜索历史:",
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 16, fontFamily: "songti")),
                  padding: EdgeInsets.only(left: 16),
                ),
                GestureDetector(
                  child: Padding(
                    child: () {
                      if (showHistorySearch) {
                        return Icon(
                          Icons.clear_all,
                          size: 18,
                        );
                      } else {
                        return Icon(
                          Icons.dehaze,
                          size: 14,
                        );
                      }
                    }(),
                    padding: EdgeInsets.only(left: 12),
                  ),
                  onTap: () {
                    setState(() {
                      showHistorySearch = !showHistorySearch;
                    });
                  },
                )
              ],
            ),
            Padding(
              child: renderHistory(),
              padding: EdgeInsets.only(left: 16, top: 2, bottom: 0),
            )
          ]);
    }
    return Container(width: 0, height: 0);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: PreferredSize(
            child: new AppBar(
              elevation: 0,
              backgroundColor: backgroundColor,
              brightness: Brightness.light,
            ),
            preferredSize: Size.zero),
        backgroundColor: backgroundColor,
        body: new Align(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(top: 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                // Column is also layout widget. It takes a list of children and
                // arranges them vertically. By default, it sizes itself to fit its
                // children horizontally, and tries to be as tall as its parent.
                //
                // Invoke "debug painting" (press "p" in the console, choose the
                // "Toggle Debug Paint" action from the Flutter Inspector in Android
                // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
                // to see the wireframe for each widget.
                //
                // Column has various properties to control how it sizes itself and
                // how it positions its children. Here we use mainAxisAlignment to
                // center the children vertically; the main axis here is the vertical
                // axis because Columns are vertical (the cross axis would be
                // horizontal).
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 0, top: 10, bottom: 0),
                        child: TextFormField(
                            cursorColor: mainColor,
                            focusNode: _contentFocusNode,
                            autofocus: false,
                            style: TextStyle(
                                color: Colors.blueGrey, fontFamily: "songti"),
                            maxLines: 1,
                            strutStyle: StrutStyle(fontStyle: FontStyle.italic),
                            controller: editController,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.search,
                            onEditingComplete: () {
                              _contentFocusNode.unfocus();
                              search(null);
                            },
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.0),
                                    borderSide: BorderSide(color: mainColor)),
                                isDense: false,
                                hintText: '请输入搜索内容',
                                suffixIcon: IconButton(
                                    iconSize: 18,
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      if (editController.text.trim() != "") {
                                        getHomeGsc();
                                      }
                                      // editController.text = "";
                                      editController.clear();
                                      _contentFocusNode.unfocus();
                                    }),
                                contentPadding: EdgeInsets.all(12.0))),
                      )),
                      IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            _contentFocusNode.unfocus();
                            search(null);
                          },
                          padding: const EdgeInsets.only(
                              left: 0, right: 0, top: 10, bottom: 0)),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Padding(
                        child: Text("只搜喜欢:",
                            style:
                                TextStyle(fontSize: 16, fontFamily: "songti")),
                        padding: EdgeInsets.only(left: 16, top: 5, bottom: 0),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 6, top: 5, bottom: 0),
                        child: Switch(
                          value: searchLike,
                          activeColor: mainColor,
                          inactiveTrackColor: Colors.blueGrey,
                          inactiveThumbColor: backgroundColor,
                          onChanged: genOnChange(),
                        ),
                      ),
                      GestureDetector(
                        onDoubleTap: () async {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.clear();
                        },
                        child: new Container(
                          child: Text(""),
                          width: 150,
                          height: 40,
                          //color: mainColor,
                        ),
                      )
                    ],
                  ),
                  renderSearchHistory(),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding:
                              EdgeInsets.only(left: 16, top: 10, bottom: 0),
                          child: Text(
                            "搜索结果({num})"
                                .replaceAll("{num}", gscList.length.toString()),
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        )
                      ]),
                  Expanded(child: renderListView())
                ],
              ),
            )));
  }

  @override
  void dispose() {
    super.dispose();
    debugPrint("dispose...");
  }
}

class GscDetailScreen extends StatefulWidget {
  final List<Gsc> gscs;
  final int index;

  GscDetailScreen({Key key, this.gscs, this.index}) : super(key: key);

  @override
  GscDetailScreenState createState() {
    return GscDetailScreenState();
  }
}

class GscDetailScreenState extends State<GscDetailScreen> {
  List<Gsc> gscs;
  int index;
  Gsc gsc;
  GlobalKey globalKey = GlobalKey();
  bool isPlaying;
  bool showTabar;

  AudioPlayer audioPlayer = new AudioPlayer();

  ValueNotifier isPlayingNotifier = ValueNotifier(0);

  ScrollController scrollController = ScrollController();

  double tabBarOffset;

  

  @override
  void initState() {
    gscs = widget.gscs;
    index = widget.index;
    gsc = gscs[index];
    isPlaying = false;
    showTabar = false;
    tabBarOffset = 0;
    super.initState();
    isPlayingNotifier.addListener(() {
      if (!isPlaying && audioPlayer != null) {
        audioPlayer.stop();
      }
    });

    audioPlayer.onPlayerStateChanged.listen((onData) {
      if (onData == AudioPlayerState.STOPPED) {
        setState(() {
          isPlaying = false;
        });
      }
      if(onData == AudioPlayerState.COMPLETED){
        togglePlaying();
      }
    }, onError: (msg) {
      setState(() {
        isPlaying = false;
      });
      debugPrint(msg);
    });
  }

  @override
  void dispose() {
    audioPlayer.stop();
    audioPlayer = null;
    super.dispose();
  }

  final TextStyle style = TextStyle(
    height: 1.5,
    fontFamily: "songti",
    fontSize: 18,
  );
  final TextStyle styleTranslation =
      TextStyle(height: 1.5, fontFamily: "songti", fontSize: 16);

  final TextStyle styleForeword = TextStyle(
      height: 1.5,
      fontFamily: "songkai",
      fontSize: 14,
      fontStyle: FontStyle.italic);

  _capturePng() async {
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext.findRenderObject();
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();
      var result = await ImagePickerSaver.saveFile(
          fileData: pngBytes, title: gsc.workTitle + "-" + gsc.workAuthor);
      if (result.length != 0) {
        Fluttertoast.showToast(
            msg: "截图成功~",
            textColor: mainColor,
            backgroundColor: backgroundColor,
            gravity: ToastGravity.TOP);
      } else {
        Fluttertoast.showToast(
            msg: "截图出错~",
            textColor: mainColor,
            backgroundColor: backgroundColor,
            gravity: ToastGravity.TOP);
      }
    } catch (e) {
      debugPrint(e);
      Fluttertoast.showToast(
          msg: "截图出错~",
          textColor: mainColor,
          backgroundColor: backgroundColor,
          gravity: ToastGravity.TOP);
    }
    return null;
  }

  Widget renderContent() {
    var text = Text(gsc.content, style: style);
    if (gsc.layout == "center") {
      text = Text(
        gsc.content,
        style: style,
        textAlign: TextAlign.center,
      );
    }
    return GestureDetector(
        child: text,
        onDoubleTap: () {
          // 双击回到上一首
          if (index == 0) {
            index = gscs.length - 1;
          } else {
            index -= 1;
          }
          setState(() {
            index = index;
            gsc = gscs[index];
            isPlaying = false;
            showTabar = false;
            tabBarOffset = 0;
          });
          isPlayingNotifier.value = gsc.id;
        },
        onLongPressEnd: (e) async {
          // 长按截图
          await _capturePng();
        },
        onHorizontalDragEnd: (e) {
          // 往左， 下一首
          if (e.primaryVelocity < 0) {
            if (index == gscs.length - 1) {
              index = 0;
            } else {
              index += 1;
            }
          } else {
            _refresh();
          }
          setState(() {
            index = index;
            gsc = gscs[index];
            isPlaying = false;
            showTabar = false;
            tabBarOffset = 0;
          });
          isPlayingNotifier.value = gsc.id;
        });
  }

  Widget renderForeword() {
    if (gsc.foreword.length > 0) {
      return GestureDetector(
        child: Text(
          gsc.foreword,
          style: styleForeword,
          textAlign: TextAlign.left,
        ),
        onLongPressEnd: (e) async {
          await _capturePng();
        },
      );
    } else {
      return new Container(
        width: 0,
        height: 0,
      );
    }
  }

  void togglePlaying() async {
    if (!isPlaying) {
      await audioPlayer.play(gsc.playUrl);
    } else {
      await audioPlayer.pause();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
    isPlayingNotifier.value = gsc.id;
  }

  Widget renderPlayIcon() {
    if (gsc.audioId > 0) {
      if (isPlaying) {
        return GestureDetector(
            child: Icon(Icons.pause), onTap: () => {togglePlaying()});
      } else {
        return GestureDetector(
            child: Icon(Icons.play_arrow), onTap: () => {togglePlaying()});
      }
    }
    return new Container(
      width: 0,
      height: 0,
    );
  }

  Widget renderLikeIcon() {
    if (gsc.like > 0) {
      return GestureDetector(
        child: Icon(
          Icons.favorite,
          color: Colors.redAccent,
          size: 25,
        ),
        onTap: () {
          gsc.disLike();
          gsc.like = 0;
          setState(() {});
        },
      );
    }
    return GestureDetector(
      child: Icon(
        Icons.favorite_border,
        color: Colors.grey,
        size: 18,
      ),
      onTap: () {
        gsc.toLike();
        gsc.like = 1;
        setState(() {});
      },
    );
  }

  renderTabBar(Key anotherGlobalKey) {
    var result = <MyTabItem>[];
    if (gsc.authorIntro != null) {
      result
          .add(MyTabItem(tabName: "作者", tabContent: gsc.authorIntro["intro"]));
    }
    if (gsc.intro.length > 0) {
      result.add(MyTabItem(tabName: "评析", tabContent: gsc.intro));
    }
    if (gsc.annotation.length > 0) {
      result.add(MyTabItem(tabName: "注释", tabContent: gsc.annotation));
    }
    if (gsc.translation.length > 0) {
      result.add(MyTabItem(tabName: "译文", tabContent: gsc.translation));
    }
    if (gsc.appreciation.length > 0) {
      result.add(MyTabItem(tabName: "赏析", tabContent: gsc.appreciation));
    }
    if (gsc.masterComment.length > 0) {
      result.add(MyTabItem(tabName: "辑评", tabContent: gsc.masterComment));
    }
    if (result.length == 0) {
      return new Container(
        width: 0,
        height: 0,
      );
    }
    return MyTabBar(
      children: result,
      key: anotherGlobalKey,
      show: showTabar,
    );
  }

  Future<void> _refresh() async {
    // 上一首
    if (index == 0) {
      index = gscs.length - 1;
    } else {
      index -= 1;
    }
    setState(() {
      index = index;
      gsc = gscs[index];
      isPlaying = false;
      showTabar = false;
      tabBarOffset = 0;
    });
    isPlayingNotifier.value = gsc.id;
  }

  renderAuthorBaiduWiki() {
    var wikiUrl = '';
    if (gsc.authorIntro != null && gsc.authorIntro["baidu_wiki"] != "") {
      wikiUrl = gsc.authorIntro["baidu_wiki"];
    }
    if (wikiUrl != '') {
      return GestureDetector(
        child: Padding(
          child: Icon(
            Icons.link,
            size: 18,
          ),
          padding: EdgeInsets.only(left: 10),
        ),
        onTap: () async {
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new WebViewWidget(
                        url: wikiUrl,
                        title: gsc.workAuthor + "介绍",
                      )));
        },
      );
    } else {
      return Container(width: 0, height: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey anotherGlobalKey = GlobalKey();
    var screenHeight = MediaQuery.of(context).size.height;
    var padding = MediaQuery.of(context).padding.top;
    double visibleHeight = screenHeight - padding;
    return new Scaffold(
        appBar: PreferredSize(
            child: new AppBar(
              elevation: 0,
              backgroundColor: backgroundColor,
              brightness: Brightness.light,
            ),
            preferredSize: Size.zero),
        backgroundColor: backgroundColor,
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton(
          foregroundColor: mainColor,
          elevation: 0,
          child: () {
            if (showTabar) {
              return Icon(Icons.radio_button_unchecked);
            } else {
              return Icon(Icons.radio_button_checked);
            }
          }(),
          mini: () {
            return !showTabar;
          }(),
          backgroundColor: () {
            if (showTabar) {
              return Color.fromARGB(180, 0xa8, 0xa8, 0xa8);
            } else {
              return Color.fromARGB(180, 0xe8, 0xe8, 0xe8);
            }
          }(),
          onPressed: () {
            if (anotherGlobalKey.currentContext != null && !showTabar) {
              // 高度不好获取
              double bottomHeight = 220;
              RenderBox box =
                  anotherGlobalKey.currentContext.findRenderObject();
              if (tabBarOffset == 0.0) {
                tabBarOffset = box.localToGlobal(Offset.zero).dy;
                if (bottomHeight > screenHeight - padding) {
                  bottomHeight = visibleHeight;
                }
                tabBarOffset = tabBarOffset + bottomHeight + scrollController.offset;
              }
              if (tabBarOffset > visibleHeight) {
                double scrollDistance =
                    (tabBarOffset ~/ visibleHeight - 1) * visibleHeight +
                        tabBarOffset % visibleHeight;
                scrollController.animateTo(scrollDistance,
                    curve: Curves.easeInOut,
                    duration: Duration(
                        milliseconds: (300 * scrollDistance ~/ visibleHeight) + 300));
              }
            }
            if (showTabar) {
              scrollController.animateTo(0,
                  curve: Curves.easeOut,
                  duration: Duration(milliseconds: 600));
            }
            setState(() {
              showTabar = !showTabar;
              tabBarOffset = tabBarOffset;
            });
          },
        ),
        body: SingleChildScrollView(
            controller: scrollController,
            child: RepaintBoundary(
                key: globalKey,
                child: Container(
                    color: backgroundColor,
                    child: Padding(
                        padding:
                            EdgeInsets.only(left: 18, right: 18, bottom: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Container(
                                child: new GestureDetector(
                              child: Text(
                                gsc.workTitle,
                                style: style,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  new MaterialPageRoute(
                                      builder: (context) => new MyHomePage(
                                            gsc: gsc,
                                            from: "title",
                                          )),
                                );
                              },
                            )),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                  child: renderPlayIcon(),
                                  padding: EdgeInsets.only(right: 8, top: 5),
                                ),
                                Padding(
                                  child: renderLikeIcon(),
                                  padding: EdgeInsets.only(top: 5),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new GestureDetector(
                                  child: Text(
                                    "【" +
                                        gsc.workDynasty +
                                        "】" +
                                        gsc.workAuthor,
                                    style: style,
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () => {
                                        Navigator.push(
                                          context,
                                          new MaterialPageRoute(
                                              builder: (context) =>
                                                  new MyHomePage(
                                                    gsc: gsc,
                                                    from: "author",
                                                  )),
                                        )
                                      },
                                ),
                                renderAuthorBaiduWiki()
                              ],
                            ),
                            renderForeword(), // foreword
                            renderContent(), // 正文
                            renderTabBar(anotherGlobalKey), // TabBar
                          ],
                        ))))));
  }
}

class MyTabItem extends StatelessWidget {
  final String tabName;
  final String tabContent;

  const MyTabItem({Key key, @required this.tabName, @required this.tabContent})
      : assert(tabName.length > 0),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(tabName),
          Text(tabContent),
        ]);
  }
}

class MyTabBar extends StatefulWidget {
  final List<MyTabItem> children;
  final bool show;

  @override
  _MyTabBarState createState() {
    return new _MyTabBarState();
  }

  MyTabBar({Key key, this.children, this.show = true})
      : assert(children.length > 0),
        super(key: key);
}

class _MyTabBarState extends State<MyTabBar> {
  List<MyTabItem> children;

  String selectContent;

  String selectItem;

  int currentIndex;

  @override
  void initState() {
    children = widget.children;
    selectContent = children[0].tabContent;
    selectItem = children[0].tabName;
    currentIndex = 0;
    super.initState();
  }

  @override
  void didUpdateWidget(MyTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      children = widget.children;
      selectContent = children[0].tabContent;
      selectItem = children[0].tabName;
      currentIndex = 0;
    });
  }

  Widget getContent() {
    return Padding(
      padding: EdgeInsets.only(left: 15, right: 15, top: 0, bottom: 5),
      child: GestureDetector(
          onHorizontalDragEnd: (e) {
            var tabNum = children.length;
            if (e.primaryVelocity < 0) {
              // 向左, 切换到下一个tab, 如果是最后一个， 切换到第一个
              if (currentIndex < tabNum - 1) {
                currentIndex += 1;
              } else if (currentIndex == tabNum - 1) {
                currentIndex = 0;
              }
            } else {
              // 向右，切换到上一个，如果是第一个，切换到最后一个
              if (currentIndex == 0) {
                currentIndex = tabNum - 1;
              } else {
                currentIndex -= 1;
              }
            }
            setState(() {
              selectContent = children[currentIndex].tabContent;
              selectItem = children[currentIndex].tabName;
              currentIndex = currentIndex;
            });
          },
          child: Text(selectContent,
              style: TextStyle(
                fontSize: 17,
                height: 1.4,
                fontFamily: "songkai",
              ))),
    );
  }

  Widget genIcon(item) {
    if (item == currentIndex) {
      return Image(
        image: AssetImage("assets/line.png"),
        height: 4,
      );
    } else {
      return Container(
        height: 0,
        width: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) {
      return Container(
        width: 0,
        height: 0,
      );
    }
    var result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(Expanded(
          child: Column(children: <Widget>[
        FlatButton(
            highlightColor: mainColor,
            child: Text(
              children[i].tabName,
              maxLines: 2,
              style: TextStyle(
                  fontFamily: "songkai",
                  fontSize: 13,
                  fontWeight: FontWeight.w900),
            ),
            onPressed: () {
              setState(() {
                selectContent = children[i].tabContent;
                selectItem = children[i].tabName;
                currentIndex = i;
              });
            }),
        genIcon(i),
      ])));
    }
    if (result.length < 5) {
      for (var i = 0; i < 5 - result.length; i++)
        result.add(Expanded(
          child: Text(""),
        ));
    }

    return AnimatedOpacity(
      opacity: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: result),
          getContent()
        ],
      ),
      duration: Duration(milliseconds: 500),
    );
  }
}

class WebViewWidget extends StatefulWidget {
  final String url;
  final String title;
  const WebViewWidget({Key key, @required this.url, this.title})
      : super(key: key);

  @override
  WebviewWidgetSate createState() {
    return new WebviewWidgetSate();
  }
}

class WebviewWidgetSate extends State<WebViewWidget> {
  bool complete;
  WebViewController webViewController;

  @override
  void initState() {
    complete = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var height, loadingHeight = 0.0;
    var padding = MediaQuery.of(context).padding.top;
    if (Platform.isAndroid) {
      setState(() {
        complete = true;
      });
    }
    if (complete) {
      loadingHeight = height;
      height = MediaQuery.of(context).size.height - 40 - padding;
    } else {
      height = loadingHeight;
      loadingHeight = MediaQuery.of(context).size.height - 40 - padding;
    }
    return Scaffold(
        appBar: PreferredSize(
            child: new AppBar(
                elevation: 0,
                centerTitle: true,
                title: Text(
                  widget.title,
                  style: TextStyle(
                      color: mainColor, fontFamily: "songkai", fontSize: 16),
                ),
                backgroundColor: backgroundColor,
                brightness: Brightness.light,
                iconTheme: IconThemeData(color: mainColor, opacity: 0)),
            preferredSize: Size.fromHeight(40)),
        body: Container(
          child: Column(
            children: <Widget>[
              () {
                if (!complete) {
                  return Container(
                      height: loadingHeight,
                      color: backgroundColor,
                      child: Center(
                          child: Center(
                              child:
                                  new CupertinoActivityIndicator(radius: 25))));
                } else {
                  return Container(
                    width: 0,
                    height: 0,
                  );
                }
              }(),
              () {
                return Container(
                    height: height,
                    child: WebView(
                      initialUrl: widget.url,
                      javascriptMode: JavascriptMode.disabled,
                      onWebViewCreated: (e) {
                        webViewController = e;
                      },
                      onPageFinished: (e) async {
                        setState(() {
                          complete = true;
                        });
                      },
                    ));
              }()
            ],
          ),
        ));
  }
}
