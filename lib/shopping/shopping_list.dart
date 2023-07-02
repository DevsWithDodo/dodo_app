import 'dart:convert';

import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/event_bus.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/groups/main_group_page.dart';
import 'package:csocsort_szamla/shopping/im_shopping_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../essentials/validation_rules.dart';
import '../essentials/widgets/error_message.dart';
import 'shopping_list_entry.dart';

class ShoppingList extends StatefulWidget {
  ShoppingList();
  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> with AutomaticKeepAliveClientMixin {
  Future<List<ShoppingRequest>>? _shoppingList;

  TextEditingController _addRequestController = TextEditingController();

  ScrollController? _scrollController;

  var _formKey = GlobalKey<FormState>();

  @override
  bool get wantKeepAlive => true;

  Future<List<ShoppingRequest>> _getShoppingList(
      {bool overwriteCache = false}) async {
    try {
      Response response = await Http.get(
        uri: generateUri(
          GetUriKeys.requests, context,
          queryParams: {'group': context.read<AppStateProvider>().user!.group!.id.toString()},
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
      throw _;
    }
  }

  Future<bool> _postShoppingRequest(String name) async {
    try {
      Map<String, dynamic> body = {'group': context.read<AppStateProvider>().currentGroup!.id, 'name': name};
      Response response =
          await Http.post(uri: '/requests', body: body);
      Future.delayed(delayTime()).then((value) => _onPostShoppingRequest(
          ShoppingRequest.fromJson(jsonDecode(response.body)['data'])));
      return true;
    } catch (_) {
      throw _;
    }
  }

  _onPostShoppingRequest(ShoppingRequest request) async {
    if (_shoppingList != null) {
      await (_shoppingList!.then<List<ShoppingRequest>>((value) {
        value.add(request);
        return value;
      }));
    }
    Navigator.pop(context);
    setState(() {
      _addRequestController.text = '';
    });
  }

  Future<bool> _undoDeleteRequest(int id) async {
    try {
      Response response = await Http.post(uri: '/requests/restore/' + id.toString());
      Future.delayed(delayTime()).then((value) => _onUndoDeleteRequest(
          ShoppingRequest.fromJson(jsonDecode(response.body)['data'])));
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onUndoDeleteRequest(ShoppingRequest request) async {
    if (_shoppingList != null) {
      await (_shoppingList!.then((list) {
        list.add(request);
        return list;
      }));
    }
    setState(() {});
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    Navigator.pop(context);
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
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      duration: Duration(seconds: 3),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'request_deleted'.tr(),
            style: Theme.of(context)
                .textTheme
                .labelLarge!
                .copyWith(color: Theme.of(context).colorScheme.onSecondary),
          ),
          InkWell(
            onTap: () {
              showDialog(
                      builder: (context) => FutureSuccessDialog(
                            future: _undoDeleteRequest(requestId),
                          ),
                      context: context,
                      barrierDismissible: false)
                  .then((value) {
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
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSecondary),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    ));
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
      showDialog(
        builder: (context) => FutureSuccessDialog(
          future: _postShoppingRequest(name),
          onDataFalse: () {
            Navigator.pop(context);
            setState(() {});
          },
        ),
        barrierDismissible: false,
        context: context,
      );
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
        if (context.read<IsOnlineProvider>().isOnline) await deleteCache(uri: '/groups');
        setState(() {
          _shoppingList = null;
          _shoppingList = _getShoppingList(overwriteCache: true);
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
                    height: 160,
                  ),
                  Expanded(
                    child: FutureBuilder(
                      future: _shoppingList,
                      builder: (context,
                          AsyncSnapshot<List<ShoppingRequest>> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasData) {
                            if (snapshot.data!.length == 0) {
                              return ListView(
                                controller: _scrollController,
                                padding: EdgeInsets.all(15),
                                children: [
                                  SizedBox(
                                    height: 15,
                                  ),
                                  Text(
                                    'nothing_to_show'.tr(),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                            }
                            return ListView(children: [
                              Container(
                                transform:
                                    Matrix4.translationValues(0.0, 0.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Column(
                                    children:
                                        _generateShoppingList(snapshot.data!),
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
                height: 180,
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
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                        )),
                        SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          validator: (value) => validateTextField([
                            isEmpty(value),
                            minimalLength(value, 2),
                          ]),
                          decoration: InputDecoration(
                            hintText: 'wish'.tr(),
                            prefixIcon: Icon(
                              Icons.shopping_cart,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.add_shopping_cart,
                                  color: Theme.of(context).colorScheme.primary),
                              onPressed: _buttonPush,
                            ),
                          ),
                          controller: _addRequestController,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(255)
                          ],
                          onFieldSubmitted: (value) => _buttonPush(),
                        ),
                        SizedBox(
                          height: 10,
                        ),
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
                        showDialog(
                            context: context,
                            builder: (context) => ImShoppingDialog());
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
      int e2Length = requestData2.reactions!
          .where((reaction) => reaction.reaction == '❗')
          .length;
      int e1Length = requestData1.reactions!
          .where((reaction) => reaction.reaction == '❗')
          .length;
      if (e2Length > e1Length) return 1;
      if (e2Length < e1Length) return -1;
      if (requestData1.updatedAt.isAfter(requestData2.updatedAt)) return -1;
      return 1;
    });
    return data.map((element) {
      return ShoppingListEntry(
        shoppingRequest: element,
        onDeleteRequest: this.handleDeletShoppingRequest,
        onEditRequest: this.handleEditShoppingRequest,
      );
    }).toList();
  }
}
