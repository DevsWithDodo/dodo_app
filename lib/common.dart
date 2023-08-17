import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

double adHeight(BuildContext context) => (isAdPlatformEnabled && (context.read<AppStateProvider>().user?.showAds ?? false)) ? 50 : 0;

/// The delay time in ms for the success dialog to pop.
int delayTime = 700;