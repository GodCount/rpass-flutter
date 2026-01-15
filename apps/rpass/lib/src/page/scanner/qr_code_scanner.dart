import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

import '../../i18n.dart';
import '../../util/route.dart';

class _QrCodeScannerArgs extends PageRouteArgs {
  _QrCodeScannerArgs({super.key});
}

class QrCodeScannerRoute extends PageRouteInfo<_QrCodeScannerArgs> {
  QrCodeScannerRoute({
    Key? key,
  }) : super(
          name,
          args: _QrCodeScannerArgs(key: key),
        );

  static const name = "QrCodeScannerRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_QrCodeScannerArgs>(
        orElse: () => _QrCodeScannerArgs(),
      );
      return QrCodeScannerPage(key: args.key);
    },
  );
}

class QrCodeScannerPage extends StatefulWidget {
  const QrCodeScannerPage({super.key});

  @override
  State<QrCodeScannerPage> createState() => _QrCodeScannerPageState();
}

class _QrCodeScannerPageState extends State<QrCodeScannerPage> {
  bool scannered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(I18n.of(context)!.scan_code),
        elevation: 0.0,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (BarcodeCapture barcodes) {
              if (mounted) {
                final barcode = barcodes.barcodes.firstOrNull;
                if (!scannered && barcode != null) {
                  scannered = true;
                  context.router.pop(barcode.displayValue);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
