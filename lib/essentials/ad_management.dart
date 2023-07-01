import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

class AdUnitForSite extends StatefulWidget {
  final String site;
  AdUnitForSite({required this.site});

  @override
  State<AdUnitForSite> createState() => _AdUnitForSiteState();
}

class _AdUnitForSiteState extends State<AdUnitForSite> {
  late BannerAd ad;
  @override
  void initState() {
    ad = BannerAd(
      adUnitId: adUnitIds[widget.site]!,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(),
    );
    if (context.read<UserProvider>().user!.showAds && isAdPlatformEnabled) {
      ad.load();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool showAds = context.read<UserProvider>().user!.showAds;
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
