import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gltntarayici/services/admob_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'package:webview_flutter/webview_flutter.dart';

AppOpenAd? _appOpenAd;

Future _createAppOpenAd() async {
  await AppOpenAd.load(
      adUnitId: AdMobService.adUnitId,
      request: AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("openad is loaded");
          _appOpenAd = ad;
          _appOpenAd!.show();
        },
        onAdFailedToLoad: (error) => debugPrint("adopenad failed $error"),
      ),
      orientation: AppOpenAd.orientationPortrait);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom]);

  MobileAds.instance.initialize();

  await _createAppOpenAd();
  runApp(MyApp());

  OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

  OneSignal.shared.setAppId("30a6a1f2-f761-4bce-a017-47e94b5d0a2a");

// The promptForPushNotificationsWithUserResponse function will show the iOS push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
  OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
    print("Accepted permission: $accepted");
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gluten Tarayıcı',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SecondScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SecondScreen extends StatefulWidget {
  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  late WebViewController controller;

  bool isLoading = true;
  String? scanResult;
  BannerAd? _banner;
  InterstitialAd? _interstitialAd;
  bool haveInt = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    connCheck();
    _createBannerAd();
    _createInterstitialAd();
  }

  Future connCheck() async {
    bool result = await InternetConnectionChecker().hasConnection;
    if (result == false) {
      setState(() {
        haveInt = false;
      });
    }
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: AdMobService.interstitialAdUnitId!,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => _interstitialAd = ad,
          onAdFailedToLoad: (LoadAdError error) => _interstitialAd = null,
        ));
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _createInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  void _createBannerAd() {
    _banner = BannerAd(
        size: AdSize.smartBanner,
        adUnitId: AdMobService.bannerAdUnitId!,
        listener: AdMobService.bannerListener,
        request: AdRequest())
      ..load();
  }

  Future scanBarcode() async {
    String scanResult;

    try {
      scanResult = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", false, ScanMode.BARCODE);
    } on PlatformException {
      scanResult = "Failed to get platform version.";
    }
    if (!mounted) return;

    setState(() {
      this.scanResult = scanResult;
      print("heyd" + this.scanResult!);
    });
    if (this.scanResult != "index" && this.scanResult != "-1") {
      setState(() {
        controller
            .loadUrl("https://app.glutentarayici.com/barkodif?ne=$scanResult");
      });
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: Text('Uygulamadan çıkmak istediğinize emin misiniz ?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: new Text('Çık'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: new Text('Devam Et'),
              ),
            ],
          ),
        )) ??
        false;
  }

  bool _isLoading = false;

  var loadingPercentage = 0;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await controller.canGoBack()) {
          controller.goBack();

          return false;
        }
        return _onWillPop();
      },
      child: Scaffold(
          floatingActionButton: FloatingActionButton(
            child: FaIcon(FontAwesomeIcons.barcode),
            onPressed: () {
              haveInt ? scanBarcode() : null;
              haveInt ? _showInterstitialAd() : null;
            },
          ),
          body: Stack(
            children: [
              haveInt
                  ? WebView(
                      initialUrl: "https://app.glutentarayici.com",
                      javascriptMode: JavascriptMode.unrestricted,

                      onWebViewCreated: (controller) {
                        this.controller = controller;
                      },
                      onPageStarted: (finish) {
                        setState(() {
                          isLoading = false;
                        });

                        // controller.runJavascript();
                      },

                      onProgress: (progress) {
                        setState(() {
                          loadingPercentage = progress;
                        });
                      },
                      onPageFinished: ((url) {}),

                      // gestureRecognizers: Set()
                      //   ..add(Factory<VerticalDragGestureRecognizer>(
                      //       () => VerticalDragGestureRecognizer()
                      //         ..onDown = (DragDownDetails dragDownDetails) {
                      //           controller.getScrollY().then((value) {
                      //             if (value == 0 &&
                      //                 dragDownDetails.globalPosition.direction < 1) {
                      //               controller.reload();
                      //             }
                      //           });
                      //         })),

                      // navigationDelegate: (NavigationRequest request) {
                      //   if (request.url.startsWith("https://lave.com.tr")) {
                      //     return NavigationDecision.navigate;
                      //   } else {
                      //     _launchURL(request.url);
                      //     return NavigationDecision.prevent;
                      //   }
                      // },
                    )
                  : Center(
                      child: Text(
                      "Lütfen İnternet Bağlantını Kontrol Et ve Tekrardan Dene",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    )),
              if (loadingPercentage < 100 && haveInt == true)
                LinearProgressIndicator(
                  color: Colors.blue,
                  value: loadingPercentage / 100.0,
                ),
              isLoading && haveInt
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : SizedBox.shrink()
            ],
          )),
    );
  }
}
