import 'dart:convert';

import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/shopping/im_shopping_dialog.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/main_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../helpers/validation_rules.dart';
import '../helpers/error_message.dart';
import 'shopping_list_entry.dart';

class ShoppingList extends StatefulWidget {
  const ShoppingList({super.key});
  @override
  State<ShoppingList> createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<List<ShoppingRequest>>? _shoppingList;

  final TextEditingController _addRequestController = TextEditingController();

  ScrollController? _scrollController;

  final _formKey = GlobalKey<FormState>();

  Future<List<ShoppingRequest>> _getShoppingList({bool overwriteCache = false}) async {
    try {
      Response response = await Http.get(
        uri: generateUri(
          GetUriKeys.requests,
          context,
          queryParams: {'group': context.read<UserState>().user!.group!.id.toString()},
        ),
        overwriteCache: overwriteCache,
      );
      Map<String, dynamic> decoded = jsonDecode(response.body);

      List<ShoppingRequest> shopping = <ShoppingRequest>[];
      decoded['data'].forEach((element) {
        shopping.add(ShoppingRequest.fromJson(element));
      });
      shopping = shopping.reversed.toList();
      return shopping;
    } catch (_) {
      rethrow;
    }
  }

  Future<BoolFutureOutput> _postShoppingRequest(String name) async {
    try {
      Map<String, dynamic> body = {'group': context.read<UserState>().currentGroup!.id, 'name': name};
      Response response = await Http.post(uri: '/requests', body: body);
      await (_shoppingList!.then<List<ShoppingRequest>>((value) {
        value.add(ShoppingRequest.fromJson(jsonDecode(response.body)['data']));
        return value;
      }));
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
  }

  Future<BoolFutureOutput> _undoDeleteRequest(int id) async {
    try {
      Response response = await Http.post(uri: '/requests/restore/$id');
      if (_shoppingList != null) {
        await (_shoppingList!.then((list) {
          list.add(ShoppingRequest.fromJson(jsonDecode(response.body)['data']));
          return list;
        }));
      }
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
  }

  void handleEditShoppingRequest(ShoppingRequest request) async {
    if (_shoppingList != null) {
      await (_shoppingList!.then((list) {
        list.removeWhere((element) => element.id == request.id);
        list.add(request);
        return list;
      }));
      setState(() {});
    }
  }

  void handleDeletShoppingRequest(int requestId) async {
    if (_shoppingList != null) {
      await (_shoppingList!.then((list) {
        list.removeWhere((element) => element.id == requestId);
        return list;
      }));
      setState(() {});
    }
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
        duration: Duration(seconds: 3),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'request_deleted'.tr(),
              style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.onSecondary),
            ),
            InkWell(
              onTap: () {
                showFutureOutputDialog(context: context, future: _undoDeleteRequest(requestId), outputCallbacks: {
                  BoolFutureOutput.True: () async {
                    setState(() {});
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    Navigator.pop(context);
                  }
                }).then((value) {
                  if (value ?? false) handleDeleteEditShoppingRequest();
                });
              },
              child: Container(
                padding: EdgeInsets.all(3),
                child: Row(
                  children: [
                    Icon(
                      Icons.undo,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'undo'.tr(),
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ));
    }
  }

  void handleDeleteEditShoppingRequest({int? restoreId}) {
    setState(() {
      _shoppingList = null;
      _shoppingList = _getShoppingList(overwriteCache: true);
    });
  }

  void _buttonPush() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      String name = _addRequestController.text;
      showFutureOutputDialog(context: context, future: _postShoppingRequest(name), outputCallbacks: {
        BoolFutureOutput.True: () {
          Navigator.pop(context);
          setState(() {
            _addRequestController.text = '';
          });
        }
      });
    }
  }

  void onRefreshShoppingEvent() {
    setState(() {
      _shoppingList = null;
      _shoppingList = _getShoppingList(overwriteCache: true);
    });
  }

  @override
  void initState() {
    super.initState();

    _shoppingList = null;
    _shoppingList = _getShoppingList();
    EventBus.instance.register(EventBus.refreshShopping, onRefreshShoppingEvent);
  }

  @override
  void dispose() {
    EventBus.instance.unregister(EventBus.refreshShopping, onRefreshShoppingEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _shoppingList = null;
          _shoppingList = _getShoppingList(overwriteCache: context.read<IsOnlineProvider>().isOnline);
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Form(
          key: _formKey,
          child: Stack(
            children: <Widget>[
              Column(
                children: [
                  SizedBox(
                    height: 195,
                  ),
                  Expanded(
                    child: FutureBuilder(
                      future: _shoppingList,
                      builder: (context, AsyncSnapshot<List<ShoppingRequest>> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasData) {
                            if (snapshot.data!.isEmpty) {
                              return ListView(
                                controller: _scrollController,
                                padding: EdgeInsets.all(15),
                                children: [
                                  SizedBox(
                                    height: 15,
                                  ),
                                  Text(
                                    'nothing_to_show'.tr(),
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                            }
                            return ListView(children: [
                              Container(
                                transform: Matrix4.translationValues(0.0, 0.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Column(
                                    children: _generateShoppingList(snapshot.data!),
                                  ),
                                ),
                              )
                            ]);
                          } else {
                            return ErrorMessage(
                              error: snapshot.error.toString(),
                              errorLocation: 'shopping_list',
                              onTap: () {
                                setState(() {
                                  _shoppingList = null;
                                  _shoppingList = _getShoppingList();
                                });
                              },
                            );
                          }
                        }
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ],
              ),
              Container(
                height: 220,
                color: Colors.transparent,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(15, 15, 15, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Center(
                            child: Text(
                          'shopping_list'.tr(),
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
                        )),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                validator: (value) => validateTextField([
                                  isEmpty(value),
                                  minimalLength(value, 2),
                                ]),
                                decoration: InputDecoration(
                                  labelText: 'wish'.tr(),
                                  prefixIcon: Icon(
                                    Icons.shopping_cart,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                controller: _addRequestController,
                                inputFormatters: [LengthLimitingTextInputFormatter(255)],
                                onFieldSubmitted: (value) => _buttonPush(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: IconButton.filledTonal(
                                icon: Icon(Icons.add_shopping_cart),
                                onPressed: _buttonPush,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text('shopping-list.hint'.tr(), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 30, top: 25),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                      icon: Icon(Icons.notifications_active),
                      onPressed: () {
                        showDialog(context: context, builder: (context) => ImShoppingDialog());
                      }),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _generateShoppingList(List<ShoppingRequest> data) {
    data.sort((requestData1, requestData2) {
      int e2Length = requestData2.reactions!.where((reaction) => reaction.reaction == '❗').length;
      int e1Length = requestData1.reactions!.where((reaction) => reaction.reaction == '❗').length;
      if (e2Length > e1Length) return 1;
      if (e2Length < e1Length) return -1;
      if (requestData1.updatedAt.isAfter(requestData2.updatedAt)) return -1;
      return 1;
    });
    return data.map((element) {
      return ShoppingListEntry(
        shoppingRequest: element,
        onDeleteRequest: handleDeletShoppingRequest,
        onEditRequest: handleEditShoppingRequest,
      );
    }).toList();
  }
}
