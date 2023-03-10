import 'dart:convert';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/shopping/im_shopping_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../essentials/validation_rules.dart';
import '../essentials/widgets/error_message.dart';
import 'shopping_list_entry.dart';

class ShoppingList extends StatefulWidget {
  final bool bigScreen;
  final bool isOnline;
  ShoppingList({this.isOnline, this.bigScreen});
  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  Future<List<ShoppingRequestData>> _shoppingList;

  TextEditingController _addRequestController = TextEditingController();

  ScrollController _scrollController;

  var _formKey = GlobalKey<FormState>();

  Future<List<ShoppingRequestData>> _getShoppingList({bool overwriteCache = false}) async {
    try {
      http.Response response = await httpGet(
          uri: generateUri(GetUriKeys.requests), context: context, overwriteCache: overwriteCache);
      Map<String, dynamic> decoded = jsonDecode(response.body);

      List<ShoppingRequestData> shopping = <ShoppingRequestData>[];
      decoded['data'].forEach((element) {
        shopping.add(ShoppingRequestData.fromJson(element));
      });
      shopping = shopping.reversed.toList();
      return shopping;
    } catch (_) {
      throw _;
    }
  }

  _onPostShoppingRequest() {
    Navigator.pop(context);
    setState(() {
      _shoppingList = null;
      _shoppingList = _getShoppingList(overwriteCache: true);
      _addRequestController.text = '';
    });
  }

  Future<bool> _postShoppingRequest(String name) async {
    try {
      Map<String, dynamic> body = {'group': currentGroupId, 'name': name};
      await httpPost(uri: '/requests', context: context, body: body);
      Future.delayed(delayTime()).then((value) => _onPostShoppingRequest());
      return true;
    } catch (_) {
      throw _;
    }
  }

  Future<bool> _undoDeleteRequest(int id) async {
    try {
      await httpPost(context: context, uri: '/requests/restore/' + id.toString());
      Future.delayed(delayTime()).then((value) => _onUndoDeleteRequest());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onUndoDeleteRequest() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    Navigator.pop(context, true);
  }

  void callback({int restoreId}) {
    setState(() {
      _shoppingList = null;
      _shoppingList = _getShoppingList(overwriteCache: true);
    });
    if (restoreId != null) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        // behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
        // padding: EdgeInsets.all(24),
        duration: Duration(seconds: 3),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'request_deleted'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  .copyWith(color: Theme.of(context).colorScheme.onSecondary),
            ),
            InkWell(
              onTap: () {
                showDialog(
                        builder: (context) => FutureSuccessDialog(
                              future: _undoDeleteRequest(restoreId),
                              dataTrueText: 'undo_scf',
                              onDataTrue: () {
                                _onUndoDeleteRequest();
                              },
                            ),
                        context: context,
                        barrierDismissible: false)
                    .then((value) {
                  if (value ?? false) callback();
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
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          .copyWith(color: Theme.of(context).colorScheme.onSecondary),
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

  void _buttonPush() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState.validate()) {
      String name = _addRequestController.text;
      showDialog(
          builder: (context) => FutureSuccessDialog(
                future: _postShoppingRequest(name),
                dataTrueText: 'add_scf',
                onDataTrue: () {
                  _onPostShoppingRequest();
                },
                onDataFalse: () {
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
          barrierDismissible: false,
          context: context);
    }
  }

  @override
  void initState() {
    super.initState();
    _shoppingList = null;
    _shoppingList = _getShoppingList();
  }

  @override
  void didUpdateWidget(ShoppingList oldWidget) {
    _shoppingList = null;
    _shoppingList = _getShoppingList();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (widget.isOnline) await deleteCache(uri: '/groups');
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
                    height: 200,
                  ),
                  Expanded(
                    child: FutureBuilder(
                      future: _shoppingList,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasData) {
                            if (snapshot.data.length == 0) {
                              return ListView(
                                controller: _scrollController,
                                padding: EdgeInsets.all(15),
                                children: [
                                  SizedBox(
                                    height: 15,
                                  ),
                                  Text(
                                    'nothing_to_show'.tr(),
                                    style: Theme.of(context).textTheme.bodyText1,
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
                                    children: _generateShoppingList(snapshot.data),
                                  ),
                                ),
                              )
                            ]);
                          } else {
                            return ErrorMessage(
                              error: snapshot.error.toString(),
                              locationOfError: 'shopping_list',
                              callback: () {
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
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              .copyWith(color: Theme.of(context).colorScheme.onSurface),
                        )),
                        SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          validator: (value) => validateTextField({
                            isEmpty: [value.trim()],
                            minimalLength: [value.trim(), 2],
                          }),
                          decoration: InputDecoration(
                            hintText: 'wish'.tr(),
                            prefixIcon: Icon(
                              Icons.shopping_cart,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.add_shopping_cart,
                                  color: Theme.of(context).colorScheme.primary),
                              onPressed: _buttonPush,
                            ),
                          ),
                          controller: _addRequestController,
                          inputFormatters: [LengthLimitingTextInputFormatter(255)],
                          onFieldSubmitted: (value) => _buttonPush(),
                        ),
                        Flexible(
                          child: SizedBox(
                            height: 20,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            showDialog(
                              builder: (context) => ImShoppingDialog(),
                              context: context,
                            );
                          },
                          child: Text('i_m_shopping'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  .copyWith(color: Theme.of(context).colorScheme.primary)),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _generateShoppingList(List<ShoppingRequestData> data) {
    data.sort((e1, e2) {
      int e2Length = e2.reactions.where((reaction) => reaction.reaction == '???').length;
      int e1Length = e1.reactions.where((reaction) => reaction.reaction == '???').length;
      if (e2Length > e1Length) return 1;
      if (e2Length < e1Length) return -1;
      if (e1.updatedAt.isAfter(e2.updatedAt)) return -1;
      return 1;
    });
    return data.map((element) {
      return ShoppingListEntry(
        data: element,
        callback: this.callback,
      );
    }).toList();
  }
}
