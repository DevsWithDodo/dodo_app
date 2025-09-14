import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:csocsort_szamla/components/helpers/background_paint.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/helpers/qr_code.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

enum AddMemberPageTabs {
  invite,
  create;
}

class AddMemberPage extends StatefulWidget {
  const AddMemberPage({super.key});

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<String> nicknames = [''];
  Future<String>? _invitation;

  void addNickname() {
    if (nicknames.last.isEmpty) return;
    setState(() {
      nicknames.add('');
    });
  }

  Future<String> _getInvitation() async {
    try {
      Response response = await Http.get(
        uri: generateUri(GetUriKeys.groupCurrent, context),
        useCache: false,
      );
      Map<String, dynamic> decoded = jsonDecode(response.body);
      return decoded['data']['invitation'];
    } catch (_) {
      rethrow;
    }
  }

  Future<BoolFutureOutput> _addGuest(String username) async {
    try {
      Map<String, dynamic> body = {"language": context.locale.languageCode, "username": username};
      await Http.post(
        uri: '/groups/${context.read<UserNotifier>().currentGroup!.id}/add_guest',
        body: body,
      );
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    _invitation = _getInvitation();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.watch<ScreenSize>().isMobile;
    final children = _children();
    return Scaffold(
      appBar: AppBar(
        title: Text('add-member.title'.tr()),
        bottom: isMobile
            ? PreferredSize(
                preferredSize: Size.fromHeight(80),
                child: Column(
                  children: [
                    SegmentedButton<AddMemberPageTabs>(
                      selectedIcon: Icon(
                        _tabController.index == 0 ? Icons.qr_code : Icons.person_add,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      segments: [
                        ButtonSegment(
                          value: AddMemberPageTabs.invite,
                          label: Text('add-member.invite'.tr()),
                          icon: Icon(Icons.qr_code, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        ButtonSegment(
                          value: AddMemberPageTabs.create,
                          label: Text('add-member.create'.tr()),
                          icon: Icon(Icons.person_add, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                      selected: {AddMemberPageTabs.values[_tabController.index]},
                      onSelectionChanged: (selected) => setState(() {
                        _tabController.animateTo(selected.first.index);
                      }),
                    ),
                    SizedBox(height: 22),
                  ],
                ),
              )
            : null,
      ),
      body: isMobile
          ? Container(
              color: Theme.of(context).colorScheme.surface,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: BackgroundPaint(
                  child: TabBarView(
                    controller: _tabController,
                    physics: NeverScrollableScrollPhysics(),
                    children: children,
                  ),
                ),
              ),
            )
          : BackgroundPaint(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children
                    .map((child) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: child,
                          ),
                        ))
                    .toList(),
              ),
            ),
    );
  }

  List<Widget> _children() {
    return [
      FutureBuilder(
          future: _invitation,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return ErrorMessage(
                error: snapshot.error.toString(),
                onTap: () => setState(() {
                  _invitation = _getInvitation();
                }),
              );
            }
            return SingleChildScrollView(
              padding: EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      'add-member.invite.with_qr'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 300, maxHeight: 300),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: QrCode(data: 'https://dodoapp.net/join/${snapshot.data}'),
                      // PrettyQrView.data(
                      //   data: 'http://dodoapp.net/join/${snapshot.data}',
                      //   decoration: PrettyQrDecoration(
                      //     shape: PrettyQrSmoothSymbol(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      //   ),
                      // ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'add-member.invite.with_link'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5),
                  Center(
                    child: GradientButton(
                      onPressed: () {
                        Share.share(
                          'https://dodoapp.net/join/${snapshot.data}',
                          subject: 'invitation_to_lender'.tr(),
                        );
                      },
                      child: Icon(Icons.share),
                    ),
                  ),
                ],
              ),
            );
          }),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500),
        child: ListView(
          padding: EdgeInsets.only(top: 16),
          children: [
            Text(
              'add-member.create.description'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: 10),
            ...nicknames.mapIndexed(
              (index, nickname) => NicknameField(
                nickname: nickname,
                onChanged: (value) => setState(() {
                  nicknames[index] = value;
                }),
                onAdd: index == nicknames.length - 1 ? addNickname : null,
                onRemove: nicknames.length == 1
                    ? null
                    : () => setState(() {
                          nicknames.removeAt(index);
                        }),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: GradientButton.icon(
                  onPressed: () {
                    List<String> usableNicknames = nicknames.where((nickname) => nickname.trim().isNotEmpty).toList();
                    if (usableNicknames.isEmpty) return;
                    usableNicknames = usableNicknames.toSet().toList(); // remove duplicates
                    Future<BoolFutureOutput> future =
                        Future.wait(usableNicknames.map((nickname) => _addGuest(nickname))).then((value) =>
                            value.contains(BoolFutureOutput.False) ? BoolFutureOutput.False : BoolFutureOutput.True);
                    showFutureOutputDialog(context: context, future: future, outputCallbacks: {
                      BoolFutureOutput.True: () {
                        EventBus.instance.fire(EventBus.refreshBalances);
                        EventBus.instance.fire(EventBus.refreshGroupMembers);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                    });
                  },
                  label: Text('add-member.create.submit'.tr()),
                  icon: Icon(nicknames.where((nickname) => nickname.trim().isNotEmpty).length > 1
                      ? Icons.group_add
                      : Icons.person_add)),
            ),
            SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 25,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    textAlign: TextAlign.center,
                    'add-member.create.note'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }
}

class NicknameField extends StatefulWidget {
  const NicknameField({
    super.key,
    required this.nickname,
    required this.onChanged,
    this.onRemove,
    this.onAdd,
  });

  final String nickname;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onAdd;

  @override
  State<NicknameField> createState() => _NicknameFieldState();
}

class _NicknameFieldState extends State<NicknameField> {
  final _controller = TextEditingController();

  @override
  void didUpdateWidget(covariant NicknameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.text = widget.nickname;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'nickname'.tr(),
              ),
              onChanged: widget.onChanged,
              controller: _controller,
            ),
          ),
          widget.onAdd != null
              ? IconButton(
                  onPressed: widget.onAdd,
                  icon: Icon(Icons.add),
                )
              : IconButton(
                  onPressed: widget.onRemove,
                  icon: Icon(Icons.remove),
                ),
        ],
      ),
    );
  }
}
