import 'dart:convert';
import 'dart:io';
import 'gsc.dart';

import 'package:flutter/material.dart';

const mainColor = Color.fromARGB(255, 98, 91, 87);
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'i古诗词',
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
          primaryColor: mainColor),
      home: MyHomePage(title: 'i古诗词', gsc: null,),
    );
  }
}

class MyHomePage extends StatefulWidget {
  Gsc gsc = null;
  MyHomePage({Key key, this.title, this.gsc}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState(gsc);
}

class _MyHomePageState extends State<MyHomePage> {
  Gsc _gsc = null;
  _MyHomePageState(gsc){
    this._gsc = gsc;
  }
  List<Gsc> gscList = [];
  var loading = false;
  var style = TextStyle(height: 1.5, fontSize: 15, fontFamily: "songkai");

  HttpClient httpClient = new HttpClient();

  final homeAip = "https://igsc.wx.haihui.site/songci/index/all/b";
  final searchAip =
      "https://igsc.wx.haihui.site/songci/query/{inputText}/main/b";

  var editController = TextEditingController();
  var _contentFocusNode = FocusNode();

  void getHomeGsc() async {
    this.gscList = [];
    this.loading = true;
    setState(() {});
    HttpClientRequest request =
        await httpClient.getUrl(Uri.parse(this.homeAip));
    request.headers.add("user-agent", "iGsc/0.0.1");
    HttpClientResponse response = await request.close();
    var resp = await response.transform(utf8.decoder).join();
    var gscs = jsonDecode(resp)["data"]["data"];
    this.gscList = [];
    for (var i = 0; i < gscs.length; i++) {
      this.gscList.add(Gsc(gscs[i]));
    }
    this.loading = false;
    setState(() {});
  }
 
  // 跳转到详情
  void goToDetail(Gsc gsc) {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new GscDetailScreen(gsc)),
    );
  }

  List<Widget> renderListView() {
    if(this.loading){
      return getProgressDialog();
    }
    List<Widget> result = [];
    for (var i = 0; i < this.gscList.length; i++) {
      var gsc = this.gscList[i];
      result.add(new GestureDetector(
          onTap: () {
            goToDetail(gsc);
          },
          onDoubleTap: () {
            goToDetail(gsc);
          },
          child: Column(
            children: <Widget>[
              Flex(direction: Axis.horizontal, children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: new EdgeInsets.all(8),
                        child: Text(
                          gsc.workTitle,
                          softWrap: true,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: style,
                        ),
                      ),
                      Padding(
                        padding: new EdgeInsets.all(8),
                        child: Text(
                          gsc.shortContent,
                          softWrap: true,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: style
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Padding(
                        padding: new EdgeInsets.all(8),
                        child: Text(
                          "",
                          style: style
                        ),
                      ),
                      Padding(
                        padding: new EdgeInsets.all(8),
                        child: Text(
                          "【" +
                              gsc.workDynasty +
                              "】" +
                              gsc.workAuthor.toString(),
                          textAlign: TextAlign.end,
                          style: style
                        ),
                      )
                    ],
                  ),
                )
              ]),
              Divider(height: 10.0, indent: 8.0, color: Colors.grey),
            ],
          )));
    }
    return result;
  }

  @override
  void initState() {
    // 初始化获取gsc
    if(this._gsc!=null){
      editController.text = this._gsc.workAuthor;
      search(this._gsc.workAuthor);
    }else{
      getHomeGsc();
    }
    super.initState();
  }

  void search(searchText) async {
    this.gscList = [];
    if(this.loading){
      return;
    }
    this.loading = true;
    setState(() {});
    var inputText;
    if(searchText==null){
      inputText = this.editController.text.trim();
    }else{
      inputText = searchText;
    }
    Uri uri;
    if (inputText.length == 0) {
      uri = Uri.parse(homeAip);
    } else {
      uri = Uri.parse(searchAip.replaceAll("{inputText}", inputText));
    }
    HttpClientRequest request = await httpClient.getUrl(uri);
    request.headers.add("user-agent", "iGsc/0.0.1");
    HttpClientResponse response = await request.close();
    var resp = await response.transform(utf8.decoder).join();
    var gscs = jsonDecode(resp)["data"]["data"];
    this.gscList = [];
    for (var i = 0; i < gscs.length; i++) {
      this.gscList.add(Gsc(gscs[i]));
    }
    this.loading = false;
    setState(() {});
  }

  getProgressDialog(){
    List<Widget> result = [];
    result.add(
      Center(child:
          new CircularProgressIndicator(backgroundColor: mainColor)
      )
    );
    return result;
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
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: new Align(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          alignment: Alignment.topLeft,
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
                    child: 
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 1, bottom: 0),
                      child: TextFormField(
                      focusNode: _contentFocusNode,
                      autofocus: false,
                      style: TextStyle(color: Colors.blueGrey),
                      strutStyle: StrutStyle(fontStyle: FontStyle.italic),
                      controller: editController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.search,
                      onEditingComplete: (){
                        _contentFocusNode.unfocus();
                        search(null);
                        },
                    ),
                    )
                  ),
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      _contentFocusNode.unfocus();
                      search(null);
                      },
                  )
                ],
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 10, bottom: 0),
                      child: Text("搜索结果({num})"
                        .replaceAll("{num}", this.gscList.length.toString()), style: TextStyle(fontWeight: FontWeight.w600),),
                    )
                    
                  ]),
              Expanded(
                child: ListView(
                    shrinkWrap: true,
                    primary: true,
                    padding: const EdgeInsets.only(
                        left: 0, right: 10, top: 10, bottom: 10),
                    children: renderListView()),
              )
            ],
          ),
        ));
  }
}

class GscDetailScreen extends StatelessWidget {
  final Gsc gsc;

  GscDetailScreen(this.gsc);

  final TextStyle style =
      TextStyle(height: 1.5, fontFamily: "songkai", fontSize: 18);
  final TextStyle styleTranslation =
      TextStyle(height: 1.5, fontFamily: "songkai", fontSize: 16);

  Widget renderTranslation(Gsc gsc) {
    if (gsc.translation.length > 0) {
      return Text(
        "\n【翻译】\n" + this.gsc.translation,
        style: styleTranslation,
      );
    } else {
      return Text("");
    }
  }

  Widget renderContent(Gsc gsc) {
    if (gsc.layout == "center") {
      return Text(
        this.gsc.content,
        style: style,
        textAlign: TextAlign.center,
      );
    } else {
      return Text(
        this.gsc.content,
        style: style,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(this.gsc.workTitle),
        ),
        body: Center(
            //Text(this.gsc.content, style: TextStyle(height: 1.5, fontFamily: "songkai"))
            child: ListView(
          padding: EdgeInsets.all(10),
          //shrinkWrap: true,
          children: <Widget>[

            Text(
              this.gsc.workTitle,
              style: style,
              textAlign: TextAlign.center,
            ),
            new GestureDetector(
              child: Text(
              "【" + this.gsc.workDynasty + "】" + this.gsc.workAuthor,
              style: style,
              textAlign: TextAlign.center,
            ),
            onTap: ()=>{
              Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => new MyHomePage(title: "i古诗词", gsc: gsc)),
            )
            },
            ),
            renderContent(this.gsc), // 正文
            Padding(
                padding: EdgeInsets.all(8), child: renderTranslation(this.gsc)),
          ],
        )));
  }
}
