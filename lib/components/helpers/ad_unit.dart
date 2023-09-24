import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/helpers/providers/app_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

class AdUnit extends StatefulWidget {
  final String site;
  AdUnit({required this.site});

  @override
  State<AdUnit> createState() => _AdUnitState();
}

class _AdUnitState extends State<AdUnit> {
  late BannerAd ad;
  @override
  void initState() {
    ad = BannerAd(
      adUnitId: adUnitIds[widget.site]!,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(),
    );
    if (context.read<AppStateProvider>().user!.showAds && isAdPlatformEnabled) {
      ad.load();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool showAds = context.select<AppStateProvider,  bool>((AppStateProvider appState) => appState.user!.showAds);
    if (ad.responseInfo == null && showAds && isAdPlatformEnabled) {
      ad.load();
    }
    if (isAdPlatformEnabled) {
      return Visibility(
        visible: showAds,
        child: Container(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      );
    }
    return Container();
  }
}
