import 'dart:convert';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/widgets/category_picker_icon_button.dart';
import 'package:csocsort_szamla/essentials/widgets/error_message.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../essentials/http_handler.dart';
import '../essentials/widgets/member_chips.dart';
import 'package:http/http.dart' as http;

class HistoryFilter extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Category? selectedCategory;
  final int? selectedMember;
  final void Function(Member, DateTime?, DateTime?, Category?)? onValuesChanged;
  const HistoryFilter({
    this.startDate,
    this.endDate,
    this.selectedCategory,
    this.selectedMember,
    this.onValuesChanged,
  });

  @override
  State<HistoryFilter> createState() => _HistoryFilterState();
}

class _HistoryFilterState extends State<HistoryFilter> {
  DateTime? _startDate;
  DateTime? _endDate;
  Category? _selectedCategory;
  Future<List<Member>>? _members;
  List<Member>? _membersChosen;

  Future<List<Member>> _getMembers() async {
    try {
      http.Response response = await httpGet(
          uri: generateUri(GetUriKeys.groupCurrent), context: context);

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedCategory = widget.selectedCategory;
    _startDate =
        widget.startDate ?? DateTime.now().subtract(Duration(days: 30));
    _endDate = widget.endDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _startDate == null
                    ? 'no_date_range'.tr()
                    : DateFormat.yMMMd(context.locale.languageCode)
                            .format(_startDate!) +
                        ' - ' +
                        DateFormat.yMMMd(context.locale.languageCode)
                            .format(_endDate!),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              IconButton(
                icon: Icon(
                  Icons.date_range,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () async {
                  DateTimeRange? range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.parse('2020-01-17'),
                    lastDate: DateTime.now(),
                    currentDate: DateTime.now(),
                    initialDateRange: DateTimeRange(
                      start: _startDate!,
                      end: _endDate!,
                    ),
                    builder: (context, child) => child!,
                  );
                  if (range != null) {
                    setState(() {
                      _startDate = range.start;
                      _endDate = range.end;
                    });
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('category'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge),
              CategoryPickerIconButton(
                selectedCategory: _selectedCategory,
                onCategoryChanged: (newCategory) {
                  setState(() {
                    if (_selectedCategory?.type == newCategory?.type) {
                      _selectedCategory = null;
                    } else {
                      _selectedCategory = newCategory;
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
                  return CircularProgressIndicator();
                }
                if (!snapshot.hasData) {
                  return ErrorMessage(
                    error: snapshot.error.toString(),
                    onTap: () {
                      setState(() {
                        _members = null;
                        _members = _getMembers();
                      });
                    },
                    errorLocation: 'history_filter',
                  );
                }
                print(_membersChosen);
                if (_membersChosen == null) {
                  _membersChosen = [];
                  if (widget.selectedMember != null) {
                    _membersChosen!.add(snapshot.data!.firstWhere(
                        (element) => element.id == widget.selectedMember));
                  }
                  if (_membersChosen!.isEmpty) {
                    _membersChosen = [
                      snapshot.data!
                          .firstWhere((element) => element.id == currentUserId)
                    ];
                  }
                }
                print(_membersChosen);
                return MemberChips(
                  allMembers: snapshot.data!,
                  chosenMembers: _membersChosen!,
                  chosenMembersChanged: (newMembersChosen) {
                    setState(() {
                      if (newMembersChosen.isEmpty) {
                        _membersChosen = [
                          snapshot.data!.firstWhere(
                              (element) => element.id == currentUserId)
                        ];
                      } else {
                        _membersChosen = newMembersChosen;
                      }
                    });
                  },
                  allowMultipleSelected: false,
                  showAnimation: false,
                );
              }),
          SizedBox(height: 15),
          GradientButton(
            useSecondary: true,
            child: Icon(Icons.check),
            onPressed: () => widget.onValuesChanged!(
                _membersChosen!.first, _startDate, _endDate, _selectedCategory),
          ),
          SizedBox(height: 10),
          Divider(),
        ],
      ),
    );
  }
}
