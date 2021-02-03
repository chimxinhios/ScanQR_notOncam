import 'dart:convert';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';
import 'package:last_qr_scanner/last_qr_scanner.dart';
import 'shared_preferences_manager.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter_application_qr/bloc/flat_card_bloc.dart';
import 'package:flutter_application_qr/models/ketqua.dart';
import 'package:flutter_application_qr/screen/book.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_app_settings/open_app_settings.dart';

class Scan extends StatefulWidget {
  @override
  _ScanState createState() => _ScanState();
}

class _ScanState extends State<Scan> with WidgetsBindingObserver {
  AppLifecycleState _lastLifecycleState;
  FlatCardBloc bloc = FlatCardBloc();
  String qrResult = "";
  List<String> list = [];
  List<KetQua> listResult = new List();
  List test;
  bool internet = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  AudioPlayer audioPlayer = new AudioPlayer();
  String hdResumeCam = "";
  String qr = "";
  @override
  void initState() {
    // TODO: implement initState
    permission();
    sharedPreferencesManager.init();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void permission() async {
    //if (await Permission.camera.request().isGranted) {}

    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
    ].request();
    print(statuses[Permission.camera]);
    if (statuses[Permission.camera] == PermissionStatus.denied) {
      _showAlertGotoSetting();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
    } else if (state == AppLifecycleState.resumed) {}
  }

  @override
  void dispose() {
    print('dispose');
    bloc.dispose();
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: myAppBar(),
      body: Container(
        padding: EdgeInsets.fromLTRB(35, 25, 35, 1),
        color: new Color(0xFF00B2FB),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            //Text(qr),
            onCam(), resultButton(),
            //scanButton()
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: Icon(
          Icons.import_contacts,
          color: Colors.blue,
        ),
        onPressed: () {
          // setState(() {});
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListWord(),
              ));
        },
      ),
    );
  }

  Widget scanButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 11,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      margin: EdgeInsets.all(1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: FlatButton(
            height: 85,
            onPressed: () async {
              String scanning = await BarcodeScanner.scan();
              bloc.getApi(scanning);
            },
            color: Colors.white,
            child: Text(
              "Scan",
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            )),
      ),
    );
  }

  Widget huongDan() {
    print("");
    Size sizeHD = MediaQuery.of(context).size;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: sizeHD.height * 0.22,
        width: sizeHD.width,
        color: Colors.white,
        //margin: EdgeInsets.fromLTRB(1, 11, 1, 11),
        padding: EdgeInsets.all(16),
        child: Container(
          width: sizeHD.height / 2,
          child: Text(
            "  Ấn vào biểu tượng để mở camera\n\n" +
                " - Đưa máy quay về mã QR\n\n" +
                "(Di chuyển nhẹ camera nếu thiết bị không nhận dạng được mã QR)\n\n",
            style: TextStyle(color: Colors.blue, fontSize: 16),
          ),
        ),
      ),
    );
  }

  resultButton() {
    //Size sideResultButton = MediaQuery.of(context).size;
    return StreamBuilder<KetQua>(
        stream: bloc.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            new Future.delayed(Duration(seconds: 0), () {
              Scaffold.of(context).showSnackBar(SnackBar(
                content: Text(snapshot.error),
              ));
            });
          }
          final result = snapshot.data;
          print(snapshot.data);
          if (!snapshot.hasData) {
            return huongDan();
          }

          new Future.delayed(Duration(seconds: 2), () {
            audioPlayer.play(result.audio);
          });
          ;
          return Container(
            height: 100,
            // color: Colors.blue,
            padding: EdgeInsets.fromLTRB(22, 10, 22, 0),
            child: FlatButton(
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.volume_up,
                    color: Colors.blue,
                  ),
                  Flexible(
                    child: Text(
                      result.word,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.blue, fontSize: 22),
                    ),
                  ),
                  Text("    "),
                ],
              ),
              onPressed: () {
                var url = result.audio;
                audioPlayer.play(url);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
                //side: BorderSide(color: Colors.red)
              ),
            ),
          );
        });
  }

  Future<void> _showAlert() async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text("Hướng Dẫn"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                SizedBox(
                  height: 12,
                ),
                SizedBox(
                  height: 8,
                ),
                Text(" - Đưa máy quay về mã QR"),
                SizedBox(
                  height: 8,
                ),
                Text(
                    "( Di chuyển nhẹ camera nếu thiết bị không nhận dạng được mã QR )"),
                SizedBox(
                  height: 8,
                ),
                Text(" Ấn vào biểu tượng để mở lại camera"),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Đã hiểu ")),
              ],
            )
          ],
        );
      },
    );
  }

  myAppBar() {
    return AppBar(
        backgroundColor: Colors.white,
        leading: question(),
        toolbarHeight: 44,
        elevation: 0,
        brightness: Brightness.light,
        title: Text(
          "MCBooks Flashcard",
          style: TextStyle(color: Colors.blue),
        ),
        centerTitle: true);
  }

  Widget question() {
    return IconButton(
      icon: Icon(
        Icons.help,
        color: Colors.blueAccent,
      ),
      onPressed: () {
        _showAlert();
      },
    );
  }

  Widget onCam() {
    Size size = MediaQuery.of(context).size;
    var siz = size.width * 0.8;
    return Container(
      height: siz,
      width: siz,
      // color: Colors.white,
      margin: EdgeInsets.fromLTRB(0, 0, 0, 15),
      child: GestureDetector(
        onTap: () async {
          String scanning = await BarcodeScanner.scan();
          qr = scanning.replaceAll("\\s\\s+", " ").trim();
          print("qr$qr.");
          bloc.getApi(qr);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Stack(children: [
            Image.asset(
              "assets/scan-icon.jpg",
            ),
            Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("  "),
                Icon(
                  Icons.camera,
                  size: siz * 0.4,
                ),
                Text("Ấn vào đây để quét",
                    style: TextStyle(fontSize: 19, color: Colors.blue[700]))
              ],
            )),
          ]),
        ),
      ),
    );
  }

  Future<bool> check() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      internet = true;

      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      internet = true;

      return true;
    }
    internet = false;
    return false;
  }

  Future<void> _showAlertGotoSetting() async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text("Hướng Dẫn"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                SizedBox(
                  height: 12,
                ),
                Text("Vui lòng cấp phép Camera để sử dụng ứng dụng"),
                SizedBox(
                  height: 8,
                ),
                Text("Vào Cài đặt -> MCbooks FlashCard -> cấp quyền cho Camera")
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () async {
                  await OpenAppSettings.openAppSettings();
                  //Navigator.of(context).pop();
                },
                child: Text(
                  "Vào cài đặt ",
                  style: TextStyle(fontSize: 15),
                ))
          ],
        );
      },
    );
  }
}
