import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:collection/collection.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

enum DefaultCurrencyFrom {
  none,
  group,
  user,
}

class CurrencyPickerSheet extends HookWidget {
  const CurrencyPickerSheet(
      {super.key,
      required this.onCurrencySelected,
      this.selectedCurrency,
      this.defaultCurrencyFrom = DefaultCurrencyFrom.none});

  final void Function(Currency currency) onCurrencySelected;
  final Currency? selectedCurrency;
  final DefaultCurrencyFrom defaultCurrencyFrom;

  Future<String?> getCountry() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return null;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return null;
      }
    }
    print('itt');
    var position = await Geolocator.getLastKnownPosition() ?? await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.low,
      )
    );
    print(position);
    final Geocoding geocoding = Geocoding();
    final placemarks = await geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    return placemarks.first.isoCountryCode;
  }

  @override
  Widget build(BuildContext context) {
    final country = useState<String?>(null); 
    final countryLoading = useState(true);
    useEffect(() {
      getCountry().then((value) => country.value = value).whenComplete(() => countryLoading.value = false);
    }, []);
    final countryCurrency = useMemoized(
        () => country.value != null
            ? Currency.all()
                .firstWhere((c) => c.countryCodes.contains(country.value!))
            : null,
        [country.value]);
    final groupCurrency = context.watch<UserNotifier>().currentGroup?.currency;
    final userCurrency = context.watch<UserNotifier>().user?.currency;
    final majorCurrencies = useMemoized(
        () => Currency.all().where((currency) => currency.isMajor).toList());
    final List<Currency> allCurrencies = useMemoized(
        () => <Currency>[
              ...(selectedCurrency != null ? [selectedCurrency!] : []),
              ...<Currency>[
                ...(countryCurrency != null ? [countryCurrency] : []),
                ...(groupCurrency != null && !groupCurrency.isMajor
                    ? [groupCurrency]
                    : []),
                ...(userCurrency != null &&
                        userCurrency.code != groupCurrency?.code &&
                        !userCurrency.isMajor
                    ? [userCurrency]
                    : []),
                ...majorCurrencies,
                ...Currency.all(),
              ].where((currency) => currency.code != selectedCurrency?.code)
            ],
        [majorCurrencies, groupCurrency, userCurrency, selectedCurrency, countryCurrency]);

    final searchController = useTextEditingController();
    final searchFocusNode = useFocusNode();
    final value = useValueListenable(searchController);
    final searchText = useMemoized(() => value.text, [value]);
    final filteredCurrencies = useMemoized(
        () => allCurrencies
            .where((currency) => currency.fullName
                .toLowerCase()
                .contains(searchText.toLowerCase()))
            .toSet()
            .toList(),
        [allCurrencies, searchText]);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final fullHeight = MediaQuery.sizeOf(context).height;

    final defaultCurrency = useMemoized(
        () => switch (defaultCurrencyFrom) {
              DefaultCurrencyFrom.group => groupCurrency,
              DefaultCurrencyFrom.user => userCurrency,
              DefaultCurrencyFrom.none => null,
            },
        [defaultCurrencyFrom, groupCurrency, userCurrency]);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: fullHeight * 0.6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("select-currency".tr(),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            if (countryLoading.value)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(
                      padding: EdgeInsets.all(3),
                      strokeWidth: 1.5,
                    )),
                    const SizedBox(width: 4),
                    Text("select-currency.loading".tr(), style: context.textTheme.bodySmall!.copyWith(color: context.colorScheme.onSurfaceVariant)),
                ],
              )
            else const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 250, maxHeight: 50),
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      decoration: InputDecoration(
                        labelText: "select-currency.search".tr(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
                if (selectedCurrency != null &&
                    defaultCurrencyFrom != DefaultCurrencyFrom.none &&
                    defaultCurrency != null &&
                    defaultCurrency.code != selectedCurrency?.code)
                  IconButton.filledTonal(
                      onPressed: () => onCurrencySelected(defaultCurrency),
                      icon: Icon(Icons.restart_alt)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  itemCount: filteredCurrencies.length,
                  itemBuilder: (context, index) {
                    final isSelected = filteredCurrencies[index].code ==
                        selectedCurrency?.code;
                    final textColor = isSelected
                        ? context.colorScheme.onPrimaryContainer
                        : context.colorScheme.onSurface;
                    return GestureDetector(
                      onTap: () =>
                          onCurrencySelected(filteredCurrencies[index]),
                      child: Container(
                        margin: EdgeInsets.only(top: index == 0 ? 0 : 4),
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.colorScheme.primaryContainer
                              : context.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          spacing: 2,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${filteredCurrencies[index].flag ?? ""} ${filteredCurrencies[index].code}",
                              style: TextStyle(color: textColor),
                            ),
                            Text(
                              "•",
                              style: TextStyle(color: textColor),
                            ),
                            Flexible(
                                child: Text(
                              filteredCurrencies[index].fullName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: textColor),
                            )),
                            Text(
                              "•",
                              style: TextStyle(color: textColor),
                            ),
                            Text(
                              filteredCurrencies[index].symbol,
                              style: TextStyle(color: textColor),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

Future<T?> showCurrencyPickerSheet<T>(
  BuildContext context, {
  required Currency currency,
  required void Function(Currency currency) onCurrencySelected,
  required DefaultCurrencyFrom defaultCurrencyFrom,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => CurrencyPickerSheet(
      onCurrencySelected: (currency) {
        onCurrencySelected(currency);
        Navigator.of(context).pop(currency);
      },
      selectedCurrency: currency,
      defaultCurrencyFrom: defaultCurrencyFrom,
    ),
  );
}
