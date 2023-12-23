import 'dart:convert';

import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/components/helpers/category_picker_icon_button.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../helpers/http.dart';
import '../helpers/member_chips.dart';

class HistoryFilter extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Category? selectedCategory;
  final int selectedMemberId;
  final void Function(int, DateTime, DateTime, Category?) onValuesChanged;
  final bool isScrolled;
  const HistoryFilter({
    required this.isScrolled,
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
  late DateTime _startDate;
  late DateTime _endDate;
  Category? _selectedCategory;
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
    _selectedMemberId = widget.selectedMemberId;
    _members = _getMembers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedMemberId = widget.selectedMemberId;
    _selectedCategory = widget.selectedCategory;
    _startDate = widget.startDate ?? DateTime.now().subtract(Duration(days: 30));
    _endDate = widget.endDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<UserState, User>(
        selector: (context, provider) => provider.user!,
        builder: (context, user, _) {
          return Container(
            height: 250,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            color: ElevationOverlay.applySurfaceTint(Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceTint, widget.isScrolled ? 2 : 0),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat.yMMMd(context.locale.languageCode).format(_startDate) +
                            ' - ' +
                            DateFormat.yMMMd(context.locale.languageCode).format(_endDate),
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
                              start: _startDate,
                              end: _endDate,
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
                      Text('category'.tr(), style: Theme.of(context).textTheme.bodyLarge),
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
                  SizedBox(height: 5),
                  Expanded(
                    child: FutureBuilder(
                      future: _members,
                      builder: (context, AsyncSnapshot<List<Member>> snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return CircularProgressIndicator();
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
                              chosenMembers:
                                  snapshot.data!.where((element) => element.id == _selectedMemberId).toList(),
                              setChosenMembers: (newMembersChosen) {
                                if (newMembersChosen.isNotEmpty) {
                                  setState(() => _selectedMemberId = newMembersChosen.first.id);
                                }
                              },
                              multiple: false,
                              showAnimation: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 5),
                  GradientButton(
                    useSecondary: true,
                    child: Icon(Icons.filter_alt),
                    onPressed: () => widget.onValuesChanged(_selectedMemberId, _startDate, _endDate, _selectedCategory),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
