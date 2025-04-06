import 'package:csocsort_szamla/app.dart';
import 'package:csocsort_szamla/helpers/initializers/exchange_rate_initializer.dart';
import 'package:csocsort_szamla/helpers/initializers/in_app_purchase_initializer.dart';
import 'package:csocsort_szamla/helpers/initializers/notification_initializer.dart';
import 'package:csocsort_szamla/helpers/initializers/supported_version_initializer.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/helpers/providers/invite_url_provider.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_usage_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<SharedPreferences> _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = SharedPreferences.getInstance();
  }

  Future<void> install() async {
    final identityKeyPair = generateIdentityKeyPair();
    final registrationId = generateRegistrationId(false);

    final preKeys = generatePreKeys(0, 110);

    final signedPreKey = generateSignedPreKey(identityKeyPair, 0);

    final sessionStore = InMemorySessionStore();
    final preKeyStore = InMemoryPreKeyStore();
    final signedPreKeyStore = InMemorySignedPreKeyStore();
    final identityStore = InMemoryIdentityKeyStore(identityKeyPair, registrationId);

    for (var p in preKeys) {
      await preKeyStore.storePreKey(p.id, p);
    }
    await signedPreKeyStore.storeSignedPreKey(signedPreKey.id, signedPreKey);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _prefs,
      builder: (context, AsyncSnapshot<SharedPreferences> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final appOpenCount = snapshot.data!.getInt('user-usage.app-open-count') ?? 0;
        snapshot.data!.setInt('user-usage.app-open-count', appOpenCount + 1);
        return FutureBuilder(
            future: install(),
            builder: (context, e2eeSnapshot) {
              if (e2eeSnapshot.connectionState != ConnectionState.done) {
                return Center(child: CircularProgressIndicator());
              }
              return Provider(
                create: (context) => snapshot.data!,
                builder: (context, child) => AppConfigProvider(
                    builder: (context) => AppThemeProvider(
                          context: context,
                          builder: (context) => InviteUrlProvider(
                            builder: (context) => ExchangeRateInitializer(
                              context: context,
                              builder: (context) => ChangeNotifierProvider(
                                  create: (context) => UserUsageNotifier(snapshot.data!),
                                  builder: (context, child) => UserProvider(
                                        context: context,
                                        builder: (context) => NotificationInitializer(
                                          context: context,
                                          builder: (context) => IAPInitializer(
                                            context: context,
                                            builder: (context) => ScreenSizeProvider(
                                              builder: (context) => EasyLocalization(
                                                supportedLocales: [Locale('en'), Locale('de'), Locale('hu')],
                                                path: 'assets/translations',
                                                fallbackLocale: Locale('en'),
                                                useOnlyLangCode: true,
                                                saveLocale: true,
                                                useFallbackTranslations: true,
                                                child: ShowCaseWidget(
                                                  builder: (context) => SupportedVersionInitializer(
                                                    builder: (context) => App(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )),
                            ),
                          ),
                        )),
              );
            });
      },
    );
  }
}
