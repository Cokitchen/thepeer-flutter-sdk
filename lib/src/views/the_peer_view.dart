import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:thepeer_flutter/src/model/thepeer_data.dart';
import 'package:thepeer_flutter/src/raw/thepeer_html.dart';
import 'package:thepeer_flutter/src/utils/extensions.dart';

import 'package:thepeer_flutter/src/views/the_peer_error_view.dart';

class ThepeerSendView extends StatefulWidget {
  /// Public Key from your https://app.withThepeer.com/apps
  final ThePeerData data;

  /// Success callback
  final VoidCallback? onSuccess;

  /// Error callback
  final Function(dynamic)? onError;

  /// Thepeer popup Close callback
  final VoidCallback? onClosed;

  /// Error Widget will show if loading fails
  final Widget? errorWidget;

  /// Show ThepeerSendView Logs
  final bool showLogs;

  /// Toggle dismissible mode
  final bool isDismissible;

  const ThepeerSendView({
    Key? key,
    required this.data,
    this.errorWidget,
    this.onSuccess,
    this.onClosed,
    this.onError,
    this.showLogs = false,
    this.isDismissible = true,
  });

  /// Show Dialog with a custom child
  Future show(BuildContext context) => showMaterialModalBottomSheet(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        isDismissible: isDismissible,
        context: context,
        builder: (context) => ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    height: context.screenHeight(.9),
                    child: ThepeerSendView(
                      data: data,
                      onClosed: onClosed,
                      onSuccess: onSuccess,
                      onError: onError,
                      showLogs: showLogs,
                      errorWidget: errorWidget,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  _ThepeerSendViewState createState() => _ThepeerSendViewState();
}

class _ThepeerSendViewState extends State<ThepeerSendView> {
  @override
  void initState() {
    super.initState();
    _handleInit();
    // Enable hybrid composition.
  }

  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  Future<WebViewController> get _webViewController => _controller.future;
  bool isLoading = false;
  bool hasError = false;

  String? contentBase64;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<String>(
          future: _getURL(),
          builder: (context, snapshot) {
            if (hasError == true) {
              return Center(
                child: widget.errorWidget ??
                    ThePeerErrorView(
                      onClosed: widget.onClosed,
                      reload: () async {
                        setState(() {});
                        (await _webViewController).reload();
                      },
                    ),
              );
            } else if (snapshot.hasData == true) {
              return Center(
                child: FutureBuilder<WebViewController>(
                  future: _controller.future,
                  builder: (BuildContext context,
                      AsyncSnapshot<WebViewController> controller) {
                    return WebView(
                      initialUrl: snapshot.data!,
                      onWebViewCreated: (WebViewController webViewController) {
                        _controller.complete(webViewController);
                      },
                      javascriptChannels: {_thepeerJavascriptChannel()},
                      javascriptMode: JavascriptMode.unrestricted,
                      onPageStarted: (String url) async {
                        setState(() {
                          isLoading = true;
                        });
                        await injectPeerStack(controller.data!);
                      },
                      onPageFinished: (String url) {
                        setState(() {
                          isLoading = false;
                        });
                      },
                      navigationDelegate: (_) =>
                          _handleNavigationInterceptor(_),
                    );
                  },
                ),
              );
            } else {
              return Center(child: CupertinoActivityIndicator());
            }
          }),
    );
  }

  Future<String> injectPeerStack(WebViewController controller) {
    return controller.evaluateJavascript('''
       window.onload = useThepeer;
        function useThepeer() {

            let send = new ThePeer.send({
                publicKey: "${widget.data.publicKey}",
                amount: "${widget.data.amount}",
                userReference: "${widget.data.userReference}",
                receiptUrl: "${widget.data.receiptUrl ?? ''}",
                onSuccess: function (data) {
                    sendMessage(data)
                },
                 onError: function (error) {
                   sendMessage(error)
                },
                onClose: function () {
                    sendMessage("thepeer.dart.closed")
                }
            });

            send.setup();
            send.open();
        }


        function sendMessage(message) {
            if (window.ThepeerClientInterface && window.ThepeerClientInterface.postMessage) {
                ThepeerClientInterface.postMessage(message);
            }
        }
      ''');
  }

  /// Javascript channel for events sent by Thepeer
  JavascriptChannel _thepeerJavascriptChannel() {
    return JavascriptChannel(
        name: 'ThepeerClientInterface',
        onMessageReceived: (JavascriptMessage msg) {
          try {
            print('ThepeerClientInterface, ${msg.message}');
            handleResponse(msg.message);
          } on Exception catch (e) {
            print(e.toString());
          }
        });
  }

  /// parse event from javascript channel
  void handleResponse(String? res) async {
    try {
      if (res != null) {
        switch (res) {
          case 'send.success':
            if (widget.onSuccess != null) widget.onSuccess!();

            return;
          case 'thepeer.dart.closed':
          case 'send.close':
            if (mounted && widget.onClosed != null) widget.onClosed!();

            return;
          default:
            if (mounted && widget.onError != null) widget.onError!(res);
            return;
        }
      }
    } catch (e) {
      if (widget.showLogs == true) print(e.toString());
    }
  }

  Future<String> _getURL() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          hasError = false;
        });
        return Uri.dataFromString(buildThepeerHtml, mimeType: 'text/html')
            .toString();
      } else {
        return Uri.dataFromString('<html><body>An Error Occurred</body></html>',
                mimeType: 'text/html')
            .toString();
      }
    } catch (_) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      return Uri.dataFromString('<html><body>An Error Occurred</body></html>',
              mimeType: 'text/html')
          .toString();
    }
  }

  void _handleInit() async {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  NavigationDecision _handleNavigationInterceptor(NavigationRequest request) {
    if (request.url.toLowerCase().contains('peer')) {
      // Navigate to all urls contianing Thepeer
      return NavigationDecision.navigate;
    } else {
      // Block all navigations outside Thepeer
      return NavigationDecision.prevent;
    }
  }
}
