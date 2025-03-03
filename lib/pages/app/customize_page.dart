import 'dart:async';

import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/components/user_settings/cards/change_language.dart';
import 'package:csocsort_szamla/components/user_settings/components/theme_picker.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StackWidgetState {
  StackWidgetState(this.widget, this.setWidget) {
    hide = _controller.stream;
  }

  Widget? widget;
  Function(Widget? widget) setWidget;
  final StreamController<bool> _controller = StreamController.broadcast();
  late Stream<bool> hide;

  void hideWidget() {
    _controller.add(true);
  }
}

class CustomizePage extends StatefulWidget {
  const CustomizePage({super.key});

  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage> {
  Widget? stackWidget;
  @override
  Widget build(BuildContext context) {
    final isMobile =
        context.select<ScreenSize, bool>((screenWidth) => screenWidth.isMobile);
    return Provider(
      create: (context) => StackWidgetState(
        stackWidget,
        (widget) => setState(() => stackWidget = widget),
      ),
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(
                'customization'.tr(),
              ),
            ),
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Column(
                children: [
                  if (isMobile)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: _settings(),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ListView(
                              controller: ScrollController(),
                              children: _settings(),
                            ),
                          ),
                          Expanded(
                            child: stackWidget ??
                                Card(
                                  child: Center(
                                    child: Text(
                                      'customize-page.preview'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  AdUnit(site: 'settings'),
                ],
              ),
            ),
          ),
          isMobile ? stackWidget ?? SizedBox() : SizedBox(),
        ],
      ),
    );
  }

  List<Widget> _settings() {
    return [
      ThemePicker(),
      LanguagePicker(),
    ];
  }
}
