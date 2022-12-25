import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../essentials/http_handler.dart';
import '../essentials/widgets/future_success_dialog.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage();
  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _torchEnabled = false;
  MobileScannerController _controller = MobileScannerController(
    torchEnabled: false,
    facing: CameraFacing.back,
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
                  allowDuplicates: false,
                  controller: _controller,
                  onDetect: (barcode, args) {
                    if (barcode.rawValue == null) {
                      debugPrint('Failed to scan Barcode');
                    } else {
                      final String code = barcode.rawValue;
                      debugPrint('code: ' + code);
                      showDialog(
                          context: context,
                          builder: (context) {
                            return FutureSuccessDialog(
                              future: _qrRead(code),
                            );
                          });
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

  Future<bool> _qrRead(String code) async {
    await Future.delayed(Duration(milliseconds: 400));
    Future.delayed(delayTime()).then((value) => _onQRRead(code));
    return Future.value(true);
  }

  void _onQRRead(code) {
    Navigator.pop(context);
    Navigator.pop(context, code);
  }
}
