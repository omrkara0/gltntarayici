import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static String adUnitId = Platform.isAndroid
      ? 'ca-app-pub-6284686343586315/7086456011'
      : 'ca-app-pub-3940256099942544/5662855259';

  static String? get bannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-6284686343586315/3645958356";
    } else if (Platform.isIOS) {
      return "ca-app-pub-6569595971264586/8613263248";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String? get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-6284686343586315/6272121693";
    } else if (Platform.isIOS) {
      return "ca-app-pub-6569595971264586/9851706183";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static final BannerAdListener bannerListener = BannerAdListener(
    onAdLoaded: ((ad) => debugPrint("Ad loaded.")),
    onAdFailedToLoad: (ad, error) {
      ad.dispose();
      debugPrint("Ad failed to load: $error");
    },
    onAdOpened: (ad) => debugPrint("Ad opened."),
    onAdClosed: (ad) => debugPrint("Ad closed."),
  );
}
