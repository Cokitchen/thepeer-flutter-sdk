import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thepeer_flutter/thepeer_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: MaterialApp(
        title: 'Thepeer Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        debugShowCheckedModeBanner: false,
        home: MyHomePage(title: 'Thepeer Demo'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ?? '',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        brightness: Brightness.light,
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 60,
                margin: EdgeInsets.symmetric(horizontal: 60),
                child: CupertinoButton(
                  color: thepeerColor,
                  child: Center(
                    child: Text(
                      'Launch thePeer Send',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onPressed: () async {
                    await ThepeerSendView(
                      data: ThePeerData(
                        amount: 400000,
                        userReference: "",
                        receiptUrl: "",
                        publicKey: "",
                      ),
                      showLogs: true,
                      onClosed: () {
                        Navigator.pop(context);
                      },
                      onSuccess: () {
                        onSuccess(context);
                      },
                    ).show(context);
                  },
                ),
              ),
              const SizedBox(height: 60),
              Container(
                height: 60,
                margin: EdgeInsets.symmetric(horizontal: 60),
                child: CupertinoButton(
                  color: thepeerColor,
                  child: Center(
                    child: Text(
                      'Launch Direct Charge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onPressed: () async {
                    await ThepeerDirectChargeView(
                      data: ThePeerData(
                        amount: 400000,
                        userReference: "",
                        publicKey: "",
                      ),
                      showLogs: true,
                      onClosed: () {
                        Navigator.pop(context);
                      },
                      onSuccess: () {
                        onSuccess(context);
                      },
                    ).show(context);
                  },
                ),
              ),
            ],
          ),
        ],
      )),
    );
  }

  void onSuccess(BuildContext context) {
    Navigator.pop(context);
    final snackBar =
        SnackBar(content: Text("Yay! Your payment was successful"));

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

final thepeerColor = Color(0xff1890ff);
