import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../components/helpers/future_output_dialog.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage();
  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _torchEnabled = false;
  String? code = null;
  MobileScannerController _controller = MobileScannerController(
    torchEnabled: false,
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Scan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (barcodeCapture) {
                    if (code != null) {
                      return;
                    }
                    if (barcodeCapture.barcodes.isEmpty ||
                        barcodeCapture.barcodes
                            .every((element) => element.rawValue == null)) {
                      debugPrint('Failed to scan Barcode');
                    } else {
                      code = barcodeCapture.barcodes
                          .firstWhere(
                              (element) =>
                                  element.rawValue!.startsWith('dodo://') ||
                                  element.rawValue!
                                      .startsWith('https://dodoapp.net/join/'),
                              orElse: null)
                          .rawValue
                          ?.replaceAll('http://', '')
                          .replaceAll('htttp://', '')
                          .replaceAll('https://dodoapp.net/join/', '')
                          .replaceAll('dodo://', '');
                      if (code == null) {
                        return;
                      }
                      showFutureOutputDialog(
                        context: context,
                        future: _qrRead(),
                        outputCallbacks: {
                          BoolFutureOutput.True: () {
                            Navigator.pop(context);
                            Navigator.pop(context, code);
                          }
                        },
                      );
                    }
                  },
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            _torchEnabled = !_torchEnabled;
                            _controller.toggleTorch();
                          },
                          icon: Icon(
                            _torchEnabled ? Icons.flash_off : Icons.flash_on,
                            color: Theme.of(context).colorScheme.tertiary,
                            size: 30,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _controller.switchCamera();
                          },
                          icon: Icon(
                            Icons.cameraswitch,
                            color: Theme.of(context).colorScheme.tertiary,
                            size: 30,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<BoolFutureOutput> _qrRead() async {
    await Future.delayed(Duration(milliseconds: 400));
    return BoolFutureOutput.True;
  }
}
