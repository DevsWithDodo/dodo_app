import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

class FutureSuccessDialog extends StatefulWidget {
  final Widget? dataTrue;
  final Widget? dataFalse;
  final Widget? noData;

  final Future<bool> future;

  final Function? onDataTrue;
  final Function? onDataFalse;
  final Function? onNoData;

  final String? dataTrueText;
  final String dataFalseText;

  ///Dialog for http requests. Translates all text given.
  ///[onDataFalse], [dataFalseText] and [onNoData] have default values.
  ///Fully customizable with [dataTrue], [dataFalse] and [noData]
  FutureSuccessDialog(
      {this.dataTrue,
      this.dataFalse,
      this.noData,
      required this.future,
      this.onDataFalse,
      this.onDataTrue,
      this.onNoData,
      this.dataTrueText,
      this.dataFalseText = 'error'});

  @override
  _FutureSuccessDialogState createState() => _FutureSuccessDialogState();
}

class _FutureSuccessDialogState extends State<FutureSuccessDialog> {
  Function? _onDataFalse;
  Function? _onNoData;

  /// Tracks if the animation is playing by whether controller is running.
  bool get isPlaying => _controller?.isActive ?? false;

  Artboard? _riveArtboard;
  RiveAnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _onDataFalse = widget.onDataFalse;
    _onNoData = widget.onNoData;

    if (_onDataFalse == null) {
      _onDataFalse = () {
        Navigator.pop(context);
      };
    }
    if (_onNoData == null) {
      _onNoData = () {
        Navigator.pop(context);
      };
    }

    rootBundle.load('assets/pipa.riv').then(
      (data) async {
        final file = RiveFile.import(data);

        // The artboard is the root of the animation and gets drawn in the
        // Rive widget.
        final artboard = file.mainArtboard;
        // Add a controller to play back a known animation on the main/default
        // artboard.We store a reference to it so we can toggle playback.
        artboard.addController(_controller = SimpleAnimation('go'));
        _riveArtboard = artboard;
      },
    );
  }

  Widget? _buildDataTrue() {
    if (widget.dataTrue == null) {
      // if(true){
      //   return Container();
      // }
      // return Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary, size: 50,);
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
    return widget.dataTrue;
  }

  Widget? _buildDataFalse() {
    if (widget.dataFalse == null) {
      return Container(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.dataFalseText.tr(),
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
                _onDataFalse!();
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
    return widget.dataFalse;
  }

  Widget? _buildNoData(AsyncSnapshot snapshot) {
    if (widget.noData == null) {
      return Container(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                snapshot.error.toString().tr(),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
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
                _onNoData!();
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
                    Theme.of(context).colorScheme.error),
              ),
            )
          ],
        ),
      );
    }
    return widget.noData;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FutureBuilder(
        future: widget.future,
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              if (snapshot.data!) {
                return _buildDataTrue()!;
              } else {
                return _buildDataFalse()!;
              }
            } else {
              return _buildNoData(snapshot)!;
            }
          }
          return Center(
              child: SizedBox(
                  width: 55, height: 55, child: CircularProgressIndicator()));
        },
      ),
    );
  }
}
