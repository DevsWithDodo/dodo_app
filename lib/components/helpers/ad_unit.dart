import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

class AdUnit extends StatefulWidget {
  final String site;
  const AdUnit({super.key, required this.site});

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
    if (context.read<UserState>().user!.showAds && context.read<AppConfig>().isAdPlatformEnabled) {
      ad.load();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool showAds = context.select<UserState,  bool>((UserState appState) => appState.user!.showAds);
    bool adsEnabled = context.select<AppConfig,  bool>((AppConfig appState) => appState.isAdPlatformEnabled);
    if (ad.responseInfo == null && showAds && adsEnabled) {
      ad.load();
    }
    if (adsEnabled) {
      return Visibility(
        visible: showAds,
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      );
    }
    return Container();
  }
}
