import 'dart:convert';

import 'package:csocsort_szamla/components/helpers/category_picker_icon_button.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../helpers/http.dart';
import '../helpers/member_chips.dart';

class HistoryFilter extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Category? selectedCategory;
  final int selectedMemberId;
  final void Function({int? selectedMemberId, DateTime? startDate, DateTime? endDate, Category? category, bool? removeCategory}) onValuesChanged;
  const HistoryFilter({
    required this.startDate,
    required this.endDate,
    required this.selectedCategory,
    required this.selectedMemberId,
    required this.onValuesChanged,
    super.key,
  });

  @override
  State<HistoryFilter> createState() => _HistoryFilterState();
}

class _HistoryFilterState extends State<HistoryFilter> {
  late Future<List<Member>> _members;
  late int _selectedMemberId;

  Future<List<Member>> _getMembers() async {
    try {
      Response response = await Http.get(uri: generateUri(GetUriKeys.groupCurrent, context));

      Map<String, dynamic> decoded = jsonDecode(response.body);
      List<Member> members = [];
      for (var member in decoded['data']['members']) {
        members.add(Member.fromJson(member));
      }
      return members;
    } catch (_) {
      throw _;
    }
  }

  @override
  void initState() {
    super.initState();
    _members = _getMembers();
    _selectedMemberId = widget.selectedMemberId;
  }

  @override
  void didUpdateWidget(covariant HistoryFilter oldWidget) {
    super.didUpdateWidget(oldWidget);

  }

  @override
  Widget build(BuildContext context) {
    return Selector<UserState, User>(
        selector: (context, provider) => provider.user!,
        builder: (context, user, _) {
          return Container(
            height: 180,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat.yMd(context.locale.languageCode).format(widget.startDate) +
                            ' - ' +
                            DateFormat.yMd(context.locale.languageCode).format(widget.endDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      IconButton.filledTonal(
                        icon: Icon(
                          Icons.date_range,
                        ),
                        onPressed: () async {
                          DateTimeRange? range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.parse('2020-01-17'),
                            lastDate: DateTime.now(),
                            currentDate: DateTime.now(),
                            initialDateRange: DateTimeRange(
                              start: widget.startDate,
                              end: widget.endDate,
                            ),
                            builder: (context, child) => child!,
                          );
                          if (range != null) {
                            widget.onValuesChanged(startDate: range.start, endDate: range.end);
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('category'.tr(), style: Theme.of(context).textTheme.bodyLarge),
                      CategoryPickerIconButton(
                        selectedCategory: widget.selectedCategory,
                        onCategoryChanged: (newCategory) {
                          setState(() {
                            if (widget.selectedCategory?.type == newCategory?.type) {
                              widget.onValuesChanged(removeCategory: true);
                            } else {
                              widget.onValuesChanged(category: newCategory);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  FutureBuilder(
                    future: _members,
                    builder: (context, AsyncSnapshot<List<Member>> snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData) {
                        return ErrorMessage(
                          error: snapshot.error.toString(),
                          onTap: () => setState(() => _members = _getMembers()),
                          errorLocation: 'history_filter',
                        );
                      }
                      return Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: MemberChips(
                            allMembers: snapshot.data!,
                            chosenMemberIds:
                                snapshot.data!.where((element) => element.id == _selectedMemberId).map((e) => e.id).toList(),
                            setChosenMemberIds: (newMembersChosen) {
                              if (newMembersChosen.isNotEmpty) {
                                widget.onValuesChanged(selectedMemberId: newMembersChosen.first);
                                setState(() {
                                  _selectedMemberId = newMembersChosen.first;
                                });
                              }
                            },
                            multiple: false,
                            showAnimation: false,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }
}
