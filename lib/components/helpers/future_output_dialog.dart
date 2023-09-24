import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'package:csocsort_szamla/common.dart';

/// A function that uses the [showDialog] function to show a [FutureOutputDialog].
Future<R?> showFutureOutputDialog<R, T extends FutureOutput>({
  required BuildContext context,
  required Future<T> future,
  Map<T, Widget>? outputChildren,
  Map<T, VoidCallback>? outputCallbacks,
  Map<T, String>? outputTexts,
  bool barrierDismissible = false,
  Color? barrierColor = Colors.black54,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
}) {
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    traversalEdgeBehavior: traversalEdgeBehavior,
    builder: (context) => FutureOutputDialog<T>(
      future: future,
      context: context,
      outputCallbacks: outputCallbacks,
      outputChildren: outputChildren,
      outputTexts: outputTexts,
    ),
  );
}

class FutureOutput {
  static const Error = FutureOutput(false, 'error');
  
  const FutureOutput(this.value, this.name);
  final bool value;
  final String name;
}

class BoolFutureOutput extends FutureOutput {
  static const True = BoolFutureOutput(true, 'true');
  static const False = BoolFutureOutput(false, 'false');

  const BoolFutureOutput(super.value, super.name);
}

class FutureOutputDialog<T extends FutureOutput> extends StatefulWidget {
  final Future<T> future;
  final BuildContext context;

  final Map<T, Widget>? outputChildren;
  final Map<T, VoidCallback>? outputCallbacks;
  final Map<T, String>? outputTexts;

  /// A dialog that shows a [CircularProgressIndicator] while the [future] is running and runs a callback when the future is ready.
  /// The [future] returns an instance of [T] extending [FutureOutput].
  /// [T] defines the end states (outputs) the [future] can have.
  /// Every output has a thruth value (defined by [FutureOutput.value]).
  /// If the [future] returns a thruthy value, by default an animated circle icon is shown and the corresponding function in the [outputCallbacks] map is run.
  /// If the [future] returns a falsy value, by default an error message with the corresponding text in the [outputTexts] map is shown.
  /// The end state for every output can be customized via the [outputChildren] map.
  /// The default value for the callbacks is the popping of the dialog. The default text for a falsy value is 'error'.
  FutureOutputDialog({
    required this.future,
    required this.context,
    this.outputCallbacks,
    this.outputChildren,
    this.outputTexts,
  });

  @override
  _FutureOutputDialogState createState() => _FutureOutputDialogState<T>();
}

class _FutureOutputDialogState<T extends FutureOutput> extends State<FutureOutputDialog> {
  Artboard? _riveArtboard;

  @override
  void initState() {
    super.initState();

    rootBundle.load('assets/pipa.riv').then(
      (data) async {
        final file = RiveFile.import(data);

        // The artboard is the root of the animation and gets drawn in the
        // Rive widget.
        final artboard = file.mainArtboard;
        // Add a controller to play back a known animation on the main/default
        // artboard.We store a reference to it so we can toggle playback.
        artboard.addController(SimpleAnimation('go'));
        _riveArtboard = artboard;
      },
    );
  }

  Widget _buildDataTrue() {
    return _riveArtboard == null
        ? Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.secondary,
            size: 50,
          )
        : ColorFiltered(
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary, BlendMode.srcIn),
            child: Container(
                height: 60, width: 60, child: Rive(artboard: _riveArtboard!)),
          );
  }

  Widget _buildDataFalse(VoidCallback callback, String text) {
    return Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                height: 15,
              ),
              ElevatedButton.icon(
                icon: Icon(
                  Icons.clear,
                  color: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () {
                  callback();
                },
                label: Text(
                  'back'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(color: Theme.of(context).colorScheme.onError),
                ),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).colorScheme.error)),
              )
            ],
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FutureBuilder(
        future: (widget.future as Future<T>),
        builder: (context, AsyncSnapshot<T> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              if (snapshot.data!.value) {
                if (widget.outputChildren?[snapshot.data!] != null) {
                  return (widget.outputChildren?[snapshot.data!])!;
                }
                Future.delayed(Duration(milliseconds: delayTime)).then((value) {
                  widget.outputCallbacks?[snapshot.data!]?.call();
                  if (widget.outputCallbacks?[snapshot.data!] == null) {
                    Navigator.pop(widget.context);
                  }
                });
                return _buildDataTrue();
              } else {
                if (widget.outputChildren?[snapshot.data!] != null) {
                  return (widget.outputChildren?[snapshot.data!])!;
                }
                return _buildDataFalse(
                  widget.outputCallbacks?[snapshot.data!] ?? () => Navigator.pop(widget.context),
                  widget.outputTexts?[snapshot.data!] ?? 'error',
                );
              }
            } else {
              return _buildDataFalse(
                widget.outputCallbacks?[FutureOutput.Error] ?? () => Navigator.pop(widget.context), 
                snapshot.error!.toString(),
              );
            }
          }
          return Center(
            child: SizedBox(
              width: 55,
              height: 55,
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
